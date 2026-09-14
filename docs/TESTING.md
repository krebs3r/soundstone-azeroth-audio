# Validation status

Version: 0.1.0. Baseline client metadata checked on 2026-09-14.

## Automated

**71 passing scenario checks** in real Lua 5.1, running the actual addon source against bounded frame/CVar test doubles. Five configurations: Retail, Mists Classic, TBC Anniversary, Classic Era and an unknown-client/global-API fallback. These labels select simulated APIs and locale; they do not run or emulate the game engine.

Covered: startup without CVar writes, initialization once, master/channel independence, mute preservation, zero/100% boundaries, rounding, invalid numeric input, sliders, wheel and Shift-wheel, external changes without feedback writes, missing APIs, rejected/ignored/throwing writes, slash commands, minimap interactions, no idle update loop, reload persistence and recovery from corrupt saved settings.

## In-game

| Client | Build baseline | Status |
| --- | --- | --- |
| Retail | 12.1.0.69814 | Pending |
| Mists Classic | 5.5.4.69585 | Pending |
| TBC Anniversary | 2.5.6.69795 | Partial live smoke test: discovered on `/reload`; bar, icons, percentages and mixer display; right-click opens mixer. Final opaque-background correction installed, awaiting visual confirmation. |
| Classic Era / Hardcore / SoD | 1.15.9.69722 | Pending |
| WoW: Forever | Not available for this test | Unverified |

In-game checklist: fresh install discovery; bar, panels and texture display; audio heard from each channel; muted sliders; original WoW shortcuts/settings; minimap interactions; screen clamping; different UI scales; `/reload` and relog persistence; combat use without protected-action errors. Check Hardcore and SoD separately even though they share a client family.

The TBC test displayed the client's existing master 100% enabled, SFX 100% disabled and music 40% disabled without resetting these settings. A subsequent user-driven change to music 45% appeared in both panel and bar. Further changes in Blizzard's Audio settings to music 35% and effects 0% were also reflected in the quick bar; the zero-volume effects icon displayed its crossed state. No claim is made that audio output or combat behavior has been verified yet. The initial live check caught a missing/transparent legacy backdrop; the current source uses a solid-color native texture instead.

For future patches, verify `GetBuildInfo()` and the public CVar APIs, update the TOC Interface list, run tests and repeat client smoke tests. Do not advertise an untested future client as compatible merely because it loads the addon.
