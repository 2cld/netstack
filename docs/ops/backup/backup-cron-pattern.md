[edit](https://github.com/2cld/netstack/edit/master/docs/ops/backup/backup-cron-pattern.md) or [./](./)

# Backup Cron Pattern — Automated Backup + Status Update

How the ops controller (nsdockerhv) runs daily backups and keeps status pages current.

## Flow

```
site-config.yml          (defines what to back up)
       │
       ▼
backup-cron.sh           (generated or hand-written per site)
       │
       ├─ 1. Run backup (tar, pg_dump, scp to targets)
       ├─ 2. Write .backup-state (timestamp + result)
       ├─ 3. Update docs/status.md (backup state table)
       └─ 4. Git commit + push (status page refreshed)
       
Morning check-in reads status pages → flags staleness
```

## Where It Runs

**All cron jobs run on the ops controller (nsdockerhv).**

Why:
- Single machine to maintain cron schedules
- Has SSH keys to all targets (push/pull data)
- Has git credentials to push status updates
- Follows ops-controller-pattern (brain in one place)

## Cron Schedule

```bash
# /etc/cron.d/federation-backup (on nsdockerhv)

# Daily 2 AM: Docker services backup (Gitea DB, data, Traefik)
0 2 * * * nsadmin /home/nsadmin/code/docker-compose/backup/backup-docker-services.sh /home/nsadmin/backups/docker-daily

# Daily 2:30 AM: Transfer Docker backup to sl
30 2 * * * nsadmin scp -r /home/nsadmin/backups/docker-daily/* ghadmin@10.147.17.94:F:/slMedia/catbu-sl/docker/

# Daily 3 AM: hwpc-rp backup (tar from cat9fin → sl)
0 3 * * * nsadmin /home/nsadmin/code/cf/ops/scripts/backup-hwpc-rp.sh

# Daily 3:30 AM: Update status pages
30 3 * * * nsadmin /home/nsadmin/code/cf/ops/scripts/update-status.sh
```

## Backup Script Pattern

Each backup script follows read → execute → report:

```bash
#!/bin/bash
# backup-<service>.sh
# Runs on nsdockerhv, reaches targets via SSH

set -euo pipefail
DATE=$(date +%Y%m%d-%H%M)
LOG="/home/nsadmin/backups/logs/backup-${DATE}.log"

echo "=== Backup Start: $(date) ===" | tee "$LOG"

# 1. EXECUTE: Run the backup
# (tar, pg_dump, scp — specific to what's being backed up)

# 2. TRANSFER: Send to off-site target(s)
scp /path/to/backup ghadmin@10.147.17.94:F:/slMedia/catbu-sl/

# 3. REPORT: Write .backup-state
echo "${DATE} OK $(du -sh /path/to/backup | cut -f1)" > /home/nsadmin/backups/.backup-state

echo "=== Backup Complete: $(date) ===" | tee -a "$LOG"
```

## Status Update Script

After backups run, update the status page:

```bash
#!/bin/bash
# update-status.sh — reads .backup-state files, updates docs/status.md in site repos

set -euo pipefail
DATE=$(date +%Y-%m-%d)

# Read backup state
DOCKER_STATE=$(cat /home/nsadmin/backups/.backup-state 2>/dev/null || echo "UNKNOWN")
HWPC_STATE=$(ssh ghadmin@10.147.17.94 "dir F:\\slMedia\\catbu-sl\\hwpc-rp-*.tar /O:-D /B 2>nul" 2>/dev/null | head -1 || echo "UNKNOWN")

# Update cf status page (sed the backup table)
# ... (site-specific logic)

# Commit and push
cd /home/nsadmin/code/cf
git add docs/status.md
git commit -m "Auto-update: backup status ${DATE}" --allow-empty
git push origin main
```

## Connection to site-config.yml

The `storage.backups` section in site-config.yml defines what to back up:

```yaml
storage:
  backups:
    - name: "hwpc-rp"
      source: "nsadmin@10.147.17.218:C:/cat9finshare/Account/hwpc-rp"
      destination: "ghadmin@10.147.17.94:F:/slMedia/catbu-sl/"
      schedule: "daily"
      method: "tar+scp"
    - name: "docker-services"
      source: "local:/home/nsadmin/backups/docker-daily"
      destination: "ghadmin@10.147.17.94:F:/slMedia/catbu-sl/docker/"
      schedule: "daily"
      method: "scp"
```

A future `generate-backup-cron.sh` in ns-site-template can read this config and produce the cron file + scripts automatically.

## Verification

Morning check-in (`morning-checkin.js`) reads:
1. `.backup-state` files (local)
2. `docs/status.md` backup table (via git or GitHub API)
3. Flags anything older than 48 hours as ⚠️ stale

## Evolution

| Stage | What | Status |
|:-----:|------|:------:|
| 1 | Hand-written scripts + manual cron | ← WE ARE HERE |
| 2 | Cron configured, runs daily, updates status | NEXT |
| 3 | ns-site-template generates scripts from site-config.yml | FUTURE |
| 4 | Morning check-in auto-flags staleness | FUTURE |

## Related

- [federation-backup-plan.md](./federation-backup-plan.md) — 3-2-1 strategy
- [ssh-rsync-pattern.md](./ssh-rsync-pattern.md) — transport method
- [../tools/ops-controller-pattern.md](../tools/ops-controller-pattern.md) — why nsdockerhv runs everything
- [../tools/automation-pattern.md](../tools/automation-pattern.md) — read → propose → apply
- [../monitor/performance-baseline-pattern.md](../monitor/performance-baseline-pattern.md) — what "stable" means
- [../deployments/federation-setup-guide.md](../deployments/federation-setup-guide.md) — full site setup
