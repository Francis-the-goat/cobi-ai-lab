#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-dev}"
DAYS="${2:-7}"
MIN_NEW_RUNS="${3:-2}"

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

bash "$SCRIPT_DIR/self_improvement_cycle.sh" "$PROFILE" "$DAYS"

python3 "$SCRIPT_DIR/self_improvement_autopromote.py" \
  --profile "$PROFILE" \
  --workspace "$WORKSPACE_DIR" \
  --min-new-runs "$MIN_NEW_RUNS"

AUTO_REPORT_PATH="$WORKSPACE_DIR/self-improvement/reports/auto-promotion-latest.md"
if [[ -f "$AUTO_REPORT_PATH" ]]; then
  echo ""
  echo "=== Auto-Promotion Report (Latest) ==="
  sed -n '1,80p' "$AUTO_REPORT_PATH"
fi
