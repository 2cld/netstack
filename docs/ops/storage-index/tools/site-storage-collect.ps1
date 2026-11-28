<#
.SYNOPSIS
  site-storage-collect.ps1 0.2.1: build the site's storage picture from device manifests, per-drive index output and health.
.DESCRIPTION
  Read-only on its inputs. Writes storage.json, storage-map.md and visit-list.md to -Out. Same output as site-storage-collect.sh.
  Spec: docs/ops/storage-index/tools/README.md (section "Site collector"). Windows PowerShell 5.1 or later.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File site-storage-collect.ps1 -Site sl -Manifests .\devices -Index C:\storage-index\out -Out .\collected -Health C:\ProgramData\sl-ops\disk-health.txt
#>
param(
  [Parameter(Mandatory=$true)][string]$Site, [Parameter(Mandatory=$true)][string]$Manifests,
  [Parameter(Mandatory=$true)][string]$Index, [Parameter(Mandatory=$true)][string]$Out,
  [string]$Health = '', [int]$StaleDays = 30, [string]$Now = (Get-Date).ToString('yyyy-MM-dd')
)
$ErrorActionPreference = 'Stop'
$Tool = 'site-storage-collect.ps1 0.2.1'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function Fail($m) { Write-Host "error: $m" -ForegroundColor Red; exit 1 }
if (-not (Test-Path -LiteralPath $Manifests -PathType Container)) { Fail "manifests folder not found: $Manifests" }
if (-not (Test-Path -LiteralPath $Index -PathType Container)) { Fail "index folder not found: $Index" }
if ($Health -and -not (Test-Path -LiteralPath $Health -PathType Leaf)) { Fail "health file not found: $Health" }
try { $NowDay = [datetime]::ParseExact($Now,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture) } catch { Fail 'bad -Now date' }
New-Item -ItemType Directory -Force -Path $Out | Out-Null
function Je([string]$s) { $s.Replace('\','\\').Replace('"','\"') }
function Safe([string]$s) { [regex]::Replace($s,'[^A-Za-z0-9._-]','_') }
function Num($v) { if ("$v" -match '^[0-9]+$') { "$v" } else { 'null' } }
function Sj($v) { if ("$v" -ne '') { '"' + (Je "$v") + '"' } else { 'null' } }
function Gib($b) { ([math]::Round([double]$b/1073741824,1)).ToString('0.0',[Globalization.CultureInfo]::InvariantCulture) }
function Get-FrontMatter([string]$file) {
  $h = @{}; $n = 0
  foreach ($l in [IO.File]::ReadAllLines($file)) {
    if ($l -match '^---\s*$') { $n++; if ($n -ge 2) { break }; continue }
    if ($n -eq 1) { $i = $l.IndexOf(':'); if ($i -gt 0) { $k = $l.Substring(0,$i); if (-not $h.ContainsKey($k)) { $v = $l.Substring($i+1).Trim(); if ($v.Length -ge 2 -and $v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1,$v.Length-2) }; $h[$k] = $v } } }
  }
  $h
}
function Get-Latest([string]$dir) {
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return $null }
  $names = [string[]]@(Get-ChildItem -LiteralPath $dir -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'summary.json') } | ForEach-Object { $_.Name })
  if ($names.Count -eq 0) { return $null }
  [Array]::Sort($names, [StringComparer]::Ordinal); Join-Path $dir $names[$names.Count-1]
}
function G($h,$k) { if ($h.ContainsKey($k)) { $h[$k] } else { '' } }

$devs = New-Object System.Collections.Generic.List[object]; $seen = @{}
$files = [string[]]@(Get-ChildItem -LiteralPath $Manifests -Filter '*.md' -File | ForEach-Object { $_.FullName }); [Array]::Sort($files, [StringComparer]::Ordinal)
foreach ($f in $files) {
  $m = Get-FrontMatter $f
  $id = G $m 'device_id'; if (-not $id) { $id = G $m 'asset_id' }; if (-not $id) { continue }
  $serial = G $m 'serial'; $kind = G $m 'kind'; if (-not $kind) { $kind = 'disk' }; $state = G $m 'state'; if (-not $state) { $state = 'unknown' }
  $idxkey = G $m 'index_serial'; if (-not $idxkey) { $idxkey = $serial }
  $d = [ordered]@{ id=$id; serial=$serial; label=(G $m 'label'); kind=$kind; state=$state; ldate=(G $m 'last_indexed_date'); llevel=(G $m 'last_indexed_level'); age=''; files=''; bytes=''; drift=''; skipped=''; trunc=''; skacc=''; skdep=''; hl=''; ho=''; hr=''; hh=''; flags=''; holds=(G $m 'holds'); members=(G $m 'members'); redundancy=(G $m 'redundancy'); power=(G $m 'power_on_requires'); nextidx=(G $m 'next_index'); source='manifest' }
  $latest = Get-Latest (Join-Path $Index (Safe $idxkey))
  if ($latest) {
    $s = Get-Content -LiteralPath (Join-Path $latest 'summary.json') -Raw | ConvertFrom-Json
    $d.ldate = ("$($s.scanned)").Split('T')[0]; $d.llevel = "$($s.level)"; $d.files = "$($s.files_total)"; $d.bytes = "$($s.bytes_total)"; $d.drift = "$($s.drift_exit)"; $d.skipped = "$($s.skipped)"; $d.skacc = "$($s.skipped_access)"; $d.skdep = "$($s.skipped_depth)"; $d.trunc = "$($s.truncated)"; $d.source = 'index'
  }
  if ($d.ldate) { try { $d.age = [string][int](($NowDay - [datetime]::ParseExact($d.ldate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)).TotalDays) } catch { $d.age = '' } }
  if ($Health -and $serial) {
    $hline = [IO.File]::ReadAllLines($Health) | Where-Object { $_.StartsWith("disk $serial ") } | Select-Object -First 1
    if ($hline) { $t = $hline.Split(' '); $d.hl = $t[2]; $d.ho = $t[3]; if ($hline -match 'reads=([0-9a-z]*)') { $d.hr = $Matches[1] }; if ($hline -match 'hours=([0-9a-z]*)') { $d.hh = $Matches[1] } }
  }
  $fl = New-Object System.Collections.Generic.List[string]
  if (-not $d.ldate) { $fl.Add('NEVER-INDEXED') } elseif ($d.age -ne '' -and [int]$d.age -gt $StaleDays) { $fl.Add('STALE') }
  if ($d.drift -eq '3') { $fl.Add('DRIFT') }; if ($d.drift -eq '2') { $fl.Add('IDENTITY') }
  if ($d.trunc -eq 'yes') { $fl.Add('TRUNCATED') }
  if (($d.skdep -match '^[0-9]+$' -and [int]$d.skdep -gt 0) -or ($d.skacc -match '^[0-9]+$' -and [int]$d.skacc -gt 0)) { $fl.Add('INCOMPLETE') }
  if ($d.hl -and ($d.hl -ne 'Healthy' -or $d.ho -ne 'OK')) { $fl.Add('HEALTH') }
  if ($state -eq 'offline') { $fl.Add('OFFLINE') }
  $d.flags = ($fl -join ',')
  $seen[(Safe $idxkey)] = $true
  $devs.Add([pscustomobject]$d)
}
$ids = [string[]]@($devs | ForEach-Object { $_.id }); [Array]::Sort($ids, [StringComparer]::Ordinal)
$sorted = @(); foreach ($i in $ids) { $sorted += ($devs | Where-Object { $_.id -eq $i } | Select-Object -First 1) }

$unreg = New-Object System.Collections.Generic.List[object]
$dirs = [string[]]@(Get-ChildItem -LiteralPath $Index -Directory | ForEach-Object { $_.Name }); [Array]::Sort($dirs, [StringComparer]::Ordinal)
foreach ($k in $dirs) {
  if ($seen.ContainsKey($k)) { continue }
  $lt = Get-Latest (Join-Path $Index $k); if (-not $lt) { continue }
  $s = Get-Content -LiteralPath (Join-Path $lt 'summary.json') -Raw | ConvertFrom-Json
  $unreg.Add([pscustomobject]@{ key=$k; label="$($s.label)"; date=("$($s.scanned)").Split('T')[0]; level="$($s.level)"; bytes="$($s.bytes_total)" })
}
function Get-Action([string]$fl,[string]$ni) {
  $a = ''; $f = ",$fl,"
  if ($f.Contains(',OFFLINE,')) { $x = if ($ni) { $ni } else { 'L1' }; $a = "power on or attach; index to $x" }
  if ($f.Contains(',NEVER-INDEXED,') -and -not $a) { $a = 'index to L1 and write a breadcrumb' }
  if ($f.Contains(',STALE,') -and -not $a) { $a = "re-index (older than $StaleDays days)" }
  if ($f.Contains(',DRIFT,')) { $a = $(if ($a) { "$a; " } else { '' }) + 'review what changed, then re-index' }
  if ($f.Contains(',IDENTITY,')) { $a = $(if ($a) { "$a; " } else { '' }) + 'STOP: serial differs from the breadcrumb; confirm which drive this is' }
  if ($f.Contains(',TRUNCATED,')) { $a = $(if ($a) { "$a; " } else { '' }) + 're-run: the last scan was cut off' }
  if ($f.Contains(',INCOMPLETE,')) { $a = $(if ($a) { "$a; " } else { '' }) + 'some folders were not read (see skipped_detail in the scan); re-run as Administrator or with a higher depth, or accept them' }
  if ($f.Contains(',HEALTH,')) { $a = $(if ($a) { "$a; " } else { '' }) + 'check disk health now' }
  $a
}
$sb = New-Object System.Text.StringBuilder
function L([string]$t) { [void]$script:sb.Append($t).Append("`n") }

# ---------- storage.json ----------
$j = New-Object System.Text.StringBuilder
[void]$j.Append("{`"format`":`"cat9-storage/1`",`"site`":`"$(Je $Site)`",`"generated`":`"$Now`",`"stale_days`":$StaleDays,`"collector`":`"$Tool`",`"devices`":[")
$first = $true
foreach ($d in $sorted) {
  if (-not $first) { [void]$j.Append(',') }; $first = $false
  $fl = '[]'; if ($d.flags) { $fl = '["' + ($d.flags.Replace(',','","')) + '"]' }
  [void]$j.Append("{`"id`":$(Sj $d.id),`"serial`":$(Sj $d.serial),`"label`":$(Sj $d.label),`"kind`":$(Sj $d.kind),`"state`":$(Sj $d.state),`"last_indexed_date`":$(Sj $d.ldate),`"last_indexed_level`":$(Sj $d.llevel),`"age_days`":$(Num $d.age),`"files_total`":$(Num $d.files),`"bytes_total`":$(Num $d.bytes),`"drift_exit`":$(Num $d.drift),`"skipped`":$(Num $d.skipped),`"skipped_access`":$(Num $d.skacc),`"skipped_depth`":$(Num $d.skdep),`"truncated`":$(Sj $d.trunc),`"health`":$(Sj $d.hl),`"op_status`":$(Sj $d.ho),`"read_errors`":$(Num $d.hr),`"power_on_hours`":$(Num $d.hh),`"flags`":$fl,`"holds`":$(Sj $d.holds),`"members`":$(Sj $d.members),`"redundancy`":$(Sj $d.redundancy),`"power_on_requires`":$(Sj $d.power),`"next_index`":$(Sj $d.nextidx),`"source`":$(Sj $d.source)}")
}
[void]$j.Append('],"unregistered":[')
$first = $true
foreach ($u in $unreg) { if (-not $first) { [void]$j.Append(',') }; $first = $false
  [void]$j.Append("{`"index_folder`":`"$(Je $u.key)`",`"label`":`"$(Je $u.label)`",`"last_indexed_date`":`"$($u.date)`",`"level`":`"$($u.level)`",`"bytes_total`":$(if ($u.bytes) { $u.bytes } else { 'null' })}") }
[void]$j.Append("]}`n")
[IO.File]::WriteAllBytes((Join-Path $Out 'storage.json'), $Utf8.GetBytes($j.ToString()))

# ---------- storage-map.md ----------
$sb.Clear() | Out-Null
L "<!-- storage-map:begin (generated by $Tool on $Now; do not edit by hand) -->"
L "## Storage map: $Site ($Now)"; L ''
L '| Device | Kind | State | Last indexed | Files | GiB | Health | Flags |'; L '|---|---|---|---|--:|--:|---|---|'
foreach ($d in $sorted) {
  $li = 'never'; if ($d.ldate) { $lv = if ($d.llevel) { $d.llevel } else { '?' }; $ag = if ($d.age -ne '') { $d.age } else { '?' }; $li = "$($d.ldate) $lv ($ag d)" }
  $g = '?'; if ($d.bytes) { $g = Gib $d.bytes }
  $hs = '?'; if ($d.hl) { $r = if ($d.hr) { $d.hr } else { '?' }; $h = if ($d.hh) { $d.hh } else { '?' }; $hs = "$($d.hl)/$($d.ho), reads $r, $h h" }
  $name = if ($d.label) { $d.label } else { $d.id }; $ser = if ($d.serial) { $d.serial } else { 'no serial' }
  $fcount = if ($d.files) { $d.files } else { '?' }; $fg = if ($d.flags) { $d.flags } else { '-' }
  L "| $name ($ser) | $($d.kind) | $($d.state) | $li | $fcount | $g | $hs | $fg |"
}
L ''
$pools = @($sorted | Where-Object { $_.kind -eq 'pool' })
if ($pools.Count -gt 0) { L 'Pools count as one failure domain (one copy), however much redundancy inside:'; foreach ($p in $pools) { L "- $($p.id): $($p.redundancy)" }; L '' }
if ($unreg.Count -gt 0) { L 'Seen by the index tool but **not registered** (no manifest):'; foreach ($u in $unreg) { L "- $($u.key) ($($u.label)), last indexed $($u.date) at $($u.level)" }; L '' }
L "Levels: L0 top-level folders, L1 second level, L2 file list. Stale means not indexed for more than $StaleDays days. A device that is offline by design is not an alert; it goes to the visit list."
L '<!-- storage-map:end -->'
[IO.File]::WriteAllBytes((Join-Path $Out 'storage-map.md'), $Utf8.GetBytes($sb.ToString()))

# ---------- visit-list.md ----------
$sb.Clear() | Out-Null
L "# Visit list: $Site ($Now)"; L ''
L 'What to do when someone is at the site. Generated from the storage map; nothing here has been done.'; L ''
$cnt = 0
foreach ($d in $sorted) {
  if (-not $d.flags) { continue }
  $a = Get-Action $d.flags $d.nextidx; if (-not $a) { continue }; $cnt++
  $extra = ''; if ($d.power) { $extra = " Needs: $($d.power)." }; if ($d.holds) { $extra = "$extra Holds: $($d.holds)." }; if ($d.kind -eq 'pool') { $extra = "$extra Pool: one failure domain." }
  $name = if ($d.label) { $d.label } else { $d.id }; $ser = if ($d.serial) { $d.serial } else { 'no serial' }; $ld = if ($d.ldate) { $d.ldate } else { 'never' }
  L "- [ ] **$name** ($ser, $($d.kind), $($d.state)): $a.$extra (flags: $($d.flags); last indexed $ld)"
}
foreach ($u in $unreg) { $cnt++; L "- [ ] **$($u.key)** ($($u.label)): attached and indexed on $($u.date) but not registered: write its manifest (device_id, serial, role, tier)." }
if ($cnt -eq 0) { L "Nothing to do: every registered device is indexed within $StaleDays days and shows no flags." }
[IO.File]::WriteAllBytes((Join-Path $Out 'visit-list.md'), $Utf8.GetBytes($sb.ToString()))
Write-Host "== ${Site}: $($sorted.Count) device(s), $($unreg.Count) unregistered, written to $Out (storage.json, storage-map.md, visit-list.md)"
exit 0
