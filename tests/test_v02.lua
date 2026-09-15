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
    A:SetView('expanded');A.UI.panelSettings:Fire('OnClick');Mock.clickDropdown(A.UI.outputDropdown)
    Mock.pressEscape();eq(A.UI.outputDropdown:IsOpen(),false);eq(A.UI.menu:IsShown(),true)
    Mock.pressEscape();eq(A.UI.menu:IsShown(),false);eq(A.db.viewMode,'expanded')
    Mock.pressEscape();eq(A.db.viewMode,'compact')
end)
test('six grip dots and unstretched icon dimensions',function()
    eq(#A.UI.gripDots,6)
    eq(#A.UI.panelGripDots,6);eq(A.UI.version.textValue,'v0.3.2')
    for _,id in ipairs({'master','sfx','music'}) do
        local names={master='Master',sfx='Sfx',music='Music'}
        local t=A.UI.barControls[id].icon.texture;local asset=A.Assets[names[id]]
        near(t.width/t.height,asset.width/asset.height)
        assert(t.width<=22 and t.height<=22)
        local row=A.UI.rows[id]
        assert(row.slider:GetFrameLevel()>row.fill:GetFrameLevel())
        eq(row.slider:GetThumbTexture().layer,'OVERLAY')
    end
end)
test('dragging does not click menu and position survives scaling',function()
    A.db.locked=false;A:SetView('compact');A.UI.grip:Fire('OnDragStart');eq(A.UI.dragging,true)
    A.UI.grip:Fire('OnDragStop');Mock.finishPlacement();local x,y=A.db.position.x,A.db.position.y
    A.UI.grip:Fire('OnClick');eq(A.UI.menu:IsShown(),false)
    A:SetScale(1.25);near(A.db.position.x,x);near(A.db.position.y,y)
    Mock.time=Mock.time+1;A.UI.grip:Fire('OnClick');eq(A.UI.menu:IsShown(),false)
    A.UI.barSettings:Fire('OnClick');eq(A.UI.menu:IsShown(),true);A.UI:CloseMenus()
end)
test('size dragging keeps control geometry stable and commits on release only',function()
    A:SetScale(1);A.UI.barSettings:Fire('OnClick')
    local left,top=A.UI.scaleSlider:GetLeft(),A.UI.scaleSlider:GetTop()
    for _,percent in ipairs({75,100,125,150}) do
        A.UI.scaleSlider:SetValue(percent)
        eq(A.db.uiScale,1);eq(A.UI.menu:GetEffectiveScale(),1)
        near(A.UI.scaleSlider:GetLeft(),left);near(A.UI.scaleSlider:GetTop(),top)
        eq(A.UI.scaleValue.textValue,percent..' %')
        A.UI:Refresh();eq(A.UI.scaleSlider:GetValue(),percent)
    end
    A.UI.scaleSlider:Fire('OnMouseUp','LeftButton');eq(A.db.uiScale,1.5)
    A.UI.scaleSlider:SetValue(75);A.UI:Escape();eq(A.db.uiScale,1.5);eq(A.UI.pendingScale,nil)
    A.UI.scaleSlider:Fire('OnMouseUp','LeftButton');eq(A.db.uiScale,1.5)
    A.UI:ToggleMenu();eq(A.UI.scaleSlider:GetValue(),150)
    A.UI.resetSize:Fire('OnClick');eq(A.db.uiScale,1)
    eq(A.UI.resetSize.template,A.UI.rows.master.toggle.template)
    eq(A.UI.resetPosition:GetWidth(),256)
    A.UI:CloseMenus()
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
                assert(A.UI.anchorX+A.UI.root:GetWidth()*s<=w/2+.01)
                assert(A.UI.anchorY-A.UI.root.height*s>=-h/2-.01)
                local pixel=A.Compat.Pixel(1.1,A.UI.root)*A.UI.root:GetEffectiveScale()/factor
                near(pixel,math.floor(pixel+.5))
                for _,pos in ipairs({{-10000,10000},{10000,10000},{-10000,-10000},{10000,-10000}}) do
                    A.db.position={x=pos[1],y=pos[2]};A.UI.menu:Show();A.UI.outputDropdown:Open();A.UI:ApplyLayout()
                    for _,frame in ipairs({A.UI.root,A.UI.menu,A.UI.outputDropdown.list}) do
                        local left,top=frame:GetLeft()*s,frame:GetTop()*s
                        local tolerance=factor/wowScale
                        assert(left>=-tolerance and top<=h+tolerance)
                        assert(left+frame:GetWidth()*s<=w+tolerance and top-frame:GetHeight()*s>=-tolerance)
                    end
                end
                local _,textY=A.UI.deviceButton.Text:GetCenter()
                local _,buttonY=A.UI.outputDropdown.clickTarget:GetCenter();near(textY,buttonY)
                for _,row in pairs(A.UI.rows) do
                    local b,icon=row.iconButton,row.icon
                    local edge=b.skinCorner or A.Compat.Pixel(3,b)
                    local gap=A.Compat.Pixel(1,b)
                    eq(b:GetWidth(),25);eq(b:GetHeight(),25);assert(icon:GetWidth()<=18)
                    near(icon:GetCenter(),b:GetCenter())
                    local _,iy=icon:GetCenter();local _,by=b:GetCenter();near(iy,by)
                    assert(icon:GetLeft()>=b:GetLeft()+edge+gap-.00001)
                    assert(icon:GetTop()<=b:GetTop()-edge-gap+.00001)
                    assert(icon.texture:GetWidth()<=icon:GetWidth() and icon.texture:GetHeight()<=icon:GetHeight())
                end
                for _,dots in ipairs({A.UI.gripDots,A.UI.panelGripDots}) do
                    local stepX=dots[2].points[1][2]-dots[1].points[1][2]
                    local stepY=dots[1].points[1][3]-dots[3].points[1][3]
                    near(stepX,stepY)
                    for i,t in ipairs(dots) do
                        near(t.width,dots[1].width);near(t.height,t.width)
                        local _,dx,dy=t:GetPoint()
                        near(dx,dots[1].points[1][2]+((i-1)%2)*stepX)
                        near(dy,dots[1].points[1][3]-math.floor((i-1)/2)*stepY)
                        local physical=dx*t:GetEffectiveScale()/factor
                        near(physical,math.floor(physical+.5))
                    end
                end
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
    eq(A.UI.outputDropdown.state.selected,nil);eq(A.devices:Select(2,'Headset'),false)
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
    eq(A.UI.outputDropdown.state.selected.name,'Speakers');eq(#Mock.writes,before)
    A.UI.menu:Show();A.UI.outputDropdown:Open();A.UI.outputDropdown.list:Fire('OnMouseWheel',-1);eq((A.UI.outputDropdown.native and A.UI.outputDropdown.list.offset or A.UI.outputDropdown.offset),1)
    eq(Mock.dropdownRows(A.UI.outputDropdown)[6].item.name,'USB 4')
    Mock.devices={'System Default','Speakers','Headset'};A.UI:RefreshDevices();eq((A.UI.outputDropdown.native and A.UI.outputDropdown.list.offset or A.UI.outputDropdown.offset),0)
end)
test('legacy positions migrate using the original bar anchor',function()
    local pos=A.Layout.LegacyPosition({point='CENTER',x=145,y=-85},1920,1080)
    eq(pos.x,-23);eq(pos.y,-62)
    pos=A.Layout.LegacyPosition({point='TOPLEFT',x=10,y=-20},1920,1080)
    eq(pos.x,-950);eq(pos.y,520)
end)
return count
