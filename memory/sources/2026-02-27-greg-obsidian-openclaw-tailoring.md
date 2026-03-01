# Greg Isenberg x Vin: Obsidian + Agent Workflow (Tailored to OpenClaw)

## Source
- Video: https://youtu.be/6MBq1paspVU
- Title: How I Use Obsidian + Claude Code to Run My Life
- Date observed: 2026-02-27
- Transcript basis: YouTube auto-captions (cleaned + timestamped files saved beside this note)

## What the video is really teaching (portable principles)
1. Treat your vault as the source of truth for context.
2. Move from chat memory to file-based memory you can inspect.
3. Use short repeatable commands for high-frequency workflows (context load, day plan, idea extraction).
4. Convert reflection into action through a promotion pipeline (daily notes -> insights -> tasks -> projects).
5. Improve outcomes by editing the knowledge system (vault), not only prompts.

## OpenClaw Translation (Claude Code -> OpenClaw)
- Claude `/context` command -> OpenClaw skill/job: `Context Loader` that reads `SOUL.md`, `USER.md`, `GOALS.md`, latest `memory/*.md`, and active project notes.
- Claude `/today` command -> OpenClaw cron: morning synthesis that builds a prioritized day plan and sends Telegram summary.
- Claude `/graduate` command -> OpenClaw skill/job: `Idea Graduate` that scans recent notes, surfaces candidate ideas, asks promotion decision, and writes promoted notes.
- Interactive coding loop -> OpenClaw orchestrator + specialized sub-agent jobs (research, synthesis, build, content).
- Agent tuning via prompt only -> Agent tuning via markdown operating docs + templates + quality rubric.

## High-value sections and why they matter
- `00:12:46` context loader concept: one command loads life/work/current state from files and backlinks.
- `00:13:42` morning review: combines calendar/tasks/messages + note history into prioritized plan.
- `00:27:02` autonomous behavior: agent reads vault, finds connections, makes decisions from deep context.
- `00:43:20` and `00:49:07` idea graduation loop: scan recent notes, cross-reference vault, promote best ideas into structured assets.

## Best-fit implementation for your setup
1. Keep Obsidian as thinking + decision layer.
2. Keep OpenClaw workspace as execution layer.
3. Enforce this pipeline daily:
   - `Sources` capture
   - `Insights` synthesis
   - `Decisions` commit
   - `Tasks` execution
   - `Assets` shipment
   - `Brand` publication
4. Require every autonomous run to output:
   - facts/evidence
   - decision
   - next 3 actions
   - risk + mitigation

## Immediate configuration fixes to unlock this model
- Your current cron has repeated failures with `model not allowed: ollama/qwen2.5:3b`.
- Either add model `qwen2.5:3b` to providers or change those cron jobs to an allowed model (for example `ollama/llama3.2:3b` or `ollama/qwen2.5:7b`).
- Without this fix, lightweight heartbeat and repetitive jobs fail, and the architecture loses reliability.

## The non-generic operating rule
Do not ask the agent for broad advice.
Ask for one of these contracts only:
- "Extract 3 decision-grade insights from X with evidence and one recommended action each."
- "Promote one idea from daily notes into a validated asset spec with done criteria."
- "Generate tonight handoff with completed work, top 3 next actions, and one risk to kill tomorrow."

## Suggested OpenClaw prompt snippets (drop into agent chat)
- "Run Context Loader. Summarize my current priorities from vault and workspace in 7 bullets max."
- "Run Idea Graduate on last 72h notes. Promote top 2 ideas into `06_Assets`-ready specs."
- "Create end-of-shift handoff: what was done, what matters, and exact next 3 actions by leverage."

## Outcome if you run this consistently
- Better decisions from deeper personal context.
- Fewer generic outputs because tasks are contract-driven.
- Higher compounding leverage because ideas are systematically promoted into reusable assets.
