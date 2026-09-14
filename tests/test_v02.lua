local A=Soundstone
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a)..' !~= '..tostring(b)) end
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
test('exactly one view and shared anchor across mode switches',function()
    A:SetView('compact');local p=A.db.position
    eq(A.UI.bar:IsShown(),true);eq(A.UI.panel:IsShown(),false)
    A:Command('expand');eq(A.UI.bar:IsShown(),false);eq(A.UI.panel:IsShown(),true)
    eq(A.db.position,p);A.UI.close:Fire('OnClick');eq(A.db.viewMode,'compact')
end)
test('Escape closes one layer and then returns to compact view',function()
    A:SetView('expanded');A.UI:ToggleMenu();A.UI.deviceButton:Fire('OnClick')
    A.UI.escape:Hide();eq(A.UI.deviceMenu:IsShown(),false);eq(A.UI.menu:IsShown(),true)
    A.UI.escape:Hide();eq(A.UI.menu:IsShown(),false);eq(A.db.viewMode,'expanded')
    A.UI.escape:Hide();eq(A.db.viewMode,'compact')
end)
test('six grip dots and unstretched icon dimensions',function()
    eq(#A.UI.gripDots,6)
    for _,id in ipairs({'master','sfx','music'}) do
        local names={master='Master',sfx='Sfx',music='Music'}
        local t=A.UI.barControls[id].icon.texture;local asset=A.Assets[names[id]]
        near(t.width/t.height,asset.width/asset.height)
        assert(t.width<=24 and t.height<=24)
    end
end)
test('dragging does not click menu and position survives scaling',function()
    A.db.locked=false;A:SetView('compact');A.UI.grip:Fire('OnDragStart');eq(A.UI.dragging,true)
    A.UI.grip:Fire('OnDragStop');local x,y=A.db.position.x,A.db.position.y
    A.UI.grip:Fire('OnClick');eq(A.UI.menu:IsShown(),false)
    A:SetScale(1.25);near(A.db.position.x,x);near(A.db.position.y,y)
    Mock.time=Mock.time+1;A.UI.grip:Fire('OnClick');eq(A.UI.menu:IsShown(),true);A.UI:CloseMenus()
end)
test('1080p and 1440p scale matrix clamps and preserves inherited scaling',function()
    for _,resolution in ipairs({{1920,1080},{2560,1440}}) do
        Mock.physicalWidth,Mock.physicalHeight=resolution[1],resolution[2]
        for _,wowScale in ipairs({.65,.85,1}) do
            UIParent:SetScale(wowScale)
            local factor=768/resolution[2]
            UIParent:SetSize(resolution[1]*factor/wowScale,768/wowScale)
            for _,s in ipairs({.75,1,1.5}) do for _,mode in ipairs({'compact','expanded'}) do
                A.db.position={x=10000,y=-10000};A:SetView(mode);A:SetScale(s)
                near(A.UI.root:GetEffectiveScale(),wowScale*s)
                near(A.UI.menu:GetEffectiveScale(),wowScale*s)
                near(A.UI.minimap:GetEffectiveScale(),wowScale)
                local w,h=UIParent:GetWidth(),UIParent:GetHeight()
                assert(A.UI.anchorX+300*s<=w/2+.01)
                assert(A.UI.anchorY-A.UI.root.height*s>=-h/2-.01)
                local pixel=A.Compat.Pixel(1.1,A.UI.root)*A.UI.root:GetEffectiveScale()/factor
                near(pixel,math.floor(pixel+.5))
            end end
        end
    end
    UIParent:SetScale(1);UIParent:SetSize(1920,1080);Mock.physicalWidth,Mock.physicalHeight=1920,1080
    A:SetScale(1);A:ResetPositions();A:SetView('compact')
end)
test('invalid scale and hidden interface retain valid state',function()
    A:SetScale(99);eq(A.db.uiScale,1.5);A:SetScale(.1);eq(A.db.uiScale,.75);A:SetScale(0/0);eq(A.db.uiScale,1)
    A:Command('bar');eq(A.UI.root:IsShown(),false);eq(A.UI.bar:IsShown(),false)
    A:Command('compact');eq(A.UI.root:IsShown(),true);eq(A.UI.bar:IsShown(),true)
end)
test('device selection writes only output index and restarts exactly once',function()
    local before=#Mock.writes;local restarts=Mock.restarts
    eq(A.devices:Select(2,'Headset'),true);eq(Mock.restarts,restarts+1)
    eq(#Mock.writes,before+1);eq(Mock.writes[#Mock.writes][1],'Sound_OutputDriverIndex')
    eq(A.devices:Get().selected.name,'Headset')
    eq(A.devices:Select(2,'Headset'),true);eq(Mock.restarts,restarts+1);eq(#Mock.writes,before+1)
end)
test('missing, reordered and unplugged devices never select a stale index',function()
    local before=#Mock.writes
    Mock.devices={'System Default','Headset','Speakers'}
    eq(A.devices:Select(2,'Headset'),false);eq(#Mock.writes,before)
    Mock.devices={'System Default'};A.events:Fire('OnEvent','SOUND_DEVICE_UPDATE')
    eq(A.UI.deviceState.selected,nil);eq(A.devices:Select(2,'Headset'),false)
    Mock.devices={'System Default','Speakers','Headset'}
end)
test('device errors and unavailable APIs fail without fake success',function()
    local before=Mock.restarts
    Mock.rejectWrite=true;eq(A.devices:Select(0,'System Default'),false);Mock.rejectWrite=false
    Mock.ignoreWrite=true;eq(A.devices:Select(0,'System Default'),false);Mock.ignoreWrite=false
    eq(Mock.restarts,before)
    local restart=Sound_GameSystem_RestartSoundSystem;Sound_GameSystem_RestartSoundSystem=nil
    eq(A.devices:Select(0,'System Default'),false);Sound_GameSystem_RestartSoundSystem=restart
    Mock.deviceError=true;eq(A.devices:Get().available,false);Mock.deviceError=false
    local get=Sound_GameSystem_GetNumOutputDrivers;Sound_GameSystem_GetNumOutputDrivers=nil
    eq(A.devices:Get().available,false);Sound_GameSystem_GetNumOutputDrivers=get
    Mock.restartError=true;eq(A.devices:Select(0,'System Default'),false);Mock.restartError=false
    Sound_GameSystem_RestartSoundSystem=function() Mock.cvars.Sound_OutputDriverIndex='0' end
    eq(A.devices:Select(1,'Speakers'),false)
    Sound_GameSystem_RestartSoundSystem=restart
end)
test('external output updates and scrolling refresh without writes',function()
    local before=#Mock.writes
    Mock.devices={'System Default','Speakers','Headset','USB 1','USB 2','USB 3','USB 4','USB 5'}
    Mock.cvars.Sound_OutputDriverIndex='1';A.events:Fire('OnEvent','CVAR_UPDATE','Sound_OutputDriverIndex')
    eq(A.UI.deviceState.selected.name,'Speakers');eq(#Mock.writes,before)
    A.UI.deviceMenu:Fire('OnMouseWheel',-1);eq(A.UI.deviceOffset,1)
    eq(A.UI.deviceRows[6].item.name,'USB 4')
    Mock.devices={'System Default','Speakers','Headset'};A.UI:RefreshDevices();eq(A.UI.deviceOffset,0)
end)
test('legacy positions migrate using the original bar anchor',function()
    local pos=A.Layout.LegacyPosition({point='CENTER',x=145,y=-85},1920,1080)
    eq(pos.x,-23);eq(pos.y,-62)
    pos=A.Layout.LegacyPosition({point='TOPLEFT',x=10,y=-20},1920,1080)
    eq(pos.x,-950);eq(pos.y,520)
end)
return count
