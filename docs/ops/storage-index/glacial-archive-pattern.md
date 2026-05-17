[edit](https://github.com/2cld/netstack/edit/master/docs/ops/storage-index/glacial-archive-pattern.md)
# Glacial Archive Pattern

How to safely move data from hot/working storage to cold/glacial archive across the 2cld federation.

## Core Rule

**Never delete the only copy.** Before removing anything from its current location, it must exist in at least one other verified location.

## Archive Lifecycle

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  1. WORKING │────►│  2. STAGED  │────►│ 3. ARCHIVED │────►│ 4. VERIFIED │
│  (on C:)    │     │  (on D:)    │     │  (on cfbu)  │     │  (delete    │
│             │     │  bootable   │     │  cold copy  │     │   source)   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Stage 1: WORKING
- Data is on fast/primary storage (e.g., C: NVMe)
- Actively used or recently used
- Tagged in index as `tier: hot` or `tier: warm`

### Stage 2: STAGED
- Copied to secondary local storage (e.g., D: SATA)
- Still accessible, still bootable (for VMs)
- Source on C: still exists (two copies now)
- Tagged in index as `tier: cold`, `status: staged`

### Stage 3: ARCHIVED
- Copied to archive storage (e.g., cfbu NAS, USB drive)
- Now exists in 3 places: C: (source), D: (staged), cfbu (archived)
- Verified: file sizes match, checksums if critical
- Tagged in index as `tier: glacial`, `status: archived`

### Stage 4: VERIFIED & CLEANED
- Source deleted from C: (space recovered)
- Data lives on D: (accessible) and cfbu (backup)
- Index updated with final locations and deletion date
- Tagged as `status: archived`, locations documented

## What Gets Tagged in the Manifest

Every glacial archive manifest must record:

```yaml
---
tier: glacial
status: archived
role: archive
archive_date: 2026-05-17
archived_by: ghadmin@CYBERTRUCK
archived_from: "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\"
archive_locations:
  - path: "D:\vmhv\archive\WTTC-LeeVM\"
    device: cybertruck-d
    verified: true
    bootable: true
  - path: "\\192.168.10.2\bg\archive\WTTC-LeeVM\"
    device: cfbu-bg
    verified: true
    bootable: false (needs copy back to import)
source_deleted: true
source_deleted_date: 2026-05-17
notes: "Laptop recovery VM, Windows 95 era program. Export includes saved state."
recovery_instructions: |
  To restore: copy from D:\vmhv\archive\WTTC-LeeVM\ or cfbu,
  then Import-VM -Path "D:\vmhv\archive\WTTC-LeeVM\..."
---
```

## Federation Verification

Each node should be able to confirm its backups exist on the other nodes:

```
CF node checks:
  - "My glacial archives on local NAS?" → ls <nas-path>/archive/
  - "My offsite backups on sl?" → ssh <sl-overlay-ip> ls /backup/cf/
  - "My offsite backups on wf?" → ssh <wf-overlay-ip> ls /volume1/backup/cf/

SL node checks:
  - "My offsite backups on cf?" → ssh <cf-overlay-ip> ls /backup/sl/
  - "My offsite backups on wf?" → ssh <wf-overlay-ip> ls /volume1/backup/sl/

WF node checks:
  - "My offsite backups on sl?" → ssh <sl-overlay-ip> ls /backup/wf/
  - "My offsite backups on cf?" → ssh <cf-overlay-ip> ls /backup/wf/
```

## Offline / Glacial Storage

For data that goes to USB drives or gets shelved:

1. **Physical label**: Write the manifest `label` name on the drive with a marker
2. **Index persists**: The manifest stays in git even after the drive is disconnected
3. **Serial number**: The `serial` field in the manifest uniquely identifies the physical media
4. **Location tracking**: `physical_location` field says where the drive is stored

Example: "USB drive labeled `seed-cf-to-sl`, serial WX1234, on shelf above CyberTruck"

## Pattern Summary

| Question | Answer |
|----------|--------|
| Where is it now? | Check `archive_locations` in the manifest |
| Can I boot it? | Check `bootable` flag per location |
| Is it safe to delete the source? | Only if `verified: true` on at least one archive location |
| How do I get it back? | Follow `recovery_instructions` in the manifest |
| Which physical drive is it on? | Check `serial` field, match to physical label |
| Does my backup exist on the remote node? | Run federation verification check |

## Reference

- Storage indexing method: [netstack.org/docs/ops/storage-index](https://netstack.org/docs/ops/storage-index/)
- Federation backup plan: [netstack.org/docs/ops/backup/federation-backup-plan](https://netstack.org/docs/ops/backup/federation-backup-plan/)
- Site implementations: [cf](https://cf.2cld.net/ops/storage-index/), [sl](https://sl.2cld.net/ops/storage-index/), [wf](https://wf.2cld.net/ops/storage-index/)
