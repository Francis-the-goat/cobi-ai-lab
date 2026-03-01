# Token Hygiene Checklist

Last updated: 2026-02-24

## Objective

Reduce credential blast radius and keep OpenClaw operable under compromise scenarios.

## Immediate Actions (This Week)

- [ ] Rotate gateway auth token in `~/.openclaw/openclaw.json`
- [ ] Rotate Telegram bot token and update channel config
- [ ] Rotate web search API key in OpenClaw config
- [ ] Rotate Moonshot API key in provider dashboard
- [ ] Re-auth OpenAI Codex profile if needed
- [ ] Rotate any stale device tokens in `~/.openclaw/devices/paired.json`

## File Permission Baseline

- [x] `~/.openclaw/.env` -> `600`
- [ ] `~/.openclaw/openclaw.json` -> `600`
- [ ] `~/.openclaw/agents/main/agent/auth.json` -> `600`
- [ ] `~/.openclaw/agents/main/agent/auth-profiles.json` -> `600`
- [ ] `~/.openclaw/devices/paired.json` -> `600`

Verify:
```bash
stat -f '%N %Sp %Su:%Sg' \
  ~/.openclaw/.env \
  ~/.openclaw/openclaw.json \
  ~/.openclaw/agents/main/agent/auth.json \
  ~/.openclaw/agents/main/agent/auth-profiles.json \
  ~/.openclaw/devices/paired.json
```

## Hygiene Rules

- [ ] Never put real secrets in workspace markdown/docs
- [ ] Keep production tokens out of demo/dev profiles
- [ ] Keep one active gateway service process only
- [ ] Review paired devices monthly and remove stale entries

## Incident Drill (Monthly)

- [ ] Simulate token compromise
- [ ] Rotate affected token
- [ ] Verify agent still responds
- [ ] Check logs for unauthorized usage patterns
- [ ] Record postmortem in `memory/YYYY-MM-DD.md`
