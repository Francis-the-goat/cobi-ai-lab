#!/usr/bin/env bash
# Master script for AI Alpha Learning System

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

COMMAND="${1:-help}"

count_lines() {
  local file="$1"
  if [ -f "$file" ]; then
    wc -l < "$file" | tr -d ' '
  else
    echo 0
  fi
}

case "$COMMAND" in
    check)
        echo "=== Checking for New Content ==="
        "$SCRIPT_DIR/check-channels.sh"
        ;;
        
    study)
        # Process next item in queue
        echo "=== Starting Study Session ==="
        "$SCRIPT_DIR/process-content.sh" --queue
        ;;
        
    process-specific)
        # Process specific content
        LINE="$2"
        if [ -z "$LINE" ]; then
            echo "Usage: $0 process-specific '<content_line>'"
            exit 1
        fi
        "$SCRIPT_DIR/process-content.sh" "$LINE"
        ;;
        
    list)
        echo "=== Learning Queue ==="
        echo ""
        echo "Tier 1 (Core Curriculum):"
        if [ -s "$INBOX_DIR/tier1-youtube.txt" ]; then
            nl "$INBOX_DIR/tier1-youtube.txt" | while read num line; do
                AUTHOR=$(echo "$line" | cut -d'|' -f2)
                TITLE=$(echo "$line" | cut -d'|' -f3)
                echo "  $num. [$AUTHOR] $TITLE"
            done
        else
            echo "  (empty - run 'check' to find new content)"
        fi
        echo ""
        ;;
        
    status)
        echo "=== AI Alpha Learning System Status ==="
        echo ""
        
        PENDING="$(count_lines "$INBOX_DIR/tier1-youtube.txt")"
        STUDIED=$(find "$CURRICULUM_DIR" -name "study-note.md" 2>/dev/null | wc -l | tr -d ' ')
        
        echo "Pending to study: $PENDING"
        echo "Studied: $STUDIED"
        echo ""
        
        if [ "$PENDING" -gt 0 ]; then
            echo "Next up:"
            head -1 "$INBOX_DIR/tier1-youtube.txt" | cut -d'|' -f3
        fi
        echo ""
        
        # Show recent studied
        echo "Recently studied:"
        find "$CURRICULUM_DIR" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | \
          while IFS= read -r dir; do basename "$dir"; done | sort -r | head -3
        ;;
        
    mastery)
        echo "=== Mastery Log ==="
        LOG="$WORKSPACE_DIR/mastery-log.md"
        if [ -f "$LOG" ]; then
            tail -50 "$LOG"
        else
            echo "No mastery log yet. Start studying!"
        fi
        ;;
        
    full)
        # Check + process all
        echo "=== Full Pipeline ==="
        "$SCRIPT_DIR/check-channels.sh"
        echo ""
        while [ -s "$INBOX_DIR/tier1-youtube.txt" ]; do
            echo "Processing next..."
            "$SCRIPT_DIR/process-content.sh" --queue
            echo ""
        done
        echo "=== All caught up ==="
        ;;
        
    demo-study)
        # Create example study note
        DEMO_DIR="$CURRICULUM_DIR/agentic-systems/2026-02-25-karpathy-llm-os"
        mkdir -p "$DEMO_DIR"
        
        cat > "$DEMO_DIR/study-note.md" << 'DEMO'
# Intro to Large Language Models (1hr Talk)
**Source:** YouTube — Andrej Karpathy  
**Date:** 2023-11-13  
**Type:** Video (Educational)  
**Tier:** 1 (Core Curriculum)

---

## The Core Idea

LLMs are next-token prediction machines trained on internet text. They compress human knowledge into weights and can be conditioned (prompted) to perform tasks they weren't explicitly trained for.

---

## Why It Matters for Cobi

Understanding LLMs at this level lets you:
- Debug agent failures (is it the model or the prompt?)
- Choose right model for task (latency vs capability tradeoffs)
- Build better prompting strategies
- Explain to clients how this actually works (builds trust)

---

## Knowledge Extraction

### Mental Model: "LLM as a Dreaming Brain"
Karpathy describes LLMs as dreaming — they hallucinate because they're not grounded, just predicting patterns. This helps me understand:
- Why RAG is necessary (ground the dream in facts)
- Why agents need tool use (let them check reality)
- Why prompting matters (steer the dream)

### Technical Pattern: Tokenization → Transformer → Sampling
The full pipeline:
1. **Tokenization** — Text → numbers (40K vocab)
2. **Transformer** — Process with attention mechanism
3. **Sampling** — Generate next token (temperature controls randomness)

**For my work:**
- Token counting = cost estimation
- Temperature = creativity vs reliability dial
- Context window = working memory limit

### Tacit Knowledge
- "Pretraining is the easy part, RLHF is the secret sauce" — OpenAI's real moat isn't model size, it's alignment
- He emphasizes that smaller models are surprisingly capable with good prompting
- The "system 1 vs system 2" analogy — LLMs are fast intuitive thinking, need to add slow deliberate thinking via agents

### Market/Timing Context
- This talk was Nov 2023 — pre-GPT-4 turbo, pre-Claude 3
- Models are getting faster and cheaper (his prediction held)
- Local models becoming viable for many use cases

---

## Key Quotes

> "LLMs are the kernel of a new operating system."

> "Pretraining is the computational phase, but the post-training phase is where the magic happens."

> "The context window is the working memory of the model."

---

## Connections

- Connects to **swyx's** "LLMs are platforms not products"
- Builds on **Nate's** "sell outcomes not AI" — LLM is the mechanism, not the value
- Contradicts hype about AGI timelines — he's conservative/practical

---

## Exercises for Mastery

### Immediate (This Week)
- [x] Watch full video with notes
- [ ] Build a token counter tool (estimate costs)
- [ ] Experiment with temperature settings in Claude

### Implementation (This Month)
- [ ] Implement basic RAG system (ground the "dream")
- [ ] Build prompt evaluation framework
- [ ] Test local model vs API for specific task

### Teaching (Solidify)
- [ ] Write thread: "What I learned from Karpathy's 1hr LLM talk"
- [ ] Explain to non-technical friend how LLMs work

---

## Mastery Checklist

- [x] Can explain to beginner (did this with roommate)
- [ ] Can implement tokenizer from scratch (doable but haven't)
- [x] Can adapt: Used temperature knowledge to tune agent responses
- [ ] Can teach: Thread drafted but not published

---

## Related

- Video: https://www.youtube.com/watch?v=zjkBMFhNj_g
- Notes: https://karpathy.ai/zero-to-hero.html
- Next: Watch "Let's build GPT" (implementation)
DEMO

        echo "Demo study note created:"
        echo "  $DEMO_DIR/study-note.md"
        echo ""
        cat "$DEMO_DIR/study-note.md" | head -40
        ;;
        
    help|*)
        echo "AI Alpha Learning System"
        echo ""
        echo "Commands:"
        echo "  check              - Check all channels for new content"
        echo "  list               - Show learning queue"
        echo "  study              - Process next item in queue"
        echo "  process-specific   - Process specific content line"
        echo "  status             - System status"
        echo "  mastery            - View mastery log"
        echo "  full               - Check + process all pending"
        echo "  demo-study         - Show example study note"
        echo ""
        echo "Learning Workflow:"
        echo "  1. $0 check              (find new content)"
        echo "  2. $0 list               (see what's queued)"
        echo "  3. $0 study              (start learning)"
        echo "  4. Fill in study-note.md using extraction prompt"
        echo "  5. Do exercises, check mastery"
        echo ""
        echo "Goal: Process 2-3 Tier 1 pieces per week deeply"
        ;;
esac
