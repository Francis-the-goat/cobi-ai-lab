#!/usr/bin/env bash
# install_leverage_crons_fixed.sh — Cost-Aware Model Router Version
# Installs cron jobs with explicit model pinning and health checks

set -euo pipefail

PROFILE="${1:-dev}"
TZ_NAME="${2:-Australia/Brisbane}"
TELEGRAM_TO="${3:-}"

# Source the model router
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/model_router.sh"

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

# Get routed model for task type
get_routed_model() {
  local task_type="$1"
  local job_name="$2"
  route_model "$task_type" "$job_name"
}

set_job() {
  local name="$1"
  local schedule_type="$2"
  local schedule_value="$3"
  local task_type="$4"  # harvest|scan|synthesize|plan|build|content|quality_audit
  local message="$5"
  
  # Route to appropriate model based on task type
  local model
  model="$(get_routed_model "$task_type" "$name")"
  
  if [[ "$model" == ERROR* ]]; then
    echo "ERROR: Could not route model for $name" >&2
    return 1
  fi
  
  echo "Routing $name → $model (task: $task_type)"

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

  echo "Applying cron job: $name (model: $model)"
  oc "${base_args[@]}"
}

# Orchestrator — Planning/Strategy (Premium)
set_job \
  "orchestrator-daily-plan" \
  "cron" \
  "55 6 * * 1-5" \
  "plan" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Orchestrator. Before planning, read memory/ACTIVE_CONTEXT.md as highest-priority context override, then BOOTSTRAP.md, PROJECTS.md, GOALS.md, and latest memory/research artifacts. Create memory/plans/YYYY-MM-DD-plan.md with one primary objective, one objective per track, and delegation tasks for specialists. If SMB was primary in the last orchestrator run, force a non-SMB primary track unless there is a hard deadline or active client blocker. Force at least 2 concrete actions outside SMB unless blocked by hard deadline. Apply QUALITY_BAR.md and OUTPUT_STANDARD.md. Return concise structured summary for Telegram."

# Resource Harvester — Data ingestion (Local)
set_job \
  "resource-harvest-video-web" \
  "cron" \
  "20 7 * * 1-5" \
  "harvest" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Resource Harvester. Run command: bash /.openclaw/workspace/scripts/value_resource_harvest.sh 3. Use only accepted sources from memory/research/YYYY-MM-DD-resource-harvest.md. Enforce strict relevance and entrepreneur importance gates from config/research_signal_policy.json. If accepted sources < minimum threshold, return BLOCKED with exact missing evidence and fastest path. Return output in exact OUTPUT_STANDARD.md section order."

# Transcription Worker — Queue processing (Local)
set_job \
  "transcription-retry-worker" \
  "cron" \
  "10 8,11,14,17,20 * * *" \
  "harvest" \
  "Run command: bash /.openclaw/workspace/scripts/transcription_queue.sh dedupe && bash /.openclaw/workspace/scripts/transcription_queue.sh process --limit 2. If processed=0, return HEARTBEAT_OK. Otherwise return processed, succeeded, failed, and one next action."

# Source Recommender — Analysis (Local)
set_job \
  "source-adaptation-recommender" \
  "cron" \
  "55 8 * * 1-5" \
  "synthesize" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Source Recommender. Run command: python3 /.openclaw/workspace/scripts/source_adapt_recommend.py --latest 5 --queue 2. Then summarize top 3 recommended sources and why they match Cobi's current style and goals across business, upskill, and brand."

# Midday Synthesis — Insight generation (Premium)
set_job \
  "intel-midday-synthesis" \
  "cron" \
  "0 12 * * 1-5" \
  "synthesize" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Insight Synthesizer. Read memory/ACTIVE_CONTEXT.md first. Then use only accepted high-signal sources from latest memory/research harvest plus new source cards/transcripts to produce 3 high-value insights. Each insight must include evidence -> implication -> 48h action and entrepreneur importance (revenue, delivery leverage, moat, or risk reduction). Update memory/YYYY-MM-DD.md and project priorities. If accepted sources are insufficient, return BLOCKED. Apply QUALITY_BAR.md and OUTPUT_STANDARD.md."

# Skill Contract Audit — Quality gate (Premium)
set_job \
  "skill-contract-weekly-audit" \
  "cron" \
  "0 9 * * 3" \
  "quality_audit" \
  "Run command: python3 /.openclaw/skills/operator-skill-reliability/scripts/run_skill_checks.py. Validate all skills meet contract requirements. Generate report at memory/reports/latest-skill-contract-audit.md. Return status: PASS if all skills ≥90, BLOCKED with fixes needed if any skill <90."

# Foundry Build Candidate — Asset creation (Premium/Build)
set_job \
  "foundry-daily-build-candidate" \
  "cron" \
  "0 14 * * 1-5" \
  "build" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Asset Builder. Check PROJECTS.md and latest synthesis for highest-leverage build. Create one reusable asset in asset-foundry/YYYY-MM-DD-<slug>/. Include: EVIDENCE.md linking to source signals, implementation files, validation checklist. Return BUILD NOW if asset ships, PROTOTYPE if needs testing, BLOCKED if prerequisite missing."

# Content Funnel — Distribution (Premium)
set_job \
  "content-funnel-evening" \
  "cron" \
  "0 20 * * 1-5" \
  "content" \
  "Follow AUTONOMOUS_WORK_SYSTEM.md role: Content Funnel. Read today's completed work from memory/YYYY-MM-DD.md. Draft content tied to real evidence (not speculation). Update CONTENT_BACKLOG.md with thread outlines, hooks, and specific metrics. Return one concrete content piece ready for Cobi review."

# Self-Improvement Sync — System optimization (Local)
set_job \
  "self-improvement-sync" \
  "cron" \
  "0 22 * * *" \
  "synthesize" \
  "Run command: python3 /.openclaw/workspace/scripts/self_improvement_sync.py --days 7. Analyze cron run history for cost, quality, speed metrics. Detect model routing drift and bottlenecks. Generate experiment recommendations. Save to memory/reports/latest-self-improvement.md."

echo ""
echo "=== Cost-Aware Cron Jobs Installed ==="
echo "Run 'openclaw --profile $PROFILE cron list' to verify"
echo ""
echo "Model routing log: memory/logs/model-routing.log"
