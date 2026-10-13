# GoldenEye 007 PC Port — v<version>

<p align="center">
  <img src="https://github.com/jkdansereau/goldeneye-pc-port/raw/v<version>/docs/img/shots/feature-splitscreen.jpg" width="340" alt="2-player split-screen multiplayer in the port">
  <img src="https://github.com/jkdansereau/goldeneye-pc-port/raw/v<version>/docs/img/shots/feature-options.jpg" width="340" alt="The PC options menu: custom crosshair colour sliders">
</p>

Platforms: **Windows x86-64** and **Linux x86-64 (including Steam Deck)**, plus
an **experimental macOS Apple Silicon** download (not notarized; see
[Running it](#running-it)). Region: **NTSC-U (US) only**. See [Known issues](#known-issues).

## Highlights

This release is v0.5.0 plus frame rates above 60, an experimental macOS port
and a batch of fixes.

- **Frame rates above 60.** The *Frame rate cap* (`Video.FpsCap`) now offers
  **90, 120, 144, 165 and 240**, and an **Auto** setting that matches your
  display's refresh rate (up to 240; 165 and 240 have had less testing than
  90 to 144). Auto is the default on fresh installs; an existing
  `ge007.ini` keeps its value. Extra frames are blended between game ticks, so
  the game still simulates at its original rate. It costs one game tick of
  extra latency, does nothing on a 60 Hz display, and the *Original N64*
  display mode caps at 60. This is my rework of f1zz1ec0ke's #137.
- **macOS on Apple Silicon (experimental).** There is now a
  `macos-arm64` download (or build from source; see `docs/building.md`). Based
  on danturn's #95. A 21-level campaign sweep and live sessions ran without
  crashes on one M3 Mac, but it has not had the wider testing the Windows and
  Linux builds have, and the download is not notarized. Test reports are very
  welcome.
- **Fixes you can see:** geometry vanishing when you stand against a wall
  (#150), the Cradle catwalk shadow flicker, stale pixels beside the
  native-widescreen picture on front-end screens, and the first launch opening
  on the wrong monitor (#151).
- **Crash fixes:** the Linux end-credits crash (#152) and a crash when a guard
  spawned wearing a hat (#153, #156).
- **Original controls are now original (#145, #149).** With *Control style*
  set to Original, a gamepad behaves as an N64 controller: South is A, West is
  B, and the game decides what each button does, so B opens a door or reloads
  (not both), A changes weapon, and B goes back in menus. *Invert look* works in
  every original style and stays in sync with the watch's *Look up/down*.
- **Mission timer (#144)**, the file-select crest drawing on a dark square
  (#146), and a fix for a Windows exit crash.

Checked on PC at 120 Hz with VSync on a G-Sync display, and on the Steam Deck
at 90 fps.

---

## What's new

### Frame rate

- **Auto, 90, 120, 144, 165 and 240** join 30 and 60 in the F10 *Frame rate cap* row.
  Above 60 the port draws extra frames between game ticks by blending the
  previous and current frame. It only applies when the display is faster than
  60 Hz; on a 60 Hz display nothing changes.
- A fresh install uses **Auto**, so a 90 Hz screen runs at 90, a 144 Hz
  monitor at 144 and a 240 Hz monitor at 240 (faster displays hold at 240).
  The *Original N64* display mode sets the cap to 60.
- A fast camera turn, or a large change in what is on screen, falls back to a
  full frame instead of a blend.
- The Steam Deck at 90 is good on most levels (see the known issues).

### macOS (Apple Silicon, experimental)

- On arm64 macOS the N64 address window sits at a high host base (set
  automatically by CMake). The 64-bit address fixes this needed (textures,
  input, animation and multiplayer crashes) are in the shared code and have no
  effect at base 0 on Windows and Linux.
- There is a `macos-arm64` download, or build from source with Homebrew's
  GNU `gcc`. The x86_64 macOS code (Julio C. Rocha's #88) is in the tree but was never
  verified on Intel hardware.

### Controls

- **Original control style = an N64 controller** (D643). Every press sends the
  real N64 button in levels, menus, the watch and the tank; no port-only
  actions are added. Default layout: South = A, West = B, right trigger = Z,
  left trigger / RB = R, LB = L, right stick = C-buttons, D-pad and Start as
  is. Each N64 button can be moved per player in `ge007.ini`
  (`Input.N64Pad.A = a`, `Input.N64Pad2.B = x`, ...). `Input.N64StickFeel = 1`
  (default in Original) gives the N64's linear stick range; 0 keeps the
  previous feel. The Modern style and keyboard/mouse are unchanged.
- **Invert look** reaches every original style (D605) and, in Original, is the
  same setting as the watch's *Look up/down* (D645).

### Settings and diagnostics

- **Mission timer** (D606, #144): an optional always-visible timer, off by
  default (F10).
- F10 dropdowns stay inside the settings box instead of covering the help
  text (D646).
- Windows: per-monitor DPI awareness, so fullscreen on a scaled 4K display is
  native resolution (D626); exclusive fullscreen uses the desktop mode (D639).

- The old front-end **Velocity** pointer mode is removed; the retired ini keys
  are ignored quietly (D574).
- The Linux/macOS **update check** no longer fails on a response over 64 KB
  (D575).
- Every log line is also written to **`ge007.log`** next to the ini; the
  previous run is kept as `ge007.prev.log` (D576).
- F10 slider labels no longer end in ".." at HUD scale 150 (D577).
- The crosshair look (colour, size, style, alpha, health colour) is your
  preference and is no longer reset by the *Display mode* presets (D440).
- The sound-effect and text-bank pointer guards check the real address range,
  so they work at any address base (D573, #108 with italoarruda).

---

## Install and upgrade

### Downloads

| File | Platform |
|---|---|
| `goldeneye-pc-port-<version>-win64.zip` | Windows x86-64 |
| `goldeneye-pc-port-<version>-linux-x86_64.tar.gz` | Linux x86-64 (incl. Steam Deck) |
| `goldeneye-pc-port-<version>-macos-arm64.tar.gz` | macOS Apple Silicon, experimental |

Each contains the engine executable, a README, license texts, and the
one-time asset tool. **No ROM, no game assets.** The Windows bundle carries
its runtime DLLs and the Linux bundle carries SDL2, so nothing needs to be
installed first. The Linux bundle runs on glibc 2.31 or newer (Ubuntu 20.04+,
Debian 11+, SteamOS). The macOS bundle carries SDL2 and the C++ runtime and
needs an M1 or later Mac on macOS 14 or newer.

### Running it

You need your own **GoldenEye 007 N64 ROM** (US version, `.z64`).

1. Unpack the archive.
2. Make a `data/` folder next to the executable and put the ROM in it, named
   `ge007.ntsc-final.z64`.
3. Run the executable from that folder. The first start takes a few extra
   seconds while it generates its asset files from your ROM.

**Updating from an earlier version:** unpack into a new folder and copy your
ROM, `ge007.eep` (your progress) and `ge007.ini` (your settings) into its
`data/` folder. Don't copy the old `pcmodels-*` / `pccg-*` folders: the new
version makes its own.

**macOS (experimental):** the app is not signed with a Developer ID or
notarized, so Gatekeeper blocks a downloaded copy. After unpacking and before the
first launch, run this once in Terminal, then start `./ge007.aarch64` from
the folder:

```
xattr -dr com.apple.quarantine goldeneye-pc-port-<version>-macos-arm64
```

Or download it in Terminal, which skips the block entirely (`curl` does not
mark the file for Gatekeeper):

```
curl -L https://github.com/jkdansereau/goldeneye-pc-port/releases/download/v<version>/goldeneye-pc-port-<version>-macos-arm64.tar.gz | tar xz
```

Without Terminal: after the first launch is blocked, open System Settings →
Privacy & Security and click **Open Anyway** next to the `ge007.aarch64`
message.

I have only run it on one M3 Mac, so please report what Mac and macOS you
tried and what happened.

**Steam Deck:** do the steps above on the Deck, then add the executable as a
non-Steam game. The options overlay opens with **Select** and is fully
controller-driven.

Full steps, controls and troubleshooting are in the bundled `README.md`.

---

## Known issues

| Issue | Impact | Workaround |
|---|---|---|
| On the Steam Deck at 90 fps, firefights in the centre of Bunker 1 and 2 can drop several fps | Performance, Deck only | Set the frame cap to 60 for those levels |
| Jungle can feel slightly less smooth at 90 fps than other levels | Feel | Frame cap 60 |
| Cradle's turret explosions may draw wrongly | Cosmetic; reported, not yet investigated | None |
| After alt-tabbing away, the picture can look hazy until it settles; fast repeated alt-tab is wonkier and takes longer | Cosmetic, Windows | It recovers on its own; alt-tab again or give it a couple of seconds |
| macOS: the end credits may crash | Ending only, macOS only | Your progress is already saved by then |
| macOS (Apple Silicon) is experimental, tested on one Mac, and not notarized | Platform | Run `xattr -dr com.apple.quarantine <folder>` before the first launch; reports welcome |
| PAL and JP ROMs aren't supported in release packages | NTSC-U only | Use an NTSC-U ROM. Both regions convert, build and boot from source; packaging is still open |
| Changing aspect ratio inside a level can briefly glitch the gun/hand model, rarely | Cosmetic, one-off | Change the ratio from the front-end PC Options, or accept it |
| Saves from v0.4.0 and earlier can hold fake unlocks from `All unlocked` | Save data | Not repaired automatically. Since v0.5.0 the option never writes the save; keep a backup of `data/ge007.eep` from before you used it |
| The first frame of a level takes a little longer while its textures upload | Brief FPS-counter dip | None needed |
| Far objects almost fully in fog are now hidden as on the N64, except in widescreen where a faint distant building edge can still show (e.g. Surface's dish from the start area); 4:3 matches the N64 | Cosmetic | Higher Draw/LOD distance shows more |

Faithful original-game quirks are not port bugs. The full list, with
workarounds, is the
[known-issues table](https://github.com/jkdansereau/goldeneye-pc-port/blob/main/docs/ROADMAP.md#known-issues).

---

## Fixes and changes, with finding labels

- **Frame interpolation above 60 fps** (D578, rework of #137). 120 fps with
  VSync on G-Sync/VRR: black frames and OLED flicker fixed (D583). Steam Deck
  90 Hz pacing (D583).
- **#150 geometry disappearing when too close to a wall:** the near-plane clip
  now cuts at the camera plane (D579).
- **Cradle catwalk shadow flicker:** a D579 regression, fixed (D584).
- **Native-widescreen stale pixels** on front-end screens: the canvas sides are
  cleared (D579 follow-up).
- **#151** the first launch opens on the primary monitor (D581).
- **#152** Linux end-credits crash: a garbage text pointer is rejected (D582).
- **#153, #156** hat-spawn crash: the object record type and the end-of-list
  marker were read from the wrong byte on a little-endian machine, so the search
  could run past the end of the list (D580).
- **#108** SFX / text-bank pointer guards (D573).
- **#145 / #149** Original control style as an N64 controller (D643); Invert
  look in the original styles (D605, D645).
- **#144** mission timer (D606).
- **#146** file-select crest on a dark square: 4-bit IA textures now decode as
  the N64 does (D644).
- **Exit crash (BSOD 0x119) on some Windows GPUs:** the GL context and window
  are released before the process exits (D632).
- Windows DPI awareness (D626), exclusive fullscreen mode (D639), F10 dropdown
  placement (D646).
- Velocity removal, update-check fix, `ge007.log`, HUD-150 sliders, preset
  scope (D574-D577, D440).
- **macOS arm64:** one address-model header, the 64-bit pointer fixes and a
  display-locked tick (D586, D591, D594, D595, D599-D604, D607-D613).

## Verification

Windows: the 21-level reference-frame sweep passes (Streets sits at the edge of
its tolerance and flips run to run with or without this release's changes).
Steam Deck and macOS: all 21 levels load, play and quit without a crash (their
reference frames are not yet comparable, so no pixel check). The fixes above
were also checked by playing on Windows, with the original controls compared
against the issue reports rather than an N64 pad.

## Thanks

f1zz1ec0ke (#137, the frame-interpolation design this release reworks),
danturn (#95, macOS), Julio C. Rocha (#88, the first macOS groundwork),
italoarruda (#108), dolent (#120-#123, already in v0.5.0), plus reporter
credits on the issue numbers named above.

## Verify the download

```
sha256sum -c goldeneye-pc-port-<version>-win64.zip.sha256
sha256sum -c goldeneye-pc-port-<version>-linux-x86_64.tar.gz.sha256
shasum -a 256 -c goldeneye-pc-port-<version>-macos-arm64.tar.gz.sha256   # macOS
```

## Source & docs

<https://github.com/jkdansereau/goldeneye-pc-port>, built on the
[GoldenEye 007 decompilation](https://github.com/n64decomp/007), with its
architecture modelled on the [Perfect Dark PC port](https://github.com/fgsfdsfgs/perfect_dark).
Non-commercial fan preservation/research project; not affiliated with any
rights holder. **AI disclosure:** built through agentic AI coding (Claude
Code + a local open-weight model), directed by one person in their spare
time. See the README's
[How it was made](https://github.com/jkdansereau/goldeneye-pc-port#how-it-was-made)
section for the full account.
