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
FILES = ['Locale.lua', 'Compat.lua', 'Audio.lua', 'UI.lua', 'Core.lua']
total = 0
for variant, project, locale, legacy, backdrop in [
    ('Retail', 1, 'deDE', False, True),
    ('Mists Classic', 19, 'enUS', False, True),
    ('TBC Anniversary', 5, 'deDE', False, True),
    ('Classic Era', 2, 'enUS', False, True),
    ('API fallback', 999, 'frFR', True, False),
]:
    print('\n--- ' + variant + ' ---', flush=True)
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
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
    lua.execute('SoundstoneDB.positions.bar={point="CENTER",x=145,y=-85}; SoundstoneDB.showBar=false; SoundstoneDB.locked=true')
    saved = ns.db
    cvars = lua.globals().Mock.cvars
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
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
    assert reloaded.db.positions.bar.x == 145
    assert reloaded.db.locked is True
    assert reloaded.UI.bar.IsShown(reloaded.UI.bar) is False
    assert reloaded.audio.Get(reloaded.audio, 'music').percent == 30
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
assert ns.db.positions.bar is None
total += 1
print('PASS corrupted SavedVariables recover to valid defaults', flush=True)
print(f'\nPASS: {total} scenario checks across 5 simulated API/client configurations.', flush=True)
