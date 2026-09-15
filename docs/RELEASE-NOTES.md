# Soundstone 0.3.0 – Azeroth Audio

Compact audio controls for World of Warcraft, with English and German UI.

## Install / Installation

1. Download **`Soundstone-0.3.0.zip`** from **Assets** below. Use this file, not **Source code (zip/tar.gz)**.
2. Close WoW and extract the archive. Copy the contained **`Soundstone`** folder into your client's **`Interface/AddOns`** directory:

   | Client | Folder inside your World of Warcraft installation |
   | --- | --- |
   | Retail | `_retail_/Interface/AddOns/` |
   | MoP Classic | `_classic_/Interface/AddOns/` |
   | TBC Anniversary | `_anniversary_/Interface/AddOns/` |
   | Classic Era / Hardcore / Season of Discovery | `_classic_era_/Interface/AddOns/` |

3. Verify **`Interface/AddOns/Soundstone/Soundstone.toc`** exists. Avoid an extra parent or nested `Soundstone` folder.
4. Start WoW, enable **Soundstone – Azeroth Audio** in **AddOns**, and type **`/soundstone`** in game.

**Deutsch:** WoW schließen, **Soundstone-0.3.0.zip** unter **Assets** herunterladen und entpacken. Den Ordner **Soundstone** in den oben genannten `Interface/AddOns`-Ordner deines Clients kopieren. WoW starten, das Addon aktivieren und **`/soundstone`** eingeben. Beim Aktualisieren den bisherigen Addon-Ordner ersetzen; den `WTF`-Ordner mit den gespeicherten Einstellungen behalten. Nach einem Austausch während des Spielens `/reload` verwenden; falls das neue Addon fehlt, WoW neu starten.

[Full installation guide / vollständige Anleitung](https://github.com/krebs3r/soundstone-azeroth-audio/blob/v0.3.0/docs/ANLEITUNG-DE.md)

## What's new

- Smaller compact bar and options, direct view/hide controls and matching red header buttons.
- Attached output-device dropdown; fixed native menu Lua font errors.
- Consistent master/music/effects activation and restoration of the last positive volume at 0%.
- Sound effects groups effects, ambience and dialogue; voice chat stays separate.
- Optional avoidance of visible UI controls when placing Soundstone, and shorter contextual tooltips.
- **300 × 160 changelog**, matching the mixer, with **one card per version**. Open it by clicking the version footer.
- Updated README with current UI-preview captures and installation instructions.

![Soundstone 0.3.0 UI preview: Retail and Classic](https://raw.githubusercontent.com/krebs3r/soundstone-azeroth-audio/v0.3.0/docs/screenshots/soundstone-0.3-overview.png)

*Captured from the production-asset browser preview, not from the game. Blizzard widgets and fonts are approximated.*

## Validation and clients

**711 simulated Lua scenarios** plus package/texture checks. Targets: Retail 12.1.0, MoP Classic 5.5.4, TBC Anniversary 2.5.6 and Classic Era 1.15.9. In-game acceptance is not complete for every client/game mode; **WoW: Forever remains unconfirmed**.

[Full changelog](https://github.com/krebs3r/soundstone-azeroth-audio/blob/v0.3.0/CHANGELOG.md) · [Compatibility](https://github.com/krebs3r/soundstone-azeroth-audio/blob/v0.3.0/docs/COMPATIBILITY.md)
