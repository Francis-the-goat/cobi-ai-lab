# SKILLS.md — Workflow Library

**Purpose:** Document workflows and patterns so future tasks are faster  
**Update:** After learning something valuable or completing a project

---

## Model Routing

### When to Use Which Model
| Task Type | Model | Example |
|-----------|-------|---------|
| Simple Q&A, summaries | Local (Llama 3.2 3B) | "What is OpenClaw?" |
| Code, debugging | LocalCode (DeepSeek 1.3B) | "Debug this Python script" |
| Creative, strategic, important | Kimi (K2.5) | "Write client proposal" |

### Override Commands
```bash
openclaw agent --model Local "task"        # Force free model
openclaw agent --model Kimi "task"         # Force best quality
openclaw agent --model LocalCode "task"    # Force code model
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
1. Is it code-related? → LocalCode
2. Is it creative/strategic/important? → Kimi
3. Is it simple transformation/research? → Local

---

## Common Commands

### OpenClaw
```bash
openclaw status                           # Check gateway health
openclaw gateway restart                  # Restart gateway
openclaw channels list                    # Check connected channels
openclaw plugins list                     # List installed plugins
openclaw agent "task"                     # Run with default model
openclaw agent --model Local "task"       # Run with local model
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
