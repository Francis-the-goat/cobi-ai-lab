# 🎯 Radar System — Automated Signal Detection

Continuous monitoring of channels for high-signal opportunities.

## Quick Status

```bash
cd ~/.openclaw/workspace/radar-system

# Check what's in the queue
./status.sh

# Run all monitors once
./run-radar.sh

# Generate today's handoff
./generate-handoff.sh
```

## What's Monitored

| Channel | Frequency | Status |
|---------|-----------|--------|
| Hacker News | 30 min | ✅ Ready |
| GitHub Trending | 2 hours | ⚠️ Needs `gh auth` |
| YouTube Uploads | 1 hour | ⚠️ Needs `yt-dlp` |
| Web Source Changes (Scrapling) | 2 hours | ✅ Ready after Scrapling runtime install |
| X/Twitter | 1 hour | ⚠️ Needs RSS setup |

## Signal Flow

```
[Monitor detects] → [Score with Foundry Rubric] → [Route to queue] → [Generate handoff]
```

**Queues:**
- 🚨 Urgent (40+ points) → Alert immediately
- 📦 Asset (35-39) → Create opportunity pack
- ✍️ Content (30-34) → Content backlog
- 🔍 Research (25-29) → Deep dive queue

## Installation

See [INSTALL.md](INSTALL.md) for full setup.

**Quick deps:**
```bash
brew install jq yt-dlp gh
gh auth login
bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh
```

## Files

```
radar-system/
├── monitors/        # Channel fetchers
├── scorer/          # Scoring logic
├── router/          # Action routing
├── queue/           # Signal storage
├── run-radar.sh     # Master script
└── status.sh        # Quick status
```

## Daily Use

1. **Morning:** Check `memory/YYYY-MM-DD-radar-handoff.md`
2. **Evening:** Review urgent alerts in `queue/urgent-alerts.jsonl`
3. **Weekend:** Process asset packs and content ideas

---

*Last updated: 2026-02-25*
