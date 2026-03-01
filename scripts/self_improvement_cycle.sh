#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-dev}"
DAYS="${2:-7}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required"
  exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI is required"
  exit 1
fi

python3 "$SCRIPT_DIR/self_improvement_sync.py" \
  --profile "$PROFILE" \
  --workspace "$WORKSPACE_DIR" \
  --days "$DAYS"

REPORT_PATH="$WORKSPACE_DIR/self-improvement/reports/latest.md"
if [[ -f "$REPORT_PATH" ]]; then
  echo ""
  echo "=== Self-Improvement Report (Latest) ==="
  sed -n '1,80p' "$REPORT_PATH"
fi
