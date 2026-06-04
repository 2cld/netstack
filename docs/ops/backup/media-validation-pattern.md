# Media Storage Validation Pattern

**Applies to:** Verifying that media backup drives contain duplicate data that already exists on the primary storage, enabling safe drive recovery/reuse.

## Problem

Media accumulates on multiple drives over time. Before wiping a drive to reclaim it, you need to confirm its contents already exist elsewhere. Without a procedure, drives pile up because "I'm not sure if this is the only copy."

## Principle

**Never wipe the only copy.** Validate before retiring. Per [service-lifecycle-pattern](../tools/service-lifecycle-pattern.md): the gate must pass before the old is archived.

## Validation Flow

```
1. IDENTIFY   - What media is on the backup drive? (manifest, scan)
2. LOCATE     - Where is the primary copy? (ZFS pool, NAS, another drive)
3. COMPARE    - Does primary contain everything on the backup? (script)
4. DOCUMENT   - Record the comparison result in the manifest
5. DECIDE     - Wipe (primary confirmed) or Keep (unique data found)
```

## Step 1: IDENTIFY (what's on the backup drive?)

From the drive manifest (storage-index), you already know:
- Drive label + serial
- Top-level folder structure
- File type summary
- Total size

If not scanned yet: run `index-device.ps1` (or equivalent) first.

## Step 2: LOCATE (where is the primary?)

Check the site's storage-index for the primary media location:
- ZFS pool dataset (e.g., MediaVolume/Media)
- NAS share
- Another indexed drive

The primary is the **always-on, monitored, backed-up** copy. Backup drives are the redundant copies.

## Step 3: COMPARE (does primary contain the backup's data?)

### Method A: Directory listing compare (quick, approximate)

```bash
# Generate sorted file lists from both locations
# On primary (e.g., cg2):
find /MediaVolume/Media -type f | sort > /tmp/primary-files.txt

# On backup drive (mounted):
find /mnt/backup-drive -type f | sort > /tmp/backup-files.txt

# Compare (files on backup NOT on primary):
comm -23 /tmp/backup-files.txt /tmp/primary-files.txt > /tmp/unique-to-backup.txt

# If unique-to-backup.txt is empty: backup is fully duplicated
# If not empty: review the unique files before wiping
```

### Method B: Size-based compare (faster, less precise)

```bash
# Compare directory sizes at top level
# Shows if overall volumes match
du -sh /MediaVolume/Media/*/ | sort > /tmp/primary-sizes.txt
du -sh /mnt/backup-drive/*/ | sort > /tmp/backup-sizes.txt
diff /tmp/primary-sizes.txt /tmp/backup-sizes.txt
```

### Method C: Checksum compare (slow, precise - for critical data only)

```bash
# Only use for small datasets or critical files
find /mnt/backup-drive -type f -exec md5sum {} \; | sort > /tmp/backup-checksums.txt
# Compare against primary checksums
```

### Windows equivalent (PowerShell)

```powershell
# List files on backup drive
Get-ChildItem E:\ -Recurse -File | Select FullName,Length | Export-Csv backup-files.csv

# List files on primary (via SSH to ZFS host)
ssh root@192.168.9.3 "find /MediaVolume/Media -type f -printf '%p,%s\n'" > primary-files.csv

# Compare in Excel/script - look for files in backup not in primary
```

## Step 4: DOCUMENT

Update the backup drive's manifest with comparison result:

```yaml
status: validated-duplicate  # or: contains-unique-data
validated_against: "cg2 MediaVolume/Media (bs3)"
validation_date: 2026-06-04
validation_method: "directory listing compare"
unique_files_found: 0  # or count
notes: "All content confirmed present on cg2. Safe to wipe."
```

## Step 5: DECIDE

| Result | Action |
|--------|--------|
| All duplicate | Wipe drive, update manifest to `status: wiped-reusable` |
| Some unique files | Copy unique files to primary first, then wipe |
| Mostly unique | Keep the drive (it IS a backup, or promote to primary) |

## Site Implementation

Each site creates a validation script tailored to their storage layout:

```
<site>/ops/scripts/validate-media.sh
```

The script:
1. Reads the manifest to know what's on the drive
2. Compares against the primary (per site storage-index)
3. Outputs results to a file in storage-index/
4. References this pattern for the procedure

## Related

- [storage-index](../storage-index/) - asset manifests + device scans
- [service-lifecycle-pattern](../tools/service-lifecycle-pattern.md) - retirement gate
- [glacial-archive-pattern](../storage-index/glacial-archive-pattern.md) - archiving after validation
- [federation-backup-plan](./federation-backup-plan.md) - where primary copies live
