# Scrapling Integration for OpenClaw Workspace

## Why This Is High-Leverage for Your Agent

Scrapling closes a major gap in your stack: structured website intelligence.

- API feeds and YouTube checks miss many high-value updates that appear first on web pages.
- Scrapling lets your agent extract targeted content with CSS selectors before LLM analysis, reducing token waste.
- The same runtime can scale from simple HTTP extraction to browser/stealth fetches when sources get harder.

For your SMB + agentic strategy, this means faster signal capture from product releases, docs changes, and market pages.

## What Was Integrated

1. Dedicated Scrapling runtime installer:
   - `scripts/install_scrapling_runtime.sh`

2. Reusable extraction tool:
   - `tools/scrapling_extract.py`
   - Optional shortcut: `bin/scrapling-extract` (auto-uses Scrapling venv if present)

3. Radar monitor for web-source change detection:
   - `radar-system/monitors/web-scrapling.py`
   - `radar-system/monitors/web-scrapling.sh`
   - Source list: `radar-system/config/web-sources.txt`

4. Radar pipeline wiring:
   - `radar-system/run-radar.sh` now executes the Scrapling monitor.

## Commands

Install runtime:

```bash
bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh
```

Install runtime with MCP extras:

```bash
bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh --with-ai
```

Run web monitor once:

```bash
bash ~/.openclaw/workspace/radar-system/monitors/web-scrapling.sh
```

Run full radar cycle (includes web monitor):

```bash
bash ~/.openclaw/workspace/radar-system/run-radar.sh
```

Extract targeted content from a page:

```bash
python3 ~/.openclaw/workspace/tools/scrapling_extract.py \
  --url "https://openai.com/news/" \
  --selector "main" \
  --format text \
  --output /tmp/openai-news.txt
```

## Tuning

Edit monitored sources and selectors:

- `~/.openclaw/workspace/radar-system/config/web-sources.txt`

Line format:

```text
name|url|css_selector|priority|focus
```
