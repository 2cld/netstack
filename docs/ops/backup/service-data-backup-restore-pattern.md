# Service Data Backup and Restore Pattern

**Status:** Draft for review (2026-11-01) | **Tracking:** [netstack#32](https://github.com/2cld/netstack/issues/32), [netstack#38](https://github.com/2cld/netstack/issues/38) | **First implementation:** [2cld/cf#14](https://github.com/2cld/cf/issues/14)

How a site backs up the data of its small Docker services (Gitea, Traefik certificates, tte, app databases) to other locations, and how it proves it can get them back. This is the **service-data** story. Large media and file shares stay in [federation-backup-plan](./federation-backup-plan.md).

> A backup you have not restored is a hope, not a backup. This pattern is not "adopted" at a site until one restore has been run and recorded.

## Where it fits

| Doc | Covers |
|-----|--------|
| [federation-backup-plan](./federation-backup-plan.md) | strategy, 3-2-1, offsite targets for big data |
| [ssh-rsync-pattern](./ssh-rsync-pattern.md) | transport and the `buadmin` user |
| [backup-cron-pattern](./backup-cron-pattern.md) | schedule and state file |
| **this doc** | **what to back up under the appdata layout, how to restore, how to test it** |
| [bmr-pattern](../deployments/bmr-pattern.md) | the rebuild; this doc is its `restore.sh` half |
| [service-recovery-pattern](./service-recovery-pattern.md) | per-service recovery notes |

## What gets backed up

One backup root per host: **`/opt/appdata`** ([layout](../../wan/cloudflare/docker-service-subdomain-pattern.md)).

| Include | Why |
|---------|-----|
| `/opt/appdata/<name>/data/`, `config/` | service state |
| `.env`, `cf-token`, `acme.json` | secrets and certificates (slow or impossible to recreate) |
| `compose.yml` | already in git; kept in the archive so the archive stands alone |
| Database dumps (below) | consistent copies of live databases |

| Exclude | Why |
|---------|-----|
| `*/logs/`, caches, `*/tmp/` | rebuildable noise |
| Container images | pulled from registries (pinned tags make this safe) |
| `~/code` repos | in git; back those up by pushing |
| NAS shares and media | federation-backup-plan |

**Never use a plain file copy of a live database.** A copy taken mid-write can be corrupt, and the corruption is discovered only at restore.

| Service type | Consistent copy before archiving |
|--------------|-----------------------------------|
| PostgreSQL (Gitea) | `docker exec <db> pg_dump -U <user> <db> > dump.sql` |
| SQLite (tte, nspwa) | `sqlite3 <db> ".backup '<out>'"`, or stop the container briefly |
| Anything else | the vendor's dump/export command, written down next to the service |

Each service keeps its backup hook in the repo that owns it (`backup.sh` beside the compose file) so the job does not need to know every service.

## Two implementations, one contract

The **contract** is the same either way: backup root, hooks, encryption, retention, state file, tested restore. Choose per site.

### A. Baseline: archive and copy (works today)

`tar` the staged data and dumps, then `scp`/`rsync` to the offsite targets over the ZeroTier overlay as `buadmin` (existing cf job: `backup-daily.sh`).

Required additions to be a conforming baseline:
- **Encrypt before it leaves the host** (`gpg --symmetric` or `age`); the passphrase or key is **not** in a crontab line, a script or git. Store it root-readable (mode 600) and record where it lives in the site's recovery doc.
- **Retention** pruning on every target (for example 7 daily, 4 weekly, 6 monthly) so offsite disks do not fill silently.
- **Per-target fault isolation** (one down target must not abort the others, and must turn the state file red).
- State file records the result **per target**.

### B. Target: restic (encrypted, deduplicated, verifiable)

`restic` over SFTP to the same offsite hosts. It provides what the baseline needs scripts for: client-side encryption, deduplicated snapshots, `forget --prune` retention, and `restic check` plus `restore` to verify.

```bash
export RESTIC_REPOSITORY=sftp:buadmin@<offsite-zt-ip>:<path>/<site>
export RESTIC_PASSWORD_FILE=/root/.config/restic/password   # mode 600
restic backup /opt/appdata --exclude '*/logs' --exclude-caches
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
restic check --read-data-subset=5%
```

Use one repository per offsite target (a bad run must not damage both copies). A restic repository **cannot be opened without its password**: store that password in at least two places apart from the host (see [credential rules](https://github.com/2cld/netstack/issues/22)).

Move to B when a site has restic available on a Linux infra node and the offsite targets accept SFTP; keep A where they do not (Windows offsite hosts reachable only by scp).

## State file and monitoring

The job writes one line, read by the site-status checker:

```
<YYYYMMDD-HHMM> OK|FAIL <source>=<size> <target>=OK|FAIL ...
```

Checks (see [public-status-endpoint-pattern](../monitor/public-status-endpoint-pattern.md)):
- **Freshness:** state file newer than 26 h.
- **Every target OK**, not just the first.
- **Restore-test age:** the date of the last successful restore test is recorded (`last-restore-test` in the site's recovery doc or state), and the check warns after 90 days. A passing backup job with a stale restore test is amber.

## Restore

Restore **into a scratch location first**, never over a running service.

1. Pick the snapshot or archive (latest, or a named date).
2. Decrypt/restore to `/tmp/restore-<date>/` (restic: `restic restore latest --target /tmp/restore-<date>`).
3. Check: file counts and sizes plausible; open each database dump/SQLite file with its own tool (`sqlite3 <db> 'PRAGMA integrity_check'`, load the SQL dump into a throwaway container).
4. For a real recovery: stop the service, move the restored folder into `/opt/appdata/<name>/`, fix ownership, `docker compose up -d`, run the service's health check.
5. Record the result (below).

### Full-site rebuild

Fresh host, this site's repo and the latest offsite backup: [bmr-pattern](../deployments/bmr-pattern.md) `bootstrap.sh` + `deploy.sh`, then restore `/opt/appdata`, then `verify.sh`. For the Cloudflare tunnel and Access setup the secrets (`TUNNEL_TOKEN`) come from the restored `.env` files; rotate them if the old host is suspected compromised.

## The restore test (required)

Run at adoption, then **at least every 90 days** and after any change to the backup job or the appdata layout.

| Step | Expected |
|------|----------|
| Restore latest backup to scratch | completes without error |
| Integrity checks on each database | pass |
| Start one service (for example tte) from the restored folder on a scratch port | health check returns 200 |
| Compare a known record (latest Gitea issue, a tte row) | present |
| Delete scratch data | done |

Record in an issue comment on the site's backup issue: date, snapshot used, who ran it, result, time taken, anything that was wrong in the docs. Fix the docs in the same change. **Time taken is the site's real recovery-time estimate.**

## Site adoption

| Site | Mode | Last restore test | Notes |
|------|------|-------------------|-------|
| cf | A (baseline), moving to B | none | [2cld/cf#14](https://github.com/2cld/cf/issues/14); job exists but predates the appdata layout |
| wf | Pending | none | wip#48 BMR test-flight; netstack#32 |
| sl | Pending | none | |

## Common failure modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Job reports OK but restore is empty or old | the job reads a path that moved (layout change) and skips it quietly | the job must fail on a missing source, not skip; re-run the test after any layout change |
| Database restores but is corrupt | file copy of a live database | use the dump/`.backup` hook |
| Cannot decrypt old backup | passphrase lived only on the dead host | two off-host copies of the key (see credentials rules) |
| Offsite disk full | no retention | prune on every target |
| One target down, state file says OK | the first success short-circuited | record per-target results; any FAIL is amber |
| Restored service starts with permission errors | ownership differs from the container user | `chown` to the container's user (see appdata ownership rules) |

## Related

- [federation-backup-plan](./federation-backup-plan.md), [ssh-rsync-pattern](./ssh-rsync-pattern.md), [backup-cron-pattern](./backup-cron-pattern.md), [service-recovery-pattern](./service-recovery-pattern.md)
- [bmr-pattern](../deployments/bmr-pattern.md), [docker-service-subdomain-pattern](../../wan/cloudflare/docker-service-subdomain-pattern.md)
- BMR test-flight: wip#48; Wip-prompted BMDR loop: wip#77
