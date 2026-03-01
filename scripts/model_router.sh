#!/bin/bash
route_model() {
  local task_type="${1:-}"
  local job_name="${2:-}"

  case "$job_name" in
    orchestrator-daily-plan|intel-midday-synthesis|proof-daily-content-draft) echo "moonshot/kimi-k2.5" ;;
    foundry-daily-build-candidate) echo "openai-codex/gpt-5.3-codex" ;;
    resource-harvest-video-web|transcription-retry-worker) echo "ollama/qwen2.5:3b" ;;
    warehouse-shift-handoff|source-adaptation-recommender|self-improvement-sync) echo "ollama/qwen2.5:7b" ;;
    security-daily-posture) echo "" ;;
    *)
      case "$task_type" in
        harvest|scan) echo "ollama/qwen2.5:3b" ;;
        synthesize|plan|content) echo "moonshot/kimi-k2.5" ;;
        build) echo "openai-codex/gpt-5.3-codex" ;;
        *) echo "ollama/qwen2.5:3b" ;;
      esac
      ;;
  esac
}
export -f route_model
