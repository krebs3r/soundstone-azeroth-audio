# Validation status

Version: 0.3.0. Client metadata rechecked against installed builds and UI sources on 2026-09-15; automated checks on 2026-09-15. Publication was explicitly requested on 2026-09-15; this does not certify in-game coverage for every client.

## Automated

The latest extension adds seven scenarios per API/backend configuration: an independent exhaustive-grid oracle for nearest free placement; frame filtering and unavailable/secret API values; drag placement throughout the scale matrix; opt-out, locking and no-space rollback; distinct short tooltips; title fitting and paged release-note behavior; and release-note screen containment. Reload also preserves the new overlap preference. UTF-8 font metrics in the mock count characters instead of bytes; real client glyph widths still require in-game inspection.

**711 passing scenario checks** execute the actual addon in Lua 5.1 against bounded frame/CVar doubles. Five configurations represent Retail, Mists Classic, TBC Anniversary, Classic Era and an unknown-client/global-API fallback; each runs with native and fallback dropdown menus. These are API simulations, not the game engine.

Audio checks cover startup without writes, mute preservation, zero/100% boundaries, rounding, sliders and wheel steps, external changes, missing APIs, rejected/ignored/throwing writes, slash commands, bindings, minimap behavior, reload and corrupt saved settings. The audio matrix runs 192 switch/zero-volume transitions per configuration/backend. Additional cases cover effects/ambience/dialogue grouping, music-only activation while master is blocked, mixed external settings, positive-volume history, first-use fallbacks, readback, every write-failure position and failed rollback. Voice/pet/error-speech settings remain untouched. Synchronous CVar callbacks cannot display intermediate group states.

The existing geometry matrix covers 1080p/1440p, WoW scale 65/85/100%, addon scale 75/100/150% and both views. It checks inherited scale, all four screen corners, icon clearance, equal grip dots, dropdown alignment and pixel positioning. The new options matrix additionally tests four corners plus the center in every combination: matching left edges, 276-unit width, a four-unit gap, above/below selection, no overlap, screen containment, 256-unit dropdown width and restoration of the saved position. It verifies all three header click areas remain 20 × 20 with aligned tops. A dedicated case covers temporary repositioning when neither side initially has room, including a pending size change that is cancelled on close.

Header-control tests cover common normal/hover/pressed colors, right-button suppression, release/re-entry, mouse release outside, hide cleanup, tooltips, title clearance and order **hide → compact view → X**. Existing direct view/hide actions, layered Escape, shared position, minimap independence, pending-size cancellation and reload restoration remain covered. The compact button keeps its existing geometry and plate states.

Device cases include one restart per successful change, unchanged/rejected selections, unavailable APIs, restart failure, unplugged/reordered devices, stale index/name checks, external changes, long names, six-row scrolling, outside clicks, second clicks and menu closure on view changes. Native frames are simulated outside UIParent with independent menu-manager Escape ownership.

The reported native `SetFont` error was reproduced by rejecting even a method lookup on compositor-managed labels. The corrected code creates one shared Font object outside the initializer and uses `SetFontObject`, following the [menu guide](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua) and [compositor restrictions](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_Menu/Compositor.lua). Repeated opening, selection and regeneration are tested. The prior unrestricted FontString mock missed this bug.

Package validation checks TOC entries, XML, 24 runtime textures, real alpha, atlas agreement, ZIP integrity and one installable folder. HeaderHide, HeaderCompact and HeaderClose must have identical dimensions, byte-identical alpha silhouettes and matching outer-frame pixels. Their PNG previews come from the same export as the TGA files.

The scenario count counts test invocations, not every assertion inside the matrices. Approximate font metrics and API doubles cannot establish in-game font rendering, physical hit targets or audible device switching.

## Release UI and screenshots

The release-note window is **300 × 160**, identical to the expanded mixer. A new scenario in each backend/configuration verifies unique version cards, boundaries, counter text, navigation clamping and separation between text and navigation buttons. There are two cards: 0.3.0 and 0.2.0. Existing Escape, screen-edge and scale-matrix cases still pass.

The README images are full-page screenshots of `readme-gallery.html` and `readme-details.html`, using the production-asset renderer. They show current Retail/Classic views, options and the resized changelog. They are explicitly labeled browser previews; actual Blizzard widgets and font rendering may differ.

The installable package is validated locally and in GitHub Actions. The release uploads its ZIP and corresponding SHA-256 file. Source archives are not the recommended installation artifact.

## Remaining in-game acceptance

Load this build in each target client, check game/headset output, combat, external Blizzard audio changes and `/reload`. Compare both skins at 1080p/1440p, WoW scale 65/85/100% and Soundstone scale 75/100/150%. Check German/English card text, the version footer, frame edges and device dropdown near screen corners.

The simulated configurations are not live client runs. See [COMPATIBILITY.md](COMPATIBILITY.md) for verified client build numbers and outstanding coverage. Forever remains unconfirmed.
