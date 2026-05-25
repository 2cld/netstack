# Ops Node Setup: nsadmin User Environment

**Pattern for:** Setting up the `nsadmin` operator account on any federation node.  
**Reference implementation:** nsdockerhv (cf site, Ubuntu 24.04)

## What This Covers

The standard operator environment that makes a node usable for daily ops work: repos, CLI tools, automation, credentials, and cron jobs.

This is separate from [Federation Setup Guide](../deployments/federation-setup-guide.md) (network, ZeroTier, Docker) — this doc covers the **user layer** on top of a working node.

## Prerequisites

- Ubuntu 24.04+ (or compatible Linux)
- `nsadmin` user account exists with sudo
- Node has network access (ZeroTier joined)
- Docker installed and nsadmin in `docker` group
- Node.js 22+ installed
- Git configured (`git config --global user.name/email`)

## 1. Directory Structure

```
/home/nsadmin/
├── code/              ← all repo clones
│   ├── netstack/      ← pattern library (always present)
│   ├── wip/           ← coordination (ops controller nodes)
│   ├── nsgctime/      ← Google API OAuth (shared node_modules)
│   ├── docker-compose/ ← service definitions
│   ├── cf/ sl/ wf/    ← site repos (as needed)
│   └── ...            ← project repos
├── backups/
│   ├── docker-daily/  ← Docker volume snapshots
│   └── logs/          ← backup cron logs
└── .local/
    └── bin/           ← CLI helper symlinks (on PATH)
```

## 2. PATH Setup

`~/.local/bin` must be on PATH. Verify:

```bash
echo $PATH | tr ':' '\n' | grep local/bin
```

If missing, add to `~/.bashrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## 3. Core Repo Clones

Every ops node gets netstack. Additional repos depend on node role.

```bash
cd ~/code

# Always
git clone https://github.com/2cld/netstack.git

# Ops controller nodes (currently: nsdockerhv)
git clone https://github.com/2cld/wip.git
git clone https://gitea.cat9.me/nsadmin/nsgctime.git
git clone https://gitea.cat9.me/nsadmin/docker-compose.git

# Site-specific
git clone https://github.com/2cld/cf.git   # if cf node
git clone https://github.com/2cld/sl.git   # if sl node
git clone https://github.com/2cld/wf.git   # if wf node
```

## 4. Node Modules (Shared Pattern)

`nsgctime` provides the shared `node_modules` for all Wip scripts (googleapis, dotenv, etc.):

```bash
cd ~/code/nsgctime
npm install
```

Scripts reference this via:
```bash
NODE_PATH=/home/nsadmin/code/nsgctime/node_modules node script.js
```

Or in the script itself:
```javascript
process.chdir('/home/nsadmin/code/nsgctime');
require('dotenv').config();
```

## 5. CLI Helpers

Per [cli-helper-pattern](../tools/cli-helper-pattern.md) — dispatcher scripts symlinked into PATH.

```bash
# Install wip command
chmod +x ~/code/wip/.local/scripts/wip
ln -sf ~/code/wip/.local/scripts/wip ~/.local/bin/wip

# Verify
which wip    # → /home/nsadmin/.local/bin/wip
wip help     # → shows subcommands
```

Add more as projects grow (e.g., `ns` for netstack ops, `hwpc` for HWPC tools).

## 6. Credentials

Credentials live in `.env` files and token JSON — never committed to git.

| File | Purpose | Repo |
|------|---------|------|
| `~/code/wip/.env` | Wip API tokens (GitHub, Gitea) | wip |
| `~/code/nsgctime/.env` | Google OAuth client ID/secret | nsgctime |
| `~/code/nsgctime/data/calendar-token.json` | Google OAuth refresh token | nsgctime |
| `~/code/docker-compose/*/.env` | Per-service secrets | docker-compose |

See [repo-private-data](../tools/repo-private-data.md) for backup and recovery of these files.

**Critical:** If this node dies, these tokens are lost unless backed up. Secure off-site backup of credentials is required.

## 7. Cron Jobs

Ops controller nodes run automated daily tasks:

```cron
# Daily 2 AM: Federation backup (Docker → off-site)
0 2 * * * /bin/bash /home/nsadmin/code/cf/ops/scripts/backup-daily.sh >> /home/nsadmin/backups/logs/cron.log 2>&1

# Daily 5:30 AM: Wip morning routine (health, calendar, task blocks)
30 5 * * * /bin/bash /home/nsadmin/code/wip/.local/scripts/wip-daily-cron.sh >> /home/nsadmin/code/wip/logs/wip-cron.log 2>&1

# Monthly: Log rotation (keep 30 days)
0 4 1 * * find /home/nsadmin/backups/logs -name '*.log' -mtime +30 -delete
0 4 1 * * find /home/nsadmin/code/wip/logs -name '*.log' -mtime +30 -delete
```

Pattern: cron calls a bash script, bash script calls node scripts, output goes to dated log files.

## 8. Kiro CLI (AI Tooling)

```
~/.local/bin/kiro-cli       ← main binary
~/.local/bin/kiro-cli-chat  ← chat mode
~/.local/bin/kiro-cli-term  ← terminal mode
```

Used for: AI-assisted ops, pattern documentation, code review, automation development.

## 9. Verification

After setup, confirm:

```bash
# PATH works
which wip && wip help

# Repos accessible
cd ~/code/netstack && git status
cd ~/code/wip && git status

# Node works
node --version   # v22+

# Cron installed
crontab -l

# Docker works
docker ps

# ZeroTier connected
zerotier-cli info   # should show ONLINE

# Credentials present
test -f ~/code/wip/.env && echo "wip .env ✓"
test -f ~/code/nsgctime/.env && echo "nsgctime .env ✓"
test -f ~/code/nsgctime/data/calendar-token.json && echo "calendar token ✓"
```

## Node Roles

Not every node needs everything:

| Component | Ops Controller | Site Node | Backup Target |
|-----------|:-:|:-:|:-:|
| netstack clone | ✓ | ✓ | ✓ |
| wip + nsgctime | ✓ | — | — |
| CLI helpers | ✓ | optional | — |
| Cron (backup) | ✓ | — | — |
| Cron (wip daily) | ✓ | — | — |
| Docker services | ✓ | ✓ | optional |
| Site repo clone | ✓ | ✓ | — |
| Kiro CLI | ✓ | optional | — |

## Related

- [Pattern Workflow](../pattern-workflow.md) — how netstack drives all ops work
- [CLI Helper Pattern](../tools/cli-helper-pattern.md) — dispatcher script convention
- [Automation Pattern](../tools/automation-pattern.md) — read→propose→apply
- [Repo Private Data](../tools/repo-private-data.md) — credential management
- [Federation Setup Guide](../deployments/federation-setup-guide.md) — network/Docker layer
- [Backup Cron Pattern](../backup/backup-cron-pattern.md) — backup automation
