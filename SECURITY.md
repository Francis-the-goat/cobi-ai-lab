# SECURITY.md — Security Hardening Guide

Last updated: 2026-02-24

## 🔐 Current Security Status

### ✅ What's Secure
- File permissions: Config files are 600 (owner-only)
- GitHub: Token stored in macOS keyring
- Telegram: Bot token in protected credentials dir
- .gitignore: Prevents credential leaks

### ⚠️ Gaps to Fix
- API keys in config files (should be env vars)
- No backup/recovery system
- No intrusion detection
- GitHub token has broad permissions

---

## Priority 1: API Key Security

### Move Keys to Environment Variables

1. **Create env file:**
   ```bash
   touch ~/.openclaw/.env
   chmod 600 ~/.openclaw/.env
   ```

2. **Add to shell profile (~/.zshrc):**
   ```bash
   # Load OpenClaw environment
   if [ -f ~/.openclaw/.env ]; then
       source ~/.openclaw/.env
   fi
   ```

3. **Migrate keys:**
   - Moonshot API key → MOONSHOT_API_KEY
   - OpenAI API key → OPENAI_API_KEY
   - Remove from openclaw.json

### Key Rotation Schedule
- **Every 90 days:** Rotate API keys
- **After any incident:** Immediate rotation
- **Before major commits:** Verify no keys in code

---

## Priority 2: GitHub Security

### Token Scope Review
Current token has: `gist`, `read:org`, `repo`, `workflow`

**Recommended:**
- For CLI use: `repo` (full repo access) is OK
- Consider fine-grained token with specific repo only
- Never use token with `delete_repo` unless needed

### SSH vs HTTPS
Currently using HTTPS with token. SSH is more secure:
```bash
# Generate SSH key (if not exists)
ssh-keygen -t ed25519 -C "cobi@openclaw.local"

# Add to GitHub
gh ssh-key add ~/.ssh/id_ed25519.pub --title "Mac Mini"

# Switch to SSH
git remote set-url origin git@github.com:Francis-the-goat/cobi-ai-lab.git
```

---

## Priority 3: System Hardening

### Firewall (macOS)
```bash
# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
```

### Automatic Updates
```bash
# Enable automatic security updates
sudo softwareupdate --schedule on
```

### Backup Strategy

**What to backup:**
- ~/.openclaw/ (config, credentials)
- ~/.codex/ (Codex config)
- ~/.ssh/ (SSH keys)
- ~/workspace/ (code)

**Backup locations:**
- Local: Time Machine
- Cloud: Encrypted zip to iCloud/Dropbox
- GitHub: Already backed up (no credentials)

**Backup script:**
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d)
BACKUP_DIR="~/Backups/openclaw"
mkdir -p $BACKUP_DIR

tar -czf "$BACKUP_DIR/openclaw-backup-$DATE.tar.gz" \
  ~/.openclaw/credentials/ \
  ~/.openclaw/.env \
  ~/.codex/config.toml \
  ~/.ssh/

echo "Backup complete: $BACKUP_DIR/openclaw-backup-$DATE.tar.gz"
```

---

## Priority 4: Intrusion Detection

### Monitor for Unauthorized Access
```bash
# Check last logins
last

# Check failed login attempts
sudo log show --predicate 'eventMessage contains "authentication"' --last 24h

# Monitor file changes (install fswatch)
brew install fswatch
fswatch -o ~/.openclaw/credentials/ | while read f; do
  echo "Credentials directory modified at $(date)"
done
```

### Audit Critical Files
```bash
# Create checksums of critical files
md5 ~/.openclaw/openclaw.json ~/.codex/config.toml > ~/.openclaw/.file-checksums

# Check for changes
md5 -c ~/.openclaw/.file-checksums
```

---

## Priority 5: Telegram Security

### Bot Token Protection
- ✅ Already in protected credentials dir
- ✅ File permissions 600
- ✅ Not in GitHub

### Allowed Users
Currently paired with: 1796812772

**Best practice:**
- Review paired users monthly
- Remove unused pairings
- Monitor for unauthorized messages

---

## Priority 6: Network Security

### Tailscale (Optional but Recommended)
```bash
# Install Tailscale for secure remote access
brew install tailscale
sudo tailscale up

# This gives you secure access from phone/other devices
# Without exposing ports to internet
```

### OpenClaw Gateway
Currently running on localhost only (127.0.0.1) — ✅ Secure

**Never expose to internet without:**
- Authentication token (already enabled)
- HTTPS/WSS
- Rate limiting
- IP allowlist

---

## Security Checklist

### Weekly
- [ ] Check `git status` for accidental credential commits
- [ ] Review GitHub security alerts
- [ ] Check for failed login attempts

### Monthly
- [ ] Review API key usage (unexpected spikes?)
- [ ] Backup credentials
- [ ] Update dependencies (`brew update`)
- [ ] Review Telegram pairings

### Quarterly
- [ ] Rotate API keys
- [ ] Security audit of all connected services
- [ ] Test backup restoration
- [ ] Review and update this document

---

## Incident Response

### If API Key Leaked
1. **Immediately:** Revoke key in provider dashboard
2. **Within 1 hour:** Generate new key, update env
3. **Within 24 hours:** Check logs for unauthorized usage
4. **Post-incident:** Rotate all other keys (precaution)

### If GitHub Token Compromised
1. Revoke token immediately: https://github.com/settings/tokens
2. Generate new token
3. Update `gh auth`
4. Check repo for unauthorized changes

### If System Compromised
1. Disconnect from network
2. Change all passwords/keys
3. Restore from clean backup
4. Audit all recent activity

---

## Current Action Items

1. **TODAY:** Move API keys to env vars
2. **THIS WEEK:** Set up automated backups
3. **THIS MONTH:** Configure SSH for GitHub
4. **ONGOING:** Weekly security checklist

---

## Trust Model

**Who has access:**
- Cobi (full access)
- OpenClaw agent (reads config, never credentials directly)

**What the agent can do:**
- ✅ Read/write workspace files
- ✅ Execute shell commands
- ✅ Access GitHub via gh CLI
- ✅ Spawn Codex for coding
- ❌ Never access ~/.openclaw/credentials/
- ❌ Never read API keys
- ❌ Never modify security config

**This is enforced by:**
- SOUL.md boundaries
- File permissions (600 on credentials)
- .gitignore preventing credential commits
- Your oversight on all actions

---

## Questions?

If you see something suspicious:
1. Check this document
2. Review recent activity
3. Ask me to audit specific concerns
