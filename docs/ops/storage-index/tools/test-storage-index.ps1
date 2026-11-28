# test-storage-index.ps1: builds a fake drive in a temp folder, runs storage-index.ps1 and checks scan, breadcrumb write,
# no-drift, drift, identity mismatch, declined write and the read-only default. Safe: works only inside a temp folder.
# Run: powershell -ExecutionPolicy Bypass -File test-storage-index.ps1 [-KeepFixture]
param([switch]$KeepFixture)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$tool = Join-Path $here 'storage-index.ps1'
$T = Join-Path $env:TEMP ('si-test-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$D = Join-Path $T 'drive'; $O = Join-Path $T 'out'
$pass = 0; $fail = 0
function Ok($m)  { Write-Host "  ok   $m"; $script:pass++ }
function Bad($m) { Write-Host "  FAIL $m" -ForegroundColor Red; $script:fail++ }
function Chk($m,$got,$want) { if ("$got" -eq "$want") { Ok $m } else { Bad "$m (got '$got', want '$want')" } }
function Bytes($path,[int]$n) { [IO.File]::WriteAllBytes($path, (New-Object byte[] $n)) }
function Text($path,[string]$t) { [IO.File]::WriteAllBytes($path, [Text.Encoding]::ASCII.GetBytes($t)) }
# Runs the tool in a child process so its exit code is observable. Returns exit code; output goes to $script:last.
function Run([string[]]$extra, [string]$stdin = '') {
  $ErrorActionPreference = 'Continue'
  $args2 = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tool,'-Root',$D,'-Site','test','-Serial','SER1','-Label','T','-Out',$O,'-NoDiskLookup') + $extra
  if ($stdin) { $script:last = $stdin | & powershell.exe @args2 2>&1 | Out-String } else { $script:last = & powershell.exe @args2 2>&1 | Out-String }
  $LASTEXITCODE
}
try {
  New-Item -ItemType Directory -Force -Path (Join-Path $D 'photos\2020'),(Join-Path $D 'docs'),(Join-Path $D '$RECYCLE.BIN'),(Join-Path $D 'empty') | Out-Null
  Bytes (Join-Path $D 'photos\2020\a.jpg') 5000; Bytes (Join-Path $D 'photos\c.jpg') 3000
  Text (Join-Path $D 'readme.txt') "hello`n"; Text (Join-Path $D 'docs\d name, with comma.txt') "x`n"; Text (Join-Path $D '$RECYCLE.BIN\r.txt') "r`n"

  Write-Host "1 read-only default: nothing written to the drive"
  Chk 'exit 0' (Run @()) 0
  Chk 'no breadcrumb files on drive' (@(Get-ChildItem $D -Filter 'cat9-*').Count) 0
  Chk 'local index has L0 and L1' (@(Get-ChildItem (Join-Path $O 'SER1') -Recurse -Filter 'L?.csv').Count) 2

  Write-Host "2 write breadcrumb"
  Chk 'exit 0' (Run @('-WriteBreadcrumb','-Yes')) 0
  foreach ($f in 'cat9-asset-tag.txt','cat9-contents.txt','cat9-history.txt') { if (Test-Path (Join-Path $D $f)) { Ok "$f written" } else { Bad "$f missing" } }
  $lines = [IO.File]::ReadAllLines((Join-Path $D 'cat9-contents.txt'))
  $body = (($lines[0..($lines.Length-2)]) -join "`n") + "`n"
  $h = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash((New-Object Text.UTF8Encoding($false)).GetBytes($body))).Replace('-','').ToLower()
  Chk 'contents checksum matches' $h ($lines[-1] -replace '^body-sha256: ','')
  Chk 'history has 1 line' (@([IO.File]::ReadAllLines((Join-Path $D 'cat9-history.txt'))).Count) 1

  Write-Host "3 same drive again: no drift"
  Chk 'exit 0' (Run @()) 0

  Write-Host "4 system folder changes are not drift"
  Text (Join-Path $D '$RECYCLE.BIN\r2.txt') "more`n"; Chk 'exit 0 after recycle bin change' (Run @()) 0

  Write-Host "5 drift: file added, folder removed"
  Text (Join-Path $D 'photos\new.jpg') "new`n"; Chk 'exit 3 after change' (Run @()) 3
  Remove-Item -Recurse -Force (Join-Path $D 'docs'); [void](Run @())
  if ($script:last -match 'REMOVED: docs') { Ok 'REMOVED reported' } else { Bad 'REMOVED not reported' }

  Write-Host "6 identity mismatch: same file, different serial"
  $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tool,'-Root',$D,'-Site','test','-Serial','OTHER','-Label','T','-Out',$O,'-NoDiskLookup')
  & powershell.exe @a *> $null; Chk 'exit 2' $LASTEXITCODE 2

  Write-Host "7 declined write"
  Chk 'exit 4' (Run @('-WriteBreadcrumb') "no") 4
  Chk 'history still 1 line' (@([IO.File]::ReadAllLines((Join-Path $D 'cat9-history.txt'))).Count) 1

  Write-Host "8 missing serial refuses to write"
  $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tool,'-Root',$D,'-Site','test','-Label','T','-Out',$O,'-NoDiskLookup','-WriteBreadcrumb','-Yes')
  & powershell.exe @a *> $null; if ($LASTEXITCODE -ne 0) { Ok 'refused' } else { Bad 'wrote without a serial' }
  Write-Host "9 deep tree: default depth reads it all; a low -Depth flags INCOMPLETE"
  $DD = Join-Path $T 'deep'; $p = Join-Path $DD 'top'; for ($i = 1; $i -le 20; $i++) { $p = Join-Path $p "d$i" }
  New-Item -ItemType Directory -Force -Path $p | Out-Null; Bytes (Join-Path $p 'leaf.bin') 777
  $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tool,'-Root',$DD,'-Site','test','-Serial','DEEP1','-Out',(Join-Path $T 'o9'),'-NoDiskLookup')
  $ErrorActionPreference = 'Continue'
  $o9 = & powershell.exe @a 2>&1 | Out-String
  if ($o9 -match 'done: 1 files') { Ok '20 levels deep counted with the default depth' } else { Bad "deep file not counted" }
  $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tool,'-Root',$DD,'-Site','test','-Serial','DEEP1','-Out',(Join-Path $T 'o9b'),'-NoDiskLookup','-Depth','5')
  $o9b = & powershell.exe @a 2>&1 | Out-String
  if ($o9b -match 'WARNING INCOMPLETE') { Ok 'low depth warns INCOMPLETE' } else { Bad 'no INCOMPLETE warning' }
  $sumf = Get-ChildItem (Join-Path $T 'o9b') -Recurse -Filter summary.json | Select-Object -First 1
  if ((Get-Content $sumf.FullName -Raw) -match '"skipped_depth":1') { Ok 'skipped_depth recorded in summary.json' } else { Bad 'skipped_depth not recorded' }

  Write-Host "10 cannot write: refused before YES, exit 5, nothing written"
  $RO = Join-Path $T 'ro'; New-Item -ItemType Directory -Force -Path (Join-Path $RO 'x') | Out-Null; Text (Join-Path $RO 'x\a.txt') "a`n"
  # Deny creating files and folders only (WD, AD). Do NOT use the simple right W: it includes SYNCHRONIZE,
  # which also blocks listing the folder (found on slwin11ops, 2026-11-28).
  $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
  & icacls $RO /deny "${me}:(WD,AD)" | Out-Null
  $probeOk = $true; try { [IO.File]::WriteAllBytes((Join-Path $RO 'probe.tmp'), [byte[]]@(0)); Remove-Item (Join-Path $RO 'probe.tmp') -Force } catch { $probeOk = $false }
  $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tool,'-Root',$RO,'-Site','test','-Serial','RO1','-Out',(Join-Path $T 'o10'),'-NoDiskLookup','-WriteBreadcrumb','-Yes')
  if ($probeOk) {
    & icacls $RO /remove:d $me | Out-Null
    Ok 'skipped: this account can still write after the deny (for example the folder owner); not a tool failure'
  } else {
    $o10 = & powershell.exe @a 2>&1 | Out-String; $rc = $LASTEXITCODE
    & icacls $RO /remove:d $me | Out-Null
    Chk 'exit 5' $rc 5
    if ($o10 -match 'cannot write') { Ok 'says cannot write' } else { Bad "no clear message: $($o10.Trim())" }
    Chk 'no breadcrumb on read-only drive' (@(Get-ChildItem $RO -Filter 'cat9-*').Count) 0
  }
} finally {
  if (-not $KeepFixture) { Remove-Item -Recurse -Force $T -ErrorAction SilentlyContinue } else { Write-Host "fixture kept: $T" }
}
Write-Host ""; Write-Host "passed $pass, failed $fail"
if ($fail -ne 0) { exit 1 }
