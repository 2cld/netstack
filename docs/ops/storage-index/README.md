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
6. **Federation-aware** - Each site publishes its own index, allocations, and fresh status; Wip rolls up and coordinates resource requests; netstack holds the method
7. **One manifest per item** - Whether it's a hard drive or a rack server, same pattern
8. **Inventory is not allocation** - An indexed device or free-space measurement is not permission to use, reclaim, or promise its capacity

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

This is a reference layout, not a requirement to move existing inventories.
Each site's `.wip-contract.md` links its canonical index, allocation register, and
read-only status source, including access requirements. Keep those links current
when paths change; Wip follows the site's references rather than inventing a
second authoritative inventory.

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
Serial: WX1234567890
Size: 1000 GB
Free: 550 GB
Status: cold (indexed, labeled, shelved)
Attached: devwin10 (10.147.17.165)
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

## Federation storage services and resource requests

**Adoption status:** this defines the publication and coordination contract.
It does not claim that sites already publish these records, that Wip reconciles
them, or that a provisioning API exists. Site adoption and any new checks require
owner approval; this document does not grant filesystem or administrative access.

The content index answers **"where is my stuff?"** A storage-service catalog
answers **"what capacity can a site commit, on what terms?"** Link these views
using stable IDs; do not treat an old scan or an offline archive as an available
storage offer.

### Ownership and publication

| Owner | Publishes / maintains | Authority |
|-------|----------------------|-----------|
| Netstack | Shared method, required evidence, request lifecycle | Defines the pattern, not site-specific capacity or allocations |
| Each site | Canonical inventory, storage offers, allocation register, fresh local observations, operator and escalation references | Accepts or rejects requests; owns reservations, provisioning, access and release |
| Requesting site | Service/data scope, required capacity and availability, consumer-side verification | Accepts the offered terms and owns its use of the allocation |
| Wip | Attributed federation rollup, linked requests/decisions, reconciled status and follow-up | Coordinates between sites; does not grant another site's capacity, credentials, or deletion permission |

Each serving site publishes three linked kinds of evidence:

| Record | Required information |
|--------|----------------------|
| Index / storage offer | Stable site, asset and storage IDs; backing device/pool/volume; owner; purpose/tier; access method; availability schedule; persistence/rebuild procedure; allocation constraints |
| Allocation register | Stable request/allocation IDs; consumer site/service; backing storage ID; approved amount and terms; reservation/usage accounting; lifecycle state; approval and operator evidence; retention, expiry/review, release and deletion authority |
| Fresh status | Storage/allocation IDs; observation time and collection result; measured capacity, usage and free space; outstanding reservations and safety reserve; site-calculated allocatable amount; relevant mount, access, capacity and availability results |

For persistent service storage, trace the backing chain: physical/cloud storage
to filesystem/dataset, host/LXC mount, and consuming service. Identify what
survives container/host rebuilds and what must be restored. An LXC root disk, a
live workstation, and a dedicated backup volume are different resources even if
they are at the same site.

Account for existing commitments, growth, retention, staging and safety reserve.
Document units and how reservations are counted, so already-used allocated space
is not subtracted twice. Offers sharing a backing pool share a reservation
budget; Wip must not sum the same capacity twice. Raw `free_gb` is not allocatable
capacity. The serving site rechecks capacity and serializes reservation decisions
to prevent competing requests from overcommitting the same storage.

### Hardware identity and independent backup placement

A reusable BMDR hardware profile is not an inventory of available machines.
Keep one asset record per physical chassis, linked to the fleet/profile and its
current role. Record stable asset ID, verified make/model and chassis serial,
physical location, installed CPU/RAM/controllers/NICs, boot/virtualization
capabilities, condition, test evidence and inspection time. Record variations
between units; do not copy an unverified model or capability to the whole fleet.
Hostnames, VM IDs and service names refer to deployments, not chassis identities.

Identify each physical drive by its asset ID and hardware serial/WWN as exposed
by the physical host, enclosure or storage controller. Link its current bay and
chassis/enclosure, capacity and pool/array membership. Device names such as
`/dev/sda` and drive letters are local observations, not persistent identity.
Filesystem UUIDs and guest-presented disk serials are useful cross-references,
but can be cloned or virtualized; they do not prove physical drive identity.

For each service source and backup target, publish the applicable backing links:

```text
service / backup allocation
  -> filesystem / dataset / container bind or volume
  -> guest virtual disk or mount
  -> hypervisor image / logical volume / passthrough device
  -> storage pool / RAID / LUN / NAS backend
  -> physical member drives
  -> enclosure / controller / chassis / site
```

Skip layers that do not apply, but do not stop at a VM disk or an exported share.
Include every backing member of mirrored, striped, parity and thin-provisioned
storage, and shared metadata/cache devices on which the allocation depends.
Use stable, owner-scoped IDs and links so aliases on different guests resolve
to the same backing resource. Record observer, observation time and unresolved
layers. A VM collector reports what it sees; the hypervisor/storage owner
supplies the underlying mapping. This does not grant guest agents host access.

Before accepting a backup placement, compare source and target backing evidence:

| Finding | Permitted claim |
|---------|-----------------|
| Overlapping physical drives, or the same backing pool/array exposed through different paths, VMs or shares | Shared storage; not an independent physical backup copy |
| Separate physical drives but shared controller, enclosure, chassis or site | Drive separation only; explicitly retain the shared failure domains |
| Verified separation at every level required by the accepted recovery terms | Independent at those named levels, not a blanket DR guarantee |
| Missing, stale, conflicting or guest-only backing evidence | Independence unverified; do not assume different names mean different hardware |

Report drive, pool/array, chassis and site separation separately. Two VMs on one
server can lose both copies with that server; two servers using the same NAS can
lose both copies with that NAS. RAID redundancy and snapshots within a pool are
not independent backup copies. Independent backup receipts and successful
restores do not, on their own, prove independent physical placement.

For externally managed storage, obtain the backing/failure-domain evidence from
its owner. If the required separation cannot be established, retain that gap
instead of inventing physical IDs or declaring independence. Keep detailed
hardware identifiers and topology protected; Wip reconciles approved reports
without requiring direct access to every drive.

### Freshness, availability and visibility

Agree observation cadence, maximum evidence age and escalation per storage
service. Report the source's observation time separately from Wip's retrieval
time; rebuilding a dashboard does not refresh a disk measurement. Missing,
expired or failed observations are unknown/stale or failed, not healthy capacity.

Distinguish always-on, scheduled/wake-on-demand, offline and failed storage.
Scheduled availability includes the agreed access window and activation owner.
A device tier is not an availability guarantee. A reachable site endpoint or a
healthy host boot disk is not proof that the allocated volume is mounted,
accessible or within its capacity terms.

Wip retains source IDs, timestamps and links in its rollup, and separates local
storage evidence from coordinator visibility. A mismatch between an approved
allocation and observed use needs follow-up, not a silent rewrite of the site's
record. Missing Wip visibility must not stop existing storage use or backup jobs;
do not make peer aggregate health recursively depend on Wip's aggregate health.

Publish only approved, sanitized summaries. Detailed file inventories, internal
paths, identities and client allocations remain in access-controlled operational
records; credentials and customer contents do not belong in the rollup. This
pattern does not change the existing
[public status schema](../monitor/public-status-endpoint-pattern.md).

### Cross-site request lifecycle

Use the owning repos' linked issues and records before adding automation:

1. **Request:** the consumer records a stable request ID, service/data scope,
   capacity estimate and growth, purpose, availability/access needs, persistence
   and DR requirements, timing, and responsible owner. Wip routes it to candidate
   sites using their current published offers and evidence.
2. **Agree:** the serving and requesting owners accept the amount, schedule,
   access scope, retention, recovery terms, monitoring, costs if applicable, and
   release/deletion authority. Pending or rejected requests are not allocations;
   Wip records the decision rather than choosing unspecified terms.
3. **Reserve:** the serving site checks current capacity, records the approved
   allocation and updates its remaining offer. Reprocessing the same request ID
   must not create another reservation. Record reservation expiry/review terms;
   expiry alone never authorizes deleting stored data.
4. **Provision and verify:** the authorized site operator provisions storage and
   least-privilege access using the site runbook. The consumer verifies the agreed
   attachment/access and the serving site publishes its evidence. A failed
   provision stays failed/pending with an operator-owned rollback or cleanup
   task, not an active allocation or silently abandoned reservation.
5. **Use and monitor:** publish fresh allocation-specific evidence and capacity
   pressure. Wip reconciles both sites' reports and routes exceptions. Changes in
   size, scope, receiver or access terms require an updated accepted allocation.
6. **Release:** the owners approve migration/retention/disposal steps, verify
   required alternate copies, revoke access and record the disposition. The
   serving site closes the allocation and returns only verified released capacity
   to its offer. Wip records closure; it does not wipe, prune or reclaim data.

Owner approval, reservation, provisioned access and operational verification are
separate claims. A request accepted in an issue is not proof that storage exists;
a mounted directory is not proof of agreed persistence or disaster recovery.

### Adoption proof

Before calling a site's storage offer operational:

1. Publish contract links and matching inventory/allocation/status IDs, with
   accepted terms, owners and freshness policy.
2. Demonstrate one owner-approved request through reservation, provisioning,
   consumer verification and attributed Wip reconciliation.
3. Demonstrate stale/missing evidence, unavailable backing storage, capacity
   pressure, duplicate requests and failed provisioning without false success
   or double allocation. Demonstrate that two guest targets sharing physical
   backing are detected as shared, and unresolved backing stays unverified.
4. Verify the agreed rebuild/reattachment or restore procedure. Exercise release
   only with an approved test allocation and disposal plan, preserving live data.
5. Record dates, commands, results, unresolved gaps and operator ownership in the
   site issue. Until then, report adoption as pending/partial, not implemented.

For offsite backup storage, this lifecycle supplies receiver allocation and
availability evidence to the
[service-data backup/restore contract](../backup/service-data-backup-restore-pattern.md#service-contracts-client-provider-receiver-coordinator).
It does not replace independent backup receipt, integrity checks or an isolated
application restore. A service client still contracts with its provider for the
recovery outcome; it need not administer the provider's storage peer.

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
- [wf storage index](https://github.com/2cld/wf/tree/main/ops/storage) — Winfield

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
