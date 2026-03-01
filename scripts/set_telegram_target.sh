#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-dev}"
TARGET="${2:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <profile> <telegram_chat_id_or_username>"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required"
  exit 1
fi

list_json="$(openclaw --profile "$PROFILE" cron list --all --json)"

ids=()
while IFS= read -r id; do
  [[ -n "$id" ]] && ids+=("$id")
done < <(printf '%s' "$list_json" | jq -r '.jobs[]?.id')

if [[ "${#ids[@]}" -eq 0 ]]; then
  echo "No cron jobs found for profile '$PROFILE'."
  exit 1
fi

for id in "${ids[@]}"; do
  echo "Updating cron job $id -> telegram target $TARGET"
  openclaw --profile "$PROFILE" cron edit "$id" --announce --channel telegram --to "$TARGET" --enable >/dev/null

done

echo
echo "Updated ${#ids[@]} jobs."
openclaw --profile "$PROFILE" cron list --all
