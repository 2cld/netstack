# Service Lifecycle Pattern

**Applies to:** Any infrastructure service, device, or system across the federation.

## Principle

You can't retire the old until the new is built, configured, deployed, AND monitored. The lifecycle is gated, not linear.

## Lifecycle Stages

```
BUILD --> CONFIGURE --> DEPLOY --> MONITOR --> BACKUP --> MAINTAIN
                                    |                       |
                                    |            [GATE: replacement validated]
                                    |                       |
                                    v                       v
                              validates gate          RETIRE/ARCHIVE
```

## Stage Definitions

| Stage | What happens | Pattern Doc | Output |
|-------|-------------|-------------|--------|
| Build | Bare metal to running OS | [federation-setup-guide](../deployments/federation-setup-guide.md) | Bootable node |
| Configure | OS to usable service | [ops-node-setup](../users/ops-node-setup.md), [cli-helper-pattern](./cli-helper-pattern.md) | Configured service |
| Deploy | Service accessible to users | [ns-site-template](https://gitea.cat9.me/nsadmin/ns-site-template) | Live service |
| Monitor | Health verified continuously | [cross-platform-monitoring](../monitor/cross-platform-monitoring-pattern.md) | Status checks pass |
| Backup | Data protected off-site | [ssh-rsync-pattern](../backup/ssh-rsync-pattern.md), [federation-backup-plan](../backup/federation-backup-plan.md) | .backup-state OK |
| Maintain | Ongoing care (updates, health) | TBD | Service stays healthy |
| Retire | Old service archived | [glacial-archive-pattern](../storage-index/glacial-archive-pattern.md), [storage-index](../storage-index/) | Indexed, labeled, shelved |

## The Retirement Gate

**Rule:** Never retire/archive/wipe until the replacement passes ALL gates:

```
OLD: sg Synology (Gitea, Plex, Cloudflare)
  Can retire WHEN:
    [x] New Gitea deployed (on nsdockerhv - DONE)
    [x] New Gitea monitored (morning check-in - DONE)
    [x] New Gitea backed up (backup-daily.sh - DONE)
    [ ] Plex migrated (to cg2 or CyberTruck?)
    [ ] Cloudflare tunnel migrated
    [ ] All data on sg confirmed copied elsewhere
  THEN: sg can be powered off and drives archived
```

## Gate Checklist Template

For any service migration:

```markdown
## Migration: [old service] -> [new service]

**Old:** [what/where]
**New:** [what/where]

**Gates (all must pass before retiring old):**
- [ ] BUILD: new service installed and running
- [ ] CONFIGURE: new service configured to match old
- [ ] DEPLOY: new service accessible (same URL/IP or updated DNS)
- [ ] MONITOR: new service in morning check-in / status script
- [ ] BACKUP: new service data backed up to off-site
- [ ] DATA: all data from old confirmed present on new
- [ ] USERS: all users can access new (no one still using old)

**Only after ALL gates pass:**
- [ ] RETIRE old service
- [ ] ARCHIVE old data per glacial-archive-pattern
- [ ] Update manifests (storage-index)
```

## Examples

### Drive Dedup (bs8 vs bs9)
- OLD: bs8 (698 GB, CATBU01)
- NEW: bs9 (1.86 TB, superset)
- Gate: confirm bs9 contains everything on bs8
- Then: wipe bs8, re-use drive

### Service Migration (sg Synology -> cg2/nsdockerhv)
- OLD: sg running Gitea, Plex, Cloudflare tunnel
- NEW: nsdockerhv (Gitea done), cg2 (Plex candidate)
- Gate: each service must be built, monitored, backed up on new
- Then: power off sg, archive drives

### Node Rebuild (devwin10 -> fresh install)
- OLD: current Windows 10 with accumulated config
- NEW: clean install with documented setup
- Gate: all data migrated, buadmin configured, monitoring verified
- Then: reformat, rebuild from docs

## Anti-Pattern

**"I'll just turn it off and see if anyone notices."**

This creates:
- Unknown data loss
- Services silently stop working weeks later
- No record of what was on it

**Instead:** Document what the old thing provides, build the replacement, validate the gates, THEN retire.

## Related

- [pattern-workflow](../pattern-workflow.md) - netstack drives all ops
- [federation-setup-guide](../deployments/federation-setup-guide.md) - BUILD stage
- [ops-node-setup](../users/ops-node-setup.md) - CONFIGURE stage
- [cross-platform-monitoring](../monitor/cross-platform-monitoring-pattern.md) - MONITOR stage
- [ssh-rsync-pattern](../backup/ssh-rsync-pattern.md) - BACKUP stage
- [glacial-archive-pattern](../storage-index/glacial-archive-pattern.md) - RETIRE stage
- [ops-cave-research](https://github.com/2cld/wip/blob/main/docs/ops-cave-research.md) - CAVE principle (freeze what works, validate before accepting)
