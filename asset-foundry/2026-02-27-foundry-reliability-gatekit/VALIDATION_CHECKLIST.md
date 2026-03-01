# Validation Checklist — Foundry Reliability Gatekit

## Objective
Confirm whether SYSTEM reliability blockers are cleared before enabling downstream build lanes.

## Preconditions
- [ ] Latest ledger exists at `memory/YYYY-MM-DD.md`
- [ ] Ledger includes KPI snapshot with `Model mismatches`
- [ ] Ledger includes per-job row for `foundry-daily-build-candidate`
- [ ] Ledger includes Active Experiment Validation Gate section with `Current: X runs`

## Run Steps
- [ ] Run:
  - `python3 asset-foundry/2026-02-27-foundry-reliability-gatekit/foundry_reliability_gate.py --ledger memory/2026-02-25.md --out memory/reports/latest-foundry-gate-report.md`
- [ ] Confirm report generated at `memory/reports/latest-foundry-gate-report.md`

## Pass Criteria
- [ ] `routing_mismatch_gate: PASS`
- [ ] `foundry_success_gate: PASS`
- [ ] `post_activation_runs_gate: PASS`
- [ ] Final decision line says build is unblocked

## Failure Handling
- If mismatch gate fails:
  - [ ] Re-run model pinning checks (`payload.model`) on `radar-daily-scan`
  - [ ] Verify local provider availability before next cron
- If success gate fails:
  - [ ] Keep Foundry in HOLD and run additional controlled retries
- If post-run gate fails:
  - [ ] Trigger required post-activation runs before any builder-lane execution

## Reusability Note
Use this checklist each time an experiment affects build-lane reliability assumptions.
