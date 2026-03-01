# MODEL_ROUTING.md

Current routing is policy-driven from:
- `config/model_routing_policy.json`

Runtime enforcer:
- `scripts/enforce_model_routing.sh`

## Fast Rules

- Default ops/chat: `LocalFast` (`ollama/qwen2.5:3b`)
- Deeper local analysis: `LocalSmart` (`ollama/qwen2.5:7b`)
- Heavy code/build: `Builder` (`openai-codex/gpt-5.3-codex`)
- High-stakes strategy/content: `Strategist` (`moonshot/kimi-k2.5`) only on allowlisted lanes

Strict guards:
- Enabled jobs are enforced by policy.
- Every enabled job must have an explicit model mapping or it is forced to local fallback.
- `moonshot/*` only runs on `allowedMoonshotJobs`.
- `openai-codex/*` only runs on `allowedOpenAICodexJobs`.
- Any non-allowlisted premium route is auto-downgraded to local fallback.

## Why

- Prevent silent premium token burn.
- Keep day-to-day response speed high.
- Reserve premium intelligence for high-leverage decisions.

## Operational Commands

```bash
# enforce policy now
bash ~/.openclaw/workspace/scripts/enforce_model_routing.sh main

# inspect active cron model map
jq -r '.jobs[] | select(.enabled==true) | [.name,.payload.model] | @tsv' ~/.openclaw-main/cron/jobs.json

# inspect default model/fallbacks
jq -r '.agents.defaults.model' ~/.openclaw-main/openclaw.json
```
