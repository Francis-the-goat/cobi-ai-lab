#!/usr/bin/env python3
"""Auto-promote or rollback self-improvement experiments with guardrails."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


PRIORITY_ORDER = {"high": 0, "medium": 1, "low": 2}
SUPPORTED_TYPES = {"routing", "reliability", "cost", "latency"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Apply/rollback safe self-improvement experiments.")
    parser.add_argument("--profile", default="dev", help="OpenClaw profile (default: dev)")
    parser.add_argument(
        "--workspace",
        default=str(Path.home() / ".openclaw" / "workspace"),
        help="Workspace root path",
    )
    parser.add_argument("--min-new-runs", type=int, default=2, help="Runs required after activation before evaluation")
    parser.add_argument("--dry-run", action="store_true", help="Do not apply edits, only report decisions")
    return parser.parse_args()


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def run_json(cmd: list[str]) -> dict[str, Any]:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)} :: {proc.stderr.strip()}")
    return json.loads(proc.stdout)


def run_cmd(cmd: list[str]) -> str:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)} :: {proc.stderr.strip()}")
    return proc.stdout.strip()


def read_json(path: Path, default: dict[str, Any] | None = None) -> dict[str, Any]:
    if not path.exists():
        return default or {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return default or {}


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
    data = "\n".join(json.dumps(r, ensure_ascii=True) for r in rows) + ("\n" if rows else "")
    path.write_text(data, encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def get_job_map(profile: str) -> dict[str, dict[str, Any]]:
    payload = run_json(["openclaw", "--profile", profile, "cron", "list", "--all", "--json"])
    jobs = payload.get("jobs") or []
    out: dict[str, dict[str, Any]] = {}
    for j in jobs:
        out[j.get("name") or ""] = j
    return out


def get_job_metric(summary: dict[str, Any], job_name: str) -> dict[str, Any] | None:
    for jm in summary.get("jobs", []):
        if jm.get("job") == job_name:
            return jm
    return None


def infer_action(
    exp: dict[str, Any],
    metric: dict[str, Any] | None,
    workspace: Path,
) -> dict[str, Any] | None:
    etype = exp.get("type")
    job = exp.get("job")
    if etype == "routing" and metric:
        configured = metric.get("configuredModel") or ""
        if configured:
            return {"kind": "set_cron_model", "model": configured}
    if etype in {"reliability", "cost"} and job == "foundry-daily-build-candidate":
        lean_prompt = workspace / "self-improvement" / "config" / "prompts" / "foundry_lean.txt"
        if lean_prompt.exists():
            return {"kind": "set_cron_message_file", "path": str(lean_prompt)}
    return None


def apply_action(
    profile: str,
    job_id: str,
    action: dict[str, Any],
    current_payload: dict[str, Any],
    dry_run: bool,
) -> dict[str, Any]:
    rollback = {
        "priorModel": current_payload.get("model") or "",
        "priorMessage": current_payload.get("message") or "",
    }

    kind = action.get("kind")
    if dry_run:
        return rollback

    if kind == "set_cron_model":
        model = action.get("model") or ""
        if not model:
            raise RuntimeError("set_cron_model requires model")
        run_cmd(["openclaw", "--profile", profile, "cron", "edit", job_id, "--model", model])
    elif kind == "set_cron_message_file":
        path = action.get("path") or ""
        message = Path(path).read_text(encoding="utf-8").strip()
        run_cmd(["openclaw", "--profile", profile, "cron", "edit", job_id, "--message", message])
    else:
        raise RuntimeError(f"Unsupported action kind: {kind}")

    return rollback


def rollback_action(
    profile: str,
    job_id: str,
    rollback: dict[str, Any],
    dry_run: bool,
) -> None:
    if dry_run:
        return
    prior_model = rollback.get("priorModel") or ""
    prior_message = rollback.get("priorMessage") or ""
    if prior_model:
        run_cmd(["openclaw", "--profile", profile, "cron", "edit", job_id, "--model", prior_model])
    if prior_message:
        run_cmd(["openclaw", "--profile", profile, "cron", "edit", job_id, "--message", prior_message])


def evaluate(exp: dict[str, Any], metric: dict[str, Any], min_new_runs: int) -> tuple[str, str]:
    baseline = exp.get("baseline") or {}
    baseline_runs = int(baseline.get("runs") or 0)
    current_runs = int(metric.get("runs") or 0)
    runs_after = current_runs - baseline_runs
    if runs_after < min_new_runs:
        return "hold", f"Need {min_new_runs} new runs after activation (have {runs_after})."

    etype = exp.get("type")
    if etype == "routing":
        mismatches = int(metric.get("modelMismatchRuns") or 0)
        if mismatches == 0:
            return "promote", "No model mismatch detected."
        return "rollback", f"Model mismatch persists ({mismatches} runs)."
    if etype == "reliability":
        sr = float(metric.get("successRate") or 0.0)
        if sr >= 0.95:
            return "promote", f"Success rate reached {sr:.0%}."
        if sr < 0.70:
            return "rollback", f"Success rate dropped to {sr:.0%}."
        return "hold", f"Success rate {sr:.0%} not yet at threshold."
    if etype == "cost":
        baseline_tokens = int(baseline.get("avgTokens") or 0)
        current_tokens = int(metric.get("avgTokens") or 0)
        if baseline_tokens <= 0:
            return "hold", "No baseline tokens available."
        if current_tokens <= int(baseline_tokens * 0.8):
            return "promote", f"Token usage improved ({baseline_tokens} -> {current_tokens})."
        if current_tokens >= int(baseline_tokens * 1.1):
            return "rollback", f"Token usage regressed ({baseline_tokens} -> {current_tokens})."
        return "hold", f"Token delta inconclusive ({baseline_tokens} -> {current_tokens})."
    if etype == "latency":
        baseline_ms = int(baseline.get("avgDurationMs") or 0)
        current_ms = int(metric.get("avgDurationMs") or 0)
        if baseline_ms <= 0:
            return "hold", "No baseline duration available."
        if current_ms <= int(baseline_ms * 0.7):
            return "promote", f"Latency improved ({baseline_ms} -> {current_ms} ms)."
        if current_ms >= int(baseline_ms * 1.1):
            return "rollback", f"Latency regressed ({baseline_ms} -> {current_ms} ms)."
        return "hold", f"Latency delta inconclusive ({baseline_ms} -> {current_ms} ms)."

    return "hold", "Unsupported experiment type for auto-evaluation."


def main() -> int:
    args = parse_args()
    workspace = Path(args.workspace).expanduser().resolve()
    root = workspace / "self-improvement"
    backlog_path = root / "experiments" / "backlog.jsonl"
    summary_path = root / "metrics" / "latest-summary.json"
    report_path = root / "reports" / "auto-promotion-latest.md"

    backlog = read_jsonl(backlog_path)
    summary = read_json(summary_path, default={})
    jobs = get_job_map(args.profile)

    if not backlog:
        write_text(report_path, "# Auto-Promotion Report\n\nNo experiments found.\n")
        print(json.dumps({"ok": True, "status": "no_experiments"}))
        return 0

    active = next((e for e in backlog if e.get("status") == "active"), None)
    actions_log: list[str] = []

    if active is None:
        candidates = [
            e
            for e in backlog
            if e.get("status", "proposed") == "proposed" and e.get("type") in SUPPORTED_TYPES
        ]
        candidates.sort(key=lambda e: (PRIORITY_ORDER.get(str(e.get("priority", "medium")).lower(), 9), e.get("createdAt", "")))
        if candidates:
            exp = candidates[0]
            job_name = exp.get("job") or ""
            job = jobs.get(job_name)
            metric = get_job_metric(summary, job_name)
            action = infer_action(exp, metric, workspace)
            if not job:
                exp["status"] = "blocked"
                exp["blockedReason"] = "job_not_found"
                exp["updatedAt"] = now_iso()
                actions_log.append(f"Blocked {exp.get('id')} (job not found).")
            elif not action:
                exp["status"] = "manual_required"
                exp["blockedReason"] = "no_safe_auto_action"
                exp["updatedAt"] = now_iso()
                actions_log.append(f"Manual required for {exp.get('id')} (no safe action mapping).")
            else:
                payload = (job.get("payload") or {})
                rollback = apply_action(args.profile, job.get("id"), action, payload, args.dry_run)
                exp["status"] = "active"
                exp["startedAt"] = now_iso()
                exp["updatedAt"] = exp["startedAt"]
                if metric:
                    exp["baseline"] = {
                        "runs": metric.get("runs", 0),
                        "successRate": metric.get("successRate", 0.0),
                        "avgDurationMs": metric.get("avgDurationMs", 0),
                        "avgTokens": metric.get("avgTokens", 0),
                        "modelMismatchRuns": metric.get("modelMismatchRuns", 0),
                    }
                exp["applied"] = {
                    "action": action,
                    "jobId": job.get("id"),
                    "rollback": rollback,
                    "dryRun": args.dry_run,
                }
                actions_log.append(f"Activated {exp.get('id')} with action {action.get('kind')}.")
                active = exp

    if active is not None:
        job_name = active.get("job") or ""
        metric = get_job_metric(summary, job_name)
        if metric:
            decision, reason = evaluate(active, metric, args.min_new_runs)
            active["lastEvaluationAt"] = now_iso()
            active["lastEvaluationReason"] = reason
            active["lastEvaluationDecision"] = decision
            if decision == "promote":
                active["status"] = "promoted"
                active["endedAt"] = now_iso()
                active["result"] = {
                    "decision": "promoted",
                    "metricSnapshot": metric,
                }
                actions_log.append(f"Promoted {active.get('id')}: {reason}")
            elif decision == "rollback":
                applied = active.get("applied") or {}
                rollback = applied.get("rollback") or {}
                job_id = applied.get("jobId") or ""
                if job_id:
                    rollback_action(args.profile, job_id, rollback, args.dry_run)
                active["status"] = "rolled_back"
                active["endedAt"] = now_iso()
                active["result"] = {
                    "decision": "rolled_back",
                    "reason": reason,
                    "metricSnapshot": metric,
                }
                actions_log.append(f"Rolled back {active.get('id')}: {reason}")
            else:
                actions_log.append(f"Holding {active.get('id')}: {reason}")
        else:
            actions_log.append(f"No metrics yet for active experiment {active.get('id')}.")

    write_jsonl(backlog_path, backlog)

    report_lines = [
        "# Auto-Promotion Report",
        "",
        f"- Generated: {now_iso()}",
        f"- Dry run: {'yes' if args.dry_run else 'no'}",
        "",
        "## Actions",
        "",
    ]
    if actions_log:
        report_lines.extend([f"- {line}" for line in actions_log])
    else:
        report_lines.append("- No changes.")
    report_lines.append("")

    write_text(report_path, "\n".join(report_lines) + "\n")
    print(json.dumps({"ok": True, "actions": actions_log, "report": str(report_path)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
