# SELF_IMPROVEMENT_OS.md — Evidence-Based Agent Upgrades

Last updated: 2026-02-25

## Objective

Make the agent better every week using measured outcomes, not intuition.

## Improvement Loop

1. Capture run data from OpenClaw cron history
2. Compute quality/cost/speed metrics
3. Detect bottlenecks and routing mismatches
4. Propose concrete experiments
5. Apply one change at a time
6. Verify improvement before promoting

## Core Metrics

- Success rate
- Avg and P95 runtime
- Avg and total token usage
- Delivery reliability
- Model-routing mismatches (configured vs actual)

## Files

```
self-improvement/
├── metrics/
│   ├── cron-runs.jsonl
│   └── latest-summary.json
├── reports/
│   ├── YYYY-MM-DD.md
│   └── latest.md
├── experiments/
│   └── backlog.jsonl
└── evals/
    └── benchmark_tasks.jsonl
```

## Commands

Run full loop (sync + experiment activation/evaluation):

```bash
bash ~/.openclaw/workspace/scripts/self_improvement_autoloop.sh dev 7 2
```

Run sync-only cycle:

```bash
bash ~/.openclaw/workspace/scripts/self_improvement_cycle.sh dev 7
```

Run auto-promotion directly:

```bash
python3 ~/.openclaw/workspace/scripts/self_improvement_autopromote.py --profile dev --workspace ~/.openclaw/workspace --min-new-runs 2
```

Or run sync directly:

```bash
python3 ~/.openclaw/workspace/scripts/self_improvement_sync.py --profile dev --days 7
```

## Operating Rules

1. Run at least once daily.
2. Promote only one experiment at a time.
3. Require measurable gain before keeping changes.
4. Roll back immediately if reliability drops.
5. Never auto-modify identity/safety rules without explicit approval.
