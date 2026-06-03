[edit](https://github.com/2cld/netstack/edit/master/docs/ops/storage-index/README.md)
# Storage and Asset Indexing Method

A federation-wide approach to inventorying, tagging, and managing **storage and physical assets** across all 2cld sites.

## Problem

Data is scattered across multiple locations, device types, and services with no single inventory. USB drives accumulate without labels. NAS devices hold unknown data. Cloud storage is untracked. Physical equipment (servers, monitors, tools, furniture) piles up with no record of what's there, what works, or what's worth keeping.

## Principles

1. **Index first, organize later** - Don't move anything until you know what you have
2. **Metadata is cheap** - The index lives in git, costs nothing
3. **Offline drives get indexed when attached** - Plug in, scan, unplug, index persists
4. **Physical assets get indexed when inspected** - Look at it, write manifest, label it
5. **Tiers drive decisions** - Tag everything, then decide what to keep/move/delete/sell
6. **Federation-aware** - Each site indexes its own assets, netstack holds the method
7. **One manifest per item** - Whether it's a hard drive or a rack server, same pattern

## Tiers (applies to both data and physical assets)

| Tier | Access Pattern | Data Examples | Physical Examples |
|------|---------------|--------------|-------------------|
| **Hot** | Always online/in use | Internal drives, local NAS | Daily-use workstation, active tools |
| **Warm** | Available but not daily | ZeroTier shares, cloud | Spare monitor, seasonal equipment |
| **Cold** | Offline, access when needed | USB drives, spare disks | Stored server (working), boxed parts |
| **Glacial** | Archive, rarely accessed | Old backups, legacy media | Legacy hardware (parts only), archive boxes |
| **Dispose** | No future value | Wiped/corrupt drives | Broken beyond repair, obsolete, scrap |

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

## Physical Asset Manifest Format

Non-storage physical assets (servers, monitors, tools, furniture) use the same manifest pattern:

```markdown
---
asset_id: "dell-r720-001"
label: "2U Dell R720 blade server"
type: server | workstation | monitor | rack | networking | tool | furniture | other
make: "Dell"
model: "PowerEdge R720"
serial: "ABC123XYZ"
location: wf-shop | wf-shed | wf-house | cf-basement | cf-garage | sl-garage
physical_location: "wf shop, south wall rack"
condition: working | needs-repair | parts-only | unknown | dispose
power: "tested-ok | untested | dead | n/a"
value_estimate: "$200"
tier: hot | warm | cold | glacial | dispose
status: active | stored | needs-review | listed-for-sale | disposed
last_inspected: 2026-06-03
inspected_by: christrees
notes: "Pulled from old datacenter. 2x Xeon E5-2670, 64GB RAM. Needs rails."
---
# Asset: 2U Dell R720 blade server

## Specs
- CPU: 2x Xeon E5-2670
- RAM: 64 GB
- Storage: 8x 2.5" bays (empty)
- Network: 4x 1GbE
- Power: dual PSU

## Triage Decision
- [ ] Power on and test
- [ ] Determine use case (Proxmox node? parts?)
- [ ] Assign to project or list for sale

## History
- 2026-06-03: Found in wf shop, inspected, manifest created
```

### Physical Asset Types

| Type | Examples | Key Fields |
|------|----------|------------|
| server | rack servers, blades, NAS chassis | CPU, RAM, drive bays, power test |
| workstation | PCs, laptops, SBCs | CPU, RAM, OS, boot status |
| monitor | displays, TVs | size, resolution, inputs, working? |
| rack | server racks, shelving, enclosures | size (U), capacity, condition |
| networking | switches, routers, APs, cables | ports, speed, managed?, PoE? |
| tool | press, welder, power tools | working?, repair needed? |
| furniture | desks, chairs, workbenches | condition, dimensions, reuse plan |
| other | misc electronics, cables, adapters | description, quantity |

### Triage Workflow (physical assets)

```
1. INSPECT  - look at it, note condition
2. INDEX    - create manifest (even minimal: type, location, condition)
3. DECIDE   - keep (assign tier) | repair | sell | dispose
4. LABEL    - write manifest label on item (tape/marker)
5. PLACE    - store in designated location matching manifest
6. RETRIEVE - search manifests, find item by label/location
```

## Directory Structure (per site repo)

```
<site>/ops/storage-index/
├── README.md                    <- Site-specific overview and inventory
├── devices/
│   ├── <device-name>.md         <- One manifest per storage device/volume
│   └── ...
├── assets/
│   ├── <asset-name>.md          <- One manifest per physical asset
│   └── ...
├── cloud/
│   ├── <service-name>.md        <- Cloud service inventories
│   └── ...
└── scripts/
    ├── index-device.ps1         <- PowerShell: scan and generate manifest
    ├── index-device.sh          <- Bash: scan and generate manifest
    └── generate-summary.ps1     <- Roll up all manifests into overview
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

### 4.5 Breadcrumb (digital receipt on device)

Write `cat9-asset-tag.txt` to the root of the device filesystem:

```bash
# Get the commit hash
HASH=$(git log -1 --format=%H ops/storage-index/devices/old-photos-usb.md)

# Write breadcrumb to device
cat > /mnt/device/cat9-asset-tag.txt << EOF
Asset: old-photos-usb
Indexed: $(date +%Y-%m-%d)
Manifest: https://github.com/2cld/<site>/blob/$HASH/ops/storage-index/devices/old-photos-usb.md
Repo: https://github.com/2cld/<site>
Pattern: https://netstack.org/docs/ops/storage-index/
EOF
```

This survives even if the physical label falls off. Find the drive in 5 years, open `cat9-asset-tag.txt`, click the link - full context.

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
zerotier_ip: <overlay-ip>
share: "\\<overlay-ip>\sharename"
backup_path: "/backup/cf/"
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
