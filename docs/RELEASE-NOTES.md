# Soundstone 0.3.8 – Azeroth Audio

Includes the fixes from the 0.3.7 prerelease.

## What's changed

- **Position with pixel-perfect scaling addons:** With addons that set the interface scale themselves (e.g. PixelPerfectUIScale), the bar still appeared away from its saved position after every login, relog or `/reload` and jumped back on the next click on Options, Expand or a right-click on a channel. Soundstone now lays the bar out once the interface has its final scale.
- **Overlap check after loading:** A scale change by such an addon in the first seconds after loading no longer cancels the overlap check of a bar you have just moved.
- **Full values at small scales:** With pixel-perfect scaling the bar cut "100 %" to "100...". Values, channel names, the title and the footer now fit their space at every interface scale.

Settings, positions and volume levels from earlier versions are kept.

## Installation and validation

Download **Soundstone-0.3.8.zip** from this release's assets and replace the **Soundstone** folder in your client's **Interface/AddOns** directory (WoW: Forever beta: **_classic_beta_/Interface/AddOns**). Keep your **WTF** folder to preserve settings.

1187 simulated Lua scenarios plus installer/release and package checks. In-game confirmation of the 0.3.8 test build is pending.

## Deutsch

Enthält die Korrekturen aus dem Prerelease 0.3.7.

- **Position mit Pixel-Perfect-Addons:** Mit Addons, die die Skalierung der Oberfläche selbst setzen (z. B. PixelPerfectUIScale), erschien die Leiste nach jedem Einloggen, Charakterwechsel oder `/reload` weiterhin neben ihrer gespeicherten Position und sprang beim nächsten Klick auf Optionen, Große Ansicht oder einem Rechtsklick auf einen Kanal zurück. Soundstone legt die Leiste jetzt erst an, wenn die Oberfläche ihre endgültige Skalierung hat.
- **Überlappungsprüfung nach dem Laden:** Eine Skalierungsänderung durch ein solches Addon in den ersten Sekunden nach dem Laden bricht die Überlappungsprüfung einer gerade verschobenen Leiste nicht mehr ab.
- **Vollständige Werte bei kleiner Skalierung:** Mit Pixel-Perfect-Skalierung kürzte die Leiste „100 %“ zu „100...“. Werte, Kanalnamen, Titel und Fußzeile passen jetzt bei jeder Skalierung in ihren Platz.

Einstellungen, Positionen und Lautstärken bleiben erhalten.

**Installation:** Den enthaltenen Ordner **Soundstone** im jeweiligen **Interface/AddOns**-Verzeichnis ersetzen (Forever-Beta: **_classic_beta_**) und **WTF** behalten. Die Bestätigung des Test-Builds 0.3.8 im Spiel steht noch aus.
