#!/bin/bash
# Manual Pattern Analysis
# Analyze a specific pattern file on demand

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VAULT_PATH="${SKILL_VAULT_PATH:-$HOME/obsidian/openclaw}"
CONFIG_FILE="$SKILL_DIR/config.yaml"

# Parse arguments
SOURCE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --pattern)
            PATTERN_FILE="$2"
            shift 2
            ;;
        --vault)
            VAULT_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== Manual Pattern Analysis ==="

if [ -n "${PATTERN_FILE:-}" ]; then
    # Direct file path
    if [ ! -f "$PATTERN_FILE" ]; then
        echo "Error: Pattern file not found: $PATTERN_FILE"
        exit 1
    fi
    python3 "$SKILL_DIR/scripts/evaluate-buildability.py" \
        --pattern "$PATTERN_FILE" \
        --vault "$VAULT_PATH" \
        --config "$CONFIG_FILE"
    
elif [ -n "$SOURCE" ]; then
    # Find pattern by source name
    PATTERN_FILE="$VAULT_PATH/03-patterns/${SOURCE}.md"
    
    if [ ! -f "$PATTERN_FILE" ]; then
        # Try partial match
        PATTERN_FILE=$(find "$VAULT_PATH/03-patterns" -name "*${SOURCE}*.md" | head -1)
    fi
    
    if [ -z "$PATTERN_FILE" ] || [ ! -f "$PATTERN_FILE" ]; then
        echo "Error: Could not find pattern matching: $SOURCE"
        echo "Available patterns:"
        ls -1 "$VAULT_PATH/03-patterns"/*.md | head -10
        exit 1
    fi
    
    echo "Analyzing: $(basename "$PATTERN_FILE")"
    python3 "$SKILL_DIR/scripts/evaluate-buildability.py" \
        --pattern "$PATTERN_FILE" \
        --vault "$VAULT_PATH" \
        --config "$CONFIG_FILE"
    
else
    echo "Usage:"
    echo "  $0 --source nate-2026-02-28"
    echo "  $0 --pattern /path/to/pattern.md"
    exit 1
fi
