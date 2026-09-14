# Artwork and provenance

- `design-concept.png` is the user-approved concept board, not an in-game screenshot.
- `icons-source.png` is the generated source atlas for the four original Soundstone symbols.
- `Soundstone/Media/Icons.tga` is a mechanical 512 × 512, 32-bit uncompressed TGA conversion for WoW. The black-matte glyphs are drawn with additive blending on the dark addon surface.
- Concept and sprite art were generated with the built-in Imagegen tool. Final prompts are preserved in `artwork-prompts.txt`.
- The art follows the requested combination of a pale teleportation stone, blue spiral rune and gold sound waves. Blizzard client textures are referenced at runtime; no extracted Blizzard art or fonts are redistributed here.
- The repository license covers the project's own code and original contributions. Blizzard names, game assets and other third-party rights remain with their respective owners. The project is independent and unofficial.

To regenerate the game texture on Windows, run `tools/convert-atlas.ps1 -Source docs/icons-source.png`.
