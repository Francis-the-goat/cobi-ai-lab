# Foundry Reliability Gate Report

- Ledger: `memory/2026-02-25.md`
- Job: `foundry-daily-build-candidate`
- Status: **HOLD**

## Inputs
- Model mismatches: 4
- Foundry success rate: 67%
- Post-activation runs: 0

## Gate thresholds
- max mismatch: <= 0
- min success: >= 95%
- min post-activation runs: >= 2

## Check results
- routing_mismatch_gate: FAIL
- foundry_success_gate: FAIL
- post_activation_runs_gate: FAIL

## Decision
HOLD: keep SYSTEM as primary until all gates pass.
