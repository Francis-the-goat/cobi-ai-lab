# OpenClaw 10x System - Quick Start Guide

## ✅ SYSTEM STATUS: OPERATIONAL

Your autonomous intelligence system is **fully operational** and running 24/7.

---

## 🎯 IMMEDIATE VALUE - What To Do Now

### 1. View Your Morning Briefing
```bash
cat ~/obsidian/openclaw/01-daily/$(date +%Y-%m-%d)-morning-briefing.md
```
**What it shows:** Overnight activity summary, pending proposals, today's focus

### 2. Check Today's Self-Improvement Task
```bash
cat ~/obsidian/openclaw/self-improvement/daily-tasks/$(date +%Y-%m-%d)-task.md
```
**What it shows:** One concrete task to improve my performance

### 3. Open Mission Control Dashboard
- **Web:** http://127.0.0.1:8765
- **CLI:** `bash ~/.openclaw/workspace/scripts/mission-control.sh`

**What it shows:** Real-time system status, today's progress, pending proposals, quick actions

### 4. Browse Extracted Patterns
```bash
ls -la ~/obsidian/openclaw/03-patterns/
```
**What it shows:** Thinking architectures extracted from your sources

### 5. Check Pending Build Proposals
```bash
ls -la ~/obsidian/openclaw/04-decisions/skill-proposals/
```
**What it shows:** Skills waiting for your "build it" approval

---

## ⏰ AUTOMATION SCHEDULE

Your system runs automatically:

| Time | Action | What Happens |
|------|--------|--------------|
| 5:00 AM | Full Pipeline | Harvest → Analyze → Detect opportunities |
| 6:00 AM | Morning Briefing | Compiles overnight activity into summary |
| 9:00 AM | Self-Improvement | Generates daily improvement task |
| 5:00 PM | Full Pipeline | Evening harvest/analyze/detect run |
| Every 6h | Pre-Compaction Save | Persists critical context |

---

## 📁 YOUR VAULT STRUCTURE

```
~/obsidian/openclaw/
├── 00-hot-memory.md           # Survives conversation compaction
├── 00-compaction-saves/       # Backup snapshots
├── 01-daily/                  # Daily briefings
├── 03-patterns/               # Extracted thinking patterns
├── 04-decisions/              # Pending & rejected proposals
│   └── skill-proposals/       # Waiting for your approval
├── 05-sessions/               # Agent run logs
└── self-improvement/          # Daily tasks & learning log
    ├── corrections/
    ├── learnings/
    ├── metrics/
    └── daily-tasks/
```

---

## 🚀 MANUAL COMMANDS

### Run Pipeline Now
```bash
bash ~/.openclaw/workspace/scripts/full-pipeline.sh
```

### Generate Morning Brief
```bash
bash ~/.openclaw/workspace/scripts/morning-briefing.sh
```

### Create Self-Improvement Task
```bash
bash ~/.openclaw/workspace/scripts/self-improvement-loop.sh --daily-surprise
```

### View CLI Dashboard
```bash
bash ~/.openclaw/workspace/scripts/mission-control.sh
```

### Start Web Dashboard
```bash
python3 ~/.openclaw/workspace/scripts/mission-control.py
# Then open: http://127.0.0.1:8765
```

---

## 🎮 INTERACTION PATTERNS

### Approve a Build Proposal
```
build [proposal-name]
```

### Skip/Reject a Proposal
```
skip [proposal-name]
```

### Add Source to Monitor
```
add source: [URL/channel] as [tier-1|tier-2|tier-3]
```

### Request Pattern Analysis
```
analyze [source] for thinking architecture
```

### Request Build Proposal
```
generate build proposal from [pattern]
```

---

## 📊 VALUE METRICS

Track your system's value generation:

| Metric | How to Check | Target |
|--------|--------------|--------|
| Patterns extracted | `ls 03-patterns/ \| wc -l` | 10/week |
| Proposals generated | `ls 04-decisions/ \| wc -l` | 5/week |
| SI tasks completed | `ls self-improvement/daily-tasks/ \| wc -l` | Daily |
| Corrections logged | `cat self-improvement/corrections/log.md` | Reduce over time |

---

## 🔔 NOTIFICATIONS (Optional)

Add Telegram notifications:

```bash
# 1. Create config file
cp ~/.openclaw/workspace/config/telegram.env.template \
   ~/.openclaw/workspace/config/telegram.env

# 2. Edit with your credentials
nano ~/.openclaw/workspace/config/telegram.env

# 3. Load credentials
source ~/.openclaw/workspace/config/telegram.env
```

---

## 🔧 TROUBLESHOOTING

### Dashboard won't start
```bash
# Check if already running
curl -s http://127.0.0.1:8765 | head -1

# If not, start manually
python3 ~/.openclaw/workspace/scripts/mission-control.py
```

### Cron jobs not running
```bash
# Verify cron is installed
crontab -l

# If empty, reinstall
crontab ~/.openclaw/workspace/crontab.openclaw
```

### Scripts not working
```bash
# Make all executable
chmod +x ~/.openclaw/workspace/scripts/*.sh
chmod +x ~/.openclaw/workspace/scripts/*.py
```

---

## 💡 GETTING MAXIMUM VALUE

### Daily Routine (5 min)
1. Check morning briefing
2. Review any proposals
3. Say "build it" or "skip it"
4. Glance at dashboard

### Weekly Routine (30 min)
1. Review extracted patterns
2. Approve/reject all pending proposals
3. Check self-improvement learnings
4. Adjust source list if needed

### Monthly Review (1 hour)
1. Analyze pattern quality trends
2. Review build output
3. Adjust automation schedule
4. Upgrade skills based on learnings

---

## 🎯 SUCCESS INDICATORS

You'll know the system is working when:

- ✅ Morning briefing appears automatically
- ✅ Patterns accumulate without prompting
- ✅ Build proposals queue up
- ✅ I improve based on corrections
- ✅ You spend 5 min/day, not 5 hours

---

**System Status:** ✅ OPERATIONAL  
**Next Action:** Check your morning briefing  
**Dashboard:** http://127.0.0.1:8765
