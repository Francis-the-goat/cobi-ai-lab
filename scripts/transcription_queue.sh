#!/bin/bash
# transcription_queue.sh - Robust video transcription pipeline
# Usage: ./transcription_queue.sh [add <url> <slug>|process|list|clear]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QUEUE_FILE="$WORKSPACE_DIR/memory/queue/transcription_queue.txt"
OUTPUT_DIR="$WORKSPACE_DIR/memory/transcripts"
TEMP_DIR="$WORKSPACE_DIR/.temp"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$(dirname "$QUEUE_FILE")" "$TEMP_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_deps() {
    local missing=()
    
    if ! command -v yt-dlp &> /dev/null; then
        missing+=("yt-dlp")
    fi
    
    if ! command -v whisper &> /dev/null; then
        missing+=("whisper")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}ERROR: Missing dependencies:${NC}"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Install with:"
        echo "  brew install yt-dlp whisper"
        exit 1
    fi
}

add_to_queue() {
    local url="${1:-}"
    local slug="${2:-}"
    
    # If no URL arg but stdin provided, read from stdin
    if [ -z "$url" ] && [ ! -t 0 ]; then
        read -r url
    fi
    
    # Generate slug from URL if not provided
    if [ -z "$slug" ] && [ -n "$url" ]; then
        # Extract video ID or use timestamp
        slug=$(echo "$url" | sed 's/.*[?&]v=//' | sed 's/.*\///' | cut -c1-20)
        slug="${slug:-$(date +%s)}"
    fi
    
    if [ -z "$url" ]; then
        echo -e "${RED}ERROR: URL required${NC}"
        echo "Usage: add <url> [slug]"
        echo "       echo '<url>' | $0 add"
        exit 1
    fi
    
    echo "$url|$slug" >> "$QUEUE_FILE"
    echo -e "${GREEN}ADDED:${NC} $slug -> queue"
}

list_queue() {
    if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
        echo "Queue is empty"
        return 0
    fi
    
    echo "Current queue:"
    local i=1
    while IFS='|' read -r url slug; do
        echo "  $i. $slug ($url)"
        ((i++))
    done < "$QUEUE_FILE"
}

clear_queue() {
    > "$QUEUE_FILE"
    echo -e "${YELLOW}CLEARED:${NC} Queue emptied"
}

process_queue() {
    if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
        echo "No items in queue to process"
        return 0
    fi
    
    check_deps
    
    local temp_queue="$TEMP_DIR/queue_processing_$$.txt"
    cp "$QUEUE_FILE" "$temp_queue"
    > "$QUEUE_FILE"
    
    local processed=0
    local failed=0
    
    while IFS='|' read -r url slug; do
        echo ""
        echo "=========================================="
        echo -e "${YELLOW}PROCESSING:${NC} $slug"
        echo "URL: $url"
        echo "=========================================="
        
        local temp_audio="$TEMP_DIR/${slug}_$$"
        local output_file="$OUTPUT_DIR/$(date +%Y-%m-%d)-$slug.txt"
        
        # Download audio
        echo "Downloading audio..."
        if ! yt-dlp -x --audio-format mp3 -o "$temp_audio.%(ext)s" "$url" 2>/dev/null; then
            echo -e "${RED}FAILED:${NC} Download failed for $slug"
            echo "$url|$slug" >> "$QUEUE_FILE"  # Re-queue for retry
            ((failed++))
            continue
        fi
        
        # Transcribe
        echo "Transcribing..."
        if ! whisper "${temp_audio}.mp3" --model base --output_format txt --output_dir "$OUTPUT_DIR" 2>/dev/null; then
            echo -e "${RED}FAILED:${NC} Transcription failed for $slug"
            echo "$url|$slug" >> "$QUEUE_FILE"  # Re-queue for retry
            rm -f "${temp_audio}.mp3"
            ((failed++))
            continue
        fi
        
        # Rename output to standard format
        mv "$OUTPUT_DIR/$(basename "${temp_audio}").txt" "$output_file" 2>/dev/null || true
        
        # Cleanup
        rm -f "${temp_audio}.mp3"
        
        echo -e "${GREEN}SUCCESS:${NC} $slug -> $output_file"
        ((processed++))
        
    done < "$temp_queue"
    
    rm -f "$temp_queue"
    
    echo ""
    echo "=========================================="
    echo "PROCESSING COMPLETE"
    echo "  Processed: $processed"
    echo "  Failed: $failed"
    echo "  Remaining in queue: $(wc -l < "$QUEUE_FILE" | tr -d ' ')"
    echo "=========================================="
}

# Main command handler
case "${1:-}" in
    add)
        add_to_queue "${2:-}" "${3:-}"
        ;;
    process)
        process_queue
        ;;
    list)
        list_queue
        ;;
    clear)
        clear_queue
        ;;
    *)
        echo "Usage: $0 [add <url> <slug>|process|list|clear]"
        echo ""
        echo "Commands:"
        echo "  add <url> <slug>    - Add video to transcription queue"
        echo "  process             - Process all queued videos"
        echo "  list                - Show queued items"
        echo "  clear               - Empty the queue"
        echo ""
        echo "Examples:"
        echo "  $0 add 'https://youtu.be/6MBq1paspVU' 'obsidian-agent-memory'"
        echo "  $0 process"
        exit 1
        ;;
esac
