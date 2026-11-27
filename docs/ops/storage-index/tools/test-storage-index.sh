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

echo; echo "passed $pass, failed $fail"; [ "$fail" = 0 ]
