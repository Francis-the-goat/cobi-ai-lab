# SKILLS.md — Workflow Library

**Purpose:** Document workflows and patterns so future tasks are faster  
**Update:** After learning something valuable or completing a project

---

## Model Routing

### When to Use Which Model
| Task Type | Model | Example |
|-----------|-------|---------|
| Strategic decisions, final outputs, business reasoning | Strategist (Kimi K2.5) | Offer design, pricing, positioning |
| Complex build specs, coding architecture, multimodal tasks | Builder (GPT-5.3 Codex) | Tool design, code implementation plan |
| Offline local reasoning (higher quality local) | LocalSmart (Qwen 2.5 7B) | Local draft synthesis and analysis |
| Fast local code scaffolding | LocalCode (DeepSeek Coder 1.3B) | Small code transforms, snippets |
| Low-heat triage and summaries | LocalFast (Llama 3.2 3B) | Quick summaries, low-stakes transforms |

### Override Commands
```bash
openclaw models set Strategist              # Quality-first default
openclaw models set Builder                 # Build-focused default
openclaw models set LocalFast               # Cool/low-power default
openclaw models fallbacks list              # Confirm fallback chain
bash ~/.openclaw/workspace/scripts/model_mode.sh quality
```

---

## AI Business Asset Foundry

### What It Does
- Turns research into build-ready assets (skill/tool/automation specs)
- Forces evidence-based opportunity scoring (non-generic ideas only)
- Produces a 3-file asset pack with execution and validation plan

### Paths
- Skill: `~/.openclaw/skills/ai-business-asset-foundry/SKILL.md`
- Scoring script: `~/.openclaw/skills/ai-business-asset-foundry/scripts/opportunity_score.py`
- Pack scaffold script: `~/.openclaw/skills/ai-business-asset-foundry/scripts/bootstrap_asset_pack.sh`

### Quick Usage
```bash
# Scaffold a new opportunity package
~/.openclaw/skills/ai-business-asset-foundry/scripts/bootstrap_asset_pack.sh <slug> ~/.openclaw/workspace

# Score an opportunity from JSON inputs (1-5 scale on rubric fields)
~/.openclaw/skills/ai-business-asset-foundry/scripts/opportunity_score.py /tmp/opportunity.json
```

---

## SMB Agentic Opportunity Radar

### What It Does
- Tracks high-signal AI changes that can be monetized for SMB operators
- Filters out generic trends and promotes only economically viable opportunities
- Extends foundry output with a dedicated radar brief for faster decision-making

### Paths
- Skill: `~/.openclaw/skills/smb-agentic-opportunity-radar/SKILL.md`
- Radar pack script: `~/.openclaw/skills/smb-agentic-opportunity-radar/scripts/new_radar_pack.sh`
- Radar template: `~/.openclaw/skills/smb-agentic-opportunity-radar/references/radar-brief-template.md`

### Quick Usage
```bash
# Create a full radar + foundry pack
~/.openclaw/skills/smb-agentic-opportunity-radar/scripts/new_radar_pack.sh <slug> ~/.openclaw/workspace
```

---

## Video Source Intelligence

### What It Does
- Transcribes YouTube videos reliably (subtitles first, Whisper fallback)
- Supports optional cloud fallback (Groq/OpenAI/Deepgram) for hard videos
- Creates source cards in `memory/sources/` for structured analysis
- Converts source intelligence into concrete next actions

### Paths
- Skill: `~/.openclaw/skills/video-source-intelligence/SKILL.md`
- Skill wrapper: `~/.openclaw/skills/video-source-intelligence/scripts/ingest_video_source.sh`
- Workspace ingest script: `~/.openclaw/workspace/scripts/ingest_video_source.sh`
- Transcriber: `~/.openclaw/workspace/tools/yt-transcribe`
- Retry queue: `~/.openclaw/workspace/scripts/transcription_queue.sh`

### Quick Usage
```bash
# Ingest video into transcript + source card
bash ~/.openclaw/workspace/scripts/ingest_video_source.sh QWzLPn164w0 nate-offer-design

# Direct transcript output
~/.openclaw/workspace/tools/yt-transcribe QWzLPn164w0 text

# Retry queue
bash ~/.openclaw/workspace/scripts/transcription_queue.sh add QWzLPn164w0 nate-offer-design "Nate Offer Design"
bash ~/.openclaw/workspace/scripts/transcription_queue.sh process --limit 3
```

---

## Leverage Automation Suite

### What It Does
- Installs an idempotent cron system for daily scanning, asset selection, and weekly planning
- Audits whether your live profile is aligned to your intended workspace/models/auth

### Paths
- Cron installer: `~/.openclaw/workspace/scripts/install_leverage_crons.sh`
- Setup audit: `~/.openclaw/workspace/scripts/leverage_setup_audit.sh`
- Telegram target updater: `~/.openclaw/workspace/scripts/set_telegram_target.sh`
- Self-improvement cycle: `~/.openclaw/workspace/scripts/self_improvement_cycle.sh`
- Operating system: `~/.openclaw/workspace/LEVERAGE_OS.md`
- Self-improvement OS: `~/.openclaw/workspace/SELF_IMPROVEMENT_OS.md`
- Daily handoff template: `~/.openclaw/workspace/DAILY_HANDOFF_TEMPLATE.md`
- Output standard: `~/.openclaw/workspace/OUTPUT_STANDARD.md`
- Quality bar: `~/.openclaw/workspace/QUALITY_BAR.md`

### Quick Usage
```bash
# Verify setup integrity for the dev profile
bash ~/.openclaw/workspace/scripts/leverage_setup_audit.sh dev

# Install/update leverage cron jobs (requires running gateway)
bash ~/.openclaw/workspace/scripts/install_leverage_crons.sh dev Australia/Brisbane
# Optional explicit Telegram destination:
bash ~/.openclaw/workspace/scripts/install_leverage_crons.sh dev Australia/Brisbane <telegram_chat_id_or_username>

# Update existing cron jobs with your Telegram target
bash ~/.openclaw/workspace/scripts/set_telegram_target.sh dev <telegram_chat_id_or_username>

# Generate a performance/optimization report from cron run history
bash ~/.openclaw/workspace/scripts/self_improvement_cycle.sh dev 7
```

---

## Operator Skill Reliability

### What It Does
- Enforces skill contracts (input/output/failure semantics/SLOs/tests)
- Scores every skill for operational readiness
- Produces an audit report with concrete hardening actions

### Paths
- Skill: `~/.openclaw/skills/operator-skill-reliability/SKILL.md`
- Contract scaffold: `~/.openclaw/skills/operator-skill-reliability/scripts/init_contract_bundle.sh`
- Audit runner: `~/.openclaw/skills/operator-skill-reliability/scripts/run_skill_checks.py`
- Latest report: `~/.openclaw/workspace/memory/reports/latest-skill-contract-audit.md`

### Quick Usage
```bash
# Initialize contract files for a skill
bash ~/.openclaw/skills/operator-skill-reliability/scripts/init_contract_bundle.sh ~/.openclaw/skills/video-source-intelligence

# Audit all skills
python3 ~/.openclaw/skills/operator-skill-reliability/scripts/run_skill_checks.py \
  --skills-root ~/.openclaw/skills \
  --report ~/.openclaw/workspace/memory/reports/latest-skill-contract-audit.md \
  --write-json ~/.openclaw/workspace/memory/reports/latest-skill-contract-audit.json
```

---

## OpenClaw Configuration Patterns

### Adding a New Model
1. Download via Ollama: `ollama pull model:tag`
2. Add provider to `openclaw.json` models section
3. Add alias to agents.defaults.models
4. Restart gateway: `openclaw gateway restart`

### Channel Setup (Telegram)
1. Get bot token from @BotFather
2. Add to config: `channels.telegram.botToken`
3. Enable plugin: `plugins.entries.telegram.enabled = true`
4. Restart gateway
5. Approve sender: `openclaw pairing approve CODE`

---

## Content Creation Workflow

### X Thread Creation
1. **Idea** → Log in CONTENT_BACKLOG.md
2. **Draft** → Write hook + 3-5 body points + CTA
3. **Review** → Cobi reviews, suggests edits
4. **Schedule** → Use scheduling tool or post manually
5. **Engage** → Respond to replies for 30 min

### Reel Creation
1. **Script** → 30-45 seconds, hook in first 3 sec
2. **Record** → Screen recording or talking head
3. **Edit** → CapCut or Descript (fast cuts, captions)
4. **Post** → Instagram, cross-post to X/LinkedIn
5. **Engage** → Respond to comments

---

## Research Workflow

### YouTube Video Analysis
1. Get transcript (if available) or download audio
2. Transcribe with Whisper
3. Extract key insights
4. Synthesize into actionable takeaways
5. Log in memory
6. Draft content if valuable

### GitHub Intelligence
1. Scan trending repositories
2. Check stars, recent commits, README quality
3. Test if relevant to Cobi's stack
4. Log in MEMORY.md
5. Suggest integration if valuable

### Web Signal Monitoring (Scrapling)
1. Install runtime: `bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh`
2. Configure sources: `~/.openclaw/workspace/radar-system/config/web-sources.txt`
3. Run monitor: `bash ~/.openclaw/workspace/radar-system/monitors/web-scrapling.sh`
4. Review output: `~/.openclaw/workspace/radar-system/queue/web-signals-*.json`
5. Route high-signal changes into leverage briefs or asset foundry work

---

## File Organization

### Daily Notes
- Path: `memory/YYYY-MM-DD.md`
- Content: What happened, what was built, what was learned
- Update: End of every day

### Long-Term Memory
- Path: `MEMORY.md`
- Content: Curated insights, decisions, lessons worth keeping
- Update: Weekly review of daily notes

### Project Tracking
- Path: `PROJECTS.md`
- Content: Active projects, status, next actions
- Update: When project status changes

### Content Ideas
- Path: `CONTENT_BACKLOG.md`
- Content: Thread/reel ideas, hooks, drafts
- Update: Daily additions, weekly prioritization

---

## Git Workflow

### Commit Pattern
```bash
git add .
git commit -m "feat: description of what changed"
git push origin main
```

### Commit Types
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code restructure
- `chore:` Maintenance

---

## Automation Patterns

### Autonomous Research (During Warehouse Hours)
1. Scan X/GitHub/YouTube for relevant content
2. Extract insights
3. Draft summaries
4. Log in daily notes
5. Prepare action list for Cobi's return

### Content Generation
1. Pull from CONTENT_BACKLOG.md
2. Draft using template
3. Review with Cobi
4. Schedule/publish
5. Engage with responses

---

## Decision Frameworks

### Should I Build This?
1. Does it serve the 12-month exit goal?
2. Can it be built in <2 weeks?
3. Will it produce content or assets?
4. Is it leverage (does work once, benefits ongoing)?

If 3+ yes → Build it
If 2 yes → Consider carefully
If <2 yes → Kill it

### Model Selection
1. Is this a final decision, strategy, or client-facing deliverable? → Strategist
2. Is this implementation-heavy (code/tools/specs)? → Builder
3. Need local/offline quality? → LocalSmart
4. Need fast local coding support? → LocalCode
5. Need low heat for lightweight tasks? → LocalFast

---

## Common Commands

### OpenClaw
```bash
openclaw status                           # Check gateway health
openclaw gateway restart                  # Restart gateway
openclaw channels list                    # Check connected channels
openclaw plugins list                     # List installed plugins
openclaw agent "task"                     # Run with default model
openclaw models set Strategist            # Set default model by alias
openclaw models set Builder               # Set default coding model
openclaw models fallbacks list            # Inspect fallback order
```

### Ollama
```bash
ollama list                               # List downloaded models
ollama pull model:tag                     # Download new model
ollama run model:tag                      # Interactive chat
```

### Git
```bash
git status                                # Check changes
git add .                                 # Stage all
git commit -m "message"                   # Commit
git push origin main                      # Push
```

---

## Learning Resources

### Agentic Systems
- OpenClaw docs: https://docs.openclaw.ai
- Anthropic: Building effective agents
- GitHub: trending TypeScript agent projects

### Business/Agency
- Agency positioning: Win Without Pitching
- Value pricing: Pricing Creativity
- SMB sales: The Brain Audit

### Content/Brand
- X growth: Study @bindureddy, @naval
- Copywriting: Ogilvy on Advertising
- Positioning: Obviously Awesome

---

## Patterns to Remember

1. **Ship small, ship often** — 1-week projects max
2. **Document everything** — Today's work is tomorrow's content
3. **Local first** — Try free models before paid
4. **Content is proof** — Show, don't tell
5. **Leverage compounds** — Build assets that reuse

---

## Last Updated

2026-02-24 — Initial workflow documentation
