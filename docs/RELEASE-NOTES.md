# Soundstone 0.3.6 – Azeroth Audio

## What's changed

- **Retail 12.1.5:** Soundstone was listed as out of date and did not load unless "Load out of date AddOns" was enabled. It now declares the 12.1.5 interface (120105).
- **Position after login and reload:** The bar could appear away from its saved position after login, relog or `/reload` and jump back on the next click. Soundstone now applies its saved position again once loading has finished and whenever the interface is resized, and keeps the bar out of WoW's own frame-position cache.
- **No more jumping while dragging:** A drag starts where the bar is shown, and audio changes or other events no longer move it while the mouse button is held. Grabbing it again right after a move keeps it under the cursor.
- **Audio changes leave the window alone:** Clicks, the mouse wheel, key bindings or other addons changing sound settings only update the values.

Settings, positions and volume levels from earlier versions are kept.

## Installation and validation

Download **Soundstone-0.3.6.zip** from this release's assets and replace the **Soundstone** folder in your client's **Interface/AddOns** directory (WoW: Forever beta: **_classic_beta_/Interface/AddOns**). Keep your **WTF** folder to preserve settings.

1115 simulated Lua scenarios plus installer/release and package checks. The 0.3.6 test build was confirmed in game by the user on 2026-10-21 in Retail 12.1.5. MoP Classic, TBC Anniversary, Classic Era and the WoW: Forever beta are released on the user's compatibility approval without a separate 0.3.6 in-game test.

## Deutsch

- **Retail 12.1.5:** Soundstone wurde als veraltet angezeigt und ohne „Veraltete AddOns laden“ nicht geladen. Es meldet jetzt die Interface-Version von 12.1.5 (120105).
- **Position nach Einloggen und Reload:** Die Leiste konnte nach dem Einloggen, Charakterwechsel oder `/reload` neben ihrer gespeicherten Position erscheinen und beim nächsten Klick zurückspringen. Soundstone setzt die gespeicherte Position jetzt nach dem Laden und bei jeder Größenänderung der Oberfläche erneut und hält die Leiste aus WoWs eigenem Positionsspeicher heraus.
- **Kein Springen mehr beim Verschieben:** Das Ziehen beginnt an der angezeigten Stelle, und Lautstärkeänderungen oder andere Ereignisse bewegen die Leiste nicht mehr, solange die Maustaste gedrückt ist. Auch direktes erneutes Greifen nach dem Ablegen hält sie unter dem Mauszeiger.
- **Lautstärkeänderungen lassen das Fenster in Ruhe:** Klicks, Mausrad, Tastenbelegungen oder andere Addons aktualisieren nur noch die Werte.

Einstellungen, Positionen und Lautstärken bleiben erhalten.

**Installation:** Den enthaltenen Ordner **Soundstone** im jeweiligen **Interface/AddOns**-Verzeichnis ersetzen (Forever-Beta: **_classic_beta_**) und **WTF** behalten. Der Test-Build 0.3.6 wurde am 21.10.2026 vom Nutzer in Retail 12.1.5 im Spiel bestätigt. MoP Classic, TBC Anniversary, Classic Era und die WoW-Forever-Beta sind auf Wunsch des Nutzers ohne separaten 0.3.6-Ingame-Test freigegeben.
