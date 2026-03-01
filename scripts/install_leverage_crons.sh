#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-dev}"
TZ_NAME="${2:-Australia/Brisbane}"
TELEGRAM_TO="${3:-}"

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI not found in PATH"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for idempotent cron updates"
  exit 1
fi

oc() {
  openclaw --profile "$PROFILE" "$@"
}

set_job() {
  local name="$1"
  local schedule_type="$2"
  local schedule_value="$3"
  local model="$4"
  local message="$5"

  local list_json
  list_json="$(oc cron list --all --json)"

  local job_id
  job_id="$(printf '%s' "$list_json" | jq -r --arg name "$name" '.jobs[]? | select(.name == $name) | .id' | head -n 1)"

  local base_args=(cron)
  local is_edit=false
  if [[ -n "$job_id" && "$job_id" != "null" ]]; then
    base_args+=(edit "$job_id")
    is_edit=true
  else
    base_args+=(add --name "$name")
  fi

  if [[ "$schedule_type" == "cron" ]]; then
    base_args+=(--cron "$schedule_value" --tz "$TZ_NAME")
  else
    base_args+=(--every "$schedule_value")
  fi

  base_args+=(
    --session isolated
    --expect-final
    --model "$model"
    --message "$message"
  )

  if [[ "$is_edit" == "true" ]]; then
    base_args+=(--enable)
  fi

  base_args+=(--announce --channel telegram)
  if [[ -n "$TELEGRAM_TO" ]]; then
    base_args+=(--to "$TELEGRAM_TO")
  fi

  echo "Applying cron job: $name"
  oc "${base_args[@]}"
}

set_job \
  "orchestrator-daily-plan" \
  "cron" \
  "55 6 * * 1-5" \
  "moonshot/kimi-k2.5" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Orchestrator. Before planning, read memory/ACTIVE_CONTEXT.md as highest-priority context override, then BOOTSTRAP.md, PROJECTS.md, GOALS.md, and latest memory/research artifacts. Create memory/plans/YYYY-MM-DD-plan.md with one primary objective, one objective per track, and delegation tasks for specialists. If SMB was primary in the last orchestrator run, force a non-SMB primary track unless there is a hard deadline or active client blocker. Force at least 2 concrete actions outside SMB unless blocked by hard deadline. Apply QUALITY_BAR.md and OUTPUT_STANDARD.md. Return concise structured summary for Telegram."

set_job \
  "resource-harvest-video-web" \
  "cron" \
  "20 7 * * 1-5" \
  "ollama/qwen2.5:3b" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Resource Harvester. Run command: bash /.openclaw/workspace/scripts/value_resource_harvest.sh 3. Use only accepted sources from memory/research/YYYY-MM-DD-resource-harvest.md. Enforce strict relevance and entrepreneur importance gates from config/research_signal_policy.json. If accepted sources < minimum threshold, return BLOCKED with exact missing evidence and fastest path. Return output in exact OUTPUT_STANDARD.md section order."

set_job \
  "transcription-retry-worker" \
  "cron" \
  "10 8,11,14,17,20 * * *" \
  "ollama/qwen2.5:3b" \
  "Run command: bash /.openclaw/workspace/scripts/transcription_queue.sh dedupe && bash /.openclaw/workspace/scripts/transcription_queue.sh process --limit 2. If processed=0, return HEARTBEAT_OK. Otherwise return processed, succeeded, failed, and one next action."

set_job \
  "source-adaptation-recommender" \
  "cron" \
  "55 8 * * 1-5" \
  "ollama/qwen2.5:7b" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Source Recommender. Run command: python3 /.openclaw/workspace/scripts/source_adapt_recommend.py --latest 5 --queue 2. Then summarize top 3 recommended sources and why they match Cobi's current style and goals across business, upskill, and brand."

set_job \
  "intel-midday-synthesis" \
  "cron" \
  "35 10 * * 1-5" \
  "moonshot/kimi-k2.5" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Insight Synthesizer. Read memory/ACTIVE_CONTEXT.md first. Then use only accepted high-signal sources from latest memory/research harvest plus new source cards/transcripts to produce 3 high-value insights. Each insight must include evidence -> implication -> 48h action and entrepreneur importance (revenue, delivery leverage, moat, or risk reduction). Update memory/YYYY-MM-DD.md and project priorities. If accepted sources are insufficient, return BLOCKED. Apply QUALITY_BAR.md and OUTPUT_STANDARD.md."

set_job \
  "foundry-daily-build-candidate" \
  "cron" \
  "20 13 * * 1-5" \
  "openai-codex/gpt-5.3-codex" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Asset Builder. Build or materially improve one reusable asset under asset-foundry/YYYY-MM-DD-<slug> based on today's validated signals and plan. Must include problem, user, workflow, files changed/created, and validation evidence. End with decision BUILD NOW, PROTOTYPE, or REJECT. Apply QUALITY_BAR.md and OUTPUT_STANDARD.md."

set_job \
  "proof-daily-content-draft" \
  "cron" \
  "45 17 * * 1-5" \
  "moonshot/kimi-k2.5" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Content Funnel. Convert today's real outputs into one X thread and one 30-45 second reel script with one concrete metric claim and one CTA each. Update CONTENT_BACKLOG.md and return concise OUTPUT_STANDARD.md summary."

set_job \
  "warehouse-shift-handoff" \
  "cron" \
  "10 20 * * 1-5" \
  "ollama/qwen2.5:7b" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: End-of-Shift Handoff. Create the handoff using DAILY_HANDOFF_TEMPLATE.md and OUTPUT_STANDARD.md. Include progress across tracks, what was completed while Cobi was at work, top 3 tonight tasks, one 20-minute upskill sprint, and key risk/mitigation. Return output in exact OUTPUT_STANDARD.md section order. Write details to memory/YYYY-MM-DD.md."

set_job \
  "trajectory-weekly-brief" \
  "cron" \
  "30 6 * * 1" \
  "moonshot/kimi-k2.5" \
  "Produce weekly trajectory brief with top 5 meaningful AI/business changes, implications for monetizable offers plus Cobi's upskill/brand/system/life tracks, what to build this week, and what to ignore. Update PROJECTS.md priorities. Enforce QUALITY_BAR.md and OUTPUT_STANDARD.md."

set_job \
  "system-weekly-retro" \
  "cron" \
  "30 19 * * 5" \
  "openai-codex/gpt-5.3-codex" \
  "Run a weekly operator retrospective. Evaluate shipped assets, output quality, cycle time, and bottlenecks across all tracks. Propose 3 concrete system upgrades (skills, tools, or automation) and update GOALS.md and PROJECTS.md. Enforce QUALITY_BAR.md and OUTPUT_STANDARD.md."

set_job \
  "quality-weekly-audit" \
  "cron" \
  "45 20 * * 6" \
  "moonshot/kimi-k2.5" \
  "Run command: python3 /.openclaw/workspace/scripts/agent_quality_audit.py --profile ${PROFILE} --workspace /.openclaw/workspace --days 7 --history-limit 20. Then read memory/reports/latest-agent-quality-audit.md and return a SYSTEM-track summary using OUTPUT_STANDARD.md with the top 3 highest-leverage fixes for next week."

set_job \
  "skill-contract-weekly-audit" \
  "cron" \
  "40 20 * * 0" \
  "moonshot/kimi-k2.5" \
  "Run command: python3 /.openclaw/skills/operator-skill-reliability/scripts/run_skill_checks.py --skills-root /.openclaw/skills --report /.openclaw/workspace/memory/reports/latest-skill-contract-audit.md --write-json /.openclaw/workspace/memory/reports/latest-skill-contract-audit.json. Then read memory/reports/latest-skill-contract-audit.md and return a SYSTEM summary using OUTPUT_STANDARD.md with top 3 contract gaps, escalation path, and this week's hardening plan."

set_job \
  "self-improvement-daily-loop" \
  "cron" \
  "50 19 * * 1-5" \
  "moonshot/kimi-k2.5" \
  "Run command: bash /.openclaw/workspace/scripts/self_improvement_autoloop.sh ${PROFILE} 7 2. Then read self-improvement/reports/latest.md and self-improvement/reports/auto-promotion-latest.md. Write a daily self-improvement ledger entry to memory/YYYY-MM-DD.md with KPI snapshot, active experiment status, promotion/rollback decision, risk flags, and next experiment hypothesis. Return OUTPUT_STANDARD.md summary."

echo
echo "Leverage cron suite applied for profile '$PROFILE'."
oc cron list --all
