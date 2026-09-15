local A=Soundstone
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a)..' !~= '..tostring(b)) end
local function test(name,fn) fn();count=count+1;print('PASS '..name) end

test('eye button closes all layers, cancels pending size and preserves settings',function()
    A:SetView('expanded');A:SetScale(1)
    local position=A.db.position;local writes=#Mock.writes;local messages=#Mock.messages
    A.UI:ToggleMenu();A.UI.scaleSlider:SetValue(150);Mock.clickDropdown(A.UI.outputDropdown)
    A.UI.panelHide:Fire('OnClick');eq(A.UI.outputDropdown:IsOpen(),false)
    for _,frame in ipairs({A.UI.root,A.UI.bar,A.UI.panel,A.UI.menu,A.UI.escape}) do eq(frame:IsShown(),false) end
    eq(A.db.viewMode,'expanded');eq(A.db.position,position);eq(A.db.uiScale,1);eq(A.UI.pendingScale,nil)
    eq(A.UI.minimap:IsShown(),true);eq(#Mock.writes,writes);eq(#Mock.messages,messages+1)
    assert(Mock.messages[#Mock.messages]:find('/soundstone',1,true))
    A.UI.scaleSlider:Fire('OnMouseUp','LeftButton');eq(A.db.uiScale,1)
    A:Command('show');eq(A.UI.panel:IsShown(),true);eq(A.UI.menu:IsShown(),false)
end)

test('slash and minimap restore each last view before toggling normally',function()
    for _,mode in ipairs({'compact','expanded'}) do
        A:SetView(mode);A:Command('hide');A:Command('');eq(A.db.viewMode,mode);eq(A.UI.root:IsShown(),true)
        A:Command('hide');A.UI.minimap:Fire('OnClick','LeftButton');eq(A.db.viewMode,mode);eq(A.UI.root:IsShown(),true)
        A.UI.minimap:Fire('OnClick','LeftButton');eq(A.db.viewMode,mode=='compact' and 'expanded' or 'compact')
        A:SetView(mode);A:Command('bar');eq(A.db.showBar,false);A:Command('bar');eq(A.db.viewMode,mode)
    end
    A:SetView('compact')
end)

test('hide and show remain idempotent and work with the minimap disabled',function()
    A:Command('minimap');eq(A.db.showMinimap,false);A:Command('hide')
    local messages=#Mock.messages;local writes=#Mock.writes
    A:Command('hide');eq(#Mock.messages,messages)
    A.events:Fire('OnEvent','CVAR_UPDATE','Sound_MasterVolume');eq(A.UI.root:IsShown(),false)
    A:Command('show');A:Command('show');eq(A.db.viewMode,'compact');eq(A.UI.root:IsShown(),true)
    eq(A.UI.minimap:IsShown(),false);eq(A.db.showMinimap,false);eq(#Mock.writes,writes)
    A:Command('hide');A:Command('');eq(A.UI.bar:IsShown(),true);eq(A.UI.minimap:IsShown(),false)
    A:Command('minimap')
end)

test('compact channels keep fixed percentage fields at zero, full volume and mute',function()
    A:SetView('compact');A:SetScale(1)
    eq(A.UI.bar:GetWidth(),276);eq(A.UI.bar:GetHeight(),36)
    eq(A.UI.panel:GetWidth(),300);eq(A.UI.panel:GetHeight(),160)
    local lastRight=A.UI.barMode:GetLeft()+A.UI.barMode:GetWidth()
    for _,ch in ipairs(A.Audio.channels) do
        local c=A.UI.barControls[ch.id];local valueX=c.value:GetLeft();local iconX=c.icon:GetLeft()
        assert(c:GetLeft()>=lastRight);lastRight=c:GetLeft()+c:GetWidth()
        eq(c:GetWidth(),68);eq(c:GetHeight(),28);eq(c.value:GetWidth(),34);eq(c.value.fontSize,11)
        near(valueX-iconX-c.icon:GetWidth(),5);eq(c.icon:GetWidth(),22);near(iconX-c:GetLeft()+11,15)
        local volume,enabled=Mock.cvars[ch.volume],Mock.cvars[ch.enabled]
        for _,percent in ipairs({0,100}) do
            A:SetVolume(ch.id,percent);eq(c.value.textValue,percent..' %')
            near(c.value:GetLeft(),valueX);near(c.icon:GetLeft(),iconX)
        end
        A.audio:SetEnabled(ch.id,false);eq(c.value.textValue,'100 %');eq(c.icon.texture.desaturated,true)
        Mock.cvars[ch.volume],Mock.cvars[ch.enabled]=volume,enabled
    end
    assert(lastRight<=A.UI.bar:GetLeft()+A.UI.bar:GetWidth()-6)
    A.UI:Refresh()
end)

test('options fit compact bounds and dropdown text centers inside the click area',function()
    local menu=A.UI.menu;eq(menu:GetWidth(),276);eq(menu:GetHeight(),236)
    local previousBottom=menu:GetTop()
    for _,b in ipairs({A.UI.resetSize,A.UI.resetPosition}) do
        eq(b:GetWidth(),256);eq(b:GetHeight(),20);eq(b.text.fontSize,10)
        near(b:GetLeft()-menu:GetLeft(),10);assert(b:GetTop()<previousBottom)
        previousBottom=b:GetTop()-b:GetHeight();assert(previousBottom>menu:GetTop()-menu:GetHeight())
        eq(b.text.wordWrap,false);eq(b.template,'UIPanelButtonTemplate')
    end
    local f=A.UI.deviceButton;local click=A.UI.outputDropdown.clickTarget;eq(click:GetHeight(),24);eq(f.Text:GetHeight(),24)
    local _,ty=f.Text:GetCenter();local _,by=click:GetCenter();near(ty,by)
    near(f.Text:GetLeft()-click:GetLeft(),7);eq(f.Text.justify,'LEFT');eq(f.Text.justifyV,'MIDDLE')
    eq(A.L.OUTPUT,Mock.locale=='deDE' and 'Ausgabegerät' or 'Output device')
    for _,mode in ipairs({'compact','expanded'}) do
        A.db.position={x=-300,y=100};A:SetView(mode)
        near(A.UI.menu:GetLeft(),A.UI.root:GetLeft())
        local gap=A.UI.root:GetTop()-A.UI.root:GetHeight()-A.UI.menu:GetTop()
        assert(math.abs(gap-4)<=A.Compat.Pixel(1,A.UI.root))
    end
    A:SetView('compact');A:ResetPositions()
end)
test('direct view buttons replace menu actions without changing audio or position',function()
    local writes=#Mock.writes;local position=A.db.position
    eq(A.UI.modeButton,nil);eq(A.UI.hideButton,nil)
    A:SetView('compact');A.UI:ToggleMenu();A.UI.barMode:Fire('OnClick')
    eq(A.db.viewMode,'expanded');eq(A.UI.menu:IsShown(),false)
    A.UI:ToggleMenu();A.UI.scaleSlider:SetValue(150);A.UI.panelMode:Fire('OnClick')
    eq(A.db.viewMode,'compact');eq(A.UI.pendingScale,nil);eq(A.db.uiScale,1)
    A.UI.barMode:Fire('OnClick');A.UI.close:Fire('OnClick');eq(A.db.viewMode,'compact')
    A.UI.barMode:Fire('OnClick');A.UI:Escape();eq(A.db.viewMode,'compact')
    eq(A.db.position,position);eq(#Mock.writes,writes)
end)

test('header controls have separate hit areas and keep the title centered',function()
    local function separated(left,right,gap)
        near(right:GetLeft()-left:GetLeft()-left:GetWidth(),gap)
    end
    separated(A.UI.barSettings,A.UI.barMode,2);separated(A.UI.barMode,A.UI.barControls.master,2)
    separated(A.UI.panelHide,A.UI.panelMode,2);separated(A.UI.panelMode,A.UI.close,2)
    assert(A.UI.panelHeader:GetLeft()>A.UI.panelSettings:GetLeft()+19)
    assert(A.UI.panelHeader:GetLeft()+A.UI.panelHeader:GetWidth()<A.UI.panelHide:GetLeft())
    local tx=A.UI.panelTitle:GetCenter();local px=A.UI.panel:GetCenter();near(tx,px)
    eq(A.UI.barMode:GetWidth(),19);eq(A.UI.barMode:GetHeight(),19)
    for _,b in ipairs({A.UI.panelMode,A.UI.panelHide,A.UI.close}) do
        eq(b:GetWidth(),20);eq(b:GetHeight(),20);eq(b:GetScript('OnDragStart'),nil)
    end
end)

test('metadata version and author surround a real heart texture in the footer',function()
    eq(A.UI.version.textValue,'v0.3.0');eq(A.UI.author.textValue,'by krebs3r')
    eq(A.UI.version.fontSize,7.5);eq(A.UI.author.fontSize,7.5);eq(A.UI.footer.alpha,.55)
    assert(A.UI.footerHeart.texturePath:find('Heart.tga',1,true))
    eq(A.UI.footerHeart:GetWidth(),8);eq(A.UI.footerHeart:GetHeight(),8)
    near(A.UI.footerHeart:GetLeft()-A.UI.version:GetLeft()-A.UI.version:GetWidth(),3)
    near(A.UI.author:GetLeft()-A.UI.footerHeart:GetLeft()-8,3)
    near(A.UI.footer:GetLeft()+A.UI.footer:GetWidth(),A.UI.panel:GetLeft()+290)
    assert(A.UI.footer:GetTop()<A.UI.rows.music:GetTop()-A.UI.rows.music:GetHeight()/2-5)
end)

test('metal buttons have distinct states, release cleanly and preserve the gear',function()
    for _,entry in ipairs({{A.UI.barMode,A.L.EXPAND}}) do
        local b,title=entry[1],entry[2]
        local function state(name,brightness,offset)
            assert(b.plate.texturePath:find(name..'.tga',1,true))
            for i=1,3 do eq(b.image.color[i],brightness) end
            local _,imageY=b.image:GetCenter();local _,buttonY=b:GetCenter();near(imageY-buttonY,offset)
            eq(b.plate:GetWidth(),19);eq(b.plate:GetHeight(),19)
        end
        b:Fire('OnLeave');state('ActionNormal',.9,0)
        b:Fire('OnEnter');eq(Mock.tooltip.text,title);eq(Mock.tooltip.owner,b);eq(Mock.tooltip.shown,true)
        state('ActionHover',1,0)
        b:Fire('OnMouseDown','LeftButton');state('ActionPressed',.7,-1)
        b:Fire('OnMouseUp','LeftButton');state('ActionHover',1,0)
        Mock.leftMouseDown=true
        b:Fire('OnMouseDown','LeftButton');b:Fire('OnLeave');state('ActionNormal',.9,0)
        b:Fire('OnEnter');state('ActionPressed',.7,-1)
        b:Fire('OnLeave');Mock.leftMouseDown=false
        b:Fire('OnEnter');state('ActionHover',1,0)
        b:Fire('OnMouseDown','LeftButton')
        b:Fire('OnHide');b:Fire('OnEnter');state('ActionHover',1,0)
        b:Fire('OnLeave');state('ActionNormal',.9,0);eq(Mock.tooltip.shown,false)
    end
    for _,b in ipairs({A.UI.barSettings,A.UI.panelSettings}) do
        eq(b.plate,nil)
        b:Fire('OnLeave');eq(b.image.color[1],.9);eq(b.image.color[2],.8);eq(b.image.color[3],.57)
        b:Fire('OnMouseDown');eq(b.image.color[1],.6);eq(b.image.color[2],.55);eq(b.image.color[3],.4)
        b:Fire('OnMouseUp')
    end
end)
return count
