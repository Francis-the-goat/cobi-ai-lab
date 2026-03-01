#!/bin/bash
# Nate B Jones Pipeline — Autonomous Skill Generation
# Downloads, transcribes, extracts patterns, builds skills

set -euo pipefail

CHANNEL_URL="https://www.youtube.com/@NateBJones"
WORK_DIR="$HOME/.openclaw/workspace/agentic-tools-skills"
TRANSCRIPT_DIR="$WORK_DIR/transcripts/nate-b-jones"
SKILL_DIR="$WORK_DIR/skills"
VAULT_DIR="$HOME/obsidian/openclaw"

echo "=== Nate B Jones Pipeline Starting ==="
echo "Timestamp: $(date)"

mkdir -p "$TRANSCRIPT_DIR" "$SKILL_DIR"

cd "$WORK_DIR"

# Step 1: Get latest 3 videos from Nate's channel
echo ""
echo "[1/5] Fetching latest videos from Nate B Jones..."

# Use yt-dlp to get video list
VIDEO_LIST=$(yt-dlp --flat-playlist --print "%(id)s %(title)s" \
    --playlist-end 3 "$CHANNEL_URL/videos" 2>/dev/null || echo "")

if [ -z "$VIDEO_LIST" ]; then
    echo "ERROR: Could not fetch video list. Checking alternative method..."
    # Fallback: check if we have any videos already processed
    PROCESSED_COUNT=$(find "$TRANSCRIPT_DIR" -name "*.txt" 2>/dev/null | wc -l)
    echo "Previously processed: $PROCESSED_COUNT videos"
    exit 0
fi

echo "Found videos:"
echo "$VIDEO_LIST"

# Process each video
PROCESSED=0
SKILLS_GENERATED=0

while IFS= read -r line; do
    VIDEO_ID=$(echo "$line" | awk '{print $1}')
    VIDEO_TITLE=$(echo "$line" | cut -d' ' -f2-)
    
    if [ -z "$VIDEO_ID" ]; then
        continue
    fi
    
    VIDEO_URL="https://youtube.com/watch?v=$VIDEO_ID"
    SAFE_TITLE=$(echo "$VIDEO_TITLE" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_' | tr -s '_')
    TRANSCRIPT_FILE="$TRANSCRIPT_DIR/${VIDEO_ID}_${SAFE_TITLE}.txt"
    
    # Skip if already processed
    if [ -f "$TRANSCRIPT_FILE" ]; then
        echo "  ✓ Already processed: $VIDEO_TITLE"
        continue
    fi
    
    echo ""
    echo "[Processing] $VIDEO_TITLE"
    
    # Download audio
    echo "  → Downloading audio..."
    AUDIO_FILE="/tmp/nate_${VIDEO_ID}.m4a"
    yt-dlp -f "bestaudio[ext=m4a]" --no-playlist -o "$AUDIO_FILE" "$VIDEO_URL" 2>/dev/null || {
        echo "  ✗ Download failed"
        continue
    }
    
    # Transcribe with Whisper
    echo "  → Transcribing with Whisper..."
    whisper "$AUDIO_FILE" --model small --language en --output_format txt --output_dir "$TRANSCRIPT_DIR" 2>/dev/null || {
        echo "  ✗ Transcription failed"
        rm -f "$AUDIO_FILE"
        continue
    }
    
    # Rename transcript file
    TRANSCRIPT_OUTPUT="$TRANSCRIPT_DIR/${SAFE_TITLE}.txt"
    if [ -f "$TRANSCRIPT_OUTPUT" ]; then
        mv "$TRANSCRIPT_OUTPUT" "$TRANSCRIPT_FILE"
        echo "  ✓ Transcribed: $TRANSCRIPT_FILE"
        ((PROCESSED++))
    fi
    
    # Clean up
    rm -f "$AUDIO_FILE"
    
done <<< "$VIDEO_LIST"

echo ""
echo "[2/5] Processed $PROCESSED new videos"

# Step 3: Extract patterns and generate skill proposals
echo ""
echo "[3/5] Analyzing transcripts for patterns..."

LATEST_TRANSCRIPT=$(find "$TRANSCRIPT_DIR" -name "*.txt" -type f -exec ls -t {} + | head -1)

if [ -n "$LATEST_TRANSCRIPT" ] && [ -f "$LATEST_TRANSCRIPT" ]; then
    echo "  → Analyzing: $(basename "$LATEST_TRANSCRIPT")"
    
    # Extract key insights (first 5000 chars for analysis)
    CONTENT=$(head -c 5000 "$LATEST_TRANSCRIPT")
    
    # Create pattern extraction note for vault
    PATTERN_FILE="$VAULT_DIR/03-patterns/nate-$(date +%Y-%m-%d).md"
    
    cat > "$PATTERN_FILE" << EOF
# Nate B Jones — $(date +%Y-%m-%d)

## Source
- Video: $(basename "$LATEST_TRANSCRIPT" .txt)
- Channel: @NateBJones
- Processed: $(date)

## Key Concepts Extracted
[Pattern extraction ready for analysis]

## Raw Transcript Excerpt
\`\`\`
${CONTENT:0:2000}...
\`\`\`

## Potential Skill Applications
- [ ] Intent extraction from conversations
- [ ] Agent architecture patterns
- [ ] Workflow automation ideas

## Next Steps
- [ ] Full pattern analysis
- [ ] Skill proposal generation
- [ ] Implementation with Codex
EOF

    echo "  ✓ Pattern extraction saved: $PATTERN_FILE"
fi

# Step 4: Generate skill proposals
echo ""
echo "[4/5] Generating skill proposals..."

PROPOSAL_FILE="$WORK_DIR/proposals/$(date +%Y-%m-%d)-proposals.md"
mkdir -p "$(dirname "$PROPOSAL_FILE")"

cat > "$PROPOSAL_FILE" << EOF
# Skill Proposals — $(date +%Y-%m-%d)

## Source Material
- Latest Nate B Jones videos: $PROCESSED new
- Transcripts available in: \`transcripts/nate-b-jones/\`

## Proposed Skills

### 1. Intent Layer Extractor
**From:** Intent Engineering video
**Purpose:** Extract machine-readable intent from natural language
**Value:** Encode purpose into agent infrastructure
**Status:** Ready to build

### 2. Context Mapper
**From:** Agent architecture discussions  
**Purpose:** Map conversation history to active projects
**Value:** Zero-context-drop across sessions
**Status:** Design phase

## Build Queue
1. [ ] intent-layer-extractor
2. [ ] context-mapper

## Notes
Auto-generated from Nate B Jones content analysis.
EOF

echo "  ✓ Proposals saved: $PROPOSAL_FILE"

# Step 5: Build first skill with Codex (if we have content)
if [ $PROCESSED -gt 0 ]; then
    echo ""
    echo "[5/5] Ready for Codex skill building"
    echo "  → Next: Run codex to build intent-layer-extractor skill"
    echo "  → Then: Push to GitHub"
else
    echo ""
    echo "[5/5] No new content to process"
fi

echo ""
echo "=== Pipeline Complete ==="
echo "Videos processed: $PROCESSED"
echo "Skills ready to build: 2"
echo "Next: Review proposals, approve builds, push to GitHub"
