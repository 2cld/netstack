<#
.SYNOPSIS
  storage-index.ps1 0.1.0: index a storage device and (only on request) leave breadcrumbs on it.
.DESCRIPTION
  Read-only by default. Same formats and exit codes as storage-index.sh.
  Spec and manual run checklist: docs/ops/storage-index/tools/README.md
  Windows PowerShell 5.1 or later. Run elevated to read 'System Volume Information'.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File storage-index.ps1 -Root D:\ -Site sl -Out C:\storage-index-out
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File storage-index.ps1 -Root D:\ -Site sl -Out C:\storage-index-out -WriteBreadcrumb
.NOTES
  Exit codes: 0 ok, 1 usage or error, 2 identity mismatch, 3 drift, 4 breadcrumb write declined, 5 cannot write to the drive.
#>
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$Site,
  [string]$Label = '', [string]$Serial = '',
  [string]$Out = '.\storage-index-out',
  [ValidateSet('L0','L1','L2')][string]$Level = 'L1',
  [int]$Depth = 64, [int]$CapMin = 25,
  [string]$IndexRef = '(not set)', [string]$ManifestUrl = '',
  [switch]$WriteBreadcrumb, [switch]$Yes, [switch]$NoDiskLookup
)
$ErrorActionPreference = 'Stop'
$Version = '0.1.2'; $Tool = "storage-index.ps1 $Version"
$SystemRe = '^(\$RECYCLE\.BIN|System Volume Information|RECYCLER|lost\+found|\.Trash-[0-9]+|\.Spotlight-V100|\.fseventsd)$'
$Own = @('cat9-asset-tag.txt','cat9-contents.txt','cat9-history.txt')
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function Fail($m) { Write-Host "error: $m" -ForegroundColor Red; exit 1 }
function Pq([string]$s) { $s.Replace('|','%7C') }
function Cq([string]$s) { '"' + $s.Replace('"','""') + '"' }
function Sha256Bytes([byte[]]$b) { $h=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($h.ComputeHash($b))).Replace('-','').ToLower() }
function WriteLf([string]$path,[string]$text) { [IO.File]::WriteAllBytes($path, $Utf8.GetBytes($text)) }

if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "not a directory: $Root" }
$RootFull = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
if ($RootFull -match '^[A-Za-z]:$') { $RootFull = $RootFull + '\' }
$HostName = $env:COMPUTERNAME
$NowIso = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz'); $Today = (Get-Date).ToString('yyyy-MM-dd')

# ---------- identity ----------
$Model=''; $VolLabel=''; $Fs=''; $SizeGib=''
if (-not $NoDiskLookup -and $RootFull -match '^([A-Za-z]):') {
  $letter = $Matches[1]
  try {
    $vol = Get-Volume -DriveLetter $letter
    $VolLabel = $vol.FileSystemLabel; $Fs = $vol.FileSystem; $SizeGib = [math]::Round($vol.Size/1GB,1).ToString('0.0',[Globalization.CultureInfo]::InvariantCulture)
    $disk = Get-Partition -DriveLetter $letter | Get-Disk
    if (-not $Serial) { $Serial = ([string]$disk.SerialNumber).Trim() }
    $Model = ([string]$disk.FriendlyName).Trim()
  } catch { Write-Host "note: could not read disk identity ($($_.Exception.Message))" }
}
if (-not $Label) { if ($VolLabel) { $Label = $VolLabel } else { $Label = Split-Path $RootFull -Leaf } }
$SerialKnown = $true; if (-not $Serial) { $Serial = 'UNKNOWN'; $SerialKnown = $false }
$SafeId = [regex]::Replace($Serial,'[^A-Za-z0-9._-]','_')
Write-Host "== device: serial=$Serial model=$Model label=$Label fs=$Fs size=$SizeGib GiB  root=$RootFull"
if (-not $SerialKnown) { Write-Host "   note: serial not found. Pass -Serial. Breadcrumbs will not be written without it." }

# ---------- scan ----------
$OutDir = Join-Path (Join-Path $Out $SafeId) $Today
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$L0 = New-Object System.Collections.Generic.List[string]; $L1 = New-Object System.Collections.Generic.List[string]
$L0p = New-Object System.Collections.Generic.List[string]; $L1p = New-Object System.Collections.Generic.List[string]
$L0.Add('child,kind,files,bytes,oldest,newest,skipped,truncated'); $L1.Add('path,kind,files,bytes,oldest,newest,skipped,truncated')
$L2w = $null
if ($Level -eq 'L2') { $L2w = New-Object System.IO.StreamWriter((Join-Path $OutDir 'L2.csv'), $false, $Utf8); $L2w.NewLine = "`n"; $L2w.WriteLine('path,bytes,mtime') }
$script:TotFiles = [int64]0; $script:TotBytes = [int64]0; $script:TotSkip = 0; $script:SkAcc = 0; $script:SkLnk = 0; $script:SkDep = 0; $script:AnyTrunc = 'no'

function Invoke-Walk([string]$dir, [string]$name, [datetime]$deadline) {
  $groups = @{}; $tc = [int64]0; $tb = [int64]0; $to = ''; $tn = ''; $skipped = 0; $skA = 0; $skL = 0; $skD = 0; $trunc = $false; $tick = 0
  $stack = New-Object System.Collections.Stack
  $stack.Push(@($dir, 0, ''))
  while ($stack.Count -gt 0) {
    $tick++; if (($tick % 100) -eq 0 -and (Get-Date) -gt $deadline) { $trunc = $true; break }
    $it = $stack.Pop(); $d = $it[0]; $dp = [int]$it[1]; $grp = [string]$it[2]
    try {
      $di = New-Object System.IO.DirectoryInfo $d
      foreach ($f in $di.EnumerateFiles()) {
        if ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) { $skipped++; $skL++; continue }
        $g = if ($dp -eq 0) { '(files in this folder)' } else { $grp }
        $dt = $f.LastWriteTime.ToString('yyyy-MM-dd'); $len = [int64]$f.Length
        if (-not $groups.ContainsKey($g)) { $groups[$g] = @{ c=[int64]0; b=[int64]0; o=$dt; n=$dt } }
        $e = $groups[$g]; $e.c++; $e.b += $len; if ($dt -lt $e.o) { $e.o = $dt }; if ($dt -gt $e.n) { $e.n = $dt }
        $tc++; $tb += $len; if ($to -eq '' -or $dt -lt $to) { $to = $dt }; if ($dt -gt $tn) { $tn = $dt }
        if ($L2w) { $rel = $f.FullName.Substring($dir.Length).TrimStart('\').Replace('\','/'); $L2w.WriteLine((Cq "$name/$rel") + ",$len,$dt") }
      }
      foreach ($s in $di.EnumerateDirectories()) {
        if ($s.Attributes -band [IO.FileAttributes]::ReparsePoint) { $skipped++; $skL++; continue }
        if (($dp + 1) -ge $Depth) { $skipped++; $skD++; continue }
        $ng = if ($dp -eq 0) { $s.Name } else { $grp }
        $stack.Push(@($s.FullName, ($dp + 1), $ng))
      }
    } catch { $skipped++; $skA++ }
  }
  $tr = if ($trunc) { 'True' } else { 'False' }
  if ($tc -eq 0) { $to = ''; $tn = '' }
  $L0.Add("$(Cq $name),dir,$tc,$tb,$to,$tn,$skipped,$tr"); $L0p.Add("$(Pq $name)|dir|$tc|$tb|$to|$tn|$skipped|$tr")
  if ($Level -ne 'L0') {
    $keys = [string[]]@($groups.Keys); [Array]::Sort($keys, [StringComparer]::Ordinal)
    foreach ($k in $keys) { $e = $groups[$k]
      $L1.Add("$(Cq "$name/$k"),dir,$($e.c),$($e.b),$($e.o),$($e.n),0,$tr"); $L1p.Add("$(Pq "$name/$k")|dir|$($e.c)|$($e.b)|$($e.o)|$($e.n)|0|$tr") }
  }
  $script:TotFiles += $tc; $script:TotBytes += $tb; $script:TotSkip += $skipped; $script:SkAcc += $skA; $script:SkLnk += $skL; $script:SkDep += $skD; if ($trunc) { $script:AnyTrunc = 'yes' }
}

Write-Host "== scanning $Level (depth cap $Depth, time cap $CapMin min per top-level folder; reparse points are not followed)"
$ri = New-Object System.IO.DirectoryInfo $RootFull
try { $entries = @($ri.EnumerateFileSystemInfos()) } catch { Fail "cannot list $RootFull ($($_.Exception.Message)). Run PowerShell as Administrator, or check the drive's permissions." }
$names = [string[]]@($entries | ForEach-Object { $_.Name })
$byName = @{}; foreach ($e in $entries) { $byName[$e.Name] = $e }
[Array]::Sort($names, [StringComparer]::Ordinal)
foreach ($n in $names) {
  if ($Own -contains $n) { continue }
  $e = $byName[$n]
  if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    $L0.Add("$(Cq $n),symlink-skipped,0,0,,,1,False"); $L0p.Add("$(Pq $n)|symlink-skipped|0|0|||1|False"); $script:TotSkip++; $script:SkLnk++
  } elseif ($e -is [System.IO.DirectoryInfo]) {
    Invoke-Walk $e.FullName $n ((Get-Date).AddMinutes($CapMin))
  } else {
    $dt = $e.LastWriteTime.ToString('yyyy-MM-dd'); $len = [int64]$e.Length
    $L0.Add("$(Cq $n),file,1,$len,$dt,$dt,0,False"); $L0p.Add("$(Pq $n)|file|1|$len|$dt|$dt|0|False")
    $script:TotFiles++; $script:TotBytes += $len
  }
}
if ($L2w) { $L2w.Close() }
WriteLf (Join-Path $OutDir 'L0.csv') (($L0 -join "`n") + "`n")
if ($Level -ne 'L0') { WriteLf (Join-Path $OutDir 'L1.csv') (($L1 -join "`n") + "`n") }
$gib = [math]::Round($script:TotBytes/1GB,1).ToString('0.0',[Globalization.CultureInfo]::InvariantCulture)
Write-Host "   done: $($script:TotFiles) files, $gib GiB, skipped $($script:TotSkip) (access $($script:SkAcc), links $($script:SkLnk), depth $($script:SkDep)), truncated $($script:AnyTrunc)"
if ($script:SkDep -gt 0) { Write-Host "   WARNING INCOMPLETE: $($script:SkDep) folder(s) deeper than -Depth $Depth were not read, so their files are not counted. Re-run with a higher -Depth." -ForegroundColor Yellow }
if ($script:SkAcc -gt 0) { Write-Host "   WARNING INCOMPLETE: $($script:SkAcc) folder(s) could not be read (access denied). Run PowerShell as Administrator and re-run." -ForegroundColor Yellow }
if ($script:AnyTrunc -eq 'yes') { Write-Host "   WARNING INCOMPLETE: the time cap cut a scan short. Re-run with a higher -CapMin." -ForegroundColor Yellow }

# ---------- contents text ----------
$b = New-Object System.Text.StringBuilder
function Add-Line([string]$s) { [void]$b.Append($s).Append("`n") }
Add-Line 'cat9-contents/1'
Add-Line "# This file describes the drive as of 'scanned'. It is a snapshot, not live. A fresh scan outranks it."
Add-Line "serial: $Serial"; $m = if ($Model) { $Model } else { 'unknown' }; Add-Line "model: $m"; Add-Line "label: $Label"
$sg = if ($SizeGib) { $SizeGib } else { 'unknown' }; Add-Line "size_gib: $sg"; $fsv = if ($Fs) { $Fs } else { 'unknown' }; Add-Line "filesystem: $fsv"
Add-Line 'unit: GiB (1 GiB = 2^30 bytes)'; Add-Line 'hidden_files_included: yes'
Add-Line "level: $Level"; Add-Line "scanned: $NowIso"; Add-Line "site: $Site"; Add-Line "host: $HostName"; Add-Line "tool: $Tool"
Add-Line "files_total: $($script:TotFiles)"; Add-Line "bytes_total: $($script:TotBytes)"; Add-Line "skipped: $($script:TotSkip)"; Add-Line "skipped_detail: access $($script:SkAcc), links $($script:SkLnk), depth $($script:SkDep)"; Add-Line "truncated: $($script:AnyTrunc)"
Add-Line "index_ref: $IndexRef"
Add-Line '[L0] name|kind|files|bytes|oldest|newest|skipped|truncated'; foreach ($r in $L0p) { Add-Line $r }
if ($Level -ne 'L0') { Add-Line '[L1] path|kind|files|bytes|oldest|newest|skipped|truncated'; foreach ($r in $L1p) { Add-Line $r } }
Add-Line '[end]'
$body = $b.ToString(); $bodySha = Sha256Bytes ($Utf8.GetBytes($body))
$contents = $body + "body-sha256: $bodySha`n"
WriteLf (Join-Path $OutDir 'cat9-contents.txt') $contents

# ---------- drift check ----------
$exit = 0
$oldPath = Join-Path $RootFull 'cat9-contents.txt'
function Get-L0Map([string[]]$lines) {
  $map = @{}; $in = $false
  foreach ($l in $lines) {
    if ($l.StartsWith('[L0]')) { $in = $true; continue }
    if ($l.StartsWith('[L1]') -or $l.StartsWith('[end]')) { $in = $false }
    if ($in -and $l.Contains('|')) { $p = $l.Split('|'); $map[$p[0]] = "$($p[2])|$($p[3])" }
  }
  $map
}
if (Test-Path -LiteralPath $oldPath) {
  Write-Host "== breadcrumb found on the drive: checking it"
  $oldLines = [IO.File]::ReadAllLines($oldPath)
  $last = $oldLines[$oldLines.Length-1]; $ohash = $last -replace '^body-sha256: ',''
  $oldBody = (($oldLines[0..($oldLines.Length-2)]) -join "`n") + "`n"
  if ((Sha256Bytes ($Utf8.GetBytes($oldBody))) -eq $ohash) { Write-Host "   checksum ok (file not edited since written)" } else { Write-Host "   WARNING: checksum does not match; the file was edited or damaged" }
  $oserial = (($oldLines | Where-Object { $_ -like 'serial: *' } | Select-Object -First 1) -replace '^serial: ','')
  $odate = (($oldLines | Where-Object { $_ -like 'scanned: *' } | Select-Object -First 1) -replace '^scanned: ','')
  $osite = (($oldLines | Where-Object { $_ -like 'site: *' } | Select-Object -First 1) -replace '^site: ','')
  Write-Host "   written: $odate at site $osite, serial $oserial"
  if ($SerialKnown -and $oserial -ne $Serial) {
    Write-Host "   IDENTITY MISMATCH: breadcrumb says serial '$oserial', this drive is '$Serial' (copied drive, cloned file, or wrong drive)"; $exit = 2
  } else {
    $oldv = Get-L0Map $oldLines; $newv = Get-L0Map ($contents -split "`n"); $drift = $false; $sysnote = 0
    foreach ($n in $newv.Keys) {
      if ($n -match $SystemRe) { if ($oldv[$n] -ne $newv[$n]) { $sysnote++ }; continue }
      if (-not $oldv.ContainsKey($n)) { Write-Host "   ADDED:   $n ($($newv[$n]))"; $drift = $true }
      elseif ($oldv[$n] -ne $newv[$n]) { Write-Host "   CHANGED: $n  was files|bytes $($oldv[$n])  now $($newv[$n])"; $drift = $true }
    }
    foreach ($n in $oldv.Keys) { if ($n -match $SystemRe) { continue }; if (-not $newv.ContainsKey($n)) { Write-Host "   REMOVED: $n (was $($oldv[$n]))"; $drift = $true } }
    if ($sysnote -gt 0) { Write-Host "   note: $sysnote system folder(s) changed (recycle bin and the like); not counted as drift" }
    if ($drift) { Write-Host "   DRIFT: the drive changed since $odate"; $exit = 3 } else { Write-Host "   no drift at top level since $odate" }
  }
} else { Write-Host "== no breadcrumb on the drive yet" }

# ---------- custody line and summary (local) ----------
$cust = Join-Path $Out 'custody.csv'
if (-not (Test-Path -LiteralPath $cust)) { [IO.File]::AppendAllText($cust, "date,serial,label,site,host,root,level,files,bytes,drift_exit`n", $Utf8) }
[IO.File]::AppendAllText($cust, "$Today,$Serial,$(Cq $Label),$Site,$HostName,$(Cq $RootFull),$Level,$($script:TotFiles),$($script:TotBytes),$exit`n", $Utf8)
$sum = '{{"format":"cat9-index-summary/1","tool":"{0}","serial":"{1}","model":"{2}","label":"{3}","site":"{4}","host":"{5}","root":"{6}","level":"{7}","scanned":"{8}","unit":"GiB (2^30)","hidden_files_included":true,"files_total":{9},"bytes_total":{10},"skipped":{11},"skipped_access":{12},"skipped_links":{13},"skipped_depth":{14},"truncated":"{15}","contents_sha256":"{16}","drift_exit":{17}}}' -f $Tool,$Serial,$Model,$Label.Replace('"','\"'),$Site,$HostName,$RootFull.Replace('\','\\'),$Level,$NowIso,$script:TotFiles,$script:TotBytes,$script:TotSkip,$script:SkAcc,$script:SkLnk,$script:SkDep,$script:AnyTrunc,$bodySha,$exit
WriteLf (Join-Path $OutDir 'summary.json') ($sum + "`n")
Write-Host "== local index written to $OutDir (L0.csv$(if($Level -ne 'L0'){', L1.csv'})$(if($Level -eq 'L2'){', L2.csv'}), cat9-contents.txt, summary.json) and $cust"

# ---------- breadcrumbs on the drive (only on request) ----------
if ($WriteBreadcrumb) {
  if (-not $SerialKnown) { Fail "refusing to write breadcrumbs without a known serial (use -Serial)" }
  # preflight: can this session write to the drive root? (checked before asking you to type YES)
  $probe = Join-Path $RootFull ('cat9-write-test-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.tmp')
  try {
    [IO.File]::WriteAllBytes($probe, [byte[]]@(0)); Remove-Item -LiteralPath $probe -Force
    foreach ($o in $Own) { $op = Join-Path $RootFull $o; if (Test-Path -LiteralPath $op) { $fs = [IO.File]::Open($op,'Open','Write','ReadWrite'); $fs.Close() } }
  } catch {
    Write-Host "error: cannot write to $RootFull ($($_.Exception.Message))" -ForegroundColor Red
    Write-Host "   On Windows this usually means PowerShell is not running as Administrator, or the drive's permissions only allow Administrators." -ForegroundColor Red
    Write-Host "   Right-click PowerShell, choose 'Run as administrator', and run the same command again. Nothing was written to the drive." -ForegroundColor Red
    exit 5
  }
  $murl = if ($ManifestUrl) { $ManifestUrl } else { "the site repo, ops/storage/devices/$SafeId.md" }
  $mdl = if ($Model) { $Model } else { 'unknown' }
  $tag = "Asset: $Label ($Serial)`nSerial: $Serial`nModel: $mdl`nWritten: $Today by $Tool on $HostName (site $Site)`nStatus: dated snapshot, not live. Details: cat9-contents.txt on this drive.`nManifest: $murl`nLast seen: site $Site, host $HostName, $Today`nPattern: https://netstack.org/docs/ops/storage-index/`n"
  $hist = "$Today $NowIso site=$Site host=$HostName level=$Level files=$($script:TotFiles) bytes=$($script:TotBytes) tool=`"$Tool`" drift_exit=$exit"
  Write-Host ""; Write-Host "== breadcrumbs to be written to the ROOT of $RootFull (nothing else on the drive is touched):"
  Write-Host "--- cat9-asset-tag.txt (replaces any existing file)"; Write-Host $tag.TrimEnd()
  Write-Host "--- cat9-contents.txt (replaces any existing file): $(($contents -split "`n").Count - 1) lines, level $Level, sha256 $bodySha"
  Write-Host "--- cat9-history.txt (one line appended):"; Write-Host $hist
  if (-not $Yes) { $ans = Read-Host "Type YES to write these three files to $RootFull"; if ($ans -ne 'YES') { Write-Host "declined; nothing written to the drive"; exit 4 } }
  $done = New-Object System.Collections.Generic.List[string]; $failed = ''
  try { WriteLf (Join-Path $RootFull 'cat9-asset-tag.txt') $tag; $done.Add('cat9-asset-tag.txt')
        WriteLf (Join-Path $RootFull 'cat9-contents.txt') $contents; $done.Add('cat9-contents.txt')
        [IO.File]::AppendAllText((Join-Path $RootFull 'cat9-history.txt'), $hist + "`n", $Utf8); $done.Add('cat9-history.txt')
  } catch { $failed = $_.Exception.Message }
  if ($failed) { Write-Host "error: write stopped after: $($done -join ', ') ($failed)" -ForegroundColor Red; Write-Host "   Files not listed were not written. Run again as Administrator." -ForegroundColor Red; exit 5 }
  $rb = [IO.File]::ReadAllLines((Join-Path $RootFull 'cat9-contents.txt')); $rbBody = (($rb[0..($rb.Length-2)]) -join "`n") + "`n"
  Write-Host "== written. Read back and verified checksum: $(Sha256Bytes ($Utf8.GetBytes($rbBody)))  (expected $bodySha)"
}
exit $exit
