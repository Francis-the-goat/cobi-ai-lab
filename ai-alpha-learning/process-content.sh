#!/usr/bin/env bash
# Process content for learning (download, transcribe, create study template)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

CONTENT_LINE="${1:-}"

if [ -z "$CONTENT_LINE" ]; then
    echo "Usage: $0 '<content_line_from_inbox>'"
    echo "Or process first in queue: $0 --queue"
    exit 1
fi

# If --queue flag, process first pending
if [ "$CONTENT_LINE" == "--queue" ]; then
    QUEUE_FILE="$INBOX_DIR/tier1-youtube.txt"
    if [ ! -s "$QUEUE_FILE" ]; then
        echo "No pending content in queue"
        exit 0
    fi
    CONTENT_LINE=$(head -1 "$QUEUE_FILE")
fi

# Parse content line
# Format: youtube:ID|author|title|date|url|duration
PLATFORM=$(echo "$CONTENT_LINE" | cut -d':' -f1)
REST=$(echo "$CONTENT_LINE" | cut -d':' -f2-)
ID=$(echo "$REST" | cut -d'|' -f1)
AUTHOR=$(echo "$REST" | cut -d'|' -f2)
TITLE=$(echo "$REST" | cut -d'|' -f3)
DATE=$(echo "$REST" | cut -d'|' -f4)
URL=$(echo "$REST" | cut -d'|' -f5)
DURATION=$(echo "$REST" | cut -d'|' -f6)

echo "Processing: $TITLE"
echo "By: $AUTHOR"
echo ""

# Create study directory
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -dc 'a-z0-9-_' | cut -c1-50)
STUDY_DIR="$CURRICULUM_DIR/inbox/$(date +%Y-%m-%d)-$AUTHOR-$SLUG"
mkdir -p "$STUDY_DIR"

echo "Study directory: $STUDY_DIR"

# Save metadata
cat > "$STUDY_DIR/meta.json" << META
{
  "id": "$ID",
  "platform": "$PLATFORM",
  "author": "$AUTHOR",
  "title": "$TITLE",
  "date": "$DATE",
  "url": "$URL",
  "duration": "$DURATION",
  "processed_at": "$(date -Iseconds)"
}
META

# Step 1: Download (if yt-dlp available)
if command -v yt-dlp &> /dev/null; then
    echo "[1/3] Downloading..."
    if ! yt-dlp -x --audio-format mp3 --audio-quality 0 \
        -o "$STUDY_DIR/audio.%(ext)s" "$URL" 2>&1 | tail -3; then
        echo "Download failed; continuing with template-only flow."
    fi
fi

# Step 2: Transcribe (if whisper available)
if [ -f "$STUDY_DIR/audio.mp3" ] && command -v whisper &> /dev/null; then
    echo "[2/3] Transcribing..."
    whisper "$STUDY_DIR/audio.mp3" --model base --language en \
        --output_format txt --output_dir "$STUDY_DIR" 2>&1 | tail -3
fi

# Step 3: Create study note template
echo "[3/3] Creating study template..."

cat > "$STUDY_DIR/study-note.md" << STUDY
# $TITLE
**Source:** YouTube — $AUTHOR  
**Date:** $DATE  
**Type:** Video  
**Tier:** 1 (Core Curriculum)

---

## The Core Idea

[1-2 sentences capturing the essence]

---

## Why It Matters for Cobi

- Building AI agency for SMBs
- Goal: Exit 9-5 in 12 months
- Current: Pre-revenue, learning phase

[Connect to your specific goals]

---

## Knowledge Extraction

### Mental Model
[How does $AUTHOR think about this problem?]

### Technical Pattern
[What are they actually building/using?]

### Tacit Knowledge
[What's implied but not stated?]

### Market/Timing Context
[Why now? What has changed?]

---

## Key Quotes

> 

> 

---

## Connections

- 

---

## Exercises

- [ ] 

---

## Mastery

- [ ] Can explain to beginner
- [ ] Can implement without reference
- [ ] Can teach it

---

## Analysis Prompt

To extract full value, feed the transcript to Claude with:

"Analyze this content from $AUTHOR for learning value. Extract:
1. Mental models and frameworks
2. Technical patterns and implementation details  
3. Tacit knowledge (what's assumed)
4. Market timing signals
5. How this applies to someone building an AI agency for SMBs

Content: [paste transcript]"
STUDY

# Create extraction prompt
cat > "$STUDY_DIR/extract-knowledge.txt" << EXTRACT
You are helping Cobi extract maximum learning value from this $AUTHOR video.

Cobi's context:
- 20 years old, Gold Coast Australia
- Works warehouse 3 days/week
- Building AI agency for SMBs (home services focus)
- Goal: Exit 9-5 in 12 months
- Learning: OpenClaw, agentic systems, Claude Code

CONTENT TO ANALYZE:
Title: $TITLE
Author: $AUTHOR

TRANSCRIPT:
[paste from transcript.txt or manually summarize]

EXTRACT:

1. MENTAL MODELS
What frameworks or ways of thinking does $AUTHOR use?
- 
- 

2. TECHNICAL PATTERNS
What are they actually building? Architecture, tools, stack?
- 
- 

3. TACIT KNOWLEDGE
What do they assume the audience knows?
What would a beginner miss?
- 

4. MARKET/TIMING
Why is this relevant now?
What's the 6-month outlook?
- 

5. COBI TRANSLATION
How does this specifically apply to:
- Building an SMB-focused AI agency?
- Learning agentic systems?
- Creating content/authority?

6. ACTION ITEMS
What should Cobi do this week based on this?
- 
- 

7. CONTENT IDEAS
X threads, reels, or posts Cobi could make inspired by this?
- 
EXTRACT

# Remove from queue
if [ -f "$INBOX_DIR/tier1-youtube.txt" ]; then
    grep -v "^$PLATFORM:$ID" "$INBOX_DIR/tier1-youtube.txt" > "$INBOX_DIR/tmp.txt" || true
    mv "$INBOX_DIR/tmp.txt" "$INBOX_DIR/tier1-youtube.txt"
fi

echo ""
echo "=== Ready for Study ==="
echo "Directory: $STUDY_DIR"
echo ""
echo "Next steps:"
if [ -f "$STUDY_DIR/audio.txt" ]; then
    echo "1. Review: $STUDY_DIR/study-note.md"
    echo "2. Extract: Use $STUDY_DIR/extract-knowledge.txt prompt"
else
    echo "1. Get transcript (manual or whisper)"
    echo "2. Extract knowledge using extract-knowledge.txt prompt"
fi
