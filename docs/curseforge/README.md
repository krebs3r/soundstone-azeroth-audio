# CurseForge-Veröffentlichung

Aktueller Einrichtungs- und Moderationsstand: [STATUS.md](STATUS.md).

## Ablauf

Ein Tag `vX.Y.Z` baut und testet ein GitHub-Prerelease. Nach dokumentierter Ingame-Abnahme wird es **in der GitHub-Oberfläche** zum regulären Release hochgestuft. Der Workflow **Publish approved release to CurseForge** überträgt dessen unverändertes ZIP. Das Generieren des Prereleases mit `GITHUB_TOKEN` löst absichtlich keine weiteren Workflows aus; die persönliche Freigabe in der Oberfläche tut dies.

Die aktuelle Automation verwendet die Werkzeuge und Abnahmedaten aus `main`, aber prüft und testet einen separaten sauberen Checkout des veröffentlichten Tags. Erst die Abnahmedaten in `main` ergänzen, dann das Release freigeben. Bestehende Tags niemals verschieben.

## Konto und Projekt

1. Auf https://authors.curseforge.com mit GitHub anmelden; Anzeigename `krebs3r`.
2. `project.json`, `description.md` und `logo-400.png` als Vorlage für ein WoW-Addon-Projekt verwenden. MIT wählen. Kommentare aktivieren, das Projekt nicht als unlisted/experimental anlegen. Keine Rewards nötig.
3. GitHub-Repository als Source, GitHub Issues als Fehlertracker hinterlegen. Nach Anlage die tatsächliche Projekt-ID/URL in `project.json` eintragen.
4. Einen CurseForge-API-Token unter https://www.curseforge.com/account/api-tokens erzeugen. Token direkt unter GitHub → Repository Settings → Secrets and variables → Actions als **Secret `CF_API_TOKEN`** speichern. Keine Tokens in Chat, Dateien, Befehlszeilen oder Git-Commits schreiben. Die numerische Projekt-ID als **Variable `CF_PROJECT_ID`** speichern.
5. CurseForge Automatic Packaging nicht zusätzlich aktivieren: der GitHub-Workflow ist die einzige Upload-Quelle.

## Lokale Testinstallation

```powershell
python tools/install-local.py --all --status
python tools/install-local.py --all --dry-run
python tools/install-local.py --all --install
python tools/install-local.py --client anniversary --install
```

Standardwurzel: `E:\Battle.net\World of Warcraft`; andere Installationen über `--root` auswählen. Ohne `--install` gibt es keine Änderungen. Ein früher verwendeter expliziter Soundstone-Zielpfad ist weiter möglich, benötigt jetzt ebenfalls `--install`. Das Paket wird anhand seiner `.sha256` geprüft; `--archive` wählt ein anderes Release-ZIP.

Laufende Clients werden standardmäßig zurückgestellt (Exitcode 2). Für bereits installierte Addons erlaubt `--install --allow-running` ausdrücklich ein Update bei laufendem Client, zum Beispiel `python tools/install-local.py --client retail --install --allow-running`. Erst nach erfolgreicher Installation und Dateiprüfung `/reload` ausführen. Bei neu hinzugefügten Dateien oder Assets kann ein Client-Neustart nötig sein. Unveränderte Installationen werden übersprungen. Sicherungen liegen unter `.local-history/install-backups/`, der letzte Bericht unter `.local-history/last-install.json`. Nur der Soundstone-Ordner wird ersetzt. `WTF` und andere Addons bleiben unangetastet. Bei fehlgeschlagener Wiederherstellung meldet das Skript den erhaltenen Transaktionsordner; diesen zur Wiederherstellung verwenden und nicht löschen.

Das 400-Pixel-Logo wird aus derselben Originalgrafik und mit demselben Exportverfahren wie das Addon-Logo erzeugt:

```powershell
./tools/export-assets.ps1 -CurseForgeLogoOnly
```

Es wurde keine neue Grafik generiert. Der Logo-Export verändert keine Laufzeit-Assets; die Herkunft steht in `docs/ARTWORK.md`.

## Abnahme je Release

`INGAME-TEST.md` ausfüllen und ein Protokoll unter `acceptance/` speichern. Die Datei muss mindestens Tag, vollständigen WoW-Build und ZIP-SHA256 nennen. Screenshots unter `screenshots/` ablegen; echte Spielaufnahmen verwenden. Die Galerie wird separat im Dashboard gepflegt.

In `releases/vX.Y.Z.json` stehen Tag, exakter Commit, ZIP-Prüfsumme, Changelog-Dateiname und **nur bestätigte** Clients. Beispiel eines Eintrags (erst nach tatsächlich bestandenem Test ausfüllen):

```json
{
  "client": "anniversary",
  "game_version": "2.5.6",
  "build": "2.5.6.69795",
  "status": "passed",
  "tested_by": "krebs3r",
  "tested_at": "2026-09-15",
  "evidence": "acceptance/v0.3.0-anniversary.md"
}
```

Zulässige Familien: `retail`, `mists`, `anniversary`, `era`. Build und Version im Beispiel sind keine Abnahme. Das Skript ermittelt die exakte CurseForge-Spielversions-ID innerhalb der jeweiligen Familie und bricht bei unbekannten/mehrdeutigen Versionen ab. Es wählt niemals ersatzweise eine andere Version. Die TOC kann zusätzliche Zielversionen enthalten; diese werden ohne Abnahme nicht als unterstützt hochgeladen.

## Prüflauf und Erstveröffentlichung 0.3.0

GitHub → Actions → **Publish approved release to CurseForge** → Run workflow auf `main`, Tag `v0.3.0`, **dry_run angehakt**. ZIP und Quellstand werden verglichen, die Lua-Szenarien und Paketprüfungen ausgeführt, Abnahme und API-Zuordnungen geprüft. Ohne Abnahme oder API-Einrichtung endet der Lauf mit einer konkreten Fehlermeldung und ohne Upload.

Nach erfolgreichem Prüflauf denselben Workflow mit deaktiviertem `dry_run` ausführen. Dieser einmalige manuelle Start ist nötig, weil 0.3.0 schon vor Einrichtung der Automation regulär veröffentlicht war. Spätere Freigaben starten automatisch. Ein reiner Tag-Push oder ein Prerelease veröffentlicht nichts auf CurseForge.

Der Rückgabestatus `uploaded-awaiting-moderation` bedeutet ausschließlich erfolgreiche Übertragung. Projekt/Datei im CurseForge-Dashboard auf Genehmigung prüfen. Danach Download-Prüfsumme und Installation über den CurseForge-Client testen. Moderationsprobleme im bestehenden Projekt beheben; keine Duplikatprojekte oder Testuploads erzeugen.

## Wiederholung und unklare Ergebnisse

Vor dem eigentlichen POST wird am GitHub-Release `curseforge-upload-pending.json` mit Tag, Commit, Projekt-ID und Prüfsumme gespeichert. Nach Erfolg folgt `curseforge-upload.json` mit der CurseForge-Datei-ID. Ein gültiger endgültiger Beleg bewirkt beim Wiederholen **keinen erneuten Upload**. Ein abweichender Beleg stoppt den Lauf. Die Workflow-Concurrency verhindert parallele Uploads desselben Tags.

Bleibt nur der Pending-Beleg, **nicht blind erneut hochladen**. Im CurseForge-Dashboard auch ausstehende/abgelehnte Dateien prüfen. Bei vorhandener Datei ihre Identität/Prüfsumme feststellen und den endgültigen Beleg mit der tatsächlichen Datei-ID ergänzen; den Upload nicht wiederholen. Ist nach Klärung sicher, dass kein Upload angenommen wurde, den Pending-Beleg am GitHub-Release entfernen und erneut starten. Eine nicht sichtbare Datei allein ist kein Nachweis, dass der Upload fehlgeschlagen ist. Bleibt das Ergebnis unklar, erst CurseForge klären lassen.

## Tests

Falls lokal der GitHub-Downloadserver nicht erreichbar ist, kann ein bereits heruntergeladenes ZIP mit `--archive dist/Soundstone-0.3.0.zip` geprüft werden. Dieser Modus verlangt zusätzlich die passende SHA256 im GitHub-Asset-Datensatz und ist ausschließlich für einen lesenden Prüflauf zulässig. Der echte Upload lädt das ZIP immer selbst von GitHub herunter.

Weitere bestätigte Clients werden bei künftigen Releases im jeweiligen Abnahmedatensatz ergänzt. Soll eine bereits hochgeladene Datei zusätzliche Spielversionen erhalten, diese nach dokumentierter Abnahme im CurseForge-Dashboard ergänzen; der Workflow lädt dieselbe Datei dank Upload-Beleg nicht erneut hoch.

```powershell
python -m unittest discover -s tests -p 'test_release_tools.py' -v
python tests/run.py
```

Die neuen Tests verwenden temporäre Ordner und simulierte APIs; sie berühren keine echten WoW-Installationen und laden nichts hoch. Python 3.12 mit `requirements-dev.txt` ist die CI-Umgebung. Die ursprünglichen 711 Szenarien bleiben unverändert.

## Quellen

- [CurseForge-Konto](https://support.curseforge.com/support/solutions/articles/9000277491-curseforge-account-security)
- [Moderationsrichtlinien](https://support.curseforge.com/support/solutions/articles/9000197279)
- [Upload-API](https://support.curseforge.com/support/solutions/articles/9000197321)
- [WoW-Familien und Versionsauflösung im BigWigs-Packager](https://github.com/BigWigsMods/packager/blob/master/release.sh)
- [GitHub Release-Ereignisse](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#release)
