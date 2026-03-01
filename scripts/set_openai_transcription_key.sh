#!/usr/bin/env bash
set -euo pipefail

CFG="/Users/cobi/.openclaw/workspace/config/transcription.env"

if [[ ! -f "$CFG" ]]; then
  echo "Missing config file: $CFG" >&2
  exit 1
fi

read -r -s -p "Paste OPENAI_API_KEY: " KEY
echo

if [[ -z "$KEY" ]]; then
  echo "No key entered; aborting." >&2
  exit 1
fi

if grep -q '^OPENAI_API_KEY=' "$CFG"; then
  sed -i '' "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=$KEY|" "$CFG"
else
  printf '\nOPENAI_API_KEY=%s\n' "$KEY" >> "$CFG"
fi

chmod 600 "$CFG"
echo "Saved OPENAI_API_KEY to $CFG"
