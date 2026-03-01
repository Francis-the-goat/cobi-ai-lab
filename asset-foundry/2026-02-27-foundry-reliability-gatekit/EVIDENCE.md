# EVIDENCE — Foundry Reliability Gatekit

## Why this asset exists
This kit is built to unblock the current SYSTEM critical path: model routing drift and unvalidated Foundry reliability.

## Source signals
1. `memory/2026-02-27.md`
   - Midday synthesis reports unresolved blockers: 80% routing drift and 0/2 post-activation Foundry validation runs.
   - Explicit gate: do not shift into broader asset building until routing mismatches are 0 and Foundry validation is 2/2.
2. `memory/plans/2026-02-27-plan.md`
   - Daily primary objective requires deterministic validation of model routing and Foundry experiment outcomes.
   - Asset Builder lane is conditional on this reliability gate.
3. `memory/2026-02-25.md`
   - Self-improvement ledger baseline: `foundry-daily-build-candidate` at 67% success and experiment `exp-2026-02-25-27403` in HOLD with insufficient post-activation data.
4. `AUTONOMOUS_WORK_SYSTEM.md`
   - Non-negotiable: if evidence is missing, return blocked decision path.
   - Asset Builder role should produce reusable implementation, not generic commentary.

## Decision supported by evidence
Highest-leverage reusable build for this checkpoint is a **reliability gate kit** that standardizes pass/fail determination before downstream builds.

## Expected impact
- Prevents premature asset execution when SYSTEM is unstable.
- Creates repeatable, low-friction validation for split-attention workflows.
- Improves cost discipline by enforcing model-routing checks before premium-lane build runs.
