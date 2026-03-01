# QUALITY_BAR.md — Non-Negotiables

Every strategic output must satisfy all checks below.

## 1) Evidence
- Include concrete sources or data points.
- Avoid unsupported claims.

## 2) Economics
- State baseline metric and target metric.
- Name the likely budget owner.

## 3) Decision Clarity
- End with one explicit decision.
- Use build-lane decisions for `SMB`/`SYSTEM`: BUILD NOW, PROTOTYPE, or REJECT.
- Use execution-lane decisions for `UPSKILL`/`BRAND`/`LIFE`: EXECUTE NOW, DEFER, or DROP.

## 4) Execution Quality
- Include top 3 next actions in priority order.
- Include one key risk and one mitigation.

## 5) Communication Quality
- Keep summary concise and actionable.
- No generic filler.

## 6) Structure Quality
- Follow `OUTPUT_STANDARD.md` for all Telegram and autonomous summaries.
- Include all required sections in order.
- End with one explicit highest-leverage next action.

## 7) Business-First Gate
- Do not build new infrastructure unless it unlocks a task required this week.
- Prefer direct value creation before framework expansion.
- If evidence quality is weak, gather better sources first (primary docs, operator artifacts, real user signal).

## 8) Anti-Generic Gate
- Include at least one non-obvious insight (not a standard chatbot pattern).
- Include at least one identified flaw/risk in the current plan and a concrete correction.
- Anchor at least one finding to a concrete artifact (`path`, command output, source URL, or metric log).

## 9) Execution Reliability
- Prefer workspace-relative paths; avoid hardcoded host-only paths.
- If `read` tool fails, immediately fallback to `exec` + `cat`/`rg` and continue.

## 10) Track Fit
- Explicitly declare the active track (`SMB`, `UPSKILL`, `BRAND`, `LIFE`, `SYSTEM`).
- Avoid repeated single-track outputs unless urgent work requires it.
- If the same track appears 3 times in a row, explain why and set the next under-served track.

## 11) Source Quality Gate
- Prioritize primary sources (official AI lab docs, first-party engineering posts, direct operator case studies).
- Do not let aggregator content dominate recommendations unless it contains original evidence.
- For research summaries, include at least:
  - one primary source
  - one operator source with practical implementation detail
- If source quality is weak, return `BLOCKED` and request higher-signal inputs.

## 12) Skill Contract Gate
- Autonomous workflows should rely only on skills with contract bundles:
  `contracts/input.schema.json`, `contracts/output.spec.json`,
  `contracts/failure-semantics.json`, `contracts/slo.json`, `tests/cases.jsonl`.
- If a required skill scores `<75` in the latest skill contract audit, treat it as unsafe and escalate to `SYSTEM` before delegation.
