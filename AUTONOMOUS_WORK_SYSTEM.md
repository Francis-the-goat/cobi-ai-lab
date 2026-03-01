# AUTONOMOUS_WORK_SYSTEM.md

Purpose: run a reliable orchestrator + specialist workflow that creates leverage while Cobi is at work.

## Roles

### 1) Orchestrator (Strategist)
- Model lane: `moonshot/kimi-k2.5`
- Inputs: `PROJECTS.md`, `GOALS.md`, latest `memory`, latest `memory/research`, latest source cards.
- Output: one daily plan with priorities across tracks and clear delegation.
- Must create: `memory/plans/YYYY-MM-DD-plan.md`.
- Use when: prioritization, cross-track tradeoffs, delegation planning.
- Do not use when: repetitive ingestion or simple queue processing.

### 2) Resource Harvester (Local Worker)
- Model lane: `ollama/qwen2.5:3b` or script-first.
- Use script: `bash ~/.openclaw/workspace/scripts/value_resource_harvest.sh 3`
- Goal: gather fresh videos/news, enforce strict relevance gates, and queue only accepted high-signal items.
- Must create: `memory/research/YYYY-MM-DD-resource-harvest.md`.
- Must create: `memory/research/YYYY-MM-DD-rejected-sources.md`.
- Use when: collecting fresh external signals.
- Do not use when: strategic synthesis is required.

### 3) Insight Synthesizer (Analyst)
- Model lane: `moonshot/kimi-k2.5`.
- Inputs: latest harvest report + any new transcripts/source cards.
- Goal: convert accepted high-signal evidence into decisions and actionable tasks.
- Must update: `memory/YYYY-MM-DD.md`.
- Use when: translating evidence into decisions and next actions.
- Do not use when: accepted source count is below policy threshold (`BLOCKED`).

### 3b) Source Recommender (Adaptation Worker)
- Model lane: `ollama/qwen2.5:7b` with script-first execution.
- Use script: `python3 ~/.openclaw/workspace/scripts/source_adapt_recommend.py --latest 5 --queue 2`
- Goal: learn from recently ingested sources and suggest/queue next best sources.
- Must create: `memory/research/YYYY-MM-DD-source-recommendations.md`.
- Use when: new source cards are added and taste/profile should be refined.
- Do not use when: no source cards exist yet.

### 4) Asset Builder (Builder)
- Model lane: `openai-codex/gpt-5.3-codex` for code-heavy assets.
- Goal: build one reusable asset (tool, playbook, automation, skill).
- Must create/update: `asset-foundry/YYYY-MM-DD-<slug>/`.
- Use when: a concrete build is selected as highest leverage.
- Do not use when: discovery/validation has not been done.

### 5) Content Funnel (Brand Operator)
- Model lane: `moonshot/kimi-k2.5`
- Inputs: real work completed today (not hypothetical).
- Goal: draft content tied to evidence and outcomes.
- Must update: `CONTENT_BACKLOG.md`.
- Use when: there is real execution evidence from today.
- Do not use when: output would be speculative or generic.

### 6) End-of-Shift Handoff (Operator)
- Model lane: `ollama/qwen2.5:7b`
- Goal: summarize what got done, what matters, and tonight's execution list.
- Must use: `DAILY_HANDOFF_TEMPLATE.md` + `OUTPUT_STANDARD.md`.
- Use when: closing the workday and preparing execution handoff.
- Do not use when: no completed work exists (return `BLOCKED`).

### 7) Quality Auditor (System Guardian)
- Model lane: `ollama/qwen2.5:7b` with script-first execution.
- Use script: `python3 ~/.openclaw/workspace/scripts/agent_quality_audit.py --profile <active-profile> --workspace ~/.openclaw/workspace --days 7 --history-limit 20`
- Goal: detect reliability/quality drift and produce prioritized fixes.
- Must create: `memory/reports/YYYY-MM-DD-agent-quality-audit.md` and `memory/reports/latest-agent-quality-audit.md`.
- Use when: weekly quality and reliability review.
- Do not use when: cron history is unavailable.

### 8) Skill Reliability Auditor (System Guardian)
- Model lane: `ollama/qwen2.5:7b` with script-first execution.
- Use script: `python3 ~/.openclaw/skills/operator-skill-reliability/scripts/run_skill_checks.py --skills-root ~/.openclaw/skills --report ~/.openclaw/workspace/memory/reports/latest-skill-contract-audit.md --write-json ~/.openclaw/workspace/memory/reports/latest-skill-contract-audit.json`
- Goal: enforce contract/test coverage and predictable failure semantics across all skills.
- Must create: `memory/reports/latest-skill-contract-audit.md` and `.json`.
- Use when: weekly system reliability review or before adding new autonomous skill workflows.
- Do not use when: skills directory is unavailable.

## Non-Negotiables
- Always declare a primary track (`SMB`, `UPSKILL`, `BRAND`, `LIFE`, `SYSTEM`).
- No generic advice. Every major output must include evidence or explicit assumptions.
- Default to actions that can be completed in <= 48 hours.
- If a track appears repeatedly, force at least one concrete action in an under-served track in the next cycle unless blocked.
- If required evidence is missing, return:
  `BLOCKED: missing = [...] | fastest path = [...]`
- For research lanes, only accepted sources from `config/research_signal_policy.json` may be used for synthesis.

## Delegation Contract
- Orchestrator assigns exactly one main objective and up to three supporting tasks.
- Specialists do execution and artifact creation, not strategic rewrites.
- Each specialist update must include:
  1. Completed work
  2. Evidence and implications
  3. One decision
  4. Top 3 next actions

## Token and Cost Discipline
- Script-first for repetitive ingestion and queue handling.
- Local model for repetitive checks and low-risk operations.
- Premium models are allowlisted by lane only:
  - `moonshot/kimi-k2.5`: `orchestrator-daily-plan`, `intel-midday-synthesis`, `proof-daily-content-draft`
  - `openai-codex/gpt-5.3-codex`: `foundry-daily-build-candidate`

## Security Rules
- Work inside workspace paths only unless explicitly approved.
- Never expose or print secrets.
- Never run destructive commands without explicit approval.
