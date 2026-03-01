# AGENT_EVOLUTION_ROADMAP.md

## Goal
Build a high-agency AI operator that continuously turns AI change into SMB business leverage, with strong quality, security, and functionality.

## Chunk 1 — Control Plane Hardening (Completed)
Outcome:
- Reduce generic chatbot behavior.
Work done:
- Tightened core injected context files.
- Added strict output contract and fail-state (`BLOCKED`).
- Enabled source-card scaffolding for adaptation.
Done when:
- Outputs consistently include decisions, evidence, and next actions.

## Chunk 2 — Source Adaptation Engine (In Progress)
Outcome:
- Agent learns from sources you feed it.
Build:
- Standard source-card workflow in `memory/sources/`.
- Maintain `memory/style_profile.md` from repeated source patterns.
- Convert each source into one actionable asset/task.
Implementation now in place:
- `tools/yt-transcribe` with subtitle-first + Whisper fallback.
- Optional cloud fallback in `tools/cloud-transcribe` (OpenAI/Deepgram).
- `scripts/ingest_video_source.sh` for video -> transcript -> source card ingestion.
- `scripts/transcription_queue.py` + `scripts/transcription_queue.sh` for retry/deadletter handling.
- Skill scaffold: `~/.openclaw/skills/video-source-intelligence/`.
Done when:
- Every new source creates a source card + one action.

## Chunk 3 — Idea Generation Engine
Outcome:
- High-quality, non-generic idea flow.
Build:
- Weekly opportunity thesis board with scoring: urgency, value, speed, timing.
- Kill weak ideas quickly; escalate top 1-2 ideas.
Done when:
- At least 3 high-quality ideas/week with explicit BUILD/PROTOTYPE/REJECT decisions.

## Chunk 4 — Agentic Asset Factory
Outcome:
- Ideas become real assets.
Build:
- Repeatable asset pack template with acceptance criteria and rollback.
- Track stage: thesis -> prototype -> proof -> offer.
Done when:
- One asset shipped per week with measurable business hypothesis.

## Chunk 5 — Self-Improvement and Auto-Promotion
Outcome:
- System improves itself safely.
Build:
- Daily metrics sync + experiment backlog.
- Auto-activate one safe experiment at a time.
- Promote or rollback based on measured runs.
Done when:
- At least one promoted improvement per 2 weeks with no reliability regression.

## Chunk 6 — Reliability + Security Ops
Outcome:
- Stable 24/7 operation with low incident rate.
Build:
- Eliminate duplicate gateway/bot pollers.
- Maintain sandboxing + minimal attack surface.
- Weekly audit cadence and incident log.
Done when:
- No Telegram 409 conflicts and no missed critical scheduled runs for 7 days.

## Quality Gate (All Chunks)
- No generic output.
- Evidence + economics + decision + action required.

## Security Gate (All Chunks)
- Sandbox on.
- Elevated tools disabled unless explicitly required.
- No credential exposure.

## Functionality Gate (All Chunks)
- Gateway healthy.
- Cron runs execute and deliver.
- Logs show no recurring transport conflicts.
