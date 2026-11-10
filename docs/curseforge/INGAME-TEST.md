# Ingame-Abnahme und Screenshots

TBC Anniversary ist für v0.3.0 bestätigt; siehe [Abnahmeprotokoll](acceptance/v0.3.0-anniversary.md). Die folgende Checkliste dient weiteren Tests. Installation und 711 simulierte Szenarien allein sind keine Ingame-Abnahme.

## Pro Client ausfüllen

- Tester und Datum:
- Client-Familie und Spielmodus (z. B. Anniversary / normal):
- WoW-Version und Build (`/dump GetBuildInfo()`):
- Soundstone-Version: 0.3.0
- ZIP-SHA256: ad31660d4a96594dec59431d2586046e23afa27b0372263a4935dfc1d8b19482
- Sprache, Auflösung, WoW- und Addon-Skalierung:

| Prüfung | Ergebnis / Beobachtung |
| --- | --- |
| Einloggen, `/soundstone`, keine Lua-Fehler | offen |
| Gesamtlautstärke, Musik, Soundeffekte einzeln regeln und stummschalten | offen |
| Einschalten bei 0 %; Musik allein bei ausgeschaltetem Gesamtkanal | offen |
| Effekte/Umgebung/Dialoge gemeinsam; Sprachchat separat | offen |
| Wechsel Lautsprecher/Headset tatsächlich hörbar; ausgewähltes Gerät stimmt | offen |
| Änderung in Blizzard-Audiooptionen erscheint im Addon | offen |
| Leiste/Mixer/Optionen, Escape, Verschieben und Bildschirmränder | offen |
| Größe 75/100/150 %, lesbare Texte, kein Überlappen der Bedienfelder | offen |
| Bedienung im Kampf ohne Lua-/Schutzfehler | offen |
| `/reload` und erneutes Einloggen erhalten Einstellungen | offen |

Falls nur ein Ausgabegerät vorhanden ist, dies dokumentieren und den Wechseltest als offen markieren. Fehlertext und Reproduktionsschritte festhalten. Nach Korrekturen den betroffenen Test und den Grundtest wiederholen.

## Galerie

Drei echte Ingame-Screenshots ohne persönliche Chat-Inhalte aufnehmen: Kompaktleiste, Mixer, Optionen/Geräteliste. WoW kann Screenshots selbst speichern; anschließend die gewünschten Aufnahmen aus dem Screenshots-Ordner übernehmen. Keine simulierten Bilder als Spielaufnahmen ausgeben.

Dateinamen: `<client>-0.3.0-compact.png`, `<client>-0.3.0-mixer.png`, `<client>-0.3.0-options.png`. Bildunterschrift: Ansicht, tatsächlicher Client-Build, Soundstone 0.3.0, Sprache. Aufnahmen unter `docs/curseforge/screenshots/` ablegen.

Nach erfolgreicher Prüfung das ausgefüllte Protokoll als `acceptance/v0.3.0-<client>.md` ablegen und den entsprechenden Eintrag in `releases/v0.3.0.json` ergänzen. Keine offenen Ergebnisse als bestanden eintragen. Siehe README für das Datenformat.

## Aussehen ab 0.4.0

Vorher verlustfreie Screenshots einschalten: `/console screenshotFormat png`. Jede Aufnahme mit Soundstone an derselben Stelle machen, möglichst vor einem dunklen, gleichmäßigen Hintergrund, und Ausschnitte pixelgenau vergleichen (z. B. mit PIL). Farbwerte in RGB 0–255; Herkunft und Toleranzen im [Plan](../FOREVER-THEME-PLAN.md#test-plan).

| Prüfung | Ergebnis / Beobachtung |
| --- | --- |
| Retail, Mists, Anniversary, Era: Leiste, große Ansicht und Optionen pixelgleich mit einem 0.3.8-Ausschnitt, bis auf die Versionsnummer | offen |
| WoW: Forever, erstes Einloggen nach dem Update: Forever-Aussehen ohne `/reload`; `/soundstone theme` ist ein unbekannter Befehl und ändert nichts | offen |
| WoW: Forever, Fensterrahmen: große Ansicht und Einstellungen im Bronzerahmen der Forever-Fenster; das Metall endet bündig an Soundstones Kanten (Ausschnitt neben einem Baganator- oder Blizzard-Fenster), nichts ragt in Band oder Titelleiste; Titel mittig in der Titelleiste und ganz lesbar; rote Kopfknöpfe (Zahnrad links, Ausblenden und Kompakt rechts) und das X in der Ecke wie bei Baganator; alle reagieren auf Hover, Klick und Tooltip; die Titelleiste verschiebt das Fenster; untere Ecken ohne Überlappung (`/dump C_Texture.GetAtlasInfo(\"UI-Frame-Metal-CornerBottomLeft\")` notieren) | optisch abgenommen am 9./10.11.2026 (1.60.1, Client-Skalierung 0.7, Soundstone 100 %); Tooltips, Ziehen an der Titelleiste und `/dump` nicht einzeln geprüft |
| WoW: Forever, Leistenrahmen: die Kompaktleiste im selben Bronzerahmen wie die große Ansicht, ohne Titelleiste; oben nur das Metallband mit seiner schwarzen Innenlinie, kein Rest der Titelleiste und keine Lücke; Ecken abgeschrägt wie am Fenster, Seiten ohne Naht; rechtes Ende oben ohne Kerbe oder Bruchstück (dort sitzt am Fenster sonst das X); Metall bündig mit Soundstones Außenkante; Zahnrad und Ansichtsknopf als rote Knöpfe mit goldenem Symbol wie in der Kopfzeile der großen Ansicht, mit Hover, Klick und Tooltip; Griff, Knöpfe, Icons und Werte ganz innerhalb des Bands; `/dump C_Texture.GetAtlasInfo(\"_UI-Frame-Metal-EdgeTop\")` und `/dump C_Texture.GetAtlasInfo(\"UI-Frame-Metal-CornerBottomLeft\")` notieren | abgenommen am 10.11.2026 (dieselbe Einstellung); Symbole der roten Knöpfe und Kanal-Icons auf verlustfreien Screenshots mittig nachgezählt; `/dump` offen |
| WoW: Forever, Regler und Icon-Rahmen: Spur und Kupferraute wie in Forevers Audioeinstellungen, goldene Füllung innerhalb der Spur; Rahmen der Kanal-Icons wie an Aktionsbuttons, Hover-Leuchten und gedrückte Darstellung | gesehen am 9.11.2026 auf einem Screenshot der großen Ansicht; Hover und Gedrückt nicht einzeln geprüft |
| WoW: Forever, Farben: Kanaltrenner 104/80/52; Titel und Abschnittsüberschriften #FFD200 (`/dump NORMAL_FONT_COLOR:GetRGB()`); Werte 240/233/218; Fußzeile 166/160/148. Der flache Ersatz (Fläche, Linien, Band, flache Felder) erscheint nur, wenn Forevers Grafik fehlt, und ist nur in den simulierten Tests geprüft | offen |
| Unverändert: Lautstärkebalken 255/176/33, stumme Icons ausgegraut, Blizzard-Buttons, Kontrollkästchen, Geräteauswahl, Geräteliste und Tooltips | offen |
| Reglerknopf: in Forever die Kupferraute aus Forevers Audioeinstellungen, in den anderen Clients das bisherige Sprite; erreicht 0 % und 100 % | offen |
| Hover und Gedrückt an Zahnrad und Ansichtsbutton; Optionen unter und über der Leiste; Geräteliste offen; ein Tooltip | offen |
| Mists, Anniversary, Era: `/dump Soundstone.UI.outputDropdown.native` notieren | offen |
