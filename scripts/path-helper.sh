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
