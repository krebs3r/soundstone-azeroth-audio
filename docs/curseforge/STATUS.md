# Einrichtungsstand am 15.09.2026

## Update: Freigabe 0.3.2

0.3.2 fasst die Platzierungs-/Tooltip-Korrekturen, den entfernten Ingame-Changelog und das kleinere Minimap-Logo zusammen. 781 Lua-Szenarien und 24 lokale Installations-/Release-Tests bestehen; ein Symlink-Test ist unter Windows übersprungen und besteht in der Linux-CI. [PR #3](https://github.com/krebs3r/soundstone-azeroth-audio/pull/3) ist übernommen.

- [v0.3.2](https://github.com/krebs3r/soundstone-azeroth-audio/releases/tag/v0.3.2) ist als reguläres GitHub-Release (Latest) veröffentlicht, Commit `254b6b6ab103421c85773df8f6c02a0af461c5c5`.
- Das originale GitHub-ZIP ist mit 38 Dateien in Retail und TBC Anniversary installiert und vollständig verifiziert. Der Nutzer hat das finale Paket einschließlich Minimap-Icon in beiden Clients bestätigt: [Retail](acceptance/v0.3.2-retail.md), [TBC Anniversary](acceptance/v0.3.2-anniversary.md). Beide Freigabedaten stehen auf `passed`.
- Der durch die reguläre GitHub-Freigabe ausgelöste [CurseForge-Workflow](https://github.com/krebs3r/soundstone-azeroth-audio/actions/runs/34964191044) ist erfolgreich: Datei **8885767**, Typ **Release**, Upload am 15.09.2026 um 11:36 UTC.
- Spielversionen im Autoren-Dashboard bestätigt: **Retail 12.1.0** (API-ID **16519**) und **TBC Anniversary 2.5.6** (API-ID **16533**).
- Der endgültige [Upload-Beleg](https://github.com/krebs3r/soundstone-azeroth-audio/releases/download/v0.3.2/curseforge-upload.json) ist am GitHub-Release gespeichert. Er hat Vorrang vor dem historischen Pending-Beleg und verhindert erneute Uploads desselben Pakets.
- Das ZIP wurde vom CurseForge-CDN zurückgeladen. SHA256 stimmt mit dem getesteten GitHub-Paket überein: `02cfe105da5fc6ea2e59e40fb830195ed05da3e6562a03c3446fdb6d89f48277`.
- Moderationsstatus im [Autoren-Dashboard](https://authors.curseforge.com/#/projects/1696875/files/8885767): **Under Review**. Das Projekt ist bis zur Genehmigung noch nicht öffentlich sichtbar; nach Genehmigung soll die Datei automatisch veröffentlicht werden.

## Noch offen

Nach der Moderationsfreigabe:

1. [Öffentliche Projektseite](https://www.curseforge.com/wow/addons/soundstone-azeroth-audio), Galerie und Zuordnung zu Retail 12.1.0 sowie TBC Anniversary 2.5.6 prüfen.
2. Installation von 0.3.2 über die CurseForge-App in beiden Clients kontrollieren. Paketidentität und direkte lokale Installation sind bereits geprüft; die Verteilung durch die App ist noch offen.
3. Diesen Status aktualisieren und gegebenenfalls Moderationsrückfragen im bestehenden Projekt bearbeiten.

Historische Tags und GitHub-ZIPs bleiben unverändert. Künftige Addon-Korrekturen bekommen eine neue Version. Galerie und Beschreibung werden separat gepflegt; der Release-Workflow überträgt ZIP und Changelog sowie ausschließlich dokumentierte, bestätigte Spielversionen.

## Erledigt (0.3.0)

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

## Historischer Prüfstand 0.3.0

Im [Autoren-Dashboard](https://authors.curseforge.com/#/projects/1696875/files) steht die Datei auf **Under Review** (geprüft nach dem Upload am 15.09.2026). Das neue Projekt ist bis zur Moderationsfreigabe noch nicht öffentlich verfügbar. Die Datei soll nach Genehmigung automatisch veröffentlicht werden.

Die Prüfsumme des übertragenen GitHub-ZIPs 0.3.0 ist `ad31660d4a96594dec59431d2586046e23afa27b0372263a4935dfc1d8b19482`; dessen Rückdownload war beim ersten Upload wegen Verbindungsabbrüchen nicht prüfbar. Für die aktuelle Version 0.3.2 ist der Rückdownload inzwischen erfolgreich geprüft (siehe oben).
