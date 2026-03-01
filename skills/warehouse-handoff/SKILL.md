# Skill: Warehouse Shift Handoff

## Purpose
Runs autonomously during Cobi's warehouse shifts. Processes backlog, surfaces priorities, writes to vault, notifies on return.

## Trigger
Cron: Every 2 hours during shift hours (06:00-14:00)

## Actions
1. Check transcription queue → Process pending
2. Check value resource harvest → Run if stale
3. Synthesize: What's most important for Cobi to see?
4. Write summary to `01-daily/YYYY-MM-DD-handoff.md`
5. If critical: Send Telegram notification

## Output Format
```
## Shift Handoff — [TIME]
### Processed
- [X] Transcription queue (N files)
- [X] Value harvest (N sources)

### Priorities
1. [Action item with context]
2. [Action item with context]

### Decisions Needed
- [Question with options]

### Next Actions
- [Specific next step]
```

## Constraints Applied
- Local-first (fits $200 budget)
- Async (runs during shift)
- Action-oriented (Cobi reviews, doesn't process)
