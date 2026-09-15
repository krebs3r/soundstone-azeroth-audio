local _, A = ...
-- One concise card per version. CHANGELOG.md retains the full history.
local en={
    {version='0.3.0',text='• Compact layouts and direct header controls.\n• Device dropdown and shorter tooltips.\n• Enable music/effects separately; restore volume at 0%.\n• Attached options and optional free placement.\n• One changelog card per version.'},
    {version='0.2.0',text='• Custom Retail and Classic designs.\n• Compact bar and expanded audio mixer.\n• Shared position for both views.\n• Additional size setting from 75–150%.\n• Output-device selection and saved layout.'},
}
local de={
    {version='0.3.0',text='• Kompakte Ansichten und direkte Titelbuttons.\n• Geräte-Dropdown und kurze Hilfetexte.\n• Musik/Effekte gezielt einschalten; Lautstärke bei 0 % wiederherstellen.\n• Optionen andocken; freies Ablegen wählen.\n• Eine Changelog-Kachel je Version.'},
    {version='0.2.0',text='• Eigene Designs für Retail und Classic.\n• Kompaktleiste und große Audioansicht.\n• Gemeinsame Position beider Ansichten.\n• Zusätzliche Größe von 75–150 %.\n• Geräteauswahl und gespeichertes Layout.'},
}
A.ReleaseNotes=GetLocale and GetLocale()=='deDE' and de or en
