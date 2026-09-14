# Artwork and provenance

- `design-concept.png` is the user-approved concept board, not an in-game screenshot.
- `icons-source.png` contains the four original Soundstone symbols.
- `skin-source-v02.png` contains generated Retail/Classic shells and controls derived from the concept. This source sheet has an opaque background; it is not itself a ready-to-use transparent atlas.
- `tools/export-assets.ps1` mechanically slices the sheets, clips the exterior of frames and controls, converts black-matte glyphs to alpha, preserves aspect ratios and exports fourteen 32-bit uncompressed TGA textures. Transparent padding uses power-of-two dimensions. Runtime rendering uses ordinary alpha blending.
- `Soundstone/Assets.lua` records exact content coordinates and original proportions. `docs/assets/*.png` are PNG copies of the same exported pixels for the comparison preview. Frames use nine separate regions so their corners do not stretch with their centers.
- Concept and sprite art were generated with the built-in Imagegen tool. Prompts are preserved in `artwork-prompts.txt`.
- The art combines a pale teleportation stone, blue spiral rune and gold sound waves. WoW supplies its own fonts, checkbox template and minimap border at runtime; no extracted Blizzard art or fonts are redistributed here.
- The repository license covers the project's own code and original contributions. Blizzard names, game assets and other third-party rights remain with their respective owners. The project is independent and unofficial.

On Windows with PowerShell 7, run `./tools/export-assets.ps1`, followed by `python tools/preview.py`. The HTML preview uses the exported sprites and runtime geometry; browser font rendering is only an approximation of WoW. It is not evidence of in-game parity. See [TESTING.md](TESTING.md).
