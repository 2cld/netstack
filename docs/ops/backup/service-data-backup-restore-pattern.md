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

## Service contracts: client, provider, receiver, coordinator

**Proposed extension (2026-11-03):** the responsibilities and evidence below are
the adoption contract, not a description of deployed checks.

A service client buys a recovery outcome, not a particular backup destination.
The hosting site is responsible for delivering it; a federation peer can provide
offsite storage without becoming a dependency the client must administer.

| Role | Owns | Must not delegate to the client |
|------|------|--------------------------------|
| Client | Service identity, required data scope, agreed recovery point/time objectives (RPO/RTO), escalation contact | Choosing disks, transport, receiver paths, or backup tooling |
| Provider site | Executable backup/recovery procedure, coverage, consistent dumps, encryption, delivery, restore proof, client-facing DR report | Responsibility for the promised recovery outcome |
| Receiver site | Accepted storage arrangement, receipt/integrity evidence, capacity, retention enforcement agreed with the provider | Verification that the application actually restores |
| Wip | Contract tracking, reconciliation of provider/receiver evidence, independent assessment, alerts and follow-up | Running the backup or declaring recovery proven from a successful transfer |

RPO is the maximum acceptable age of recoverable data; RTO is the maximum
acceptable recovery duration. Record owner-approved values, not assumed defaults.
Until terms and restore evidence exist, report protection as pending/unverified,
not as a fulfilled DR promise.

### What `.wip-contract.md` points to

Contracts link to this standard; they do not copy it. Use the existing
[contract-driven monitoring](../monitor/contract-driven-monitoring-pattern.md)
split between human-readable contracts and machine-readable checks.

| Contract | Required references and terms |
|----------|-------------------------------|
| Client | Service ID, provider, this standard, required data scope, agreed RPO/RTO, provider and Wip status lookup, escalation contact |
| Provider | This standard, owning repo's executable backup/recovery procedure, covered service IDs, agreed targets/retention, receiver agreement, status evidence and restore-test record |
| Receiver | Provider/backup-set ID, accepted storage allocation, transport/identity, retention and deletion authority, capacity threshold, receipt evidence, owner |
| Wip | Participating contracts, accepted monitoring endpoints/cadence, reconciliation rules, alert owner and escalation path |

An unspecified RPO, RTO, retention period, capacity threshold, or receiver
acceptance is an open adoption decision, not permission to choose one silently.
New probes require target-owner approval; a documentation change does not enable
monitoring or grant data/admin access.

The client needs only its provider's service-level result and Wip's assessment.
Changing an offsite peer must not require changing the client contract when the
promised service remains the same. Receiver topology, storage paths, credentials,
and other clients' results stay in provider/receiver operational records.

## Three-way evidence and communication check

```text
Provider: "I captured and sent backup B for the contracted data."
Receiver: "I received B and verified its expected contents."
Wip:      "The reports for B agree; freshness and restore evidence meet terms."
Provider site view: shows its result, receiver evidence, and Wip's assessment.
Client view: shows only its service's protection and Wip's assessment.
```

These are separate claims. A reachable receiver, an existing directory, or an
`scp` exit code is not independent proof of receipt or recoverability.

For each backup set, retain a stable service/backup-set ID and a unique,
non-secret run ID. Provider and receiver reports correlate on the same IDs.
Evidence includes:

| Producer | Evidence |
|----------|----------|
| Provider | Capture time, expected coverage manifest, successful database-dump results, artifact sizes/digests, per-target send result and time |
| Receiver | Matching run ID and manifest, received time, observed sizes/digests or repository-native verification result, available capacity and retention result |
| Restore operator | Service ID, backup run/snapshot restored, test time, database/application checks, elapsed recovery time, result |
| Wip | Source-report timestamps and run IDs, checked-at time, match/mismatch/missing evidence, freshness/RPO and restore-age assessment |

Keep manifests, hashes, customer records, and internal paths in protected
operational evidence. Public status exposes only approved non-secret IDs, times,
and sanitized results under the existing
[per-site status contract](../monitor/public-status-endpoint-pattern.md).
This extension does not add a per-service public endpoint or change the current
`status.json` schema. Machine-readable evidence fields need implementation and
validation before adoption.

The provider's report must project coverage **per service**. A backup set passes
for a client only if that client's required data is included. Restoring one
unrelated service cannot certify every client. Check the age of the captured data
and the receiver's evidence; a freshly generated dashboard cannot refresh an old
backup. Keep the last successful run visible when a newer run fails.

Wip reconciles the accepted reports; it does not need customer data or direct
access to the receiver's disk. The provider site can read Wip and peer status
without making backup execution depend on either monitoring endpoint.

Show backup protection, receiver evidence, restore proof, and coordinator
visibility separately. Missing/stale/mismatched evidence is unverified and maps to
`warning` (or `error` for an explicit failure) in the existing check vocabulary.
An unavailable Wip report must not erase a valid local backup result, and a
healthy Wip report must not turn a failed backup green. Do not feed peer aggregate
health recursively into local health; assess the relevant local evidence instead.

### Adoption proof before calling the loop operational

1. Owners accept the client/provider terms and provider/receiver arrangement.
2. Record expected service coverage, backup tooling, encryption/key recovery,
   retention, capacity thresholds, and read-only status lookup.
3. Capture a consistent backup and verify the same run at the receiver.
4. Restore from that offsite copy into isolation and verify the contracted
   service/data, measuring recovery time without contacting production.
5. Demonstrate missing-file, failed-transfer, stale-receipt, and mismatched-run
   detection. Demonstrate that losing Wip does not stop backups.
6. Publish sanitized provider/receiver evidence and Wip's correlated assessment;
   verify the provider and client views consume the intended service result.
7. Record commands, dates, results, unresolved gaps, and operator ownership in the
   implementation issue. Feed corrections back here.

Retain existing backup routes during a pilot. Do not prune or remove rollback
copies until the new route, retention policy, and restore proof are approved.

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

`BACKUP_STAGE` below must point to a fresh, complete run's staging directory,
prepared by the service hooks with consistent database backups and required
config/secrets. Do not substitute live database directories or reuse stale
staging contents.

```bash
export RESTIC_REPOSITORY=sftp:buadmin@<offsite-zt-ip>:<path>/<site>
export RESTIC_PASSWORD_FILE=/root/.config/restic/password   # mode 600
restic backup "${BACKUP_STAGE:?set the consistent staging directory}" --exclude '*/logs' --exclude-caches
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
restic check --read-data-subset=5%
```

Use one repository per offsite target (a bad run must not damage both copies). A restic repository **cannot be opened without its password**: store that password in at least two places apart from the host (see [credential rules](https://github.com/2cld/netstack/issues/22)).

Move to B when a site has restic available on a Linux infra node and the offsite targets accept SFTP; keep A where they do not (Windows offsite hosts reachable only by scp).

## State file and monitoring

The existing job writes one line, read by the site-status checker:

```
<YYYYMMDD-HHMM> OK|FAIL <source>=<size> <target>=OK|FAIL ...
```

Checks (see [public-status-endpoint-pattern](../monitor/public-status-endpoint-pattern.md)):
- **Freshness:** state file newer than 26 h.
- **Every target OK**, not just the first.
- **Restore-test age:** the date of the last successful restore test is recorded (`last-restore-test` in the site's recovery doc or state), and the check warns after 90 days. A passing backup job with a stale restore test is amber.

This legacy summary is not the independent receiver receipt or per-client
coverage proof defined above. Keep existing consumers working while adding those
signals; do not infer them from an overall `OK`.

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
