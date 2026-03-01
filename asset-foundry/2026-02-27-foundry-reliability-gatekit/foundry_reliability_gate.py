#!/usr/bin/env python3
"""
Foundry Reliability Gate

Purpose:
- Parse a self-improvement ledger markdown file
- Extract routing mismatch count and foundry success rate
- Evaluate release gate status for build-lane readiness

Gate rules (default):
1) model mismatches <= 0
2) foundry success rate >= 95
3) post-activation runs >= 2

Usage:
  python3 foundry_reliability_gate.py \
    --ledger /Users/cobi/.openclaw/workspace/memory/2026-02-25.md \
    --job foundry-daily-build-candidate \
    --min-success 95 \
    --max-mismatch 0 \
    --min-post-runs 2 \
    --out /Users/cobi/.openclaw/workspace/memory/reports/latest-foundry-gate-report.md
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def parse_percent(value: str) -> int | None:
    m = re.search(r"(\d+)%", value)
    return int(m.group(1)) if m else None


def extract_model_mismatches(text: str) -> int | None:
    m = re.search(r"\|\s*Model mismatches\s*\|\s*(\d+)\s*\|", text)
    return int(m.group(1)) if m else None


def extract_foundry_success(text: str, job: str) -> int | None:
    # Matches table row like:
    # | `foundry-daily-build-candidate` | 3 | 67% | ...
    pattern = rf"\|\s*`{re.escape(job)}`\s*\|\s*\d+\s*\|\s*([^|]+)\|"
    m = re.search(pattern, text)
    if not m:
        return None
    return parse_percent(m.group(1))


def extract_post_activation_runs(text: str) -> int | None:
    m = re.search(r"Required:\s*(\d+)\s*runs.*?Current:\s*(\d+)\s*runs", text, re.S)
    if not m:
        return None
    return int(m.group(2))


def evaluate(mismatches, foundry_success, post_runs, max_mismatch, min_success, min_post_runs):
    checks = {
        "routing_mismatch_gate": mismatches is not None and mismatches <= max_mismatch,
        "foundry_success_gate": foundry_success is not None and foundry_success >= min_success,
        "post_activation_runs_gate": post_runs is not None and post_runs >= min_post_runs,
    }
    passed = all(checks.values())
    return passed, checks


def build_report(ledger_path, mismatches, foundry_success, post_runs, checks, passed, args):
    status = "PASS" if passed else "HOLD"
    lines = [
        f"# Foundry Reliability Gate Report",
        "",
        f"- Ledger: `{ledger_path}`",
        f"- Job: `{args.job}`",
        f"- Status: **{status}**",
        "",
        "## Inputs",
        f"- Model mismatches: {mismatches if mismatches is not None else 'not found'}",
        f"- Foundry success rate: {str(foundry_success) + '%' if foundry_success is not None else 'not found'}",
        f"- Post-activation runs: {post_runs if post_runs is not None else 'not found'}",
        "",
        "## Gate thresholds",
        f"- max mismatch: <= {args.max_mismatch}",
        f"- min success: >= {args.min_success}%",
        f"- min post-activation runs: >= {args.min_post_runs}",
        "",
        "## Check results",
        f"- routing_mismatch_gate: {'PASS' if checks['routing_mismatch_gate'] else 'FAIL'}",
        f"- foundry_success_gate: {'PASS' if checks['foundry_success_gate'] else 'FAIL'}",
        f"- post_activation_runs_gate: {'PASS' if checks['post_activation_runs_gate'] else 'FAIL'}",
        "",
        "## Decision",
        ("BUILD UNBLOCKED: proceed with Asset Builder lane." if passed else
         "HOLD: keep SYSTEM as primary until all gates pass."),
    ]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description="Evaluate foundry reliability gate from ledger markdown")
    parser.add_argument("--ledger", required=True, help="Path to self-improvement ledger markdown")
    parser.add_argument("--job", default="foundry-daily-build-candidate")
    parser.add_argument("--min-success", type=int, default=95)
    parser.add_argument("--max-mismatch", type=int, default=0)
    parser.add_argument("--min-post-runs", type=int, default=2)
    parser.add_argument("--out", default="")
    args = parser.parse_args()

    ledger_path = Path(args.ledger)
    text = ledger_path.read_text(encoding="utf-8")

    mismatches = extract_model_mismatches(text)
    foundry_success = extract_foundry_success(text, args.job)
    post_runs = extract_post_activation_runs(text)

    passed, checks = evaluate(
        mismatches,
        foundry_success,
        post_runs,
        args.max_mismatch,
        args.min_success,
        args.min_post_runs,
    )

    report = build_report(ledger_path, mismatches, foundry_success, post_runs, checks, passed, args)

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(report, encoding="utf-8")

    print(report, end="")


if __name__ == "__main__":
    main()
