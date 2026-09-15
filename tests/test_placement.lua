local A=Soundstone
local count=0
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function drop(x,y)
    A.UI.grip:Fire('OnDragStart')
    A.UI.root:ClearAllPoints();A.UI.root:SetPoint('TOPLEFT',UIParent,'CENTER',x/A.db.uiScale,y/A.db.uiScale)
    A.UI.grip:Fire('OnDragStop')
end

test('free drop skips candidate sorting even with thousands of obstacles',function()
    local rects={}
    for i=1,4000 do rects[i]={left=320+i/10,right=340+i/10,bottom=100,top=120} end
    local sort=table.sort;table.sort=function() error('A free drop must not sort candidates') end
    local ok,x,y=pcall(A.Placement.Find,10,1070,276,36,1920,1080,rects,3)
    table.sort=sort
    assert(ok);eq(x,10);eq(y,1070)
end)

test('visible tree scan prunes hidden pools and never uses EnumerateFrames',function()
    local pool=CreateFrame('Frame',nil,UIParent);pool:Hide()
    pool.GetChildren=function() error('Hidden subtree was traversed') end
    local enum=EnumerateFrames;EnumerateFrames=function() error('Global enumeration called') end
    local ok,rects=pcall(A.Placement.Collect,A.UI.root)
    EnumerateFrames=enum
    assert(ok and rects)
end)

test('noninteractive Blizzard bars protect inaccessible action buttons at every scale',function()
    local oldBar=MainActionBar
    local bar=CreateFrame('Frame',nil,UIParent);MainActionBar=bar
    bar:SetSize(454,45);bar:SetPoint('BOTTOM',UIParent,'BOTTOM',0,100)
    bar.IsMouseEnabled=function() error('Protected input flags') end
    bar.IsMovable=function() error('Protected input flags') end
    bar.GetChildren=function() error('Reserved bar must not inspect its protected children') end
    A.db.avoidOverlap=true;A.db.locked=false;A:SetView('compact')
    for _,uiScale in ipairs({.65,.75,1}) do for _,barScale in ipairs({.8,1.25}) do
        UIParent:SetScale(uiScale);bar:SetScale(barScale)
        for _,addonScale in ipairs({.75,1,1.5}) do
            A:SetScale(addonScale)
            local left,top=bar:GetLeft()*barScale,bar:GetTop()*barScale
            drop(left-UIParent:GetWidth()/2+20,top-UIParent:GetHeight()/2-10)
            assert(A.UI.placementJob);Mock.finishPlacement()
            local root=A.UI.root;local x,y=root:GetLeft()*addonScale,root:GetTop()*addonScale
            local w,h=root:GetWidth()*addonScale,root:GetHeight()*addonScale
            assert(x+w<=left or x>=left+454*barScale or y<=top-45*barScale or y-h>=top)
            eq(A.Placement.lastStats.known,1)
        end
    end end
    -- Hidden/forbidden bars do not contribute geometry through the known list.
    bar:Hide();local stats={};A.Placement.Collect(A.UI.root,nil,stats);eq(stats.known,0)
    bar:Show();bar.forbidden=true;A.Placement.Collect(A.UI.root,nil,stats);eq(stats.known,0)
    bar:Hide();MainActionBar=oldBar;UIParent:SetScale(1);A:SetScale(1);A:ResetPositions()
end)

test('expensive collision solving yields and agrees with the synchronous solver',function()
    local old=A.Placement.Collect
    local rects={}
    for i=1,120 do rects[i]={left=300+i/4,right=600+i/4,bottom=150+i,top=600+i/3} end
    A.Placement.Collect=function() return rects end
    local x,y=A.Placement.Find(400,500,276,36,1920,1080,rects,3)
    local job=A.Placement.Start(A.UI.root,400,500,276,36,1920,1080)
    eq(job:Step(),false)
    local done,px,py,status
    for i=1,10000 do done,px,py,status=job:Step();if done then break end end
    A.Placement.Collect=old
    assert(done);eq(status,'placed');eq(px,x);eq(py,y);assert(job.stats.steps>1)
end)

test('placement obeys elapsed slice budget and times out without stale coordinates',function()
    local oldCollect,oldClock=A.Placement.Collect,debugprofilestop
    local calls,clock=0,0
    debugprofilestop=function() clock=clock+1;return clock end
    A.Placement.Collect=function(_,checkpoint)
        for i=1,100 do calls=calls+1;checkpoint() end
        return {}
    end
    local job=A.Placement.Start(A.UI.root,0,100,276,36,1920,1080)
    eq(job:Step(),false);assert(calls<=2,'Time budget was ignored')
    Mock.time=Mock.time+3
    local done,x,y,status=job:Step();assert(done);eq(x,nil);eq(status,'unavailable')
    A.Placement.Collect=oldCollect;debugprofilestop=oldClock
end)

test('new drags and explicit layout changes cancel pending work without stale moves',function()
    local old=A.Placement.Collect
    A.Placement.Collect=function(_,checkpoint)
        for i=1,1000 do checkpoint() end
        return {}
    end
    A.db.locked=false;A.db.avoidOverlap=true;A:SetView('compact');A:ResetPositions()
    for _,change in ipairs({
        function() A:SetView('expanded') end,
        function() A:SetScale(1.25) end,
        function() A:SetVisible(false) end,
        function() A:ResetPositions() end,
        function() A.db.avoidOverlap=false;A.UI:Refresh() end,
    }) do
        A:SetVisible(true);A:SetView('compact');A.db.avoidOverlap=true
        drop(100,200);local update=A.UI.root:GetScript('OnUpdate')
        change();eq(A.UI.placementJob,nil);eq(A.UI.root:GetScript('OnUpdate'),nil)
        local position=A.db.position;update();eq(A.db.position,position)
    end
    A:SetVisible(true);A:SetView('compact');A.db.avoidOverlap=true
    drop(100,200);local first=A.UI.root:GetScript('OnUpdate')
    drop(300,400);local second=A.UI.placementJob
    first();eq(A.UI.placementJob,second);Mock.finishPlacement()
    assert(math.abs(A.db.position.x-300)<1 and math.abs(A.db.position.y-400)<1)
    eq(A.UI.root:GetScript('OnUpdate'),nil)
    A.Placement.Collect=old;A:SetScale(1);A:ResetPositions()
end)
return count
