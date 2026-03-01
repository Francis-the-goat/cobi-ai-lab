# Radar System Installation & Setup

## What This Is

Automated signal detection across channels (GitHub, HN, YouTube, X) that:
1. Monitors sources every 30-60 minutes
2. Scores opportunities using Foundry Rubric
3. Routes high-signal items to action queues
4. Generates daily handoffs for Cobi

## System Architecture

```
monitors/          # Channel-specific fetchers
├── github.sh      # GitHub trending + search
├── hackernews.sh  # HN Show + AI posts
├── youtube.sh     # Channel uploads
└── x-rss.sh       # Twitter via RSS bridges

scorer/            # Signal evaluation
└── score-signal.* # Applies Foundry Rubric

router/            # Action routing
└── route-action.sh # Queues by priority

queue/             # Signal storage
├── urgent-alerts.jsonl     # Score 40+
├── asset-*.json            # Score 35-39
├── content-ideas.jsonl     # Score 30-34
├── research-queue.jsonl    # Score 25-29
└── all-signals.jsonl       # Everything else

run-radar.sh       # Master orchestrator
generate-handoff.sh # Daily summary
```

## Setup Steps

### 1. Dependencies

```bash
# Install jq (JSON processor)
# macOS:
brew install jq

# Ubuntu/Debian:
sudo apt-get install jq

# Install yt-dlp (YouTube monitoring)
brew install yt-dlp  # or pip install yt-dlp

# GitHub CLI (optional, for authenticated API)
brew install gh
gh auth login
```

### 2. Configure Channels

**YouTube:**
Edit `config/youtube-channels.txt`:
```
UCt8xK0wfUCn5YTCYEmIDa1g|Nate B Jones
UCR2btWn3i6e1S8iOQpR4V1A|Kyle Pathy
# Add more: channel_id|name
```

**X/Twitter (via RSS):**
Use services like:
- nitter.net RSS feeds
- rss.app
- feedrabbit.com

Add feeds to `config/x-feeds.txt`.

**GitHub:**
Configure search queries in `monitors/github.sh`:
- Default: TypeScript + AI/agent keywords
- Customize for your focus areas

### 3. Test Monitors

```bash
cd /workspace/radar-system

# Test individual monitors
./monitors/hackernews.sh
./monitors/youtube.sh
./monitors/github.sh

# Check output
ls -la queue/
cat queue/hn-signals-*.json
```

### 4. Run Full System

```bash
# Single run
./run-radar.sh

# Generate handoff
./generate-handoff.sh
```

### 5. Automate with Cron

Add to crontab (`crontab -e`):

```bash
# Radar runs every 30 min during business hours (7am-7pm)
*/30 7-19 * * * cd /workspace/radar-system && ./run-radar.sh >> logs/cron.log 2>&1

# Generate handoff at 3pm (before Cobi gets home)
0 15 * * * cd /workspace/radar-system && ./generate-handoff.sh

# Clean old signal files weekly (keep last 7 days)
0 0 * * 0 find /workspace/radar-system/queue -name "*-signals-*.json" -mtime +7 -delete
```

Or use OpenClaw's cron skill:
```bash
openclaw cron add --name radar --schedule "*/30 * * * *" \
  --command "cd /workspace/radar-system && ./run-radar.sh"
```

## Usage

### Daily Workflow

1. **Morning:** Review overnight signals
   ```bash
   cat queue/urgent-alerts.jsonl
   ls queue/asset-*.json
   ```

2. **Evening:** Check handoff
   ```bash
   cat /workspace/memory/$(date +%Y-%m-%d)-radar-handoff.md
   ```

3. **Process queues:**
   - Urgent alerts → Act immediately
   - Asset packs → Build when time available
   - Content ideas → Draft when inspiration strikes
   - Research queue → Deep dive on weekends

### Adding Custom Monitors

Create `monitors/custom.sh`:

```bash
#!/bin/bash
OUTPUT="/workspace/radar-system/queue/custom-$(date +%Y%m%d-%H%M).json"

# Your fetching logic here
DATA=$(curl -s "https://api.example.com/signals")

echo "{
  \"timestamp\": \"$(date -Iseconds)\",
  \"source\": \"custom\",
  \"data\": $DATA
}" > "$OUTPUT"
```

Then add to `run-radar.sh`.

## Scoring Algorithm

The Foundry Rubric scores signals 0-45:

| Score | Action | Priority |
|-------|--------|----------|
| 40+ | ALERT+BUILD | Immediate |
| 35-39 | CREATE_ASSET | This week |
| 30-34 | CONTENT | When convenient |
| 25-29 | RESEARCH | Deep dive |
| <25 | LOG | Reference only |

Weights:
- Pain (8): Problem acuity
- ROI (8): Quantifiable value
- Auto-fit (8): Agent solvability
- Distribution (7): Reachability
- Defensibility (6): Moat potential
- Speed (8): Build speed

## Troubleshooting

**No signals appearing:**
- Check monitor logs: `tail logs/radar-$(date +%Y%m%d).log`
- Verify API rate limits
- Test individual monitors manually

**Too many signals:**
- Adjust scoring thresholds
- Refine source filters
- Add keyword exclusions

**Duplicate signals:**
- Cache files track seen IDs
- Check cache file permissions
- Clear cache to reset: `rm queue/*-seen.txt`

## Integration with OpenClaw

The radar system is designed to work with OpenClaw's heartbeat system:

1. HEARTBEAT.md checks radar queue status
2. High-signal items trigger alerts
3. Daily handoff appears in memory folder
4. Sub-agents can process queues in parallel

## Next Steps

1. [ ] Install dependencies (jq, yt-dlp)
2. [ ] Configure YouTube channels
3. [ ] Test all monitors
4. [ ] Set up cron automation
5. [ ] Let it run for 24h
6. [ ] Review first handoff
7. [ ] Iterate based on signal quality
