local _, A = ...

local en = {
    MASTER = "Master", SFX = "Sound effects", MUSIC = "Music",
    ON = "On", OFF = "Off", UNAVAILABLE = "Unavailable",
    MASTER_OFF = "Muted by master", MASTER_ZERO = "Master at 0%",
    ZERO = "Volume at 0%", SAVED = "Saved volume: %d%%",
    MASTER_HELP = "Controls all game audio routed through WoW's master channel. Individual volumes stay unchanged.",
    SFX_HELP = "Controls the sound-effects channel. Music, ambience and dialogue have separate settings.",
    MUSIC_HELP = "Controls in-game music.",
    TOGGLE_HELP = "Left-click: toggle  |  Right-click: open mixer",
    WHEEL_HELP = "Mouse wheel: 5%  |  Shift + wheel: 1%",
    DRAG_HELP = "Drag to move. Right-click to open the mixer.",
    LOCKED_HELP = "Position locked. Unlock in the mixer settings.",
    MINIMAP_HELP = "Left-click: mixer  |  Right-click: show/hide bar",
    MINIMAP_DRAG = "Drag around the minimap to reposition.",
    SETTINGS = "Options", SHOW_BAR = "Show compact bar", SHOW_MINIMAP = "Show minimap button",
    LOCK = "Lock positions", RESET = "Reset positions", CLOSE = "Close",
    MUTED_NOTE = "Muting keeps the saved volume.",
    READ_ERROR = "This audio control is unavailable in this client.",
    WRITE_ERROR = "WoW did not accept this audio change. The display has been refreshed.",
    HELP = "/soundstone or /azeraudio: mixer; bar, minimap, lock, reset, help; master/sfx/music [0-100|on|off|toggle]",
    BAD_COMMAND = "Unknown command. Use /soundstone help.",
    WELCOME = "Ready. Use /soundstone to open the mixer.",
    BIND_HEADER = "Soundstone - Azeroth Audio", BIND_PANEL = "Open audio mixer",
    BIND_MASTER = "Toggle all game audio", BIND_SFX = "Toggle sound effects", BIND_MUSIC = "Toggle music",
}

local de = {
    MASTER = "Gesamt", SFX = "Soundeffekte", MUSIC = "Musik",
    ON = "An", OFF = "Aus", UNAVAILABLE = "Nicht verfügbar",
    MASTER_OFF = "Durch Gesamt stumm", MASTER_ZERO = "Gesamt auf 0 %",
    ZERO = "Lautstärke auf 0 %", SAVED = "Gespeicherte Lautstärke: %d %%",
    MASTER_HELP = "Steuert den gesamten Spielton über WoWs Hauptkanal. Die einzelnen Lautstärkewerte bleiben erhalten.",
    SFX_HELP = "Steuert Soundeffekte. Musik, Umgebung und Dialoge haben eigene WoW-Einstellungen.",
    MUSIC_HELP = "Steuert die Musik im Spiel.",
    TOGGLE_HELP = "Linksklick: umschalten  |  Rechtsklick: Regler öffnen",
    WHEEL_HELP = "Mausrad: 5 %  |  Umschalt + Mausrad: 1 %",
    DRAG_HELP = "Zum Verschieben ziehen. Rechtsklick öffnet die Regler.",
    LOCKED_HELP = "Position gesperrt. In den Regleroptionen entsperren.",
    MINIMAP_HELP = "Linksklick: Regler  |  Rechtsklick: Leiste ein/aus",
    MINIMAP_DRAG = "Zum Verschieben am Minimap-Rand ziehen.",
    SETTINGS = "Optionen", SHOW_BAR = "Kompaktleiste anzeigen", SHOW_MINIMAP = "Minimap-Button anzeigen",
    LOCK = "Positionen sperren", RESET = "Positionen zurücksetzen", CLOSE = "Schließen",
    MUTED_NOTE = "Stummschalten erhält die Lautstärke.",
    READ_ERROR = "Diese Audiosteuerung ist in diesem Client nicht verfügbar.",
    WRITE_ERROR = "WoW hat die Audioänderung nicht übernommen. Die Anzeige wurde aktualisiert.",
    HELP = "/soundstone oder /azeraudio: Regler; bar, minimap, lock, reset, help; master/sfx/music [0-100|on|off|toggle]",
    BAD_COMMAND = "Unbekannter Befehl. Nutze /soundstone help.",
    WELCOME = "Bereit. Mit /soundstone öffnest du die Regler.",
    BIND_HEADER = "Soundstone - Azeroth Audio", BIND_PANEL = "Audioregler öffnen",
    BIND_MASTER = "Gesamten Spielton umschalten", BIND_SFX = "Soundeffekte umschalten", BIND_MUSIC = "Musik umschalten",
}

en.COMPACT='Compact view';en.EXPAND='Expanded view';en.OUTPUT='Output device'
en.HIDE='Hide Soundstone';en.HIDDEN='Hidden. Use /soundstone or left-click the minimap button to show it again.'
en.SIZE='Soundstone size';en.RESET_SIZE='Reset size';en.RESET='Reset position'
en.DEVICE_UNAVAILABLE='Output devices unavailable';en.DEVICE_GONE='Device no longer available'
en.DEVICE_RESTART_ERROR='WoW could not restart audio. Check the selected device in Audio settings.'
en.DEVICE_BUSY='Audio device change in progress';en.DEVICE_SCROLL='Scroll to see more devices'
en.DRAG_HELP='Drag: move. Click the gear for options and output device.'
en.SCALE_RELEASE='Release the slider to apply the size.'
en.TOGGLE_HELP='Left-click: toggle | Right-click: expanded view'
en.MINIMAP_HELP='Left-click: change view | Right-click: show/hide Soundstone'
en.BIND_PANEL='Switch compact / expanded view'
en.HELP='/soundstone: restore/change view; compact, expand, hide, show, bar, minimap, lock, reset, scale [75-150]; master/sfx/music [0-100|on|off|toggle]'
de.COMPACT='Kompaktansicht';de.EXPAND='Große Ansicht';de.OUTPUT='Ausgabegerät'
de.HIDE='Soundstone ausblenden';de.HIDDEN='Ausgeblendet. Mit /soundstone oder Minimap-Linksklick wieder anzeigen.'
de.SIZE='Soundstone-Größe';de.RESET_SIZE='Größe zurücksetzen';de.RESET='Position zurücksetzen'
de.DEVICE_UNAVAILABLE='Ausgabegeräte nicht verfügbar';de.DEVICE_GONE='Gerät nicht mehr verfügbar'
de.DEVICE_RESTART_ERROR='WoW konnte den Ton nicht neu starten. Prüfe das Gerät in den Audioeinstellungen.'
de.DEVICE_BUSY='Gerätewechsel läuft';de.DEVICE_SCROLL='Mausrad: weitere Geräte'
de.DRAG_HELP='Ziehen: verschieben. Zahnrad: Optionen und Ausgabegerät.'
de.SCALE_RELEASE='Größe wird beim Loslassen übernommen.'
de.TOGGLE_HELP='Linksklick: umschalten | Rechtsklick: große Ansicht'
de.MINIMAP_HELP='Linksklick: Ansicht wechseln | Rechtsklick: Soundstone ein/aus'
de.BIND_PANEL='Kompakte / große Ansicht wechseln'
de.HELP='/soundstone: wieder anzeigen/Ansicht wechseln; compact, expand, hide, show, bar, minimap, lock, reset, scale [75-150]; master/sfx/music [0-100|on|off|toggle]'
en.EFFECTS='Effects';en.AMBIENCE='Ambience';en.DIALOG='Dialogue';en.GROUP_PARTIAL='Group partly active'
de.EFFECTS='Effekte';de.AMBIENCE='Umgebung';de.DIALOG='Dialoge';de.GROUP_PARTIAL='Gruppe teilweise aktiv'
en.MASTER_HELP='Mutes all game audio and restores the previous channel selection. If every channel is off, enabling master activates both groups.'
de.MASTER_HELP='Schaltet den gesamten Spielton stumm und stellt die vorherige Kanalauswahl wieder her. Sind alle Kanäle aus, aktiviert Gesamt beide Gruppen.'
en.SFX_HELP='Groups effects, ambience and dialogue. The slider sets all three volumes to the displayed value. Muting preserves their individual levels. Voice chat stays separate.'
de.SFX_HELP='Bündelt Effekte, Umgebung und Dialoge. Der Regler setzt alle drei Lautstärken auf den angezeigten Wert. Stummschalten erhält die Einzelwerte. Voicechat bleibt separat.'
en.ACTIVATION_HELP='If master is off or at 0%, enabling a channel opens master for that group only. Enabling at 0% restores the last positive volume.'
de.ACTIVATION_HELP='Ist Gesamt aus oder auf 0 %, aktiviert Einschalten nur die gewählte Gruppe samt Gesamt. Einschalten bei 0 % stellt die letzte positive Lautstärke wieder her.'
en.AUDIO_BUSY='An audio change is already in progress.'
de.AUDIO_BUSY='Eine Audioänderung läuft bereits.'
en.AUDIO_RESTORE_ERROR='WoW rejected the change and could not restore all previous settings. Check the displayed audio values.'
de.AUDIO_RESTORE_ERROR='WoW hat die Änderung abgelehnt und konnte nicht alle vorherigen Einstellungen wiederherstellen. Prüfe die angezeigten Audiowerte.'
en.TIP_COMPACT='Click: on/off · Right-click: mixer'
de.TIP_COMPACT='Klick: an/aus · Rechtsklick: Mixer'
en.TIP_EXPANDED='Click: on/off';de.TIP_EXPANDED='Klick: an/aus'
en.TIP_SLIDER='Drag: volume';de.TIP_SLIDER='Ziehen: Lautstärke'
en.TIP_SFX='Effects, ambience and dialogue'
de.TIP_SFX='Effekte, Umgebung und Dialoge'
en.WHEEL_HELP='Wheel: 5% · Shift + wheel: 1%'
de.WHEEL_HELP='Mausrad: 5% · mit Umschalt: 1%'
en.AVOID_OVERLAP='Avoid overlap when placing'
de.AVOID_OVERLAP='Überlappung beim Ablegen vermeiden'
en.AVOID_HELP='On release or when expanding, find a free spot beside visible UI controls. Later-opening windows and inaccessible frames cannot be reserved.'
de.AVOID_HELP='Beim Loslassen oder Vergrößern einen freien Platz neben sichtbaren Bedienelementen suchen. Später geöffnete Fenster und nicht lesbare Bereiche lassen sich nicht freihalten.'
en.NO_FREE_SPACE='No free space found. Previous position restored.'
de.NO_FREE_SPACE='Kein freier Platz gefunden. Vorherige Position wiederhergestellt.'
en.PLACEMENT_UNAVAILABLE='Placement could not be checked completely. Previous position restored.'
de.PLACEMENT_UNAVAILABLE='Der Ablageplatz konnte nicht vollständig geprüft werden. Vorherige Position wiederhergestellt.'
A.L = setmetatable(GetLocale and GetLocale() == "deDE" and de or {}, { __index = en })
BINDING_HEADER_SOUNDSTONE = A.L.BIND_HEADER
BINDING_NAME_SOUNDSTONE_PANEL = A.L.BIND_PANEL
BINDING_NAME_SOUNDSTONE_MASTER = A.L.BIND_MASTER
BINDING_NAME_SOUNDSTONE_SFX = A.L.BIND_SFX
BINDING_NAME_SOUNDSTONE_MUSIC = A.L.BIND_MUSIC
