#!/usr/bin/env bash
# Install/upgrade a dedicated Scrapling runtime for OpenClaw tooling.

set -euo pipefail

DEFAULT_VENV="${OPENCLAW_SCRAPLING_VENV:-$HOME/.openclaw/scrapling-venv}"
VENV_DIR="$DEFAULT_VENV"
WITH_AI=0
WITH_BROWSERS=0

usage() {
  cat <<'EOF'
Usage: install_scrapling_runtime.sh [options]

Options:
  --venv <path>         Install into a custom virtualenv path
  --with-ai             Install MCP extras (scrapling[ai])
  --with-browsers       Install Playwright browser dependencies (scrapling install)
  -h, --help            Show this help

Examples:
  bash scripts/install_scrapling_runtime.sh
  bash scripts/install_scrapling_runtime.sh --with-ai
  bash scripts/install_scrapling_runtime.sh --with-ai --with-browsers
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --venv)
      VENV_DIR="$2"
      shift 2
      ;;
    --with-ai)
      WITH_AI=1
      shift
      ;;
    --with-browsers)
      WITH_BROWSERS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found. Install Python 3 first." >&2
  exit 1
fi

mkdir -p "$(dirname "$VENV_DIR")"

if [[ ! -x "$VENV_DIR/bin/python3" ]]; then
  echo "Creating virtualenv: $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

echo "Upgrading pip/setuptools/wheel..."
python3 -m pip install --upgrade pip setuptools wheel

EXTRAS="fetchers"
if [[ "$WITH_AI" -eq 1 ]]; then
  EXTRAS="ai"
fi

echo "Installing Scrapling with extras: [$EXTRAS]"
python3 -m pip install --upgrade "scrapling[$EXTRAS]>=0.4,<0.5"

if [[ "$WITH_BROWSERS" -eq 1 ]]; then
  echo "Installing browser dependencies (this can take a while)..."
  "$VENV_DIR/bin/scrapling" install
fi

cat <<EOF

Scrapling runtime ready.
  Venv: $VENV_DIR
  Scrapling binary: $VENV_DIR/bin/scrapling

Recommended env var:
  export OPENCLAW_SCRAPLING_VENV="$VENV_DIR"
EOF
