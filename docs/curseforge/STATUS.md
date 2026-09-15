# Einrichtungsstand am 15.09.2026

## Erledigt

- Projekt **Soundstone – Azeroth Audio**, ID **1696875**, Konto `krebs3r`.
- Kategorie Audio & Video, MIT, GitHub-Quellcode und externer GitHub-Issue-Tracker, Drittanbieter-Verteilung erlaubt.
- Englische/deutsche Beschreibung, 400×400-Logo und drei echte, beschriftete Ingame-Aufnahmen gespeichert.
- GitHub Secret `CF_API_TOKEN` und Variable `CF_PROJECT_ID` eingerichtet. Keine Zugangsdaten im Repository.
- Installationshilfe und Veröffentlichung über reguläre GitHub-Releases in `main` aktiviert.
- Alle vier lokalen Clients enthalten exakt die 39 Dateien des GitHub-Release-ZIPs v0.3.0. Die frühere Anniversary-Installation wurde gesichert; `WTF` blieb unverändert.
- 711 Lua-Szenarien und 23 Installations-/Release-Tests in der GitHub-CI bestanden.
- [TBC Anniversary 2.5.6.69795 erfolgreich abgenommen](acceptance/v0.3.0-anniversary.md). Andere Clients noch nicht für CurseForge freigegeben.
- [Vollständiger API-Prüflauf erfolgreich](https://github.com/krebs3r/soundstone-azeroth-audio/actions/runs/34952987691).
- [Erster Upload erfolgreich](https://github.com/krebs3r/soundstone-azeroth-audio/actions/runs/34953150511): Datei **8885266**, Typ **Release**, Spielversion **2.5.6**, CurseForge-Versions-ID **16533**.
- Der endgültige Upload-Beleg `curseforge-upload.json` ist am [GitHub-Release v0.3.0](https://github.com/krebs3r/soundstone-azeroth-audio/releases/tag/v0.3.0) gespeichert. Ein vorhandener Pending-Beleg bleibt als Historie erhalten; der endgültige Beleg hat Vorrang.

## Noch offen

Im [Autoren-Dashboard](https://authors.curseforge.com/#/projects/1696875/files) steht die Datei auf **Under Review** (geprüft nach dem Upload am 15.09.2026). Das neue Projekt ist bis zur Moderationsfreigabe noch nicht öffentlich verfügbar. Die Datei soll nach Genehmigung automatisch veröffentlicht werden.

Nach der Freigabe:

1. [Öffentliche Projektseite](https://www.curseforge.com/wow/addons/soundstone-azeroth-audio), Galerie und Zuordnung ausschließlich zu TBC Anniversary 2.5.6 prüfen.
2. Das von CurseForge heruntergeladene ZIP auf SHA256 `ad31660d4a96594dec59431d2586046e23afa27b0372263a4935dfc1d8b19482` prüfen. Die Prüfsumme des tatsächlich übertragenen GitHub-ZIPs ist bestätigt; der Rückdownload vom CurseForge-CDN konnte lokal wegen Verbindungsabbrüchen noch nicht geprüft werden.
3. Installation über die CurseForge-App in TBC Anniversary kontrollieren; zuvor WoW schließen. Das ist zusätzlich zu den bereits geprüften lokalen Testinstallationen nötig.
4. Diesen Status aktualisieren. Moderationsrückfragen im bestehenden Projekt bearbeiten.

Historischer Tag und GitHub-ZIP bleiben unverändert. Künftige Addon-Korrekturen bekommen eine neue Version. Galerie und Beschreibung werden separat gepflegt; der Release-Workflow überträgt ZIP und Changelog sowie ausschließlich dokumentierte, bestätigte Spielversionen.
