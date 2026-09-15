"""Execute the real addon modules in Lua 5.1 with a bounded WoW API test double.

Requires lupa>=2.8. No WoW installation, account, or audio-device access is used.
This does not replace an in-game smoke test.
"""
import os
from pathlib import Path
import sys

if os.environ.get('SOUNDSTONE_TEST_DEPS'):
    sys.path.insert(0, os.environ['SOUNDSTONE_TEST_DEPS'])
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FILES = ['Locale.lua', 'Compat.lua', 'Assets.lua', 'Layout.lua', 'Placement.lua', 'ReleaseNotes.lua', 'Audio.lua', 'Devices.lua', 'Dropdown.lua', 'UI.lua', 'Core.lua']
total = 0
configs = [
    ('Retail', 1, 'deDE', False, True),
    ('Mists Classic', 19, 'enUS', False, True),
    ('TBC Anniversary', 5, 'deDE', False, True),
    ('Classic Era', 2, 'enUS', False, True),
    ('API fallback', 999, 'frFR', True, False),
]
for variant, project, locale, legacy, backdrop, native in [(*config, native) for config in configs for native in (False, True)]:
    print('\n--- ' + variant + (' / native menu' if native else ' / fallback menu') + ' ---', flush=True)
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
    if native:
        lua.execute((ROOT / 'tests/menu_mock.lua').read_text(encoding='utf-8'))
    lua.globals().print = lambda *items: print(*items, flush=True)
    lua.execute('SoundstoneDB={positions={bar={point="CENTER",x=145,y=-85}},showBar=true,showMinimap=true,locked=false}')
    lua.globals().WOW_PROJECT_ID = project
    lua.globals().Mock.locale = locale
    if legacy:
        lua.execute('C_CVar=nil; Mock.legacyReturn=true')
    if not backdrop:
        lua.execute('BackdropTemplateMixin=nil')
    ns = lua.table()
    load = lua.eval('function(code,name,ns) local f,e=loadstring(code,name); assert(f,e); return f("Soundstone",ns) end')
    for name in FILES:
        load((ROOT / 'Soundstone' / name).read_text(encoding='utf-8'), '@'+name, ns)
    total += lua.execute((ROOT / 'tests/test_soundstone.lua').read_text(encoding='utf-8'))
    assert ns.L.MASTER == ('Gesamt' if locale == 'deDE' else 'Master')
    # Reload into an independent namespace and fresh frames, keeping saved data/CVars.
    total += lua.execute((ROOT / 'tests/test_v02.lua').read_text(encoding='utf-8'))
    total += lua.execute((ROOT / 'tests/test_compact.lua').read_text(encoding='utf-8'))
    total += lua.execute((ROOT / 'tests/test_dropdown.lua').read_text(encoding='utf-8'))
    total += lua.execute((ROOT / 'tests/test_audio_logic.lua').read_text(encoding='utf-8'))
    total += lua.execute((ROOT / 'tests/test_ui03.lua').read_text(encoding='utf-8-sig'))
    total += lua.execute((ROOT / 'tests/test_followups.lua').read_text(encoding='utf-8'))
    reload_mode = 'expanded' if project % 2 else 'compact'
    ns.SetView(ns, reload_mode)
    ns.Command(ns, 'hide')
    lua.execute('SoundstoneDB.position={x=145,y=-85}; SoundstoneDB.showMinimap=false; SoundstoneDB.locked=true; SoundstoneDB.avoidOverlap=false')
    saved = ns.db
    cvars = lua.globals().Mock.cvars
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
    if native:
        lua.execute((ROOT / 'tests/menu_mock.lua').read_text(encoding='utf-8'))
    lua.globals().SoundstoneDB = saved
    lua.globals().Mock.cvars = cvars
    lua.globals().WOW_PROJECT_ID = project
    lua.globals().Mock.locale = locale
    if legacy:
        lua.execute('C_CVar=nil; Mock.legacyReturn=true')
    if not backdrop:
        lua.execute('BackdropTemplateMixin=nil')
    reloaded = lua.table()
    for name in FILES:
        load((ROOT / 'Soundstone' / name).read_text(encoding='utf-8'), '@'+name, reloaded)
    reloaded.Initialize(reloaded)
    assert len(lua.globals().Mock.writes) == 0
    assert reloaded.db.position.x == 145
    assert reloaded.db.locked is True
    assert reloaded.db.avoidOverlap is False
    assert reloaded.UI.bar.IsShown(reloaded.UI.bar) is False
    assert reloaded.UI.root.IsShown(reloaded.UI.root) is False
    assert reloaded.UI.minimap.IsShown(reloaded.UI.minimap) is False
    assert reloaded.db.viewMode == reload_mode
    assert reloaded.audio.Get(reloaded.audio, 'music').percent == 30
    reloaded.Command(reloaded, '')
    assert reloaded.db.viewMode == reload_mode
    assert reloaded.UI.root.IsShown(reloaded.UI.root) is True
    assert reloaded.UI.minimap.IsShown(reloaded.UI.minimap) is False
    assert reloaded.db.position.x == 145
    assert len(lua.globals().Mock.writes) == 0
    total += 1
    print('PASS reload preserves settings and channel state without CVar writes', flush=True)

# A damaged SavedVariables file must not prevent the UI from loading.
lua.execute('SoundstoneDB={showBar="bad",positions={bar={point="INVALID",x="bad"}},minimapAngle=0/0}')
ns = lua.table()
for name in FILES:
    load((ROOT / 'Soundstone' / name).read_text(encoding='utf-8'), '@'+name, ns)
ns.Initialize(ns)
assert ns.db.showBar is True
assert ns.db.minimapAngle == 225
assert ns.db.positions is None
assert ns.db.schema == 2
total += 1
print('PASS corrupted SavedVariables recover to valid defaults', flush=True)
print(f'\nPASS: {total} scenario checks across 5 simulated API/client configurations, each with native and fallback menus.', flush=True)
