# Soundstone – Azeroth Audio

## Installation

Entpacke `Soundstone-0.1.0.zip` in den Ordner `Interface\AddOns` der gewünschten WoW-Version. Die Datei muss anschließend unter `Interface\AddOns\Soundstone\Soundstone.toc` liegen.

Wähle im WoW-Installationsordner `_retail_`, `_classic_`, `_anniversary_` oder `_classic_era_`. Bei Installation im laufenden Spiel zuerst `/reload` versuchen. Falls Soundstone danach nicht erscheint, den Client vollständig neu starten und Soundstone in der Addon-Liste aktivieren.

## Bedienung

- `/soundstone` oder `/azeraudio` öffnet das Reglerfenster.
- Linksklick auf ein Leisten-Icon schaltet Gesamt, Soundeffekte oder Musik um.
- Rechtsklick öffnet die Regler. Alle Lautstärken reichen von 0–100 %.
- Das Mausrad verändert den Wert um 5 Prozentpunkte, mit Umschalt um 1.
- Die Leiste lässt sich am Griff verschieben, das Fenster an der Titelleiste.
- Linksklick auf den Minimap-Button öffnet das Fenster. Rechtsklick blendet die Leiste ein oder aus.
- Unter **Optionen** kannst du Leiste und Minimap-Button separat einblenden, Positionen sperren oder zurücksetzen.
- Unter WoWs Tastenbelegungen sind vier optionale Soundstone-Aktionen verfügbar. Vorhandene Tastenbelegungen werden nicht geändert.

## Was bedeuten die Prozentwerte?

Die Zahlen sind die eingestellten Lautstärken der WoW-Kanäle. Stummschalten erhält sie. Steht Musik auf 25 %, bleibt auch nach dem Ausschalten **25 %** sichtbar. Ein durchgestrichenes Icon zeigt die Stummschaltung an; der Tooltip nennt die Ursache.

**Gesamt** ist WoWs Master-Regler. Er beeinflusst den gesamten darüber laufenden Spielton, ohne die Einzelwerte neu einzustellen. **Soundeffekte** steuert den SFX-Kanal, **Musik** den Musikkanal. Umgebungsgeräusche, Dialoge und Voicechat erhalten keine zusätzlichen Einzelregler.

## Erste Prüfung im Spiel

1. Vorhandene Audioeinstellungen notieren. Nach dem Laden müssen die Werte unverändert sein.
2. Musik aus- und wieder einschalten; ihr Prozentwert muss gleich bleiben.
3. Gesamt ausschalten, den Musikregler verändern und Gesamt wieder einschalten. Musik darf nicht selbstständig aktiviert werden.
4. Einen Wert in Blizzards Audioeinstellungen verändern und mit der Soundstone-Anzeige vergleichen.
5. Leiste verschieben, sperren und `/reload` ausführen. Position und Sichtbarkeit müssen erhalten bleiben.

Die automatisierten Lua-Tests ersetzen nicht den Test im echten Client. Der genaue Stand steht in [TESTING.md](TESTING.md). WoW: Forever ist noch nicht bestätigt.
