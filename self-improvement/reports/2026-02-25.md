# Self-Improvement Report

- Generated: 2026-02-25T09:50:08.675986+00:00
- Window: last 7 days

## Snapshot

- Runs: 14
- Success rate: 86%
- Avg duration: 166.5s
- P95 duration: 403.8s
- Avg tokens: 19314
- Total tokens: 251089
- Model mismatches: 4

## Job Metrics

- `radar-daily-scan` runs=5 success=100% avgDuration=127.3s avgTokens=19197 configured=ollama/qwen2.5:7b actual=moonshot/kimi-k2.5
- `foundry-daily-build-candidate` runs=3 success=67% avgDuration=106.9s avgTokens=27316 configured=moonshot/kimi-k2.5 actual=moonshot/kimi-k2.5
- `self-improvement-daily-loop` runs=2 success=100% avgDuration=63.4s avgTokens=14214 configured=moonshot/kimi-k2.5 actual=moonshot/kimi-k2.5
- `transcription-retry-worker` runs=2 success=50% avgDuration=501.9s avgTokens=8810 configured=ollama/llama3.2:3b actual=unknown
- `warehouse-shift-handoff` runs=1 success=100% avgDuration=65.4s avgTokens=18600 configured=moonshot/kimi-k2.5 actual=moonshot/kimi-k2.5
- `proof-daily-content-draft` runs=1 success=100% avgDuration=177.6s avgTokens=17314 configured=moonshot/kimi-k2.5 actual=moonshot/kimi-k2.5

## Top Experiments

1. [HIGH] `foundry-daily-build-candidate` reliability
   - Issue: Success rate is 67%.
   - Change: Shorten prompt scope and add deterministic pre-check steps.
   - Target: successRate>=95% over next 10 runs
2. [HIGH] `radar-daily-scan` routing
   - Issue: Configured model does not match runtime model consistently.
   - Change: Pin payload.model to explicit provider/model and verify provider health.
   - Target: modelMismatchRuns=0 over next 5 runs
3. [MEDIUM] `foundry-daily-build-candidate` cost
   - Issue: Average tokens per run is 27316.
   - Change: Trim system context for this lane and add explicit output length caps.
   - Target: avgTokens reduced by 20%
4. [MEDIUM] `radar-daily-scan` cost
   - Issue: Average tokens per run is 19197.
   - Change: Trim system context for this lane and add explicit output length caps.
   - Target: avgTokens reduced by 20%

## One-Line Focus

Run experiment: foundry-daily-build-candidate -> Shorten prompt scope and add deterministic pre-check steps.
