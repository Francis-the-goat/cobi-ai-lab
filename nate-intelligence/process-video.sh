#!/usr/bin/env bash
# Process a single Nate B Jones video end-to-end

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

VIDEO_ID="${1:-}"
FROM_INBOX=false
VIDEO_TITLE=""
VIDEO_DATE=""
VIDEO_URL=""
VIDEO_DURATION=""

if [ -z "$VIDEO_ID" ]; then
    echo "Usage: $0 <video_id>"
    echo "Or process from inbox: $0 --inbox"
    exit 1
fi

# If --inbox flag, process first pending video
if [ "$VIDEO_ID" == "--inbox" ]; then
    FROM_INBOX=true
    if [ ! -s "$INBOX_DIR/pending.txt" ]; then
        echo "No pending videos in inbox"
        exit 0
    fi
    # Get first pending video
    LINE=$(head -1 "$INBOX_DIR/pending.txt")
    VIDEO_ID=$(echo "$LINE" | cut -d'|' -f1)
    VIDEO_TITLE=$(echo "$LINE" | cut -d'|' -f2)
    VIDEO_DATE=$(echo "$LINE" | cut -d'|' -f3)
    VIDEO_URL=$(echo "$LINE" | cut -d'|' -f4)
    VIDEO_DURATION=$(echo "$LINE" | cut -d'|' -f5)
else
    VIDEO_URL="https://www.youtube.com/watch?v=$VIDEO_ID"
    if command -v yt-dlp &> /dev/null; then
        META_LINE="$(yt-dlp --skip-download \
            --print "%(title)s|%(upload_date)s|%(webpage_url)s|%(duration_string)s" \
            "$VIDEO_URL" 2>/dev/null | head -1 || true)"
        if [ -n "$META_LINE" ]; then
            VIDEO_TITLE="$(echo "$META_LINE" | cut -d'|' -f1)"
            VIDEO_DATE="$(echo "$META_LINE" | cut -d'|' -f2)"
            VIDEO_URL="$(echo "$META_LINE" | cut -d'|' -f3)"
            VIDEO_DURATION="$(echo "$META_LINE" | cut -d'|' -f4)"
        fi
    fi

    VIDEO_TITLE="${VIDEO_TITLE:-video-$VIDEO_ID}"
    VIDEO_DATE="${VIDEO_DATE:-$(date +%Y%m%d)}"
    VIDEO_DURATION="${VIDEO_DURATION:-unknown}"
fi

# Create processing directory
SLUG=$(echo "$VIDEO_TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -dc 'a-z0-9-_' | cut -c1-50)
PROC_DIR="$PROCESSED_DIR/$(date +%Y-%m-%d)-$SLUG"
mkdir -p "$PROC_DIR"

echo "Processing: $VIDEO_TITLE"
echo "Directory: $PROC_DIR"

# Save metadata
cat > "$PROC_DIR/meta.json" << METAEOF
{
  "id": "$VIDEO_ID",
  "title": "$VIDEO_TITLE",
  "upload_date": "$VIDEO_DATE",
  "url": "$VIDEO_URL",
  "duration": "$VIDEO_DURATION",
  "processed_at": "$(date -Iseconds)"
}
METAEOF

# Step 1: Download audio for transcription (if yt-dlp available)
if command -v yt-dlp &> /dev/null; then
    echo "[1/4] Downloading audio..."
    if ! yt-dlp -x --audio-format mp3 --audio-quality 0 \
        -o "$PROC_DIR/audio.%(ext)s" \
        "$VIDEO_URL" 2>&1 | tail -5; then
        echo "[1/4] Download failed; continuing with metadata only"
    fi
else
    echo "[1/4] yt-dlp not available - skipping download"
    echo "Install: brew install yt-dlp"
fi

# Step 2: Transcribe (if whisper available)
if [ -f "$PROC_DIR/audio.mp3" ] && command -v whisper &> /dev/null; then
    echo "[2/4] Transcribing with Whisper..."
    whisper "$PROC_DIR/audio.mp3" \
        --model base \
        --language en \
        --output_format txt \
        --output_dir "$PROC_DIR" 2>&1 | tail -3
elif [ -f "$PROC_DIR/audio.mp3" ]; then
    echo "[2/4] Whisper not available - audio saved for manual transcription"
    echo "Install: pip install openai-whisper"
else
    echo "[2/4] No audio file - skipping transcription"
fi

# Check for transcript
TRANSCRIPT="$PROC_DIR/audio.txt"
if [ -f "$TRANSCRIPT" ]; then
    echo "✓ Transcript ready: $TRANSCRIPT"
else
    echo "✗ No transcript available"
    # Create placeholder
    echo "Transcript not available. Video: $VIDEO_URL" > "$PROC_DIR/transcript-placeholder.txt"
fi

# Step 3: Create analysis prompt template
cat > "$PROC_DIR/analyze-prompt.txt" << 'PROMPTEOF'
You are analyzing a Nate B Jones video about AI, business, and entrepreneurship for Cobi — a 20-year-old building an AI agency focused on agentic systems for SMBs.

VIDEO TITLE: {{TITLE}}

YOUR TASK: Extract maximum actionable value from this content.

## Output Format

### Summary (2-3 paragraphs)
What Nate actually said. Key arguments, frameworks, or insights.

### Key Framework
The mental model, strategy, or system he presents. Name it and describe it in 2-3 sentences.

### Cobi Translation
How does this specifically apply to Cobi's situation?
- Building AI agency for SMBs (home services, etc.)
- Current: pre-revenue, learning phase, warehouse job 3 days/week
- Goal: Exit 9-5 in 12 months through agency + personal brand

Be specific: "Instead of X, do Y because [reason from video]."

### Content Angle
X thread or reel idea based on this video.
- Hook (first tweet)
- 3-5 bullet structure
- CTA

### Business Action
ONE specific thing Cobi should do this week based on this insight.
- Action: [what to do]
- Why: [connect to video insight]
- Success metric: [how to know it worked]

### Quote Bank
3-5 tweet-worthy lines from the video (paraphrase if needed). These should be standalone quotable insights.

---

TRANSCRIPT:
{{TRANSCRIPT}}

Generate the analysis now.
PROMPTEOF

echo "[3/4] Analysis prompt created: $PROC_DIR/analyze-prompt.txt"

# Step 4: Create placeholder outputs
cat > "$PROC_DIR/summary.md" << 'PLACEHOLDER'
# Summary

[Run analysis with transcript to generate]

## Next Step
Paste transcript into Claude/Codex with the analyze-prompt.txt template.
PLACEHOLDER

cat > "$PROC_DIR/translation.md" << 'PLACEHOLDER'
# Cobi Translation

[How this applies to your specific situation]

## Business Action

[Specific action to take this week]
PLACEHOLDER

cat > "$PROC_DIR/content-ideas.md" << 'PLACEHOLDER'
# Content Ideas

## X Thread

**Hook:**

**Body:**
1.
2.
3.

**CTA:**

---

## Reel Concept

**Visual:**
**Hook (0-3s):**
**Script:**
**CTA:**
PLACEHOLDER

echo "[4/4] Output templates created"

# Remove from pending
if [ "$FROM_INBOX" = true ] && [ -f "$INBOX_DIR/pending.txt" ]; then
    tail -n +2 "$INBOX_DIR/pending.txt" > "$INBOX_DIR/pending.tmp"
    mv "$INBOX_DIR/pending.tmp" "$INBOX_DIR/pending.txt"
fi

echo ""
echo "=== Processing Complete ==="
echo "Directory: $PROC_DIR"
echo ""
echo "Next steps:"
if [ -f "$TRANSCRIPT" ]; then
    echo "1. Review transcript: $TRANSCRIPT"
    echo "2. Run analysis with: cat $PROC_DIR/analyze-prompt.txt | [claude/codex]"
    echo "3. Update summary.md, translation.md, content-ideas.md"
else
    echo "1. Transcribe audio (if downloaded) or get transcript manually"
    echo "2. Run analysis with: cat $PROC_DIR/analyze-prompt.txt | [claude/codex]"
fi
echo ""
ls -la "$PROC_DIR/"
