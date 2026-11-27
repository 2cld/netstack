#!/usr/bin/env bash
# test-site-storage-collect.sh: fixtures for the collector. Safe: works only inside a temp directory.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok() { echo "  ok   $1"; pass=$((pass+1)); }; bad() { echo "  FAIL $1"; fail=$((fail+1)); }
has() { if grep -q -- "$2" "$3"; then ok "$1"; else bad "$1 (missing: $2)"; fi; }
hasnt() { if grep -q -- "$2" "$3"; then bad "$1 (found: $2)"; else ok "$1"; fi; }
M="$T/manifests"; I="$T/index"; O="$T/out"; mkdir -p "$M" "$I"
mf() { printf -- '---\n%s\n---\n# body\n' "$2" > "$M/$1.md"; }
sj() { mkdir -p "$I/$1/$2"; printf '{"format":"cat9-index-summary/1","serial":"%s","label":"%s","level":"%s","scanned":"%sT10:00:00-06:00","files_total":%s,"bytes_total":%s,"skipped":0,"truncated":"%s","drift_exit":%s}\n' "$1" "$1" "$3" "$2" "$4" "$5" "${6:-no}" "${7:-0}" > "$I/$1/$2/summary.json"; }
mf fresh   $'device_id: fresh\nserial: A1\nlabel: FRESH\nstate: attached'
mf stale   $'device_id: stale\nserial: B1\nlabel: STALE\nstate: attached'
mf never   $'device_id: never\nserial: C1\nlabel: NEVER\nstate: attached'
mf drifted $'device_id: drifted\nserial: D1\nlabel: DRIFTED\nstate: attached'
mf sick    $'device_id: sick\nserial: E1\nlabel: SICK\nstate: attached'
mf pool    $'device_id: cg2-MediaVolume\nkind: pool\nserial: cg2-MediaVolume\nlabel: MediaVolume\nstate: offline\npower_on_requires: on-site human at wf\nlast_indexed_date: 2026-05-24\nlast_indexed_level: L0\nmembers: Z4D0830X, Z4D0825P\nredundancy: raidz1, one parity, one failure domain\nholds: CAT_MPictures, Media\nnext_index: L0 + L1 for Media'
sj A1 2026-11-20 L1 1000 2147483648
sj B1 2026-09-01 L1 50 1048576
sj D1 2026-11-25 L1 70 5368709120 no 3
sj E1 2026-11-26 L1 10 1073741824
sj X9 2026-11-26 L0 5 4096
printf 'disk A1 Healthy OK reads=0 hours=100 temp=30 model=x\ndisk E1 Warning OK reads=7 hours=61000 temp=39 model=y\n' > "$T/health.txt"
run() { "$HERE/site-storage-collect.sh" --site test --manifests "$M" --index "$I" --out "$O" --health "$T/health.txt" --now 2026-11-27 "$@"; }

echo "1 runs and writes the three files"
run >/dev/null; [ "$?" = 0 ] && ok "exit 0" || bad "exit"
for f in storage.json storage-map.md visit-list.md; do [ -s "$O/$f" ] && ok "$f written" || bad "$f missing"; done
echo "2 flags"
has "fresh has no flags" '"id":"fresh".*"flags":\[\],"holds"' "$O/storage.json"
has "stale flagged STALE" '"id":"stale".*"flags":\["STALE"\]' "$O/storage.json"
has "never flagged NEVER-INDEXED" '"id":"never".*"flags":\["NEVER-INDEXED"\]' "$O/storage.json"
has "drifted flagged DRIFT" '"id":"drifted".*"flags":\["DRIFT"\]' "$O/storage.json"
has "sick flagged HEALTH" '"id":"sick".*"flags":\["HEALTH"\]' "$O/storage.json"
has "pool flagged STALE,OFFLINE" '"id":"cg2-MediaVolume".*"flags":\["STALE","OFFLINE"\]' "$O/storage.json"
has "pool is kind pool, state offline" '"kind":"pool","state":"offline"' "$O/storage.json"
has "unregistered X9 listed" '"unregistered":\[{"index_folder":"X9"' "$O/storage.json"
has "ages computed (stale is 87 days)" '"age_days":87' "$O/storage.json"
echo "3 visit list"
has "pool: power on and index to next_index" 'MediaVolume.*power on or attach; index to L0 + L1 for Media' "$O/visit-list.md"
has "pool notes one failure domain" 'Pool: one failure domain' "$O/visit-list.md"
has "pool notes what it needs" 'Needs: on-site human at wf' "$O/visit-list.md"
has "stale: re-index" 'STALE.*re-index (older than 30 days)' "$O/visit-list.md"
has "drift: review" 'review what changed' "$O/visit-list.md"
has "health: check" 'check disk health now' "$O/visit-list.md"
has "unregistered: write its manifest" 'X9.*not registered: write its manifest' "$O/visit-list.md"
hasnt "fresh not on the visit list" '\*\*FRESH\*\*' "$O/visit-list.md"
echo "4 storage map"
has "begin marker" 'storage-map:begin' "$O/storage-map.md"; has "end marker" 'storage-map:end' "$O/storage-map.md"
has "pool one-failure-domain note" 'Pools count as one failure domain' "$O/storage-map.md"
has "offline device shows state" 'MediaVolume (cg2-MediaVolume) | pool | offline | 2026-05-24 L0' "$O/storage-map.md"
echo "5 deterministic"
cp "$O/storage.json" "$T/first.json"; run >/dev/null; cmp -s "$T/first.json" "$O/storage.json" && ok "same input gives same storage.json" || bad "output changed between runs"
echo "6 nothing to do when all is fine"
rm -rf "$M"/* "$I"/*; mf fresh $'device_id: fresh\nserial: A1\nlabel: FRESH\nstate: attached'; sj A1 2026-11-26 L1 10 100
run >/dev/null; has "visit list says nothing to do" 'Nothing to do' "$O/visit-list.md"
echo; echo "passed $pass, failed $fail"; [ "$fail" = 0 ]
