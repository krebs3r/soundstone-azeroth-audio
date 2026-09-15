local A=Soundstone
local count=0
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b,t) assert(math.abs(a-b)<(t or .0001),tostring(a)..' !~= '..tostring(b)) end
local function clear(x,y,w,h,rects,gap)
    for _,r in ipairs(rects) do
        if x<r.right+gap and x+w>r.left-gap and y>r.bottom-gap and y-h<r.top+gap then return false end
    end
    return true
end
test('placement finds the nearest free position against an independent exhaustive grid',function()
    local rects={{left=8,right=15,bottom=5,top=11},{left=13,right=22,bottom=9,top=18},{left=0,right=7,bottom=0,top=7}}
    for x=-4,32,3 do for y=-3,28,3 do
        local nx,ny=A.Placement.Find(x,y,6,4,30,24,rects,1)
        local nearest
        for bx=0,24 do for by=4,24 do if clear(bx,by,6,4,rects,1) then
            local distance=(bx-x)^2+(by-y)^2;nearest=math.min(nearest or math.huge,distance)
        end end end
        assert(nx and ny);assert(clear(nx,ny,6,4,rects,1))
        near((nx-x)^2+(ny-y)^2,nearest)
    end end
    eq(A.Placement.Find(0,10,31,4,30,24,{},0),nil)
    eq(A.Placement.Find(0,10,6,4,30,24,{{left=0,right=30,bottom=0,top=24}},0),nil)
end)

test('frame collection ignores own, invisible, forbidden, inaccessible and full-screen containers',function()
    local parent=CreateFrame('Frame',nil,UIParent);parent:SetSize(140,90);parent:SetPoint('TOPLEFT',200,-100);parent:EnableMouse(true)
    local child=CreateFrame('Button',nil,parent);child:SetSize(20,20);child:SetPoint('CENTER')
    local before=A.Placement.Collect(A.UI.root);assert(#before>=2)
    child.forbidden=true;near(#A.Placement.Collect(A.UI.root),#before-1)
    child.forbidden=false;parent:Hide();near(#A.Placement.Collect(A.UI.root),#before-2)
    parent:Show();parent.GetLeft=function() error('restricted coordinates') end
    -- The child also depends on its parent's geometry in the client double.
    local readable=A.Placement.Collect(A.UI.root);assert(type(readable)=='table')
    parent:Hide()
    local overlay=CreateFrame('Frame',nil,UIParent);overlay:SetSize(UIParent:GetWidth(),UIParent:GetHeight());overlay:SetPoint('CENTER');overlay:EnableMouse(true)
    local n=#A.Placement.Collect(A.UI.root);overlay:Hide();eq(#A.Placement.Collect(A.UI.root),n)
    local oldChildren=UIParent.GetChildren;UIParent.GetChildren=function() error('unavailable') end
    eq(A.Placement.Collect(A.UI.root),nil);UIParent.GetChildren=oldChildren
    local protected=CreateFrame('Button',nil,UIParent);protected:SetSize(40,40);protected:SetPoint('CENTER')
    local secret={};protected.IsVisible=function() return secret end
    local oldSecret=issecretvalue;issecretvalue=function(value) return value==secret end
    n=#A.Placement.Collect(A.UI.root);protected:Hide();protected.IsVisible=function() return false end;eq(#A.Placement.Collect(A.UI.root),n)
    issecretvalue=oldSecret
end)

test('dropping avoids UI buttons across both views and all screen/addon scales',function()
    local obstacle=CreateFrame('Button',nil,UIParent);obstacle:SetSize(140,60);obstacle:SetPoint('CENTER')
    local writes=#Mock.writes
    A.db.locked=false;A.db.avoidOverlap=true
    for _,resolution in ipairs({{1920,1080},{2560,1440}}) do
        Mock.physicalWidth,Mock.physicalHeight=resolution[1],resolution[2]
        local factor=768/resolution[2]
        for _,ws in ipairs({.65,.85,1}) do
            UIParent:SetScale(ws);UIParent:SetSize(resolution[1]*factor/ws,768/ws)
            for _,scale in ipairs({.75,1,1.5}) do for _,mode in ipairs({'compact','expanded'}) do
                A:SetScale(scale);A:SetView(mode)
                local handle=mode=='compact' and A.UI.grip or A.UI.panelHeader
                handle:Fire('OnDragStart')
                A.UI.root:ClearAllPoints();A.UI.root:SetPoint('TOPLEFT',UIParent,'CENTER',-40,20)
                handle:Fire('OnDragStop')
                Mock.finishPlacement()
                local root=A.UI.root;local x,y=root:GetLeft()*scale,root:GetTop()*scale
                local rect={left=obstacle:GetLeft(),right=obstacle:GetLeft()+140,top=obstacle:GetTop(),bottom=obstacle:GetTop()-60}
                assert(clear(x,y,root:GetWidth()*scale,root:GetHeight()*scale,{rect},0))
                near(A.db.position.x+UIParent:GetWidth()/2,x,1.2)
                eq(root.moving,false);eq(A.UI.dragging,false);eq(A.UI.dragOrigin,nil)
                assert(x>=-1 and x+root:GetWidth()*scale<=UIParent:GetWidth()+1)
            end end
        end
    end
    eq(#Mock.writes,writes);obstacle:Hide()
    UIParent:SetScale(1);UIParent:SetSize(1920,1080);Mock.physicalWidth,Mock.physicalHeight=1920,1080;A:SetScale(1);A:ResetPositions()
end)

test('placement option, locked position and no-room rollback preserve user control',function()
    A:SetView('compact');A.db.locked=false;A.db.avoidOverlap=false
    local old=A.Placement.Collect;A.Placement.Collect=function() error('disabled option must not enumerate UI') end
    A.UI.grip:Fire('OnDragStart');A.UI.root:ClearAllPoints();A.UI.root:SetPoint('TOPLEFT',UIParent,'CENTER',77,88);A.UI.grip:Fire('OnDragStop')
    Mock.finishPlacement()
    near(A.db.position.x,77);near(A.db.position.y,88)
    A.db.avoidOverlap=true;A.Placement.Collect=function() return {{left=0,right=1920,bottom=0,top=1080}} end
    A.UI.grip:Fire('OnDragStart');A.UI.root:ClearAllPoints();A.UI.root:SetPoint('TOPLEFT',UIParent,'CENTER',20,30);A.UI.grip:Fire('OnDragStop')
    Mock.finishPlacement()
    near(A.db.position.x,77);near(A.db.position.y,88);assert(Mock.messages[#Mock.messages]:find(A.L.NO_FREE_SPACE,1,true))
    A.Placement.Collect=function() return nil end
    A.UI.grip:Fire('OnDragStart');A.UI.root:ClearAllPoints();A.UI.root:SetPoint('TOPLEFT',UIParent,'CENTER',44,55);A.UI.grip:Fire('OnDragStop')
    Mock.finishPlacement()
    near(A.db.position.x,77);assert(Mock.messages[#Mock.messages]:find(A.L.PLACEMENT_UNAVAILABLE,1,true))
    A.Placement.Collect=old;A.db.locked=true;A.UI.grip:Fire('OnDragStart');eq(A.UI.dragging,false)
    A.db.locked=false;A:ResetPositions()
    A.UI:ToggleMenu();A.UI.checks.avoidOverlap:SetChecked(false);A.UI.checks.avoidOverlap:Fire('OnClick');eq(A.db.avoidOverlap,false)
    A.UI.checks.avoidOverlap:SetChecked(true);A.UI.checks.avoidOverlap:Fire('OnClick');eq(A.db.avoidOverlap,true)
    eq(A.UI.menu:GetHeight(),236);assert(A.UI.resetSize:GetTop()<A.UI.checks.avoidOverlap:GetTop()-24)
    A.UI:CloseMenus()
end)

test('short contextual tooltips describe compact, buttons and sliders individually',function()
    for _,id in ipairs({'master','sfx','music'}) do
        A.UI.barControls[id]:Fire('OnEnter');local compact=Mock.tooltip.line
        assert(compact:find(A.L.TIP_COMPACT,1,true));assert(not compact:find(A.L.ACTIVATION_HELP,1,true))
        local _,lines=compact:gsub('\n','');assert(lines<=2)
        A.UI.rows[id].toggle:Fire('OnEnter');local expanded=Mock.tooltip.line
        assert(expanded:find(A.L.TIP_EXPANDED,1,true));assert(not expanded:find(A.L.TIP_COMPACT,1,true));assert(compact~=expanded)
        _,lines=expanded:gsub('\n','');assert(lines<=3)
        A.UI.rows[id].slider:Fire('OnEnter');assert(Mock.tooltip.line:find(A.L.TIP_SLIDER,1,true))
        assert(not Mock.tooltip.line:find(A.L.TIP_EXPANDED,1,true))
    end
end)

test('long title fits and the version opens readable translated release notes with layered closing',function()
    A:SetView('expanded');eq(A.UI.panelTitle.textValue,'Soundstone – Azeroth Audio');assert(A.UI.panelTitle:GetStringWidth()<=152)
    assert(A.UI.panelTitle.fontSize>=10);near(A.UI.panelHeader:GetLeft()+A.UI.panelHeader:GetWidth()/2,A.UI.panel:GetLeft()+150)
    A.UI:ToggleMenu();A.UI.scaleSlider:SetValue(130);assert(A.UI.pendingScale)
    A.UI.footer:Fire('OnClick','LeftButton');eq(A.UI.news:IsShown(),true);eq(A.UI.menu:IsShown(),false);eq(A.UI.pendingScale,nil)
    eq(A.UI.newsPage,1);eq(A.UI.newsPrevious:IsEnabled(),false);eq(A.UI.newsBody.fontSize,11)
    eq(A.UI.newsBody.textValue,A.ReleaseNotes[1].text);assert(A.UI.newsTitle.textValue:find('v0.3.1',1,true))
    A.UI.newsNext:Fire('OnClick');eq(A.UI.newsPage,2);eq(A.UI.newsNext:IsEnabled(),true)
    A.UI.newsPrevious:Fire('OnClick');eq(A.UI.newsPage,1)
    Mock.pressEscape();eq(A.UI.news:IsShown(),false);eq(A.db.viewMode,'expanded')
    Mock.pressEscape();eq(A.db.viewMode,'compact')
    A:SetView('expanded');A.UI.footer:Fire('OnClick');A.UI.footer:Fire('OnClick');eq(A.UI.news:IsShown(),false)
    A.UI.footer:Fire('OnClick');A:SetVisible(false);eq(A.UI.news:IsShown(),false);A:SetVisible(true)
    A.UI.footer:Fire('OnClick');A:SetView('compact');eq(A.UI.news:IsShown(),false)
    A:SetView('expanded');A.UI.footer:Fire('OnClick');A.UI:ToggleMenu();eq(A.UI.news:IsShown(),false);eq(A.UI.menu:IsShown(),true);A.UI:CloseMenus()
end)

test('release notes use one card per version with the same dimensions as the mixer',function()
    eq(A.UI.news:GetWidth(),A.UI.panel:GetWidth());eq(A.UI.news:GetHeight(),A.UI.panel:GetHeight())
    eq(A.UI.news:GetWidth(),300);eq(A.UI.news:GetHeight(),160)
    local versions={}
    for i,entry in ipairs(A.ReleaseNotes) do
        assert(not versions[entry.version],'Duplicate release card: '..entry.version);versions[entry.version]=true
        A.UI:ShowNewsPage(i);eq(A.UI.newsBody.textValue,entry.text)
        eq(A.UI.newsCounter.textValue,i..' / '..#A.ReleaseNotes)
        local body=A.UI.newsBody
        assert(body:GetTop()-body:GetHeight()>A.UI.newsPrevious:GetTop())
        assert(body:GetTop()<A.UI.newsTitle:GetTop()-12)
    end
    assert(versions['0.3.1'] and versions['0.3.0'] and versions['0.2.0']);eq(#A.ReleaseNotes,3)
    A.UI:ShowNewsPage(99);eq(A.UI.newsPage,3);A.UI:ShowNewsPage(-1);eq(A.UI.newsPage,1)
end)

test('release notes remain on screen at corners throughout the scale matrix',function()
    for _,size in ipairs({{1920,1080},{2560,1440}}) do
        Mock.physicalWidth,Mock.physicalHeight=size[1],size[2]
        for _,ws in ipairs({.65,.85,1}) do for _,scale in ipairs({.75,1,1.5}) do
            UIParent:SetScale(ws);UIParent:SetSize(size[1]*768/size[2]/ws,768/ws)
            A:SetScale(scale);A:SetView('expanded')
            for _,p in ipairs({{-10000,10000},{10000,-10000}}) do
                A.db.position={x=p[1],y=p[2]};A.UI:ApplyLayout();A.UI.footer:Fire('OnClick')
                local news=A.UI.news
                assert(news:GetLeft()*scale>=-1.2)
                assert((news:GetLeft()+news:GetWidth())*scale<=UIParent:GetWidth()+1.2)
                assert(news:GetTop()*scale<=UIParent:GetHeight()+1.2)
                assert((news:GetTop()-news:GetHeight())*scale>=-1.2)
                near(news:GetLeft(),A.UI.root:GetLeft());A.UI:CloseMenus()
            end
        end end
    end
    UIParent:SetScale(1);UIParent:SetSize(1920,1080);Mock.physicalWidth,Mock.physicalHeight=1920,1080;A:SetScale(1);A:ResetPositions();A:SetView('compact')
end)
return count
