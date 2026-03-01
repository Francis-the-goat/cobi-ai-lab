#!/usr/bin/env python3
"""Retry queue for video transcription ingestion."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
import uuid
from pathlib import Path
from typing import Any


def now_utc() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def now_iso() -> str:
    return now_utc().isoformat()


def parse_iso(value: str | None) -> dt.datetime:
    if not value:
        return dt.datetime.fromtimestamp(0, tz=dt.timezone.utc)
    try:
        parsed = dt.datetime.fromisoformat(value)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=dt.timezone.utc)
        return parsed.astimezone(dt.timezone.utc)
    except ValueError:
        return dt.datetime.fromtimestamp(0, tz=dt.timezone.utc)


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = "\n".join(json.dumps(r, ensure_ascii=True) for r in rows)
    if text:
        text += "\n"
    path.write_text(text, encoding="utf-8")


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=True) + "\n")


def queue_counts(rows: list[dict[str, Any]]) -> dict[str, int]:
    counts: dict[str, int] = {"pending": 0, "retrying": 0, "done": 0, "deadletter": 0}
    for row in rows:
        status = str(row.get("status") or "pending")
        counts[status] = counts.get(status, 0) + 1
    return counts


def write_legacy_snapshot(legacy_file: Path, queue_file: Path) -> None:
    rows = read_jsonl(queue_file)
    payload = {
        "generatedAt": now_iso(),
        "queueFile": str(queue_file),
        "counts": queue_counts(rows),
        "total": len(rows),
        "items": rows[-20:],
    }
    legacy_file.parent.mkdir(parents=True, exist_ok=True)
    legacy_file.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def extract_field(stdout: str, prefix: str) -> str:
    for line in stdout.splitlines():
        if line.startswith(prefix):
            return line[len(prefix) :].strip()
    return ""


def cmd_add(args: argparse.Namespace) -> int:
    queue = read_jsonl(args.queue_file)
    for existing in queue:
        status = str(existing.get("status") or "pending")
        if status in {"pending", "retrying", "done"} and (
            str(existing.get("source") or "") == args.source
            or str(existing.get("slug") or "") == args.slug
        ):
            write_legacy_snapshot(args.legacy_file, args.queue_file)
            print(
                json.dumps(
                    {
                        "ok": True,
                        "queued": existing.get("id"),
                        "deduped": True,
                        "status": status,
                    }
                )
            )
            return 0
    row = {
        "id": f"txq-{uuid.uuid4().hex[:12]}",
        "source": args.source,
        "slug": args.slug,
        "title": args.title or f"YouTube {args.slug}",
        "status": "pending",
        "attempts": 0,
        "createdAt": now_iso(),
        "updatedAt": now_iso(),
        "nextAttemptAt": now_iso(),
        "lastError": "",
    }
    queue.append(row)
    write_jsonl(args.queue_file, queue)
    write_legacy_snapshot(args.legacy_file, args.queue_file)
    print(json.dumps({"ok": True, "queued": row["id"]}))
    return 0


def should_process(row: dict[str, Any], now: dt.datetime) -> bool:
    status = str(row.get("status") or "")
    if status not in {"pending", "retrying"}:
        return False
    due = parse_iso(row.get("nextAttemptAt"))
    return due <= now


def cmd_process(args: argparse.Namespace) -> int:
    queue = read_jsonl(args.queue_file)
    now = now_utc()
    selected = [r for r in queue if should_process(r, now)]
    selected.sort(key=lambda r: (parse_iso(r.get("nextAttemptAt")).timestamp(), r.get("createdAt", "")))
    selected = selected[: args.limit]

    processed = 0
    succeeded = 0
    failed = 0

    for row in selected:
        processed += 1
        row["attempts"] = int(row.get("attempts") or 0) + 1
        row["updatedAt"] = now_iso()

        cmd = [
            "bash",
            str(args.ingest_script),
            str(row.get("source") or ""),
            str(row.get("slug") or ""),
            str(row.get("title") or ""),
        ]
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=False,
                timeout=args.ingest_timeout_seconds,
            )
        except subprocess.TimeoutExpired:
            proc = subprocess.CompletedProcess(
                args=cmd,
                returncode=124,
                stdout="",
                stderr=f"ingest_timeout_{args.ingest_timeout_seconds}s",
            )

        if proc.returncode == 0:
            row["status"] = "done"
            row["completedAt"] = now_iso()
            row["lastError"] = ""
            row["transcriptPath"] = extract_field(proc.stdout, "Transcript:")
            row["sourceCardPath"] = extract_field(proc.stdout, "Source card:")
            append_jsonl(args.history_file, row)
            succeeded += 1
        else:
            error = (proc.stderr.strip() or proc.stdout.strip() or f"exit_{proc.returncode}")
            row["lastError"] = error[-1500:]
            attempts = int(row.get("attempts") or 0)
            if attempts >= args.max_attempts:
                row["status"] = "deadletter"
                row["deadletterAt"] = now_iso()
                append_jsonl(args.deadletter_file, row)
                failed += 1
            else:
                row["status"] = "retrying"
                delay_seconds = min(args.base_delay_seconds * (2 ** (attempts - 1)), args.max_delay_seconds)
                next_due = now_utc() + dt.timedelta(seconds=delay_seconds)
                row["nextAttemptAt"] = next_due.isoformat()
                failed += 1

    write_jsonl(args.queue_file, queue)
    write_legacy_snapshot(args.legacy_file, args.queue_file)
    print(
        json.dumps(
            {
                "ok": True,
                "processed": processed,
                "succeeded": succeeded,
                "failed": failed,
                "queueFile": str(args.queue_file),
            }
        )
    )
    return 0


def cmd_list(args: argparse.Namespace) -> int:
    queue = read_jsonl(args.queue_file)
    counts = queue_counts(queue)
    write_legacy_snapshot(args.legacy_file, args.queue_file)
    print(json.dumps({"ok": True, "counts": counts, "total": len(queue)}))
    return 0


def cmd_dedupe(args: argparse.Namespace) -> int:
    queue = read_jsonl(args.queue_file)
    if not queue:
        write_legacy_snapshot(args.legacy_file, args.queue_file)
        print(json.dumps({"ok": True, "removed": 0, "remaining": 0}))
        return 0

    rank = {"done": 4, "pending": 3, "retrying": 2, "deadletter": 1}
    best_by_key: dict[tuple[str, str], dict[str, Any]] = {}
    for row in queue:
        key = (str(row.get("source") or ""), str(row.get("slug") or ""))
        status = str(row.get("status") or "pending")
        row_rank = rank.get(status, 0)
        existing = best_by_key.get(key)
        if existing is None:
            best_by_key[key] = row
            continue
        existing_status = str(existing.get("status") or "pending")
        existing_rank = rank.get(existing_status, 0)
        if row_rank > existing_rank:
            best_by_key[key] = row
            continue
        if row_rank == existing_rank and parse_iso(row.get("updatedAt")).timestamp() > parse_iso(
            existing.get("updatedAt")
        ).timestamp():
            best_by_key[key] = row

    deduped = list(best_by_key.values())
    deduped.sort(key=lambda r: parse_iso(r.get("createdAt")).timestamp())
    removed = len(queue) - len(deduped)
    write_jsonl(args.queue_file, deduped)
    write_legacy_snapshot(args.legacy_file, args.queue_file)
    print(json.dumps({"ok": True, "removed": removed, "remaining": len(deduped)}))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Video transcription retry queue")
    parser.add_argument(
        "--workspace",
        default=str(Path.home() / ".openclaw" / "workspace"),
        help="Workspace root path",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    add = sub.add_parser("add", help="Queue a new video transcription ingest task")
    add.add_argument("source")
    add.add_argument("slug")
    add.add_argument("title", nargs="?", default="")

    proc = sub.add_parser("process", help="Process due queue items")
    proc.add_argument("--limit", type=int, default=3)
    proc.add_argument("--max-attempts", type=int, default=4)
    proc.add_argument("--base-delay-seconds", type=int, default=300)
    proc.add_argument("--max-delay-seconds", type=int, default=86400)
    proc.add_argument("--ingest-timeout-seconds", type=int, default=300)

    sub.add_parser("list", help="List queue counts")
    sub.add_parser("dedupe", help="Remove duplicate queue entries by source/slug")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    workspace = Path(args.workspace).expanduser().resolve()
    tdir = workspace / "memory" / "transcription"
    args.queue_file = tdir / "queue.jsonl"
    args.history_file = tdir / "history.jsonl"
    args.deadletter_file = tdir / "deadletter.jsonl"
    args.legacy_file = workspace / "memory" / "transcription_queue.json"
    args.ingest_script = workspace / "scripts" / "ingest_video_source.sh"

    if args.cmd == "add":
        return cmd_add(args)
    if args.cmd == "process":
        return cmd_process(args)
    if args.cmd == "list":
        return cmd_list(args)
    if args.cmd == "dedupe":
        return cmd_dedupe(args)
    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
