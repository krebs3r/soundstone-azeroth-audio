-- Reported: the bar moved after login/reload, snapped back on click and jumped while dragged.
local A=Soundstone
local count=0
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b,t) assert(math.abs(a-b)<(t or .0001),tostring(a)..' !~= '..tostring(b)) end
-- Top-left of the root in UIParent units relative to UIParent's centre, as SoundstoneDB stores it.
local function topLeft()
    local root=A.UI.root;local s=root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local cx,cy=UIParent:GetCenter()
    return root:GetLeft()*s-cx,root:GetTop()*s-cy
end
local function move(x,y)
    local scale=A.UI.root.scale or 1
    A.UI.root:ClearAllPoints();A.UI.root:SetPoint('TOPLEFT',UIParent,'CENTER',x/scale,y/scale)
end
-- One client frame: only visible frames run OnUpdate.
local function frame() if A.UI.watch:IsVisible() then A.UI.watch:Fire('OnUpdate',1/60) end end
-- In the client UIParent fills the screen, so its scale sets its size in UI units, without
-- OnSizeChanged here. The client applies the uiScale CVar itself; addons call SetScale.
local function screen(scale,width,height) UIParent.width,UIParent.height=width/scale,height/scale end
local function engineScale(scale,width,height) screen(scale,width,height);UIParent.scale=scale end
local function addonScale(scale,width,height) screen(scale,width,height);UIParent:SetScale(scale) end
local function counted(root)
    local calls={n=0}
    root.SetPoint=function(self,...) calls.n=calls.n+1;return Mock.methods.SetPoint(self,...) end
    return calls
end
local cvars={};for k,v in pairs(Mock.cvars) do cvars[k]=v end
local saved={position=A.db.position,locked=A.db.locked,avoidOverlap=A.db.avoidOverlap,uiScale=A.db.uiScale,viewMode=A.db.viewMode}
A:SetVisible(true);A.UI:CloseMenus();A:SetView('compact');A:SetScale(1);A.db.locked=false;A.db.avoidOverlap=false

test('a drag starts where the bar is shown and refreshes cannot pull it back until release',function()
    A.db.position={x=-300,y=-200};A.UI:ApplyLayout()
    -- Something outside Soundstone re-anchored the bar to another spot.
    A.UI.root:ClearAllPoints();A.UI.root:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',500,300)
    local shown=A.UI.root.points[1]
    Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart')
    eq(A.UI.dragging,true);eq(A.UI.root.moving,true);eq(A.UI.root.points[1],shown)
    move(120,80);local moved=A.UI.root.points[1]
    A.events:Fire('OnEvent','CVAR_UPDATE','Sound_EnableSFX','0')
    A:Toggle('music');A:Toggle('music')
    A.events:Fire('OnEvent','CVAR_UPDATE','uiScale','0.8')
    for _,event in ipairs({'UI_SCALE_CHANGED','DISPLAY_SIZE_CHANGED','VARIABLES_LOADED','LOADING_SCREEN_DISABLED'}) do
        A.events:Fire('OnEvent',event)
    end
    UIParent:SetSize(1366,768);A.UI:Refresh();A:SetScale(1.25)
    eq(#A.UI.root.points,1);eq(A.UI.root.points[1],moved)
    A.UI.root:Fire('OnUpdate',1/60);eq(A.UI.dragging,true)
    Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop')
    eq(A.UI.dragging,false);eq(A.UI.root.moving,false)
    near(A.db.position.x,120);near(A.db.position.y,80);UIParent:SetSize(1920,1080)
    -- The scale change made during the drag applies around the dropped position.
    eq(A.UI.root.scale,1.25);local x,y=topLeft();near(x,120,1);near(y,80,1)
    A:SetScale(1)
end)

test('the client layout cache never stores a second Soundstone position',function()
    local root=A.UI.root
    if Mock.methods.GetDontSavePosition then eq(root:GetDontSavePosition(),true) end
    for _,handle in ipairs({A.UI.grip,A.UI.panelHeader,A.UI.panelGrip}) do
        A:SetView(handle==A.UI.grip and 'compact' or 'expanded')
        Mock.leftMouseDown=true;handle:Fire('OnDragStart')
        -- Precondition: like the client, the mock marks a moved frame user-placed.
        if Mock.methods.IsUserPlaced then eq(root:IsUserPlaced(),true) end
        move(10,20);Mock.leftMouseDown=false;handle:Fire('OnDragStop')
        if Mock.methods.IsUserPlaced then eq(root:IsUserPlaced(),false) end
    end
    -- A failing SetUserPlaced must not leave the drag active.
    root.SetUserPlaced=function() error('restricted') end
    Mock.leftMouseDown=true;A.UI.panelHeader:Fire('OnDragStart');Mock.leftMouseDown=false;A.UI.panelHeader:Fire('OnDragStop')
    eq(A.UI.dragging,false);eq(root.moving,false);root.SetUserPlaced=nil
    A.db.locked=true;local shown=root.points[1]
    A.UI.panelHeader:Fire('OnDragStart');eq(A.UI.dragging,false);eq(root.moving,false)
    A.UI.panelHeader:Fire('OnDragStop');eq(root.points[1],shown)
    A.db.locked=false;A:SetView('compact')
end)

test('a late re-anchor while loading is replaced by the saved position',function()
    eq(A.events.events.VARIABLES_LOADED,true);eq(A.events.events.LOADING_SCREEN_DISABLED,true)
    for _,scale in ipairs({.75,1,1.5}) do
        A:SetScale(scale);A.db.position={x=-200,y=-100};A.UI:ApplyLayout()
        for _,event in ipairs({'PLAYER_ENTERING_WORLD','VARIABLES_LOADED','LOADING_SCREEN_DISABLED'}) do
            A.UI.root:ClearAllPoints();A.UI.root:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-10,10)
            A.events:Fire('OnEvent',event)
            local x,y=topLeft();near(x,-200,1);near(y,-100,1)
        end
    end
    -- Other addons loading later (e.g. Blizzard load-on-demand panels) do not re-layout.
    local root=A.UI.root;local calls=0
    root.SetPoint=function(self,...) calls=calls+1;return Mock.methods.SetPoint(self,...) end
    A.events:Fire('OnEvent','ADDON_LOADED','Blizzard_TimeManager');A.events:Fire('OnEvent','ADDON_LOADED','Soundstone')
    root.SetPoint=nil;eq(calls,0)
    A:SetScale(1)
end)

test('resizing UIParent without a scale event re-clamps from the saved position',function()
    A:SetView('compact');A.db.position={x=-900,y=-480};A.UI:ApplyLayout()
    local x,y=topLeft();near(x,-900,1);near(y,-480,1)
    UIParent:SetSize(1366,768);frame()
    x,y=topLeft();near(x,-683,1);near(y,-384+36,1)
    UIParent:SetSize(1920,1080);frame()
    x,y=topLeft();near(x,-900,1);near(y,-480,1);eq(A.db.position.x,-900);eq(A.db.position.y,-480)
end)

test('audio changes update values without moving the window',function()
    A.db.position={x=-150,y=-250};A.UI:ApplyLayout()
    local root=A.UI.root;local calls=0
    root.SetPoint=function(self,...) calls=calls+1;return Mock.methods.SetPoint(self,...) end
    A:Toggle('sfx');A:Toggle('sfx');A:Step('master',-1);A:Step('master',1)
    A.UI.barControls.music:Fire('OnMouseWheel',-1);A.UI.barControls.music:Fire('OnMouseWheel',1)
    Mock.cvars.Sound_MusicVolume='0.4';A.events:Fire('OnEvent','CVAR_UPDATE','Sound_MusicVolume','0.4')
    root.SetPoint=nil
    eq(calls,0);eq(A.UI.barControls.music.value.textValue,'40 %');eq(A.UI.rows.music.value.textValue,'40 %')
    local x,y=topLeft();near(x,-150,1);near(y,-250,1)
end)

test('regrabbing a bar during its overlap check keeps it under the cursor',function()
    local old=A.Placement.Collect
    A.Placement.Collect=function(_,checkpoint) for i=1,1000 do checkpoint() end;return {} end
    A.db.avoidOverlap=true;A.db.position={x=-50,y=-60};A.UI:ApplyLayout()
    Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(100,200);Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop')
    assert(A.UI.placementJob);local shown=A.UI.root.points[1]
    Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart')
    -- Until release the save keeps the verified spot, while the bar stays under the cursor.
    eq(A.UI.placementJob,nil);eq(A.UI.root.points[1],shown);near(A.db.position.x,-50);near(A.db.position.y,-60)
    -- Without room for the second drop, the last verified position returns, not the unchecked first drop.
    A.Placement.Collect=function() return {{left=0,right=1920,bottom=0,top=1080}} end
    move(300,400);Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop');Mock.finishPlacement()
    near(A.db.position.x,-50);near(A.db.position.y,-60)
    local x,y=topLeft();near(x,-50,1);near(y,-60,1)
    A.Placement.Collect=old;A.db.avoidOverlap=false
end)

test('closing the options at drag start leaves a temporarily shifted window under the cursor',function()
    UIParent:SetSize(1366,768);A:SetScale(1.5);A:SetView('expanded')
    A.db.position={x=-150,y=150};A.UI:ApplyLayout();A.UI:ToggleMenu();eq(A.UI.menu:IsShown(),true)
    local _,shifted=topLeft();assert(math.abs(shifted-150)>1,'Options did not shift the window')
    local shown=A.UI.root.points[1]
    Mock.leftMouseDown=true;A.UI.panelHeader:Fire('OnDragStart')
    eq(A.UI.menu:IsShown(),false);eq(A.UI.root.points[1],shown)
    Mock.leftMouseDown=false;A.UI.panelHeader:Fire('OnDragStop')
    local x,y=topLeft();near(A.db.position.y,shifted,1);near(y,shifted,1);near(x,-150,1)
    UIParent:SetSize(1920,1080);A:SetScale(1);A:SetView('compact')
end)

test('switching views or releasing outside the game window ends a drag',function()
    A:SetView('compact');A.db.position={x=0,y=0};A.UI:ApplyLayout()
    Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(40,-30)
    A:SetView('expanded') -- e.g. the Soundstone key binding while the button is held
    eq(A.UI.dragging,false);eq(A.UI.root.moving,false);eq(A.UI.root:GetScript('OnUpdate'),nil)
    near(A.db.position.x,40);near(A.db.position.y,-30);eq(A.UI.root.width,300);eq(A.UI.panel:IsShown(),true)
    A.UI.panelHeader:Fire('OnDragStart');eq(A.UI.dragging,true);move(-60,90)
    A.UI.root:Fire('OnUpdate',1/60);eq(A.UI.dragging,true)
    Mock.leftMouseDown=false;A.UI.root:Fire('OnUpdate',1/60)
    eq(A.UI.dragging,false);eq(A.UI.root.moving,false);eq(A.UI.root:GetScript('OnUpdate'),nil)
    near(A.db.position.x,-60);near(A.db.position.y,90)
    A.UI.panelHeader:Fire('OnDragStop');eq(A.UI.dragging,false);near(A.db.position.x,-60)
    -- A second OnDragStart without a release in between restarts cleanly.
    Mock.leftMouseDown=true;A.UI.panelHeader:Fire('OnDragStart');move(5,6);A.UI.panelHeader:Fire('OnDragStart')
    eq(A.UI.dragging,true);near(A.db.position.x,5);move(7,8);Mock.leftMouseDown=false;A.UI.panelHeader:Fire('OnDragStop')
    near(A.db.position.x,7);near(A.db.position.y,8)
    A:SetView('compact')
end)

test('view switches during a drag after a regrab keep the verified fallback',function()
    local old=A.Placement.Collect
    local slow=function(_,checkpoint) for i=1,1000 do checkpoint() end;return {} end
    local blocked=function() return {{left=0,right=1920,bottom=0,top=1080}} end
    A.db.avoidOverlap=true;A:SetView('compact');A.db.position={x=-50,y=-60};A.UI:ApplyLayout()
    for _,toggle in ipairs({function() A:TogglePanel() end,function() A:Command('expand') end}) do
        A.Placement.Collect=slow
        Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(100,200);Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop')
        assert(A.UI.placementJob)
        Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(300,400)
        A.Placement.Collect=blocked;toggle() -- key binding or slash command while the button is held
        eq(A.UI.dragging,false);Mock.leftMouseDown=false;Mock.finishPlacement()
        eq(A.db.viewMode,'compact');near(A.db.position.x,-50);near(A.db.position.y,-60)
        local x,y=topLeft();near(x,-50,1);near(y,-60,1)
    end
    -- Regrabbing the panel during its expansion check keeps the compact fallback.
    A.Placement.Collect=slow;A:SetView('expanded');assert(A.UI.placementJob)
    Mock.leftMouseDown=true;A.UI.panelHeader:Fire('OnDragStart');eq(A.db.viewMode,'expanded');move(10,20)
    A.Placement.Collect=blocked;Mock.leftMouseDown=false;A.UI.panelHeader:Fire('OnDragStop');Mock.finishPlacement()
    eq(A.db.viewMode,'compact');near(A.db.position.x,-50);near(A.db.position.y,-60);eq(A.UI.root.width,276)
    A.Placement.Collect=old;A.db.avoidOverlap=false
end)

test('Escape or hiding Soundstone during a drag keeps the drop',function()
    local old=A.Placement.Collect;A.Placement.Collect=function() return {} end
    A.db.avoidOverlap=true;A:SetView('expanded');Mock.finishPlacement();A.db.position={x=0,y=0};A.UI:ApplyLayout()
    Mock.leftMouseDown=true;A.UI.panelHeader:Fire('OnDragStart');move(40,-30)
    Mock.pressEscape()
    eq(A.db.viewMode,'compact');eq(A.UI.dragging,false);eq(A.UI.root.moving,false);eq(A.UI.root.width,276)
    Mock.finishPlacement();near(A.db.position.x,40);near(A.db.position.y,-30)
    A.UI.grip:Fire('OnDragStart');move(-70,25);A:SetVisible(false)
    eq(A.UI.dragging,false);eq(A.UI.placementJob,nil);near(A.db.position.x,-70);near(A.db.position.y,25)
    A:SetVisible(true);local x,y=topLeft();near(x,-70,1);near(y,25,1)
    Mock.leftMouseDown=false;A.Placement.Collect=old;A.db.avoidOverlap=false
end)

test('hiding the whole interface keeps the shown and saved positions together',function()
    local old=A.Placement.Collect
    A.Placement.Collect=function(_,checkpoint) for i=1,1000 do checkpoint() end;return {} end
    A.db.avoidOverlap=true;A:SetView('compact');A.db.position={x=-50,y=-60};A.UI:ApplyLayout()
    local function hideUI(childFirst)
        UIParent.shown=false
        if childFirst then A.UI.bar:Fire('OnHide') end
        A.UI.root:Fire('OnHide')
        if not childFirst then A.UI.bar:Fire('OnHide') end
    end
    local function showUI() UIParent.shown=true;A.UI.root:Fire('OnShow') end
    for _,childFirst in ipairs({true,false}) do
        -- Alt+Z during a drag: the drop is kept, and no check starts while hidden.
        Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(200,100);hideUI(childFirst)
        eq(A.UI.dragging,false);eq(A.UI.placementJob,nil);near(A.db.position.x,200);near(A.db.position.y,100)
        Mock.time=Mock.time+5;showUI();Mock.leftMouseDown=false
        local x,y=topLeft();near(x,200,1);near(y,100,1)
        -- Alt+Z during the check of a fresh drop: the unchecked drop is dropped, on screen too.
        Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(-120,40);Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop')
        assert(A.UI.placementJob);hideUI(childFirst);showUI()
        eq(A.UI.placementJob,nil);near(A.db.position.x,200);near(A.db.position.y,100)
        x,y=topLeft();near(x,200,1);near(y,100,1)
    end
    A.Placement.Collect=old;A.db.avoidOverlap=false
end)

-- Reported for 0.3.6 with PixelPerfectUIScale at 1440p: displaced after every login, back on
-- the next click. After login it calls UIParent:SetScale(768/1440); its retries first write the
-- uiScale CVar, and the client fires CVAR_UPDATE and UI_SCALE_CHANGED inside it at 0.64.
test('a pixel-perfect UIParent scale keeps the saved position',function()
    Mock.physicalWidth,Mock.physicalHeight=2560,1440
    local sw,sh,perfect=2560*768/1440,768,768/1440
    addonScale(perfect,sw,sh);frame();A:SetView('compact');A:SetScale(.87)
    local corner={x=1280-276*.87,y=720};A.db.position=corner;A.UI:ApplyLayout()
    -- The anchor from the report: the corner clamped against UIParent at 0.64.
    engineScale(.64,sw,sh);A.UI:ApplyLayout()
    near(A.UI.root.points[1][4],950.19159,.001);near(A.UI.root.points[1][5],689.65515,.001)
    addonScale(perfect,sw,sh);frame()
    local x,y=topLeft();near(x,corner.x,1);near(y,corner.y,1);eq(A.UI.watch:GetScript('OnUpdate'),nil)
    for _=1,8 do
        engineScale(.64,sw,sh)
        A.events:Fire('OnEvent','CVAR_UPDATE','uiScale',tostring(perfect));A.events:Fire('OnEvent','UI_SCALE_CHANGED')
        addonScale(perfect,sw,sh)
        x,y=topLeft();near(x,corner.x,1);near(y,corner.y,1)
        frame();x,y=topLeft();near(x,corner.x,1);near(y,corner.y,1)
    end
    eq(A.db.position,corner)
    -- Options and the channel toggles no longer move the bar.
    for _,click in ipairs({function() A.UI.barSettings:Fire('OnClick') end,function() A.UI:CloseMenus() end,
        function() A.UI.barControls.music:Fire('OnClick','LeftButton') end,function() A.UI.barControls.music:Fire('OnClick','LeftButton') end}) do
        click();x,y=topLeft();near(x,corner.x,1);near(y,corner.y,1)
    end
    -- A right-click expands in place; only the wider panel keeps to the screen edge.
    A.UI.barControls.sfx:Fire('OnClick','RightButton');x,y=topLeft();near(x,1280-300*.87,1);near(y,corner.y,1)
    A:SetView('compact');x,y=topLeft();near(x,corner.x,1);near(y,corner.y,1)
    UIParent.scale=nil;UIParent:SetSize(1920,1080);Mock.physicalWidth,Mock.physicalHeight=1920,1080;A:SetScale(1);frame()
end)

test('UIParent:SetScale and resizes lay out once on the next frame; idle frames do nothing',function()
    A:SetView('compact');A.db.position={x=-900,y=-480};A.UI:ApplyLayout()
    local calls=counted(A.UI.root)
    eq(A.UI.watch:GetScript('OnUpdate'),nil);frame();eq(calls.n,0)
    addonScale(1.25,1920,1080);eq(calls.n,0)
    frame();eq(calls.n,1);local x,y=topLeft();near(x,-768,1);near(y,-432+36,1)
    eq(A.UI.watch:GetScript('OnUpdate'),nil);frame();eq(calls.n,1)
    addonScale(1,1920,1080);frame();eq(calls.n,2)
    UIParent:SetSize(1366,768);eq(calls.n,2);frame();eq(calls.n,3)
    x,y=topLeft();near(x,-683,1);near(y,-384+36,1)
    UIParent:SetSize(1920,1080);frame();eq(calls.n,4);frame();eq(calls.n,4)
    A.UI.root.SetPoint=nil;UIParent.scale=nil
    x,y=topLeft();near(x,-900,1);near(y,-480,1);eq(A.db.position.x,-900);eq(A.db.position.y,-480)
end)

test('scale events lay out on the next frame, and hiding drops a queued layout',function()
    A:SetView('compact');A.db.position={x=-900,y=-480};A.UI:ApplyLayout()
    for _,event in ipairs({{'UI_SCALE_CHANGED'},{'DISPLAY_SIZE_CHANGED'},{'CVAR_UPDATE','uiScale','0.8'},{'CVAR_UPDATE','useUiScale','1'}}) do
        engineScale(1.25,1920,1080);A.events:Fire('OnEvent',unpack(event))
        local x,y=topLeft();near(x,-900,1);near(y,-480,1)
        frame();x,y=topLeft();near(x,-768,1);near(y,-432+36,1);eq(A.UI.watch:GetScript('OnUpdate'),nil)
        engineScale(1,1920,1080);A.UI:ApplyLayout()
    end
    UIParent:SetSize(1366,768);assert(A.UI.watch:GetScript('OnUpdate'))
    UIParent.shown=false;A.UI.root:Fire('OnHide');eq(A.UI.watch:GetScript('OnUpdate'),nil)
    UIParent.shown=true;A.UI.root:Fire('OnShow');local x,y=topLeft();near(x,-683,1);near(y,-384+36,1)
    UIParent.scale=nil;UIParent:SetSize(1920,1080);frame();eq(A.UI.watch:GetScript('OnUpdate'),nil)
    x,y=topLeft();near(x,-900,1);near(y,-480,1)
end)

test('a drop being checked survives a passing UIParent size',function()
    local old=A.Placement.Collect
    A.Placement.Collect=function(_,checkpoint) for i=1,1000 do checkpoint() end;return {} end
    A.db.avoidOverlap=true;A:SetView('compact');A.db.position={x=-50,y=-60};A.UI:ApplyLayout()
    Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(100,200);Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop')
    local job=A.UI.placementJob;assert(job)
    engineScale(1.2,1920,1080)
    A.events:Fire('OnEvent','CVAR_UPDATE','uiScale','0.5');A.events:Fire('OnEvent','UI_SCALE_CHANGED')
    A.events:Fire('OnEvent','DISPLAY_SIZE_CHANGED')
    addonScale(1,1920,1080);frame()
    eq(A.UI.placementJob,job);Mock.finishPlacement()
    near(A.db.position.x,100);near(A.db.position.y,200)
    local x,y=topLeft();near(x,100,1);near(y,200,1)
    -- A lasting change still cancels the unchecked drop, as a resize did before.
    Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(300,250);Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop')
    assert(A.UI.placementJob);UIParent:SetSize(1366,768);frame()
    eq(A.UI.placementJob,nil);near(A.db.position.x,100);near(A.db.position.y,200)
    UIParent.scale=nil;UIParent:SetSize(1920,1080);frame()
    A.Placement.Collect=old;A.db.avoidOverlap=false
end)

test('a rescale during a drag waits for the drop, and a hidden bar catches up when shown',function()
    A:SetView('compact');A.db.position={x=0,y=0};A.UI:ApplyLayout()
    Mock.leftMouseDown=true;A.UI.grip:Fire('OnDragStart');move(600,350)
    local shown=A.UI.root.points[1]
    UIParent:SetSize(1366,768);A.events:Fire('OnEvent','UI_SCALE_CHANGED');frame();frame()
    eq(A.UI.dragging,true);eq(#A.UI.root.points,1);eq(A.UI.root.points[1],shown)
    Mock.leftMouseDown=false;A.UI.grip:Fire('OnDragStop')
    -- Saved where it was dropped; shown clamped into the smaller UIParent.
    near(A.db.position.x,600);near(A.db.position.y,350)
    local x,y=topLeft();near(x,683-276,1);near(y,350,1)
    UIParent.shown=false;A.UI.root:Fire('OnHide');eq(A.UI.watch:IsVisible(),false)
    UIParent:SetSize(1920,1080);eq(A.UI.watch:GetScript('OnUpdate'),nil)
    UIParent.shown=true;A.UI.root:Fire('OnShow')
    x,y=topLeft();near(x,600,1);near(y,350,1)
end)

for k in pairs(Mock.cvars) do Mock.cvars[k]=nil end
for k,v in pairs(cvars) do Mock.cvars[k]=v end
A.db.locked,A.db.avoidOverlap,A.db.viewMode=saved.locked,saved.avoidOverlap,saved.viewMode
A:SetScale(saved.uiScale);A.db.position=saved.position;A.UI:Refresh()
return count
