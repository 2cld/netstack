#!/usr/bin/env bash
# site-storage-collect.sh 0.2.0: build the site's storage picture from device manifests, per-drive index output and health.
# Read-only on its inputs. Writes storage.json, storage-map.md and visit-list.md to --out.
# Spec: docs/ops/storage-index/tools/README.md (section "Site collector")
#
# Usage: site-storage-collect.sh --site <site> --manifests <dir> --index <dir> --out <dir>
#                                [--health <disk-health.txt>] [--stale-days 30] [--now YYYY-MM-DD]
# Exit codes: 0 ok, 1 usage or error. (Flags in the report are information, not failures.)
set -u
VERSION="0.2.1"; TOOL="site-storage-collect.sh $VERSION"
SITE=""; MAN=""; IDX=""; OUT=""; HEALTH=""; STALE=30; NOW="$(date +%F)"
die() { echo "error: $*" >&2; exit 1; }
while [ $# -gt 0 ]; do
  case "$1" in
    --site) SITE="$2"; shift 2;; --manifests) MAN="$2"; shift 2;; --index) IDX="$2"; shift 2;; --out) OUT="$2"; shift 2;;
    --health) HEALTH="$2"; shift 2;; --stale-days) STALE="$2"; shift 2;; --now) NOW="$2"; shift 2;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1;; *) die "unknown option $1";;
  esac
done
[ -n "$SITE" ] && [ -d "$MAN" ] && [ -d "$IDX" ] && [ -n "$OUT" ] || die "need --site, --manifests <dir>, --index <dir>, --out <dir>"
[ -z "$HEALTH" ] || [ -f "$HEALTH" ] || die "health file not found: $HEALTH"
mkdir -p "$OUT" || die "cannot create $OUT"
US=$'\037'   # field separator that is not whitespace, so empty fields survive `read`
NOWDAY="$(date -d "$NOW" +%s 2>/dev/null)" || die "bad --now date"

je() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }                 # json string escape
fm() { awk -v k="$2" 'BEGIN{n=0} /^---[ \t]*$/{n++; next} n==1{ i=index($0,":"); if(i>0 && substr($0,1,i-1)==k){ v=substr($0,i+1); sub(/^[ \t]+/,"",v); sub(/[ \t\r]+$/,"",v); gsub(/^"|"$/,"",v); print v; exit } }' "$1"; }
jv() { sed -n "s/.*\"$2\":\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" "$1" | head -1; }   # flat json value
safe() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }
days_between() { local t; t="$(date -d "$1" +%s 2>/dev/null)" || { echo ""; return; }; echo $(( (NOWDAY - t) / 86400 )); }
gib() { awk -v b="$1" 'BEGIN{printf "%.1f", b/1073741824}'; }

declare -a IDS ROWS; declare -A SEEN
: > "$OUT/.devices.tsv"
for f in $(ls "$MAN"/*.md 2>/dev/null | LC_ALL=C sort); do
  id="$(fm "$f" device_id)"; [ -n "$id" ] || id="$(fm "$f" asset_id)"; [ -n "$id" ] || continue
  serial="$(fm "$f" serial)"; label="$(fm "$f" label)"; kind="$(fm "$f" kind)"; kind="${kind:-disk}"
  state="$(fm "$f" state)"; state="${state:-unknown}"
  idxkey="$(fm "$f" index_serial)"; idxkey="${idxkey:-$serial}"
  holds="$(fm "$f" holds)"; members="$(fm "$f" members)"; redundancy="$(fm "$f" redundancy)"; power="$(fm "$f" power_on_requires)"; nextidx="$(fm "$f" next_index)"
  ldate="$(fm "$f" last_indexed_date)"; llevel="$(fm "$f" last_indexed_level)"
  files=""; bytes=""; drift=""; skipped=""; trunc=""; skacc=""; skdep=""; source="manifest"
  sdir="$IDX/$(safe "$idxkey")"; latest=""
  [ -d "$sdir" ] && latest="$(ls -d "$sdir"/*/ 2>/dev/null | while read -r d; do [ -f "${d}summary.json" ] && echo "${d%/}"; done | LC_ALL=C sort | tail -1)"
  if [ -n "$latest" ]; then
    s="$latest/summary.json"; scanned="$(jv "$s" scanned)"; ldate="${scanned%%T*}"; llevel="$(jv "$s" level)"
    files="$(jv "$s" files_total)"; bytes="$(jv "$s" bytes_total)"; drift="$(jv "$s" drift_exit)"; skipped="$(jv "$s" skipped)"; skacc="$(jv "$s" skipped_access)"; skdep="$(jv "$s" skipped_depth)"; trunc="$(jv "$s" truncated)"; source="index"
  fi
  age=""; [ -n "$ldate" ] && age="$(days_between "$ldate")"
  hl=""; ho=""; hr=""; hh=""
  if [ -n "$HEALTH" ] && [ -n "$serial" ]; then
    hline="$(grep -m1 "^disk $serial " "$HEALTH" 2>/dev/null || true)"
    if [ -n "$hline" ]; then hl="$(echo "$hline" | awk '{print $3}')"; ho="$(echo "$hline" | awk '{print $4}')"; hr="$(echo "$hline" | sed -n 's/.*reads=\([0-9a-z]*\).*/\1/p')"; hh="$(echo "$hline" | sed -n 's/.*hours=\([0-9a-z]*\).*/\1/p')"; fi
  fi
  flags=""; addf() { flags="${flags:+$flags,}$1"; }
  if [ -z "$ldate" ]; then addf NEVER-INDEXED; elif [ -n "$age" ] && [ "$age" -gt "$STALE" ]; then addf STALE; fi
  [ "$drift" = 3 ] && addf DRIFT; [ "$drift" = 2 ] && addf IDENTITY
  [ "$trunc" = yes ] && addf TRUNCATED
  { [[ "$skdep" =~ ^[0-9]+$ ]] && [ "$skdep" -gt 0 ]; } || { [[ "$skacc" =~ ^[0-9]+$ ]] && [ "$skacc" -gt 0 ]; } && addf INCOMPLETE
  { [ -n "$hl" ] && { [ "$hl" != "Healthy" ] || [ "$ho" != "OK" ]; }; } && addf HEALTH
  [ "$state" = offline ] && addf OFFLINE
  SEEN["$(safe "$idxkey")"]=1
  printf '%s\037' "$id" "$serial" "$label" "$kind" "$state" "$ldate" "$llevel" "$age" "$files" "$bytes" "$drift" "$skipped" "$trunc" "$hl" "$ho" "$hr" "$hh" "$flags" "$holds" "$members" "$redundancy" "$power" "$nextidx" "$source" "$skacc" "$skdep" >> "$OUT/.devices.tsv"; echo >> "$OUT/.devices.tsv"
done
LC_ALL=C sort -t"$US" -k1,1 "$OUT/.devices.tsv" -o "$OUT/.devices.tsv"

# unregistered: index folders with no manifest
: > "$OUT/.unreg.tsv"
for d in $(ls -d "$IDX"/*/ 2>/dev/null | LC_ALL=C sort); do
  k="$(basename "$d")"; [ -n "${SEEN[$k]:-}" ] && continue
  lt="$(ls -d "$d"*/ 2>/dev/null | while read -r x; do [ -f "${x}summary.json" ] && echo "${x%/}"; done | LC_ALL=C sort | tail -1)"; [ -n "$lt" ] || continue
  s="$lt/summary.json"; printf '%s\037%s\037%s\037%s\037%s\n' "$k" "$(jv "$s" label)" "$(jv "$s" scanned | cut -c1-10)" "$(jv "$s" level)" "$(jv "$s" bytes_total)" >> "$OUT/.unreg.tsv"
done

action() {  # flags state next_index -> action text
  local fl="$1" st="$2" ni="$3" a=""
  case ",$fl," in *,OFFLINE,*) a="power on or attach; index to ${ni:-L1}";; esac
  case ",$fl," in *,NEVER-INDEXED,*) [ -z "$a" ] && a="index to L1 and write a breadcrumb";; esac
  case ",$fl," in *,STALE,*) [ -z "$a" ] && a="re-index (older than $STALE days)";; esac
  case ",$fl," in *,DRIFT,*) a="${a:+$a; }review what changed, then re-index";; esac
  case ",$fl," in *,IDENTITY,*) a="${a:+$a; }STOP: serial differs from the breadcrumb; confirm which drive this is";; esac
  case ",$fl," in *,TRUNCATED,*) a="${a:+$a; }re-run: the last scan was cut off";; esac
  case ",$fl," in *,INCOMPLETE,*) a="${a:+$a; }re-run with a higher depth or as an administrator: the last scan did not read everything";; esac
  case ",$fl," in *,HEALTH,*) a="${a:+$a; }check disk health now";; esac
  echo "$a"
}

# ---------- storage.json ----------
{
  printf '{"format":"cat9-storage/1","site":"%s","generated":"%s","stale_days":%s,"collector":"%s","devices":[' "$(je "$SITE")" "$NOW" "$STALE" "$TOOL"
  first=1
  while IFS="$US" read -r id serial label kind state ldate llevel age files bytes drift skipped trunc hl ho hr hh flags holds members redundancy power nextidx source skacc skdep; do
    [ "$first" = 1 ] || printf ','; first=0
    n() { [[ "$1" =~ ^[0-9]+$ ]] && printf '%s' "$1" || printf 'null'; }; sj() { [ -n "$1" ] && printf '"%s"' "$(je "$1")" || printf 'null'; }
    fl="[]"; [ -n "$flags" ] && fl="[\"$(echo "$flags" | sed 's/,/","/g')\"]"
    printf '{"id":%s,"serial":%s,"label":%s,"kind":%s,"state":%s,"last_indexed_date":%s,"last_indexed_level":%s,"age_days":%s,"files_total":%s,"bytes_total":%s,"drift_exit":%s,"skipped":%s,"skipped_access":%s,"skipped_depth":%s,"truncated":%s,"health":%s,"op_status":%s,"read_errors":%s,"power_on_hours":%s,"flags":%s,"holds":%s,"members":%s,"redundancy":%s,"power_on_requires":%s,"next_index":%s,"source":%s}' \
      "$(sj "$id")" "$(sj "$serial")" "$(sj "$label")" "$(sj "$kind")" "$(sj "$state")" "$(sj "$ldate")" "$(sj "$llevel")" "$(n "$age")" "$(n "$files")" "$(n "$bytes")" "$(n "$drift")" "$(n "$skipped")" "$(n "$skacc")" "$(n "$skdep")" "$(sj "$trunc")" "$(sj "$hl")" "$(sj "$ho")" "$(n "$hr")" "$(n "$hh")" "$fl" "$(sj "$holds")" "$(sj "$members")" "$(sj "$redundancy")" "$(sj "$power")" "$(sj "$nextidx")" "$(sj "$source")"
  done < "$OUT/.devices.tsv"
  printf '],"unregistered":['
  first=1
  while IFS="$US" read -r k label d lv b; do
    [ "$first" = 1 ] || printf ','; first=0
    printf '{"index_folder":"%s","label":"%s","last_indexed_date":"%s","level":"%s","bytes_total":%s}' "$(je "$k")" "$(je "$label")" "$d" "$lv" "${b:-null}"
  done < "$OUT/.unreg.tsv"
  printf ']}\n'
} > "$OUT/storage.json"

# ---------- storage-map.md ----------
{
  echo "<!-- storage-map:begin (generated by $TOOL on $NOW; do not edit by hand) -->"
  echo "## Storage map: $SITE ($NOW)"; echo
  echo "| Device | Kind | State | Last indexed | Files | GiB | Health | Flags |"; echo "|---|---|---|---|--:|--:|---|---|"
  while IFS="$US" read -r id serial label kind state ldate llevel age files bytes drift skipped trunc hl ho hr hh flags holds members redundancy power nextidx source skacc skdep; do
    li="never"; [ -n "$ldate" ] && li="$ldate ${llevel:-?} (${age:-?} d)"
    g="?"; [ -n "$bytes" ] && g="$(gib "$bytes")"; hs="?"; [ -n "$hl" ] && hs="$hl/$ho, reads ${hr:-?}, ${hh:-?} h"
    echo "| ${label:-$id} (${serial:-no serial}) | $kind | $state | $li | ${files:-?} | $g | $hs | ${flags:--} |"
  done < "$OUT/.devices.tsv"
  echo
  pools="$(awk -F"$US" '$4=="pool"{print $1": "$21}' "$OUT/.devices.tsv")"
  [ -n "$pools" ] && { echo "Pools count as one failure domain (one copy), however much redundancy inside:"; echo "$pools" | sed 's/^/- /'; echo; }
  if [ -s "$OUT/.unreg.tsv" ]; then echo "Seen by the index tool but **not registered** (no manifest):"; while IFS="$US" read -r k label d lv b; do echo "- $k ($label), last indexed $d at $lv"; done < "$OUT/.unreg.tsv"; echo; fi
  echo "Levels: L0 top-level folders, L1 second level, L2 file list. Stale means not indexed for more than $STALE days. A device that is offline by design is not an alert; it goes to the visit list."
  echo "<!-- storage-map:end -->"
} > "$OUT/storage-map.md"

# ---------- visit-list.md ----------
{
  echo "# Visit list: $SITE ($NOW)"; echo
  echo "What to do when someone is at the site. Generated from the storage map; nothing here has been done."; echo
  cnt=0
  while IFS="$US" read -r id serial label kind state ldate llevel age files bytes drift skipped trunc hl ho hr hh flags holds members redundancy power nextidx source skacc skdep; do
    [ -n "$flags" ] || continue
    a="$(action "$flags" "$state" "$nextidx")"; [ -n "$a" ] || continue; cnt=$((cnt+1))
    extra=""; [ -n "$power" ] && extra=" Needs: $power."; [ -n "$holds" ] && extra="$extra Holds: $holds."; [ "$kind" = pool ] && extra="$extra Pool: one failure domain."
    echo "- [ ] **${label:-$id}** (${serial:-no serial}, $kind, $state): $a.$extra (flags: $flags; last indexed ${ldate:-never})"
  done < "$OUT/.devices.tsv"
  while IFS="$US" read -r k label d lv b; do cnt=$((cnt+1)); echo "- [ ] **$k** ($label): attached and indexed on $d but not registered: write its manifest (device_id, serial, role, tier)."; done < "$OUT/.unreg.tsv"
  [ "$cnt" = 0 ] && echo "Nothing to do: every registered device is indexed within $STALE days and shows no flags."
} > "$OUT/visit-list.md"
NDEV="$(wc -l < "$OUT/.devices.tsv" | tr -d ' ')"; NUN="$(wc -l < "$OUT/.unreg.tsv" | tr -d ' ')"
rm -f "$OUT/.devices.tsv" "$OUT/.unreg.tsv"
echo "== $SITE: $NDEV device(s), $NUN unregistered, written to $OUT (storage.json, storage-map.md, visit-list.md)"
exit 0
