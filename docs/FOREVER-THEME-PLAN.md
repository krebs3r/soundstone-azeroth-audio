# WoW: Forever in its own look: plan

Status: **approved on 8 November 2026, revised on 9 November 2026** after the first look in game, **and released in 0.4.0 on 10 November 2026**. The first draft (flat plates, one-pixel lines) was seen on Forever and read as foreign next to Forever's own windows, so the mixer, the options and the compact bar now wear Forever's window frame. See [Revision: Forever's own frames](#revision-forevers-own-frames). On 10 November 2026 the theme switcher was removed: the look follows the client, with no command or saved setting, because the other clients cannot draw Forever's frames. Sections below that describe `/soundstone theme` and switching without `/reload` record the earlier design; the code keeps `UI:ApplyTheme(name)` for the tests. The frames of the mixer and the compact bar were seen and accepted in game on 9 and 10 November 2026 (Forever 1.60.1, client scale 0.7, Soundstone 100%); the options window in the frame and other points of the in-game checklist have no documented in-game check.

The mockup comes in two files:
- [ui-mockup-forever.png](ui-mockup-forever.png): 1.3125 pixels per UI unit, the scale the Forever values were measured at.
- [ui-mockup-forever-2x.png](ui-mockup-forever-2x.png): the same pixels, each drawn as 2 × 2.

Regenerate both with `python tools/mockup.py forever`. Without an argument the tool still writes the 0.3 boards byte-identically (on Windows the HTML page gets CRLF line endings, as before; git normalizes them).

## Goal

On WoW: Forever, Soundstone should wear Forever's own design language, as Umbra Unit Frames does since 0.9: flat near-black plates, a one-pixel bronze line, the gold window title, and nothing that reads as foreign chrome. On Retail, Mists Classic, the Anniversary realms and Classic Era, nothing changes.

**A theme changes the surface, never the information.** These keep their look:
- the volume fill and the values;
- the mute state of an icon, on/off and availability;
- the selected device;
- every Blizzard control.

## What Forever shows today

### Detection

**How Forever is recognized:**
- The release client (build 1.60.1.70862, interface 16001) sets `WOW_PROJECT_ID = WOW_PROJECT_CAMELOT` (18). The source is `Blizzard_ProjectConstants/Camelot/ProjectConstants.lua` on the `forever` branch of Gethe/wow-ui-source; no other branch defines the constant.
- `C.IsForever()` checks the interface number (16000–16999), so it is true on the beta and on release.
- `C.RetailStyle() = C.IsRetail() and not C.IsForever()` is false on Forever.

**What Forever gets today:**
- the Classic plates ClassicBar and ClassicPanel (`UI.lua:577`)
- SilverThumb (`UI.lua:303`)
- the ClassicPanel icon wells (`UI.lua:333`)
- the Rivet grip, which is the same on every client

**Finding: `C.IsRetail()` is false on Forever's release client.** It only compares `WOW_PROJECT_ID` with `WOW_PROJECT_MAINLINE`, and Forever reports 18. No Retail behavior is lost because of it:
- Its only caller is `C.RetailStyle()`, which is meant to be false on Forever anyway, and already was on the beta.
- Every functional branch uses feature detection, and every detected feature exists on the `forever` branch: the addon compartment, the native Menu dropdown, `C_CVar`, `C_AddOns`, `PixelUtil`, `GetMouseFoci`, `hooksecurefunc`, `issecretvalue` and `SetDontSavePosition`.
- Placement finds the same 13 of its 17 action-bar names as on Retail. The four Classic-only names are absent on both and are skipped.
- The minimap button follows `RetailStyle()` and so keeps the Classic geometry. The user accepted that geometry on the Forever beta (0.3.5). It is off by default there, because the compartment exists.

**Finding: `python tools/install-local.py --client forever` installs into `_classic_beta_`.** That was the beta's folder. The release client loads its addons from `_forever_` (`tools/install-local.py:14`).

These descriptions still date from the beta. All are left as they are until implementation:
- `Compat.lua:24` says Forever runs "project MAINLINE".
- The Forever configuration in `tests/run.py:24` uses project 1, i.e. the beta.
- `docs/COMPATIBILITY.md:11` (beta, build 70450, `_classic_beta_`).
- `README.md:53`.
- `docs/TESTING.md:9` and `:37`.
- `docs/ANLEITUNG-DE.md:91` and `:108`.

### Blizzard's own controls on Forever

**Templates.** Soundstone's controls come from four Blizzard templates. Their definitions are byte-identical to `live`:
- `UIPanelButtonTemplate` (on/off and reset buttons)
- `UICheckButtonTemplate`
- `WowStyle1DropdownTemplate` and the Menu system
- `GameTooltip`

The surrounding Lua on Forever only adds or fixes things that do not change their look: gamepad support, clamping for multi-column menus, a nil guard. The Menu frame itself loads `Camelot\Menu.xml` instead of `Menu.xml`, but that file only adds gamepad focus.

**Forever's own art.** Forever ships its art on the data side, under the same names. `Blizzard_SharedXML/Camelot/NineSliceLayoutOverrides.lua` corrects offsets because "the art made for Camelot doesn't match the exact size of the Mainline Standard art". The source proves such remade art only for the `UI-Frame-Metal` atlases.

**What Forever draws inside Soundstone today**, captured enabled and lossless on 8 November 2026 with the expanded panel, the options and the device list open:
- **On/off and reset buttons** (`UIPanelButtonTemplate`): Retail's red art.
  - Dark edge, and a gray rim that is lighter at the top (#4A494A–#504E50) than at the bottom (#363536).
  - Red body from #460000 over #6B0000 to #3F0000 (median of the middle rows #640203).
  - Label #FFD200.
- **Checkboxes** (`UICheckButtonTemplate`): Retail's art.
  - Near-black box #0D0D0D with a gray rim.
  - Check #FFFB21.
- **Device field** (`WowStyle1DropdownTemplate`): Forever's own art.
  - Ground #110E09 (the plaque's #110D09, one step off) inside a double bronze line.
  - Outer line #614F35 at the top, #645036 on the left, #55442E at the bottom; inner line #413424 at the top.
  - Chamfered corners; a gold arrow in a gray box with a bronze edge; text #FFFFFF.
  - Its art ends at the field's own 256 units, so nothing of it reaches the options plate's edge.
- **Device list** (the Menu system): Forever's own art.
  - **Line:** exactly one physical pixel wide on all four sides.
    - The top is #92744C and the bottom #755B3A.
    - Left and right are one vertical ramp between the two (#8F714A → #775D3B, #836743 at mid-height), the same on both sides.
    - So the list is lit from the top and darkens toward the bottom.
  - **Inside:**
    - Directly inside the top line, one dark pixel. It renders #0A0806 (10/8/6) over Soundstone's #1A1A1A plate; its own color is about #090705 at about 0.93.
    - Left, right and bottom go straight into the body.
    - The body renders #030303 over the plate, about 11% see-through, so the options behind it show faintly.
  - **Corners:** cut over 8–9 physical pixels (about 6 units). The top left is rounded with a gold highlight; the other three are straight 45° steps.
  - **Details:**
    - Text #FFFFFF.
    - Radio rings neutral gray (#333333–#4C4C4C, lit up to #878787); the selected dot is gold.
    - A soft shadow of about 7 px outside the line.
    - The list is wider than the field and sticks out 12 px past the options plate's right edge.

**Under the pointer**, a red button lights up and its label turns #FFFFFF, as on Retail. Its center reaches #D81404–#E51C10; the middle-row median is #AB0A02.

**Forever's own settings window** (Esc → Options → Audio), captured the same evening:
- **Slider** (`MinimalSliderTemplate`):
  - **Track:** a dark, translucent pill about 14 px (10.7 units) high with rounded ends and no fill.
    - It is black at about 40% opacity, so its colors follow what lies behind it.
    - Over the settings window its ground reads #131010–#1D1613 and its outline #453328–#4E382A (bottom #493629).
    - Over Soundstone's plate it would render about #0D0B0A, with an outline of about #3A2B1D.
  - **Thumb:** the atlas `Minimal_SliderBar_Button`.
    - A copper diamond 19 px (14.5 units) across, median #926545, lit from the top and brightest at its tip (#F1D6C1).
    - Around it, a near-black rim and shadow: the atlas region is about 26 px, i.e. about 20 units.
  - **Steppers:** bronze chevrons on both sides.
- **Checkboxes:** a near-black box (#100C08, ranging #100800–#181410), a chamfered bronze edge (#574639 top, #534336 / #493A2C sides, #5A4A39 bottom) and a gold check (median #EDC605). That is not the `UICheckButtonTemplate` art Soundstone shows.
- **Text:**
  - #FFD200 (`GameFontNormal`): the window title, the category entries, every setting label and every slider value.
  - #FFFFFF: the category headers, the selected entry and the page heading.
- **Frame:** a heavy textured bronze band with chamfered corners, i.e. the big-window art, not a one-pixel line.

Forever's control lines against `lineBottom` (104/80/52):
- device field 2.8 (top edge)
- settings checkbox 5.2–9.6
- slider track 9.8–12 over the settings window, about 14 over Soundstone's plate

Their grounds against `band`: checkbox 1.4–3.3; the track 2–5 over the settings window, about 0.7 over Soundstone's plate.

**Minimap and compartment.**
- Soundstone's minimap button uses raw file textures: `UI-Minimap-Background` and `MiniMap-TrackingBorder`.
- Forever's own minimap buttons use Camelot XML with other atlases.
- The addon compartment has Camelot XML and Lua of its own.

### Forever's design language, measured

**How it was measured.** Measured on 7–8 November 2026 with PIL, from lossless PNG screenshots of the release client.
- **Scale:** 20 PNGs from 7–8 November 2026. All with the UI shown are at 1.3125 physical pixels per UI unit, except two at 2.15625 (UI scale 1.15); one has the UI hidden. Soundstone's own bar confirms the scale: 362 × 47 px for 276 × 36 units, at a position exact to the pixel.
- **No post-processing:** UI colors come out bit-exact. Examples: Soundstone's #F5F0DE (.96/.94/.87), its divider blended to #695028, and Umbra's rim values. So the UI layer has no gamma or post-processing.

| Element | What was measured |
| :--- | :--- |
| Tooltip | **Line:** one UI unit wide, spread over 1–2 pixels. Lit from the top only: per unit the top is about #E5C9A1–#EACBA4; left, right and bottom are the same, about #B48F61.<br>**Inside the line:** a dark gradient of 5–6 pixels that starts near-black (#010101–#060404).<br>**Body:** translucent (about 0.7–0.75). Its darkest reading is #150F17; next to the edge it reads #161017, Umbra's value.<br>**Corners:** rounded over 3–4 pixels.<br>**Text:** titles and body lines #FFFFFF; a spell's description #FFD200. |
| Zone plaque | **Line:** three pixels on top, right and bottom (dark bronze, bronze, dark bronze) and two on the left. Then one dark pixel: #0F0B08 at the top, #0F0605 at the right, #120907 at the bottom.<br>**Brightness by side:** top #896C44 > left #715939 ≈ bottom #6D5438 > right #4E3822.<br>**Body:** translucent, #130E0A–#1D1C14.<br>**Corners:** 45° chamfers of about 3 px. The highlight on each diagonal is near-white at the top left (#FCF5D4) and duller elsewhere (#E2CAA3, #C1A78A, #B1916C). |
| Tracking box beside the plaque | Lit differently again: its right side is brighter than its left and bottom. |
| Trainer window | **Frame:** a 7-pixel textured bronze band, brightest at the bottom, then black.<br>**Title:** #FFD200.<br>**Close button:** red field #4F0201–#660201, gold X about #EDC001, bronze frame.<br>**Filter dropdown:** dark neutral #373737 → #1D1D1D with a bronze line and gold text. |
| Minimap ring | The lip is brightest at the top left: #E9C496 at 120°, #EABF8B at 135°. |
| Quest tracker header | #FFD200 |
| Device list (Blizzard's Menu inside Soundstone's options) | **Line:** one physical pixel. Top #92744C, sides a ramp from about the top color to about the bottom color (mid-height #836743), bottom #755B3A.<br>**Against Umbra's rim values:** top 4.6, sides 4.65 / 1.7 / 4.10 (top end / mean / bottom end), bottom 4.3 CIEDE2000.<br>**Inside:** one dark pixel under the top line, rendering 10/8/6 over Soundstone's plate. Then the body.<br>**Corners:** cut over 8–9 px. |
| Umbra's Forever theme | **Rims:** match its code: #9A805C, #806848, #685034. Each is one physical pixel, inside the frame, at both scales.<br>**Band:** none visible next to them.<br>**Corners:** square. |
| Soundstone today | **Plate:** opaque, about #1A1A1A.<br>**Edge:** silver-gray and beveled, with chamfered corners.<br>**Dividers:** 1 px #695028.<br>**Values:** #F5F0DE.<br>**Icons:** gold.<br>**Gear:** its brightest pixel is 154/134/97 under the tint .9/.8/.57, so the texture's gray is about 0.67. |

What follows from this for Soundstone:
- **Forever's lighting is not consistent.** The tooltip is lit from the top only. The plaque is lit from the top left. The tracking box has a bright right side, and the trainer band is brightest at the bottom.
- **Soundstone follows Forever's device list.** It is the closest relative of Soundstone's own panels: a small popup with a one-pixel line, and Forever draws it inside Soundstone's options.
  - The top is lightest and the bottom darkest. Left and right are equal, and run from one to the other.
  - Umbra's three values fit it within 5 CIEDE2000, so they stay: top 154/128/92, left and right 128/104/72, bottom 104/80/52.
  - The flat sides are about the ramp's mean (1.7 away). A ramp would cost a gradient texture per side for a difference of at most 4.7.
- **Inside the line:**
  - The device list has one dark pixel under its top line, which renders as Umbra's band value 10/8/6.
  - The plaque has one dark pixel inside every side; the tooltip has a gradient that starts near-black on every side.
  - Soundstone draws one pixel of 10/8/6 inside all four lines.
- **Corners:** Forever has no square corners, not even on the one-pixel line of its device list.
- **Umbra's notes:** its source gives Forever's panel lines as #9A846B → #8B6E4A. That matches the tooltip's line pixels where a one-unit line straddles two pixels. Umbra's palette, and this plan, use the darker 154/128/92 → 104/80/52.

## Revision: Forever's own frames

**Why.** In game, the flat draft looked unlike Forever's windows: the character frame, the bags (drawn by the addon Baganator) and Blizzard's settings all wear a thick bronze frame with a dark title strip. The decision mockup (not in the repository, because it was cut from screenshots) compared two bars: the thin HUD frame of Forever's action bars (variant B) and the window band all round (variant A, 22.9 units inside instead of 36). Variant B was built first; seen in game it did not look right next to the framed mixer, so the bar now wears variant A, the same frame as the windows.

**What Forever draws, and where** (measured on lossless screenshots at 1.3125 px per unit; the bag's frame rect was pinned from Baganator's saved position and code, Blizzard's Settings window was the second data point, and an independent re-measurement corrected the first pass):

- **Window frame.** Blizzard's `ButtonFrameTemplateNoPortrait` nine-slice with Forever's art (Camelot shifts its right corners by −2 and its bottom corners to −8). The opaque metal is 6.1 units wide on every side, with 5.3-unit chamfers; a translucent black glow reaches about 0.7–1 unit beyond it at the top, left and right and about 6 units below. Relative to the nine-slice's box the metal starts 4.4 units inside on the left and 3.35 above the top, and ends 0.5 and 0.35 beyond the right and bottom. The title strip spans 2.8 to 19.6 units below the box's top (center 11.2), the separator ends at 25.7, the flat ground starts at 26.4. The ground is `ButtonFrameTemplate`'s `UI-Background-Rock` with `_UI-Frame-TopTileStreaks`, 52/48/41 on Forever.
- **Header.** Baganator's buttons are Blizzard's `UIPanelButtonTemplate` at 32 × 22 with a 16-unit symbol: the first at TOPLEFT (8, 1), the right group against the close button's left edge at TOP +1. The close button is 28 × 28 at TOPRIGHT (0, 3) (`RedButton-*`). The title is `GameFontNormal`, 6 units below the box's top.
- **HUD frame.** `UI-HUD-ActionBar-Frame` on a plain texture, as on the main, micro-menu and bag bars. Its line band is 3 units wide and lies about 2.85 units inside the texture; the corners are chamfered 5.3 units and stay identical on bars 318 to 572 units wide, so the atlas is sliced horizontally (its edges tile every 23.1 units). Whether it is sliced vertically cannot be seen: every Blizzard host is 56 units tall. The interior is a translucent dark wash (#140d06 over Forever's brown ground). The dividers are `HorizontalDividerTemplate`'s three slices, 12 units wide, with V caps of about 9 × 4.5 units against the band.
- **Slider and icon frames.** Forever's settings use `MinimalSliderTemplate`: the pieces `Minimal_SliderBar_Left`, `_Minimal_SliderBar_Middle` and `Minimal_SliderBar_Right` at atlas size (about 11–12 units high, a pill whose interior starts about 4 units in) and the thumb `Minimal_SliderBar_Button`. Forever's action buttons wear `UI-HUD-ActionBar-IconFrame` at 46:45 on the button's top left, with `-Down` while pressed and `-Mouseover` on hover; the middle is open.

**What Soundstone does with it, on the Forever client only.** Mists, the Anniversary realms and Era draw `ButtonFrameTemplateNoPortrait` with their own borders and lack most of these atlases, and Retail has other art under some of the names. So `Theme.Art()` returns nothing outside Forever, and on Forever it checks every atlas with `C_Texture.GetAtlasInfo`; each piece falls back to the flat draft on its own:

- **Mixer and options:**
  - A border frame, ten levels above the window and without mouse, anchored TOPLEFT (−4.4, −3.35) and BOTTOMRIGHT (+0.5, +0.35), so the opaque metal ends on Soundstone's own edges. It carries the nine-slice; `NineSliceUtil.UpdateCornerCropping` crops its bottom corners where Forever has it.
  - The ground (rock and streaks) at `ButtonFrameTemplate`'s offsets.
  - The header as Baganator's, twelve levels up: gear on the left, hide and compact on the right, and Forever's close button, which switches to the compact view as Soundstone's X always did (Options: closes them). The gold symbols sit on the button art's center, 0.8 units below the rectangle's. Counted on lossless screenshots at 1.3125 pixels per unit, the 20-row red face then shows 3 rows above the 15-row symbol and 2 below, as close to the middle as whole pixels allow. Centered on the rectangle, as Baganator does, it was 1 above and 4 below (too high); one pixel lower than the art's center, 4 above and 1 below (too low).
  - The title strip between gear and hide drags the window and carries the title at size 12. Without room it falls back to "Soundstone" as before.
  - The panel's grip and header rule give way to the frame. The rows sit 37 units apart from 30 units down, and the footer moves to (−12, 10). The options' controls move up by up to 7 units, so everything clears the 8.3 units of band and shade at the bottom.
- **Compact bar:**
  - The same frame without its title strip. The layout's own pieces (with Camelot's offsets) are cut with texture coordinates set before `SetAtlas`, the way NineSlice mirrors pieces: the top corners and edge keep 8 units, from 5 above the box's top (glow included) to 3 below it, where the band's inner black line ends at 2.81; the bottom corners keep their lowest units up to 8 above the box's bottom, where band and inner shade end at 7.95; the bottom edge as much of that as it has; the sides run between them, tiled as their atlases say.
  - The same border offsets as the windows, so the opaque metal ends on the bar's edges and the 276 × 36 footprint stays. The windows' ground inside, and their streaks pressed to a 4-unit shade under the top band, as the art shades the other three sides.
  - Inside the band (6.1 units, plus about 2.5 of shade) the grip moves 2 units right. Vertically each piece's visible art sits on the middle of the band's opening: the red buttons 1 unit up (their art lies 0.8 units low in their rectangle), the channels half a unit down (the icons' ink lies about half a pixel high in theirs), the grip centered. On the last lossless screenshot, with everything 1 unit up, the icons and values sat 2 pixels high; the channel and grip positions were then set by calculation and confirmed by the user without a new screenshot. Gear and Expand become the mixer header's red `UIPanelButtonTemplate` buttons at the template's narrowest width, 24 × 22 (two 12-unit caps), at 25 and 49 units; the user chose this over a red Expand alone, a bare symbol and the action-button frame. The channels take 64 units each from 75, their values 2 units before the next divider. The one-pixel dividers stay.
  - If the pieces are too short to cut that way, the whole frame look falls back to the flat draft.
- **Sliders** wear the three track pieces, with the fill 4 units in from each end. The **channel icons** wear the action-button frame.

**Not known without the game** (checks in the [in-game checklist](curseforge/INGAME-TEST.md)):
- the atlas sizes and the rows of the band inside the top and bottom pieces, i.e. whether the bar's cut lands exactly on the band (measured to about ±0.3 units);
- whether the bottom corners need cropping at 160 units;
- how the action-button frame reads at 25 units;
- how Forever's `UIPanelButtonTemplate` art looks at 32 × 22 with Soundstone's symbols.

## What changes on Forever, and what does not

**Unchanged** means the same texture, color, size and behavior as 0.3.8. Values marked *(assumed)* are design choices, neither measured nor taken from Umbra. The full list with sources is in the [inventory](#inventory-what-each-element-wears-on-forever-today).

| Element | Forever today | Proposed on Forever |
| :--- | :--- | :--- |
| Bar, panel and options plate | ClassicBar / ClassicPanel nine-slice sprite | **Revised:** mixer, options and bar in Forever's window frame, the bar without its title strip (see the revision above). **Without that art (flat draft):** Flat plate 21/18/15 at 0.96. A one-pixel line: top 154/128/92, left and right 128/104/72, bottom 104/80/52. A one-pixel band 10/8/6 inside it. All within the frame's bounds; square corners |
| Drag grips | 6 Rivet sprites | 6 flat squares of 2 units *(assumed)*, snapped to whole pixels, muted. **Revised:** inside the window frame the mixer has no grip; its title strip drags |
| Gear | GEAR_64GREY tinted .9/.8/.57; hover white; pressed .6/.55/.4 | Same texture. Muted at rest, accent on hover, muted × 0.67 when pressed *(assumed: today's pressed/normal ratio)* |
| Expand button plate | ActionNormal / Hover / Pressed sprites | Flat well: band ground and a one-pixel 104/80/52 outline. Hover turns the outline accent. Pressed keeps the accent outline, and the glyph goes to .7 and 1 unit down as today |
| Expand glyph | Expand sprite, brightness .9 / 1 / .7 | **Unchanged** |
| Row icon well | ClassicPanel nine-slice, corner 3 | **Revised:** Forever's action-button frame with its pushed and highlight art. Flat draft: a flat well as for Expand, no hover. The icon keeps its size |
| Slider track | Toggle nine-slice, corner 2, 8 high | **Revised:** Forever's own track pieces at atlas height, fill 4 units in. Flat draft: band ground and a one-pixel 104/80/52 outline, 8 high. Forever's own track is a translucent pill whose outline renders darker (about 14 away over Soundstone's plate); the square, opaque track matches the rest of Soundstone's wells |
| Slider thumb | SilverThumb sprite, 10 × 18 | **The client's own thumb:** the atlas `Minimal_SliderBar_Button` that Forever's settings sliders use.<ul><li>On Forever, a copper diamond 14.5 units across inside a dark rim.</li><li>At the atlas's own size (`SetAtlas(name, true)`, about 20 × 20 units).</li></ul>**Fallback:** if `C_Texture.GetAtlasInfo` does not know the atlas, today's sprite thumb.<br>Its size and travel change: about 10 units less travel on a 98-unit slider |
| Slider fill | 255/176/33 | **Unchanged** (information) |
| Unavailable channel | slider, fill and track at alpha .35 | **Unchanged** |
| Bar channel dividers | 0.6 unit, .58/.43/.19 at .65 (renders #695028) | One physical pixel, 104/80/52 (3.8 CIEDE2000 from today's rendering), also inside the framed bar |
| Header divider | 1 unit, .67/.64/.56 at .55 | **Revised:** none inside the window frame (its separator takes the place). Flat draft: one physical pixel, muted at 0.35 |
| Row dividers | 0.6 unit, .55/.52/.45 at .3 | One physical pixel, muted at 0.18 |
| Panel title, Options title | gold 255/207/66 | `NORMAL_FONT_COLOR` (#FFD200). **Revised:** inside the window frame at size 12 in the title strip, as Blizzard's window titles |
| "Output device", "Soundstone size" | gold 255/207/66 | `NORMAL_FONT_COLOR` (#FFD200), case unchanged. Forever's own audio settings show their labels in this gold. It is 3.5 from today's gold |
| Values, row names, scale value, checkbox labels | 245/240/222 | 240/233/218 |
| Footer (version, ♥, author) | text color, group alpha .55 | Muted, group alpha .85. Contrast 5.5:1, today 5.4:1. Heart color unchanged |
| Channel icons and their muted state | Master / Sfx / Music sprites; desaturated at alpha .66 when muted | **Unchanged** (identity and information) |
| Hide, compact and close buttons; Options close | Red-and-gold sprites | **Revised:** inside the window frame Blizzard's red `UIPanelButtonTemplate` (32 × 22, gold symbols) as Baganator's, and Forever's own close button. Flat draft: **unchanged** sprites |
| On/off and reset buttons, checkboxes, device field and list, tooltips, minimap button, compartment entry | Blizzard templates and textures | **Unchanged.** Forever draws red buttons and dark checkboxes, as on Retail, and its own bronze device field and list (captured 8 November 2026) |
| Chat prefix #ffcc4d | — | **Unchanged** |
| Frame sizes, positions, placement, menu attachment, fonts and font sizes | — | **Unchanged.** What changes its footprint inside the frames: the thumb, the one-pixel lines and dividers, and the grip squares. **Revised:** inside the window frame the rows sit 37 units apart, the footer and the options' controls move to clear the bottom band, and the mixer's title is 12 |

**On Retail, Mists, Anniversary and Classic Era nothing changes:** same textures, same colors, same layout. In code, the theme `soundstone` paints exactly today's constants, and no Forever region is even created unless the Forever look is chosen.

## Palette

RGB 0–255. Distances are CIEDE2000 (sRGB, D65), computed from the values. Contrast is WCAG over the plate, taken as opaque.

| Key | Value | Used for | Origin |
| :--- | :--- | :--- | :--- |
| `plate` | 21/18/15 at 0.96 | ground of bar, panel and options | **Umbra**, from Forever's plaque #110D09 and tooltip #161017. The screenshots read #130E0A–#1D1C14 and #150F17, but both are translucent art, so they confirm the value only roughly |
| `band` | 10/8/6 | Used for:<ul><li>one pixel inside every outer line;</li><li>the ground of wells, track and the Expand button.</li></ul> | **Umbra** (`border`, its control ground). **Measured:** the dark pixel inside the top line of Forever's device list renders 10/8/6 over Soundstone's plate. The plaque and the tooltip have a dark pixel or gradient inside every side. Umbra draws nothing next to its rims |
| `lineTop` | 154/128/92 | top line of the three plates | **Umbra** `rimTop`. **Measured:** the device list's top line #92744C, 4.6 away |
| `lineSide` | 128/104/72 | left and right lines | **Umbra** `rimRight`. **Measured:** the device list's sides ramp from about #8F714A to #775D3B (4.65 and 4.10 away; their mean #836743 is 1.7 away). Umbra draws no left line |
| `lineBottom` | 104/80/52 | bottom line; outlines of wells, track and Expand; the bar's channel dividers | **Umbra** `rimBottom`.<br>**Measured:**<ul><li>the device list's bottom line #755B3A, 4.3 away;</li><li>the device field's outer line, #614F35 at the top, 2.8 away.</li></ul>Today's rendered divider #695028 is 3.8 away |
| `text` | 240/233/218 | values, names, labels of controls | **Umbra**. Forever writes headings and tooltips in #FFFFFF and setting labels in gold; today's 245/240/222 is 2.2 away |
| `muted` | 166/160/148 | footer, gear, grip squares, dividers in the panel | Value: **Umbra**.<br>Alphas:<ul><li>0.18 for row dividers: **Umbra** (its window rule).</li><li>0.35 for the header divider: **deviation**; Umbra uses 0.18.</li><li>0.85 for the footer: **deviation**; Umbra uses 0.7.</li></ul> |
| `accent` | 240/204/140 | hover on the gear; hover and pressed outline of Expand | **Umbra**, from the minimap lip. Measured: #E9C496 at the lip's brightest, 4.8 away |
| `title` | `NORMAL_FONT_COLOR`, fallback 1/0.8235/0 | panel title, Options title, the two section labels | **Measured**: #FFD200 on window titles, and on the labels and values of Forever's own audio settings. Read from the client at runtime, because the value is not in the UI source (`C_UIColor`). The fallback is 210/255, Blizzard's own `\|cffffd200`. Umbra's `{1, 0.82, 0}` renders #FFD100 |
| `fill` | 255/176/33 | volume fill | **Unchanged** |

**Umbra's warrior rule, translated.** Soundstone shows no class colors. Its information colors are the volume fill and the thumb that marks its end (on Forever the client's own copper diamond). The rule becomes: chrome stays at least 11 CIEDE2000 away from any information color it touches.
- **Full fill:**
  - accent 13.0
  - title 12.6 (12.2 for a hard-coded #FFD100)
  - `lineTop` 24.5, `lineSide` 32.4, `lineBottom` 42.3
  - muted and text 26.2
- **Thumb:**
  - against the fill: Forever's copper diamond 31.2 (its highlight #F1D6C1: 21.8);
  - against the track outline: 11.7.
  - On an unavailable slider (alpha .35) the dimmed diamond (about 62/45/32) is 4.4 from the dimmed outline. Only its dark rim separates them; that is accepted, because the whole slider then reads as off.
- **Unavailable slider:** fill and track are both at alpha .35. The fill (about 100/71/19) is 16.8 from its dimmed outline (about 50/40/28).

**Contrast:**
- Text 15.4:1, title 12.9:1, accent 12.2:1, muted 7.2:1, footer 5.5:1.
- The gear renders about 111/107/99 (gray 0.67 × muted). That is 3.5:1 against the plate; today's gear measures 4.9:1. It stays above the 3:1 for non-text controls.

## Where Soundstone differs from Umbra 0.9

| Umbra | Soundstone on Forever | Why |
| :--- | :--- | :--- |
| **Windows:** one line in `rimTop` on all four sides, one pixel *outside* the window. **Frames:** three tones inside, no left line | Lines *inside* the frame on all four sides: top `lineTop`, left and right `lineSide`, bottom `lineBottom` | Inside keeps the 276/300-unit rectangles that the 4-unit menu gap, clamping and the placement solver use (Umbra moved its frame rims inside for a similar reason). Soundstone has no class edge, so it needs a left line: the same as the right, as on Forever's device list |
| The right line owns both corners | Top and bottom lines run the full width and own the corners | The lighter top line runs unbroken, as on Forever's device list and tooltip |
| No band next to the rim; `border` only as a control ground | One pixel of `band` inside every outer line | Forever's device list has one under its top line (rendering 10/8/6); the plaque and tooltip have one inside every side |
| Title `{1, 0.82, 0}` | `NORMAL_FONT_COLOR` at runtime, fallback 210/255 | Gives the measured #FFD200 instead of #FFD100 |
| Gold only on a window's title; section headings muted and uppercase | Gold (`NORMAL_FONT_COLOR`) on titles and on the two section labels; case unchanged | Umbra's reason is unit frames, where that yellow is the level's difficulty color; Soundstone shows no levels. Forever's own audio settings label everything in that gold, and Soundstone's labels are gold today. Uppercase would widen text in a layout fitted to today's widths |
| Its own flat checkbox and buttons instead of Blizzard templates | Blizzard's on/off and reset buttons, checkboxes and device field stay | Soundstone uses the client's templates on every client today. Replacing them would change the other clients, or create Forever-only controls. Forever draws them in its own art |
| Control outlines muted at 0.35 (checkbox), none on buttons | Wells, track and Expand have a one-pixel `lineBottom` outline | Forever's own device field, filter field and footer field carry a bronze line: the device field's outer line is 2.8 away at the top, 1.75 on the left, 5.5 at the bottom. Without it, a 10/8/6 well disappears on a 21/18/15 plate |
| A 3-unit accent edge on the window's left | No accent edge | It stands in for a class edge, which Soundstone does not have; on a 36-unit bar it would take room from the grip |
| Close button: muted × on a `border` ground | The red-and-gold sprites stay | Forever's own close button is red with a gold X; and the three header buttons share one frame by design (0.3) |
| Theme switch in the options window | Slash command only (for now) | A new row would change the options window on every client |
| Header rule 0.18, footer 0.7 | Header 0.35, footer 0.85 | Keeps today's hierarchy (header above rows) and today's footer contrast |
| Scale fixed after build; lines measured again on two events | Measured again in every `ApplyLayout` | Soundstone has its own 75–150% scale |

Adopted unchanged from Umbra:
- the plate, the band and line values, `text`, `muted` and `accent`;
- the paint registry and the in-place palette rewrite;
- `pcall` around each repaint;
- the one-pixel formula;
- the child frame for the lines;
- the `auto` default and the command shape;
- the chat accent left alone.

## Detection and the switch

*Removed on 10 November 2026: there is no switch any more; see the status at the top.*

**Detection.** `C.IsForever()` keeps its interface check and also accepts `WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT`, as Umbra does. The comment is corrected. `C.IsRetail()` stays as it is, with a comment that it is false on Forever.

**Recommended: `auto` by default, with a switch.**
- The command is `/soundstone theme auto|soundstone|forever`, stored as `SoundstoneDB.theme`:
  - `auto` means the Forever look on Forever and today's sprites everywhere else.
  - `soundstone` means today's sprites: Retail art on Retail, Classic art elsewhere.
  - `forever` means the Forever look.
- Without a value it prints the stored choice and, for `auto`, what it resolves to.
- At load, a saved value other than the three becomes `auto`. An unknown word in the command is refused, as in Umbra.
- **Why a switch at all:**
  - A player who prefers the sprites keeps them on Forever.
  - If a Forever patch moves its art, the old look is one command away instead of one update.
  - The Forever look can be checked on another client.
- **Why not a fixed choice:** it would be simpler and would leave the help text alone, but it gives Forever players no way back.
- **No new control in the options window** in this round. Only the help line (`L.HELP`, en/de) gains `theme`.

## Switching without /reload

*Players can no longer switch; the tests still apply both looks this way.*

1. **A new `Soundstone/Theme.lua`** (TOC: after `Layout.lua`, before `UI.lua`) holds:
   - the two palettes: `soundstone` with today's constants, `forever` with the values above;
   - `Theme.Resolve(choice)` and `Theme.Use(name)`;
   - a weak-keyed paint registry, as in Umbra: each region remembers its palette *key*;
   - `Theme.Pixel(region)` and `Theme.HasAtlas(name)`.

   The switch itself is `UI:ApplyTheme()`. Unlike Umbra, the palette tables are swapped rather than rewritten in place; every reader goes through `Theme.Color(key)` or the registry when it paints, so nothing holds a stale table.
2. **Painting.** Every text and flat texture that today gets a constant color is painted through the registry instead. Under `soundstone` the registry paints exactly today's numbers. Hover and pressed scripts read the palette when the pointer arrives.
3. **Lazy creation.** The Forever pieces are created the first time the Forever look is applied. On the other clients, with `auto`, they never exist. Per plate that means the plate fill, plus an edge frame holding four lines and four band textures. On top come the flat wells and the grip squares.
4. **What `UI:ApplyTheme()` does, in this order:**
   - It shows one set of pieces and hides the other: `skinPieces`, rivets, Action plates, ClassicPanel wells.
   - It sets every slider thumb in both directions:
     - Forever: the atlas through `GetThumbTexture():SetAtlas('Minimal_SliderBar_Button', true, nil, true)`, at the atlas's own size. The last argument resets the texture coordinates, which `SetAtlas` would otherwise carry over from the sprite.
     - `soundstone`: today's sprite, with its texcoords, 10 × 18, draw layer, blend mode and vertex color.
     - Blizzard sets this atlas only in XML (`MinimalSlider.xml`), never from Lua on a slider's thumb. That it works from Lua has to be confirmed in game, and the sprite stays the fallback.
   - It repaints the registry, each region inside `pcall` (Umbra: a region inside an instance can refuse a recolor).
   - It sizes every line itself. It does not rely on `UI:ApplyLayout()` here: that returns at once during a drag (`UI.lua:444`), and `FinishDrag` lays out only afterwards.
   - Nothing moves: no frame size, anchor or `db.position` changes, and a running placement check keeps its inputs.
5. **When it runs:** first at the end of `UI:Create`, before its final `Refresh` (`UI.lua:596`); then on every `/soundstone theme`. Nothing in Soundstone is secure, so a switch should also work in combat. That has to be tried, as for Umbra.

## Pixel-exact lines

- **One physical pixel** is `PixelUtil.GetPixelToUIUnitFactor() / region:GetEffectiveScale()`, i.e. 768 divided by the physical height, divided by the effective scale, as in Umbra.
  - `GetPixelToUIUnitFactor` and the other shared `PixelUtil` functions have the same bodies on all five branches.
  - `GetEffectiveScale` is documented with a secret return on Retail and Forever. As a precaution it is checked with `issecretvalue and issecretvalue(scale)`, as in `Placement.lua:82`, and the line falls back to one unit. The rest of `ApplyLayout` and `C.Pixel` already assume a scale that is not secret.
- **When it is measured again:** in `UI:ApplyLayout`, which already runs after all of these:
  - `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (through `QueueLayout`);
  - the `uiScale` CVar;
  - `UIParent`'s size and `SetScale`;
  - `/soundstone scale` and the size slider;
  - showing the root.

  This covers what Umbra's two events do not: Soundstone's own 75–150% scale. The lines are placed at the end of `UI:PositionMenus`, which ends every layout, after the options plate has its final position. During a drag, `UI:ApplyTheme` sizes the lines itself (see above).
- **Inside the frame:** the line takes the outermost pixel and the band the next one, both within the frame's bounds. The bar stays 276 units, the panel 300 and the menu 276. Top and bottom lines span the full width; left and right lie between.
- **On a child frame above the content**, as Umbra's rim frame does: one edge frame per plate, a few levels above the plate, taking no mouse.
  - On the options plate, the device field's template background region reaches 2 units from the plate's edge (Classic template: 1), because it is anchored 8 units outside the field.
  - On Forever the captured field's art ends at the field itself, so it is transparent there. On the other clients, with `theme forever`, it has not been seen. The edge frame keeps the line and band on top either way.
- **Fractional edges:**
  - `ApplyLayout` puts the root's top left at a whole-pixel offset from `UIParent`'s center (`UI.lua:461`), so bar and panel start on a pixel when the physical size is even.
  - The options plate hangs from the root's bottom or top edge (`UI.lua:379-381`), and 276 × 1.3125 = 362.25. So right, bottom and the menu's edges fall between pixels.
  - At 1440 pixels and UI scale 1.0 (1.875 px per unit) a 276-unit plate is 517.5 px wide, and an edge on exactly half a pixel could round either way: a line there could come out doubled or missing.
  - **So the lines are placed on whole pixels:** the plate's (or well's) rectangle is rounded to whole physical pixels from its actual position on screen (`GetLeft`/`GetTop` over one pixel). Fill, lines and band are anchored to its top left with whole-pixel offsets and sizes. The drawn rectangle may therefore differ from the frame's by up to half a pixel on each side. During a drag the root moves freely, and the lines are snapped again when it is dropped.
  - **Snapping:** the client snaps textures to the pixel grid by default (`snapToPixelGrid` default `true` in `UI.xsd`). With whole-pixel rectangles a one-pixel texture should cover exactly one pixel; *expected, to be confirmed in game* with `IsSnappingToPixelGrid()` and `GetTexelSnappingBias()`.
  - **Fallback:** if a line doubles or drops out, `SetSnapToPixelGrid(false)` and `SetTexelSnappingBias(0)`, as Blizzard's `NineSliceUtil.DisableSharpening` does. Both exist on all five branches.
- **Inner dividers** take one physical pixel the same way, and their thin edge is moved onto a whole screen pixel (at 1.5 px per unit their anchors fall on half pixels). The grip squares are moved onto whole screen pixels too.

## Files and assets

| File | Change |
| :--- | :--- |
| `Soundstone/Theme.lua` | new: palettes, name, paint registry, pixel size, apply |
| `Soundstone/Soundstone.toc` | add `Theme.lua`; interface list unchanged |
| `Soundstone/UI.lua` | Painting and lines:<ul><li>paint through the registry;</li><li>lazy Forever pieces and edge frames;</li><li>one-pixel sizes in `ApplyLayout`.</li></ul>Per theme:<ul><li>thumbs (atlas or sprite), wells and grips;</li><li>dividers;</li><li>gear and Expand states.</li></ul>Lifecycle: the first `Theme.Apply()` before the final `Refresh` of `UI:Create` |
| `Soundstone/Compat.lua` | `IsForever` also accepts `WOW_PROJECT_CAMELOT`; comments |
| `Soundstone/Core.lua` | `db.theme` default; `theme` command |
| `Soundstone/Locale.lua` | help line and theme replies, en/de |
| `tests/run.py` | `Theme.lua` in `FILES`. Seven configurations: the Forever release (project 18, `WOW_PROJECT_CAMELOT` set, compartment kept) next to the beta configuration |
| `tests/wow_mock.lua`, new `tests/test_theme.lua` | Mock `PixelUtil.GetPixelToUIUnitFactor` only, so that `C.Pixel` keeps today's fallback and the 0.3.8 baseline. Let `SetThumbTexture` reuse its texture. Mock `C_Texture.GetAtlasInfo` (atlas known or unknown, switchable) and `Texture:SetAtlas`, recording the atlas name. `NORMAL_FONT_COLOR`, `issecretvalue` guarded. Assertions below |
| `tools/install-local.py` and its tests | `forever` → `_forever_` (the finding above) |
| `tools/mockup.py` | Forever board (already done for this proposal) |
| Docs | `CHANGELOG.md`, `README.md`, `docs/COMPATIBILITY.md`, `docs/TESTING.md`, `docs/DEVELOPMENT.md`, `docs/ARTWORK.md`, `docs/ANLEITUNG-DE.md`, `docs/curseforge/description.md`, `docs/curseforge/INGAME-TEST.md`: the theme, the switch, the release client, the tests |

**No new sprites.** Everything new is drawn in code with `Interface\Buttons\WHITE8X8`, which Soundstone already uses. The one exception is the slider thumb, which is the client's own atlas `Minimal_SliderBar_Button`. Reasons for code drawing:
- A sprite cannot hold a line of exactly one physical pixel at every scale.
- Exact palette colors are one call away.
- There is no new art to export or document.
- `Media/`, `docs/assets/` and the package checks stay as they are.

The one place a sprite would help is the Expand glyph, whose old gold is baked into it. See [open questions](#open-questions).

## Risks

- **Forever's client art.** The enabled buttons, checkboxes, device field and device list were captured on 8 November 2026, and the mockup draws them after that capture.
  - The buttons are Retail's red. On the flat plate they read as Forever's own red close button does.
  - A button under the pointer lights up and its label turns white, as on Retail.
- **The slider thumb is client art set from Lua.**
  - `Minimal_SliderBar_Button` is referenced by `MinimalSlider.xml` on all five branches. `Texture:SetAtlas` and `C_Texture.GetAtlasInfo` are documented on all five.
  - Blizzard sets this atlas on a slider's thumb only through XML. It sets other atlases from Lua routinely (for example on the scroll bar's thumb), so the risk is small.
  - With `theme forever` on another client, the thumb shows that client's own settings-slider thumb.
  - If `C_Texture.GetAtlasInfo` does not know the atlas, the sprite thumb stays.
  - At about 20 units wide instead of 10, the thumb travels about 10 units less on a 98-unit slider. Steps of 1% and the wheel are unaffected.
- **The device list is Blizzard's.** About 11% of what is behind it shows through, and it sticks out 12 px past the options plate's right edge. That is true today and stays so with the proposal; this plan does not change it.
- **The palette is a snapshot.** It was measured on build 1.60.1.70862 in November 2026, and a Forever patch can move its art.
- **Regressions on the other clients.** Routing every color through the registry touches code that runs everywhere. Mitigation:
  - Tests assert today's exact numbers under `soundstone`.
  - The Forever pieces are not created there.
  - Lossless before/after crops on each client must be pixel-identical, except for the version in the footer.
- **Lines at fractional positions.** A line can land one pixel further on after a move. That is acceptable. A doubled or missing line is not, and the tests look for it.
- **A secret effective scale** would make the lines fall back to one unit, which can render two pixels wide.
- **Combinations of scales** have to be measured, not assumed:
  - Soundstone's 75–150%;
  - the client UI scale;
  - pixel-perfect addons that scale `UIParent` below the CVar's minimum.
- **Translucency.** At 0.96, about 4% of the world shows through the plate. Today's sprites are opaque.
- **The gear gets dimmer:** 3.5:1 instead of 4.9:1.
- **Hourstone.** The README says Soundstone shares its look with Hourstone. On Forever the two would differ until Hourstone gets the same treatment.
- **The help text changes on every client** (one word).

## Test plan

*Written for the switch; the `theme` commands below no longer exist. The current in-game checks are in the [checklist](curseforge/INGAME-TEST.md).*

**Automated**, in `tests/run.py`, for all seven configurations, each with native and fallback menus:
- `auto` resolves to `forever` only in the two Forever configurations: release (project 18) and beta (project 1, interface 16001).
- **Under `soundstone`,** every texture path, texcoord, vertex color, text color, size, shown state and thumb texture equals 0.3.8's. This is a snapshot of the mock's recorded calls.
- **No Forever region** is created under `auto` in the other five configurations.
- **One-pixel sizes** equal `768 / physical height / effective scale` for:
  - physical heights 1080, 1440 and 2160;
  - client scales 0.53, 0.64, 0.7, 1 and 1.15;
  - Soundstone scales 0.75, 1 and 1.5.

  They are measured again after `SetScale`, `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`.
- **Round trip:** `forever` → `soundstone` → `forever` restores every region exactly. Nothing moves and `db.position` stays the same, including during a drag and during a placement check.
- **Command:** `/soundstone theme` with no, a valid and an invalid value. The saved value survives a reload; an invalid saved value becomes `auto`.
- **Thumb:** under `forever` the thumb gets the atlas when the mocked `C_Texture.GetAtlasInfo` knows it, and the sprite when it does not. Under `soundstone` it is always the sprite, with 0.3.8's texcoords and size.

**In game, on every client.** Turn on lossless screenshots first (`/console screenshotFormat png`), take each shot with the UI at the same place, and compare crops with PIL:

| Client | Measured |
| :--- | :--- |
| **Retail 12.1.5** | `/soundstone theme` says `auto` → `soundstone`.<br>Bar, panel and options are pixel-identical to a 0.3.8 crop, except for the version number.<br>With `theme forever`, without `/reload`:<ul><li>the top line is exactly one row of 154/128/92;</li><li>left and right are one column of 128/104/72;</li><li>the bottom is one row of 104/80/52;</li><li>the band 10/8/6 lies directly inside.</li></ul>The slider thumb is Retail's own `Minimal_SliderBar_Button` (or the sprite if the atlas is unknown) and lands on 0% and 100%.<br>`theme auto` gives the identical crop back.<br>Repeat with PixelPerfectUIScale at 0.53. |
| **WoW: Forever 1.60.1** | **First login** after the update: the Forever look without `/reload`; `theme` says `auto` → `forever`.<br>**Lines:** starting from 1.3125 px/unit (client scale 0.7, Soundstone 100%), each line is exactly one pixel, never two and never missing, on bar, panel and options. Also at Soundstone 75% and 150%, at client scale 1.15, and after changing the scale while open.<br>**Colors:**<ul><li>the plate over a dark, even backdrop ≈ 21/18/15 at 0.96;</li><li>titles #FFD200 (`/dump NORMAL_FONT_COLOR:GetRGB()`);</li><li>values 240/233/218, labels 166/160/148;</li><li>fill still 255/176/33, a muted icon still desaturated;</li><li>top line 154/128/92, left and right 128/104/72, bottom 104/80/52, band 10/8/6 directly inside;</li><li>well, track and Expand outlines and the bar's channel dividers 104/80/52;</li><li>the slider thumb is the same copper diamond as in Forever's own audio settings, and the thumb still lands on 0% and 100% at the ends.</li></ul>**Round trip:** `theme soundstone` gives a crop identical to 0.3.8's Classic look; `theme auto` returns.<br>**Snapping:** `IsSnappingToPixelGrid()` on one line.<br>**Interaction:** hover and pressed on the gear and Expand; options open below and above the bar; the device list open; a tooltip; a switch in combat. |
| **Mists Classic 5.5.4** | `auto` → `soundstone`. Bar, panel and options pixel-identical to 0.3.8.<br>`theme forever`: lines one pixel and colors as on Forever, at this client's scale. The thumb is this client's own `Minimal_SliderBar_Button` (or the sprite if the atlas is unknown) and lands on 0% and 100%. `theme auto` returns to the identical crop.<br>`/dump Soundstone.UI.outputDropdown.native` records which dropdown path draws the device field. |
| **TBC Anniversary 2.5.6** | Same as Mists. |
| **Classic Era 1.15.9** | Same as Mists. |

## Open questions

1. **Switch.** Is `auto|soundstone|forever` as a slash command right, or should Forever simply always get its look? Should the switch also go into the options window?
2. **Line colors.**
   - Recommended: Umbra's three bronzes. They are within 5 CIEDE2000 of Forever's device list, and Soundstone and Umbra then wear the same line on the same screen.
   - Alternative: the device list's own values #92744C, #836743 (sides, mid-height) and #755B3A.
3. **Corners.** Even the device list's one-pixel line has chamfered corners. Should Soundstone keep square corners, as Umbra does (recommended, simplest), or cut one pixel at each corner as a nod to Forever's chamfers?
4. **Expand glyph.** Keep the baked old-gold sprite (no new asset), or add a white mask so it follows the palette (muted, accent on hover) like the gear?
5. **Slider thumb.** Is the client's own thumb right (recommended: Forever's copper diamond, exactly as in its audio settings)? The alternatives are today's sprite or a flat bar.
6. **Header buttons.** Keep the red-and-gold hide, compact and close sprites on Forever, as proposed?
7. **Checkboxes.** Forever's own settings draw a bronze-edged box. Soundstone's `UICheckButtonTemplate` shows Retail's gray one there.
   - Recommended: keep the template, as for every Blizzard control.
   - Alternative: give Soundstone's checkboxes the settings look on Forever.
8. **Gold text.** Forever's own audio settings write their labels *and* values in gold.
   - The proposal keeps gold for titles and the two section labels (as today), and warm white for names and values.
   - Should the row names and values turn gold as well?
9. **Release version.** 0.4.0, for a new look and a new command?

## Captures

All on Forever, as lossless PNG (`/console screenshotFormat png`), with the UI not hidden, ideally in front of a dark, even part of the world.

**All received on 8 November 2026:**
- the compact bar and the expanded panel;
- the panel with the options, and the same with the device list open;
- the pointer on **Reset size**, for the button's highlight;
- Forever's own audio settings, with its sliders and checkboxes.

Their measurements are in [Blizzard's own controls on Forever](#blizzards-own-controls-on-forever).

Nothing further is needed for this plan. A later Forever patch would call for the same shots again.

## Inventory: what each element wears on Forever today

Source references are to 0.3.8.
- **Origin:** *code* is a constant in Soundstone, *sprite* a Soundstone TGA, *Blizzard* a client template or texture.
- **Info:** whether the element carries information.

**Compact bar**

| Element | Built | On Forever today | Origin | Info |
| :--- | :--- | :--- | :--- | :--- |
| Plate 276 × 36 | UI.lua:275-276 | ClassicBar nine-slice, corner 10 (Retail: RetailBar, 7) | sprite | no |
| Drag grip | UI.lua:279-281, 257-273 | 6 × Rivet, 3.1 units, step 5.3 (all clients) | sprite | no |
| Gear 19 × 19 | UI.lua:104, 128-134 | GEAR_64GREY; tint .9/.8/.57, hover 1, pressed .6/.55/.4 | Blizzard + code | no |
| Expand button 19 × 19 | UI.lua:283, 106-117 | ActionNormal / Hover / Pressed plate; Expand glyph .9 / 1 / .7, pressed 1 unit down | sprite | no |
| Channel icons | UI.lua:288 | Master / Sfx / Music in 22 units | sprite | yes |
| Muted icon | UI.lua:74, 555 | desaturated, alpha .66 | code | yes |
| Values | UI.lua:289, 480 | .96/.94/.87, 11 → 9 to fit 38 units | code | yes |
| Channel dividers | UI.lua:290 | 0.6 × 26, .58/.43/.19 at .65 | code | no |

**Expanded panel**

| Element | Built | On Forever today | Origin | Info |
| :--- | :--- | :--- | :--- | :--- |
| Plate 300 × 160 | UI.lua:310-311 | ClassicPanel nine-slice, corner 10 (Retail: RetailPanel, 7) | sprite | no |
| Grip, gear | UI.lua:318-321 | as in the bar | sprite / Blizzard | no |
| Title | UI.lua:314, 476-477 | gold 1/.81/.26, 14 → 10 to fit 152, else "Soundstone" | code | no |
| Hide, compact, close | UI.lua:322-327 | HeaderHide / HeaderCompact / HeaderClose 20 × 20; hover 1/.94/.75, pressed .65 | sprite | no |
| Header divider | UI.lua:328 | 286 × 1, .67/.64/.56 at .55 | code | no |
| Icon well | UI.lua:332-333 | 25 × 25, ClassicPanel nine-slice, corner 3 (Retail: none) | sprite | no |
| Icon, muted icon | UI.lua:334, 466-468, 555 | min(18, 25 − 2 × (3 + 1) units snapped): 17 at 1 px/unit, 17.4 at 1.3125; desaturated at .66 | sprite + code | yes |
| Icon button disabled | UI.lua:557 | `SetEnabled(false)` when the channel is unavailable | code | yes |
| Row name | UI.lua:335 | .96/.94/.87, 10 → 8 | code | no |
| On/off | UI.lua:336, 556-557 | `UIPanelButtonTemplate` 34 × 20, text 10; "--" and disabled when unavailable. Captured: Retail's red art, label #FFD200 | Blizzard | yes |
| Slider track | UI.lua:299 | Toggle nine-slice, corner 2, 8 high | sprite | no |
| Slider fill | UI.lua:300-302 | 255/176/33, 3 high | code | yes |
| Slider thumb | UI.lua:303-305 | SilverThumb 10 × 18, OVERLAY 7 (Retail: GoldThumb) | sprite | yes |
| Unavailable | UI.lua:558-559 | slider, fill and track at alpha .35 | code | yes |
| Row value | UI.lua:339 | .96/.94/.87, 10 → 8 | code | yes |
| Row dividers | UI.lua:340 | 272 × 0.6, .55/.52/.45 at .3 | code | no |
| Footer | UI.lua:343-346 | version and author .96/.94/.87 at 7.5; heart .95/.3/.38; group alpha .55 | code + sprite | no |

**Options menu**

| Element | Built | On Forever today | Origin | Info |
| :--- | :--- | :--- | :--- | :--- |
| Plate 276 × 236 | UI.lua:407-408 | ClassicPanel nine-slice, corner 10 (Retail: RetailPanel) | sprite | no |
| Title "Options" | UI.lua:410 | gold, 12 | code | no |
| Close 18 × 18 | UI.lua:411 | Close sprite; hover 1/.94/.75, pressed .65 | sprite | no |
| "Output device", "Soundstone size" | UI.lua:412, 416 | gold, 10 | code | no |
| Device field and list | Dropdown.lua:117-146, 183-203 | `WowStyle1DropdownTemplate` and the Menu system (native path on Forever). Field text in a font object without color (renders #FFFFFF); alpha .45 when no device is available (Dropdown.lua:19). Captured: field ground #110E09 in a double bronze line; list with a one-pixel line #92744C / #836743 / #755B3A and a dark pixel under the top line | Blizzard | yes |
| Size slider | UI.lua:417 | as the row sliders, 208 wide | sprite + code | yes |
| Scale value | UI.lua:421 | .96/.94/.87, 10 | code | yes |
| Checkboxes | UI.lua:426-434 | `UICheckButtonTemplate` 24 × 24, label .96/.94/.87. Captured: box #0D0D0D with a gray rim, check #FFFB21 | Blizzard + code | yes |
| Reset size, reset position | UI.lua:435-436 | `UIPanelButtonTemplate` 256 × 20. Captured: Retail's red art, label #FFD200 | Blizzard | no |

**Elsewhere**

| Element | Built | On Forever today | Origin | Info |
| :--- | :--- | :--- | :--- | :--- |
| Fallback device list (not reached on Forever) | Dropdown.lua:147-182 | **Backdrop:** `UI-Tooltip-Background` / `-Border`, .07/.06/.04 at .98, border .85/.78/.6.<br>**Parts:** `UI-ScrollBar-Knob`; rows 1/.82/.45 with `UI-QuestTitleHighlight`; current device marked with `UI-CheckBox-Check` | Blizzard + code | yes |
| Minimap button | UI.lua:498-510 | `UI-Minimap-Background`, Logo, `MiniMap-TrackingBorder`, Classic geometry; off by default on Forever | Blizzard + sprite | no |
| Compartment entry | UI.lua:535-546 | Logo.tga; the row is drawn by the client | Blizzard + sprite | no |
| Tooltips | UI.lua:78-82 | GameTooltip; title 1/.82/.3, body .94/.93/.88 | Blizzard + code | yes |
| Chat | Core.lua:4-6 | prefix #ffcc4d | code | no |
