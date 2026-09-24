# Soundstone – Azeroth Audio

## Warum ich Soundstone erstellt habe

Ich habe Soundstone erstellt, weil ich beim WoW-Spielen gelegentlich Netflix, YouTube oder andere Streamingdienste auf dem zweiten Bildschirm schaue. Dafür wollte ich Spielsound und Musik schnell stummschalten oder anpassen können, ohne jedes Mal das Audiomenü zu öffnen.

## Installation

Entpacke `Soundstone-0.3.2.zip` in den Ordner `Interface\AddOns` der gewünschten WoW-Version. Die Datei muss anschließend unter `Interface\AddOns\Soundstone\Soundstone.toc` liegen.

Wähle im WoW-Installationsordner `_retail_`, `_classic_`, `_anniversary_` oder `_classic_era_`. Bei Installation im laufenden Spiel zuerst `/reload` versuchen. Falls Soundstone danach nicht erscheint, den Client vollständig neu starten und Soundstone in der Addon-Liste aktivieren.

## Bedienung

- `/soundstone` oder `/azeraudio` wechselt zwischen Kompaktleiste und großem Reglerfenster. Ist Soundstone ausgeblendet, wird zuerst die zuletzt verwendete Ansicht wiederhergestellt. Beide Ansichten teilen sich eine Position und ersetzen einander.
- Linksklick auf ein Leisten-Icon schaltet Gesamt, Soundeffekte oder Musik um. Rechtsklick öffnet die Regler.
- Alle Lautstärken reichen von 0–100 %. Das Mausrad verändert den Wert um 5 Prozentpunkte, mit Umschalt um 1.
- Das Zahnrad neben dem Sechspunktgriff öffnet das Zusatzmenü. Der Griff dient zum Verschieben. Das große Fenster lässt sich zusätzlich an der Titelleiste verschieben.
- Die Pfeile wechseln direkt die Ansicht: In der Kompaktleiste stehen sie rechts neben dem Zahnrad, im großen Fenster zwischen Auge und X.
- Das rote X kehrt zur Kompaktleiste zurück. Escape schließt zuerst die Geräteliste, dann das Zusatzmenü und zuletzt das große Fenster.
- In Retail steht Soundstone im **Addons-Menü** oben rechts unter der Uhr. Linksklick stellt die ausgeblendete Ansicht wieder her oder wechselt die sichtbare Ansicht, Rechtsklick blendet Soundstone ein oder aus. Der Minimap-Button ist dort ab 0.3.3 standardmäßig aus und lässt sich in den Optionen oder mit `/soundstone minimap` wieder einschalten.
- Linksklick auf den Minimap-Button stellt die ausgeblendete Ansicht wieder her oder wechselt die sichtbare Ansicht. Rechtsklick blendet Soundstone ein oder aus. Ziehen verschiebt den Minimap-Button.
- Im Zusatzmenü kannst du das Ausgabegerät wählen, die Größe einstellen, den Minimap-Button einblenden sowie Positionen sperren oder zurücksetzen.
- Das **durchgestrichene Auge im rechten Buttonblock** in der großen Ansicht blendet Soundstone aus: Es schließt alle Soundstone-Fenster und verwirft eine noch nicht übernommene Größenänderung. Mit `/soundstone`, `/soundstone show` oder Minimap-Linksklick kehrst du zur letzten Ansicht zurück. Der Befehl funktioniert auch bei ausgeblendetem Minimap-Button. Ansicht, Position und Audioeinstellungen bleiben auch nach `/reload` erhalten; die Minimap-Sichtbarkeit bleibt separat eingestellt. In der Kompaktleiste kannst du direkt `/soundstone hide` oder Minimap-Rechtsklick verwenden.
- Unter WoWs Tastenbelegungen sind vier optionale Soundstone-Aktionen verfügbar. Vorhandene Tastenbelegungen werden nicht geändert.

## Was bedeuten die Prozentwerte?

Die Zahlen sind die eingestellten Lautstärken der WoW-Kanäle. Stummschalten erhält sie. Steht Musik auf 25 %, bleibt auch nach dem Ausschalten **25 %** sichtbar. Nicht hörbare Kanäle haben ausgegraute Icons ohne roten Strich; der Tooltip nennt die Ursache. Die An/Aus-Buttons berücksichtigen ebenfalls den gesamten Signalweg: Ist Gesamt aus oder auf 0 %, zeigen auch Soundeffekte und Musik **Aus**. Ist kein Einzelkanal hörbar, zeigt Gesamt ebenfalls Aus.

**Gesamt** schaltet den gesamten Spielton stumm und merkt sich die bisherigen Einzelschalter und Lautstärken. Beim Wiedereinschalten kehrt diese Auswahl zurück. Sind alle Einzelkanäle ausdrücklich ausgeschaltet, aktiviert Gesamt beide Gruppen.

**Soundeffekte** bündelt Effekte, Umgebungsgeräusche und Dialoge. Der Schalter aktiviert beziehungsweise deaktiviert alle drei gemeinsam. Der Lautstärkeregler setzt alle drei auf denselben Prozentwert. Aus- und Einschalten erhält dagegen ihre jeweiligen positiven Lautstärken. Stellst du in Blizzards Audiomenü unterschiedliche Werte ein, zeigt das Hauptfeld den Effektwert; der kurze Tooltip erklärt die Gruppierung und zeigt, wenn nur ein Teil aktiv ist. **Musik** bleibt eine eigene Gruppe; Voicechat wird nicht mitgesteuert.

Ist Gesamt aus oder auf 0 % und du aktivierst Musik, werden nur Musik und der benötigte Gesamtkanal eingeschaltet. Effekte, Umgebung und Dialoge bleiben stumm. Aktivierst du stattdessen Soundeffekte, bleibt Musik stumm. Ist Gesamt schon aktiv, verändert das Einschalten einer Gruppe die andere Gruppe nicht.

Beim Einschalten eines Kanals mit 0 % wird dessen letzte positive Lautstärke wiederhergestellt, bei Bedarf auch die Gesamtlautstärke. Diese Werte bleiben über `/reload` erhalten. Falls Soundstone noch keinen positiven Wert kennt, verwendet erst der ausdrückliche Einschaltklick 50 % für Gesamt/Effekte/Umgebung/Dialoge und 25 % für Musik. Beim Laden werden keine Lautstärken oder Schalter geändert. Das Verschieben eines stummen Reglers allein schaltet weiterhin keinen Kanal ein.

Kompakt-Icons, große Ansicht, Tastenbelegungen und Slash-Befehle verwenden dieselbe Schaltlogik. Nach Änderungen liest Soundstone WoWs Werte zurück. Scheitert eine Änderung, versucht es die vorherigen Werte wiederherzustellen und meldet den Fehler; die Anzeige folgt den tatsächlich gelesenen Einstellungen.

## Ausgabegerät und Größe

Die Geräteauswahl steuert den WoW-Spielton. Unterstützt der Client Blizzards modernes Menüsystem, nutzt Soundstone dessen Dropdown mit Einzelauswahl. Sonst erscheint eine angehängte Ersatzliste im Blizzard-Stil. Beide folgen der eingestellten UI-Größe; ein separates Gerätefenster gibt es nicht mehr. Sie zeigt die Geräte an, die WoW anbietet, einschließlich des Systemstandards. Die Liste klappt direkt am Auswahlfeld auf, bei Platzmangel nach oben. Sie zeigt höchstens sechs Zeilen; weitere Geräte erreichst du durch Scrollen. Das Mausrad wechselt dabei kein Gerät. Eine Auswahl, ein erneuter Klick auf das Feld oder ein Klick außerhalb schließt die Liste. Lange Namen erscheinen vollständig im Tooltip. Escape schließt pro Tastendruck nur eine Ebene: Geräteliste, Optionen, große Ansicht.

Ein Gerätewechsel wird sofort übernommen und initialisiert WoWs Soundsystem einmal neu. Lautstärken und Stummschaltungen bleiben erhalten. Verschwundene Geräte und abgelehnte Änderungen meldet Soundstone im Chat. Die Liste wird beim Öffnen und bei Geräteereignissen aktualisiert; Geräteindizes werden nicht in den Addon-Einstellungen gespeichert.

Die Kompaktleiste misst 276 × 36, das große Fenster 300 × 160 und die Optionen 276 × 236 WoW-UI-Einheiten. Die Audio-Beschriftungen behalten ihre Größe; der volle Fenstertitel wird passend eingepasst. Die Leiste hat drei gleich breite Audiobereiche; feste Prozentfelder verhindern Verschiebungen zwischen 0 % und 100 %. In der großen Ansicht passen die Audio-Icons proportional in maximal 18 × 18 Einheiten und halten Abstand zur gerundeten Rahmenkante. Ihre Klickflächen bleiben 25 × 25 groß. Soundstone folgt WoWs UI-Skalierung und bietet zusätzlich 75–150 % Größe, mit 100 % als Standard. Der Minimap-Button folgt der Minimap. Beim Update von 0.1 werden die bisherige Leistenposition und Sichtbarkeit übernommen.

Die Einstellungen haben dieselbe Breite wie die Kompaktleiste und öffnen bündig mit vier Einheiten Abstand darunter. Am unteren Bildschirmrand öffnen sie darüber. Ist auf beiden Seiten zu wenig Platz, rückt die sichtbare Fenstergruppe vorübergehend ins Bild; beim Schließen kehrt sie zur gespeicherten Position zurück. Das große Fenster verwendet dieselbe vertikale Anordnung. Ausgabefeld und Rücksetzknöpfe sind innen 256 Einheiten breit.

Beim Ziehen des Größenreglers ändert sich zunächst nur die Prozentanzeige. Erst beim Loslassen wird die Größe übernommen. So bleibt der Regler während der Eingabe an derselben Stelle. Schließt du das Menü vorher mit Escape, wird die Vorschau verworfen. Der entsprechende Hinweis steht im Tooltip des Reglers. Die Rücksetzknöpfe stehen untereinander und haben die volle Breite. Unten rechts im großen Fenster siehst du die Addon-Version mit einem kleinen Herz und **by krebs3r**.

## Nützliche Befehle

```text
/soundstone compact       Kompaktleiste anzeigen
/soundstone expand        Großes Fenster anzeigen
/soundstone hide          Alle Soundstone-Fenster ausblenden
/soundstone show          Zuletzt verwendete Ansicht anzeigen
/soundstone scale 100     Größe auf 100 % setzen
/soundstone bar           Soundstone ein-/ausblenden
/soundstone minimap       Minimap-Button ein-/ausblenden
/soundstone lock          Positionen sperren/entsperren
/soundstone reset         Positionen zurücksetzen
/soundstone music 35      Musiklautstärke auf 35 % setzen
/soundstone music off     Musik stummschalten
/soundstone music on      Musik aktivieren, bei Bedarf mit Gesamt
/soundstone help          Befehle anzeigen
```

Stumme beziehungsweise nicht hörbare Kanäle werden in beiden Ansichten ausgegraut und leicht abgedunkelt angezeigt, ohne roten Strich. Beim erneuten Einschalten erscheinen die Icons wieder farbig, sobald der Kanal hörbar ist.

## Erste Prüfung im Spiel

1. Vorhandene Audioeinstellungen notieren. Nach dem Laden müssen die Werte unverändert sein.
2. Musik aus- und wieder einschalten; ihr Prozentwert muss gleich bleiben.
3. Gesamt ausschalten: Alle drei Buttons müssen Aus anzeigen. Gesamt wieder einschalten: Die bisherige Kanalauswahl muss zurückkehren. Anschließend Gesamt aus und nur das Musik-Icon anklicken: Nur Musik darf hörbar werden. Mit Soundeffekten wiederholen; dann müssen Effekte, Umgebung und Dialoge gemeinsam aktiv sein und Musik aus bleiben. Bei bereits aktivem Gesamt kann die zweite Gruppe dazugeschaltet werden.
4. Einen Wert in Blizzards Audioeinstellungen verändern und mit der Soundstone-Anzeige vergleichen.
5. Leiste verschieben, sperren und `/reload` ausführen. Position und Sichtbarkeit müssen erhalten bleiben.
6. Zwischen beiden Ansichten wechseln und das stufenweise Schließen mit Escape testen.
7. Größe verändern und an den Bildschirmrändern prüfen; anschließend auf 100 % zurücksetzen.
8. Ein anderes Ausgabegerät wählen und den Ton prüfen. Danach das ursprüngliche Gerät wieder auswählen; Lautstärken und Stummschaltungen müssen unverändert sein.
9. Über das Auge Soundstone ausblenden, `/reload` ausführen und mit `/soundstone` zurückholen. Auch bei deaktiviertem Minimap-Button wiederholen; zum Ausblenden der Kompaktleiste `/soundstone hide` verwenden.
10. Dropdown-Zentrierung, vollständige Buttontexte, 0 % / 100 % und stumme Kanäle prüfen. Bei beiden Auflösungen (1080p/1440p), WoW-Skalierungen (65/85/100 %) und Soundstone-Größen (75/100/150 %) auf Überlappungen und Bildschirmränder achten.
11. Rechts im großen Fenster stehen Auge, Kompaktansicht und X. Alle drei verwenden denselben roten Rahmen und identische 20 × 20 große Klickflächen. Beim Darüberfahren werden sie wärmer, beim Drücken dunkler. Die Kompaktleiste behält ihren bisherigen 19 × 19 großen Ansichtsbutton. In beiden Ansichten die Tooltips, Buttonzustände und Mausfreigabe außerhalb prüfen.
12. Pfeilbuttons in beiden Ansichten sowie Augen-Button und ihre Tooltips prüfen. Icons müssen vollständig innerhalb der Classic-Rahmen bleiben. Titel und Fußzeile dürfen keine Bedienelemente überdecken.
13. Dropdown öffnen, erneut anklicken, außerhalb klicken und dreimal Escape drücken. Bei mehr als sechs Geräten scrollen, lange Namen im Tooltip prüfen und das Menü am unteren Bildschirmrand testen. Während der offenen Liste das Ausgabegerät in Blizzards Einstellungen ändern oder ein Gerät trennen; Liste und Auswahl müssen aktuell bleiben.
14. Musik auf einen positiven Wert stellen, dann auf 0 %. Einschalten muss den positiven Wert zurückholen; mit Gesamt auf 0 % und nach `/reload` wiederholen. Das Verschieben eines ausgeschalteten Reglers allein darf nichts einschalten. Sind alle Einzelschalter aus, muss Gesamt beide Gruppen aktivieren.
15. In Blizzards Audiomenü unterschiedliche Effekt-, Umgebungs- und Dialogwerte einstellen. Das Hauptfeld zeigt den Effektwert; gemeinsames Stummschalten und Wiedereinschalten erhält positive Einzelwerte. Erst das Bewegen des Soundeffektreglers setzt alle drei gleich. Auch Musik-only auf Umgebungsgeräusche und gesprochene Dialoge prüfen; Voicechat-Einstellungen müssen erhalten bleiben.

Die automatisierten Lua-Tests ersetzen nicht den Test im echten Client. Der genaue Stand steht in [TESTING.md](TESTING.md). WoW: Forever ist noch nicht bestätigt.

16. Einstellungen an allen Bildschirmrändern öffnen: Breite und linke Außenkante müssen zur Kompaktleiste passen. Unten müssen sie nach oben ausweichen. Nach dem Schließen darf die gespeicherte Position nicht verändert sein.


## Freier Platz, kurze Hilfe und Version

In den Optionen ist **„Überlappung beim Ablegen vermeiden“** standardmäßig eingeschaltet. Beim Loslassen und beim Wechsel von der kleinen zur großen Ansicht sucht Soundstone den nächstgelegenen freien Platz neben sichtbaren, lesbaren UI-Bedienelementen. Andere Fenster werden nicht verschoben. Ist kein Platz verfügbar, geht Soundstone zur vorherigen Position zurück und meldet dies im Chat. Ist beim Vergrößern kein Platz verfügbar oder die Prüfung nicht möglich, kehrt Soundstone zur kleinen Ansicht zurück. Nachträglich geöffnete Fenster, dekorative Flächen und von WoW geschützte/nicht lesbare Positionen können weiterhin überlappen. Für völlig freies Ablegen die Option ausschalten.

Die Kompaktleiste zeigt kurze Klick-/Mausradhilfe. In der großen Ansicht unterscheiden sich die Hinweise für An/Aus-Buttons und Lautstärkeregler. Soundeffekte umfasst weiterhin Effekte, Umgebung und Dialoge.

Der Titel heißt **Soundstone – Azeroth Audio**. Die Schrift passt sich innerhalb des vorhandenen Platzes an; falls ein Client den Namen nicht lesbar unterbringt, zeigt er „Soundstone“ und den vollen Namen im Tooltip.

Die Versionszeile zeigt die installierte Addon-Version. Ab 0.3.2 enthält das Addon keine Änderungsübersicht mehr. Versionshinweise stehen auf der GitHub-Release-Seite und auf CurseForge.

Die Optionen sind 276 × 236 Einheiten groß. Kompaktleiste und Audiofenster bleiben unverändert.

Alle vier aktuellen offiziellen Clientfamilien sind Zielplattformen. Die aktuelle Version ist noch nicht in sämtlichen Clients und Spielmodi im Spiel abgenommen. Siehe `docs/COMPATIBILITY.md`; Forever bleibt unbestätigt.


## Release herunterladen

Das installierbare Paket heißt **Soundstone-0.3.2.zip** und liegt unter **Assets** auf der [Release-Seite](https://github.com/krebs3r/soundstone-azeroth-audio/releases/tag/v0.3.0). Nicht die automatisch angebotenen „Source code“-Archive verwenden. Beim Entpacken muss genau `Interface/AddOns/Soundstone/Soundstone.toc` entstehen. Die zusätzlichen README-Bilder zeigen die aktuelle Browser-Vorschau mit Originaltexturen, keine Ingame-Aufnahmen.
