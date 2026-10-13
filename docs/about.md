---
title: About the project
description: Release history, how the GoldenEye 007 PC port was made, how it works, and how it differs from the other GoldenEye PC projects.
---

# About the project

- [Release history](#release-history)
- [Status in detail](#status-in-detail)
- [How it was made](#how-it-was-made)
- [How it works](#how-it-works)
- [How this differs from the other GoldenEye PC projects](#how-this-differs-from-the-other-goldeneye-pc-projects)


## Release history

The full notes for each version are on the [Releases page](https://github.com/jkdansereau/goldeneye-pc-port/releases).

- **2026-10-13** — **v0.6.0** ([release notes](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.6.0)):
  - **Frame rates above 60.** `Video.FpsCap` now offers 90, 120, 144, 165 and
    240, and an **Auto** setting (the new default on fresh installs) that
    matches your display's refresh rate, up to 240. Frames between game ticks are blended from the
    previous and current frame; the game still simulates at its original
    rate. It costs one game tick of extra latency, does nothing on a 60 Hz
    display, and the *Original N64* preset caps at 60. This is a rework of
    f1zz1ec0ke's #137. I checked 120 Hz with VSync on a G-Sync display
    on PC and 90 fps on the Steam Deck.
  - **macOS on Apple Silicon (experimental).** There is now a `macos-arm64`
    download (or build from source; see [Building](building.md)). Based
    on danturn's #95 (with Julio C. Rocha's earlier Intel groundwork in
    #88). Tested with a 21-level sweep and live sessions on one M3 Mac (the
    one crash seen, in the end credits, is guarded in this release); the download is not notarized, so see [macOS](user-guide.md#macos-apple-silicon-experimental)
    for the one-line unblock. Test reports are very welcome.
  - **Fixes:** geometry vanishing when you press against a wall (#150),
    the first launch opening on the wrong monitor (#151), a crash in the end
    credits on Linux and macOS (#152), a crash when a guard spawns with a hat (#153, #156), a
    sound/text pointer check that rejected valid pointers (#108), a Cradle
    catwalk shadow flicker, stale pixels beside the widescreen picture on
    front-end screens, and a black window on macOS when the game was started
    with the display asleep.
  - **Original controls (#145, #149):** with *Control style* set to Original,
    a gamepad now behaves as an N64 controller (South = A, West = B, the game
    decides what each does), and *Invert look* works in every original style.
    Also an optional mission timer (#144), the file-select crest no longer
    drawing on a dark square (#146), and a fix for a Windows blue screen on
    exit.
  - **Smaller changes:** the legacy front-end Velocity pointer mode is gone,
    the Linux/macOS update check no longer fails on a large response, every
    run is also logged to `ge007.log` next to the ini, and F10 slider labels
    fit at HUD 150.
  - **Known issues on the Steam Deck at 90 fps:** firefights in the centre of
    Bunker 1 and 2 can drop several fps, and Jungle can feel slightly less
    smooth than other levels. Cradle's turret explosions may draw wrongly
    (reported, not yet investigated).
- **2026-10-07** — **v0.5.0** ([release notes](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.5.0)), the first release
  since v0.4.0; it includes the v0.4.1 work, which was never published on
  its own:
  - **Split-screen multiplayer for up to 4 players**, each player with their
    own pad, controls and aim settings.
  - **One options menu** for every setting, laid out like the Perfect Dark
    port's, with the game's own crosshair as the mouse pointer. Pick the
    game's own N64 control styles (1.1–2.4) per player, or the Xbox release's
    presets with per-player pad rebinding; PlayStation and Nintendo pads show
    their own button names.
  - **Closer to the N64:** fog and haze (Surface 2's ground fog, the sky at
    the horizon), automatic-weapon fire rate, sniper and camera zoom, Dam and
    Caverns water, the Jungle boss fight's timing, guard visibility in
    widescreen, and the Dam ending camera.
  - **Fewer crashes and glitches:** a multiplayer crash with the crouched
    rifle, rockets passing through the ground, and broken geometry around
    Aztec's shuttle.
  - **A steady 60 fps on low-end GPUs** (tested on an Intel HD 3000 laptop),
    with lighter first-launch defaults on Atom/Celeron-class graphics.
  - **Emulator saves load directly:** copy a 1964 or Project64 save in as
    `data/ge007.eep` and it is converted on first launch.
  - Also: more audio, video and control settings (master volume, audio device,
    trilinear filtering, draw distance up to 800%, PC-friendly crouch and
    look-ahead defaults), and controllers are picked up again when replugged.
- **2026-09-28** — **v0.4.0**: native widescreen, a complete aim system for
  mouse and controller, in-game key rebinding, crosshair customization,
  rumble-pak haptics, a rebuilt options overlay, and a broad fidelity-fix
  pass (water, particles, billboard trees, front-end logo, gunshot SFX, a
  true stable 60 fps). [Release notes](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.4.0).
- **2026-09-20** — **v0.3.0**: the first release with the complete campaign
  playable end to end at 60 fps on Windows, Linux, and Steam Deck.
  [Release notes](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.3.0).
- **2026-09-04 → 2026-09-16** — **v0.1.0 – v0.2.2**: the alpha and beta
  cycle: build chain, software RSP, first rendered frames, front end, and
  per-level stabilization across the campaign.

## Status in detail

**Fully playable, with a small set of known caveats.** All 20 solo missions
and the end-of-campaign credits load, render and run crash-free. For v0.6.0
the release downloads themselves were tested on Windows, Steam Deck (Desktop
and Game Mode), macOS on Apple Silicon and a 2011 Linux laptop: a fresh
folder with only the ROM, a first launch, then all 21 solo levels. The new frame-rate path and the listed fixes were also checked by
playing on Windows and the Steam Deck. The full campaign was last played end
to end, at Agent difficulty on Windows, Linux and the Deck, for v0.4.0.
Split-screen was played live in 2P on every multiplayer map and in 4P on
Temple.

**Known issues:** see the **[known-issues table](ROADMAP.md#known-issues)**
(what you'll notice, impact, workarounds). The short version: NTSC-U ROMs
only in the release packages, and the Apple Silicon macOS download is
experimental and not notarized. On the Steam Deck at 90 fps, Bunker 1/2
centre firefights can drop several fps and Jungle can feel slightly less smooth
than other levels.

> ***All unlocked* never changes your save** since v0.5.0: it unlocks every
> level and cheat in memory only, and switching it off shows your real
> progress. v0.4.0 and earlier could write fake unlocks into the save, and
> those are not repaired; if you used it on an older build, keep a backup of
> `data/ge007.eep`.

What a release installs (no networking unless you turn on the opt-in update check, which is off by default and makes one HTTPS request to GitHub per launch; no telemetry, no ROM or game assets)
and how faithfully the port tracks the original game's logic:
[Security](security.md) and [fidelity](fidelity.md) status.
The binaries are not code-signed; from v0.5.0 on each release artifact also
carries a GitHub build-provenance attestation you can check with
`gh attestation verify <file> --repo jkdansereau/goldeneye-pc-port`
(see [SECURITY.md](../.github/SECURITY.md)).

## How it was made

The port was built by several coding agents directed by one maintainer, with
contributions from a handful of people (credited in the release notes).
A local open-weight model (`unsloth/Qwen3.8-27B-GGUF` on one RTX 5090, via the
[pi](https://github.com/earendil-works/pi) agent) did the groundwork: build, boot chain,
software-RSP integration, asset pipeline, first frames. **Claude Code**
(Sonnet 5 and Opus 5, now 5.5; Opus for the hardest bugs) joined for the collaborative phase:
the 21-level sweep, the ABI finding catalog, SDL input, front end. The two
handed work back and forth through shared written notes. Up to v0.5.0: 51
days (16 Aug – 6 Oct), 1,537 commits (the public history squashes the
v0.4.1–v0.5.0 work into 17), and 419 findings root-caused and logged
(`D1`–`D564`). Every change is checked by comparing captured frames from all
21 solo levels against reference images, crash sweeps on Windows, Linux,
Steam Deck and macOS, and play-testing; there is no unit-test suite.

The full write-up (timeline, handoff mechanism, effort breakdown, an honest
"what worked / what didn't"): [`docs/dev/agentic-development.md`](dev/agentic-development.md).
The workflow itself: [`docs/dev-process.md`](dev-process.md). To cite the
project or its findings: [`CITATION.cff`](../CITATION.cff) (GitHub's "Cite this
repository" menu).

### Tools and models used to develop the port

Development ran for most of its life on a single local model — **Unsloth's
Qwen 3.8 27B** — which did nearly all of the local (groundwork) work on its
own. In the final week that grew into a small menu, and the **current standard
is NInfer + Strata**; tools are chosen per task, with local models carrying
the high-volume work and hosted models the exception. The full record of the
models used, and the harnesses that drove them:

| Model | Ran as | How it was used |
|---|---|---|
| **Qwen 3.8 27B** ([Unsloth](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF)) | `UD-Q4_K_XL`, one RTX 5090 | The primary local workhorse for the bulk of the port's development. |
| **Qwen 3.8 27B** via [NInfer](https://github.com/natpate/ninfer-windows) (Windows) | base, NVFP4 and NVFP4-full artifacts; MTP (DFlash2) spec-decode; one 5090 | Trialed in the final week, now half of the standard; the fast day-to-day local driver. |
| **Qwen 3.8 27B** ([ISTA-DASLab](https://huggingface.co/ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF)) | `IQ3_S` (GSQ-RCO), larger context | Briefly trialed for larger-context workloads; shelved, little use since v0.2.0. |
| **Qwen 3.8 Flash-Next** via [Strata](https://github.com/Niko1221/Strata) | 125B MoE, `IQ1_M` (1-bit), one gaming GPU | The big-context local tier: a model that normally needs a server, run locally for the largest-context passes. |
| **Claude** (Anthropic) | Sonnet 5 / Opus 5, now **Sonnet 5.5 / Opus 5.5** (out in the last few weeks) | The orchestrator in the two-agent phase: held what the 27B couldn't close, took over on limit handoff; the 5.5 tier has driven the most recent work. |
| **GPT-6 (Sol)** (OpenAI), via [OpenRouter](https://openrouter.ai) | a frontier hosted model | Trialed. |

*Harnesses and tooling:*

- **[pi](https://github.com/earendil-works/pi)** — the local coding-agent
  harness that drives the local models.
- **[Claude Code](https://github.com/anthropics/claude-code)** (Anthropic) —
  the agentic harness that drove the Claude models above; the orchestrator in
  the two-agent phase.
- **[claude-code-delegate-local](https://github.com/fegone/claude-code-delegate-local)** —
  the MCP bridge that let Claude and the local models talk (delegating Claude's
  subagents to the local engines).

## How it works

The game code in `src/` is the decompilation's, and its control flow is the
reference we preserve. Everything that would touch N64 hardware is redirected into
`port/`: a **software RSP** (`port/fast3d/`, adapted from the Perfect Dark
port) that interprets the graphics command stream (the GBI display list)
the game builds each frame and
emits OpenGL, bypassing the RDP; libultra OS shims (`port/src/libultra.c`,
game threads as real host threads) that let the game's own scheduler run,
with the software RSP on its own render thread as the RSP was its own chip;
and SDL2/OpenGL/filesystem backends for video, audio, input and storage.
Every port change inside `src/` is gated behind `#ifdef PORT` and
documented. They are few in kind, all narrow in scope: mechanical 32→64-bit
pointer/struct fixes (the pointer-width transition touches many structs, so
there are a lot of them), a few maintainer-approved timing fixes where
per-frame N64 code ran too fast at the PC's 60 fps (for example sniper zoom
and turret fire), the opt-in *All unlocked* hook, and env-gated diagnostic
probes tied to the bug catalogue (off by default, no behavior change). Where it diverges from the Perfect Dark port: GoldenEye's N64
serialized asset formats are converted in a separate step rather than
fixed up at load time — on first start for a download, or by the offline
Python converters in `tools_pc/` for a source build. Full detail:
[`docs/internals.md`](internals.md) and
[`docs/porting-notes.md`](porting-notes.md).

```
CMakeLists.txt      PC build (parallel to the decomp's Makefile, which is untouched)
build-pc.sh         configure + build helper
src/  include/      the decompilation (game + libultra); port edits are #ifdef PORT
port/
  fast3d/           software RSP -> OpenGL
  src/              port layer (main, OS shims, video, audio, input, fs, ...)
  include/          port-facing headers
tools/  Makefile    the N64 build + asset extraction (from the decomp; do not modify)
tools_pc/           PC-port helper + analysis scripts
docs/               see below
```

## How this differs from the other GoldenEye PC projects

This is a native port of the original 1997 Nintendo 64 game, built from its
reconstructed source code, the same lineage as the Perfect Dark PC port.
Other GoldenEye PC projects take a different approach: they statically
recompile the Xbox 360 XBLA remaster, a separate version of the game with its
own codebase. The two don't share code, and they target different versions
of the game.

| | This project | The XBLA recompilation projects |
|---|---|---|
| **What it ports** | The original **Nintendo 64** game (1997) | The **Xbox 360 XBLA** remaster |
| **How** | Decompilation-based source port: reconstructed C, compiled for the host | Static recompilation of the Xbox 360 executable |
| **Lineage** | [GoldenEye 007 decompilation](https://github.com/n64decomp/007) + [Perfect Dark PC port](https://github.com/fgsfdsfgs/perfect_dark) engine family | The Xbox 360 static-recompilation family |
