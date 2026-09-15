# README interface previews

The three `soundstone-0.3.2-*.png` images show the current Retail mixer, Classic mixer and compact Classic bar with German options. They use production PNG textures, UV coordinates from `Soundstone/Assets.lua`, dimensions from `Soundstone/Layout.lua` and the version from `Soundstone.toc`.

These are browser-rendered mockups, not in-game screenshots. Georgia and the drawn native controls approximate WoW's fonts, buttons, gear, checkboxes and device menu. No game or system font files are redistributed.

## Regenerate

Use Python, Node.js and a locally available Playwright installation with Chromium:

```sh
python tools/preview.py
node tools/capture-readme.cjs
```

If Playwright is installed outside this repository, set `PLAYWRIGHT_MODULE` to its package path. Set `BROWSER_CHANNEL=msedge` to use an installed Microsoft Edge instead of Playwright's Chromium. The renderer launches a separate headless browser and reads local files only.

Exports use four pixels per UI unit: **1200 × 640** for each mixer and **1104 × 1104** for compact plus options. The README displays them at half their pixel dimensions for crisp text and edges on high-density screens. The compact image is cropped to the actual 276-unit frame width. Review all three exports for clipped text, missing textures and current version before replacing README references.

`soundstone-0.3-overview.png` and `soundstone-0.3-details.png` remain historical 0.3.0 captures. The latter includes a changelog popup removed in 0.3.2; neither is used by the current README. The separate CurseForge screenshots remain historical in-game captures.
