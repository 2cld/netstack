# SSH + rsync Pattern for Federation Backup

**Applies to:** All federation nodes (cf, sl, wf) and coordination machines
**Related:** [Federation Backup Plan](ops/backup/federation-backup-plan.md) | [CAVE Principles](ops/security/cave-principles.md)

## Why SSH/rsync Over SMB

| Feature | SMB | rsync/SSH |
|---------|-----|-----------|
| Efficiency | Mounts full share, reads everything | Only transfers diffs (delta) |
| Security | Windows auth, NTLM/Kerberos | SSH keys, fully encrypted |
| Automation | Needs mount, credentials in fstab | Key-based auth, no password prompts |
| Cross-platform | Windows-centric | Works on Linux, macOS, Windows (OpenSSH) |
| Monitoring | Hard to verify what transferred | Exit codes, logs, checksums, --dry-run |
| Long-distance | Poor over high-latency links | Designed for it (delta compression) |
| Verification | No built-in integrity check | --checksum flag verifies every byte |

## Architecture

```
Source node (has the data)
    |
    | rsync over SSH (encrypted, delta-only)
    v
Target node (receives backup)
    |
    | Verify: exit code + file count + checksum
    v
.backup-state (timestamp + status)
```

## Setup Pattern

### 0. Create dedicated backup user (buadmin)

Every federation node gets a `buadmin` user dedicated to backup operations. This user:
- Has read access to backup source paths only
- Owns no services or interactive sessions
- Uses a dedicated SSH key (no passphrase, for automation)
- Can be restricted via `authorized_keys` command= directives
- Has NO sudo access (principle of least privilege)

**Linux (nsdockerhv, future Ubuntu nodes):**
```bash
# Create user with no login shell, no home directory clutter
sudo useradd -m -s /bin/bash buadmin
sudo mkdir -p /home/buadmin/.ssh
sudo chmod 700 /home/buadmin/.ssh

# Generate backup key pair (on ops controller)
sudo ssh-keygen -t ed25519 -f /home/buadmin/.ssh/id_backup -N "" -C "buadmin@$(hostname)"
sudo chown -R buadmin:buadmin /home/buadmin/.ssh

# Add buadmin to groups for read access to backup sources
sudo usermod -aG docker buadmin  # if backing up Docker volumes
```

**Windows (sl, wf, cat9fin):**
```powershell
# Create local user (no password login - key auth only)
net user buadmin /add /active:yes
# Set a strong random password (won't be used - key auth only)
net user buadmin "$(New-Guid)" /y

# Create .ssh directory
mkdir C:\Users\buadmin\.ssh

# Add the ops controller's buadmin public key
# Copy from nsdockerhv: /home/buadmin/.ssh/id_backup.pub
# Paste into: C:\ProgramData\ssh\administrators_authorized_keys
# (or C:\Users\buadmin\.ssh\authorized_keys if not admin)
```

**Key deployment (from ops controller to all nodes):**
```bash
# Deploy buadmin's public key to each target node
# Linux targets:
ssh-copy-id -i /home/buadmin/.ssh/id_backup.pub buadmin@<target-ip>

# Windows targets (manual - paste key into authorized_keys):
cat /home/buadmin/.ssh/id_backup.pub
# Then on Windows: add to C:\ProgramData\ssh\administrators_authorized_keys
```

**Verify:**
```bash
# From ops controller as buadmin:
sudo -u buadmin ssh -i /home/buadmin/.ssh/id_backup buadmin@<target-ip> "echo buadmin connected"
```

### 1. Generate SSH key pair (on the machine that PUSHES or PULLS)

```bash
# Generate a dedicated backup key (no passphrase for automation)
ssh-keygen -t ed25519 -f ~/.ssh/id_backup -N "" -C "backup@$(hostname)"
```

### 2. Deploy public key to target node

```bash
# Copy public key to target's authorized_keys
ssh-copy-id -i ~/.ssh/id_backup.pub user@target-node

# Or manually append:
cat ~/.ssh/id_backup.pub | ssh user@target "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Enable OpenSSH on Windows nodes (if needed)

```powershell
# PowerShell as Administrator:
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Add authorized key:
# Place public key in C:\Users\<user>\.ssh\authorized_keys
# Or for admin users: C:\ProgramData\ssh\administrators_authorized_keys
```

### 4. Test connectivity

```bash
ssh -i ~/.ssh/id_backup user@target-node "echo 'SSH works'"
```

### 5. rsync backup command

```bash
# Push backup to remote (from source to target)
rsync -avz --checksum \
  -e "ssh -i ~/.ssh/id_backup" \
  /path/to/critical/data/ \
  user@target-node:/path/to/backup/

# Pull backup from remote (target pulls from source)
rsync -avz --checksum \
  -e "ssh -i ~/.ssh/id_backup" \
  user@source-node:/path/to/data/ \
  /local/backup/path/
```

### 6. Automation (cron)

```bash
# Daily backup at 2am
0 2 * * * /path/to/backup-script.sh >> /var/log/backup.log 2>&1
```

## Backup Script Template

```bash
#!/bin/bash
# Federation backup script - rsync over SSH
# Pattern: push critical data to off-site node
# Runs as: buadmin (dedicated backup user)

set -euo pipefail

SOURCE="/path/to/critical/data"
TARGET_USER="buadmin"
TARGET_HOST="10.x.x.x"  # ZeroTier overlay IP
TARGET_PATH="/path/to/backup/$(hostname)"
SSH_KEY="/home/buadmin/.ssh/id_backup"
STATE_FILE="/path/to/.backup-state"

echo "[$(date)] Starting backup..."

# Run rsync
rsync -avz --checksum --delete \
  -e "ssh -i $SSH_KEY -o ConnectTimeout=10" \
  "$SOURCE/" \
  "${TARGET_USER}@${TARGET_HOST}:${TARGET_PATH}/"

EXIT_CODE=$?

# Write state file
cat > "$STATE_FILE" << EOF
{
  "last_run": "$(date -Iseconds)",
  "status": "$([ $EXIT_CODE -eq 0 ] && echo success || echo failed)",
  "source": "$SOURCE",
  "target": "${TARGET_HOST}:${TARGET_PATH}",
  "exit_code": $EXIT_CODE
}
EOF

echo "[$(date)] Backup complete (exit: $EXIT_CODE)"
```

## Security Considerations

### Key management
- Use dedicated backup keys (not your personal SSH key)
- No passphrase on automated keys (trade-off: if key is stolen, attacker gets read access)
- Restrict the key on the target side (see below)

### Restricting backup keys (authorized_keys)

Limit what the backup key can do on the target:
```
# In target's ~/.ssh/authorized_keys:
command="/usr/bin/rrsync -ro /path/to/backup",no-pty,no-agent-forwarding ssh-ed25519 AAAA... backup@source
```

This restricts the key to read-only rsync access to a specific directory only.

### Network security
- All traffic over ZeroTier (encrypted overlay) or direct SSH (encrypted)
- No cleartext credentials on the wire
- Firewall: only allow SSH from known ZeroTier IPs

## Connection to Vault Pattern

The vault approach (age-encrypted secrets in a private git repo) complements rsync/SSH:

- **Vault (git):** Small, rarely-changing secrets (tokens, keys, configs)
- **rsync/SSH:** Large, frequently-changing data (databases, media, backups)

Both use SSH as transport. The vault repo is pulled via git (SSH). Backup data is synced via rsync (SSH). One key infrastructure, two use cases.

### Reference: Vault architecture (pattern from federation partner)

```
Provisioning repo (public or private git):
├── Setup scripts (rebuild OS from scratch)
├── Service configs (declarative)
└── secrets/ (age-encrypted keys)

Backup target (rsync over SSH):
├── Incremental data snapshots
├── Database dumps
└── .backup-state (monitoring)
```

The provisioning scripts are reproducible (CAVE principle). Only dynamic data needs rsync backup. This minimizes what you're transferring and storing.

## Monitoring Integration

Status scripts verify backup health:
```bash
# Read .backup-state and check freshness
LAST_RUN=$(cat .backup-state | jq -r '.last_run')
STATUS=$(cat .backup-state | jq -r '.status')
# Alert if stale or failed
```

See [Monitoring Pattern](ops/monitor/monitoring-pattern.md) for integration with morning check-in.

## Federation Backup Topology (SSH/rsync)

```
cf (Cedar Falls) ──rsync──→ sl (O'Fallon)
       |                         |
       └──rsync──→ wf (Winfield) ←──rsync──┘

Each node can push to both others.
Each node can pull from both others.
SSH keys deployed bidirectionally.
```

## Designated Monitor (Wip)

The backup user (`buadmin`) runs the backups. A **designated monitor** verifies they ran successfully and alerts when they don't.

**Monitor role (Wip):**
- Reads `.backup-state` files during morning check-in
- Flags stale backups (> 24h since last success)
- Surfaces failures in daily standup
- Sends action recommendations to node owner per [contract-map](https://github.com/2cld/wip/blob/main/docs/contract-map.md)

**Monitor does NOT:**
- Run backups (that's buadmin's job via cron)
- Fix failures directly (sends recommendation to owner)
- Have sudo or admin access (read-only observation)

**Separation of concerns:**
```
buadmin (ownership)  = runs backup, writes .backup-state
wip (observability)  = reads .backup-state, alerts on failure
nsadmin (admin)      = fixes issues when alerted
```

**Monitor check (in morning-checkin.js):**
```bash
# Read .backup-state, verify freshness
STATE=$(cat /home/nsadmin/backups/.backup-state)
# If stale or missing: flag in standup + send action recommendation
```

**Integration with [federation-backup-plan](./federation-backup-plan.md):**
- Each node's `.backup-state` is the contract between buadmin and the monitor
- Monitor checks all nodes daily (via SSH read or local file)
- Red alerts squeak daily until resolved (Principle 8)

## Related
- [Federation Backup Plan](ops/backup/federation-backup-plan.md) — 3-2-1 strategy
- [Federation Production Plan](ops-federation-production-plan.md) — phased deployment
- [Git as Backup](ops-git-as-backup.md) — for code/docs (complements rsync for data)
- [CAVE Principles](ops/security/cave-principles.md) — reproducible environments
- [Sensitive Data Pattern](ops/security/sensitive-data-pattern.md) — what goes where
- [Monitoring Pattern](ops/monitor/monitoring-pattern.md) — verifying backup health
