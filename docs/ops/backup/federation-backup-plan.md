[edit](https://github.com/2cld/netstack/edit/master/docs/ops/backup/federation-backup-plan.md)
# Federation Backup Plan

Cross-site backup strategy for the 2cld federation. Each site maintains a working copy locally and replicates critical data to the other two nodes via encrypted overlay VPN.

## Design Principles

1. **3-2-1 Rule**: 3 copies, 2 different media/locations, 1 offsite
2. **Rotating offsite**: Alternate between two offsite targets (backup-0, backup-1) so a bad sync doesn't destroy both copies
3. **Tiered data**: Not everything needs 3 copies
4. **Encrypted transport**: All cross-site traffic goes over encrypted overlay VPN
5. **Pull-based optional**: Each site can pull its own backups from the others

## Storage Tiers

| Tier | Description | Copies | Offsite | Examples |
|------|-------------|--------|---------|----------|
| **Critical** | Irreplaceable, config, personal | 3 | 2 (both offsite nodes) | Photos, documents, VM exports, git repos, SSH keys |
| **Media** | Replaceable but costly to recreate | 2 | 1 (one offsite node) | Plex libraries, DVR recordings, music rips |
| **Scratch** | Easily re-obtained | 1 | 0 | Downloads, temp files, caches |

## Site Backup Map

```
┌─────────────────────────────────────────────────────────────┐
│                  Encrypted Overlay VPN Mesh                  │
│                                                             │
│  ┌──────────┐       ┌──────────┐       ┌──────────┐        │
│  │  CF      │       │  SL      │       │  WF      │        │
│  │          │◄─────►│          │◄─────►│          │        │
│  └────┬─────┘       └────┬─────┘       └────┬─────┘        │
│       │                   │                   │             │
└───────┼───────────────────┼───────────────────┼─────────────┘
        │                   │                   │
   ┌────▼─────┐       ┌────▼─────┐       ┌────▼─────┐
   │ Local    │       │ Local    │       │ Local    │
   │ Storage  │       │ Storage  │       │ Storage  │
   └──────────┘       └──────────┘       └──────────┘
```

### Per-Site Pattern

Each site has:

| Role | Description |
|------|-------------|
| Working | Local fast storage (NAS, internal drives) |
| Backup-0 | Offsite target on one of the other two nodes |
| Backup-1 | Offsite target on the remaining node |

Specific device assignments, IPs, and paths are documented in each site's private repo under `ops/backup/`.

## Backup Targets (Directory Layout)

Each offsite target maintains this structure:

```
/backup/<source-site>/
├── critical/           ← Tier: Critical (synced to both offsite)
│   ├── documents/
│   ├── photos/
│   ├── vm-exports/
│   └── config/
├── media/              ← Tier: Media (synced to one offsite)
│   ├── plex/
│   └── dvr/
└── .backup-state       ← Toggle file (contains "0" or "1")
```

## Rotation Logic

The toggle script alternates which offsite target gets updated:

```
Day/Run N:   sync → backup-0
Day/Run N+1: sync → backup-1
Day/Run N+2: sync → backup-0
...
```

State is tracked in `.backup-state` (local file, contains `0` or `1`).

**Why rotate?** If a file gets corrupted or accidentally deleted, the next sync propagates the damage to one target. The other target still has the previous good copy. You have until the *second* sync cycle to notice and recover.

## Transport

| Method | Use Case | Pattern Doc |
|--------|----------|-------------|
| rsync over SSH (via overlay VPN) | Primary method - incremental, efficient | [ssh-rsync-pattern](./ssh-rsync-pattern.md) |
| Synology Hyper Backup | Between Synology devices if both online | — |
| Manual USB drive (sneakernet) | Initial seed for large datasets | — |

**Backup user:** All automated rsync runs as `buadmin` (dedicated backup user, no sudo). See [ssh-rsync-pattern Step 0](./ssh-rsync-pattern.md) for setup.

## Prerequisites

Before running backups:

1. **buadmin user**: Created on all nodes per [ssh-rsync-pattern](./ssh-rsync-pattern.md)
2. **SSH keys**: buadmin has passwordless SSH to all targets
   ```bash
   # From ops controller as buadmin:
   ssh -i /home/buadmin/.ssh/id_backup buadmin@<target-overlay-ip> "echo ok"
   ```
   ```

2. **Target directories**: Create `/backup/<site>/` on each target

3. **Overlay VPN online**: Both source and target must be on the VPN network

## Sneakernet Seeding

For initial large syncs (hundreds of GB), physically carry a USB drive:

1. Attach USB to source, rsync data to it
2. Carry to target site
3. Attach at target, rsync from USB to backup path
4. Future: incremental rsync over VPN picks up from this baseline

Track seed media in the storage index with `role: seed-media` and the disk serial number.

## Implementation

Each site implements this plan in their private repo:
- `ops/backup/federation-sync.sh` — rsync with rotation logic
- `ops/backup/federation-sync.ps1` — PowerShell wrapper (Windows sites)
- `ops/backup/.backup-state` — current target toggle (gitignored)
- `ops/backup/logs/` — sync logs (gitignored)

## Future Improvements

- [ ] Add restic/borg for deduplication and versioning
- [ ] Add encryption at rest on offsite targets
- [ ] Automate via cron (daily critical, weekly media)
- [ ] Add monitoring: alert if backup hasn't run in X days
- [ ] Synology Hyper Backup between NAS devices when both online

## Related

- [Glacial Archive Pattern](../storage-index/glacial-archive-pattern.md) — archiving to cold/offline storage
- [Storage Indexing](../storage-index/) — knowing what you have
- [Sensitive Data Pattern](../security/sensitive-data-pattern.md) — protecting backup configs
- [Monitoring Pattern](../monitor/monitoring-pattern.md) — checking backup freshness
