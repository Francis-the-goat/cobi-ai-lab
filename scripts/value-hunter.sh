#!/bin/bash
# Value Hunter Analyst v2
# Extracts actionable, monetizable patterns from content
# Focus: Claude Code, OpenClaw, Agentic AI

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$VAULT_PATH/03-patterns"
mkdir -p "$VAULT_PATH/04-decisions/value-cards"
mkdir -p "$VAULT_PATH/05-sessions"
mkdir -p "$WORKSPACE_PATH/logs"

LOG_FILE="$WORKSPACE_PATH/logs/value-hunter-${TIMESTAMP}.log"

echo "=== Value Hunter Analyst v2 ===" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Focus: Claude Code | OpenClaw | Agentic AI | MRR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Target keywords for high-value extraction
KEYWORDS="claude code|openclaw|agentic|multi-agent|orchestration|MCP|Model Context Protocol|autonomous|production-ready|deploy|skill|workflow|automation"

# Find content from last 24h
CONTENT_FILES=$(find "$VAULT_PATH" -name "*.md" -mtime -1 \
    -not -path "*/03-patterns/*" \
    -not -path "*/04-decisions/*" \
    -not -path "*/05-sessions/*" \
    -not -path "*/01-daily/*" \
    -not -path "*/self-improvement/*" 2>/dev/null | head -20 || true)

if [ -z "$CONTENT_FILES" ]; then
    echo "No new content to analyze" | tee -a "$LOG_FILE"
    exit 0
fi

FILE_COUNT=$(echo "$CONTENT_FILES" | wc -l | tr -d ' ')
echo "Scanning $FILE_COUNT files for value..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

HIGH_VALUE_COUNT=0

# Process each content file
for content_file in $CONTENT_FILES; do
    if [ ! -f "$content_file" ]; then
        continue
    fi
    
    FILENAME=$(basename "$content_file" .md)
    echo "Analyzing: $FILENAME" | tee -a "$LOG_FILE"
    
    # Check for keyword matches
    MATCH_COUNT=$(grep -ciE "$KEYWORDS" "$content_file" 2>/dev/null | tr -d ' ' || echo "0")
    MATCH_COUNT=${MATCH_COUNT:-0}
    
    # Skip if no relevant keywords
    if [ "$MATCH_COUNT" -eq 0 ]; then
        echo "  → No high-value keywords found, skipping" | tee -a "$LOG_FILE"
        continue
    fi
    
    echo "  → Found $MATCH_COUNT keyword matches" | tee -a "$LOG_FILE"
    
    # Determine value type
    if grep -qi "skill\|template\|reusable" "$content_file" 2>/dev/null; then
        VALUE_TYPE="skill-template"
    elif grep -qi "workflow\|process\|pipeline" "$content_file" 2>/dev/null; then
        VALUE_TYPE="workflow"
    elif grep -qi "tool\|script\|automation" "$content_file" 2>/dev/null; then
        VALUE_TYPE="internal-tool"
    elif grep -qi "tutorial\|how.*to\|guide" "$content_file" 2>/dev/null; then
        VALUE_TYPE="content-draft"
    else
        VALUE_TYPE="research-note"
    fi
    
    # Assess implementation clarity (simplified)
    if grep -q "^\`\`\`" "$content_file" 2>/dev/null; then
        # Has code blocks
        if [ $(grep "^\`\`\`" "$content_file" 2>/dev/null | wc -l | awk '{print $1}') -ge 6 ]; then
            CLARITY="8-10"
            EFFORT="2-4 hours"
        else
            CLARITY="5-7"
            EFFORT="4-8 hours"
        fi
    else
        CLARITY="3-5"
        EFFORT="8+ hours"
    fi
    
    # Assess MRR potential
    MRR_POTENTIAL="Low (3-5)"
    MRR_NOTE="Research/learning value"
    
    if grep -qi "client\|service\|sell\|offer\|mrr\|revenue" "$content_file" 2>/dev/null; then
        MRR_POTENTIAL="High (7-10)"
        MRR_NOTE="Direct service application"
    elif grep -qi "productivity\|save time\|efficiency" "$content_file" 2>/dev/null; then
        MRR_POTENTIAL="Medium (5-7)"
        MRR_NOTE="Indirect time savings"
    fi
    
    # Create value card
    CARD_FILE="$VAULT_PATH/04-decisions/value-cards/${FILENAME}-value.md"
    
    case "$VALUE_TYPE" in
        "skill-template") RECOMMENDATION="BUILD: Create as ClawHub skill for client reuse" ;;
        "workflow") RECOMMENDATION="BUILD: Document as internal workflow template" ;;
        "internal-tool") RECOMMENDATION="BUILD: Create tool for personal productivity" ;;
        "content-draft") RECOMMENDATION="WRITE: Create blog/video content from this" ;;
        *) RECOMMENDATION="RESEARCH: File for future reference" ;;
    esac
    
    cat > "$CARD_FILE" << EOF
# Value Card: $FILENAME

## Source
- File: $content_file
- Analyzed: $(date)

## Keyword Matches
$MATCH_COUNT relevant keywords found

## Value Assessment

### Asset Type
**$VALUE_TYPE**

### Implementation Clarity
**$CLARITY/10**

### Estimated Effort
**$EFFORT**

### MRR Potential
**$MRR_POTENTIAL**  
${MRR_NOTE}

### Cost to Build
**\$0** (local models only)

## Core Insight
$(grep -iE "$KEYWORDS" "$content_file" 2>/dev/null | head -3 || echo "[See source file for details]")

## Recommended Action
**$RECOMMENDATION**

## Build Command
\`\`\`bash
# To build this asset, reply:
build $FILENAME
\`\`\`

## Next Steps
- [ ] Review value assessment
- [ ] Approve/reject build (reply: build $FILENAME)
- [ ] If approved: auto-build within 24h
- [ ] If rejected: archive with reason

---
Status: **Proposed** | Created: $(date)
EOF
    
    echo "  → Created value card" | tee -a "$LOG_FILE"
    
    # Also create pattern note if doesn't exist
    PATTERN_FILE="$VAULT_PATH/03-patterns/${FILENAME}-pattern.md"
    if [ ! -f "$PATTERN_FILE" ]; then
        cat > "$PATTERN_FILE" << EOF
# Pattern: $FILENAME

## Thinking Architecture
$(grep "^#" "$content_file" 2>/dev/null | head -5 || echo "[Extracted from content]")

## Key Concepts
$(grep -iE "$KEYWORDS" "$content_file" 2>/dev/null | head -5 || echo "[See value card for details]")

## Application
Reusable insight for $(case "$VALUE_TYPE" in
    skill-template) echo "client projects" ;;  
    workflow) echo "workflow optimization" ;;
    internal-tool) echo "productivity enhancement" ;;
    *) echo "knowledge base" ;;
esac)

## Linked Value Card
[[${FILENAME}-value|View Value Assessment]]

---
Status: Extracted | Value: $MRR_POTENTIAL
EOF
        echo "  → Created pattern note" | tee -a "$LOG_FILE"
    fi
    
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo "" | tee -a "$LOG_FILE"
done

# Create session summary
cat > "$VAULT_PATH/05-sessions/value-hunter-${TIMESTAMP}.md" << EOF
# Value Hunter Session - $TIMESTAMP

## Summary
- Started: $(date)
- Files scanned: $FILE_COUNT
- High-value items found: $HIGH_VALUE_COUNT

## Value Cards Created
$(ls -1t "$VAULT_PATH/04-decisions/value-cards/"/*-value.md 2>/dev/null | head -10 | while read f; do echo "- $(basename "$f")"; done || echo "None")

## Next Actions
$(if [ $HIGH_VALUE_COUNT -gt 0 ]; then
    echo "Review value cards in 04-decisions/value-cards/"
    echo "Reply 'build [name]' to approve any asset"
else
    echo "No high-value content found in this batch"
fi)

## Log
$LOG_FILE
EOF

echo "=== Value Hunter Complete ===" | tee -a "$LOG_FILE"
echo "High-value items found: $HIGH_VALUE_COUNT" | tee -a "$LOG_FILE"
echo "Value cards: $VAULT_PATH/04-decisions/value-cards/" | tee -a "$LOG_FILE"
echo "Session log: $VAULT_PATH/05-sessions/value-hunter-${TIMESTAMP}.md" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Output for pipeline
echo "VALUE_HUNTER_RESULT: found=$HIGH_VALUE_COUNT status=success"
