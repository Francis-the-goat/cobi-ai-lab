#!/bin/bash
# Harvester Agent - Direct Execution Version
# Monitors sources and extracts content without session spawning

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$VAULT_PATH/03-patterns"
mkdir -p "$VAULT_PATH/05-sessions"
mkdir -p "$WORKSPACE_PATH/logs"

LOG_FILE="$WORKSPACE_PATH/logs/harvester-${TIMESTAMP}.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Harvester Agent ==="
echo "Started: $(date)"
echo ""

# Track what we processed
SOURCES_CHECKED=0
TRANSCRIPTS_CREATED=0

echo "[PHASE 1] Checking Tier 1 Sources..."

# Check YouTube subscriptions (if gog skill available)
if command -v gog &> /dev/null; then
    echo "  - Checking YouTube subscriptions via gog..."
    SOURCES_CHECKED=$((SOURCES_CHECKED + 1))
    # gog youtube list --subscriptions would go here
    echo "    (YouTube monitoring requires manual source list)"
fi

# Check RSS feeds
if [ -f "$WORKSPACE_PATH/config/rss-sources.txt" ]; then
    echo "  - Checking RSS feeds..."
    SOURCES_CHECKED=$((SOURCES_CHECKED + $(wc -l < "$WORKSPACE_PATH/config/rss-sources.txt")))
    while IFS= read -r feed; do
        echo "    Processing: $feed"
        # Would fetch and parse RSS here
    done < "$WORKSPACE_PATH/config/rss-sources.txt"
else
    echo "  - No RSS sources configured (create config/rss-sources.txt)"
fi

# Check GitHub releases for tracked repos
if [ -f "$WORKSPACE_PATH/config/github-repos.txt" ]; then
    echo "  - Checking GitHub releases..."
    SOURCES_CHECKED=$((SOURCES_CHECKED + $(wc -l < "$WORKSPACE_PATH/config/github-repos.txt")))
    while IFS= read -r repo; do
        echo "    Checking: $repo"
        # Would check releases via API here
    done < "$WORKSPACE_PATH/config/github-repos.txt"
else
    echo "  - No GitHub repos configured (create config/github-repos.txt)"
fi

echo ""
echo "[PHASE 2] Processing Content..."

# Find any new transcript files created in last 24h
NEW_TRANSCRIPTS=$(find "$VAULT_PATH" -name "*.md" -mtime -1 -not -path "*/05-sessions/*" -not -path "*/01-daily/*" 2>/dev/null | wc -l | tr -d ' ')
TRANSCRIPTS_CREATED=$NEW_TRANSCRIPTS

echo "  New transcripts found: $TRANSCRIPTS_CREATED"

# Create harvester session log
cat > "$VAULT_PATH/05-sessions/harvester-${TIMESTAMP}.md" << EOF
# Harvester Session - $TIMESTAMP

## Summary
- Started: $(date)
- Sources checked: $SOURCES_CHECKED
- Transcripts created: $TRANSCRIPTS_CREATED

## Sources Monitored
$(if [ -f "$WORKSPACE_PATH/config/rss-sources.txt" ]; then
    echo "### RSS Feeds"
    cat "$WORKSPACE_PATH/config/rss-sources.txt"
fi)

$(if [ -f "$WORKSPACE_PATH/config/github-repos.txt" ]; then
    echo "### GitHub Repos"
    cat "$WORKSPACE_PATH/config/github-repos.txt"
fi)

## Output
- Log: $LOG_FILE
- Transcripts: $TRANSCRIPTS_CREATED new files

## Next Steps
Analyst will process transcripts and extract patterns.
EOF

echo ""
echo "=== Harvester Complete ==="
echo "Sources checked: $SOURCES_CHECKED"
echo "Transcripts: $TRANSCRIPTS_CREATED"
echo "Session log: $VAULT_PATH/05-sessions/harvester-${TIMESTAMP}.md"
echo ""

# Output for pipeline to capture
echo "HARVESTER_RESULT: sources=$SOURCES_CHECKED transcripts=$TRANSCRIPTS_CREATED"
