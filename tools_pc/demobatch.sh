#!/usr/bin/env bash
# demobatch.sh -- batch-replay maintainer-recorded pad demos through
# tools_pc/levelbench.sh --replay, collect frames / flicker flags / pacing
# stats, and write one report per batch. Sequential only (parallel runs
# invalidate frame pacing).
#
#   demobatch.sh [options] DEMODIR [ENV=VAL ...]
#     --dir GAMEDIR   game dir holding data/ (default: cwd)
#     --exe PATH      game binary (default: levelbench's autodetect)
#     --out ROOT      results root (default: <GAMEDIR>/demobatch/<YYYYMMDD-HHMMSS>)
#     --spot f1,f2    dump just these game frames (GE_PCDUMP lo-hi:step with
#                     step = gcd of the spacing; extra frames are deleted)
#     --flicker lo-hi dump every frame in the window, run flicker_scan.py
#                     (--spot and --flicker are mutually exclusive: one dump
#                     spec per run)
#     --only a,b      only these demo names (file name without .demo)
#     --dry-run       print the commands, launch nothing
#   demobatch.sh --compare ROOT_A ROOT_B
#                     side-by-side report rows with deltas for numeric columns
#
# Demo harness (maintainer workflow). Record once, per level:
#   tools_pc/levelbench.sh --dir <game dir> --secs N --record demos/<name>.demo <level>
# You play the level with the pad; input is saved to the .demo and a
# <name>.demo.meta (level, secs, seed, binary md5, date) is written beside it.
# Demos live in <game dir>/demos/ -- personal input recordings, gitignored,
# never committed. Then `demobatch.sh --dir <game dir> <game dir>/demos`
# replays each with the recorded level/secs/seed (GE_RSEED pinned) and writes
# <ROOT>/report.txt. Replays drift slightly (D117): compare runs within one
# session (--compare), never as pixel gates. Extra ENV=VAL args go to every run.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
absdir() { (cd "$1" 2>/dev/null && pwd); }

compare() {
    local A=$1/report.txt B=$2/report.txt
    if [ ! -f "$A" ] || [ ! -f "$B" ]; then echo "missing report.txt in $1 or $2" >&2; exit 2; fi
    awk '
    function d(a, b) {
        if (a ~ /^-?[0-9.]+$/ && b ~ /^-?[0-9.]+$/) return sprintf("%+.2f", b - a)
        return "-"
    }
    FNR == NR { if ($1 != "name" && NF >= 9) { a[$1] = $0; order[++n] = $1 } next }
    $1 != "name" && NF >= 9 { b[$1] = $0 }
    END {
        f = "%-16s %-5s | %-5s %-5s | %-4s %-4s %-6s | %-8s %-8s %-7s | %-6s %-6s %-6s | %-5s %-5s %-6s\n"
        printf f, "name", "level", "exitA", "exitB", "wdA", "wdB", "dWd", "pres/sA", "pres/sB", "dPres", "unevA", "unevB", "dUnev", "slowA", "slowB", "dSlow"
        for (i = 1; i <= n; i++) {
            k = order[i]
            split(a[k], x, " ")
            if (!(k in b)) { printf "%-16s (only in A)\n", k; continue }
            split(b[k], y, " ")
            printf f, k, x[2], x[3], y[3], x[5], y[5], d(x[5], y[5]), x[6], y[6], d(x[6], y[6]), x[7], y[7], d(x[7], y[7]), x[8], y[8], d(x[8], y[8])
            if (x[9] != y[9]) printf "%-16s   flicker flags: %s -> %s (%s)\n", "", x[9], y[9], d(x[9], y[9])
        }
        for (k in b) if (!(k in a)) printf "%-16s (only in B)\n", k
    }' "$A" "$B"
}

if [ "${1:-}" = --compare ]; then
    [ $# -eq 3 ] || { echo "usage: $0 --compare ROOT_A ROOT_B" >&2; exit 2; }
    compare "$2" "$3"; exit 0
fi

GAME=$PWD; EXE=; OUT=; SPOT=; FLK=; ONLY=; DRY=0
while [ $# -gt 0 ]; do
    case $1 in
        --dir) GAME=$2; shift 2;;
        --exe) EXE=$2; shift 2;;
        --out) OUT=$2; shift 2;;
        --spot) SPOT=$2; shift 2;;
        --flicker) FLK=$2; shift 2;;
        --only) ONLY=$2; shift 2;;
        --dry-run) DRY=1; shift;;
        -h|--help) sed -n 2,26p "$0"; exit 0;;
        *) break;;
    esac
done
[ $# -ge 1 ] || { echo "usage: $0 [options] DEMODIR [ENV=VAL ...]" >&2; exit 2; }
DEMODIR=$1; shift
if [ -n "$SPOT" ] && [ -n "$FLK" ]; then echo "--spot and --flicker are mutually exclusive" >&2; exit 2; fi
[ -d "$DEMODIR" ] || { echo "no demo dir: $DEMODIR" >&2; exit 2; }
GAME=$(absdir "$GAME") || { echo "bad --dir" >&2; exit 2; }
DEMODIR=$(absdir "$DEMODIR")
[ -n "$OUT" ] || OUT="$GAME/demobatch/$(date +%Y%m%d-%H%M%S)"
case $OUT in /*|[A-Za-z]:*) ;; *) OUT=$PWD/$OUT;; esac

# Dump spec: spot frames -> lo-hi:step (step = gcd of gaps); flicker -> lo-hi.
DUMP=; SPOTLIST=
if [ -n "$SPOT" ]; then
    SPOTLIST=$(echo "$SPOT" | tr ',' '\n' | sort -n -u | tr '\n' ' ')
    read -r -a FR <<< "$SPOTLIST"
    lo=${FR[0]}; hi=${FR[$((${#FR[@]} - 1))]}; g=0
    for ((i = 1; i < ${#FR[@]}; i++)); do
        a=$((FR[i] - FR[i-1])); b=$g
        while [ "$b" -ne 0 ]; do t=$((a % b)); a=$b; b=$t; done
        g=$a
    done
    DUMP="$lo-$hi"
    [ "$g" -gt 1 ] && DUMP="$lo-$hi:$g"
elif [ -n "$FLK" ]; then
    DUMP=$FLK
fi

LB=("$HERE/levelbench.sh" --dir "$GAME")
[ -n "$EXE" ] && LB+=(--exe "$EXE")
PY=
for c in python3 python py; do
    if command -v "$c" > /dev/null 2>&1 && "$c" -c 'import sys' > /dev/null 2>&1; then PY=$c; break; fi
done
[ -n "$PY" ] || PY=python3
[ "$DRY" = 1 ] || mkdir -p "$OUT"

metaget() { sed -n "s/^$2=//p" "$1" | head -1 | tr -d '\r'; }

NAMES=()
for demo in "$DEMODIR"/*.demo; do
    [ -f "$demo" ] || continue
    n=$(basename "$demo" .demo)
    if [ -n "$ONLY" ]; then case ",$ONLY," in *",$n,"*) ;; *) continue;; esac; fi
    if [ ! -f "$demo.meta" ]; then echo "skip $n: no $n.demo.meta" >&2; continue; fi
    NAMES+=("$n")
    lvl=$(metaget "$demo.meta" level); secs=$(metaget "$demo.meta" secs); seed=$(metaget "$demo.meta" seed)
    CMD=("${LB[@]}" --secs "$secs" --replay "$demo" --out "$OUT/$n")
    [ -n "$DUMP" ] && CMD+=(--dump "$DUMP")
    CMD+=("$lvl" "GE_RSEED=${seed:-0123456789abcdef}" "$@")
    if [ "$DRY" = 1 ]; then
        echo "[$n] ${CMD[*]}"
        [ -n "$SPOTLIST" ] && echo "[$n]   then keep only frames: $SPOTLIST"
        [ -n "$FLK" ] && echo "[$n]   then: $PY -I $HERE/flicker_scan.py $OUT/$n/ppm --csv $OUT/$n/flicker.csv"
        continue
    fi
    echo "=== $n (level $lvl, ${secs}s)"
    "${CMD[@]}" > "$OUT/$n.console" 2>&1
    tail -3 "$OUT/$n.console"
    if [ -n "$SPOTLIST" ] && [ -d "$OUT/$n/ppm" ]; then
        for f in "$OUT/$n"/ppm/frame_*.ppm; do
            [ -e "$f" ] || continue
            num=$((10#$(basename "$f" .ppm | sed 's/frame_//')))
            case " $SPOTLIST " in *" $num "*) ;; *) rm -f "$f";; esac
        done
    fi
    if [ -n "$FLK" ] && [ -d "$OUT/$n/ppm" ]; then
        "$PY" -I "$HERE/flicker_scan.py" "$OUT/$n/ppm" --csv "$OUT/$n/flicker.csv" > "$OUT/$n/flicker.txt" 2>&1
        tail -1 "$OUT/$n/flicker.txt"
    fi
done
if [ "$DRY" = 1 ]; then echo "(dry run: no report written; root would be $OUT)"; exit 0; fi

# ---- report ----------------------------------------------------------------
# presents/s: mean over "D578 interp: X presents/s, ..." lines.
# uneven%: from "D578 cadence: gaps <7:a 7-9.5:b 9.5-12:c 12-20:d >20:e | ...",
# bucket counts summed over all lines; uneven = share outside the modal bucket.
R="$OUT/report.txt"
fmt="%-16s %-5s %-5s %-5s %-9s %-10s %-8s %-5s %-7s\n"
{
printf "$fmt" name level exit crash watchdog presents/s uneven% slow flicker
for n in "${NAMES[@]}"; do
    d="$OUT/$n"; L="$d/ge007.log"; [ -f "$L" ] || L="$d/stdout.txt"
    lvl=$(metaget "$DEMODIR/$n.demo.meta" level)
    ex=n; crash=n; wd=0; slow=0; stats="- -"
    if [ -f "$L" ]; then
        grep -q -E 'quit requested|video: exiting' "$L" && ex=y
        wd=$(grep -c 'no frame rendered' "$L")
        slow=$(grep -c 'D583 SLOW' "$L")
        stats=$(awk '
            /D578 interp:/ { for (i = 2; i <= NF; i++) if ($i ~ /^presents\/s/) { p += $(i-1); pn++ } }
            /D578 cadence:/ {
                for (i = 1; i <= NF; i++) if ($i == "gaps") {
                    for (j = 1; j <= 5; j++) { s = $(i + j); sub(/^.*:/, "", s); g[j] += s + 0 }
                    break
                }
            }
            END {
                tot = 0; mx = 0
                for (j = 1; j <= 5; j++) { tot += g[j]; if (g[j] > mx) mx = g[j] }
                printf "%s %s", (pn ? sprintf("%.1f", p / pn) : "-"), (tot ? sprintf("%.1f", 100 * (tot - mx) / tot) : "-")
            }' "$L")
    fi
    [ -f "$d/ge007.crash.log" ] && crash=y
    fl=-; [ -f "$d/flicker.txt" ] && fl=$(grep -c '^FLICKER' "$d/flicker.txt")
    printf "$fmt" "$n" "${lvl:--}" "$ex" "$crash" "$wd" "${stats% *}" "${stats#* }" "$slow" "$fl"
done
} > "$R"
cat "$R"
echo "report: $R"
