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

## Cross-Site Summary

Netstack maintains a federation-wide view at `docs/ops/storage-index/federation.md` that links to each site's index. Updated periodically by pulling summaries from each site.

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
