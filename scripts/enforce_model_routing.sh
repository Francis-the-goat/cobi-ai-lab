#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-main}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
POLICY_PATH="${2:-$WORKSPACE/config/model_routing_policy.json}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[routing-guard] missing command: $1" >&2
    exit 1
  }
}

alias_for_model() {
  case "$1" in
    "moonshot/kimi-k2.5") echo "Strategist" ;;
    "openai-codex/gpt-5.3-codex") echo "Builder" ;;
    "ollama/qwen2.5:3b") echo "LocalFast" ;;
    "ollama/qwen2.5:7b") echo "LocalSmart" ;;
    "ollama/deepseek-coder:1.3b") echo "LocalCode" ;;
    "ollama/llama3.2:3b") echo "LocalFallback" ;;
    *)
      local provider model provider_upper
      provider="$(printf '%s' "$1" | cut -d'/' -f1)"
      model="$(printf '%s' "$1" | cut -d'/' -f2 | tr -cd 'A-Za-z0-9')"
      provider_upper="$(printf '%s' "$provider" | tr '[:lower:]' '[:upper:]')"
      echo "${provider_upper}${model}"
      ;;
  esac
}

ollama_name_for_id() {
  case "$1" in
    "qwen2.5:3b") echo "Qwen 2.5 3B (Local Fast)" ;;
    "qwen2.5:7b") echo "Qwen 2.5 7B (Local Smart)" ;;
    "llama3.2:3b") echo "Llama 3.2 3B (Local)" ;;
    "deepseek-coder:1.3b") echo "DeepSeek Coder 1.3B (Local)" ;;
    *) echo "$1 (Local)" ;;
  esac
}

ollama_max_tokens_for_id() {
  case "$1" in
    "qwen2.5:7b") echo 3072 ;;
    *) echo 2048 ;;
  esac
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

STATE_DIR="$(state_dir_for_profile "$PROFILE")"
CFG="$STATE_DIR/openclaw.json"
CRON="$STATE_DIR/cron/jobs.json"

[[ -f "$POLICY_PATH" ]] || { echo "[routing-guard] missing policy: $POLICY_PATH" >&2; exit 1; }
[[ -f "$CFG" ]] || { echo "[routing-guard] missing config: $CFG" >&2; exit 1; }
[[ -f "$CRON" ]] || { echo "[routing-guard] missing cron jobs: $CRON" >&2; exit 1; }

policy_json="$(cat "$POLICY_PATH")"
policy_profile="$(jq -r '.profile // ""' "$POLICY_PATH")"
if [[ -n "$policy_profile" && "$policy_profile" != "$PROFILE" ]]; then
  echo "[routing-guard] warning: policy profile=$policy_profile, runtime profile=$PROFILE"
fi

policy_primary="$(jq -r '.defaults.primary' "$POLICY_PATH")"
policy_heartbeat="$(jq -r '.defaults.heartbeatModel' "$POLICY_PATH")"
policy_fallbacks="$(jq -c '.defaults.fallbacks' "$POLICY_PATH")"
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

TMP_CFG="$CFG.tmp"
TMP_CRON="$CRON.tmp"

jq \
  --arg primary "$policy_primary" \
  --arg heartbeat "$policy_heartbeat" \
  --argjson fallbacks "$policy_fallbacks" \
  '
    .agents.defaults.model.primary = $primary
    | .agents.defaults.model.fallbacks = $fallbacks
    | .agents.defaults.heartbeat.model = $heartbeat
  ' "$CFG" > "$TMP_CFG"

while IFS= read -r model_ref; do
  [[ -z "$model_ref" ]] && continue
  alias_name="$(alias_for_model "$model_ref")"
  jq --arg model_ref "$model_ref" --arg alias "$alias_name" '
    .agents.defaults.models //= {}
    | .agents.defaults.models[$model_ref] = (.agents.defaults.models[$model_ref] // {alias: $alias})
  ' "$TMP_CFG" > "${TMP_CFG}.next"
  mv "${TMP_CFG}.next" "$TMP_CFG"

  if [[ "$model_ref" == ollama/* ]]; then
    ollama_id="${model_ref#ollama/}"
    ollama_name="$(ollama_name_for_id "$ollama_id")"
    ollama_max_tokens="$(ollama_max_tokens_for_id "$ollama_id")"
    jq \
      --arg id "$ollama_id" \
      --arg name "$ollama_name" \
      --argjson maxTokens "$ollama_max_tokens" \
      '
        .models //= {}
        | .models.providers //= {}
        | .models.providers.ollama //= {"baseUrl":"http://127.0.0.1:11434","api":"ollama","models":[]}
        | .models.providers.ollama.models //= []
        | if ([.models.providers.ollama.models[]?.id] | index($id)) == null then
            .models.providers.ollama.models += [
              {
                "id": $id,
                "name": $name,
                "reasoning": false,
                "input": ["text"],
                "cost": {
                  "input": 0,
                  "output": 0,
                  "cacheRead": 0,
                  "cacheWrite": 0
                },
                "contextWindow": 128000,
                "maxTokens": $maxTokens
              }
            ]
          else
            .
          end
      ' "$TMP_CFG" > "${TMP_CFG}.next"
    mv "${TMP_CFG}.next" "$TMP_CFG"
  fi
done <<<"$required_model_refs"

if ! cmp -s "$CFG" "$TMP_CFG"; then
  mv "$TMP_CFG" "$CFG"
  cfg_changed=1
else
  rm -f "$TMP_CFG"
  cfg_changed=0
fi

jq --argjson policy "$policy_json" '
  .jobs |= map(
    (.name // "") as $job_name
    |
    (
      if ($policy.enforceEnabledSet // false) then
        .enabled = ((($policy.enabledJobs // []) | index($job_name)) != null)
      else
        .
      end
    )
    | if .enabled then
        (
          if (($policy.cronModelByName | has($job_name))) then
            if ($policy.cronModelByName[$job_name] == null) then
              .
            else
              (.payload //= {})
              | .payload.model = $policy.cronModelByName[$job_name]
            end
          elif ($policy.requireExplicitCronModel // false) then
            (.payload //= {})
            | .payload.model = ($policy.defaults.nonPremiumCronFallbackModel // "ollama/qwen2.5:3b")
          else
            .
          end
        )
        | if ((.payload.model // "") | startswith("moonshot/")) and ((($policy.allowedMoonshotJobs // []) | index($job_name)) == null) then
            (.payload //= {})
            | .payload.model = ($policy.defaults.nonPremiumCronFallbackModel // "ollama/qwen2.5:3b")
          else
            .
          end
        | if ((.payload.model // "") | startswith("openai-codex/")) and ((($policy.allowedOpenAICodexJobs // []) | index($job_name)) == null) then
            (.payload //= {})
            | .payload.model = ($policy.defaults.nonPremiumCronFallbackModel // "ollama/qwen2.5:3b")
          else
            .
          end
      else
        .
      end
  )
' "$CRON" > "$TMP_CRON"

if ! cmp -s "$CRON" "$TMP_CRON"; then
  mv "$TMP_CRON" "$CRON"
  cron_changed=1
else
  rm -f "$TMP_CRON"
  cron_changed=0
fi

enabled_jobs_count="$(jq -r '[.jobs[] | select(.enabled == true)] | length' "$CRON")"
enabled_moonshot_count="$(jq -r '[.jobs[] | select(.enabled == true and ((.payload.model // "") | startswith("moonshot/")))] | length' "$CRON")"
enabled_codex_count="$(jq -r '[.jobs[] | select(.enabled == true and ((.payload.model // "") | startswith("openai-codex/")))] | length' "$CRON")"
primary_model="$(jq -r '.agents.defaults.model.primary // ""' "$CFG")"
heartbeat_model="$(jq -r '.agents.defaults.heartbeat.model // ""' "$CFG")"

echo "[routing-guard] profile=$PROFILE cfg_changed=$cfg_changed cron_changed=$cron_changed primary=$primary_model heartbeat=$heartbeat_model enabled_jobs=$enabled_jobs_count enabled_moonshot_jobs=$enabled_moonshot_count enabled_codex_jobs=$enabled_codex_count"
