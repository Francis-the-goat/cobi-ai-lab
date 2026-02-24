#!/bin/bash
# codex-wrapper.sh - Wrapper to run Codex with proper permissions for OpenClaw workspace

# Change to workspace directory
cd /Users/cobi/.openclaw/workspace

# Run codex with full access (not sandboxed)
# This allows it to actually write files
exec codex exec --skip-git-repo-check "$@"
