#!/usr/bin/env bash
# test-storage-index.sh: builds a fake drive, runs storage-index.sh, and checks scan, breadcrumb write, no-drift,
# drift, identity mismatch, declined write and read-only default. Safe: works only inside a temp directory.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()   { echo "  ok   $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL $1"; fail=$((fail+1)); }
chk()  { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }
D="$T/drive"; O="$T/out"; mkdir -p "$D/photos/2020" "$D/docs" "$D/\$RECYCLE.BIN" "$D/empty"
head -c 5000 /dev/zero > "$D/photos/2020/a.jpg"; head -c 3000 /dev/zero > "$D/photos/c.jpg"; echo hi > "$D/readme.txt"; echo x > "$D/docs/d.txt"; echo r > "$D/\$RECYCLE.BIN/r.txt"
run() { "$HERE/storage-index.sh" "$D" --site test --serial SER1 --label T --out "$O" --no-disk-lookup "$@"; }

echo "1 read-only default: nothing written to the drive"
run >/dev/null; chk "exit 0" "$?" 0
chk "no breadcrumb files on drive" "$(ls "$D" | grep -c '^cat9-')" 0
chk "local index has L0 and L1" "$(ls "$O"/SER1/*/ | grep -c '^L[01].csv')" 2

echo "2 write breadcrumb"
run --write-breadcrumb --yes >/dev/null; chk "exit 0" "$?" 0
for f in cat9-asset-tag.txt cat9-contents.txt cat9-history.txt; do [ -f "$D/$f" ] && ok "$f written" || bad "$f missing"; done
chk "contents checksum matches" "$(head -n -1 "$D/cat9-contents.txt" | sha256sum | cut -d' ' -f1)" "$(tail -1 "$D/cat9-contents.txt" | sed 's/body-sha256: //')"
chk "history has 1 line" "$(wc -l < "$D/cat9-history.txt")" 1

echo "3 same drive again: no drift (history grows only with --write-breadcrumb)"
run >/dev/null; chk "exit 0" "$?" 0

echo "4 system folder changes are not drift"
echo more > "$D/\$RECYCLE.BIN/r2.txt"; run >/dev/null; chk "exit 0 after recycle bin change" "$?" 0

echo "5 drift: file added, folder removed"
echo new > "$D/photos/new.jpg"; run >/dev/null; chk "exit 3 after change" "$?" 3
rm -rf "$D/docs"; out="$(run)"; echo "$out" | grep -q 'REMOVED: docs' && ok "REMOVED reported" || bad "REMOVED not reported"

echo "6 identity mismatch: same file, different serial"
"$HERE/storage-index.sh" "$D" --site test --serial OTHER --label T --out "$O" --no-disk-lookup >/dev/null; chk "exit 2" "$?" 2

echo "7 declined write"
printf 'no\n' | run --write-breadcrumb >/dev/null; chk "exit 4" "$?" 4
chk "history still 1 line" "$(wc -l < "$D/cat9-history.txt")" 1

echo "8 missing serial refuses to write"
"$HERE/storage-index.sh" "$D" --site test --label T --out "$O" --no-disk-lookup --write-breadcrumb --yes >/dev/null 2>&1; [ "$?" != 0 ] && ok "refused" || bad "wrote without a serial"

echo "9 deep tree: default depth reads it all; a low --depth flags INCOMPLETE"
DD="$T/deep"; p="$DD/top"; for i in $(seq 1 20); do p="$p/d$i"; done; mkdir -p "$p"; head -c 777 /dev/zero > "$p/leaf.bin"
"$HERE/storage-index.sh" "$DD" --site test --serial DEEP1 --out "$T/o9" --no-disk-lookup > "$T/o9.txt"
grep -q 'done: 1 files' "$T/o9.txt" && ok "20 levels deep counted with the default depth" || bad "deep file not counted: $(grep done "$T/o9.txt")"
"$HERE/storage-index.sh" "$DD" --site test --serial DEEP1 --out "$T/o9b" --no-disk-lookup --depth 5 > "$T/o9b.txt"
grep -q 'WARNING INCOMPLETE' "$T/o9b.txt" && ok "low depth warns INCOMPLETE" || bad "no INCOMPLETE warning"
grep -q '"skipped_depth":1' "$T"/o9b/DEEP1/*/summary.json && ok "skipped_depth recorded in summary.json" || bad "skipped_depth not recorded"

echo "10 cannot write: refused before YES, exit 5, nothing written"
if [ "$(id -u)" = 0 ]; then ok "skipped (running as root, permissions not enforced)"; else
  RO="$T/ro"; mkdir -p "$RO/x"; echo a > "$RO/x/a"; chmod 555 "$RO"
  "$HERE/storage-index.sh" "$RO" --site test --serial RO1 --out "$T/o10" --no-disk-lookup --write-breadcrumb --yes > "$T/o10.txt" 2>&1; rc=$?
  chk "exit 5" "$rc" 5
  grep -q 'cannot write' "$T/o10.txt" && ok "says cannot write" || bad "no clear message"
  chk "no breadcrumb on read-only drive" "$(ls "$RO" | grep -c '^cat9-')" 0
  chmod 755 "$RO"
fi

echo "11 L0 oldest and newest dates come from the oldest and newest file, whatever the listing order"
# Two mirrored fixtures with the same names: in at least one, the oldest file is not the last one listed.
for m in 1 2; do
  DT="$T/dates$m"; mkdir -p "$DT/f/a" "$DT/f/b"; echo 1 > "$DT/f/a/x.txt"; echo 2 > "$DT/f/b/x.txt"
  if [ "$m" = 1 ]; then touch -d 2006-04-11 "$DT/f/a/x.txt"; touch -d 2025-05-05 "$DT/f/b/x.txt"
  else touch -d 2025-05-05 "$DT/f/a/x.txt"; touch -d 2006-04-11 "$DT/f/b/x.txt"; fi
  "$HERE/storage-index.sh" "$DT" --site test --serial DATES$m --out "$T/o11" --no-disk-lookup >/dev/null
  chk "fixture $m: L0 row oldest 2006-04-11, newest 2025-05-05" "$(grep '^"f"' "$T"/o11/DATES$m/*/L0.csv | cut -d, -f5,6)" "2006-04-11,2025-05-05"
done

echo "12 unreadable System Volume Information is not INCOMPLETE"
if [ "$(id -u)" = 0 ]; then ok "skipped (running as root)"; else
  SV="$T/svi"; mkdir -p "$SV/System Volume Information/x" "$SV/data"; echo a > "$SV/data/a.txt"; chmod 000 "$SV/System Volume Information"
  "$HERE/storage-index.sh" "$SV" --site test --serial SVI1 --out "$T/o12" --no-disk-lookup > "$T/o12.txt" 2>&1
  chmod 755 "$SV/System Volume Information"
  grep -q 'access 0, system 1' "$T/o12.txt" && ok "counted as system, not access" || bad "not counted as system: $(grep done "$T/o12.txt")"
  grep -q 'WARNING INCOMPLETE' "$T/o12.txt" && bad "warned INCOMPLETE for a system folder" || ok "no INCOMPLETE warning"
fi

echo; echo "passed $pass, failed $fail"; [ "$fail" = 0 ]
