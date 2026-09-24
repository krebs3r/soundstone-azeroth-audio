# Compatibility status — 16 September 2026

Soundstone has user-confirmed in-game compatibility for the four client families below. Version 0.3.2 is confirmed for all four families. Acceptance remains release-specific. Mocked API scenarios cannot replace loading a new release in each game.

| Family | Installed build checked locally | Interface in TOC | Current validation |
| --- | --- | --- | --- |
| Retail / Midnight | 12.1.0.69814 | 120100 | [Final 0.3.2 package confirmed in game](curseforge/acceptance/v0.3.2-retail.md), 2026-09-15 |
| Mists of Pandaria Classic | 5.5.4.69585 | 50504 | [0.3.2 confirmed by user](curseforge/acceptance/v0.3.2-mists.md), 2026-09-16 |
| TBC Classic Anniversary | 2.5.6.69795 | 20506 | [Final 0.3.2 package confirmed in game](curseforge/acceptance/v0.3.2-anniversary.md), 2026-09-15 |
| Classic Era / Hardcore / Season of Discovery | 1.15.9.69722 | 11509 | [0.3.2 confirmed by user](curseforge/acceptance/v0.3.2-era.md), 2026-09-16; separate game-mode checks pending |
| WoW: Forever (beta) | Beta client in `_classic_beta_` | 16001 | Interface listed from 0.3.4; Classic artwork on the Retail API. 0.3.4 test build confirmed by the user in the beta on 2026-09-24; beta builds change, recheck at launch (2026-11-04) |

The four build numbers were read from the local Battle.net `.build.info` and compared with the published UI-source versions: [Retail](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/version.txt), [MoP Classic](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic/version.txt), [Anniversary](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_anniversary/version.txt), [Era](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_era/version.txt). Blizzard's [current hotfix page](https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-september-10-2026) lists the active game families. The [Forever announcement](https://news.blizzard.com/en-us/article/24302093/carve-a-new-path-with-world-of-warcraft-forever) is not evidence of addon API compatibility.

## Compatibility mechanisms checked

- Lua 5.1 syntax and no external addon dependency.
- CVar access uses `C_CVar` with legacy global fallbacks; metadata access supports `C_AddOns` and the older global API.
- Audio reads, writes and device APIs are checked. Unsupported controls fail gracefully; device changes are validated and read back.
- Modern Blizzard dropdown menus and the attached legacy fallback are tested separately. Menu initializers use `SetFontObject`; the disallowed compositor `SetFont` access is absent.
- Retail uses its own skin; other client families use Classic styling. Pixel alignment has a fallback when `PixelUtil` is absent.
- Optional event registration is protected against unavailable events.
- Placement only moves Soundstone. It reads public frame bounds and skips forbidden, hidden, inaccessible and secret-valued frames. The relevant [Blizzard frame API declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) explicitly allow some properties to be secret. It does not modify protected Blizzard frames.

The placement option reserves no space globally. It checks visible interactive/movable frames at the instant the drag ends; full-screen input containers are excluded, but their readable controls are considered. Newly opened windows, decorative noninteractive regions, or unavailable bounds can still overlap later. If no placement is found, the previous position is restored and a chat message explains why.

## Remaining in-game checks

For each family/mode: startup and `/reload`, master/SFX/music switching, zero-volume restoration, external Blizzard audio changes, speakers/headset selection, combat, Escape layers, placement near action bars/minimap/windows, and 1080p/1440p at WoW scale 65/85/100% with Soundstone 75/100/150%.

Future patches require checking Interface metadata, changed APIs and client rendering again. Historical/private clients and unreleased clients are not covered by a blanket “all versions” promise.
