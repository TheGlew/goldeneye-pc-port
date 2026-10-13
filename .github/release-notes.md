# GoldenEye 007 PC Port — v<version>

<p align="center">
  <img src="https://github.com/jkdansereau/goldeneye-pc-port/raw/v<version>/docs/img/shots/feature-splitscreen.jpg" width="340" alt="2-player split-screen multiplayer in the port">
  <img src="https://github.com/jkdansereau/goldeneye-pc-port/raw/v<version>/docs/img/shots/feature-options.jpg" width="340" alt="The PC options menu: custom crosshair colour sliders">
</p>

> [!NOTE]
> **Updating?** Your progress and settings carry over. Unpack the new version
> into a new folder and copy your ROM, `ge007.eep` and `ge007.ini` into its
> `data/` folder. Leave the old `pcmodels-*` and `pccg-*` folders behind; the
> new version makes its own.

> [!NOTE]
> The downloads aren't code-signed. On Windows, if SmartScreen appears, click
> **More info**, then **Run anyway**. On macOS, see [Getting started](#getting-started).

## Highlights

- **Frame rates above 60.** Pick 90, 120, 144, 165 or 240, or **Auto** to
  match your display (up to 240). The game still runs at its original speed;
  the extra frames are blended between its ticks. A rework of f1zz1ec0ke's
  #137.
- **macOS on Apple Silicon (experimental).** A new download for M1 and later
  Macs, based on danturn's #95. Tested on one M3 Mac so far; reports are
  welcome.
- **Original controls are now original (#145, #149).** With *Control style*
  set to Original, your pad behaves as an N64 controller, and *Invert look*
  works in every original style.
- **Fixes:** geometry vanishing up close (#150), the first launch opening on
  the wrong monitor (#151), the end-credits crash on Linux and macOS (#152)
  and a crash when a guard spawns with a hat (#153, #156).
- **Also:** an optional mission timer (#144), the file-select crest fixed
  (#146), and a fix for a Windows blue screen on exit.

## Downloads

| File | Platform |
|---|---|
| `goldeneye-pc-port-<version>-win64.zip` | Windows 10/11, 64-bit |
| `goldeneye-pc-port-<version>-linux-x86_64.tar.gz` | Linux x86-64 (glibc 2.31+), including Steam Deck |
| `goldeneye-pc-port-<version>-macos-arm64.tar.gz` | macOS 14+ on Apple Silicon (experimental) |

Each download is ready to run: it carries its runtime libraries, a README,
the license texts and the one-time asset tool. **No ROM and no game assets
are included; you need your own US GoldenEye 007 ROM.**

## Getting started

1. Unpack the download.
2. Make a `data/` folder next to the executable and put your ROM in it as
   `ge007.ntsc-final.z64`.
3. Start the game. The first start takes a few extra seconds while it prepares
   the game files from your ROM. **F10** (controller: **Select**) opens the
   options menu.

**Steam Deck:** do the steps on the Deck, then add the executable as a
non-Steam game.

**macOS:** the app isn't notarized, so run this once in Terminal before the
first launch, then start `./ge007.aarch64` from the folder. If the window ever
stays black on the first start, close it and start it again.

```
xattr -dr com.apple.quarantine goldeneye-pc-port-<version>-macos-arm64
```

Or download it in Terminal, which skips that step:

```
curl -L https://github.com/jkdansereau/goldeneye-pc-port/releases/download/v<version>/goldeneye-pc-port-<version>-macos-arm64.tar.gz | tar xz
```

Without Terminal: after macOS blocks the first launch, open System Settings →
Privacy & Security and click **Open Anyway** next to the `ge007.aarch64`
message.

The [user guide](https://github.com/jkdansereau/goldeneye-pc-port/blob/v0.6.0/docs/user-guide.md)
covers controls, settings, emulator saves and troubleshooting.

## What's new

### Added

- **Frame rate cap:** Auto, 90, 120, 144, 165 and 240 join 30 and 60 (F10 →
  *Video*). Auto is the default on fresh installs; an existing `ge007.ini`
  keeps its value. Above 60 the extra frames are blended between game ticks
  (no effect on a 60 Hz display), which adds one tick of latency; a fast camera turn or a big change on screen
  shows a full frame instead. The *Original N64* display mode keeps 60.
- **macOS Apple Silicon download** (experimental), plus source builds with
  Homebrew's GNU `gcc`.
- **Original control style as an N64 controller:** every press sends the real
  N64 button in levels, menus, the watch and the tank. Default layout: South =
  A, West = B, right trigger = Z, left trigger / RB = R, LB = L, right stick =
  C-buttons. Each button can be moved per player in `ge007.ini`
  (`Input.N64Pad.A = a`, ...), and `Input.N64StickFeel` picks the N64's linear
  stick range.
- **Mission timer** (#144): an optional always-visible timer, off by default.
- **`ge007.log`:** every run is logged next to the ini; the previous run is
  kept as `ge007.prev.log`.

### Fixed

- Geometry vanishing when you stand against a wall (#150).
- The first launch opening on the wrong monitor (#151).
- A crash during the end credits on Linux and macOS (#152).
- A crash when a guard spawns wearing a hat (#153, #156).
- The file-select crest drawing on a dark square (#146).
- *Invert look* now works in every original control style and stays in sync
  with the watch's *Look up/down* (#145).
- A Windows blue screen (0x119) when the game exits, seen on an NVIDIA GPU.
- The Cradle catwalk shadow flicker, and stale pixels beside the widescreen
  picture on front-end screens.
- Sound and text pointer checks that rejected valid pointers (#108, with
  italoarruda).
- The Linux/macOS update check failing on a large response.
- F10 slider labels being cut off at HUD scale 150.

### Changed

- Windows: per-monitor DPI awareness, so fullscreen on a scaled 4K display is
  native resolution.
- F10 dropdowns stay inside the settings box.
- The crosshair look (colour, size, style) is no longer reset by the *Display
  mode* presets.
- The old front-end *Velocity* pointer mode is removed.

## Known issues

| Issue | Workaround |
|---|---|
| On the Steam Deck at 90 fps, firefights in the centre of Bunker 1 and 2 can drop a few fps, and Jungle can feel slightly less smooth | Set the frame cap to 60 for those levels |
| Cradle's turret explosions may draw wrongly | None yet |
| On Windows, the picture can look hazy for a moment after alt-tabbing back | It settles on its own |
| macOS: the window can stay black on the very first start | Close it and start it again |
| PAL and JP ROMs aren't supported yet | Use the US (NTSC-U) ROM |
| Saves from v0.4.0 and earlier can hold fake unlocks from *All unlocked* | Keep a backup of `data/ge007.eep` from before you used it |

The full list is the
[known-issues table](https://github.com/jkdansereau/goldeneye-pc-port/blob/main/docs/ROADMAP.md#known-issues).

## Tested on

The release downloads themselves, from a fresh folder with only the ROM: all
21 solo levels on Windows (at 120 fps), the Steam Deck (Desktop and Game
Mode, at 90), macOS on Apple Silicon, and a 2011 Linux laptop with Intel HD
3000 graphics (at 60).

## Thanks

f1zz1ec0ke (#137, the frame-interpolation design this release reworks),
danturn (#95, macOS), Julio C. Rocha (#88, the first macOS groundwork),
italoarruda (#108), and everyone who reported the issues above.

## Verify the download

```
sha256sum -c goldeneye-pc-port-<version>-win64.zip.sha256
sha256sum -c goldeneye-pc-port-<version>-linux-x86_64.tar.gz.sha256
shasum -a 256 -c goldeneye-pc-port-<version>-macos-arm64.tar.gz.sha256   # macOS
gh attestation verify <file> --repo jkdansereau/goldeneye-pc-port         # build provenance
```

---

Built on the [GoldenEye 007 decompilation](https://github.com/n64decomp/007)
and modelled on the [Perfect Dark PC port](https://github.com/fgsfdsfgs/perfect_dark).
A non-commercial fan project, not affiliated with any rights holder. Developed
with AI coding agents directed by one maintainer; see
[About the project](https://github.com/jkdansereau/goldeneye-pc-port/blob/v0.6.0/docs/about.md#how-it-was-made).
