# storage-index tools (index v0.1.1, collector v0.2.1)

Two scripts that do the same job, one for Windows (`storage-index.ps1`) and one for Linux and WSL (`storage-index.sh`). They index a storage device, keep a local index, and **only when asked** leave three small breadcrumb files on the device. Part of [netstack#57](https://github.com/2cld/netstack/issues/57); the process around them is in [media-storage-process](../media-storage-process.md).

**Who runs them:** the site-ops human or agent of the site where the drive is attached (`wip/<site-ops>`). The coordinator (`wip/chris`) reads the results and asks for more detail. It does not run these on a site's machines.

## What they do
1. **Identify** the device: serial, model, label, filesystem, size.
2. **Scan safely** to the level you ask for (default L1). Symlinks, junctions and other filesystems are never followed. Depth cap 64. Time cap 25 minutes per top-level folder. Every skipped folder is counted by reason (access, links, depth) and a cut-off scan says `truncated`. If any folder was not read for access or depth, the tool prints `WARNING INCOMPLETE` and the collector flags the device `INCOMPLETE`.
3. **Write a local index** in `<out>/<serial>/<date>/`: `L0.csv`, `L1.csv`, optional `L2.csv`, `cat9-contents.txt`, `summary.json`, plus a line in `<out>/custody.csv`.
4. **Check drift** if the drive already carries a `cat9-contents.txt`: checksum, serial, then top-level folders added, removed or changed.
5. **Leave breadcrumbs on the drive** only with `--write-breadcrumb` / `-WriteBreadcrumb`, after showing exactly what will be written and asking you to type `YES`.

They never write to the drive in any other case. Hidden and system files are included in every count. Sizes are bytes in the files and GiB (2^30) in the text.

## Levels
| Level | Records | Output |
|-------|---------|--------|
| L0 | Top-level folders and files: files, bytes, oldest and newest file date | `L0.csv` |
| L1 (default) | Adds the children of each top-level folder (the second level) | `L1.csv` |
| L2 | Adds one row per file: path, bytes, modified date | `L2.csv` |

L3 (quick hash) and L4 (full hash) are not in v0.1.0. The format already has room for them.

## Files written to the drive (root only)
| File | Behaviour | Content |
|------|-----------|---------|
| `cat9-asset-tag.txt` | Replaced | Short breadcrumb: asset, serial, model, who wrote it and when, "dated snapshot, not live", manifest pointer, last seen |
| `cat9-contents.txt` | Replaced | The drive's own L0 and L1 index with a checksum (format below) |
| `cat9-history.txt` | One line appended per write | Date, site, host, level, files, bytes, tool, drift result: a visit log that travels with the drive |

The three files are excluded from the scan, so writing them does not cause drift.

### `cat9-contents.txt` format (`cat9-contents/1`)
```
cat9-contents/1
# This file describes the drive as of 'scanned'. It is a snapshot, not live. A fresh scan outranks it.
serial: NA5KDK82
model: Seagate Backup+ Desk
label: CATOP
size_gib: 3726.0
filesystem: NTFS
unit: GiB (1 GiB = 2^30 bytes)
hidden_files_included: yes
level: L1
scanned: 2026-11-27T10:15:00-06:00
site: sl
host: SLWIN11OPS
tool: storage-index.ps1 0.1.0
files_total: 28060
bytes_total: 1102548807211
skipped: 0
skipped_detail: access 0, links 0, depth 0
truncated: no
index_ref: <where the full index lives>
[L0] name|kind|files|bytes|oldest|newest|skipped|truncated
bs4scan|dir|28034|1102548807211|2006-04-11|2025-05-05|0|False
[L1] path|kind|files|bytes|oldest|newest|skipped|truncated
bs4scan/CATMedia|dir|585|892394268362|2012-03-27|2016-03-13|0|False
[end]
body-sha256: <sha256 of every line above this one, LF line endings>
```
`|` in a name is written as `%7C`. A fresh scan always outranks this file: it tells you where to look, not what is true today.

### Drift rules
- The checksum tells whether the file was edited or damaged since it was written.
- A **different serial** is an identity mismatch (exit 2): a copied drive, a cloned file, or the wrong drive.
- A top-level folder **added, removed or changed** (files or bytes) is drift (exit 3).
- `$RECYCLE.BIN`, `System Volume Information`, `RECYCLER`, `lost+found`, `.Trash-*`, `.Spotlight-V100`, `.fseventsd` change by themselves and never count as drift (they are noted).
- Drift is checked at the top level. A change deeper inside an unchanged-size folder is not seen until L2.

## Exit codes
| Code | Meaning |
|------|---------|
| 0 | Done, no drift (or no breadcrumb yet) |
| 1 | Usage error or failure (also: refused to write because the serial is unknown) |
| 2 | Identity mismatch |
| 3 | Drift |
| 4 | Breadcrumb write declined |
| 5 | Cannot write to the drive: checked **before** asking for YES, nothing written (on Windows: run PowerShell as Administrator) |

## Safe-walk rules (from the 2024 hash database that failed on nested storage)
- Never follow symlinks, junctions or other reparse points; count them as skipped.
- Never cross into another filesystem (bash: `find -xdev`).
- Depth cap (default 64; v0.1.0 used 12, which missed 2,052 folders on bs5: old user profiles nest deeply), time cap per top-level folder (default 25 minutes), one drive per run.
- Record what was skipped and whether the scan was truncated. A scan with `truncated: yes` is incomplete.

## Manual run checklist (what wip/chris asks a site-ops human to do)
Do this once per drive visit. Stop at any step that does not look right and tell the coordinator.

**0. Get the scripts** (netstack is public). Windows PowerShell:
```powershell
mkdir C:\storage-index; cd C:\storage-index
$b = 'https://raw.githubusercontent.com/2cld/netstack/master/docs/ops/storage-index/tools'
iwr "$b/storage-index.ps1" -OutFile storage-index.ps1
iwr "$b/test-storage-index.ps1" -OutFile test-storage-index.ps1
```
In WSL (or Linux): `curl -fsSLO "$b/storage-index.sh" -O "$b/test-storage-index.sh"; chmod +x *.sh`.

**1. Test the tool on a fake drive first** (safe, touches only a temp folder). It must say `passed 23, failed 0`:
```powershell
powershell -ExecutionPolicy Bypass -File .\test-storage-index.ps1
```
```bash
./test-storage-index.sh
```

**2. Attach the drive and note its letter** (`Get-Disk` and `Get-Volume`, or Disk Management). In WSL a USB drive shows as `/mnt/<letter>`; if it is missing run `sudo mkdir -p /mnt/d && sudo mount -t drvfs D: /mnt/d`.

**3. Scan, read-only.** The first run writes nothing to the drive:
```powershell
powershell -ExecutionPolicy Bypass -File .\storage-index.ps1 -Root D:\ -Site sl -Out C:\storage-index\out
```
```bash
./storage-index.sh /mnt/d --site sl --out ~/storage-index-out
```
Read the lines it prints: the serial matches the drive's label and sticker, file counts look plausible, `skipped` is 0 or explained, `truncated` is `no`. If it found a breadcrumb it says whether there is drift.

**4. Look at what it would leave on the drive.** Run the same command again with `-WriteBreadcrumb` (`--write-breadcrumb`). It prints the three files and waits. Type `NO` (anything but `YES`) to stop. Type `YES` only if the serial and the text are right.

**5. Check it.** The drive root now has `cat9-asset-tag.txt`, `cat9-contents.txt`, `cat9-history.txt`. The script reads the file back and prints its checksum; it must equal the `sha256` it showed before you typed YES.

**6. Send the result.** Put the folder `<out>/<serial>/<date>/` and the new line in `custody.csv` where the coordinator can read them (the site repo, or the private index repo). Update the drive's manifest with the custody line the script printed.

**7. Move the drive to another machine and run step 3 again.** That tests drift protection: an unchanged drive reports "no drift"; a drive that changed reports what changed; a different drive with a copied file reports an identity mismatch.

**To validate bash against PowerShell:** scan the same attached drive with both (Windows `D:\` and WSL `/mnt/d`), same `-Level`, then compare the top-level and second-level files after sorting: `diff <(sort ps/L0.csv) <(sort wsl/L0.csv)`. Differences in `skipped` or in system folders are expected; anything else is a bug to report.

## Tests
`test-storage-index.sh` (23 checks) and `test-storage-index.ps1` (23 checks) build a fake drive in a temp folder and check: read-only default, breadcrumb write, checksum, no drift on a second run, system folders ignored, drift on an added file and a removed folder, identity mismatch, a declined write, refusal to write without a serial, a 20-level deep tree read in full with the default depth and flagged `INCOMPLETE` with a low depth, and a drive that cannot be written refused before YES with exit 5. On 2026-11-27 both passed, and both tools produced identical `L0.csv`, `L1.csv`, `L2.csv` and `cat9-contents.txt` (apart from time, host, tool and checksum) on the same fixture. Each tool also accepted and verified a breadcrumb written by the other.

## Limits (v0.1.0)
- Windows: run PowerShell **as Administrator**. Without it, writing breadcrumbs fails on drives whose root only lets Administrators create files (found on bs5, 2026-11-28; the tool now says so before YES and exits 5), and some folders are counted as skipped for access. Even elevated, a few folders may be denied (9 on bs5).
- Dates are the file's modified date in local time. Names with newlines are not supported in the bash tool.
- Identity in WSL asks Windows through `powershell.exe`. On Linux it uses `lsblk`; some USB bridges hide the real disk serial. Use `--serial` and say so in the manifest.
- Drift is checked only at the top level (L0).
- No hashes yet (L3, L4), no reading of the site's `site-config.yml`, no automatic manifest update.

## Site collector (v0.2.0)
`site-storage-collect.sh` and `site-storage-collect.ps1` turn the site's device manifests, the per-drive index output and the health file into the site's storage picture. They are read-only on their inputs and write three files:

| Output | For | Content |
|--------|-----|---------|
| `storage.json` | Wip and the site's protected `/storage.json` | One record per registered device plus the unregistered ones (format `cat9-storage/1`) |
| `storage-map.md` | Humans, and the generated block in `docs/storage-map.md` | A table between `<!-- storage-map:begin -->` and `<!-- storage-map:end -->` markers |
| `visit-list.md` | Whoever is next at the site | One checkbox per device that needs something |

```bash
./site-storage-collect.sh --site wf --manifests ops/storage/devices --index ~/storage-index-out --out ./collected \
                          [--health disk-health.txt] [--stale-days 30]
```
```powershell
.\site-storage-collect.ps1 -Site sl -Manifests .\ops\storage\devices -Index C:\storage-index\out -Out .\collected -Health C:\ProgramData\sl-ops\disk-health.txt
```

**Manifest fields it reads** (flat `key: value` lines in the front matter; values are literal text, no YAML escapes or nesting):
`device_id` (or `asset_id`), `serial`, `label`, `kind` (`disk` default, or `pool`), `state` (`attached`, `offline`, `in-transit`, `retired`; default `unknown`), `index_serial` (the index folder name if it is not the serial, for example a pool name), `last_indexed_date` and `last_indexed_level` (used only when there is no index output), `power_on_requires`, `members`, `redundancy`, `holds`, `next_index`. Existing manifests that use `status:` are read, but `state` stays `unknown` until the field is added.

**Index output it reads:** `<index>/<serial>/<date>/summary.json` from the per-drive tool; the latest date wins. **Health:** lines `disk <serial> <health> <op> reads=<n> hours=<h> ...` as written by sl's `disk-health.ps1`.

**Flags** (information, never a failure): `NEVER-INDEXED`, `STALE` (older than `--stale-days`), `DRIFT` (last drift exit was 3), `IDENTITY` (2), `TRUNCATED`, `INCOMPLETE` (folders not read for access or depth), `HEALTH` (not Healthy and OK), `OFFLINE`. A device that is offline by design is `known_down`-like: it appears on the visit list, not as an alert.
**Pools** (`kind: pool`) are listed as one failure domain, one copy, however much redundancy they have inside. An index folder with no manifest is listed as **unregistered**.

**Tests:** `test-site-storage-collect.sh` and `test-site-storage-collect.ps1`, 29 checks each. On 2026-11-27 both tools produced byte-identical `storage.json`, `storage-map.md` and `visit-list.md` (apart from the tool name) on one fixture that included an offline pool, a stale, drifted, sick and never-indexed device, an unregistered index folder and a label with quotes and a backslash. A run of the index tool followed by the collector showed the new drive as fresh with no flags.

**Not in v0.2.0:** pool mode for the index tool (`zpool` and `zfs list`), reading `site-config.yml`, writing the generated block into `docs/storage-map.md` automatically, and publishing `/storage.json` through the site's web container.
