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
FILES = ['Locale.lua', 'Compat.lua', 'Assets.lua', 'Layout.lua', 'Theme.lua', 'Placement.lua', 'Audio.lua', 'Devices.lua', 'Dropdown.lua', 'UI.lua', 'Core.lua']
total = 0
# Unknown clients may lack C_CVar and the layout-cache frame methods.
LEGACY_API = 'C_CVar=nil; C_Texture=nil; PixelUtil=nil; Mock.legacyReturn=true; Mock.methods.SetUserPlaced=nil; Mock.methods.IsUserPlaced=nil; Mock.methods.SetDontSavePosition=nil; Mock.methods.GetDontSavePosition=nil; Mock.methods.GetUnboundedStringWidth=nil'
configs = [
    ('Retail', 1, 'deDE', False, True),
    ('Mists Classic', 19, 'enUS', False, True),
    ('TBC Anniversary', 5, 'deDE', False, True),
    ('Classic Era', 2, 'enUS', False, True),
    ('WoW Forever', 1, 'enUS', False, True),
    # The release client reports WOW_PROJECT_CAMELOT (18); the beta reported MAINLINE.
    ('WoW Forever release', 18, 'deDE', False, True),
    ('API fallback', 999, 'frFR', True, False),
]
for variant, project, locale, legacy, backdrop, native in [(*config, native) for config in configs for native in (False, True)]:
    print('\n--- ' + variant + (' / native menu' if native else ' / fallback menu') + ' ---', flush=True)
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
    if native:
        lua.execute((ROOT / 'tests/menu_mock.lua').read_text(encoding='utf-8'))
    lua.globals().print = lambda *items: print(*items, flush=True)
    lua.execute('SoundstoneDB={positions={bar={point="CENTER",x=145,y=-85}},showBar=true,showMinimap=true,locked=false,compartmentMigrated=true}')
    # Forever loads with its own look; test_theme.lua checks that look in detail.
    if variant.startswith('WoW Forever'):
        lua.execute('Mock.expectForever=true')
    lua.globals().WOW_PROJECT_ID = project
    lua.globals().Mock.locale = locale
    if project not in (1, 18):
        lua.execute('AddonCompartmentFrame=nil')
    if variant.startswith('WoW Forever'):
        lua.execute('Mock.interface=16001')
    if project == 18:
        lua.execute('WOW_PROJECT_CAMELOT=18')
    if legacy:
        lua.execute(LEGACY_API)
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
    total += lua.execute((ROOT / 'tests/test_placement.lua').read_text(encoding='utf-8'))
    total += lua.execute((ROOT / 'tests/test_compartment.lua').read_text(encoding='utf-8'))
    total += lua.execute((ROOT / 'tests/test_position.lua').read_text(encoding='utf-8'))
    total += lua.execute((ROOT / 'tests/test_theme.lua').read_text(encoding='utf-8'))
    forever = variant.startswith('WoW Forever')
    assert ns.Compat.IsForever() is forever
    assert ns.UI.theme == ('Retail' if project == 1 and not forever else 'Classic')
    total += 1
    reload_mode = 'expanded' if project % 2 else 'compact'
    ns.SetView(ns, reload_mode)
    ns.Command(ns, 'hide')
    lua.execute('SoundstoneDB.position={x=145,y=-85}; SoundstoneDB.showMinimap=false; SoundstoneDB.locked=true; SoundstoneDB.avoidOverlap=false')
    # A look choice saved by an unreleased 0.4.0 build is dropped: the look follows the client.
    lua.execute('SoundstoneDB.theme="soundstone"' if forever else 'SoundstoneDB.theme="forever"')
    saved = ns.db
    cvars = lua.globals().Mock.cvars
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
    if native:
        lua.execute((ROOT / 'tests/menu_mock.lua').read_text(encoding='utf-8'))
    lua.globals().SoundstoneDB = saved
    lua.globals().Mock.cvars = cvars
    lua.globals().WOW_PROJECT_ID = project
    lua.globals().Mock.locale = locale
    if project not in (1, 18):
        lua.execute('AddonCompartmentFrame=nil')
    if variant.startswith('WoW Forever'):
        lua.execute('Mock.interface=16001')
    if project == 18:
        lua.execute('WOW_PROJECT_CAMELOT=18')
    if legacy:
        lua.execute(LEGACY_API)
    if not backdrop:
        lua.execute('BackdropTemplateMixin=nil')
    # The client's art is there on reload: only Forever wears its window frame (and the bar its band);
    # elsewhere a saved look is ignored and nothing of Forever's look is built.
    lua.execute('Mock.atlases=Mock.foreverAtlases')
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
    assert reloaded.db.theme is None
    assert reloaded.UI.themeName == ('forever' if forever else 'soundstone')
    framed = forever and not legacy
    assert (reloaded.UI.windowsBuilt is True) is framed
    assert (reloaded.UI.bar.window is not None) is framed
    assert reloaded.audio.Get(reloaded.audio, 'music').percent == 30
    reloaded.Command(reloaded, '')
    assert reloaded.db.viewMode == reload_mode
    assert reloaded.UI.root.IsShown(reloaded.UI.root) is True
    assert reloaded.UI.minimap.IsShown(reloaded.UI.minimap) is False
    assert reloaded.db.position.x == 145
    assert len(lua.globals().Mock.writes) == 0
    total += 1
    print('PASS reload preserves settings and channel state without CVar writes', flush=True)

# The Addons menu replaces the minimap button once; a later opt-in survives reloads.
for has_menu in (True, False):
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
    if not has_menu:
        lua.execute('AddonCompartmentFrame=nil')
    lua.execute('SoundstoneDB={showMinimap=true,minimapAngle=90}')
    for step in range(2):
        ns = lua.table()
        for name in FILES:
            load((ROOT / 'Soundstone' / name).read_text(encoding='utf-8'), '@'+name, ns)
        ns.Initialize(ns)
        assert ns.db.showMinimap is (not has_menu or step == 1)
        assert ns.UI.minimap.IsShown(ns.UI.minimap) is ns.db.showMinimap
        assert (ns.UI.compartment is True) is has_menu
        assert ns.db.minimapAngle == 90
        if has_menu and step == 0:
            ns.Command(ns, 'minimap')
            lua.execute('Mock.compartment={}')
    total += 1
print('PASS Addons menu migration hides the minimap button once and keeps later opt-in', flush=True)

# A damaged SavedVariables file must not prevent the UI from loading.
lua.execute('SoundstoneDB={showBar="bad",positions={bar={point="INVALID",x="bad"}},minimapAngle=0/0,theme="bogus"}')
ns = lua.table()
for name in FILES:
    load((ROOT / 'Soundstone' / name).read_text(encoding='utf-8'), '@'+name, ns)
ns.Initialize(ns)
assert ns.db.showBar is True
assert ns.db.minimapAngle == 225
assert ns.db.positions is None
assert ns.db.schema == 2
assert ns.db.theme is None
total += 1
print('PASS corrupted SavedVariables recover to valid defaults', flush=True)
print(f'\nPASS: {total} scenario checks across 7 simulated API/client configurations, each with native and fallback menus.', flush=True)
