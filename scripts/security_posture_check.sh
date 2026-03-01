#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-main}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
POLICY_PATH="${2:-$WORKSPACE/config/model_routing_policy.json}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

state_dir_for_profile() {
  local profile="$1"
  if [[ "$profile" == "default" ]]; then
    printf '%s\n' "$HOME/.openclaw"
  else
    printf '%s\n' "$HOME/.openclaw-$profile"
  fi
}

need_cmd jq
need_cmd openclaw

STATE_DIR="$(state_dir_for_profile "$PROFILE")"
CFG="$STATE_DIR/openclaw.json"
CRON="$STATE_DIR/cron/jobs.json"

[[ -f "$CFG" ]] || fail "missing config: $CFG"
[[ -f "$CRON" ]] || fail "missing cron jobs: $CRON"
[[ -f "$POLICY_PATH" ]] || fail "missing policy: $POLICY_PATH"

auth_mode="$(jq -r '.gateway.auth.mode // ""' "$CFG")"
[[ "$auth_mode" == "token" ]] || fail "gateway.auth.mode must be token (got: $auth_mode)"

main_sbx="$(jq -r '.agents.list[] | select(.id=="main") | .sandbox.mode // ""' "$CFG" | head -n1)"
[[ "$main_sbx" == "off" ]] || fail "main sandbox.mode must be off (got: $main_sbx)"

lev_count="$(jq -r '[.agents.list[] | select(.id=="leverage")] | length' "$CFG")"
if [[ "$lev_count" -gt 0 ]]; then
  lev_sbx="$(jq -r '.agents.list[] | select(.id=="leverage") | .sandbox.mode // ""' "$CFG" | head -n1)"
  [[ "$lev_sbx" == "off" ]] || fail "leverage sandbox.mode must be off (got: $lev_sbx)"
fi

elev_enabled="$(jq -r '.tools.elevated.enabled // false' "$CFG")"
[[ "$elev_enabled" == "true" ]] || fail "tools.elevated.enabled must be true"

tg_allow_count="$(jq -r '.tools.elevated.allowFrom.telegram | if type=="array" then length else 0 end' "$CFG")"
wc_allow_count="$(jq -r '.tools.elevated.allowFrom.webchat | if type=="array" then length else 0 end' "$CFG")"
[[ "$tg_allow_count" -gt 0 ]] || fail "tools.elevated.allowFrom.telegram must contain at least one allowed source"
[[ "$wc_allow_count" -gt 0 ]] || fail "tools.elevated.allowFrom.webchat must contain at least one allowed source"

perm="$(stat -f '%Lp' "$CFG")"
[[ "$perm" == "600" ]] || fail "config permissions must be 600 (got: $perm)"

policy_primary="$(jq -r '.defaults.primary' "$POLICY_PATH")"
cfg_primary="$(jq -r '.agents.defaults.model.primary // ""' "$CFG")"
[[ "$cfg_primary" == "$policy_primary" ]] || fail "primary model drift: cfg=$cfg_primary policy=$policy_primary"

policy_fallbacks="$(jq -c '.defaults.fallbacks' "$POLICY_PATH")"
jq -e --argjson expected "$policy_fallbacks" '
  (.agents.defaults.model.fallbacks // []) == $expected
' "$CFG" >/dev/null || fail "fallback model drift detected"

required_model_refs="$(
  jq -r '
    [
      .defaults.primary,
      .defaults.heartbeatModel,
      (.defaults.fallbacks[]?),
      (.cronModelByName[]?)
    ]
    | map(select(type == "string" and length > 0 and contains("/")))
    | unique[]
  ' "$POLICY_PATH"
)"

while IFS= read -r model_ref; do
  [[ -z "$model_ref" ]] && continue
  jq -e --arg m "$model_ref" '.agents.defaults.models[$m] != null' "$CFG" >/dev/null \
    || fail "model allowlist missing in agents.defaults.models: $model_ref"
  if [[ "$model_ref" == ollama/* ]]; then
    ollama_id="${model_ref#ollama/}"
    jq -e --arg id "$ollama_id" '
      ([.models.providers.ollama.models[]?.id] | index($id)) != null
    ' "$CFG" >/dev/null || fail "ollama provider model missing: $ollama_id"
  fi
done <<<"$required_model_refs"

jq -e --argjson policy "$(cat "$POLICY_PATH")" '
  .jobs
  | map(select(.enabled == true and ((.payload.model // "") | startswith("moonshot/"))))
  | all(.name as $n | (($policy.allowedMoonshotJobs // []) | index($n)) != null)
' "$CRON" >/dev/null || fail "moonshot model assigned to non-allowlisted enabled job"

jq -e --argjson policy "$(cat "$POLICY_PATH")" '
  .jobs
  | map(select(.enabled == true and ((.payload.model // "") | startswith("openai-codex/"))))
  | all(.name as $n | (($policy.allowedOpenAICodexJobs // []) | index($n)) != null)
' "$CRON" >/dev/null || fail "codex model assigned to non-allowlisted enabled job"

jq -e --argjson policy "$(cat "$POLICY_PATH")" '
  [.jobs[] | select(.enabled == true)] as $enabled
  | all($enabled[]; . as $j | (($policy.cronModelByName // {}) | has($j.name)))
  and
  all($enabled[]; . as $j | (($policy.cronModelByName[$j.name]) == ($j.payload.model // null)))
' "$CRON" >/dev/null || fail "enabled cron model mapping drift from policy"

if [[ "$(jq -r '.enforceEnabledSet // false' "$POLICY_PATH")" == "true" ]]; then
  jq -e --argjson policy "$(cat "$POLICY_PATH")" '
    (
      [.jobs[] | select(.enabled == true) | .name] | sort
    ) == (
      ($policy.enabledJobs // []) | sort
    )
  ' "$CRON" >/dev/null || fail "enabled job set drift from policy"
fi

cron_json="$(openclaw --profile "$PROFILE" cron list --all --json)"
model_not_allowed_count="$(
  printf '%s' "$cron_json" | jq -r '
    [.jobs[] | select(.enabled == true and ((.state.lastError // "") | test("model not allowed"; "i")))] | length
  '
)"
[[ "$model_not_allowed_count" == "0" ]] || fail "enabled jobs still failing with model-not-allowed ($model_not_allowed_count)"

enabled_jobs="$(jq -r '[.jobs[] | select(.enabled == true)] | length' "$CRON")"
echo "PASS: security posture check succeeded profile=$PROFILE enabled_jobs=$enabled_jobs primary=$cfg_primary"
