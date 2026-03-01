# AGENTIC_ARCHITECTURE_V2.md — Cobi Execution Architecture

Last updated: 2026-02-26

## 1) What You Want (Design Intent)

- High-agency execution while you are at work.
- Premium intelligence where it matters, not everywhere.
- Fast response and low thermal load on Mac mini for routine operations.
- Reliable artifact shipping (assets, reports, content), not long chat loops.

## 2) Current Problems (Root Causes)

1. Chat-shaped usage burned premium tokens.
2. Routing drift from profile/service mismatch and hardcoded guards.
3. Too many overlapping jobs produced maintenance noise.
4. Documentation and runtime policy diverged.

## 3) Control Plane

- Single gateway profile: `main`
- Single scheduler truth: `~/.openclaw-main/cron/jobs.json`
- Single routing truth: `config/model_routing_policy.json`
- Single enforcer: `scripts/enforce_model_routing.sh`

## 4) Runtime Lanes

### Lane A — Orchestration (Premium Cognition)
- Job: `orchestrator-daily-plan`
- Model: `moonshot/kimi-k2.5`
- Output: plan + delegated tasks

### Lane B — Ingestion/Queue Workers (Local Fast)
- Jobs: `resource-harvest-video-web`, `transcription-retry-worker`
- Model: `ollama/qwen2.5:3b`
- Output: source inventory + queue movement

### Lane C — Midday Analysis (Premium Strategist)
- Job: `intel-midday-synthesis`
- Model: `moonshot/kimi-k2.5`
- Output: decisions from fresh evidence

### Lane D — Build Lane (Premium Builder)
- Job: `foundry-daily-build-candidate`
- Model: `openai-codex/gpt-5.3-codex`
- Output: asset files in `asset-foundry/`

### Lane E — Distribution + Handoff
- `proof-daily-content-draft` -> `moonshot/kimi-k2.5`
- `warehouse-shift-handoff` -> `ollama/qwen2.5:7b`

### Lane F — Guardrails
- Job: `security-daily-posture`
- Runs policy enforcement + posture checks + integrity verification

## 5) Human-in-the-Loop Split (Important)

### Codex (Design/Operator Brain)
Use Codex for:
- architecture design
- policy changes
- debugging failures
- task decomposition

### OpenClaw (Execution Engine)
Use OpenClaw for:
- scheduled execution
- scripted ingestion
- delegated specialist runs
- artifact production

Rule: if it looks like conversation, keep it in Codex. If it has a contract and artifact, send to OpenClaw.

## 6) Task Contract Standard

All execution tasks must define:
- Goal
- Inputs
- Constraints
- Deliverables
- Done checks

No contract -> no autonomous execution.

## 7) Cost/Quality Strategy

- Default model is local fast (`qwen2.5:3b`).
- Local smart (`qwen2.5:7b`) only for analysis lanes.
- Moonshot is allowlisted to 2 high-value jobs.
- Codex is allowlisted to build lane.
- No premium fallback in defaults.

## 8) Reliability Rules

- Script-first for repetitive tasks.
- One source of truth per concern (gateway, cron, routing policy).
- Every output follows `OUTPUT_STANDARD.md`.
- Drift corrected automatically by routing guard.

## 9) Scale Path (When You Grow)

Add new lanes only when all are true:
1. Existing lane is capacity-constrained for 2+ weeks.
2. New lane has unique artifact output and KPI.
3. New lane has explicit model/cost budget.
4. New lane can be disabled without breaking core loop.
