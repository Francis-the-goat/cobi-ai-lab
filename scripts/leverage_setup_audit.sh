#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-dev}"
CONFIG_PATH="$HOME/.openclaw-${PROFILE}/openclaw.json"
EXPECTED_WORKSPACE="$HOME/.openclaw/workspace"
AUTH_PROFILES="$HOME/.openclaw-${PROFILE}/agents/${PROFILE}/agent/auth-profiles.json"

failures=0

pass() {
  echo "PASS  $1"
}

fail() {
  echo "FAIL  $1"
  failures=$((failures + 1))
}

echo "Leverage setup audit (profile: $PROFILE)"
echo "Config: $CONFIG_PATH"
echo

if [[ -f "$CONFIG_PATH" ]]; then
  pass "Config file exists"
else
  fail "Config file exists"
fi

workspace_value="$(jq -r '.agents.defaults.workspace // empty' "$CONFIG_PATH" 2>/dev/null || true)"
if [[ "$workspace_value" == "$EXPECTED_WORKSPACE" ]]; then
  pass "Workspace path points to $EXPECTED_WORKSPACE"
else
  fail "Workspace path points to $EXPECTED_WORKSPACE"
fi

primary_model="$(jq -r '.agents.defaults.model.primary // empty' "$CONFIG_PATH" 2>/dev/null || true)"
if [[ "$primary_model" == "moonshot/kimi-k2.5" ]]; then
  pass "Primary model is moonshot/kimi-k2.5"
else
  fail "Primary model is moonshot/kimi-k2.5"
fi

if jq -e '.agents.defaults.model.fallbacks[]? | select(. == "openai-codex/gpt-5.3-codex")' "$CONFIG_PATH" >/dev/null 2>&1; then
  pass "Fallback includes Builder"
else
  fail "Fallback includes Builder"
fi

heartbeat_model="$(jq -r '.agents.defaults.heartbeat.model // empty' "$CONFIG_PATH" 2>/dev/null || true)"
if [[ "$heartbeat_model" == "LocalFast" ]]; then
  pass "Heartbeat model is LocalFast"
else
  fail "Heartbeat model is LocalFast"
fi

if [[ -f "$AUTH_PROFILES" ]]; then
  pass "Auth profiles exist"
else
  fail "Auth profiles exist"
fi

if jq -e '.profiles["moonshot:default"]' "$AUTH_PROFILES" >/dev/null 2>&1; then
  pass "Moonshot auth profile available"
else
  fail "Moonshot auth profile available"
fi

if jq -e '.profiles["openai-codex:default"]' "$AUTH_PROFILES" >/dev/null 2>&1; then
  pass "OpenAI Codex auth profile available"
else
  fail "OpenAI Codex auth profile available"
fi

if [[ -f "$HOME/.openclaw/skills/ai-business-asset-foundry/SKILL.md" ]]; then
  pass "Skill ai-business-asset-foundry exists"
else
  fail "Skill ai-business-asset-foundry exists"
fi

if [[ -f "$HOME/.openclaw/skills/smb-agentic-opportunity-radar/SKILL.md" ]]; then
  pass "Skill smb-agentic-opportunity-radar exists"
else
  fail "Skill smb-agentic-opportunity-radar exists"
fi

if [[ -f "$EXPECTED_WORKSPACE/LEVERAGE_OS.md" ]]; then
  pass "Leverage OS doc exists"
else
  fail "Leverage OS doc exists"
fi

if [[ -x "$EXPECTED_WORKSPACE/scripts/install_leverage_crons.sh" ]]; then
  pass "Cron installer exists"
else
  fail "Cron installer exists"
fi

echo
if [[ "$failures" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "$failures checks failed."
fi

exit "$failures"
