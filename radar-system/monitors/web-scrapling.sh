#!/usr/bin/env bash
# Wrapper to run the Scrapling web monitor using the configured runtime.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/web-scrapling.py"
DEFAULT_VENV="${OPENCLAW_SCRAPLING_VENV:-$HOME/.openclaw/scrapling-venv}"

if [[ -x "$DEFAULT_VENV/bin/python3" ]]; then
  exec "$DEFAULT_VENV/bin/python3" "$PY_SCRIPT" "$@"
fi

exec python3 "$PY_SCRIPT" "$@"
