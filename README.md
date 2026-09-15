<p align="center"><img src="docs/assets/Logo.png" width="170" alt="Soundstone: blue rune stone with golden sound waves"></p>

# Soundstone – Azeroth Audio

**Your game. Your sound.**

Control your World of Warcraft audio in one compact window. Soundstone brings together master volume, sound effects, music and your output device, with a quick bar and an expanded mixer. No additional addons are required.

[Download Soundstone 0.3.2](https://github.com/krebs3r/soundstone-azeroth-audio/releases/download/v0.3.2/Soundstone-0.3.2.zip) · [CurseForge](https://www.curseforge.com/wow/addons/soundstone-azeroth-audio) · [Deutsche Anleitung](docs/ANLEITUNG-DE.md) · [Report an issue](https://github.com/krebs3r/soundstone-azeroth-audio/issues)

## Why I built Soundstone

I sometimes watch Netflix, YouTube or another streaming service on my second monitor while playing WoW. I wanted to quickly mute or adjust game sound and music without opening the full audio settings every time, so I built Soundstone to keep those controls within reach.

Soundstone shares its visual style with [Hourstone – Azeroth Hours](https://github.com/krebs3r/hourstone-azeroth-hours), with frames for Retail and Classic.

## Features

- Master volume, sound effects and music, with individual toggles and volume sliders.
- Switch between a compact bar and an expanded mixer.
- Adjust volume with the mouse wheel; hold Shift for finer steps.
- Choose WoW's audio output device from an attached, scrollable menu.
- Movable window with saved position and scale, position locking and optional overlap avoidance.
- Optional minimap button that can be moved or hidden.
- German on `deDE` clients, English on all other locales.
- No dependencies or external service. Preferences stay in WoW's local SavedVariables.

## Interface previews

These design previews show the **0.3.2** layout using the addon's actual frame and icon textures, rendered at high resolution. The in-game addon uses WoW's native fonts and controls; those are approximated here. These are interface mockups, not in-game screenshots.

### Retail — audio mixer

Master volume, sound effects and music at 80%, 60% and 25%, with all three groups enabled.

<img src="docs/screenshots/soundstone-0.3.2-retail.png" width="600" alt="Soundstone 0.3.2 Retail mixer with three audio groups, volume sliders and view controls">

### Classic — audio mixer

The same controls in the Classic frame, with silver slider thumbs.

<img src="docs/screenshots/soundstone-0.3.2-classic.png" width="600" alt="Soundstone 0.3.2 Classic mixer with master volume, sound effects and music enabled">

### Compact — quick controls and options

The compact Classic bar with attached settings. This example also shows the German interface, including output device, size and placement options.

<img src="docs/screenshots/soundstone-0.3.2-compact-classic.png" width="552" alt="Soundstone 0.3.2 compact Classic bar and German options, including overlap avoidance">

## Supported clients

| Client family | Addon interface version | In-game testing |
| --- | ---: | --- |
| Retail (12.1.0) | 120100 | Confirmed (2026-09-15) |
| Mists of Pandaria Classic (5.5.4) | 50504 | Pending |
| Burning Crusade Classic Anniversary (2.5.6) | 20506 | Confirmed (2026-09-15) |
| Classic Era, Hardcore and Season of Discovery (1.15.9) | 11509 | Pending |

Version **0.3.2** has been tested in [Retail](docs/curseforge/acceptance/v0.3.2-retail.md) and [Burning Crusade Classic Anniversary](docs/curseforge/acceptance/v0.3.2-anniversary.md). Support for the other listed clients is implemented but still awaits in-game testing. See the [compatibility audit](docs/COMPATIBILITY.md) and [validation status](docs/TESTING.md) for coverage and outstanding checks. WoW: Forever is unconfirmed.

## Installation

1. Download **`Soundstone-0.3.2.zip`** from [GitHub Releases](https://github.com/krebs3r/soundstone-azeroth-audio/releases/tag/v0.3.2). GitHub's automatically generated source archives are for development.
2. Exit WoW and extract the ZIP into the relevant client's `Interface/AddOns` folder.
3. Confirm the result is **`Interface/AddOns/Soundstone/Soundstone.toc`**, without an extra repository folder or nested `Soundstone` folder.
4. Enable Soundstone in the character selection AddOns list and log in. Use `/soundstone` or the minimap button to open it.

Repeat for each WoW installation you use: `_retail_`, `_classic_`, `_anniversary_` or `_classic_era_`. No extra addon or library is required. The CurseForge project link is above; see the [publication status](docs/curseforge/STATUS.md) if it is not yet available.

**Updating:** exit WoW, replace the existing `Soundstone` addon folder and restart. Keep your `WTF` folder; it contains saved preferences. If an update was already copied while playing, `/reload` reloads the addon. Restart the client to discover a newly installed addon.

## Usage

| Control | Action |
| --- | --- |
| `/soundstone` or `/azeraudio` | Restore Soundstone or switch its view |
| `/soundstone show` / `hide` | Show / hide the addon, even with the minimap button hidden |
| Left-click an audio icon or On/Off button | Toggle that audio group |
| Right-click a compact audio icon | Open the expanded mixer |
| Mouse wheel over an icon or slider | Change volume by 5%; Shift + wheel changes 1% |
| Drag a volume slider | Set volume from 0–100% |
| Gear button | Output device, size, minimap visibility and placement settings |
| View arrows | Switch compact and expanded views |
| Crossed-out eye | Hide Soundstone; restore with `/soundstone` |
| Escape or red X | Close the current popup, then return from mixer to compact view |
| Drag the six-dot grip or mixer title | Move Soundstone unless positions are locked |
| Minimap left-click / right-click | Restore or switch view / show or hide Soundstone |

### Commands and bindings

Both `/soundstone` and `/azeraudio` accept:

```text
compact / expand      Choose a view
hide / show / bar     Hide, restore or toggle visibility
minimap               Toggle the minimap button
lock / reset          Lock positions or reset them
scale 100             Set addon size (75–150%)
master 70             Set master volume to 70%
sfx off               Mute effects, ambience and dialogue
music on              Enable music; restore volume if needed
music toggle          Toggle music
help                  Show command help
```

Optional bindings are available under **Soundstone – Azeroth Audio** in WoW's Key Bindings menu. No keys are assigned automatically.

## How audio controls work

Turning **Master** off makes every group appear off while preserving its settings. Enabling **Music** with master off activates only music; enabling **Sound effects** instead activates that group alone. Sound effects includes effects, ambience and dialogue; voice chat remains separate. The effects slider adjusts the three grouped volumes together.

Enabling at **0%** restores the last positive volume. Muting preserves volume levels; dragging a muted slider does not unmute it. Gray icons indicate inactive audio. Percentages show configured channel volumes, not measured output. WoW's audio settings remain the source of truth; startup never applies default volumes.

The output-device menu validates and reads back the selection. Successful changes restart WoW's audio system once. Unsupported APIs and rejected changes are reported rather than displayed as successful selections.

### Saved preferences and layout

Preferences are stored locally as `SoundstoneDB`, per WoW installation and account. The views share a saved position; minimap visibility is independent. The compact bar is **276 × 36**, the mixer **300 × 160**, and options **276 × 236** UI units.

Soundstone follows WoW's UI scale and adds its own **75–150%** size setting. Size changes apply when the slider is released. Options attach below the current view, or above near the bottom screen edge.

**Avoid overlap when placing** finds a free position beside visible, readable UI controls when a drag ends or the mixer expands. It does not reserve space against later-opening windows or inaccessible frame bounds. Turn the option off for unrestricted placement.

## Feedback

Found a problem? [Open an issue](https://github.com/krebs3r/soundstone-azeroth-audio/issues) with your WoW client version, Soundstone version and the steps to reproduce it. Include a screenshot or Lua error message if available.

## Development

Runtime code is Lua 5.1 compatible. Development uses Python 3.10+ and the dependencies in `requirements-dev.txt`; CI runs Python 3.12:

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p 'test_release_tools.py'
python tools/preview.py
python tools/package.py
```

The Lua suite runs simulated client/API configurations with native and fallback dropdown menus. Packaging validates TOC entries, XML, textures, shared header bounds and ZIP integrity. The result is `dist/Soundstone-0.3.2.zip` with one installable `Soundstone/` folder and a SHA-256 file.

`python tools/preview.py` generates a browser preview using production textures and layout metadata. Serve `docs/` locally to inspect `ui-preview.html`, `readme-gallery.html` and `readme-details.html`. See [preview export instructions](docs/screenshots/README.md) to regenerate the README images. Fonts and native controls are approximated; visual changes still need to be checked in game. `tools/export-assets.ps1` exports the artwork.

Pushes and pull requests run **Validate and package** and produce an installable ZIP. A matching version tag builds and publishes a prerelease; a tested release is promoted explicitly. See the [CurseForge release guide](docs/curseforge/README.md) for approved-release uploads and the local multi-client installer.

See the [changelog](CHANGELOG.md), [validation status](docs/TESTING.md) and [German guide](docs/ANLEITUNG-DE.md) for release history and testing details. Release notes are maintained outside the addon; the version footer has no changelog popup in 0.3.2.

## License and artwork

[MIT](LICENSE), © 2026 krebs3r. See [artwork provenance](docs/ARTWORK.md). World of Warcraft is a trademark of Blizzard Entertainment; Soundstone is an independent community addon.
