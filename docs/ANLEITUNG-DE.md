# Soundstone – Azeroth Audio

## Warum ich Soundstone erstellt habe

Ich habe Soundstone erstellt, weil ich beim WoW-Spielen gelegentlich Netflix, YouTube oder andere Streamingdienste auf dem zweiten Bildschirm schaue. Dafür wollte ich Spielsound und Musik schnell stummschalten oder anpassen können, ohne jedes Mal das Audiomenü zu öffnen.

## Installation

Entpacke `Soundstone-0.2.0.zip` in den Ordner `Interface\AddOns` der gewünschten WoW-Version. Die Datei muss anschließend unter `Interface\AddOns\Soundstone\Soundstone.toc` liegen.

Wähle im WoW-Installationsordner `_retail_`, `_classic_`, `_anniversary_` oder `_classic_era_`. Bei Installation im laufenden Spiel zuerst `/reload` versuchen. Falls Soundstone danach nicht erscheint, den Client vollständig neu starten und Soundstone in der Addon-Liste aktivieren.

## Bedienung

- `/soundstone` oder `/azeraudio` wechselt zwischen Kompaktleiste und großem Reglerfenster. Beide Ansichten teilen sich eine Position und ersetzen einander.
- Linksklick auf ein Leisten-Icon schaltet Gesamt, Soundeffekte oder Musik um. Rechtsklick öffnet die Regler.
- Alle Lautstärken reichen von 0–100 %. Das Mausrad verändert den Wert um 5 Prozentpunkte, mit Umschalt um 1.
- Ein Klick auf den Sechspunktgriff öffnet das Zusatzmenü. Ziehen am Griff verschiebt die Leiste. Das große Fenster lässt sich an der Titelleiste verschieben und hat links einen Menüknopf.
- Das rote X kehrt zur Kompaktleiste zurück. Escape schließt zuerst die Geräteliste, dann das Zusatzmenü und zuletzt das große Fenster.
- Linksklick auf den Minimap-Button wechselt die Ansicht. Rechtsklick blendet Soundstone ein oder aus. Ziehen verschiebt den Minimap-Button.
- Im Zusatzmenü kannst du die Ansicht wechseln, das Ausgabegerät wählen, die Größe einstellen, den Minimap-Button einblenden sowie Positionen sperren oder zurücksetzen.
- Unter WoWs Tastenbelegungen sind vier optionale Soundstone-Aktionen verfügbar. Vorhandene Tastenbelegungen werden nicht geändert.

## Was bedeuten die Prozentwerte?

Die Zahlen sind die eingestellten Lautstärken der WoW-Kanäle. Stummschalten erhält sie. Steht Musik auf 25 %, bleibt auch nach dem Ausschalten **25 %** sichtbar. Ein durchgestrichenes Icon zeigt die Stummschaltung an; der Tooltip nennt die Ursache.

**Gesamt** ist WoWs Master-Regler. Er beeinflusst den gesamten darüber laufenden Spielton, ohne die Einzelwerte neu einzustellen. **Soundeffekte** steuert den SFX-Kanal, **Musik** den Musikkanal. Umgebungsgeräusche, Dialoge und Voicechat erhalten keine zusätzlichen Einzelregler.

## Ausgabegerät und Größe

Die Geräteauswahl steuert den WoW-Spielton. Sie zeigt die Geräte an, die WoW anbietet, einschließlich des Systemstandards. Lange Namen erscheinen vollständig im Tooltip; bei mehr als sechs Einträgen kannst du mit dem Mausrad durch die Liste blättern.

Ein Gerätewechsel wird sofort übernommen und initialisiert WoWs Soundsystem einmal neu. Lautstärken und Stummschaltungen bleiben erhalten. Verschwundene Geräte und abgelehnte Änderungen meldet Soundstone im Chat. Die Liste wird beim Öffnen und bei Geräteereignissen aktualisiert; Geräteindizes werden nicht in den Addon-Einstellungen gespeichert.

Die Kompaktleiste misst 300 × 45, das große Fenster 300 × 160 WoW-UI-Einheiten. Soundstone folgt WoWs UI-Skalierung und bietet zusätzlich 75–150 % Größe, mit 100 % als Standard. Der Minimap-Button folgt der Minimap. Beim Update von 0.1 werden die bisherige Leistenposition und Sichtbarkeit übernommen.

## Nützliche Befehle

```text
/soundstone compact       Kompaktleiste anzeigen
/soundstone expand        Großes Fenster anzeigen
/soundstone scale 100     Größe auf 100 % setzen
/soundstone bar           Soundstone ein-/ausblenden
/soundstone minimap       Minimap-Button ein-/ausblenden
/soundstone lock          Positionen sperren/entsperren
/soundstone reset         Positionen zurücksetzen
/soundstone music 35      Musiklautstärke auf 35 % setzen
/soundstone music off     Musik stummschalten
/soundstone help          Befehle anzeigen
```

## Erste Prüfung im Spiel

1. Vorhandene Audioeinstellungen notieren. Nach dem Laden müssen die Werte unverändert sein.
2. Musik aus- und wieder einschalten; ihr Prozentwert muss gleich bleiben.
3. Gesamt ausschalten, den Musikregler verändern und Gesamt wieder einschalten. Musik darf nicht selbstständig aktiviert werden.
4. Einen Wert in Blizzards Audioeinstellungen verändern und mit der Soundstone-Anzeige vergleichen.
5. Leiste verschieben, sperren und `/reload` ausführen. Position und Sichtbarkeit müssen erhalten bleiben.
6. Zwischen beiden Ansichten wechseln und das stufenweise Schließen mit Escape testen.
7. Größe verändern und an den Bildschirmrändern prüfen; anschließend auf 100 % zurücksetzen.
8. Ein anderes Ausgabegerät wählen und den Ton prüfen. Danach das ursprüngliche Gerät wieder auswählen; Lautstärken und Stummschaltungen müssen unverändert sein.

Die automatisierten Lua-Tests ersetzen nicht den Test im echten Client. Der genaue Stand steht in [TESTING.md](TESTING.md). WoW: Forever ist noch nicht bestätigt.
