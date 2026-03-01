# OUTPUT_STANDARD.md — Required Format

Use this format for all important autonomous outputs and Telegram handoffs.

## 0) Track
- Exactly one primary track: `SMB` / `UPSKILL` / `BRAND` / `LIFE` / `SYSTEM`.
- Optional secondary track if clearly relevant.

## 1) What I Did
- 2-5 bullets of concrete completed work.
- Include at least one artifact reference (file path, script, or command).

## 2) What Matters
- 1-3 findings.
- Each finding must include one metric, evidence point, or explicit assumption label.
- At least one finding must include either a source URL or a workspace file reference.

## 3) Decision
- Exactly one decision.
- For `SMB` or `SYSTEM` build tasks: `BUILD NOW` / `PROTOTYPE` / `REJECT`.
- For `UPSKILL`, `BRAND`, or `LIFE` tasks: `EXECUTE NOW` / `DEFER` / `DROP`.
- One sentence for why.

## 4) Top 3 Next Actions
1. Immediate next step.
2. Second highest-leverage step.
3. Third step with clear completion condition.

## 5) Risk
- One key risk and one mitigation.

## 6) One-Line Focus
- Single highest-leverage action for today.

## Fail State
If data is insufficient:
`BLOCKED: missing = [list] | fastest path = [action]`

## Style Rules
- No filler.
- No vague language.
- Prefer numbers over adjectives.
- Avoid defaulting to SMB if evidence points to a different highest-leverage move.
