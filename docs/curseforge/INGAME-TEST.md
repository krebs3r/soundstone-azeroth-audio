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
