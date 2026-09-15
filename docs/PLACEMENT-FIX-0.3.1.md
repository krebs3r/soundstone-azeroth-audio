# Retail placement fix: 0.3.1 test build

## Report and diagnosis

The user reported a roughly two-second freeze when dropping Soundstone in Retail, and confirmed that disabling placement avoidance removes it. They also reproduced overlap with Blizzard action icons while every addon except Soundstone was disabled. This rules out requiring BetterBlizzFrames to reproduce the problem.

In 0.3.0, `FinishDrag` synchronously enumerated all client frames and then searched and sorted obstacle intervals at every candidate x position, even when the requested drop position was already free. The collection filter also required mouse input or movement, excluding noninteractive layout containers. The precise failed frame getter in the user's client has not been measured; the new code explicitly reserves readable Blizzard action-bar geometry independently of these input flags.

## Correction

- Walk visible descendants of UIParent and WorldFrame instead of globally calling EnumerateFrames. Prune hidden, forbidden, Soundstone-owned and already reserved bar subtrees.
- Reserve readable Blizzard action-bar containers even if their mouse flags cannot be queried. Do not read protected button state, change another frame, or bypass secret geometry restrictions.
- Return immediately for a free clamped drop position. Prune candidate columns that cannot improve the current closest result.
- Split collection, searching and merge sorting into a coroutine resumed by Soundstone's OnUpdate handler. Each resume yields after 200 operations or approximately 2 ms; individual native API calls cannot be interrupted. A two-second overall deadline restores the prior position if the check cannot finish.
- Remove OnUpdate when done or cancelled. A new drag, hide, view/scale change, reset or disabled option cancels the pending result. An unverified position is not retained on cancellation unless an explicit new position replaced it.
- Reserve three UI units of clearance to allow for final pixel rounding.

## Validation

771 scenarios passed across five API/client configurations and both menu backends, including 60 new invocations for free placement, hidden-pool pruning, Blizzard bars with inaccessible input flags, scale combinations, cooperative solving/sorting, deadlines and cancellation. The release/installation suite passed 22 tests locally; the symlink test requires privileges unavailable in the local Windows test context. Package validation passed.

Lua 5.1 benchmark of the actual `Placement.Find` with an unobstructed drop and 4,000 synthetic rectangles: **2,960.70 ms before, 0.17 ms after**. These are local solver measurements, not Retail frame timings or a claim about every layout.

## In-game verification required

1. Close Retail; install the test ZIP with `python tools/install-local.py --client retail --archive dist/Soundstone-0.3.1.zip --install`.
2. Start Retail and confirm the footer says 0.3.1. Enable **Überlappung beim Ablegen vermeiden**.
3. Drag to open space, then directly onto the main action bar and additional action bars. Test compact and expanded views, including the current 75% WoW UI scale. The bar should settle outside the action icons without a multi-second freeze.
4. Repeat at addon sizes 75%, 100%, 150%, during combat and after `/reload`. Also try dragging again before a previous check has finished, hiding, resetting the position and disabling the option.
5. If placement still fails, `/dump Soundstone.Placement.lastStats` shows the last check's scanned-frame count, reserved-bar count, obstacle count, number of steps, maximum measured slice time and completion status. This is transient diagnostic data and does not change settings.

Retail acceptance remains pending. No 0.3.1 CurseForge release is approved by these simulated tests. The historical v0.3.0 tag, release ZIP, and TBC acceptance remain unchanged.

## API references

- [Blizzard MainActionBar layout](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ActionBar/Mainline/MainActionBar.xml)
- [Blizzard action button containers and layout](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ActionBar/Shared/ActionBar.lua)
- [Blizzard frame API: GetChildren, alpha and scale access](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua)
