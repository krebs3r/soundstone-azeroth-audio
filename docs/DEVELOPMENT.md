# Development

Runtime code is Lua 5.1 compatible. Development uses Python 3.10+ and the dependencies in `requirements-dev.txt`; CI runs Python 3.12. Run these commands from the repository root:

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p 'test_release_tools.py'
python tools/preview.py
python tools/package.py
```

The Lua suite runs simulated client/API configurations with native and fallback dropdown menus. Packaging validates TOC entries, XML, textures, shared header bounds and ZIP integrity. The result is `dist/Soundstone-<version>.zip`, named after the TOC version, with one installable `Soundstone/` folder and a SHA-256 file.

`python tools/preview.py` generates a browser preview using production textures and layout metadata. Serve `docs/` locally to inspect `ui-preview.html`, `readme-gallery.html` and `readme-details.html`. See [preview export instructions](screenshots/README.md) to regenerate the README images. Fonts and native controls are approximated; visual changes still need to be checked in game. `tools/export-assets.ps1` exports the artwork.

Pushes and pull requests run **Validate and package** and produce an installable ZIP. A matching version tag builds and publishes a prerelease; a tested release is promoted explicitly. See the [CurseForge release guide](curseforge/README.md) for approved-release uploads and the local multi-client installer.

See the [changelog](../CHANGELOG.md), [validation status](TESTING.md) and [German guide](ANLEITUNG-DE.md) for release history and testing details. Release notes are maintained outside the addon; the version footer has no changelog popup since 0.3.2.

## Themes

`Soundstone/Theme.lua` (loaded after `Layout.lua`, before `UI.lua`) holds two palettes. `soundstone` paints exactly the 0.3.8 colors over the sprite skin: Retail sprites on Retail, Classic sprites elsewhere. `forever` is WoW: Forever's own look. On the Forever client it uses the client's own art where `Theme.Art()` finds it: the window frame on the mixer and options, the same frame cut to its band on the compact bar, the slider track and the action-button frame on the channel icons. Every piece without its art is a flat stand-in: a plate, a one-pixel bronze line with a one-pixel band inside, flat wells and grip squares. The look follows the client, `Theme.Resolve()`: `forever` where `Compat.IsForever()` is true, `soundstone` everywhere else. There is no command or saved setting for it; a `SoundstoneDB.theme` left by an unreleased 0.4.0 build is dropped at load.

- Every text and flat texture that a theme colors is registered with `Theme.Paint(region, key, method)`, using a palette key, instead of a constant color. The weak-keyed registry is painted again whenever a look is applied, each region inside `pcall`. Hover and pressed scripts read `Theme.Color(key)` when the pointer arrives.
- `UI:ApplyTheme()` shows one set of pieces and hides the other, sets every slider thumb (the client atlas `Minimal_SliderBar_Button` under `forever`, if known; otherwise the sprite), repaints and sizes the lines. No frame size or saved position changes. Inside Forever's window frame some controls take other places: `place()` records each such region's sprite layout at creation, `UI:BuildWindows()` adds the framed one with `framePlace()`, and `applyPlaces()` sets one or the other, so the sprite layout returns exactly. It runs once at the end of `UI:Create`, before its final refresh. `UI:ApplyTheme(name)` takes the other look too; the tests use that to switch back and forth and check that both looks restore each other exactly.
- The Forever pieces are built lazily the first time that look is applied: `UI:BuildForever()` the flat stand-in (per plate a fill and an edge frame above the content with the line and band, plus wells and grip squares), `UI:BuildWindows()` (with `UI:BuildBarBand()`, which cuts the layout's own pieces to their band with texture coordinates set before `SetAtlas`, as NineSlice mirrors pieces) and the track and slot builders the client-art pieces. The window border sits 10 levels above its window and the header controls 12, as Blizzard's NineSlice (500) sits below its title and buttons. On the other clients none of this exists.
- `UI:SizeTheme()` sets every line and divider to one physical pixel (`Theme.Pixel`: `PixelUtil.GetPixelToUIUnitFactor()` divided by the effective scale, one unit if the scale is secret). It runs from `UI:ApplyLayout` and on every switch, because `ApplyLayout` returns early during a drag.

`python tools/mockup.py forever` writes the comparison boards `docs/ui-mockup-forever.png` and `docs/ui-mockup-forever-2x.png`; without an argument the tool writes the 0.3 boards as before. Measurements, palette sources and the test plan are in the [WoW: Forever theme plan](FOREVER-THEME-PLAN.md).
