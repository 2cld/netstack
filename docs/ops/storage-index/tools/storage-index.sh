#!/usr/bin/env bash
# storage-index.sh 0.1.0: index a storage device and (only on request) leave breadcrumbs on it.
# Read-only by default. Spec and manual run checklist: docs/ops/storage-index/tools/README.md
# Needs GNU find, awk, sha256sum. Works on Linux and in WSL (drives appear under /mnt/<letter>).
#
# Usage: storage-index.sh <root> --site <site> [--label <name>] [--serial <serial>] [--out <dir>]
#                         [--level L0|L1|L2] [--depth 64] [--cap-min 25]
#                         [--index-ref <text>] [--manifest-url <url>]
#                         [--write-breadcrumb [--yes]] [--no-disk-lookup]
# Exit codes: 0 ok, 1 usage or error, 2 identity mismatch (serial differs from the breadcrumb),
#             3 drift (drive changed since the breadcrumb), 4 breadcrumb write declined,
#             5 cannot write to the drive.
set -u
VERSION="0.1.2"
TOOL="storage-index.sh $VERSION"
LEVEL="L1"; DEPTH=64; CAPMIN=25; OUT="./storage-index-out"; SITE=""; LABEL=""; SERIAL=""
INDEXREF="(not set)"; MANIFESTURL=""; WRITE=0; YES=0; ROOT=""; NODISK=0
SYSTEM_RE='^(\$RECYCLE\.BIN|System Volume Information|RECYCLER|lost\+found|\.Trash-[0-9]+|\.Spotlight-V100|\.fseventsd)$'

die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --site) SITE="$2"; shift 2;; --label) LABEL="$2"; shift 2;; --serial) SERIAL="$2"; shift 2;;
    --out) OUT="$2"; shift 2;; --level) LEVEL="$2"; shift 2;; --depth) DEPTH="$2"; shift 2;;
    --cap-min) CAPMIN="$2"; shift 2;; --index-ref) INDEXREF="$2"; shift 2;;
    --manifest-url) MANIFESTURL="$2"; shift 2;; --write-breadcrumb) WRITE=1; shift;;
    --yes) YES=1; shift;; --no-disk-lookup) NODISK=1; shift;; -h|--help) usage;;
    -*) die "unknown option $1";; *) [ -z "$ROOT" ] && ROOT="$1" || die "extra argument $1"; shift;;
  esac
done
[ -n "$ROOT" ] || usage
[ -d "$ROOT" ] || die "not a directory: $ROOT"
[ -n "$SITE" ] || die "--site is required (for example sl, wf, cf)"
case "$LEVEL" in L0|L1|L2) ;; *) die "--level must be L0, L1 or L2";; esac
ROOT="${ROOT%/}"; [ -n "$ROOT" ] || ROOT="/"
HOST="$(hostname 2>/dev/null || echo unknown)"
NOW_ISO="$(date +%Y-%m-%dT%H:%M:%S%z | sed 's/\(..\)$/:\1/')"; TODAY="$(date +%Y-%m-%d)"

# ---------- identity ----------
VOLLABEL=""; MODEL=""; FSTYPE=""; SIZE_GIB=""
identity() {
  if [ "$NODISK" = 1 ]; then [ -n "$LABEL" ] || LABEL="$(basename "$ROOT")"; return; fi
  FSTYPE="$(findmnt -no FSTYPE -T "$ROOT" 2>/dev/null | head -1)"
  local bytes; bytes="$(df -B1 --output=size "$ROOT" 2>/dev/null | tail -1 | tr -d ' ')"
  [ -n "$bytes" ] && SIZE_GIB="$(awk -v b="$bytes" 'BEGIN{printf "%.1f", b/1073741824}')"
  local src; src="$(findmnt -no SOURCE -T "$ROOT" 2>/dev/null | head -1)"
  case "$src" in
    /dev/*)
      local pk disk; pk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -1)"; disk="${pk:-$(basename "$src")}"
      [ -z "$SERIAL" ] && SERIAL="$(lsblk -dno SERIAL "/dev/$disk" 2>/dev/null | tr -d ' ')"
      MODEL="$(lsblk -dno MODEL "/dev/$disk" 2>/dev/null | sed 's/ *$//')"
      VOLLABEL="$(lsblk -no LABEL "$src" 2>/dev/null | head -1)";;
    *)  # WSL: a Windows drive mounted under /mnt/<letter>; ask Windows for the disk
      if command -v powershell.exe >/dev/null 2>&1 && [[ "$ROOT" =~ ^/mnt/([a-zA-Z])(/|$) ]]; then
        local l="${BASH_REMATCH[1]}" r
        r="$(powershell.exe -NoProfile -Command "\$d=Get-Partition -DriveLetter $l | Get-Disk; \$v=Get-Volume -DriveLetter $l; Write-Output ('{0}|{1}|{2}' -f \$d.SerialNumber.Trim(),\$d.FriendlyName,\$v.FileSystemLabel)" 2>/dev/null | tr -d '\r')"
        if [ -n "$r" ]; then
          [ -z "$SERIAL" ] && SERIAL="${r%%|*}"; r="${r#*|}"; MODEL="${r%%|*}"; VOLLABEL="${r#*|}"
        fi
      fi;;
  esac
  [ -n "$LABEL" ] || LABEL="${VOLLABEL:-$(basename "$ROOT")}"
}
identity
# WSL guard: /mnt/<letter> that is not a Windows drive mount is just an empty folder on the WSL disk.
# Indexing it would record the WSL virtual disk under the wrong name (found on slwin11ops, 2026-11-28).
if grep -qi microsoft /proc/version 2>/dev/null && [[ "$ROOT" =~ ^/mnt/[a-zA-Z](/|$) ]]; then
  case "$(findmnt -no FSTYPE -T "$ROOT" 2>/dev/null | head -1)" in
    9p|drvfs|v9fs) ;;
    *) die "$ROOT is not a mounted Windows drive (it is a folder on the WSL disk). Mount it first, for drive D: sudo mkdir -p /mnt/d && sudo mount -t drvfs D: /mnt/d";;
  esac
fi
SERIAL_KNOWN=1; [ -n "$SERIAL" ] || { SERIAL="UNKNOWN"; SERIAL_KNOWN=0; }
SAFE_ID="$(printf '%s' "$SERIAL" | tr -c 'A-Za-z0-9._-' '_')"
echo "== device: serial=$SERIAL model=${MODEL:-?} label=$LABEL fs=${FSTYPE:-?} size=${SIZE_GIB:-?} GiB  root=$ROOT"
[ "$SERIAL_KNOWN" = 1 ] || echo "   note: serial not found. Pass --serial. Breadcrumbs will not be written without it."

# ---------- scan ----------
OUTDIR="$OUT/$SAFE_ID/$TODAY"; mkdir -p "$OUTDIR" || die "cannot create $OUTDIR"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
L0="$TMP/L0.csv"; L1="$TMP/L1.csv"; L2="$OUTDIR/L2.csv"; L0P="$TMP/L0.pipe"; L1P="$TMP/L1.pipe"; : > "$L0P"; : > "$L1P"
echo "child,kind,files,bytes,oldest,newest,skipped,truncated" > "$L0"
echo "path,kind,files,bytes,oldest,newest,skipped,truncated" > "$L1"
[ "$LEVEL" = "L2" ] && echo "path,bytes,mtime" > "$L2"
TOTFILES=0; TOTBYTES=0; TOTSKIP=0; SKACC=0; SKSYS=0; SKLNK=0; SKDEP=0; ANYTRUNC="no"
csvq() { sed 's/"/""/g'; }
pq() { printf '%s' "$1" | sed 's/|/%7C/g'; }

# aggregate lines "F<TAB>size<TAB>date<TAB>relpath" into per-group rows
AGG='BEGIN{FS="\t"} { sz=$2; d=$3; p=$4; n=split(p,a,"/"); g=(n>1)?a[1]:"(files in this folder)";
  c[g]++; b[g]+=sz; if(!(g in o)||d<o[g])o[g]=d; if(!(g in nw)||d>nw[g])nw[g]=d;
  tc++; tb+=sz; if(tc==1||d<to1)to1=d; if(d>tn)tn=d;
  if(l2!=""){q=p; gsub(/"/,"\"\"",q); printf "\"%s/%s\",%s,%s\n", pre, q, sz, d >> l2} }
END{ for(g in c) printf "G\t%s\t%d\t%d\t%s\t%s\n", g,c[g],b[g],o[g],nw[g]; printf "T\t%d\t%d\t%s\t%s\n", tc,tb,to1,tn }'

scan_dir() {  # $1 = top-level directory name
  local name="$1" dir="$ROOT/$1" trunc="False" skipped=0 rc=0
  local raw="$TMP/raw.$$"; : > "$raw"
  timeout "${CAPMIN}m" find "$dir" -xdev -maxdepth "$DEPTH" -type f -printf 'F\t%s\t%TY-%Tm-%Td\t%P\n' > "$raw" 2>"$TMP/err.$$"
  rc=$?; [ "$rc" = 124 ] && { trunc="True"; ANYTRUNC="yes"; }
  # skipped = symlinks (not followed) + directories beyond the depth cap + unreadable paths
  local sl dd er
  sl="$(find "$dir" -xdev -maxdepth "$DEPTH" -type l 2>/dev/null | wc -l)"
  dd="$(find "$dir" -xdev -mindepth "$DEPTH" -maxdepth "$DEPTH" -type d 2>/dev/null | wc -l)"
  er="$(grep -c . "$TMP/err.$$" 2>/dev/null || true)"; [ "$rc" = 124 ] && er=0
  skipped=$((sl+dd+er)); SKLNK=$((SKLNK+sl)); SKDEP=$((SKDEP+dd))
  # unreadable system folders (System Volume Information, recycle bins) are expected and do not make a scan incomplete
  if [[ "$name" =~ $SYSTEM_RE ]]; then SKSYS=$((SKSYS+er)); else SKACC=$((SKACC+er)); fi
  local res; res="$(awk -v l2="$([ "$LEVEL" = L2 ] && echo "$L2")" -v pre="$name" "$AGG" "$raw")"
  local tline; tline="$(echo "$res" | grep '^T' | head -1)"
  local fc bc old new
  fc="$(echo "$tline" | cut -f2)"; bc="$(echo "$tline" | cut -f3)"; old="$(echo "$tline" | cut -f4)"; new="$(echo "$tline" | cut -f5)"
  [ "${fc:-0}" -gt 0 ] || { fc=0; bc=0; old=""; new=""; }
  local nq; nq="$(printf '%s' "$name" | csvq)"
  echo "\"$nq\",dir,$fc,$bc,$old,$new,$skipped,$trunc" >> "$L0"
  echo "$(pq "$name")|dir|$fc|$bc|$old|$new|$skipped|$trunc" >> "$L0P"
  if [ "$LEVEL" != "L0" ]; then
    echo "$res" | grep '^G' | LC_ALL=C sort -t$'\t' -k2 | while IFS=$'\t' read -r _ g c b o n; do
      local pqv; pqv="$(printf '%s/%s' "$name" "$g" | csvq)"
      echo "\"$pqv\",dir,$c,$b,$o,$n,0,$trunc" >> "$L1"
      echo "$(pq "$name/$g")|dir|$c|$b|$o|$n|0|$trunc" >> "$L1P"
    done
  fi
  TOTFILES=$((TOTFILES+fc)); TOTBYTES=$((TOTBYTES+bc)); TOTSKIP=$((TOTSKIP+skipped))
  rm -f "$raw" "$TMP/err.$$"
}

echo "== scanning $LEVEL (depth cap $DEPTH, time cap ${CAPMIN} min per top-level folder; symlinks and other filesystems are not followed)"
while IFS= read -r -d '' e; do
  base="$(basename "$e")"
  case "$base" in cat9-asset-tag.txt|cat9-contents.txt|cat9-history.txt) continue;; esac   # our own breadcrumbs are not content
  if [ -L "$e" ]; then
    echo "\"$(printf '%s' "$base" | csvq)\",symlink-skipped,0,0,,,1,False" >> "$L0"; echo "$(pq "$base")|symlink-skipped|0|0|||1|False" >> "$L0P"; TOTSKIP=$((TOTSKIP+1)); SKLNK=$((SKLNK+1))
  elif [ -d "$e" ]; then scan_dir "$base"
  elif [ -f "$e" ]; then
    sz="$(stat -c %s "$e")"; dt="$(date -r "$e" +%Y-%m-%d)"
    echo "\"$(printf '%s' "$base" | csvq)\",file,1,$sz,$dt,$dt,0,False" >> "$L0"; echo "$(pq "$base")|file|1|$sz|$dt|$dt|0|False" >> "$L0P"
    TOTFILES=$((TOTFILES+1)); TOTBYTES=$((TOTBYTES+sz))
  fi
done < <(find "$ROOT" -mindepth 1 -maxdepth 1 -print0 | LC_ALL=C sort -z)
cp "$L0" "$OUTDIR/L0.csv"; [ "$LEVEL" != "L0" ] && cp "$L1" "$OUTDIR/L1.csv"
echo "   done: $TOTFILES files, $(awk -v b="$TOTBYTES" 'BEGIN{printf "%.1f", b/1073741824}') GiB, skipped $TOTSKIP (access $SKACC, system $SKSYS, links $SKLNK, depth $SKDEP), truncated $ANYTRUNC"
[ "$SKDEP" -gt 0 ] && echo "   WARNING INCOMPLETE: $SKDEP folder(s) deeper than --depth $DEPTH were not read, so their files are not counted. Re-run with a higher --depth."
if [ "$SKACC" -gt 0 ]; then
  if [ "$(id -u)" = 0 ]; then echo "   WARNING INCOMPLETE: $SKACC path(s) could not be read even as root (for example a WSL drvfs mount without metadata). Their files are not counted."
  else echo "   WARNING INCOMPLETE: $SKACC path(s) could not be read (permission denied). Re-run with sudo, or accept them as incomplete."; fi
fi
[ "$ANYTRUNC" = yes ] && echo "   WARNING INCOMPLETE: the time cap cut a scan short. Re-run with a higher --cap-min."

# ---------- contents text (the breadcrumb body) ----------
build_contents() {
  {
    echo "cat9-contents/1"
    echo "# This file describes the drive as of 'scanned'. It is a snapshot, not live. A fresh scan outranks it."
    echo "serial: $SERIAL"; echo "model: ${MODEL:-unknown}"; echo "label: $LABEL"
    echo "size_gib: ${SIZE_GIB:-unknown}"; echo "filesystem: ${FSTYPE:-unknown}"
    echo "unit: GiB (1 GiB = 2^30 bytes)"; echo "hidden_files_included: yes"
    echo "level: $LEVEL"; echo "scanned: $NOW_ISO"; echo "site: $SITE"; echo "host: $HOST"; echo "tool: $TOOL"
    echo "files_total: $TOTFILES"; echo "bytes_total: $TOTBYTES"; echo "skipped: $TOTSKIP"; echo "skipped_detail: access $SKACC, system $SKSYS, links $SKLNK, depth $SKDEP"; echo "truncated: $ANYTRUNC"
    echo "index_ref: $INDEXREF"
    echo "[L0] name|kind|files|bytes|oldest|newest|skipped|truncated"
    cat "$L0P"
    if [ "$LEVEL" != "L0" ]; then echo "[L1] path|kind|files|bytes|oldest|newest|skipped|truncated"; cat "$L1P"; fi
    echo "[end]"
  }
}
build_contents > "$TMP/body.txt"
BODYSHA="$(sha256sum "$TMP/body.txt" | cut -d' ' -f1)"
{ cat "$TMP/body.txt"; echo "body-sha256: $BODYSHA"; } > "$TMP/contents.txt"
cp "$TMP/contents.txt" "$OUTDIR/cat9-contents.txt"

# ---------- drift check against an existing breadcrumb ----------
EXIT=0
OLD="$ROOT/cat9-contents.txt"
if [ -f "$OLD" ]; then
  echo "== breadcrumb found on the drive: checking it"
  olast="$(tail -1 "$OLD")"; ohash="${olast#body-sha256: }"
  ahash="$(head -n -1 "$OLD" | sha256sum | cut -d' ' -f1)"
  [ "$ohash" = "$ahash" ] && echo "   checksum ok (file not edited since written)" || echo "   WARNING: checksum does not match; the file was edited or damaged"
  oserial="$(grep -m1 '^serial: ' "$OLD" | cut -d' ' -f2-)"; odate="$(grep -m1 '^scanned: ' "$OLD" | cut -d' ' -f2-)"; osite="$(grep -m1 '^site: ' "$OLD" | cut -d' ' -f2-)"
  echo "   written: $odate at site $osite, serial $oserial"
  if [ "$SERIAL_KNOWN" = 1 ] && [ "$oserial" != "$SERIAL" ]; then
    echo "   IDENTITY MISMATCH: breadcrumb says serial '$oserial', this drive is '$SERIAL' (copied drive, cloned file, or wrong drive)"; EXIT=2
  else
    # compare L0 rows (system folders are reported but never count as drift)
    declare -A oldv newv
    while IFS='|' read -r n k f b _; do oldv["$n"]="$f|$b"; done < <(sed -n '/^\[L0\]/,/^\[L1\]\|^\[end\]/p' "$OLD" | grep -v '^\[')
    while IFS='|' read -r n k f b _; do newv["$n"]="$f|$b"; done < <(sed -n '/^\[L0\]/,/^\[L1\]\|^\[end\]/p' "$TMP/contents.txt" | grep -v '^\[')
    drift=0; sysnote=0
    for n in "${!newv[@]}"; do
      if [[ "$n" =~ $SYSTEM_RE ]]; then [ "${oldv[$n]:-}" != "${newv[$n]}" ] && sysnote=$((sysnote+1)); continue; fi
      if [ -z "${oldv[$n]:-}" ]; then echo "   ADDED:   $n (${newv[$n]})"; drift=1
      elif [ "${oldv[$n]}" != "${newv[$n]}" ]; then echo "   CHANGED: $n  was files|bytes ${oldv[$n]}  now ${newv[$n]}"; drift=1; fi
    done
    for n in "${!oldv[@]}"; do
      [[ "$n" =~ $SYSTEM_RE ]] && continue
      [ -z "${newv[$n]:-}" ] && { echo "   REMOVED: $n (was ${oldv[$n]})"; drift=1; }
    done
    [ "$sysnote" -gt 0 ] && echo "   note: $sysnote system folder(s) changed (recycle bin and the like); not counted as drift"
    if [ "$drift" = 1 ]; then echo "   DRIFT: the drive changed since $odate"; EXIT=3; else echo "   no drift at top level since $odate"; fi
  fi
else
  echo "== no breadcrumb on the drive yet"
fi

# ---------- custody line (local) ----------
[ -f "$OUT/custody.csv" ] || echo "date,serial,label,site,host,root,level,files,bytes,drift_exit" > "$OUT/custody.csv"
echo "$TODAY,$SERIAL,\"$LABEL\",$SITE,$HOST,\"$ROOT\",$LEVEL,$TOTFILES,$TOTBYTES,$EXIT" >> "$OUT/custody.csv"
cat > "$OUTDIR/summary.json" <<JSON
{"format":"cat9-index-summary/1","tool":"$TOOL","serial":"$SERIAL","model":"${MODEL:-}","label":"$LABEL","site":"$SITE","host":"$HOST","root":"$ROOT","level":"$LEVEL","scanned":"$NOW_ISO","unit":"GiB (2^30)","hidden_files_included":true,"files_total":$TOTFILES,"bytes_total":$TOTBYTES,"skipped":$TOTSKIP,"skipped_access":$SKACC,"skipped_system":$SKSYS,"skipped_links":$SKLNK,"skipped_depth":$SKDEP,"truncated":"$ANYTRUNC","contents_sha256":"$BODYSHA","drift_exit":$EXIT}
JSON
echo "== local index written to $OUTDIR (L0.csv$([ "$LEVEL" != L0 ] && echo ", L1.csv")$([ "$LEVEL" = L2 ] && echo ", L2.csv"), cat9-contents.txt, summary.json) and $OUT/custody.csv"

# ---------- breadcrumbs on the drive (only on request) ----------
if [ "$WRITE" = 1 ]; then
  [ "$SERIAL_KNOWN" = 1 ] || die "refusing to write breadcrumbs without a known serial (use --serial)"
  # preflight: can we write to the drive root? (checked before asking you to type YES)
  probe="$ROOT/cat9-write-test-$$.tmp"
  if ! { : > "$probe"; } 2>/dev/null; then
    echo "error: cannot write to $ROOT (permission denied or read-only). Nothing was written to the drive." >&2
    echo "   Re-run with enough rights (sudo, or as the drive's owner), or remount it read-write." >&2; exit 5
  fi
  rm -f "$probe"
  for o in cat9-asset-tag.txt cat9-contents.txt cat9-history.txt; do [ -e "$ROOT/$o" ] && [ ! -w "$ROOT/$o" ] && { echo "error: $ROOT/$o exists and is not writable. Nothing was written." >&2; exit 5; }; done
  MURL="${MANIFESTURL:-the site repo, ops/storage/devices/$SAFE_ID.md}"
  cat > "$TMP/tag.txt" <<TAG
Asset: $LABEL ($SERIAL)
Serial: $SERIAL
Model: ${MODEL:-unknown}
Written: $TODAY by $TOOL on $HOST (site $SITE)
Status: dated snapshot, not live. Details: cat9-contents.txt on this drive.
Manifest: $MURL
Last seen: site $SITE, host $HOST, $TODAY
Pattern: https://netstack.org/docs/ops/storage-index/
TAG
  HIST="$TODAY $NOW_ISO site=$SITE host=$HOST level=$LEVEL files=$TOTFILES bytes=$TOTBYTES tool=\"$TOOL\" drift_exit=$EXIT"
  echo; echo "== breadcrumbs to be written to the ROOT of $ROOT (nothing else on the drive is touched):"
  echo "--- cat9-asset-tag.txt (replaces any existing file)"; cat "$TMP/tag.txt"
  echo "--- cat9-contents.txt (replaces any existing file): $(wc -l < "$TMP/contents.txt") lines, level $LEVEL, sha256 $BODYSHA"
  echo "--- cat9-history.txt (one line appended):"; echo "$HIST"
  if [ "$YES" != 1 ]; then
    printf 'Type YES to write these three files to %s: ' "$ROOT"; read -r ans
    [ "$ans" = "YES" ] || { echo "declined; nothing written to the drive"; exit 4; }
  fi
  wrote=""
  { cp "$TMP/tag.txt" "$ROOT/cat9-asset-tag.txt" && wrote="cat9-asset-tag.txt" && cp "$TMP/contents.txt" "$ROOT/cat9-contents.txt" && wrote="$wrote cat9-contents.txt" \
    && echo "$HIST" >> "$ROOT/cat9-history.txt" && wrote="$wrote cat9-history.txt"; } \
    || { echo "error: write stopped after: ${wrote:-nothing}. Files not listed were not written." >&2; exit 5; }
  echo "== written. Read back and verified checksum: $(head -n -1 "$ROOT/cat9-contents.txt" | sha256sum | cut -d' ' -f1)  (expected $BODYSHA)"
fi
exit "$EXIT"
