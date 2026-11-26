# Process: site media storage (inventory, library map, classify, copies, config sync)

**Applies to:** every site that holds media or other data it cannot easily recreate, and runs a media service (Plex or similar).
**Issue:** [netstack#51](https://github.com/2cld/netstack/issues/51). **First run:** sl, 2026-11-23 to 2026-11-26 (sl#13, sl#22, sl#23).
**Builds on:** [storage-index README](./README.md) (device manifests, tiers), [media-service-pattern](../backup/media-service-pattern.md) (classes, service doc), [media-validation-pattern](../backup/media-validation-pattern.md) (compare before wiping). This page adds the missing joins and the loop that runs them.

## The loop

Seven steps, one artifact each. A site runs it once to start, then again whenever a disk, a library or a config changes, and at least every 30 days.

| # | Step | Artifact (in the site repo) | Who decides |
|---|------|-----------------------------|-------------|
| 1 | Inventory drives and volumes, with health | `docs/storage-map.md` and `site-config.yml` `storage_index`; health file feeds the status checker | Facts, not a decision |
| 2 | Map each media library to a folder and an owner | Library map table in `docs/storage-map.md` | Facts, from the app's settings |
| 3 | Classify each library and folder | `docs/library-classification.md` (worksheet) | **The owner** |
| 4 | Count verified copies against what the class needs | Copies table per collection (format below) | Rule, applied to facts |
| 5 | Decide and act on each gap | Second copy, or "not backed up, by design" | **The owner** |
| 6 | Sync the config with steps 1 and 2 | `site-config.yml` `storage`, `storage_index`, Plex paths | Check, then fix |
| 7 | Re-run | Dates in the artifacts; stale flag after 30 days | Schedule |

Inventory is not allocation ([storage-index principle 8](./README.md)): finding free space does not give anyone the right to use it.

## Step 1: Inventory, with health

Per drive: serial, model, bus, size, free space, power-on hours, role, tier, backup status (the existing [device manifest](./README.md#device-manifest-format) fields). Add health:

| Field | Source on Windows | Source on Linux |
|-------|-------------------|-----------------|
| Health and operational status | `Get-PhysicalDisk` (`HealthStatus`, `OperationalStatus`) | `smartctl -H` |
| Read errors | `Get-StorageReliabilityCounter` (`ReadErrorsTotal`) | `smartctl -A` (`Raw_Read_Error_Rate`, `Reallocated_Sector_Ct`, `Current_Pending_Sector`) |
| Power-on hours, temperature | same counter | `smartctl -A` |
| Free space per volume | `Get-Volume` | `df` |

**Limit, stated plainly:** the Windows counters do **not** show reallocated or pending sectors. "Healthy" on Windows is weaker than a SMART check. The sl disk that failed (`Z1F16T1K`) failed without warning. Record which source a site has.

**Thresholds** (from sl, adjust per site):
- **Fail:** health not Healthy, operational status not OK, read errors above the recorded baseline, or the health file older than 25 hours (no data is not a pass).
- **Warn:** free space under 10 percent (15 percent on the OS drive).
- **Baseline:** write each disk's current read-error count as the baseline the first time. A disk with 1 old error stays a pass at 1 and fails at 2.

**How it gets to the status page without credentials in the checker:** a read-only script on the host writes a small text file; the checker mounts it read-only and runs `command` checks against it. sl: `ops/monitor/disk-health.ps1` writes `C:\ProgramData\sl-ops\disk-health.txt` from a scheduled task; six checks in `checks.yml` read it. See sl `ops/monitor/README.md`. Run host scripts by copying a `.ps1` over SSH ([windows-openssh-setup](../backup/windows-openssh-setup.md)).

## Step 2: Library map

For every media service, a table filled in from the app's settings (not its database):

| Library | Type | Folder | Owner | Class (from step 3) |
|---------|------|--------|-------|---------------------|

Plex: Settings, Manage, Libraries, or the library list from its API. Add one line per folder on the disk that **no** library points at (sl found `HDHomeRun`, `slShareE` and `rawClips`: about 380 GB, none in Plex). Those are the folders most likely to be forgotten.

## Step 3: Classify

One worksheet per site: a row per library or folder with files, size, file date range, owner, a **proposed** class and the reason, any lead on another site's copy, and one question for the owner. Measure read-only (file count, total size, oldest and newest file date per folder).

Classes ([media-service-pattern](../backup/media-service-pattern.md)):

| Class | Meaning | Copies needed |
|-------|---------|---------------|
| Irreplaceable | No source to recreate it from | 3 copies, 2 locations, 1 offline |
| Replaceable-costly | A physical source exists (discs, tapes, CDs) or a lot of curation work | 2 copies |
| Replaceable-easy | Can be re-downloaded or re-recorded | 1 copy, "not backed up, by design" |

Rules:
- **When unsure, irreplaceable until the owner says otherwise.** Names and dates suggest a class; they do not decide it.
- The owner answers the questions. Wip proposes, never confirms.
- "Re-record" only counts if the way to record still exists. A DVR with no tuner is not a source.
- A curated version is its own cost. Raw disc rips on another site are a lead, not a copy of the curated library.

## Step 4: Copies

One manifest per collection (the format wf proved in wf#39). A collection can be a library, a folder or a set of drives:

```yaml
---
collection_id: <name>
name: "<readable name>"
class: irreplaceable | replaceable-costly | replaceable-easy
required_copies: 2
required_offsite: 1
owner: <who decides>
backup_policy: "3 copies, 2 locations, 1 offline"
last_reviewed: 2026-11-24
copies:
  - id: 1
    site: wf
    device: "<device and serial>"
    path: "<path>"
    status: confirmed | indexed | reported | candidate
    verified: 2026-11-24
    verified_by: "<how: file count and size, name list, content compare>"
    files: 18087
    size_gb: 34
    offsite: false
---
```

**Counting rule** (wf#40): a copy counts toward `required_copies` only if it is `confirmed` and was verified in the last 30 days. `indexed`, `reported` and `candidate` copies never count. A confirmed copy not verified in 30 days is stale and does not count. Wip's `collection-check.js` applies this rule and flags irreplaceable collections below the minimum or with no off-site copy.

Finding copies: compare file names and sizes read-only against the other site's index or filesystem ([media-validation-pattern](../backup/media-validation-pattern.md)). Record the method in `verified_by`. Name and size match is `confirmed` for replaceable classes; content compare is wanted for irreplaceable ones.

## Step 5: Decide and act

For each row below its required copies:
- **Make a second copy** at another site (or an offline drive for the third), record it in the manifest with date and serial.
- **Or record "not backed up, by design"** with the reason, and the owner's name.
- Never use the off-site backup receiver's space for a media copy without a decision ([federation-backup-plan](../backup/federation-backup-plan.md)): that space is the other site's disaster recovery.
- Before wiping any drive, run the compare in media-validation-pattern.

## Step 6: Config sync

`site-config.yml` is what the site generators and Wip read, so it must match the disk. Check these by hand for now:
1. Every folder under the media root appears in `storage_index` (or is listed as ignored on purpose).
2. Every path in the media service's `storage` block exists on the disk and matches the library map.
3. No `reproducible: true` unless the class in step 3 says replaceable. Use `unknown` until classified.
4. Retired hardware is marked `known_down` with an issue, and its paths are not listed as live (sl: DVR and tuner, sl#33).
5. The machine model and drive serials are the real ones (sl's config said "Dell 1U / TBD" for an Inspiron 3847).

sl found drift in every one of these on 2026-11-23: a layout (`{DVR,Movies,TV,Music}`) that never existed, `reproducible: true` on unclassified libraries, a wrong model, and a `docs/storage.md` that described cf. A scripted check is not built; open item below.

## Step 7: Re-run

- Re-run step 1 after any disk change, and every 30 days. The health file's age is itself checked (25 hours).
- Re-run steps 2 and 6 when a library or path changes.
- Wip's roll-up ([wip#151](https://github.com/2cld/wip/issues/151)) reads each site's own record and `status.json`, flags rows older than 30 days, and lists failed or unknown drives by serial. `storage-status.js` already reads sl's free space and disk health from `status.json` (wip#153).

## Worked example: sl

| Step | What sl produced | Where |
|------|------------------|-------|
| 1 | Three disks with serial, age, health; failed `Z1F16T1K` listed as offline; six health and space checks live on the status page | sl `docs/storage-map.md`, `ops/monitor/disk-health.ps1`, `checks.yml` |
| 2 | 10 Plex libraries mapped to folders; three non-Plex folders found (about 380 GB) | sl `docs/storage-map.md` |
| 3 | Worksheet: 10 libraries and 3 folders, proposed classes, 13 owner questions. Three rows start as irreplaceable until told (`gusCuts`, `gusVHSProject`, `rawClips`). | sl `docs/library-classification.md` (sl#22) |
| 4 | Not yet. Leads only: wf synology holds `gusMovies`, raw `gusHorrorClassic100`, a small part of `gusShows` and `gusMusic`, likely `catRip` | wf `collections.md` |
| 5 | Waiting on the owners' answers | sl#22 |
| 6 | `site-config.yml` rewritten to the real folders; DVR marked `known_down` | sl PR #32, sl#33 |
| 7 | Health file refreshed daily at 04:00 by a scheduled task | sl `ops/monitor/README.md` |

Time cost, roughly: inventory 1 session, library map 10 minutes once the list was pasted, worksheet about an hour including the size scan (a 1.1 TB disk takes several minutes to scan), config sync 1 hour.

## Open items

- A script that does step 6 (compare `site-config.yml` with the disk and the library map) and runs on the Wip cron.
- Extend `collection-check.js` to read library and folder manifests, not only the five wf collections.
- A Linux health source (`smartctl`) written up the same way as the Windows one, for cf and wf.
- Whether the status checker should publish a storage block so Wip does not parse check names.
- A shared worksheet and library-map template in `site-template`.

## Related

[storage-index README](./README.md) · [glacial-archive-pattern](./glacial-archive-pattern.md) · [media-service-pattern](../backup/media-service-pattern.md) · [media-validation-pattern](../backup/media-validation-pattern.md) · [federation-backup-plan](../backup/federation-backup-plan.md) · [windows-host-boot-recovery-pattern](../deployments/windows-host-boot-recovery-pattern.md) · wip#151, wip#152, wip#153 · wf#38, wf#39, wf#40
