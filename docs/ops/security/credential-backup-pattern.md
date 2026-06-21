# Pattern: Credential Backup (Encrypted Off-Site)

**Category:** `docs/ops/security/`  
**Purpose:** Encrypted backup of sensitive credentials (API tokens, OAuth tokens, .env files) to multiple off-site locations, with automated cron scheduling and documented recovery.  
**Audience:** Any admin managing services with credentials that are single-copy on one machine.

---

## The Problem

Credentials (API tokens, OAuth refresh tokens, .env files) are:
- Gitignored (correctly — never committed to repos)
- Single-copy on the machine that uses them
- Irreplaceable without manual regeneration (multiple services, multiple accounts)

If the machine dies, ALL credentials must be recreated from scratch. This can take hours or days depending on how many services are involved.

## The Solution: GPG + SCP to Federation Storage

```
Machine with credentials
    ↓
tar (collect files) → gpg (encrypt) → scp (transfer to 2+ locations)
    ↓                                    ↓
CyberTruck (local off-machine)     sl (off-site)
```

---

## Generic Script Template

```bash
#!/bin/bash
# backup-credentials.sh — Encrypted off-site backup of sensitive files
# Cron: weekly (Sunday 3 AM recommended — after daily backups complete)
#
# Requirements: gpg, ssh, scp, tar
# Set GPG_PASSPHRASE env var for non-interactive (cron) use

set -euo pipefail

DATE=$(date +%Y%m%d)
TMP_DIR="/tmp/cred-backup-$$"
ARCHIVE="credentials-${DATE}.tar.gz"
ENCRYPTED="${ARCHIVE}.gpg"

# --- CONFIGURE THESE ---
# Files to backup (absolute paths)
FILES=(
  "/path/to/.env"
  "/path/to/oauth-token.json"
  "/path/to/other-sensitive-file"
)

# Base directory (for relative path preservation in tar)
BASE_DIR="/path/to/project"

# Destinations (SSH targets)
DEST_1_TARGET="user@host1"
DEST_1_PATH="/path/to/backup/dir"
DEST_2_TARGET="user@host2"
DEST_2_PATH="/path/to/backup/dir"

SSH_KEY="${HOME}/.ssh/id_backup"
# --- END CONFIGURATION ---

echo "=== Credential Backup — $(date) ==="

# Setup
mkdir -p "$TMP_DIR"
trap "rm -rf $TMP_DIR" EXIT

# Collect
echo "[1/4] Collecting files..."
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    REL="${f#$BASE_DIR/}"
    mkdir -p "$TMP_DIR/$(dirname "$REL")"
    cp "$f" "$TMP_DIR/$REL"
    echo "  + $REL"
  else
    echo "  ! MISSING: $f"
  fi
done

# Archive
echo "[2/4] Archiving..."
tar -czf "$TMP_DIR/$ARCHIVE" -C "$TMP_DIR" .
echo "  -> $ARCHIVE ($(du -sh "$TMP_DIR/$ARCHIVE" | cut -f1))"

# Encrypt
echo "[3/4] Encrypting (AES-256)..."
if [ -n "${GPG_PASSPHRASE:-}" ]; then
  echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "$TMP_DIR/$ENCRYPTED" "$TMP_DIR/$ARCHIVE"
else
  gpg --symmetric --cipher-algo AES256 -o "$TMP_DIR/$ENCRYPTED" "$TMP_DIR/$ARCHIVE"
fi
echo "  -> $ENCRYPTED"

# Transfer
echo "[4/4] Transferring..."
for dest in "1" "2"; do
  eval TARGET="\$DEST_${dest}_TARGET"
  eval PATH_="\$DEST_${dest}_PATH"
  if scp -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 -q "$TMP_DIR/$ENCRYPTED" "$TARGET:$PATH_/$ENCRYPTED" 2>/dev/null; then
    echo "  ✅ $TARGET: $PATH_/$ENCRYPTED"
  else
    echo "  ❌ $TARGET: transfer failed"
  fi
done

echo "=== Complete ==="
```

---

## Cron Setup

```bash
# Add to crontab (run as the user who owns the credentials):
# Weekly Sunday 3 AM (after daily backups complete at 2 AM)
0 3 * * 0 GPG_PASSPHRASE="your-secure-passphrase" /bin/bash /path/to/backup-credentials.sh >> /path/to/logs/cred-backup.log 2>&1
```

**Security note:** Passphrase in crontab is readable only by the owning user. For higher security, use gpg-agent or a key file with restricted permissions:
```bash
# Alternative: read passphrase from a file
GPG_PASSPHRASE=$(cat /path/to/.gpg-passphrase)
```

---

## Recovery Procedure

When you need to restore credentials on a new/rebuilt machine:

```bash
# 1. Copy encrypted file from backup location
scp user@backup-host:/path/to/credentials-YYYYMMDD.tar.gz.gpg /tmp/

# 2. Decrypt (will prompt for passphrase)
gpg --decrypt /tmp/credentials-YYYYMMDD.tar.gz.gpg > /tmp/credentials.tar.gz

# 3. Extract to project directory
tar -xzf /tmp/credentials.tar.gz -C /path/to/project/

# 4. Verify files are in place
ls -la /path/to/project/.env
ls -la /path/to/project/path/to/token.json

# 5. Clean up
rm /tmp/credentials-YYYYMMDD.tar.gz.gpg /tmp/credentials.tar.gz

# 6. Test: run the service that uses these credentials
# (service-specific — verify API calls work)
```

---

## Monitoring

Add a check to the daily cron to verify credential backup freshness:

```bash
# Check: does a recent encrypted backup exist on the backup target?
LATEST=$(ssh user@backup-host "ls -t /path/to/backup/credentials-*.gpg 2>/dev/null | head -1")
if [ -n "$LATEST" ]; then
  echo "  ✅ Credential backup: $LATEST"
else
  echo "  ❌ Credential backup: NOT FOUND on backup-host"
fi
```

---

## What to Include

| Include | Example | Why |
|---------|---------|-----|
| .env files | API tokens, secrets | Can't regenerate without service access |
| OAuth tokens | calendar-token.json | Avoid re-auth flow |
| SSH keys (private) | id_backup, id_ed25519 | Rebuilding key auth is tedious |
| Config with secrets | database URLs, connection strings | Service won't start without them |

## What NOT to Include

| Exclude | Why |
|---------|-----|
| Public keys | Not secret, can be re-derived |
| Code (in git repos) | Already backed up by git |
| Large data files | Use regular backup (backup-daily.sh), not credential backup |
| Temp files | Regenerated on use |

---

## Retention

- Keep last 4 weekly backups (1 month of history)
- Old backups: delete from destinations monthly
- Add to log rotation: `find /path/to/backups -name "credentials-*.gpg" -mtime +30 -delete`

---

## Related

- [sensitive-data-pattern.md](./sensitive-data-pattern.md) — what's sensitive, two-layer approach
- [backup-cron-pattern](../backup/backup-cron-pattern.md) — general cron backup methodology
- [ssh-rsync-pattern](../backup/ssh-rsync-pattern.md) — SSH transport for backups
- [Wip implementation](https://github.com/2cld/wip/blob/main/.local/scripts/backup-wip-credentials.sh) — reference implementation
