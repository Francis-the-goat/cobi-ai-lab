#!/usr/bin/env bash
# Master script for SaaS Disruption Intelligence

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DIR="${OPENCLAW_SAAS_DIR:-$SCRIPT_DIR}"

case "${1:-help}" in
    analyze)
        echo "=== Signal Analysis ==="
        echo ""
        echo "Framework:"
        echo "1. What capability unlocked?"
        echo "2. What SaaS is vulnerable?"
        echo "3. What's the business model?"
        echo "4. Build, buy, partner, or ignore?"
        echo "5. What's the timing window?"
        echo "6. What's the execution path?"
        echo ""
        echo "Then score 1-5 on:"
        echo "  - Pain urgency"
        echo "  - Economic value"
        echo "  - Build speed"
        echo "  - Window duration"
        echo "  - Your advantage"
        echo ""
        echo "Output to: analysis/YYYY-MM-DD-signal.md"
        ;;
        
    thesis)
        echo "=== Core Thesis Documents ==="
        echo ""
        ls -1 "$DIR/thesis/" 2>/dev/null | while read f; do
            echo "  - $f"
        done
        echo ""
        echo "Read these for deep understanding of:"
        echo "  - Which SaaS categories are dying"
        echo "  - How pricing models are shifting"
        echo "  - Where your opportunities are"
        ;;
        
    queue)
        echo "=== Action Queue ==="
        echo ""
        cat "$DIR/action-queue.md" | head -60
        ;;
        
    new-signal)
        echo "=== Create New Signal Entry ==="
        echo ""
        read -p "Signal title: " title
        read -p "Source (e.g., 'Nate B Jones video'): " source
        
        SLUG=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | cut -c1-40)
        DATE=$(date +%Y-%m-%d)
        FILE="$DIR/signals/$DATE-$SLUG.md"
        
        cat > "$FILE" << SIGNAL
# $title
**Date:** $DATE  
**Source:** $source  
**Status:** Raw capture

## The Signal
[What was announced/discovered]

## Links
- [Primary source]()
- [Related]()

## Initial Reaction
[Your first thoughts]

---

## Analysis (to be completed)
Run through analysis-framework.md

1. Capability unlock:
2. SaaS vulnerability:
3. Business model:
4. Build/Buy/Partner/Ignore:
5. Timing window:
6. Execution path:

## Score
- Pain urgency: /5
- Economic value: /5
- Build speed: /5
- Window duration: /5
- Your advantage: /5
- **Total: /30**

## Decision
[What to do]
SIGNAL

        echo "Created: $FILE"
        echo ""
        echo "Next: Fill in analysis section"
        ;;
        
    opportunities)
        echo "=== Scored Opportunities ==="
        ls -1t "$DIR/opportunities/" 2>/dev/null | head -10 | while read f; do
            SCORE=$(grep -o "Total: [0-9]*" "$DIR/opportunities/$f" 2>/dev/null | head -1)
            echo "  $f $SCORE"
        done
        ;;
        
    status)
        echo "=== SaaS Disruption Intelligence Status ==="
        echo ""
        echo "Signals captured: $(ls -1 "$DIR/signals/" 2>/dev/null | wc -l)"
        echo "Analyzed: $(ls -1 "$DIR/analysis/" 2>/dev/null | wc -l)"
        echo "Opportunities: $(ls -1 "$DIR/opportunities/" 2>/dev/null | wc -l)"
        echo ""
        echo "Core thesis documents:"
        ls -1 "$DIR/thesis/" 2>/dev/null | sed 's/^/  /'
        echo ""
        echo "Next action from queue:"
        grep -A 2 "## Immediate" "$DIR/action-queue.md" | head -5
        ;;
        
    help|*)
        echo "SaaS Disruption Intelligence System"
        echo ""
        echo "Commands:"
        echo "  analyze       - Show analysis framework"
        echo "  thesis        - List core thesis documents"
        echo "  queue         - Show action queue"
        echo "  new-signal    - Create new signal entry"
        echo "  opportunities - List scored opportunities"
        echo "  status        - System overview"
        echo ""
        echo "Workflow:"
        echo "  1. Detect signal (from channels)"
        echo "  2. ./run.sh new-signal"
        echo "  3. Fill in analysis (use analysis-framework.md)"
        echo "  4. If score >=25, create opportunity"
        echo "  5. Execute from action-queue"
        echo ""
        echo "Focus: SaaS → Agent transition opportunities"
        ;;
esac
