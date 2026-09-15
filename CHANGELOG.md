# Changelog

User-facing changes are grouped by version. Unreleased entries describe local work and do not imply a GitHub release or verified support for every WoW client.

## 0.3.1 — Unreleased

### Fixed

- Placement avoidance now traverses visible UI trees in small batches instead of scanning every client frame synchronously. Hidden pooled frames and Soundstone's own controls are excluded early.
- Free drop positions return immediately; blocked positions use a yielding search and sort so larger layouts can be processed across rendered frames.
- Visible Blizzard action-bar containers are reserved even when their mouse-input flags are disabled or inaccessible. Forbidden or secret geometry remains excluded.
- Pending placement work is cancelled on a new drag, hide, scale/view changes or position reset. It never applies an outdated result after those actions.

Retail in-game verification remains pending. Historical 0.3.0 packages and its TBC acceptance are unchanged.

## 0.3.0 — 2026-09-15

This version collects the changes made after the 0.2.0 baseline.

### Added

- Installable GitHub release ZIP with English/German installation instructions and current UI-preview screenshots in the README.

- Optional placement avoidance: choose the nearest free spot beside visible, readable UI controls when a drag ends; restore the previous position if none is available. The preference survives reload. Other windows are never moved.
- Short in-game release notes opened from the version footer: 300 × 160, matching the mixer, with one readable English/German card per version and layered Escape handling.
- A current-client compatibility audit that separates target APIs and simulated tests from outstanding in-game acceptance, including unconfirmed Forever support.

- Dedicated settings gears beside the six-dot drag grips in both views.
- Direct expand/collapse buttons in both views and a hide button in the expanded header, with localized tooltips and hover/pressed states.
- `/soundstone hide` and `/soundstone show`. Slash commands and minimap left-click restore the last hidden view, including after reload and with the minimap icon disabled.
- A metadata-driven version footer with a graphical heart and **by krebs3r**.
- Saved last-positive volumes, restored by an explicit enable action at 0%. First-use activation without history uses 50% for master/effects/ambience/dialogue and 25% for music; startup does not change audio settings.

### Changed

- Context-specific, concise hover help for compact controls, expanded buttons and sliders.
- The expanded title fits “Soundstone – Azeroth Audio” within its existing header; the complete title remains available on hover.

- Compact bar reduced from 300 × 45 to 276 × 36 UI units. Three equal 68-unit audio areas have fixed percentage fields; compact icons fit proportionally within 22 × 22 and retain their centers.
- Options resized to 276 × 236 with full-width reset buttons on separate rows. View/hide actions moved from options into the main UI. The expanded mixer remains 300 × 160.
- Mixer icons fit within 18 × 18 and allow extra clearance for pixel-rounded Classic borders; click areas remain 25 × 25.
- Inaudible channels use gray, dimmed icons without red strike-through marks.
- The expanded header now orders hide, compact view and X on the right. All three use the same red/gold frame, identical alpha silhouettes and 20 × 20 click areas. The compact view button retains its dark metal styling and 19 × 19 click area; the gear stays unchanged.
- Size adjustments preview only the percentage while dragging and apply once on release. Closing or hiding cancels pending changes; the explanation moved into the tooltip.
- Audio/option buttons use Blizzard templates. Output labels shortened to “Output device” / “Ausgabegerät”, with left-aligned, vertically centered selection text.
- Output-device selection now opens an attached native Blizzard radio dropdown, with an attached fallback for older menu APIs. Both support six visible rows, scrolling, full-name tooltips, effective scaling, screen-edge flipping and one-layer Escape. The separate device window was removed.
- Sound effects now groups effects, ambience and dialogue. The switch controls all three; its slider sets all three levels together. Toggling retains individual positive levels, and short tooltips identify partially active groups. Voice chat stays separate.
- All audio controls use effective audibility: master off or at 0% makes the child groups appear off too. Enabling one group while master is blocked opens master for that group only. With master already active, the other group is left unchanged.
- Master mute retains the individual selection. Enabling restores that selection, or activates both groups if all individual channels were switched off. Moving a muted slider does not unmute it.
- README, German instructions, production-asset preview and local packages updated throughout the refinements.

### Fixed

- Master/child button states disagreeing with muted icons, and compact music activation failing when master was off. Icons, mixer buttons, bindings and commands now share one activation path.
- Multi-channel changes are read back, with rollback on failure and an error if restoration also fails. Synchronous CVar events no longer display intermediate states or corrupt volume history.
- Native dropdown Lua errors: compositor-managed labels now receive a shared Font object through `SetFontObject`; their forbidden `SetFont` method is never accessed.
- Device-list regeneration during an active selection, stale index/name pairs, lost devices, failed selections and external changes while a list is open. Rejected selections are not displayed as successful switches.
- Reset text clipping, uneven expanded-view grip dots, underspecified menu click targets and slider fills covering the thumb.
- Screen clamping uses actual view dimensions. View changes and hiding close all attached menus, preserve the last view and keep minimap visibility independent.
- Tests now enforce Blizzard's native-menu font restrictions. Coverage increased from 126 baseline scenarios to 711 invocations across five API configurations and both menu backends, with additional audio-state, failure, geometry and reload matrices inside those cases.

### Approved layout implemented

- Options matching the compact bar's 276-unit width, attached directly below it with a four-unit gap and opening above near the bottom edge.
- Expanded header ordered **hide → view switch → close** on the right; hide and view switch reuse the exact red/gold close-button frame. All three share 20 × 20 dimensions, the same visible alpha silhouette and centered glyphs. Compact controls retain their existing styling.
- Both views attach options vertically. If neither side has room, the visible pair shifts temporarily without saving the offset; closing options restores its position. Added scale-matrix and pointer-state regression coverage.
- See the [approved mockup](docs/ui-mockup-0.3.html) and [production-asset preview](docs/ui-preview.html). Local in-game acceptance remains pending.

## 0.2.0 — Baseline

- Custom Retail and Classic skins based on the approved concept, with sliced corners, proportional transparent icons, six grip dots, a red close button and diamond slider thumbs.
- Mutually exclusive compact and expanded views sharing one saved position, with screen clamping and layered Escape handling.
- WoW output-device enumeration, validated selection and a single audio-system restart per successful change.
- Additional 75–150% addon scale following WoW UI scale, and migration of the earlier bar position and visibility.
- English/German documentation, asset provenance, installable ZIP and automated Lua/package checks. In-game coverage remained incomplete.

## 0.1.0 — Initial implementation

- Master, effects and music controls, movable compact bar and mixer, minimap button, mouse-wheel volume, slash commands and optional bindings.
- English/German UI, saved layout preferences and compatibility adapters for target Retail and Classic clients.
