# Skill Opportunity Detector

**Autonomous analysis of extracted patterns to identify codifiable, valuable skills.**

## Problem
- Pushing infrastructure into skill repos (bad)
- Building without understanding value (waste)
- No constraint-checking before proposals (risk)

## Solution
Daily autonomous scan that evaluates patterns against:
1. **Codifiable** — Can this be an OpenClaw skill?
2. **Reusable** — Would others use it?
3. **Valuable** — Solves real operational problems?
4. **Constraint-fit** — Fits $200 budget, warehouse shifts, async?

## Quick Start

```bash
# Install
cd ~/.openclaw/skills
git clone https://github.com/Francis-the-goat/skill-opportunity-detector.git

# Configure
export SKILL_VAULT_PATH="$HOME/obsidian/openclaw"

# Run daily scan
./scripts/daily-scan.sh

# Or analyze specific pattern
./scripts/analyze-patterns.sh --source nate-2026-02-28
```

## Output

**Proposals** (`04-decisions/skill-proposals/`):
- Overall score ≥ 7
- Full spec with acceptance criteria
- Risk assessment
- Awaits your "build it"

**Rejected** (`04-decisions/rejected-patterns/`):
- Score < 7
- Logged with reasoning
- May combine with future patterns

## Scoring Rubric

| Criterion | Weight | What Counts |
|-----------|--------|-------------|
| Codifiable | 40% | Automation, workflow, framework language |
| Reusable | 25% | Agent-related, OpenClaw, business value |
| Valuable | 20% | Solves problem, improves efficiency |
| Constraint-fit | 15% | Async-friendly, budget-aligned |

## Automation

```bash
# Daily at 7 AM (after pattern extraction)
0 7 * * * ~/.openclaw/skills/skill-opportunity-detector/scripts/daily-scan.sh
```

## Files

```
skill-opportunity-detector/
├── SKILL.md                    # Full documentation
├── config.yaml                 # Scoring thresholds
├── scripts/
│   ├── daily-scan.sh          # Cron entry point
│   ├── analyze-patterns.sh    # Manual trigger
│   └── evaluate-buildability.py  # Scoring logic
└── README.md                   # This file
```

## Cost

- Analysis: $0 (local models)
- Synthesis: ~$0.25/day for complex patterns
- **Total: <$8/month**

## License

MIT
