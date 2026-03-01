# 2026-02-27 Foundry Reliability Gatekit

Reusable asset to enforce a deterministic go/no-go decision for Asset Builder workflows.

## Included
- `foundry_reliability_gate.py` — parser + gate evaluator for ledger markdown
- `VALIDATION_CHECKLIST.md` — operator checklist for pass/fail execution
- `EVIDENCE.md` — linked source signals and rationale

## Why this is highest leverage now
Current synthesis marks SYSTEM reliability as critical path. This kit standardizes gate evaluation so build work does not proceed on unstable infrastructure.

## Quick Start
```bash
python3 asset-foundry/2026-02-27-foundry-reliability-gatekit/foundry_reliability_gate.py \
  --ledger memory/2026-02-25.md \
  --out memory/reports/latest-foundry-gate-report.md
```

## Expected Output
A markdown report with gate results and a final HOLD/PASS decision.
