# Validation status

Version: 0.2.0 validation build. Client metadata baseline checked on 2026-09-14; automated checks on 2026-09-15.

## Automated

**126 passing scenario checks** in real Lua 5.1, running the actual addon source against bounded frame/CVar test doubles. Five configurations: Retail, Mists Classic, TBC Anniversary, Classic Era and an unknown-client/global-API fallback. These labels select simulated APIs and locale; they do not run or emulate the game engine.

Original audio coverage is retained: startup without CVar writes, initialization once, master/channel independence, mute preservation, zero/100% boundaries, rounding, invalid input, sliders, wheel and Shift-wheel, external changes without feedback writes, missing APIs, rejected/ignored/throwing writes, commands, minimap interactions, no idle update loop, reload persistence and corrupt settings recovery. View assertions reflect 0.2's mutually exclusive views.

New coverage: device selection and exactly one restart, unchanged selections, missing/reordered/unplugged devices, unavailable APIs, rejected writes and restart failure, external device changes and long lists, six grip dots, proportional icons, shared anchors, layered Escape, drag/click suppression, hidden state and legacy position migration.

The geometry test exercises **36 combinations per API configuration**: 1920 × 1080 and 2560 × 1440, WoW scales 65/85/100%, Soundstone sizes 75/100/150%, and both views. It verifies inherited scale, screen clamping and pixel alignment. It cannot establish readable text, texture rendering or correct physical hit targets inside WoW.

Package validation checks TOC entries, binding XML, all fourteen textures' dimensions and real alpha, ZIP integrity and the single installable folder. The HTML preview displays the same exported texture pixels with approximate browser fonts.

## In-game

| Client | Build baseline | Version 0.2 status |
| --- | --- | --- |
| Retail | 12.1.0.69814 | Pending |
| Mists Classic | 5.5.4.69585 | Pending |
| TBC Anniversary | 2.5.6.69795 | Initial 0.2 mixer/options rendering observed at 2560 × 1440; final corrections awaiting reload |
| Classic Era / Hardcore / SoD | 1.15.9.69722 | Pending |
| WoW: Forever | Not available for this test | Unverified |

Earlier 0.1 Anniversary checks confirmed loading, visible audio values and synchronization with changes in Blizzard's Audio menu. They do not validate the replaced 0.2 renderer or device selection.

The first 0.2 observation showed the new Classic mixer, options and the client's system-default device name. It caught stretched borders on wide menu buttons and a slider fill covering the thumb. The source now uses sliced button corners and explicit frame ordering for slider decorations; this correction still needs a fresh live check. No audible output-device test or final visual approval has been recorded.

## Remaining acceptance checks

- Capture each design in the game at the reference's comparison size. Overlay the captures with `design-concept.png` and inspect enlarged frame, corner, grip, icon and close-button crops. Transparent corners, six dots, correct icon proportions, aligned click targets and no clipped or overlapping text are required.
- Repeat the 1080p/1440p, WoW 65/85/100% and Soundstone 75/100/150% matrix in actual clients. The automated matrix is supplementary evidence only.
- Test speakers and headset by listening, restore the original device, and verify unchanged volumes and mute switches. Test external changes in Blizzard's menu and unplugging the selected device.
- Test switching views, device/menu/panel Escape order, grip click versus drag, minimap controls, screen edges, `/reload`, relog and combat use without protected-action errors.
- Check Retail, MoP Classic, TBC Anniversary and Classic Era individually. Check Hardcore and SoD separately even though they share a client family.
- Add genuine in-game screenshots after these checks. Do not label generated art or browser previews as in-game captures.

Device enumeration and the output CVar follow the client UI's [Audio.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Audio.lua). For future patches, verify `GetBuildInfo()` and public APIs, update the TOC Interface list, run tests and repeat client smoke tests. Loading successfully alone does not establish future-client compatibility.
