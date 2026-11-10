# Compatibility status — 23 October 2026; WoW: Forever updated 8 November 2026

Soundstone has user-confirmed in-game compatibility for the four client families below. Version 0.3.2 is confirmed for all four families. Acceptance remains release-specific. Mocked API scenarios cannot replace loading a new release in each game.

| Family | Installed build checked locally | Interface in TOC | Current validation |
| --- | --- | --- | --- |
| Retail / Midnight | 12.1.5.70529 | 120105 | [0.3.8 confirmed in game](curseforge/acceptance/v0.3.8-retail.md), 2026-10-23, with PixelPerfectUIScale at 0.53; 12.1.5 needs 120105, older TOCs load only as out of date |
| Mists of Pandaria Classic | 5.5.4.70531 | 50504 | [0.3.5 confirmed in game](curseforge/acceptance/v0.3.5-mists.md), 2026-09-26; [0.3.8 released by user decision](curseforge/acceptance/v0.3.8-mists.md) without separate in-game test |
| TBC Classic Anniversary | 2.5.6.70006 | 20506 | [0.3.5 confirmed in game](curseforge/acceptance/v0.3.5-anniversary.md), 2026-09-26; [0.3.8 released by user decision](curseforge/acceptance/v0.3.8-anniversary.md) without separate in-game test |
| Classic Era / Hardcore / Season of Discovery | 1.15.9.70003 | 11509 | [0.3.5 confirmed in game](curseforge/acceptance/v0.3.5-era.md), 2026-09-26; [0.3.8 released by user decision](curseforge/acceptance/v0.3.8-era.md) without separate in-game test; separate game-mode checks pending |
| WoW: Forever | 1.60.1.70862 (`_forever_`) | 16001 | Released client; reports `WOW_PROJECT_ID = WOW_PROJECT_CAMELOT` (18), which 0.4.0 also checks besides the interface number. Interface listed from 0.3.4; up to 0.3.8 Classic artwork on the Retail API. On the beta (1.60.1.70450, `_classic_beta_`): [0.3.5 confirmed in game](curseforge/acceptance/v0.3.5-forever.md), 2026-09-26; [0.3.8 released by user decision](curseforge/acceptance/v0.3.8-forever.md) without separate in-game test. 0.4.0 adds Forever's own look; its window frames seen and accepted in game on the release client on 2026-11-09/10 at client scale 0.7 and Soundstone 100%, the rest of the 0.4.0 checklist not yet confirmed |

The four build numbers were read from the local Battle.net `.build.info` and compared with the published UI-source versions: [Retail](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/version.txt), [MoP Classic](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic/version.txt), [Anniversary](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_anniversary/version.txt), [Era](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_era/version.txt). The Forever release build matches the [Forever UI source](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/version.txt); only that branch defines `WOW_PROJECT_CAMELOT`. Blizzard's [current hotfix page](https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-september-10-2026) lists the active game families. The [Forever announcement](https://news.blizzard.com/en-us/article/24302093/carve-a-new-path-with-world-of-warcraft-forever) is not evidence of addon API compatibility.

## Compatibility mechanisms checked

- Lua 5.1 syntax and no external addon dependency.
- CVar access uses `C_CVar` with legacy global fallbacks; metadata access supports `C_AddOns` and the older global API.
- Audio reads, writes and device APIs are checked. Unsupported controls fail gracefully; device changes are validated and read back.
- Modern Blizzard dropdown menus and the attached legacy fallback are tested separately. Menu initializers use `SetFontObject`; the disallowed compositor `SetFont` access is absent.
- Retail uses its own skin; Mists, Anniversary and Era use Classic styling. From 0.4.0, WoW: Forever uses its own look: the client's window frame (`ButtonFrameTemplateNoPortrait` with Forever's art; on the compact bar its pieces cut to the metal band), its close button, slider track and action-button icon frame, each only on the Forever client and only if `C_Texture.GetAtlasInfo` knows the atlases, because Mists, the Anniversary realms and Era draw other art under some of these names. Without them a flat stand-in drawn in code takes their place. The look follows the client; there is no setting to change it. Pixel alignment has a fallback when `PixelUtil` is absent. The Forever look's one-pixel lines use `PixelUtil.GetPixelToUIUnitFactor()` (or the physical screen height) and fall back to one UI unit if the effective scale is secret. Its slider thumb is the client atlas `Minimal_SliderBar_Button` if `C_Texture.GetAtlasInfo` knows it, and the sprite otherwise.
- Optional event registration is protected against unavailable events.
- Placement only moves Soundstone. It reads public frame bounds and skips forbidden, hidden, inaccessible and secret-valued frames. The relevant [Blizzard frame API declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) explicitly allow some properties to be secret. It does not modify protected Blizzard frames.

The placement option reserves no space globally. It checks visible interactive/movable frames at the instant the drag ends; full-screen input containers are excluded, but their readable controls are considered. Newly opened windows, decorative noninteractive regions, or unavailable bounds can still overlap later. If no placement is found, the previous position is restored and a chat message explains why.

## Remaining in-game checks

For each family/mode: startup and `/reload`, master/SFX/music switching, zero-volume restoration, external Blizzard audio changes, speakers/headset selection, combat, Escape layers, placement near action bars/minimap/windows, and 1080p/1440p at WoW scale 65/85/100% with Soundstone 75/100/150%.

For 0.4.0, check on every client that the 0.3.8 look stays pixel for pixel outside Forever, that on Forever the frame sits flush with Soundstone's own edges on the windows and the bar with nothing overlapping them, and that the one-pixel dividers and the slider thumb work there. The flat stand-in appears only where a piece of Forever's art is missing and is covered by simulated scenarios. The checks are listed in the [in-game checklist](curseforge/INGAME-TEST.md).

Future patches require checking Interface metadata, changed APIs and client rendering again. Historical/private clients and unreleased clients are not covered by a blanket “all versions” promise.
