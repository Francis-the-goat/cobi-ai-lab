# Local Tools

## YouTube Transcription Tool

Extract transcripts from YouTube videos using:
- YouTube subtitles first (`yt-dlp`)
- Local Whisper fallback when subtitles are missing

## Usage

```bash
~/.openclaw/workspace/tools/yt-transcribe <youtube_url> [text|json|srt]
```

## Examples

```bash
# Clean text (default)
~/.openclaw/workspace/tools/yt-transcribe https://youtu.be/QWzLPn164w0

# JSON with timestamps
~/.openclaw/workspace/tools/yt-transcribe QWzLPn164w0 json

# Raw SRT
~/.openclaw/workspace/tools/yt-transcribe QWzLPn164w0 srt
```

## Requirements

- yt-dlp
- ffmpeg (for subtitle conversion and audio extraction)
- whisper (fallback transcription)
- Python 3 (for JSON output)

## Notes

- Default config file (already created):
```bash
~/.openclaw/workspace/config/transcription.env
```
- Set Whisper model via env var if needed:
```bash
WHISPER_MODEL=small ~/.openclaw/workspace/tools/yt-transcribe QWzLPn164w0 text
```
- Optional cloud fallback if subtitles + local Whisper fail:
```bash
TRANSCRIBE_ENABLE_CLOUD_FALLBACK=1 \
TRANSCRIBE_CLOUD_PROVIDER=auto \
GROQ_API_KEY=... \
~/.openclaw/workspace/tools/yt-transcribe QWzLPn164w0 text
```
- `auto` chooses provider in this order: `groq` -> `openai` -> `deepgram` (based on available API keys).
- If you specifically want native timestamped SRT from OpenAI, use:
```bash
TRANSCRIBE_OPENAI_MODEL=whisper-1
```
- Force Groq explicitly:
```bash
TRANSCRIBE_CLOUD_PROVIDER=groq \
GROQ_API_KEY=... \
~/.openclaw/workspace/tools/yt-transcribe QWzLPn164w0 text
```
- Deepgram cloud fallback option:
```bash
TRANSCRIBE_ENABLE_CLOUD_FALLBACK=1 \
TRANSCRIBE_CLOUD_PROVIDER=deepgram \
DEEPGRAM_API_KEY=... \
~/.openclaw/workspace/tools/yt-transcribe QWzLPn164w0 text
```
- For source adaptation workflow, use:
```bash
bash ~/.openclaw/workspace/scripts/ingest_video_source.sh QWzLPn164w0 my-source-slug
```
- Queue failed ingests for retry:
```bash
bash ~/.openclaw/workspace/scripts/transcription_queue.sh add QWzLPn164w0 my-source-slug "Video title"
bash ~/.openclaw/workspace/scripts/transcription_queue.sh process --limit 3
bash ~/.openclaw/workspace/scripts/transcription_queue.sh list
```

## Scrapling Extraction Tool

Fetch and extract high-value page content for research/monitoring.

### Install runtime

```bash
bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh
```

### Usage

```bash
python3 ~/.openclaw/workspace/tools/scrapling_extract.py \
  --url "https://openai.com/news/" \
  --selector "main" \
  --format text \
  --output /tmp/openai-news.txt
```
