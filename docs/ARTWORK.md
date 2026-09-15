# Artwork and provenance

- `design-concept.png` is the user-approved concept board, not an in-game screenshot.
- `icons-source.png` contains the four original Soundstone symbols.
- `skin-source-v02.png` contains generated Retail/Classic shells and controls derived from the concept. This source sheet has an opaque background; it is not itself a ready-to-use transparent atlas.
- `tools/export-assets.ps1` mechanically slices the sheets, clips the exterior of frames and controls, converts black-matte glyphs to alpha and preserves aspect ratios. It also draws the project's four geometric vector symbols (Expand, Collapse, EyeOff and Heart) with antialiasing, plus three rounded metal button plates (ActionNormal, ActionHover, ActionPressed). The exporter produces twenty-four 32-bit uncompressed TGA textures and PNG copies. Transparent padding uses power-of-two dimensions. Runtime rendering uses ordinary alpha blending.
- `Soundstone/Assets.lua` records exact content coordinates and original proportions. `docs/assets/*.png` are PNG copies of the same exported pixels for the comparison preview. Frames use nine separate regions so their corners do not stretch with their centers.
- Concept and sprite art were generated with the built-in Imagegen tool. Prompts are preserved in `artwork-prompts.txt`.
- The four navigation/credit symbols are original code-drawn vectors in the exporter, separate from the generated concept sheets. Expand, Collapse and EyeOff bake a muted old-gold gradient, thicker strokes, dark brown outline and restrained upper highlight into their pixels. The legacy action symbols retain internal clearance for their new dark metal wells. Three plate textures supply normal, brighter bronze hover and inverted pressed bevels. Pressed symbols move down one UI unit. Runtime symbol multipliers are neutral brightness only (normal 0.9, hover 1.0, pressed 0.7). Heart keeps its original white-alpha texture and red tint; no font glyph is required. The client gear texture and its existing tint/states remain unchanged.
- The art combines a pale teleportation stone, blue spiral rune and gold sound waves. WoW supplies its own fonts, `UIPanelButtonTemplate`, `WowStyle1DropdownTemplate`, the Blizzard radio-menu system, the fallback `UIDropDownMenuTemplate` and tooltip border, checkboxes, `GEAR_64GREY` settings icon and minimap border at runtime; no extracted Blizzard art or fonts are redistributed here. The browser preview approximates these native controls; verify their actual appearance inside WoW.
- The repository license covers the project's own code and original contributions. Blizzard names, game assets and other third-party rights remain with their respective owners. The project is independent and unofficial.

On Windows with PowerShell 7 and Python/Pillow, run `./tools/export-assets.ps1`, followed by `python tools/preview.py`. The HTML preview uses the exported sprites and runtime geometry; browser font rendering is only an approximation of WoW. It is not evidence of in-game parity. See [TESTING.md](TESTING.md).

Compact Master/Sfx/Music icons fit proportionally in 22 × 22 UI units, with their prior centers preserved. The preview selects closed/open/scrolling device lists and normal/hover/pressed symbol states. PNG copies retain the same baked colors as the runtime TGAs.


## 0.3 approved layout and header graphics

`tools/header_art.py` exports HeaderHide, HeaderCompact and HeaderClose from the approved correction. It preserves the Close frame and alpha silhouette, composes an empty ruby interior and draws the two action glyphs centrally. All three are 128 × 128 PNG/TGA sprites with the same UV coordinates, displayed in 20 × 20 UI units. Package validation compares their alpha bytes and outer frame pixels. `tools/export-assets.ps1` calls this exporter after exporting the source sheets; `-Python` can select the executable.

The large header uses these sprites with common hover/pressed tinting and fixed bounds. The compact Expand button retains ActionNormal/Hover/Pressed and the original vector glyph. The old Collapse and EyeOff sprites remain available as source artwork; the large header uses the new composed variants. The source Close texture is unchanged.

`tools/mockup.py` now uses those exact production sprites for the approved comparison boards and enlarged button detail. The accompanying HTML switches attachment direction. Georgia/Segoe UI approximate game text. The boards are labeled as the approved reference, not in-game captures. The production HTML preview independently uses the current runtime metadata and assets.
