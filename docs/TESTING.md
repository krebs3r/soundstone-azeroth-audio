# Validation status

Version: 0.3.2. Client metadata rechecked against installed builds and UI sources on 2026-09-15; automated checks on 2026-09-15. Publication was explicitly requested on 2026-09-15; this does not certify in-game coverage for every client.

## Automated

Placement tests cover nearest-free-position search, visible-frame collection, cooperative time limits, cancellation, scaled Blizzard action bars and expansion from the compact view. Routine audio refreshes preserve pending checks. The removed in-game release notes no longer have runtime or layout tests. The final 0.3.2 package, including its smaller minimap logo, was confirmed in [Retail](curseforge/acceptance/v0.3.2-retail.md) and [TBC Anniversary](curseforge/acceptance/v0.3.2-anniversary.md) on 2026-09-15. MoP Classic and Classic were additionally confirmed for 0.3.2 on 2026-09-16 (see below). The full scale/resolution matrix still requires in-game inspection.

**983 passing scenario checks** execute the actual addon in Lua 5.1 against bounded frame/CVar doubles. Six configurations represent Retail, Mists Classic, TBC Anniversary, Classic Era, the WoW: Forever beta and an unknown-client/global-API fallback; each runs with native and fallback dropdown menus. These are API simulations, not the game engine.

Audio checks cover startup without writes, mute preservation, zero/100% boundaries, rounding, sliders and wheel steps, external changes, missing APIs, rejected/ignored/throwing writes, slash commands, bindings, minimap behavior, reload and corrupt saved settings. The audio matrix runs 192 switch/zero-volume transitions per configuration/backend. Additional cases cover effects/ambience/dialogue grouping, music-only activation while master is blocked, mixed external settings, positive-volume history, first-use fallbacks, readback, every write-failure position and failed rollback. Voice/pet/error-speech settings remain untouched. Synchronous CVar callbacks cannot display intermediate group states.

The existing geometry matrix covers 1080p/1440p, WoW scale 65/85/100%, addon scale 75/100/150% and both views. It checks inherited scale, all four screen corners, icon clearance, equal grip dots, dropdown alignment and pixel positioning. The new options matrix additionally tests four corners plus the center in every combination: matching left edges, 276-unit width, a four-unit gap, above/below selection, no overlap, screen containment, 256-unit dropdown width and restoration of the saved position. It verifies all three header click areas remain 20 × 20 with aligned tops. A dedicated case covers temporary repositioning when neither side initially has room, including a pending size change that is cancelled on close.

Header-control tests cover common normal/hover/pressed colors, right-button suppression, release/re-entry, mouse release outside, hide cleanup, tooltips, title clearance and order **hide → compact view → X**. Existing direct view/hide actions, layered Escape, shared position, minimap independence, pending-size cancellation and reload restoration remain covered. The compact button keeps its existing geometry and plate states.

Device cases include one restart per successful change, unchanged/rejected selections, unavailable APIs, restart failure, unplugged/reordered devices, stale index/name checks, external changes, long names, six-row scrolling, outside clicks, second clicks and menu closure on view changes. Native frames are simulated outside UIParent with independent menu-manager Escape ownership.

The reported native `SetFont` error was reproduced by rejecting even a method lookup on compositor-managed labels. The corrected code creates one shared Font object outside the initializer and uses `SetFontObject`, following the [menu guide](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua) and [compositor restrictions](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_Menu/Compositor.lua). Repeated opening, selection and regeneration are tested. The prior unrestricted FontString mock missed this bug.

Package validation checks TOC entries, XML, 24 runtime textures, real alpha, atlas agreement, ZIP integrity and one installable folder. HeaderHide, HeaderCompact and HeaderClose must have identical dimensions, byte-identical alpha silhouettes and matching outer-frame pixels. Their PNG previews come from the same export as the TGA files.

The scenario count counts test invocations, not every assertion inside the matrices. Approximate font metrics and API doubles cannot establish in-game font rendering, physical hit targets or audible device switching.

## Release UI and screenshots

The README uses three high-resolution **0.3.2** browser mockups: Retail mixer, Classic mixer and compact Classic with German options. They use the production-asset renderer and current layout/version metadata. Fonts and native widgets are approximated. See [export instructions](screenshots/README.md) for dimensions, provenance and regeneration.

The older 0.3.0 overview/details PNGs remain historical references. Their release-notes popup was removed in 0.3.2 and is not shown in the current README.

The installable package is validated locally and in GitHub Actions. The release uploads its ZIP and corresponding SHA-256 file. Source archives are not the recommended installation artifact.

## Remaining in-game acceptance

Retail and TBC Anniversary have user acceptance for the final 0.3.2 package, linked above. On 2026-09-16, after the initial 0.3.0 acceptance, the user also confirmed **0.3.2** working in [MoP Classic 5.5.4](curseforge/acceptance/v0.3.2-mists.md) and [Classic 1.15.9](curseforge/acceptance/v0.3.2-era.md). This confirms all four client families for 0.3.2, but does not establish separate Classic game-mode coverage. For remaining client and matrix checks, verify game/headset output, combat, external Blizzard audio changes and `/reload`. Compare both skins at 1080p/1440p, WoW scale 65/85/100% and Soundstone scale 75/100/150%. Check German/English option text, the version footer, frame edges and device dropdown near screen corners.

The simulated configurations are not live client runs. See [COMPATIBILITY.md](COMPATIBILITY.md) for verified client build numbers and outstanding coverage. Forever remains unconfirmed.
