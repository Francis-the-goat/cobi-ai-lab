#!/bin/bash
# Fix for resource-harvest-video-web path issue
# Ensures agent reads from correct absolute path

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"

echo "=== Resource Harvest Path Fix ==="
echo "Checking file access from different contexts..."
echo ""

# Test 1: File exists
echo "1. Testing file existence:"
if [ -f "$WORKSPACE_PATH/memory/research/2026-03-02-resource-harvest.md" ]; then
    echo "   ✅ File exists at: $WORKSPACE_PATH/memory/research/2026-03-02-resource-harvest.md"
    echo "   Size: $(wc -c < "$WORKSPACE_PATH/memory/research/2026-03-02-resource-harvest.md") bytes"
else
    echo "   ❌ File not found"
fi

# Test 2: Can read from different working directories
echo ""
echo "2. Testing read from different CWD:"
echo "   From workspace: $(pwd)"
head -1 memory/research/2026-03-02-resource-harvest.md 2>/dev/null && echo "   ✅ OK" || echo "   ❌ Failed"

echo "   From home: ~"
(head -1 "$HOME/.openclaw/workspace/memory/research/2026-03-02-resource-harvest.md" 2>/dev/null | grep -q "Resource Harvest") && echo "   ✅ OK" || echo "   ❌ Failed"

echo ""
echo "=== Creating Robust Path Helper ==="

# Create a helper script that agents can source
cat > "$WORKSPACE_PATH/scripts/path-helper.sh" << 'EOF'
#!/bin/bash
# Path helper for agents - ensures correct paths regardless of CWD

export WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"
export VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"

# Helper function to get research file path
get_research_file() {
    local date="${1:-$(date +%Y-%m-%d)}"
    echo "$WORKSPACE_PATH/memory/research/${date}-resource-harvest.md"
}

# Helper function to check if research exists
research_exists() {
    local date="${1:-$(date +%Y-%m-%d)}"
    [ -f "$WORKSPACE_PATH/memory/research/${date}-resource-harvest.md" ]
}

# Helper function to read research content
read_research() {
    local date="${1:-$(date +%Y-%m-%d)}"
    local file="$WORKSPACE_PATH/memory/research/${date}-resource-harvest.md"
    if [ -f "$file" ]; then
        cat "$file"
    else
        echo "ERROR: Research file not found: $file" >&2
        return 1
    fi
}
EOF

chmod +x "$WORKSPACE_PATH/scripts/path-helper.sh"
echo "✅ Created: scripts/path-helper.sh"

echo ""
echo "=== Updating Resource Harvest Cron ==="

# Check current crontab and ensure it cds to workspace first
CRON_CONTENT=$(crontab -l 2>/dev/null || echo "")

# Check if we need to fix the working directory issue
if echo "$CRON_CONTENT" | grep -q "resource_harvest.sh" && ! echo "$CRON_CONTENT" | grep -q "cd.*workspace"; then
    echo "⚠️  Crontab may have CWD issues"
    echo ""
    echo "Current cron entries:"
    echo "$CRON_CONTENT" | grep resource | head -3
else
    echo "✅ Crontab appears correctly configured"
fi

echo ""
echo "=== Fix Summary ==="
echo "1. File exists and is readable: $(ls -la "$WORKSPACE_PATH/memory/research/2026-03-02-resource-harvest.md" | awk '{print $5}') bytes"
echo "2. Created path-helper.sh for agents to use correct absolute paths"
echo "3. If agent still fails, it needs to source path-helper.sh or use absolute paths"
echo ""
echo "For agents/scripts that read research data:"
echo "   source $WORKSPACE_PATH/scripts/path-helper.sh"
echo "   read_research  # or read_research 2026-03-02"
