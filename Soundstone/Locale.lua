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

A.L = setmetatable(GetLocale and GetLocale() == "deDE" and de or {}, { __index = en })
BINDING_HEADER_SOUNDSTONE = A.L.BIND_HEADER
BINDING_NAME_SOUNDSTONE_PANEL = A.L.BIND_PANEL
BINDING_NAME_SOUNDSTONE_MASTER = A.L.BIND_MASTER
BINDING_NAME_SOUNDSTONE_SFX = A.L.BIND_SFX
BINDING_NAME_SOUNDSTONE_MUSIC = A.L.BIND_MUSIC
