# test-site-storage-collect.ps1: fixtures for the collector. Safe: works only inside a temp folder.
# Run: powershell -ExecutionPolicy Bypass -File test-site-storage-collect.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$tool = Join-Path $here 'site-storage-collect.ps1'
$T = Join-Path $env:TEMP ('si-col-test-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$M = Join-Path $T 'manifests'; $I = Join-Path $T 'index'; $O = Join-Path $T 'out'
New-Item -ItemType Directory -Force -Path $M,$I | Out-Null
$pass = 0; $fail = 0
function Ok($m)  { Write-Host "  ok   $m"; $script:pass++ }
function Bad($m) { Write-Host "  FAIL $m" -ForegroundColor Red; $script:fail++ }
function Has($m,$rx,$file) { if ((Get-Content -LiteralPath $file -Raw) -match $rx) { Ok $m } else { Bad "$m (missing: $rx)" } }
function HasNot($m,$rx,$file) { if ((Get-Content -LiteralPath $file -Raw) -match $rx) { Bad "$m (found: $rx)" } else { Ok $m } }
function Mf($name,[string[]]$lines) { [IO.File]::WriteAllText((Join-Path $M "$name.md"), ("---`n" + ($lines -join "`n") + "`n---`n# body`n")) }
function Sj($serial,$date,$level,$files,$bytes,$trunc='no',$drift=0) {
  $d = Join-Path (Join-Path $I $serial) $date; New-Item -ItemType Directory -Force -Path $d | Out-Null
  [IO.File]::WriteAllText((Join-Path $d 'summary.json'), "{`"format`":`"cat9-index-summary/1`",`"serial`":`"$serial`",`"label`":`"$serial`",`"level`":`"$level`",`"scanned`":`"${date}T10:00:00-06:00`",`"files_total`":$files,`"bytes_total`":$bytes,`"skipped`":0,`"truncated`":`"$trunc`",`"drift_exit`":$drift}`n")
}
function Run() { $script:last = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tool -Site test -Manifests $M -Index $I -Out $O -Health (Join-Path $T 'health.txt') -Now 2026-11-27 2>&1 | Out-String; $LASTEXITCODE }
try {
  Mf 'fresh' 'device_id: fresh','serial: A1','label: FRESH','state: attached'
  Mf 'stale' 'device_id: stale','serial: B1','label: STALE','state: attached'
  Mf 'never' 'device_id: never','serial: C1','label: NEVER','state: attached'
  Mf 'drifted' 'device_id: drifted','serial: D1','label: DRIFTED','state: attached'
  Mf 'sick' 'device_id: sick','serial: E1','label: SICK','state: attached'
  Mf 'pool' 'device_id: cg2-MediaVolume','kind: pool','serial: cg2-MediaVolume','label: MediaVolume','state: offline','power_on_requires: on-site human at wf','last_indexed_date: 2026-05-24','last_indexed_level: L0','members: Z4D0830X, Z4D0825P','redundancy: raidz1, one parity, one failure domain','holds: CAT_MPictures, Media','next_index: L0 + L1 for Media'
  Sj 'A1' '2026-11-20' 'L1' 1000 2147483648; Sj 'B1' '2026-09-01' 'L1' 50 1048576; Sj 'D1' '2026-11-25' 'L1' 70 5368709120 'no' 3
  Sj 'E1' '2026-11-26' 'L1' 10 1073741824; Sj 'X9' '2026-11-26' 'L0' 5 4096
  [IO.File]::WriteAllText((Join-Path $T 'health.txt'), "disk A1 Healthy OK reads=0 hours=100 temp=30 model=x`ndisk E1 Warning OK reads=7 hours=61000 temp=39 model=y`n")

  Write-Host "1 runs and writes the three files"
  if ((Run) -eq 0) { Ok 'exit 0' } else { Bad 'exit' }
  foreach ($f in 'storage.json','storage-map.md','visit-list.md') { if ((Test-Path (Join-Path $O $f)) -and ((Get-Item (Join-Path $O $f)).Length -gt 0)) { Ok "$f written" } else { Bad "$f missing" } }
  $J = Join-Path $O 'storage.json'; $V = Join-Path $O 'visit-list.md'; $S = Join-Path $O 'storage-map.md'
  Write-Host "2 flags"
  Has 'fresh has no flags' '"id":"fresh".*?"flags":\[\],"holds"' $J
  Has 'stale flagged STALE' '"id":"stale".*?"flags":\["STALE"\]' $J
  Has 'never flagged NEVER-INDEXED' '"id":"never".*?"flags":\["NEVER-INDEXED"\]' $J
  Has 'drifted flagged DRIFT' '"id":"drifted".*?"flags":\["DRIFT"\]' $J
  Has 'sick flagged HEALTH' '"id":"sick".*?"flags":\["HEALTH"\]' $J
  Has 'pool flagged STALE,OFFLINE' '"id":"cg2-MediaVolume".*?"flags":\["STALE","OFFLINE"\]' $J
  Has 'pool is kind pool, state offline' '"kind":"pool","state":"offline"' $J
  Has 'unregistered X9 listed' '"unregistered":\[\{"index_folder":"X9"' $J
  Has 'ages computed (stale is 87 days)' '"age_days":87' $J
  Write-Host "3 visit list"
  Has 'pool: power on and index to next_index' 'MediaVolume.*power on or attach; index to L0 \+ L1 for Media' $V
  Has 'pool notes one failure domain' 'Pool: one failure domain' $V
  Has 'pool notes what it needs' 'Needs: on-site human at wf' $V
  Has 'stale: re-index' 'STALE.*re-index \(older than 30 days\)' $V
  Has 'drift: review' 'review what changed' $V
  Has 'health: check' 'check disk health now' $V
  Has 'unregistered: write its manifest' 'X9.*not registered: write its manifest' $V
  HasNot 'fresh not on the visit list' '\*\*FRESH\*\*' $V
  Write-Host "4 storage map"
  Has 'begin marker' 'storage-map:begin' $S; Has 'end marker' 'storage-map:end' $S
  Has 'pool one-failure-domain note' 'Pools count as one failure domain' $S
  Has 'offline device shows state' 'MediaVolume \(cg2-MediaVolume\) \| pool \| offline \| 2026-05-24 L0' $S
  Write-Host "5 deterministic"
  $first = Get-Content -LiteralPath $J -Raw; [void](Run); if ($first -eq (Get-Content -LiteralPath $J -Raw)) { Ok 'same input gives same storage.json' } else { Bad 'output changed between runs' }
  Write-Host "6 nothing to do when all is fine"
  Remove-Item -Recurse -Force (Join-Path $M '*'),(Join-Path $I '*'); Mf 'fresh' 'device_id: fresh','serial: A1','label: FRESH','state: attached'; Sj 'A1' '2026-11-26' 'L1' 10 100
  [void](Run); Has 'visit list says nothing to do' 'Nothing to do' $V
} finally { Remove-Item -Recurse -Force $T -ErrorAction SilentlyContinue }
Write-Host ""; Write-Host "passed $pass, failed $fail"
if ($fail -ne 0) { exit 1 }
