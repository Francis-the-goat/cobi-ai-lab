# MODEL_ARCHITECTURE.md — Execution-First Multi-Model Policy

Last updated: 2026-02-26

## Objective

Maximize throughput and reliability on Mac mini M4 while preserving premium intelligence for high-leverage decisions.

## Role Assignment (Single Source of Truth)

1. `LocalFast` -> `ollama/qwen2.5:3b`
- Default lane for chat-like ops, triage, summaries, queue workers, and low-risk execution.
- Priority: speed + low heat.

2. `LocalSmart` -> `ollama/qwen2.5:7b`
- Escalation lane for deeper local analysis and better reasoning quality.
- Priority: quality bump when `LocalFast` is insufficient.

3. `LocalCode` -> `ollama/deepseek-coder:1.3b`
- Lightweight local code helper for simple transforms and scaffolding.

4. `Strategist` -> `moonshot/kimi-k2.5`
- Premium cognition lane for planning and high-stakes synthesis only.

5. `Builder` -> `openai-codex/gpt-5.3-codex`
- Premium implementation lane for heavy build/coding tasks.

## Default + Fallback Policy

Default primary model:
- `ollama/qwen2.5:3b`

Fallback order:
1. `ollama/llama3.2:3b`
2. `ollama/qwen2.5:7b`
3. `ollama/deepseek-coder:1.3b`

Policy note:
- No premium fallback in defaults (prevents silent cost burn).
- Premium lanes are explicit and allowlisted per cron/job.

## Premium Allowlist (Current)

Moonshot (`moonshot/kimi-k2.5`) allowed jobs:
- `orchestrator-daily-plan`
- `intel-midday-synthesis`
- `proof-daily-content-draft`

OpenAI Codex (`openai-codex/gpt-5.3-codex`) allowed jobs:
- `foundry-daily-build-candidate`

## Heat + Speed Discipline

- Prefer `LocalFast` for repetitive operations.
- Use `LocalSmart` only for analysis where quality gain justifies slower throughput.
- Keep one heavy local generation lane active at a time.
- Keep automation script-first wherever possible.

## Automation Routing (Current 8-Job Core)

- `orchestrator-daily-plan` -> `moonshot/kimi-k2.5`
- `resource-harvest-video-web` -> `ollama/qwen2.5:3b`
- `transcription-retry-worker` -> `ollama/qwen2.5:3b`
- `intel-midday-synthesis` -> `moonshot/kimi-k2.5`
- `foundry-daily-build-candidate` -> `openai-codex/gpt-5.3-codex`
- `proof-daily-content-draft` -> `moonshot/kimi-k2.5`
- `warehouse-shift-handoff` -> `ollama/qwen2.5:7b`
- `security-daily-posture` -> script-only (no model)

## Enforcement

Single policy file:
- `config/model_routing_policy.json`

Guard script:
- `scripts/enforce_model_routing.sh <profile>`

Guard execution paths:
- Startup healthcheck (every 5 min)
- Daily security posture cron
