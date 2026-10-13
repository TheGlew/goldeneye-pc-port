#!/usr/bin/env bash
# release_gate.sh -- run the automatable release checks per platform and print
# one PASS/FAIL/SKIPPED table. Reuses verify.sh (pixel gate) and levelbench.sh
# (scripted run + clean-quit + crash-log detection); invents no new harness.
#
#   release_gate.sh [--dry-run] [--secs N] [--out DIR] <win|deck HOST|mac HOST|all>
#
#   win          verify.sh sweep --platform win (pixel gate vs goldens/<lvl>/win)
#                + scripted-fire smoke on -level_09 (GE_INPUTSCRIPT MLB1/MLB0,
#                  the D595/D597 regression) + exit-path check (rc 0 through
#                  GE_QUITFRAME, "quit requested" log line, no ge007.crash.log)
#   deck HOST    queue 21 levelbench jobs through deckrunner (Steam shortcut must
#                be running on the Deck), crash-free + clean-quit + fps summary.
#                Pixel compare is SKIPPED (deck goldens 640x480 vs 1280x800 dumps).
#   mac HOST     over ssh: optional build, 21-level crash-free sweep + fire smoke.
#                No goldens exist -> crash-free only.
#   all          every platform that is configured (HOSTs from env), else SKIPPED.
#
# Environment (no defaults are machine-specific):
#   GE_WIN_DIR     game dir for the Windows runs (default: <repo>/build-pc, has data/)
#   GE_DECK_HOST / GE_MAC_HOST   ssh targets for `all` (or pass as argument)
#   GE_MAC_DIR     remote game dir on the Mac (binary + data/); required for mac
#   GE_MAC_EXE     remote binary name inside GE_MAC_DIR (default: ge007)
#   GE_MAC_BUILD_CMD  optional command run in GE_MAC_DIR before the sweep
#   GE_GATE_SSH_OPTS  extra ssh/scp options
# Every run ends through GE_QUITFRAME (levelbench sets it); nothing is hard-killed.
# Remote temp/result files are removed after results are pulled.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DRY=0; SECS=30; OUT=; MODE=; HOST=
while [ $# -gt 0 ]; do
    case $1 in
        --dry-run) DRY=1; shift;;
        --secs) SECS=$2; shift 2;;
        --out) OUT=$2; shift 2;;
        -h|--help) sed -n 2,26p "$0"; exit 0;;
        win|all) MODE=$1; shift;;
        deck|mac) MODE=$1; HOST=${2:-}; shift; [ $# -gt 0 ] && shift;;
        *) echo "unknown argument: $1" >&2; exit 2;;
    esac
done
[ -n "$MODE" ] || { sed -n 2,6p "$0" >&2; exit 2; }
[ -n "$OUT" ] || OUT="$ROOT/scratch/release-gate-$(date +%Y%m%d-%H%M%S)"
LEVELS="33 34 35 36 09 20 26 43 27 22 24 29 30 25 37 23 39 41 28 32 54"
FIRE='1500:START;6000:MLB1;14000:MLB0'
SSHO=${GE_GATE_SSH_OPTS:-}
ROWS=(); FAILS=0
row() { [ $DRY = 1 ] && [ "$3" = PASS ] && set -- "$1" "$2" DRY "$4"; ROWS+=("$1|$2|$3|$4"); [ "$3" = FAIL ] && FAILS=$((FAILS + 1)); }
run() { if [ $DRY = 1 ]; then echo "+ $*"; return 0; fi; "$@"; }
if [ $DRY = 1 ]; then OUT=$(mktemp -d); trap 'rm -rf "$OUT"' EXIT; else mkdir -p "$OUT"; fi

# judge_summary FILE -> "PASS" or "FAIL:<why>" from a levelbench summary.txt
judge_summary() {
    local f=$1
    [ -s "$f" ] || { echo "FAIL:no summary"; return; }
    grep -q '^exit=0$' "$f" || { echo "FAIL:rc $(grep -m1 '^exit=' "$f" | cut -d= -f2)"; return; }
    grep -q 'CRASH LOG PRESENT' "$f" && { echo "FAIL:crash log"; return; }
    grep -q 'no clean quit line' "$f" && { echo "FAIL:no clean quit"; return; }
    echo PASS
}

gate_win() {
    local d=${GE_WIN_DIR:-$ROOT/build-pc} v rc
    echo "== win: pixel sweep"
    if [ $DRY = 1 ]; then
        echo "+ $ROOT/tools_pc/verify.sh sweep --platform win"; rc=0
    else
        "$ROOT/tools_pc/verify.sh" sweep --platform win | tee "$OUT/win-sweep.txt"; rc=${PIPESTATUS[0]}
    fi
    if [ $rc = 0 ]; then row win "verify.sh sweep (21 lvls vs win goldens)" PASS ""
    else row win "verify.sh sweep (21 lvls vs win goldens)" FAIL "rc $rc, see win-sweep.txt"; fi
    echo "== win: scripted-fire smoke + exit path (level 09)"
    run "$ROOT/tools_pc/levelbench.sh" --dir "$d" --secs "$SECS" --script "raw:$FIRE" \
        --out "$OUT/win-fire" 09
    if [ $DRY = 1 ]; then v=PASS; else v=$(judge_summary "$OUT/win-fire/summary.txt"); fi
    if [ "$v" = PASS ]; then
        row win "fire smoke -level_09 (MLB1/MLB0)" PASS ""
        row win "exit path (rc 0 via GE_QUITFRAME, no crash log)" PASS ""
    else
        row win "fire smoke / exit path -level_09" FAIL "${v#FAIL:}"
    fi
}

gate_mac() {
    local h=${HOST:-${GE_MAC_HOST:-}} dir=${GE_MAC_DIR:-} exe=${GE_MAC_EXE:-ge007} l v bad=0 badl=
    if [ -z "$h" ] || [ -z "$dir" ]; then
        row mac "all checks" SKIPPED "no host (arg/GE_MAC_HOST) or GE_MAC_DIR"; return
    fi
    # shellcheck disable=SC2086  # SSHO is an option list
    run scp $SSHO "$ROOT/tools_pc/levelbench.sh" "$h:$dir/levelbench.sh"
    # shellcheck disable=SC2086
    [ -n "${GE_MAC_BUILD_CMD:-}" ] && run ssh $SSHO "$h" "cd '$dir' && $GE_MAC_BUILD_CMD"
    for l in $LEVELS; do
        # shellcheck disable=SC2086
        run ssh $SSHO "$h" "cd '$dir' && bash levelbench.sh --dir . --exe './$exe' --secs $SECS --script 'raw:$FIRE' --out gate-$l $l >/dev/null 2>&1; cat gate-$l/summary.txt; rm -rf gate-$l" \
            > "$OUT/mac-$l.txt" 2>&1
        [ $DRY = 1 ] && continue
        v=$(judge_summary "$OUT/mac-$l.txt")
        [ "$v" = PASS ] || { bad=$((bad + 1)); badl="$badl $l(${v#FAIL:})"; }
    done
    # shellcheck disable=SC2086
    run ssh $SSHO "$h" "cd '$dir' && rm -rf levelbench.sh gate-* ppm ge007.crash.log"
    if [ $bad = 0 ]; then row mac "21-level crash-free + fire smoke" PASS ""
    else row mac "21-level crash-free + fire smoke" FAIL "$bad bad:$badl"; fi
    row mac "pixel compare" SKIPPED "no mac goldens exist"
}

gate_deck() {
    local h=${HOST:-${GE_DECK_HOST:-}} l n=0 v bad=0 badl= name t pre last max
    if [ -z "$h" ]; then row deck "all checks" SKIPPED "no host (arg/GE_DECK_HOST)"; return; fi
    echo "== deck: checking for duplicate deckrunner instances"
    if [ $DRY = 1 ]; then echo "+ ssh $h pgrep -af deckrunner.sh"; else
        # shellcheck disable=SC2086
        ssh $SSHO "$h" 'pgrep -af deckrunner.sh' || true
        echo "(if more than one deckrunner.sh is listed, stop the extras before continuing)"
    fi
    # shellcheck disable=SC2086
    run scp $SSHO "$ROOT/tools_pc/levelbench.sh" "$h:levelbench.sh"
    pre="gate$(date +%H%M%S)"
    for l in $LEVELS; do
        n=$((n + 1)); name=$(printf '%s-%03d-%s' "$pre" "$n" "$l")
        # shellcheck disable=SC2086
        run ssh $SSHO "$h" "mkdir -p ~/lb/queue && echo '--secs $SECS --script fight $l' > ~/lb/queue/$name.job"
    done
    # the runner is serial; wait for the last job's .finished marker
    last=$(printf '%s-%03d-%s' "$pre" 21 54); t=0; max=$((21 * (SECS + 60)))
    if [ $DRY = 1 ]; then echo "+ poll: ssh $h test -e ~/lb/$last.finished (timeout ${max}s)"; else
        # shellcheck disable=SC2086
        until ssh $SSHO "$h" "test -e ~/lb/$last.finished" 2>/dev/null; do
            sleep 10; t=$((t + 10))
            [ $t -ge $max ] && { echo "deck: timed out waiting (is the deckrunner shortcut running?)" >&2; break; }
        done
    fi
    n=0
    for l in $LEVELS; do
        n=$((n + 1)); name=$(printf '%s-%03d-%s' "$pre" "$n" "$l")
        # shellcheck disable=SC2086
        run ssh $SSHO "$h" "cat ~/lb/$name/summary.txt" > "$OUT/deck-$l.txt" 2>&1
        [ $DRY = 1 ] && continue
        v=$(judge_summary "$OUT/deck-$l.txt")
        [ "$v" = PASS ] || { bad=$((bad + 1)); badl="$badl $l(${v#FAIL:})"; }
    done
    # shellcheck disable=SC2086
    run ssh $SSHO "$h" "rm -rf ~/lb/$pre-* ~/lb/done/$pre-* ~/levelbench.sh"
    if [ $bad = 0 ]; then row deck "21-level crash-free + clean quit" PASS ""
    else row deck "21-level crash-free + clean quit" FAIL "$bad bad:$badl"; fi
    row deck "levelbench fps summary" INFO "D578 cadence / D583 SLOW lines in deck-<lvl>.txt"
    row deck "pixel compare" SKIPPED "deck goldens 640x480 vs 1280x800 dumps (known v0.7.0 item)"
}

case $MODE in
    win) gate_win;;
    deck) gate_deck;;
    mac) gate_mac;;
    all) gate_win; gate_deck; gate_mac;;
esac

echo
echo "=== RELEASE GATE ($([ $DRY = 1 ] && echo dry-run || echo "$OUT")) ==="
printf '%-5s %-52s %-8s %s\n' PLAT CHECK RESULT NOTE
for r in "${ROWS[@]}"; do
    IFS='|' read -r a b c d <<<"$r"
    printf '%-5s %-52s %-8s %s\n' "$a" "$b" "$c" "$d"
done
if [ $FAILS = 0 ]; then echo "OVERALL: no failures"; else echo "OVERALL: $FAILS FAIL"; fi
[ $FAILS = 0 ]
