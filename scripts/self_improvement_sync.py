#!/usr/bin/env python3
"""Build a self-improvement report from OpenClaw cron run history.

This script gives the agent an evidence-backed improvement loop:
1) ingest cron runs
2) compute quality/cost/speed metrics
3) detect bottlenecks
4) propose concrete experiments
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import statistics
import subprocess
import sys
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Sync OpenClaw run metrics and generate self-improvement report.")
    parser.add_argument("--profile", default="dev", help="OpenClaw profile (default: dev)")
    parser.add_argument(
        "--workspace",
        default=str(Path.home() / ".openclaw" / "workspace"),
        help="Workspace root path",
    )
    parser.add_argument("--days", type=int, default=7, help="Lookback window in days (default: 7)")
    parser.add_argument("--limit-per-job", type=int, default=30, help="Run history entries per job (default: 30)")
    parser.add_argument("--min-sample", type=int, default=3, help="Minimum runs before optimization suggestions (default: 3)")
    return parser.parse_args()


def run_json(cmd: list[str]) -> dict[str, Any]:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"Command failed ({proc.returncode}): {' '.join(cmd)}\n{proc.stderr.strip()}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON from command: {' '.join(cmd)}") from exc


def ensure_dirs(base: Path) -> dict[str, Path]:
    paths = {
        "root": base,
        "metrics": base / "metrics",
        "reports": base / "reports",
        "experiments": base / "experiments",
        "evals": base / "evals",
    }
    for p in paths.values():
        p.mkdir(parents=True, exist_ok=True)
    return paths


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


def append_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        return
    with path.open("a", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=True) + "\n")


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=True), encoding="utf-8")


def now_utc() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def ts_to_iso(ts_ms: int | None) -> str:
    if not ts_ms:
        return ""
    return dt.datetime.fromtimestamp(ts_ms / 1000, tz=dt.timezone.utc).isoformat()


def normalize_model_ref(provider: str | None, model: str | None) -> str:
    p = (provider or "").strip()
    m = (model or "").strip()
    if not p:
        return m
    if "/" in m:
        return m
    return f"{p}/{m}"


def resolve_alias(configured: str, aliases: dict[str, str]) -> str:
    return aliases.get(configured, configured)


def token_total(entry: dict[str, Any]) -> int:
    usage = entry.get("usage") or {}
    if "total_tokens" in usage and isinstance(usage["total_tokens"], int):
        return usage["total_tokens"]
    if "total" in usage and isinstance(usage["total"], int):
        return usage["total"]
    inp = usage.get("input_tokens") or usage.get("input") or 0
    out = usage.get("output_tokens") or usage.get("output") or 0
    cache = usage.get("cacheRead") or 0
    try:
        return int(inp) + int(out) + int(cache)
    except (TypeError, ValueError):
        return 0


def duration_ms(entry: dict[str, Any]) -> int:
    raw = entry.get("durationMs")
    return int(raw) if isinstance(raw, (int, float)) else 0


def gather_runs(profile: str, limit_per_job: int) -> tuple[list[dict[str, Any]], dict[str, str]]:
    jobs_payload = run_json(["openclaw", "--profile", profile, "cron", "list", "--all", "--json"])
    model_status = run_json(["openclaw", "--profile", profile, "models", "status", "--json"])
    aliases: dict[str, str] = model_status.get("aliases") or {}

    rows: list[dict[str, Any]] = []
    jobs = jobs_payload.get("jobs") or []
    for job in jobs:
        job_id = job.get("id")
        if not job_id:
            continue
        runs_payload = run_json(
            ["openclaw", "--profile", profile, "cron", "runs", "--id", str(job_id), "--limit", str(limit_per_job)]
        )
        entries = runs_payload.get("entries") or []
        for entry in entries:
            run_at = entry.get("runAtMs")
            session_id = entry.get("sessionId") or ""
            uid = f"{job_id}:{run_at}:{session_id}"
            configured_model = (job.get("payload") or {}).get("model") or ""
            expected_model = resolve_alias(configured_model, aliases)
            actual_model = normalize_model_ref(entry.get("provider"), entry.get("model"))
            row = {
                "uid": uid,
                "jobId": job_id,
                "jobName": job.get("name") or "",
                "status": entry.get("status") or "unknown",
                "ts": int(entry.get("ts") or 0),
                "runAtMs": int(run_at or 0),
                "runAtIso": ts_to_iso(int(run_at or 0)),
                "durationMs": duration_ms(entry),
                "provider": entry.get("provider") or "",
                "model": entry.get("model") or "",
                "actualModelRef": actual_model,
                "configuredModel": configured_model,
                "expectedModelRef": expected_model,
                "modelMismatch": bool(expected_model) and bool(actual_model) and (expected_model != actual_model),
                "totalTokens": token_total(entry),
                "delivered": bool(entry.get("delivered")),
                "deliveryStatus": entry.get("deliveryStatus") or "unknown",
                "sessionId": session_id,
                "summary": entry.get("summary") or "",
                "error": entry.get("error") or "",
            }
            rows.append(row)
    return rows, aliases


def aggregate(window_rows: list[dict[str, Any]], min_sample: int) -> dict[str, Any]:
    total = len(window_rows)
    ok = sum(1 for r in window_rows if r["status"] == "ok")
    err = total - ok
    success_rate = (ok / total) if total else 0.0
    durations = [r["durationMs"] for r in window_rows if r["durationMs"] > 0]
    tokens = [r["totalTokens"] for r in window_rows if r["totalTokens"] > 0]
    mismatch_count = sum(1 for r in window_rows if r["modelMismatch"])
    delivery_fail = sum(1 for r in window_rows if r["deliveryStatus"] not in ("delivered", "not-delivered", "unknown"))

    by_job: dict[str, dict[str, Any]] = {}
    for row in window_rows:
        key = row["jobName"] or row["jobId"]
        item = by_job.setdefault(
            key,
            {
                "runs": 0,
                "ok": 0,
                "errors": 0,
                "durationMs": [],
                "tokens": [],
                "mismatch": 0,
                "deliveryFailures": 0,
                "configuredModel": row["configuredModel"],
                "actualModelRefs": {},
            },
        )
        item["runs"] += 1
        if row["status"] == "ok":
            item["ok"] += 1
        else:
            item["errors"] += 1
        if row["durationMs"] > 0:
            item["durationMs"].append(row["durationMs"])
        if row["totalTokens"] > 0:
            item["tokens"].append(row["totalTokens"])
        if row["modelMismatch"]:
            item["mismatch"] += 1
        if row["deliveryStatus"] not in ("delivered", "not-delivered", "unknown"):
            item["deliveryFailures"] += 1
        model_ref = row["actualModelRef"] or "unknown"
        item["actualModelRefs"][model_ref] = item["actualModelRefs"].get(model_ref, 0) + 1

    job_metrics: list[dict[str, Any]] = []
    for name, item in by_job.items():
        runs = item["runs"]
        avg_duration = int(statistics.mean(item["durationMs"])) if item["durationMs"] else 0
        avg_tokens = int(statistics.mean(item["tokens"])) if item["tokens"] else 0
        job_metrics.append(
            {
                "job": name,
                "runs": runs,
                "successRate": round(item["ok"] / runs, 3) if runs else 0.0,
                "avgDurationMs": avg_duration,
                "avgTokens": avg_tokens,
                "modelMismatchRuns": item["mismatch"],
                "deliveryFailures": item["deliveryFailures"],
                "configuredModel": item["configuredModel"],
                "topActualModel": max(item["actualModelRefs"], key=item["actualModelRefs"].get),
                "actualModelCounts": item["actualModelRefs"],
            }
        )
    job_metrics.sort(key=lambda x: x["runs"], reverse=True)

    recommendations: list[dict[str, Any]] = []
    for jm in job_metrics:
        if jm["runs"] < min_sample:
            continue
        if jm["modelMismatchRuns"] > 0:
            recommendations.append(
                {
                    "priority": "high",
                    "type": "routing",
                    "job": jm["job"],
                    "issue": "Configured model does not match runtime model consistently.",
                    "change": "Pin payload.model to explicit provider/model and verify provider health.",
                    "targetMetric": "modelMismatchRuns=0 over next 5 runs",
                }
            )
        if jm["successRate"] < 0.9:
            recommendations.append(
                {
                    "priority": "high",
                    "type": "reliability",
                    "job": jm["job"],
                    "issue": f"Success rate is {jm['successRate']:.0%}.",
                    "change": "Shorten prompt scope and add deterministic pre-check steps.",
                    "targetMetric": "successRate>=95% over next 10 runs",
                }
            )
        if jm["avgDurationMs"] > 240000:
            recommendations.append(
                {
                    "priority": "medium",
                    "type": "latency",
                    "job": jm["job"],
                    "issue": f"Average duration is {jm['avgDurationMs']/1000:.0f}s.",
                    "change": "Reduce injected context and split long jobs into 2 stages.",
                    "targetMetric": "avgDurationMs reduced by 30%",
                }
            )
        if jm["avgTokens"] > 15000:
            recommendations.append(
                {
                    "priority": "medium",
                    "type": "cost",
                    "job": jm["job"],
                    "issue": f"Average tokens per run is {jm['avgTokens']}.",
                    "change": "Trim system context for this lane and add explicit output length caps.",
                    "targetMetric": "avgTokens reduced by 20%",
                }
            )

    recommendations = sorted(
        recommendations,
        key=lambda r: (0 if r["priority"] == "high" else 1, r["job"], r["type"]),
    )[:6]

    return {
        "window": {
            "runs": total,
            "success": ok,
            "errors": err,
            "successRate": round(success_rate, 3),
            "avgDurationMs": int(statistics.mean(durations)) if durations else 0,
            "p95DurationMs": int(sorted(durations)[max(int(len(durations) * 0.95) - 1, 0)]) if durations else 0,
            "avgTokens": int(statistics.mean(tokens)) if tokens else 0,
            "totalTokens": sum(tokens),
            "modelMismatchRuns": mismatch_count,
            "deliveryFailures": delivery_fail,
        },
        "jobs": job_metrics,
        "recommendations": recommendations,
    }


def render_markdown(summary: dict[str, Any], generated_at: str, days: int) -> str:
    window = summary["window"]
    lines: list[str] = []
    lines.append("# Self-Improvement Report")
    lines.append("")
    lines.append(f"- Generated: {generated_at}")
    lines.append(f"- Window: last {days} days")
    lines.append("")
    lines.append("## Snapshot")
    lines.append("")
    lines.append(f"- Runs: {window['runs']}")
    lines.append(f"- Success rate: {window['successRate']:.0%}")
    lines.append(f"- Avg duration: {window['avgDurationMs']/1000:.1f}s")
    lines.append(f"- P95 duration: {window['p95DurationMs']/1000:.1f}s")
    lines.append(f"- Avg tokens: {window['avgTokens']}")
    lines.append(f"- Total tokens: {window['totalTokens']}")
    lines.append(f"- Model mismatches: {window['modelMismatchRuns']}")
    lines.append("")
    lines.append("## Job Metrics")
    lines.append("")
    for jm in summary["jobs"][:10]:
        lines.append(
            f"- `{jm['job']}` runs={jm['runs']} success={jm['successRate']:.0%} "
            f"avgDuration={jm['avgDurationMs']/1000:.1f}s avgTokens={jm['avgTokens']} "
            f"configured={jm['configuredModel'] or '-'} actual={jm['topActualModel']}"
        )
    lines.append("")
    lines.append("## Top Experiments")
    lines.append("")
    if not summary["recommendations"]:
        lines.append("- No urgent optimization experiments detected in this window.")
    else:
        for idx, rec in enumerate(summary["recommendations"], start=1):
            lines.append(f"{idx}. [{rec['priority'].upper()}] `{rec['job']}` {rec['type']}")
            lines.append(f"   - Issue: {rec['issue']}")
            lines.append(f"   - Change: {rec['change']}")
            lines.append(f"   - Target: {rec['targetMetric']}")
    lines.append("")
    lines.append("## One-Line Focus")
    lines.append("")
    if summary["recommendations"]:
        top = summary["recommendations"][0]
        lines.append(f"Run experiment: {top['job']} -> {top['change']}")
    else:
        lines.append("Keep current configuration and collect more runs for signal.")
    lines.append("")
    return "\n".join(lines)


def recommend_to_backlog(
    recommendations: list[dict[str, Any]],
    generated_at: str,
    backlog_path: Path,
) -> int:
    existing = read_jsonl(backlog_path)
    existing_keys = {(r.get("job"), r.get("type"), r.get("change")) for r in existing}
    rows: list[dict[str, Any]] = []
    for rec in recommendations:
        key = (rec.get("job"), rec.get("type"), rec.get("change"))
        if key in existing_keys:
            continue
        rows.append(
            {
                "id": f"exp-{generated_at[:10]}-{abs(hash(key)) % 100000:05d}",
                "status": "proposed",
                "createdAt": generated_at,
                "job": rec.get("job"),
                "type": rec.get("type"),
                "priority": rec.get("priority"),
                "issue": rec.get("issue"),
                "change": rec.get("change"),
                "targetMetric": rec.get("targetMetric"),
            }
        )
    append_jsonl(backlog_path, rows)
    return len(rows)


def main() -> int:
    args = parse_args()
    workspace = Path(args.workspace).expanduser().resolve()
    self_dir = workspace / "self-improvement"
    paths = ensure_dirs(self_dir)
    runs_path = paths["metrics"] / "cron-runs.jsonl"
    summary_path = paths["metrics"] / "latest-summary.json"
    backlog_path = paths["experiments"] / "backlog.jsonl"

    generated_at = now_utc().isoformat()
    horizon_ms = int((now_utc() - dt.timedelta(days=args.days)).timestamp() * 1000)

    rows, aliases = gather_runs(args.profile, args.limit_per_job)
    existing_rows = read_jsonl(runs_path)
    existing_ids = {r.get("uid") for r in existing_rows}
    new_rows = [r for r in rows if r.get("uid") not in existing_ids]
    append_jsonl(runs_path, new_rows)

    all_rows = existing_rows + new_rows
    window_rows = [r for r in all_rows if int(r.get("runAtMs") or 0) >= horizon_ms]
    summary = aggregate(window_rows, args.min_sample)
    summary["generatedAt"] = generated_at
    summary["profile"] = args.profile
    summary["aliases"] = aliases
    summary["newRowsIngested"] = len(new_rows)
    write_json(summary_path, summary)

    report_date = generated_at[:10]
    report_md = render_markdown(summary, generated_at, args.days)
    report_path = paths["reports"] / f"{report_date}.md"
    latest_report = paths["reports"] / "latest.md"
    report_path.write_text(report_md, encoding="utf-8")
    latest_report.write_text(report_md, encoding="utf-8")

    new_experiments = recommend_to_backlog(summary["recommendations"], generated_at, backlog_path)

    print(
        json.dumps(
            {
                "ok": True,
                "profile": args.profile,
                "newRowsIngested": len(new_rows),
                "windowRuns": summary["window"]["runs"],
                "successRate": summary["window"]["successRate"],
                "report": str(report_path),
                "latestReport": str(latest_report),
                "newExperiments": new_experiments,
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
