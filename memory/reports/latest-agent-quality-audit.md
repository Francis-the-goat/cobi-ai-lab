# Agent Quality Audit - 2026-02-25

## Scope
- Profile: `dev`
- Window: last `7` days
- Overall score: `85.7/100`

## Job Scores
| Job | Runs | Reliability | Delivery | Median ms | Score |
|---|---:|---:|---:|---:|---:|
| transcription-retry-worker | 4 | 50% | 25% | 501878 | 43.0 |
| foundry-daily-build-candidate | 3 | 67% | 100% | 127939 | 78.0 |
| orchestrator-daily-plan | 0 | 100% | 100% | 0 | 85.0 |
| intel-midday-synthesis | 0 | 100% | 100% | 0 | 85.0 |
| system-weekly-retro | 0 | 100% | 100% | 0 | 85.0 |
| trajectory-weekly-brief | 0 | 100% | 100% | 0 | 85.0 |
| resource-harvest-video-web | 3 | 100% | 100% | 27234 | 92.0 |
| warehouse-shift-handoff | 1 | 100% | 100% | 65428 | 92.0 |
| proof-daily-content-draft | 1 | 100% | 100% | 177604 | 93.0 |
| self-improvement-daily-loop | 3 | 100% | 100% | 67032 | 94.7 |
| source-adaptation-recommender | 2 | 100% | 100% | 39637 | 96.0 |
| quality-weekly-audit | 1 | 100% | 100% | 103550 | 100.0 |

## Findings
- `P1` `transcription-retry-worker` reliability is 50% over recent runs.
- `P1` `transcription-retry-worker` median runtime is 501878ms (timeout risk).
- `P2` `transcription-retry-worker` delivery success is only 25%.
- `P3` `transcription-retry-worker` latest error: cron: job execution timed out
- `P1` `foundry-daily-build-candidate` reliability is 67% over recent runs.
- `P3` `foundry-daily-build-candidate` latest error: ⚠️ ✉️ Message failed
- `P2` `resource-harvest-video-web` output structure compliance is low (33%).
- `P2` `warehouse-shift-handoff` output structure compliance is low (33%).

## Recommended Fixes
1. Move long-running workers to fewer runs/day and cap batch size per run.
2. Pin flaky jobs to a more stable model lane and simplify prompt scope.
3. Force `OUTPUT_STANDARD.md` headings in cron prompts and reject non-compliant drafts.
4. Keep a single Telegram poller/profile active and monitor deliveryStatus weekly.

## Next Review
- Re-run this audit after 7 days and compare score delta.
