local A=Soundstone
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b,t) assert(math.abs(a-b)<(t or .00001),tostring(a)..' !~= '..tostring(b)) end
local function test(name,fn) fn();count=count+1;print('PASS '..name) end

test('red header buttons share size, bounds, ordering and pointer states',function()
    A:SetScale(1);A:SetView('expanded')
    for _,entry in ipairs({{A.UI.panelHide,'HeaderHide',A.L.HIDE},{A.UI.panelMode,'HeaderCompact',A.L.COMPACT},{A.UI.close,'HeaderClose',A.L.COMPACT}}) do
        local b,name,title=unpack(entry)
        near(b:GetWidth(),20);near(b:GetHeight(),20);eq(b.plate,nil)
        assert(b.image.texturePath:find(name..'.tga',1,true))
        near(b.image:GetLeft(),b:GetLeft());near(b.image:GetTop(),b:GetTop())
        near(b.image:GetWidth(),20);near(b.image:GetHeight(),20)
        local function color(r,g,bl) eq(b.image.color[1],r);eq(b.image.color[2],g);eq(b.image.color[3],bl) end
        b:Fire('OnLeave');color(1,1,1)
        b:Fire('OnEnter');color(1,.94,.75);eq(Mock.tooltip.text,title)
        b:Fire('OnMouseDown','RightButton');color(1,.94,.75)
        b:Fire('OnMouseDown','LeftButton');color(.65,.65,.65)
        b:Fire('OnMouseUp','LeftButton');color(1,.94,.75)
        Mock.leftMouseDown=true;b:Fire('OnMouseDown','LeftButton');b:Fire('OnLeave');color(1,1,1)
        b:Fire('OnEnter');color(.65,.65,.65)
        b:Fire('OnLeave');Mock.leftMouseDown=false;b:Fire('OnEnter');color(1,.94,.75)
        b:Fire('OnMouseDown','LeftButton');b:Fire('OnHide');b:Fire('OnEnter');color(1,.94,.75)
        b:Fire('OnLeave');eq(Mock.tooltip.shown,false)
    end
    near(A.UI.panelMode:GetLeft()-A.UI.panelHide:GetLeft()-20,2)
    near(A.UI.close:GetLeft()-A.UI.panelMode:GetLeft()-20,2)
    near(A.UI.panelHide:GetTop(),A.UI.close:GetTop());near(A.UI.panelMode:GetTop(),A.UI.close:GetTop())
    assert(A.UI.panelHeader:GetLeft()+A.UI.panelHeader:GetWidth()<A.UI.panelHide:GetLeft())
    near(A.UI.barMode:GetWidth(),19);assert(A.UI.barMode.plate.texturePath:find('ActionNormal',1,true))
end)

test('attached options stay flush and separate in every resolution and scale combination',function()
    local writes=#Mock.writes
    for _,resolution in ipairs({{1920,1080},{2560,1440}}) do
        Mock.physicalWidth,Mock.physicalHeight=resolution[1],resolution[2]
        local factor=768/resolution[2]
        for _,ws in ipairs({.65,.85,1}) do
            UIParent:SetScale(ws);UIParent:SetSize(resolution[1]*factor/ws,768/ws)
            for _,scale in ipairs({.75,1,1.5}) do for _,mode in ipairs({'compact','expanded'}) do
                A:SetScale(scale);A:SetView(mode)
                for _,position in ipairs({{-10000,10000},{10000,10000},{-10000,-10000},{10000,-10000},{0,0}}) do
                    A.UI:CloseMenus();A.db.position={x=position[1],y=position[2]};A.UI:ApplyLayout()
                    local saved=A.db.position;local beforeX,beforeY=A.UI.root:GetLeft(),A.UI.root:GetTop()
                    A.UI:ToggleMenu()
                    local menu,root=A.UI.menu,A.UI.root
                    near(menu:GetWidth(),276);near(menu:GetHeight(),236);near(A.UI.outputDropdown.field:GetWidth(),256)
                    near(menu:GetLeft(),root:GetLeft());near(menu:GetEffectiveScale(),root:GetEffectiveScale())
                    local gap=A.UI.menuOpensUp and menu:GetTop()-menu:GetHeight()-root:GetTop() or root:GetTop()-root:GetHeight()-menu:GetTop()
                    near(gap,A.Compat.Pixel(4,menu))
                    if position[2]==10000 then eq(A.UI.menuOpensUp,false)
                    elseif position[2]==-10000 then eq(A.UI.menuOpensUp,true) end
                    local tolerance=factor/ws+.001
                    for _,frame in ipairs({root,menu}) do
                        assert(frame:GetLeft()*scale>=-tolerance)
                        assert((frame:GetLeft()+frame:GetWidth())*scale<=UIParent:GetWidth()+tolerance)
                        assert(frame:GetTop()*scale<=UIParent:GetHeight()+tolerance)
                        assert((frame:GetTop()-frame:GetHeight())*scale>=-tolerance)
                    end
                    for _,b in ipairs({A.UI.panelHide,A.UI.panelMode,A.UI.close}) do
                        near(b:GetWidth(),20);near(b:GetHeight(),20);near(b:GetTop(),A.UI.close:GetTop())
                    end
                    Mock.clickDropdown(A.UI.outputDropdown);near(A.UI.outputDropdown.list:GetWidth(),256)
                    A.UI:Escape();A.UI:Escape();eq(menu:IsShown(),false)
                    eq(A.db.position,saved);eq(saved.x,position[1]);eq(saved.y,position[2])
                    near(root:GetLeft(),beforeX);near(root:GetTop(),beforeY)
                end
            end end
        end
    end
    eq(#Mock.writes,writes)
    UIParent:SetScale(1);UIParent:SetSize(1920,1080);Mock.physicalWidth,Mock.physicalHeight=1920,1080
    A:SetScale(1);A:ResetPositions();A:SetView('compact')
end)

test('insufficient room on both sides temporarily moves the pair without saving it',function()
    UIParent:SetSize(1365,768);A:SetScale(1.5);A:SetView('expanded')
    A.db.position={x=0,y=120};A.UI:ApplyLayout();local y=A.UI.root:GetTop()
    A.UI:ToggleMenu();assert(A.UI.root:GetTop()~=y);eq(A.db.position.y,120)
    local top=A.UI.root:GetTop();A.UI.scaleSlider:SetValue(75);A.UI:Refresh()
    near(A.UI.root:GetTop(),top);eq(A.db.uiScale,1.5)
    A.UI:CloseMenus();near(A.UI.root:GetTop(),y);eq(A.UI.pendingScale,nil);eq(A.db.position.y,120)
    UIParent:SetSize(1920,1080);A:SetScale(1);A:ResetPositions();A:SetView('compact')
end)
return count
