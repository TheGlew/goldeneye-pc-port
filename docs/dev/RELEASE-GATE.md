# Release gate driver

`tools_pc/release_gate.sh` runs the automatable pre-release checks and prints one
PASS / FAIL / SKIPPED table. It wraps `verify.sh` (pixel gate) and `levelbench.sh`
(scripted run, clean-quit and crash-log detection); every run ends through
`GE_QUITFRAME`, nothing is hard-killed.

```sh
tools_pc/release_gate.sh --dry-run all       # print what would run
tools_pc/release_gate.sh win                 # sweep vs win goldens + fire smoke + exit path
tools_pc/release_gate.sh deck <host>         # 21 levels via deckrunner (shortcut must be up)
GE_MAC_DIR=<remote game dir> tools_pc/release_gate.sh mac <host>
```

Options: `--secs N` (per-level run length, default 30), `--out DIR`. Hosts and
paths come only from arguments or env (`GE_WIN_DIR`, `GE_DECK_HOST`,
`GE_MAC_HOST`, `GE_MAC_DIR`, `GE_MAC_EXE`, `GE_MAC_BUILD_CMD`,
`GE_GATE_SSH_OPTS`). The Deck pixel compare is reported SKIPPED (640x480
goldens vs 1280x800 dumps); Mac has no goldens, so it is crash-free only. The
fire smoke is `GE_INPUTSCRIPT` `MLB1`/`MLB0` (D597, the D595 regression).
Remote job, result and script files are deleted after the summaries are pulled.
