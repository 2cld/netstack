[edit](https://github.com/2cld/netstack/edit/master/docs/ops/storage-index/README.md)
# Storage Indexing Method

A federation-wide approach to inventorying, tagging, and managing storage across all 2cld nodes.

## Problem

Data is scattered across multiple locations, device types, and services with no single inventory. USB drives accumulate without labels. NAS devices hold unknown data. Cloud storage is untracked.

## Principles

1. **Index first, organize later** — Don't move anything until you know what you have
2. **Metadata is cheap** — The index lives in git, costs nothing
3. **Offline drives get indexed when attached** — Plug in, scan, unplug, index persists
4. **Tiers drive decisions** — Tag everything, then decide what to keep/move/delete
5. **Federation-aware** — Each node indexes its own storage, netstack holds the method

## Storage Tiers

| Tier | Access Pattern | Examples | Backup |
|------|---------------|----------|--------|
| **Hot** | Always online, fast access | Internal drives, local NAS | Replicate to 2 offsite nodes |
| **Warm** | Online but slow or remote | ZeroTier shares, cloud services | 1 offsite copy |
| **Cold** | Offline, plug in when needed | USB drives, spare NAS disks | Index only, store safely |
| **Glacial** | Archive, rarely accessed | Old project backups, legacy media | Index, label, shelf |

## Device Manifest Format

Each indexed device gets a markdown file with structured frontmatter:

```markdown
---
device_id: "WD-WX1234567890"
serial: "WX1234567890"
label: "catbu-usb-photos"
type: usb | internal | nas | cloud | optical
connection: USB3 | SATA | NVMe | SMB | ZeroTier | HTTPS
location: cf | sl | wf
physical_location: "shelf above CyberTruck"
capacity_gb: 1000
used_gb: 450
free_gb: 550
filesystem: NTFS | ext4 | exFAT | btrfs | cloud
tier: hot | warm | cold | glacial
status: active | archive | unknown | needs-review | failed
role: working | backup-target | seed-media | archive
last_indexed: 2026-05-16
indexed_by: ghadmin@cybertruck
notes: "Old photos and documents from 2018 migration"
---
# Device: catbu-usb-photos

## Summary
- **450 GB used** of 1 TB
- 12,345 files across 234 directories
- Primarily: .jpg (8000), .mp4 (200), .doc (500)

## Top-Level Contents

| Directory | Size | Files | Description |
|-----------|------|-------|-------------|
| /Photos/ | 300 GB | 8000 | Family photos 2010-2018 |
| /Documents/ | 50 GB | 500 | Tax docs, receipts |
| /Video/ | 100 GB | 200 | Home video |

## File Type Summary

| Extension | Count | Size | Notes |
|-----------|-------|------|-------|
| .jpg | 8000 | 280 GB | Photos |
| .mp4 | 200 | 100 GB | Video |
| .doc/.docx | 500 | 2 GB | Documents |
| .pdf | 300 | 5 GB | Scanned docs |

## Actions
- [ ] Review /Documents/ for sensitive data
- [ ] Verify photos are backed up to Google Photos
- [ ] Consider moving to glacial (label and shelf)
```

## Directory Structure (per site repo)

```
<site>/ops/storage-index/
├── README.md                    ← Site-specific overview and device list
├── devices/
│   ├── <device-name>.md         ← One manifest per device/volume
│   └── ...
├── cloud/
│   ├── <service-name>.md        ← Cloud service inventories
│   └── ...
└── scripts/
    ├── index-device.ps1         ← PowerShell: scan and generate manifest
    ├── index-device.sh          ← Bash: scan and generate manifest
    └── generate-summary.ps1     ← Roll up all manifests into overview
```

## Indexing Workflow

### 1. Attach Device

Plug in USB drive, mount NAS share, or identify internal volume.

### 2. Run Index Script

```powershell
# PowerShell (Windows admin workstation)
.\ops\storage-index\scripts\index-device.ps1 -Drive "E:" -Label "old-photos-usb" -Tier cold

# Bash (Linux/WSL)
./ops/storage-index/scripts/index-device.sh /mnt/e "old-photos-usb" cold
```

The script:
- Reads volume serial/label for device_id
- Calculates capacity/used/free
- Walks top-level directories (depth 1-2) for size summary
- Counts files by extension
- Generates the manifest markdown file

### 3. Review and Tag

Open the generated manifest, add:
- `physical_location` (where is this device stored?)
- `notes` (what is this data? whose is it?)
- `status` (active/archive/unknown/needs-review)
- `actions` (what to do with it)

### 4. Commit

```bash
git add ops/storage-index/devices/old-photos-usb.md
git commit -m "Index: old-photos-usb (cold, 450GB photos)"
git push
```

### 5. Detach (if cold/glacial)

Label the physical device with its `label` name. Store it. The index persists in git.

## Remote Storage (ZeroTier-attached)

Remote storage accessed via ZeroTier gets a **shallow index only** — just enough to know what's available for backup targets. The detailed file-level index lives in that node's own site repo.

### Shallow index captures:
- Share names and mount points
- Total capacity / free space
- Designated backup target path
- Whether it's currently online

### Why shallow?
- Crawling remote shares over ZT is slow and unnecessary
- Each node owns its own detailed index
- From a backup perspective, you only need: "can I write to it, and how much space is there?"

### Example shallow manifest:

```markdown
---
label: "sl-backup-target"
type: nas
connection: ZeroTier-SMB
location: sl
zerotier_ip: 10.147.17.94
share: "\\10.147.17.94\slMedia"
backup_path: "/catbu-sl/cf-backup/"
capacity_gb: 1863
free_gb: 800
tier: warm
status: active
role: backup-target
last_checked: 2026-05-16
detail_index: "https://sl.2cld.net/ops/storage-index/"
---
```

## Physical Media UID

Every indexed device records a hardware serial number or volume UUID. This is critical for:

1. **Sneakernet seeding** — Initial backup sync by physically carrying a drive to another node
2. **Tracking which physical media holds what** — "USB drive SN:WX1234 contains the cf→sl seed from 2026-05-16"
3. **Verifying you have the right drive** — Plug in, check serial matches manifest

### How to get the UID:

```powershell
# Windows — disk serial number
Get-Disk | Select Number, FriendlyName, SerialNumber, Size

# Windows — volume serial (for partitions)
Get-Volume | Select DriveLetter, UniqueId, FileSystemLabel
```

```bash
# Linux — disk serial
lsblk -o NAME,SERIAL,SIZE,MODEL

# Linux — filesystem UUID
blkid
```

### Sneakernet Workflow

```
1. ATTACH portable drive to source node (e.g., cf)
2. INDEX it: index-device.ps1 -Drive "E:" -Label "seed-cf-to-sl" -Type usb -Tier cold
3. SYNC backup data to it: robocopy or rsync
4. RECORD in manifest: "seeded from cf, date, contents"
5. PHYSICALLY CARRY to target node (e.g., sl)
6. ATTACH at target, rsync from USB to target backup path
7. DETACH USB, label it, update manifest with "delivered to sl on <date>"
8. FUTURE: incremental rsync over ZeroTier picks up from this baseline
```

The manifest tracks the full lifecycle of the physical media.

## Naming Convention

Device manifest filenames: `<descriptive-name>.md`
- Internal drives: `cybertruck-c.md`, `cybertruck-d.md`
- NAS: `cfbu-synology.md`, `sg-wf-synology.md`
- USB: `usb-wd-1tb-photos.md`, `usb-seagate-2tb-backup.md`
- Cloud: `google-drive-ghadmin.md`, `github-2cld.md`

Use lowercase, hyphens, descriptive names. Include capacity or purpose in the name if helpful.

## Implementation

Each site implements this method:
- [cf storage index](https://cf.2cld.net/ops/storage-index/) — Cedar Falls
- [sl storage index](https://sl.2cld.net/ops/storage-index/) — St. Louis
- [wf storage index](https://wf.2cld.net/ops/storage-index/) — Winfield

## Tools

The index scripts are kept in each site repo under `ops/storage-index/scripts/`. They're adapted from the reference implementation here but customized per-site as needed.

### What the script does NOT do:
- Does not move, copy, or delete any files
- Does not require admin privileges (read-only scan)
- Does not index file contents (just names, sizes, types)
- Does not store sensitive data (no file contents, no credentials)

### What it captures:
- Volume metadata (serial, label, capacity)
- Directory tree (top 2 levels with sizes)
- File extension summary (count and total size per type)
- Timestamp of when indexed
