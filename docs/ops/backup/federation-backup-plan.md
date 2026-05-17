[edit](https://github.com/2cld/netstack/edit/master/docs/ops/backup/federation-backup-plan.md)
# Federation Backup Plan

Cross-site backup strategy for the 2cld federation. Each site maintains a working copy locally and replicates critical data to the other two nodes via ZeroTier VPN.

## Design Principles

1. **3-2-1 Rule**: 3 copies, 2 different media/locations, 1 offsite
2. **Rotating offsite**: Alternate between two offsite targets (backup-0, backup-1) so a bad sync doesn't destroy both copies
3. **Tiered data**: Not everything needs 3 copies
4. **ZeroTier transport**: All cross-site traffic goes over encrypted ZT overlay
5. **Pull-based optional**: Each site can pull its own backups from the others (avoids needing push credentials everywhere)

## Data Tiers

| Tier | Description | Copies | Offsite | Examples |
|------|-------------|--------|---------|----------|
| **Critical** | Irreplaceable, config, personal | 3 | 2 (both offsite nodes) | Photos, documents, VM exports, git repos, SSH keys |
| **Media** | Replaceable but costly to recreate | 2 | 1 (one offsite node) | Plex libraries, DVR recordings, music rips |
| **Scratch** | Easily re-obtained | 1 | 0 | MeTube downloads, temp files, caches |

## Site Backup Map

```
┌─────────────────────────────────────────────────────────────┐
│                    ZeroTier VPN Mesh                         │
│                  (d5e5fb65371eb4a4)                          │
│                                                             │
│  ┌──────────┐       ┌──────────┐       ┌──────────┐        │
│  │  CF      │       │  SL      │       │  WF      │        │
│  │          │◄─────►│          │◄─────►│          │        │
│  │ .17.219  │       │ .17.94   │       │ .17.209  │        │
│  └────┬─────┘       └────┬─────┘       └────┬─────┘        │
│       │                   │                   │             │
└───────┼───────────────────┼───────────────────┼─────────────┘
        │                   │                   │
   ┌────▼─────┐       ┌────▼─────┐       ┌────▼─────┐
   │ cfbu     │       │ slMedia  │       │ sg       │
   │ DS212    │       │ (share)  │       │ Synology │
   │ 10.2/24  │       │ slwin11  │       │ .9.2     │
   └──────────┘       └──────────┘       └──────────┘
```

### CF Site (Cedar Falls)

| Role | Device | Path | ZeroTier | Notes |
|------|--------|------|----------|-------|
| Working | cfbu Synology | 192.168.10.2 (isolated) | — | Direct-connected to CyberTruck |
| Backup-0 | sl: slwin11ops | /backup/cf/ | 10.147.17.94 | Via ZT, rsync over SSH |
| Backup-1 | wf: sg Synology | /backup/cf/ | 10.147.17.209 | Via ZT, rsync over SSH |

### SL Site (St. Louis)

| Role | Device | Path | ZeroTier | Notes |
|------|--------|------|----------|-------|
| Working | slwin11ops | S:\slMedia, local | 10.147.17.94 | Primary ops machine |
| Working | mg2 | Docker volumes | 10.147.17.135 | Hyper-V VM (currently offline) |
| Backup-0 | cf: cfbu | /backup/sl/ | via 10.147.17.219 | CyberTruck must relay (cfbu isolated) |
| Backup-1 | wf: sg Synology | /backup/sl/ | 10.147.17.209 | Via ZT, rsync over SSH |

### WF Site (Winfield)

| Role | Device | Path | ZeroTier | Notes |
|------|--------|------|----------|-------|
| Working | sg Synology | 192.168.9.2 | 10.147.17.209 | Primary NAS |
| Backup-0 | sl: slwin11ops | /backup/wf/ | 10.147.17.94 | Via ZT, rsync over SSH |
| Backup-1 | cf: cfbu | /backup/wf/ | via 10.147.17.219 | CyberTruck must relay |

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
Day/Run N:   sync → backup-0 (e.g., sl)
Day/Run N+1: sync → backup-1 (e.g., wf)
Day/Run N+2: sync → backup-0
...
```

State is tracked in `.backup-state` (local file, contains `0` or `1`).

**Why rotate?** If a file gets corrupted or accidentally deleted, the next sync propagates the damage to one target. The other target still has the previous good copy. You have until the *second* sync cycle to notice and recover.

## Transport

| Method | Use Case |
|--------|----------|
| rsync over SSH (via ZeroTier) | Primary method — incremental, efficient |
| Synology Hyper Backup | Between Synology devices (cfbu ↔ sg) if both online |
| Manual USB drive | Initial seed for large datasets (avoid days of ZT transfer) |

## Prerequisites

Before running backups:

1. **SSH keys**: Each backup source needs passwordless SSH to its targets
   ```bash
   # From cf (CyberTruck WSL):
   ssh-keygen -t ed25519 -f ~/.ssh/id_backup
   ssh-copy-id -i ~/.ssh/id_backup ghadmin@10.147.17.94   # sl
   ssh-copy-id -i ~/.ssh/id_backup buadmin@10.147.17.209  # wf
   ```

2. **Target directories**: Create `/backup/<site>/` on each target
   ```bash
   # On sl:
   sudo mkdir -p /backup/cf /backup/wf
   # On wf sg:
   mkdir -p /volume1/backup/cf /volume1/backup/sl
   ```

3. **ZeroTier online**: Both source and target must be on ZT network

## Current Limitations

| Issue | Impact | Workaround |
|-------|--------|------------|
| mg2 (sl) offline 3 months | Can't backup to mg2 | Use slwin11ops directly |
| cfDVR/sg (wf) offline 1 month | Can't backup to wf | Wait for sg to come online, or use devwin10 |
| cfbu is isolated (no ZT) | Remote sites can't push to cfbu | CyberTruck pulls from remote, pushes to cfbu |
| Initial sync is large | ZT bandwidth limited | Seed via USB drive on-site visit |

## Future Improvements

- [ ] Add restic/borg for deduplication and versioning
- [ ] Add encryption at rest on offsite targets
- [ ] Automate via cron (daily critical, weekly media)
- [ ] Add monitoring: alert if backup hasn't run in X days
- [ ] Synology Hyper Backup between cfbu and sg when both online
