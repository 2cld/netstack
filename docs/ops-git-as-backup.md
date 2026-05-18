# Git as Backup — Federation Backup via Distributed Repos

**Status:** Active pattern (2026-05-18)
**Related:** [Federation Backup Plan](backup/federation-backup-plan.md) | [Sensitive Data Pattern](ops/security/sensitive-data-pattern.md)

## Thesis

> Git repos on multiple remotes ARE backups — with history, deduplication, and integrity checking built in.

Every `git push` to a remote is a backup. Every `git clone` by a collaborator is a backup. If you push to 2+ remotes on different physical machines, you satisfy the 3-2-1 rule without rsync, cron jobs, or backup software.

## Why Git is Better Than rsync for Text Data

| Feature | rsync | Git multi-remote |
|---------|-------|-----------------|
| Deduplication | File-level | Block-level (packfiles) |
| History | None (latest only) | Full history (every commit is a restore point) |
| Integrity | Checksum on transfer | SHA on every object (corruption detected) |
| Efficiency | Transfers diffs | Transfers diffs (similar efficiency) |
| Restore to point-in-time | ❌ Need snapshots | ✅ Any commit is a restore point |
| Encrypted transit | Optional (SSH) | Built-in (SSH/HTTPS) |
| Collaboration | Not designed for it | Core feature |

## The Multi-Remote Pattern

```
Working machine (local)
    ↓ git push
Remote 1: gitea.cat9.me (your metal, primary)
    ↓ mirror/sync
Remote 2: gitea on another node (your metal, different site)
    ↓ optional
Remote 3: GitHub (not your metal, but off-site + public/private)
    ↓ natural
Remote 4+: Collaborator clones (distributed copies)
```

### Git config for multi-remote push:
```bash
# Push to multiple remotes simultaneously
[remote "all"]
    url = git@gitea.cat9.me:nsadmin/REPO.git
    url = git@wf-gitea:nsadmin/REPO.git
    url = git@github.com:2cld/REPO.git

# Or use Gitea's built-in mirroring (automatic, no manual push needed)
```

## Backup Tiers by Data Type

| Data Type | Git as Backup? | Strategy |
|-----------|:-:|-----------|
| Code | ✅ Perfect | Multi-remote push |
| Documentation (markdown) | ✅ Perfect | Multi-remote push |
| Config files (sanitized) | ✅ Perfect | Multi-remote push |
| Session logs | ✅ Perfect | Push to private remotes only |
| Small data (JSON, CSV) | ✅ Good | Multi-remote push |
| Large binaries (photos, video) | ❌ | Use tar/rsync to federation storage |
| Databases | ❌ | Dump + transfer (or replication) |
| VM images / snapshots | ❌ | Federation storage (rsync/Incus) |
| Credentials / tokens | ❌ Never | Password manager only |

## Remote Classification

| Remote Type | Owns Metal? | Use For | Counts as Backup? |
|-------------|:-:|-----------|:-:|
| **Gitea (self-hosted)** | ✅ Yes | All data (including sensitive) | ✅ Primary backup |
| **GitHub (private repo)** | ❌ No | Non-sensitive code + docs | ✅ Off-site backup |
| **GitHub (public repo)** | ❌ No | Published patterns, public docs | ✅ Off-site + community |
| **Collaborator clone** | ❌ No | Active projects with contributors | ✅ Distributed backup |

## Collaborators as Backup

> Active collaborators who pull regularly ARE a distributed backup network.

Every collaborator's local clone is a full copy with complete history. The more active the collaboration, the more copies exist naturally.

**Benefits:**
- Zero additional backup infrastructure needed
- Backup freshness correlates with project activity
- Encourages frequent check-ins (good for collaboration AND backup)
- Geographic distribution (collaborators in different locations)

**The insight:** Instead of building separate backup infrastructure for active projects, encourage collaborators to pull often. Their workflow IS your backup strategy.

**When this works:**
- Active projects with regular contributors
- Open source / shared projects
- Any repo where multiple people need current code

**When this doesn't work:**
- Solo projects with no collaborators
- Sensitive repos you can't share
- Inactive/archived repos (no one is pulling)

## Federation Backup Architecture

```
Tier 1: Git multi-remote (code, docs, configs, logs)
├── gitea.cat9.me (cf node — your metal)
├── gitea on wf node (your metal, different site) — FUTURE
├── GitHub private (off-site, not your metal)
└── Collaborator clones (distributed)

Tier 2: Federation rsync/tar (large binaries, databases)
├── ZeroTier share triangle (cf ↔ sl ↔ wf)
└── Encrypted, scheduled, monitored via .backup-state

Tier 3: Cold archive (rarely accessed, long-term)
├── Glacial storage (see glacial-archive-pattern.md)
└── Offline media (USB drives, indexed per storage-index method)
```

## What Still Needs rsync

Even with git-as-backup, some data doesn't fit in git:
- hwpc-rp customer database (binary, large, changes constantly)
- Media files (CATPhotos, CATMusic — large binaries)
- VM exports and disk snapshots
- Proxmox backups (cg2 ZFS snapshots)

For these: use the federation triangle (ZeroTier shares) with tar/rsync.

## Implementation Steps

1. **Immediate:** Ensure all active repos push to at least 2 remotes
2. **Short-term:** Set up Gitea mirroring between cf and wf nodes
3. **Medium-term:** Add collaborators to active projects (backup + feedback)
4. **Long-term:** Automate mirror health monitoring (detect stale mirrors)

## Monitoring

Status scripts should verify:
- Last push to each remote (stale = backup gap)
- Mirror sync status (if using Gitea mirroring)
- Collaborator activity (active projects should have recent pulls)

## Related
- [Federation Backup Plan](backup/federation-backup-plan.md) — full 3-2-1 strategy
- [Storage Indexing](ops/storage-index/) — knowing what you have
- [Sensitive Data Pattern](ops/security/sensitive-data-pattern.md) — what goes where
- [CAVE Principles](ops/security/cave-principles.md) — own your infrastructure
- [Monitoring Pattern](ops/monitor/monitoring-pattern.md) — verifying backup health
