# Local Model Benchmark - 2026-02-26

Scope:
- Compare `llama3.2:3b`, `qwen2.5:3b`, `qwen2.5:7b` on Mac mini M4.
- Cases: strict math output, strict JSON output, 90-word ops plan.

Raw data:
- `memory/reports/2026-02-26-local-model-benchmark.csv`

Summary:
- `qwen2.5:3b` avg eval speed: **55.84 tok/s**, pass rate: **3/3**
- `llama3.2:3b` avg eval speed: **46.37 tok/s**, pass rate: **0/3**
- `qwen2.5:7b` avg eval speed: **25.68 tok/s**, pass rate: **1/3**

Decision:
- Set `qwen2.5:3b` as `LocalFast` default.
- Keep `qwen2.5:7b` as `LocalSmart` for deeper analysis.
- Keep `llama3.2:3b` as fallback for resilience.

Applied changes:
- `config/model_routing_policy.json`
- `scripts/enforce_model_routing.sh`
- `scripts/model_router.sh`
- docs aligned in `MODEL_ROUTING.md`, `MODEL_ARCHITECTURE.md`, `AGENTIC_ARCHITECTURE_V2.md`, `AUTONOMOUS_WORK_SYSTEM.md`
