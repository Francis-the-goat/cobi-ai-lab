#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import statistics
import subprocess
from pathlib import Path
from typing import Any


def utc_now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def run_json(cmd: list[str]) -> dict[str, Any]:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"command failed: {' '.join(cmd)}\n{proc.stderr.strip()}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"invalid json from: {' '.join(cmd)}") from exc


def fmt_pct(value: float) -> str:
    return f"{value * 100:.0f}%"


def run_cutoff(days: int) -> int:
    return int((utc_now() - dt.timedelta(days=days)).timestamp() * 1000)


def score_summary_structure(summary: str) -> tuple[int, int]:
    if not summary:
        return 0, 3
    score = 0
    lower = summary.lower()
    if "decision" in lower:
        score += 1
    if "top 3" in lower or "next action" in lower:
        score += 1
    if "track" in lower:
        score += 1
    return score, 3


def score_summary_genericness(summary: str) -> tuple[int, int]:
    if not summary:
        return 0, 1
    lower = summary.lower()
    generic_phrases = [
        "great progress",
        "interesting",
        "good insight",
        "keep going",
        "you should consider",
        "high level",
    ]
    hit = any(p in lower for p in generic_phrases)
    return (0, 1) if hit else (1, 1)


def is_structure_exempt(job_name: str) -> bool:
    exempt = {
        "transcription-retry-worker",
        "quality-weekly-audit",
    }
    return job_name in exempt


def job_metrics(entries: list[dict[str, Any]], cutoff_ms: int, structure_exempt: bool) -> dict[str, Any]:
    scoped = [e for e in entries if int(e.get("runAtMs") or 0) >= cutoff_ms]
    total = len(scoped)
    if total == 0:
        return {
            "total": 0,
            "ok": 0,
            "err": 0,
            "delivered": 0,
            "reliability": 1.0,
            "delivery": 1.0,
            "median_ms": 0,
            "structure": 1.0,
            "specificity": 1.0,
            "score": 85.0,
            "last_error": "",
            "structure_exempt": structure_exempt,
        }
    ok = sum(1 for e in scoped if e.get("status") == "ok")
    err = sum(1 for e in scoped if e.get("status") == "error")
    delivered = sum(1 for e in scoped if e.get("deliveryStatus") == "delivered" or e.get("delivered") is True)
    durations = [int(e.get("durationMs") or 0) for e in scoped if int(e.get("durationMs") or 0) > 0]
    median_ms = int(statistics.median(durations)) if durations else 0

    structure_have = 0
    structure_total = 0
    generic_have = 0
    generic_total = 0
    for e in scoped:
        if e.get("status") != "ok":
            continue
        summary = str(e.get("summary") or "")
        s_have, s_total = score_summary_structure(summary)
        g_have, g_total = score_summary_genericness(summary)
        structure_have += s_have
        structure_total += s_total
        generic_have += g_have
        generic_total += g_total

    reliability = (ok / total) if total else 1.0
    delivery = (delivered / total) if total else 1.0
    structure = (structure_have / structure_total) if structure_total else (1.0 if structure_exempt else 0.5)
    specificity = (generic_have / generic_total) if generic_total else 0.5

    # Score out of 100
    duration_score = 1.0
    if median_ms > 0:
        if median_ms > 600000:
            duration_score = 0.1
        elif median_ms > 300000:
            duration_score = 0.5
        elif median_ms > 120000:
            duration_score = 0.8
    quality_mix = (structure * 0.6) + (specificity * 0.4)
    score = (
        reliability * 45
        + delivery * 20
        + duration_score * 15
        + quality_mix * 20
    )

    last_error = ""
    for e in reversed(scoped):
        if e.get("status") == "error":
            last_error = str(e.get("error") or "")
            break

    return {
        "total": total,
        "ok": ok,
        "err": err,
        "delivered": delivered,
        "reliability": reliability,
        "delivery": delivery,
        "median_ms": median_ms,
        "structure": structure,
        "specificity": specificity,
        "score": score,
        "last_error": last_error,
        "structure_exempt": structure_exempt,
    }


def priority_findings(job_rows: list[dict[str, Any]]) -> list[tuple[str, str]]:
    findings: list[tuple[str, str]] = []
    for row in sorted(job_rows, key=lambda r: r["metrics"]["score"]):
        m = row["metrics"]
        name = row["name"]
        if m["total"] == 0:
            continue
        if m["total"] >= 2 and m["reliability"] < 0.7:
            findings.append(("P1", f"`{name}` reliability is {fmt_pct(m['reliability'])} over recent runs."))
        if m["median_ms"] >= 300000:
            findings.append(("P1", f"`{name}` median runtime is {m['median_ms']}ms (timeout risk)."))
        if (not m.get("structure_exempt")) and m["structure"] < 0.5:
            findings.append(("P2", f"`{name}` output structure compliance is low ({fmt_pct(m['structure'])})."))
        if m["specificity"] < 0.6:
            findings.append(("P2", f"`{name}` outputs are trending generic ({fmt_pct(m['specificity'])} specificity)."))
        if m["delivery"] < 0.7:
            findings.append(("P2", f"`{name}` delivery success is only {fmt_pct(m['delivery'])}."))
        if m["last_error"]:
            findings.append(("P3", f"`{name}` latest error: {m['last_error'][:140]}"))
    if not findings:
        findings.append(("P3", "No critical findings in the current audit window."))
    return findings[:12]


def recommendations(findings: list[tuple[str, str]]) -> list[str]:
    recs: list[str] = []
    text = " ".join(f[1].lower() for f in findings)
    if "timeout" in text or "runtime" in text:
        recs.append("Move long-running workers to fewer runs/day and cap batch size per run.")
    if "reliability" in text:
        recs.append("Pin flaky jobs to a more stable model lane and simplify prompt scope.")
    if "structure compliance" in text:
        recs.append("Force `OUTPUT_STANDARD.md` headings in cron prompts and reject non-compliant drafts.")
    if "generic" in text:
        recs.append("Add explicit evidence requirement in prompts: at least one metric or source per finding.")
    if "delivery success" in text:
        recs.append("Keep a single Telegram poller/profile active and monitor deliveryStatus weekly.")
    if not recs:
        recs.append("Maintain current settings; no urgent prompt/model changes required this week.")
    return recs[:5]


def write_report(
    report_path: Path,
    profile: str,
    days: int,
    overall_score: float,
    rows: list[dict[str, Any]],
    findings: list[tuple[str, str]],
    recs: list[str],
) -> None:
    lines: list[str] = []
    today = dt.date.today().isoformat()
    lines.append(f"# Agent Quality Audit - {today}")
    lines.append("")
    lines.append("## Scope")
    lines.append(f"- Profile: `{profile}`")
    lines.append(f"- Window: last `{days}` days")
    lines.append(f"- Overall score: `{overall_score:.1f}/100`")
    lines.append("")
    lines.append("## Job Scores")
    lines.append("| Job | Runs | Reliability | Delivery | Median ms | Score |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for row in sorted(rows, key=lambda r: r["metrics"]["score"]):
        m = row["metrics"]
        lines.append(
            f"| {row['name']} | {m['total']} | {fmt_pct(m['reliability'])} | {fmt_pct(m['delivery'])} | "
            f"{m['median_ms']} | {m['score']:.1f} |"
        )
    lines.append("")
    lines.append("## Findings")
    for sev, finding in findings:
        lines.append(f"- `{sev}` {finding}")
    lines.append("")
    lines.append("## Recommended Fixes")
    for i, rec in enumerate(recs, 1):
        lines.append(f"{i}. {rec}")
    lines.append("")
    lines.append("## Next Review")
    lines.append("- Re-run this audit after 7 days and compare score delta.")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description="Weekly quality audit for OpenClaw cron jobs.")
    ap.add_argument("--profile", default="dev")
    ap.add_argument("--workspace", default=str(Path.home() / ".openclaw" / "workspace"))
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--history-limit", type=int, default=20)
    args = ap.parse_args()

    workspace = Path(args.workspace).expanduser().resolve()
    cutoff_ms = run_cutoff(args.days)

    jobs = run_json(["openclaw", "--profile", args.profile, "cron", "list", "--all", "--json"]).get("jobs", [])
    rows: list[dict[str, Any]] = []

    for job in jobs:
        jid = str(job.get("id") or "")
        name = str(job.get("name") or jid)
        runs = run_json(
            [
                "openclaw",
                "--profile",
                args.profile,
                "cron",
                "runs",
                "--id",
                jid,
                "--limit",
                str(args.history_limit),
            ]
        ).get("entries", [])
        rows.append(
            {
                "id": jid,
                "name": name,
                "metrics": job_metrics(runs, cutoff_ms, structure_exempt=is_structure_exempt(name)),
            }
        )

    if not rows:
        raise RuntimeError("No cron jobs found to audit.")

    overall_score = sum(r["metrics"]["score"] for r in rows) / len(rows)
    findings = priority_findings(rows)
    recs = recommendations(findings)

    date_tag = dt.date.today().isoformat()
    report_dir = workspace / "memory" / "reports"
    report_path = report_dir / f"{date_tag}-agent-quality-audit.md"
    latest_path = report_dir / "latest-agent-quality-audit.md"
    write_report(report_path, args.profile, args.days, overall_score, rows, findings, recs)
    latest_path.write_text(report_path.read_text(encoding="utf-8"), encoding="utf-8")

    print(
        f"audit_status=ok profile={args.profile} score={overall_score:.1f} "
        f"report={report_path} latest={latest_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
