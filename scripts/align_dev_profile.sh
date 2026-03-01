#!/usr/bin/env bash
set -euo pipefail

MAIN_CFG="$HOME/.openclaw/openclaw.json"
DEV_CFG="$HOME/.openclaw-dev/openclaw.json"
TARGET_WORKSPACE="$HOME/.openclaw/workspace"
MAIN_AUTH_PROFILES="$HOME/.openclaw/agents/main/agent/auth-profiles.json"
DEV_AUTH_DIR="$HOME/.openclaw-dev/agents/dev/agent"
DEV_AUTH_PROFILES="$DEV_AUTH_DIR/auth-profiles.json"

if [[ ! -f "$MAIN_CFG" ]]; then
  echo "Main config not found: $MAIN_CFG"
  exit 1
fi

if [[ ! -f "$DEV_CFG" ]]; then
  echo "Dev config not found: $DEV_CFG"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required"
  exit 1
fi

dev_token="$(jq -r '.gateway.auth.token // ""' "$DEV_CFG")"

cp "$DEV_CFG" "${DEV_CFG}.bak.$(date +%Y%m%d-%H%M%S)"

jq \
  --arg workspace "$TARGET_WORKSPACE" \
  --arg token "$dev_token" \
  '
  .agents.defaults.workspace = $workspace |
  .agents.defaults.skipBootstrap = false |
  .agents.defaults.compaction.mode = "safeguard" |
  .agents.defaults.sandbox.mode = "all" |
  .agents.defaults.sandbox.workspaceAccess = "rw" |
  .agents.defaults.sandbox.scope = "agent" |
  .agents.list = ((.agents.list // [{"id":"dev","default":true}]) | map(.workspace = $workspace)) |
  .gateway.port = 19001 |
  .gateway.mode = "local" |
  .gateway.bind = "loopback" |
  .gateway.auth.mode = "token" |
  (if $token != "" then .gateway.auth.token = $token else . end) |
  .plugins.enabled = true |
  .plugins.entries.telegram.enabled = true |
  .channels.telegram.enabled = true
  ' "$MAIN_CFG" > "$DEV_CFG"

chmod 600 "$DEV_CFG"

if [[ -f "$MAIN_AUTH_PROFILES" ]]; then
  mkdir -p "$DEV_AUTH_DIR"
  cp "$MAIN_AUTH_PROFILES" "$DEV_AUTH_PROFILES"
  chmod 600 "$DEV_AUTH_PROFILES"
fi

echo "Aligned dev profile to main model/tool stack and workspace: $TARGET_WORKSPACE"
echo "Updated: $DEV_CFG"
if [[ -f "$DEV_AUTH_PROFILES" ]]; then
  echo "Synced auth profiles: $DEV_AUTH_PROFILES"
else
  echo "Warning: auth-profiles.json was not found in main profile; provider auth may still be missing."
fi
