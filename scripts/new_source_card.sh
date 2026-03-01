#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-}"
SOURCE_URL="${2:-}"
SOURCE_TITLE="${3:-Unknown Source}"

if [[ -z "$SLUG" ]]; then
  echo "Usage: $0 <slug> [url] [title]"
  exit 1
fi

WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
OUT_DIR="$WORKSPACE_DIR/memory/sources"
DATE_STR="$(date +%Y-%m-%d)"
OUT_FILE="$OUT_DIR/${DATE_STR}-${SLUG}.md"

mkdir -p "$OUT_DIR"

cat > "$OUT_FILE" <<CARD
# Source Card: ${SOURCE_TITLE}

- Date: ${DATE_STR}
- URL: ${SOURCE_URL}
- Type: 
- Creator: 

## 1) Core Claims
- 

## 2) Evidence Quality
- Strong evidence:
- Weak/assumed points:

## 3) Transferable Frameworks
- 

## 4) Application Context
- Target workflow:
- Baseline KPI:
- Target KPI:

## 5) Style Patterns To Adopt
- Hook style:
- Structure style:
- CTA style:

## 6) Adopt / Reject
- Adopt:
- Reject:

## 7) Action Extracted Today
- Decision:
- Next action:
CARD

echo "Created: $OUT_FILE"
