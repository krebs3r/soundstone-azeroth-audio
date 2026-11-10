local A=Soundstone
local T=A.Theme
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a)..' !~= '..tostring(b)) end
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local function rgb(r,g,b) return {r/255,g/255,b/255} end
local function color(c,expected,alpha)
    near(c[1],expected[1]);near(c[2],expected[2]);near(c[3],expected[3])
    if alpha then near(c[4],alpha) else eq(c[4],nil) end
end
local ui=A.UI
local saved={scale=A.db.uiScale,view=A.db.viewMode,height=Mock.physicalHeight,parent=UIParent.scale}
local plates={ui.bar,ui.panel,ui.menu}
local function pixel(frame) return 768/(Mock.physicalHeight or 1080)/frame:GetEffectiveScale() end

-- State of every region Soundstone had before Forever's look was first applied.
local function snapshot()
    local result={shown={}}
    for _,o in ipairs(Mock.objects) do
        local points={}
        for i,p in ipairs(o.points) do points[i]=table.concat({tostring(p[1]),tostring(p[2]),tostring(p[3]),tostring(p[4]),tostring(p[5])},',') end
        result.shown[o]=o.shown
        result[o]=table.concat({tostring(o.texturePath),tostring(o.atlas),o.uv and table.concat(o.uv,',') or '-',
            o.color and table.concat(o.color,',') or '-',o.textColor and table.concat(o.textColor,',') or '-',
            tostring(o.width),tostring(o.height),tostring(o.shown),tostring(o.alpha),tostring(o.layer),tostring(o.sublevel),
            tostring(o.blend),table.concat(points,'|'),tostring(o.fontSize),tostring(o.textValue),
            (o.kind=='Texture' or o.kind=='FontString') and '-' or tostring(o.level-ui.root.level)},';')
    end
    return result
end

test('the client look keeps the sprite skin on other clients and builds nothing for Forever',function()
    ui:ApplyTheme()
    if Mock.expectForever then
        -- Forever's first login: its look is in place without a switch or /reload.
        eq(ui.themeName,'forever');eq(T.name,'forever');eq(ui.foreverBuilt,true)
        for _,frame in ipairs(plates) do for _,p in ipairs(frame.skinPieces) do eq(p.t.shown,false) end end
        near(ui.bar.flatPlate.line.top.height,pixel(ui.bar));eq(ui.footer.alpha,.85);return
    end
    eq(ui.themeName,'soundstone');eq(ui.foreverBuilt,nil)
    for _,frame in ipairs(plates) do eq(frame.flatPlate,nil);for _,p in ipairs(frame.skinPieces) do eq(p.t.shown,true) end end
    eq(ui.barMode.flatWell,nil);eq(ui.grip.squares,nil);eq(ui.footer.alpha,.55)
    color(ui.barControls.master.value.textColor,{.96,.94,.87});color(ui.panelTitle.textColor,{1,.81,.26})
end)

local pristine,pristineCompact
test('switching to Forever and back restores every region and moves nothing',function()
    ui:ApplyTheme('soundstone');eq(ui.themeName,'soundstone')
    A:SetView('compact');pristineCompact=snapshot()
    A:SetView('expanded');ui:ToggleMenu()
    local before=snapshot();pristine=before;local position=A.db.position;local x,y=ui.root:GetLeft(),ui.root:GetTop()
    ui:ApplyTheme('forever');eq(ui.themeName,'forever');eq(A.db.position,position)
    near(ui.root:GetLeft(),x);near(ui.root:GetTop(),y)
    for _,frame in ipairs(plates) do eq(frame.flatPlate.edge.shown,true) end
    ui:ApplyTheme('soundstone');eq(A.db.position,position);near(ui.root:GetLeft(),x);near(ui.root:GetTop(),y)
    local after=snapshot()
    -- Every region keeps its shown state; every region shown under the sprites is exactly as before.
    -- Hidden Forever pieces may have been measured again meanwhile.
    for o,state in pairs(before) do if o~='shown' then
        eq(o.shown,before.shown[o])
        if o:IsVisible() then assert(after[o]==state,'changed: '..tostring(o.kind)..' '..state..' -> '..tostring(after[o])) end
    end end
    -- What Forever's look added is hidden again.
    for _,frame in ipairs(plates) do eq(frame.flatPlate.fill.shown,false);eq(frame.flatPlate.edge.shown,false) end
    for _,t in ipairs(ui.grip.squares) do eq(t.shown,false) end
    eq(ui.barMode.flatWell.ground.shown,false)
    ui:CloseMenus();A:SetView(saved.view)
end)

test('Forever plates wear a one-pixel line and band inside their bounds',function()
    ui:ApplyTheme('forever')
    for _,frame in ipairs(plates) do
        for _,p in ipairs(frame.skinPieces) do eq(p.t.shown,false) end
        local plate=frame.flatPlate;eq(plate.fill.shown,true);color(plate.fill.color,rgb(21,18,15),.96)
        local d=pixel(frame);near(plate.line.top.height,d);near(plate.line.left.width,d)
        color(plate.line.top.color,rgb(154,128,92));color(plate.line.left.color,rgb(128,104,72))
        color(plate.line.right.color,rgb(128,104,72));color(plate.line.bottom.color,rgb(104,80,52))
        color(plate.band.top.color,rgb(10,8,6))
        assert(plate.edge.level>frame.level,'edge above the content');eq(plate.edge.mouse,false)
    end
    eq(ui.bar.width,276);eq(ui.panel.width,300);eq(ui.menu.width,276)
end)

-- In physical pixels: left, top, width and height of a region, which must be whole numbers.
local function pixels(region,d)
    local l,t,w,h=region:GetLeft()/d,region:GetTop()/d,region:GetWidth()/d,region:GetHeight()/d
    for _,v in ipairs({l,t,w,h}) do near(v,math.floor(v+.5)) end
    return math.floor(l+.5),math.floor(t+.5),math.floor(w+.5),math.floor(h+.5)
end
local function round(v) return math.floor(v+.5) end
local function checkPlate(frame)
    local d=pixel(frame);local plate=frame.flatPlate
    -- The frame's own rectangle, rounded to whole pixels; it may end between pixels.
    local L,Tp=round(frame:GetLeft()/d),round(frame:GetTop()/d)
    local R,B=round((frame:GetLeft()+frame:GetWidth())/d),round((frame:GetTop()-frame:GetHeight())/d)
    local function at(region,l,t,w,h)
        local a,b,c,e=pixels(region,d);eq(a,l);eq(b,t);eq(c,w);eq(e,h)
    end
    at(plate.fill,L,Tp,R-L,Tp-B)
    at(plate.line.top,L,Tp,R-L,1);at(plate.line.bottom,L,B+1,R-L,1)
    at(plate.line.left,L,Tp-1,1,Tp-B-2);at(plate.line.right,R-1,Tp-1,1,Tp-B-2)
    at(plate.band.top,L+1,Tp-1,R-L-2,1);at(plate.band.bottom,L+1,B+2,R-L-2,1)
    at(plate.band.left,L+1,Tp-2,1,Tp-B-4);at(plate.band.right,R-2,Tp-2,1,Tp-B-4)
end

test('lines and band sit on whole pixels at the frame edges, also between pixels',function()
    ui:ApplyTheme('forever');A:SetView('expanded');ui:ToggleMenu()
    -- 1440 pixels at UI scale 1 is 1.875 pixels per unit: 276 units end on half a pixel.
    -- 1.5 and 1.25 pixels per unit put the dividers' own anchors on half pixels.
    local dividers={}
    for _,o in ipairs(Mock.objects) do
        if o.kind=='Texture' and o.texturePath=='Interface\\Buttons\\WHITE8X8' and (o.width==286 or o.width==272 or o.height==26) then dividers[#dividers+1]=o end
    end
    eq(#dividers,5)
    local function onPixels()
        -- Across the divider: a whole pixel, exactly one. Along it, its ends may fall between pixels.
        for _,t in ipairs(dividers) do
            local d=pixel(t)
            local edge,size=t:GetTop()/d,t:GetHeight()/d
            if t.height==26 then edge,size=t:GetLeft()/d,t:GetWidth()/d end
            near(edge,math.floor(edge+.5));near(size,1)
        end
        for _,grip in ipairs({ui.grip,ui.panelGrip}) do for _,t in ipairs(grip.squares) do pixels(t,pixel(grip)) end end
    end
    for _,setup in ipairs({{1080,1,1},{1440,1,1},{1440,.64,1.5},{2160,1.15,.75},{1440,.8,1},{1080,768/1080,1.5},{1080,768/1080,1.25}}) do
        Mock.physicalHeight=setup[1];UIParent:SetScale(setup[2]);A:SetScale(setup[3])
        for _,opensUp in ipairs({false,true}) do
            ui.menuOpensUp=opensUp;ui:PositionMenus()
            checkPlate(ui.panel);checkPlate(ui.menu)
        end
        onPixels()
    end
    A:SetView('compact');ui:PositionMenus();checkPlate(ui.bar);checkPlate(ui.menu);onPixels()
    -- Wells: ground and outline on the same whole-pixel rectangle.
    for _,b in ipairs({ui.barMode,ui.rows.master.iconButton,ui.rows.master.slider.track}) do
        local d=pixel(b);local w=b.flatWell
        local l,t,width,height=pixels(w.ground,d)
        local tl,tt,tw,th=pixels(w.line.top,d);eq(tl,l);eq(tt,t);eq(tw,width);eq(th,1)
        local bl,bt=pixels(w.line.bottom,d);eq(bl,l);eq(bt,t-height+1)
        local rl=pixels(w.line.right,d);eq(rl,l+width-1)
    end
    ui:CloseMenus();Mock.physicalHeight=saved.height;UIParent:SetScale(saved.parent);A:SetScale(saved.scale);A:SetView(saved.view)
end)

test('scale and display events measure the lines again',function()
    ui:ApplyTheme('forever');A:SetView('compact')
    Mock.physicalHeight=1440;A.events:Fire('OnEvent','DISPLAY_SIZE_CHANGED');ui.watch:Fire('OnUpdate',0)
    near(ui.bar.flatPlate.line.top.height,pixel(ui.bar));checkPlate(ui.bar)
    UIParent:SetScale(.64);ui.watch:Fire('OnUpdate',0);near(ui.bar.flatPlate.line.top.height,pixel(ui.bar))
    A.events:Fire('OnEvent','UI_SCALE_CHANGED');ui.watch:Fire('OnUpdate',0);checkPlate(ui.bar)
    Mock.physicalHeight=saved.height;UIParent:SetScale(saved.parent);ui.watch:Fire('OnUpdate',0)
    near(ui.bar.flatPlate.line.top.height,pixel(ui.bar));A:SetView(saved.view)
end)

test('dividers of the panel: one pixel high under Forever, their units under the sprites',function()
    ui:ApplyTheme('forever');local d=pixel(ui.panel)
    local header,row
    for _,o in ipairs(Mock.objects) do
        if o.kind=='Texture' and o.texturePath=='Interface\\Buttons\\WHITE8X8' then
            if o.parent==ui.panel and o.width==286 then header=o end
            if o.parent==ui.rows.master and o.width==272 then row=o end
        end
    end
    assert(header and row,'header and row dividers')
    near(header.height,d);color(header.color,rgb(166,160,148),.35);near(row.height,d);color(row.color,rgb(166,160,148),.18)
    ui:ApplyTheme('soundstone');eq(header.height,1);eq(row.height,.6);color(header.color,{.67,.64,.56},.55);color(row.color,{.55,.52,.45},.3)
end)

test('the soundstone palette is exactly 0.3.8',function()
    local S=T.palettes.soundstone
    color(S.text,{.96,.94,.87});color(S.title,{1,.81,.26});color(S.footer,{.96,.94,.87});eq(S.footerAlpha,.55)
    color(S.gear,{.9,.8,.57});color(S.gearHover,{1,1,1});color(S.gearPressed,{.6,.55,.4})
    color(S.divider,{.58,.43,.19},.65);color(S.headerRule,{.67,.64,.56},.55);color(S.rowRule,{.55,.52,.45},.3)
end)

test('Forever is recognized by its project alone and by its interface alone',function()
    local id,camelot,interface=WOW_PROJECT_ID,WOW_PROJECT_CAMELOT,Mock.interface
    WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18;Mock.interface=120105;eq(A.Compat.IsForever(),true)
    WOW_PROJECT_CAMELOT=nil;WOW_PROJECT_ID=1;Mock.interface=16001;eq(A.Compat.IsForever(),true)
    Mock.interface=120105;eq(A.Compat.IsForever(),false)
    WOW_PROJECT_ID,WOW_PROJECT_CAMELOT,Mock.interface=id,camelot,interface
end)

test('Forever lines follow every scale change, one physical pixel each',function()
    ui:ApplyTheme('forever')
    for _,height in ipairs({1080,1440,2160}) do
        for _,parentScale in ipairs({.53,.64,.7,1,1.15}) do
            for _,scale in ipairs({.75,1,1.5}) do
                Mock.physicalHeight=height;UIParent:SetScale(parentScale);A:SetScale(scale)
                local d=768/height/(parentScale*scale)
                near(pixel(ui.bar),d);near(ui.bar.flatPlate.line.top.height,d);near(ui.menu.flatPlate.band.left.width,d)
                near(ui.barMode.flatWell.line.bottom.height,d)
                near(ui.rows.master.slider.track.flatWell.line.top.height,d)
            end
        end
    end
    Mock.physicalHeight=saved.height;UIParent:SetScale(saved.parent);A:SetScale(saved.scale)
end)

test('dividers become one physical pixel and keep their units under the sprites',function()
    ui:ApplyTheme('forever');local d=pixel(ui.bar)
    local sep=ui.barControls.sfx;local found
    for _,o in ipairs(Mock.objects) do
        if o.parent==sep and o.kind=='Texture' and o.texturePath=='Interface\\Buttons\\WHITE8X8' then found=o end
    end
    assert(found,'channel divider');near(found.width,d);eq(found.height,26);color(found.color,rgb(104,80,52))
    ui:ApplyTheme('soundstone');near(found.width,.6);eq(found.height,26);color(found.color,{.58,.43,.19},.65)
end)

test('Forever text: client gold on titles and section labels, warm white elsewhere',function()
    ui:ApplyTheme('soundstone');NORMAL_FONT_COLOR={GetRGB=function() return 1,.8235,0 end};ui:ApplyTheme('forever')
    for _,f in ipairs({ui.panelTitle,ui.menuTitle,ui.outputLabel,ui.scaleLabel}) do color(f.textColor,{1,.8235,0}) end
    for _,f in ipairs({ui.barControls.master.value,ui.rows.music.name,ui.rows.sfx.value,ui.scaleValue}) do color(f.textColor,rgb(240,233,218)) end
    color(ui.version.textColor,rgb(166,160,148));eq(ui.footer.alpha,.85)
    ui:ApplyTheme('soundstone');NORMAL_FONT_COLOR=nil;ui:ApplyTheme('forever')
    color(ui.panelTitle.textColor,{1,210/255,0})
    ui:ApplyTheme('soundstone');color(ui.panelTitle.textColor,{1,.81,.26});color(ui.version.textColor,{.96,.94,.87});eq(ui.footer.alpha,.55)
end)

test('Forever controls: wells, gear and Expand states, grip squares',function()
    ui:ApplyTheme('forever')
    local b=ui.barMode;eq(b.plate.shown,false);eq(b.flatWell.ground.shown,true);color(b.flatWell.ground.color,rgb(10,8,6))
    b:Fire('OnLeave');color(b.flatWell.line.top.color,rgb(104,80,52))
    b:Fire('OnEnter');color(b.flatWell.line.top.color,rgb(240,204,140));eq(b.image.color[1],1)
    b:Fire('OnMouseDown','LeftButton');color(b.flatWell.line.left.color,rgb(240,204,140));eq(b.image.color[1],.7)
    b:Fire('OnMouseUp','LeftButton');b:Fire('OnLeave');color(b.flatWell.line.top.color,rgb(104,80,52))
    for _,g in ipairs({ui.barSettings,ui.panelSettings}) do
        g:Fire('OnLeave');color(g.image.color,rgb(166,160,148))
        g:Fire('OnEnter');color(g.image.color,rgb(240,204,140))
        g:Fire('OnMouseDown');color(g.image.color,rgb(111,107,99));g:Fire('OnMouseUp');g:Fire('OnLeave')
    end
    for _,row in pairs(ui.rows) do
        eq(row.iconButton.flatWell.ground.shown,true)
        for _,p in ipairs(row.iconButton.skinPieces or {}) do eq(p.t.shown,false) end
        eq(row.slider.track.flatWell.ground.shown,true)
    end
    for _,grip in ipairs({ui.grip,ui.panelGrip}) do
        for _,t in ipairs(grip.rivets) do eq(t.shown,false) end
        eq(#grip.squares,6);for _,t in ipairs(grip.squares) do eq(t.shown,true);assert(t.width>=pixel(grip)-.00001) end
    end
    -- A switch under the pointer keeps the gear's hover tint.
    ui.barSettings:Fire('OnEnter');ui:ApplyTheme('soundstone');color(ui.barSettings.image.color,{1,1,1})
    ui:ApplyTheme('forever');color(ui.barSettings.image.color,rgb(240,204,140));ui.barSettings:Fire('OnLeave')
    ui:ApplyTheme('soundstone');b:Fire('OnLeave');assert(b.plate.texturePath:find('ActionNormal.tga',1,true));eq(b.plate.shown,true)
    ui.barSettings:Fire('OnLeave');color(ui.barSettings.image.color,{.9,.8,.57})
end)

test('the slider thumb is the client atlas on Forever and the sprite otherwise',function()
    local sprite=A.Compat.RetailStyle() and 'GoldThumb' or 'SilverThumb'
    local function isSprite(s)
        local thumb=s:GetThumbTexture();eq(thumb.atlas,nil);assert(thumb.texturePath:find(sprite..'.tga',1,true))
        eq(thumb.width,10);eq(thumb.height,18);eq(thumb.layer,'OVERLAY');eq(thumb.sublevel,7);eq(thumb.uv[1],A.Assets[sprite].uv[1])
    end
    ui:ApplyTheme('soundstone');Mock.atlases=nil;ui:ApplyTheme('forever')
    for _,s in ipairs(ui.sliders) do isSprite(s) end
    ui:ApplyTheme('soundstone');Mock.atlases={Minimal_SliderBar_Button={width=20,height=20}};ui:ApplyTheme('forever')
    if C_Texture then
        for _,s in ipairs(ui.sliders) do local thumb=s:GetThumbTexture();eq(thumb.atlas,'Minimal_SliderBar_Button');eq(thumb.uv,nil);eq(thumb.width,20);eq(thumb.layer,'OVERLAY') end
    else
        for _,s in ipairs(ui.sliders) do isSprite(s) end
    end
    ui:ApplyTheme('soundstone');for _,s in ipairs(ui.sliders) do isSprite(s) end
    Mock.atlases=nil
end)

test('a switch during a drag and a placement check sizes lines and keeps both running',function()
    ui:ApplyTheme('soundstone');A.db.locked=false;A:SetView('compact')
    -- A new scale first, so lines measured before the drag would be wrong.
    A:SetScale(1.5)
    Mock.leftMouseDown=true;ui:StartDrag();eq(ui.dragging,true)
    ui:ApplyTheme('forever');eq(ui.dragging,true);near(ui.bar.flatPlate.line.top.height,768/(Mock.physicalHeight or 1080)/1.5)
    Mock.leftMouseDown=false;ui:StopDrag();Mock.finishPlacement()
    ui:ApplyTheme('soundstone');A.db.avoidOverlap=true;A:SetView('compact');A:SetView('expanded')
    local job=ui.placementJob;assert(job,'placement check running')
    ui:ApplyTheme('forever');eq(ui.placementJob,job);Mock.finishPlacement()
    ui:ApplyTheme('soundstone');A:SetScale(saved.scale);A:SetView(saved.view)
end)

test('the look follows the client: no theme command, no saved choice',function()
    ui:ApplyTheme();local look=Mock.expectForever and 'forever' or 'soundstone';eq(ui.themeName,look)
    for _,word in ipairs({'theme','theme forever','theme soundstone','theme auto'}) do
        local messages=#Mock.messages;A:Command(word)
        eq(#Mock.messages,messages+1);assert(Mock.messages[#Mock.messages]:find(A.L.BAD_COMMAND,1,true))
        eq(ui.themeName,look);eq(A.db.theme,nil)
    end
    assert(not A.L.HELP:find('theme',1,true));eq(A.SetTheme,nil);eq(A.Theme.choices,nil)
end)

test('a secret effective scale falls back to one unit',function()
    issecretvalue=function() return true end
    eq(T.Pixel(ui.bar),1)
    issecretvalue=nil;near(T.Pixel(ui.bar),pixel(ui.bar))
end)

-- Forever's own frames: the client's art, on the Forever client only.
local function withArt(fn)
    ui:ApplyTheme('soundstone');Mock.atlases=Mock.foreverAtlases;ui:ApplyTheme('forever')
    fn()
    ui:ApplyTheme('soundstone');Mock.atlases=nil
end
local function point(region,i) return {region:GetPoint(i)} end
local function anchored(region,i,expected)
    local p=point(region,i)
    for k=1,5 do
        if type(expected[k])=='number' then near(p[k],expected[k]) else eq(p[k],expected[k]) end
    end
end

test('the window frame, track and icon frames come only on Forever and only with its art',function()
    withArt(function()
        if not Mock.expectForever then
            -- Other clients ship other art under these names: the look stays flat.
            eq(ui.art.window,nil);eq(ui.windowsBuilt,nil);eq(ui.bar.window,nil)
            for _,frame in ipairs(plates) do eq(frame.flatPlate.fill.shown,true);eq(frame.flatPlate.edge.shown,true) end
            for _,s in ipairs(ui.sliders) do eq(s.track.art,nil) end
            eq(ui.rows.master.iconButton.slot,nil);eq(ui.close.shown,true);return
        end
        eq(ui.art.window,true);eq(ui.art.track,true);eq(ui.art.slot,true)
        for _,frame in ipairs({ui.panel,ui.menu}) do
            local w=frame.window;local border=w.border
            eq(border.shown,true);eq(border.level,frame.level+10);eq(border.mouse,false)
            anchored(border,1,{'TOPLEFT',-4.4,-3.35});anchored(border,2,{'BOTTOMRIGHT',.5,.35})
            eq(border.TopLeftCorner.atlas,'UI-Frame-Metal-CornerTopLeft');eq(border.RightEdge.atlas,'!UI-Frame-Metal-EdgeRight')
            eq(w.ground.texturePath,'Interface\\FrameGeneral\\UI-Background-Rock');eq(w.ground.horizTile,true);eq(w.ground.vertTile,true)
            eq(w.streaks.atlas,'_UI-Frame-TopTileStreaks');eq(w.streaks.shown,true);eq(w.streaks.height,43)
            eq(w.ground.layer,'BACKGROUND');eq(w.ground.sublevel,-6);eq(w.streaks.sublevel,-5)
            anchored(w.ground,1,{'TOPLEFT',border,'TOPLEFT',7,-21});anchored(w.ground,2,{'BOTTOMRIGHT',border,'BOTTOMRIGHT',-2,2})
            anchored(w.streaks,1,{'TOPLEFT',border,'TOPLEFT',6,-21});anchored(w.streaks,2,{'TOPRIGHT',border,'TOPRIGHT',-2,-21})
            eq(frame.flatPlate.fill.shown,false);eq(frame.flatPlate.edge.shown,false)
            -- The opaque metal ends on the frame's own edges.
            near(border:GetLeft()+4.4,frame:GetLeft());near(border:GetTop()+3.35,frame:GetTop())
        end
        local c=ui.frameControls;local border=ui.panel.window.border
        for _,b in ipairs({ui.close,ui.panelMode,ui.panelHide,ui.panelSettings,ui.panelGrip,ui.headerRule,ui.menuTitle,ui.menuSpriteClose}) do eq(b.shown,false) end
        for _,b in pairs(c) do eq(b.shown,true);eq(b.level,ui.panel.level+12) end
        eq(c.close.width,28);eq(c.close.height,28);anchored(c.close,1,{'TOPRIGHT',border,'TOPRIGHT',0,3})
        eq(c.close.normalAtlas,'RedButton-Exit');eq(c.close.pushedAtlas,'RedButton-exit-pressed');eq(c.close.highlightAtlas[1],'RedButton-Highlight')
        for _,b in ipairs({c.mode,c.hide,c.settings}) do eq(b.template,'UIPanelButtonTemplate');eq(b.width,32);eq(b.height,22);color(b.symbol.color,rgb(255,230,128));anchored(b.symbol,1,{'CENTER',0,-.8}) end
        anchored(c.mode,1,{'TOPRIGHT',border,'TOPRIGHT',-28,1});anchored(c.hide,1,{'TOPRIGHT',c.mode,'TOPLEFT',0,0});anchored(c.settings,1,{'TOPLEFT',border,'TOPLEFT',8,1})
        eq(c.settings.symbol.texturePath,'Interface\\WorldMap\\GEAR_64GREY')
        eq(ui.menuClose.shown,true);eq(ui.menuTitleFrame.shown,true);eq(ui.menuTitleFrame.level,ui.menu.level+12);color(ui.menuFrameTitle.textColor,{1,210/255,0})
        anchored(ui.menuClose,1,{'TOPRIGHT',ui.menu.window.border,'TOPRIGHT',0,3});eq(ui.menuClose.level,ui.menu.level+12);eq(ui.menuClose.normalAtlas,'RedButton-Exit')
        anchored(ui.menuFrameTitle,1,{'TOP',ui.menu.window.border,'TOP',0,-6});eq(ui.menuFrameTitle.textValue,A.L.SETTINGS)
        -- The title strip drags the window and carries the title above the frame.
        eq(ui.panelHeader.level,ui.panel.level+12);near(ui.panelHeader:GetLeft(),c.settings:GetLeft()+32);near(ui.panelHeader:GetLeft()+ui.panelHeader:GetWidth(),c.hide:GetLeft())
        eq(ui.panelTitle.fontSize<=12,true);assert(ui.panelTitle:GetStringWidth()<=ui.panelHeader:GetWidth()-4)
        -- At the default scale the whole title fits the strip, near the client's window-title size
        -- (the double's font metrics run wide, so it may take half a size less here).
        eq(ui.panelTitle.textValue,'Soundstone – Azeroth Audio');assert(ui.panelTitle.fontSize>=11)
        anchored(ui.panelTitle,1,{'TOP',ui.panelHeader,'TOP',0,-7})
        -- Rows of 37 below the separator, the footer above the bottom band; the options move with them.
        for i,id in ipairs({'master','sfx','music'}) do near(ui.panel:GetTop()-ui.rows[id]:GetTop(),30+(i-1)*37);eq(ui.rows[id].height,37) end
        near(ui.footer:GetTop()-ui.footer:GetHeight()-(ui.panel:GetTop()-ui.panel:GetHeight()),10)
        near(ui.panel:GetLeft()+ui.panel:GetWidth()-(ui.footer:GetLeft()+ui.footer:GetWidth()),12)
        near(ui.menu:GetTop()-ui.outputLabel:GetTop(),32);near(ui.menu:GetTop()-ui.scaleLabel:GetTop(),73);near(ui.menu:GetTop()-ui.scaleSlider:GetTop(),85)
        near(ui.menu:GetTop()-ui.resetSize:GetTop(),181)
        near(ui.menu:GetTop()-ui.resetPosition:GetTop()+ui.resetPosition:GetHeight(),224)
        for i,key in ipairs({'showMinimap','locked','avoidOverlap'}) do near(ui.menu:GetTop()-ui.checks[key]:GetTop(),107+(i-1)*23) end
        -- The bar: the same frame's band on its own edges, the windows' ground, its content inside the band.
        local w=ui.bar.window;local band=w.border
        eq(band.shown,true);eq(band.level,ui.bar.level+10);eq(band.mouse,false)
        anchored(band,1,{'TOPLEFT',-4.4,-3.35});anchored(band,2,{'BOTTOMRIGHT',.5,.35})
        eq(ui.bar.flatPlate.fill.shown,false);eq(ui.bar.flatPlate.edge.shown,false)
        eq(w.ground.texturePath,'Interface\\FrameGeneral\\UI-Background-Rock');eq(w.ground.sublevel,-6)
        anchored(w.ground,1,{'TOPLEFT',band,'TOPLEFT',7,-2});anchored(w.ground,2,{'BOTTOMRIGHT',band,'BOTTOMRIGHT',-2,2})
        eq(w.streaks.height,4);eq(w.streaks.sublevel,-5);anchored(w.streaks,1,{'TOPLEFT',band,'TOPLEFT',6,-2.8})
        for _,ctrl in pairs(ui.barControls) do if ctrl.rule then eq(ctrl.rule.shown,true) end;eq(ctrl.width,64);eq(ctrl.height,28) end
        anchored(ui.grip,1,{'LEFT',5,0})
        -- Gear and Expand as the mixer header's red buttons; the sprite-look buttons give way.
        local bc=ui.barFrameControls;eq(ui.barSettings.shown,false);eq(ui.barMode.shown,false)
        -- Symbols on the button art's centre, 0.8 units below the rectangle's.
        for _,b in pairs(bc) do eq(b.shown,true);eq(b.template,'UIPanelButtonTemplate');eq(b.width,24);eq(b.height,22);color(b.symbol.color,rgb(255,230,128));anchored(b.symbol,1,{'CENTER',0,-.8}) end
        anchored(bc.settings,1,{'LEFT',25,1});anchored(bc.mode,1,{'LEFT',49,1})
        eq(bc.settings.symbol.texturePath,'Interface\\WorldMap\\GEAR_64GREY');eq(bc.settings.symbol.width,15)
        assert(bc.mode.symbol.texturePath:find('Expand.tga',1,true));eq(bc.mode.symbol.width,14)
        near(bc.settings:GetLeft()+24,bc.mode:GetLeft());assert(bc.mode:GetLeft()+24<ui.barControls.master:GetLeft()+.0001)
        for i,id in ipairs({'master','sfx','music'}) do anchored(ui.barControls[id],1,{'LEFT',75+(i-1)*64,-.5}) end
        -- The last value ends before the band's inner shade (6.1 units of band, about 2.3 of shade on the right).
        local last=ui.barControls.music;assert(last:GetLeft()+24+38<=ui.bar:GetLeft()+ui.bar:GetWidth()-8.4+.0001)
        for _,ctrl in pairs(ui.barControls) do anchored(ctrl.value,1,{'LEFT',24,0});near(ctrl:GetLeft()+ctrl:GetWidth()-(ctrl.value:GetLeft()+ctrl.value:GetWidth()),2) end
        assert(ui.grip:GetLeft()>=ui.bar:GetLeft()+5)
        -- Tracks: the client's three pieces at atlas height, the fill clear of the rounded ends.
        for _,s in ipairs(ui.sliders) do
            eq(s.track.art.left.atlas,'Minimal_SliderBar_Left');eq(s.track.art.middle.shown,true);eq(s.track.height,11)
            eq(s.track.flatWell.ground.shown,false);anchored(s.fill,1,{'LEFT',s,'LEFT',4,0});anchored(s.fill,2,{'RIGHT',s,'RIGHT',-4,0})
        end
        -- Icon frames: normal at rest, highlight on hover, pushed while held.
        local b=ui.rows.master.iconButton;local slot=b.slot
        eq(b.flatWell.ground.shown,false);eq(slot.normal.atlas,'UI-HUD-ActionBar-IconFrame');near(slot.normal.width,25*46/45)
        eq(slot.normal.shown,true);eq(slot.pushed.shown,false);eq(slot.highlight.shown,false);eq(slot.highlight.blend,'ADD')
        b:Fire('OnEnter');eq(slot.highlight.shown,true)
        b:Fire('OnMouseDown','LeftButton');eq(slot.pushed.shown,true);eq(slot.normal.shown,false)
        b:Fire('OnMouseUp','LeftButton');b:Fire('OnLeave');eq(slot.normal.shown,true);eq(slot.highlight.shown,false);eq(slot.pushed.shown,false)
        -- Hidden while held: no pushed art when it shows again.
        b:Fire('OnEnter');b:Fire('OnMouseDown','LeftButton');b:Fire('OnHide');b:Fire('OnEnter')
        eq(slot.pushed.shown,false);eq(slot.normal.shown,true);eq(slot.highlight.shown,true);b:Fire('OnLeave')
        -- Released outside the game window: the next hover finds the button up.
        Mock.leftMouseDown=true;b:Fire('OnEnter');b:Fire('OnMouseDown','LeftButton');b:Fire('OnLeave')
        Mock.leftMouseDown=false;b:Fire('OnEnter');eq(slot.pushed.shown,false);eq(slot.normal.shown,true);b:Fire('OnLeave')
        -- An unavailable channel's button shows no pushed art.
        b:SetEnabled(false);b:Fire('OnEnter');b:Fire('OnMouseDown','LeftButton');eq(slot.pushed.shown,false)
        b:Fire('OnMouseUp','LeftButton');b:Fire('OnLeave');b:SetEnabled(true)
    end)
end)

test('the bar wears the window frame cut to its band, from Blizzard\'s own pieces',function()
    if not Mock.expectForever then return end
    withArt(function()
        local band=ui.bar.window.border;local p=band.pieces;local L=NineSliceLayouts.ButtonFrameTemplateNoPortrait
        local function rows(t,from,to,height) eq(t.uv[1],0);eq(t.uv[2],1);near(t.uv[3],from/height);near(t.uv[4],to/height) end
        -- Top pieces: from 5 units above the box's top to 3 below it, at the layout's own offsets.
        eq(p.topLeft.atlas,L.TopLeftCorner.atlas);rows(p.topLeft,11,19,74);eq(p.topLeft.width,75);eq(p.topLeft.height,8)
        anchored(p.topLeft,1,{'TOPLEFT',band,'TOPLEFT',-8,5})
        eq(p.topRight.atlas,L.TopRightCorner.atlas);rows(p.topRight,11,19,74);anchored(p.topRight,1,{'TOPRIGHT',band,'TOPRIGHT',2,5})
        eq(p.top.atlas,L.TopEdge.atlas);rows(p.top,11,19,74);eq(p.top.height,8);eq(p.top.horizTile,true)
        anchored(p.top,1,{'TOPLEFT',p.topLeft,'TOPRIGHT'});anchored(p.top,2,{'TOPRIGHT',p.topRight,'TOPLEFT'})
        -- Bottom corners: their lowest 16 units (8 below the box, 8 above it); the bottom edge as far as it goes.
        eq(p.bottomLeft.atlas,L.BottomLeftCorner.atlas);rows(p.bottomLeft,64,80,80);eq(p.bottomLeft.height,16)
        anchored(p.bottomLeft,1,{'BOTTOMLEFT',band,'BOTTOMLEFT',-8,-8});anchored(p.bottomRight,1,{'BOTTOMRIGHT',band,'BOTTOMRIGHT',2,-8})
        eq(p.bottom.atlas,L.BottomEdge.atlas);rows(p.bottom,4,20,20);eq(p.bottom.height,16);eq(p.bottom.horizTile,true)
        anchored(p.bottom,1,{'BOTTOMLEFT',p.bottomLeft,'BOTTOMRIGHT'});anchored(p.bottom,2,{'BOTTOMRIGHT',p.bottomRight,'BOTTOMLEFT'})
        eq(p.topRight.width,75);eq(p.topRight.height,8)
        eq(p.bottomRight.atlas,L.BottomRightCorner.atlas);rows(p.bottomRight,64,80,80);eq(p.bottomRight.width,75);eq(p.bottomRight.height,16)
        -- Sides between them, tiled as the layout's atlases say.
        eq(p.left.atlas,L.LeftEdge.atlas);eq(p.left.vertTile,true);eq(p.left.width,16);eq(p.right.atlas,L.RightEdge.atlas)
        anchored(p.left,1,{'TOPLEFT',p.topLeft,'BOTTOMLEFT'});anchored(p.left,2,{'BOTTOMLEFT',p.bottomLeft,'TOPLEFT'});rows(p.left,0,32,32)
        eq(p.right.vertTile,true);eq(p.right.width,16);rows(p.right,0,32,32)
        anchored(p.right,1,{'TOPRIGHT',p.topRight,'BOTTOMRIGHT'});anchored(p.right,2,{'BOTTOMRIGHT',p.bottomRight,'TOPRIGHT'})
        near(p.right:GetHeight(),36-3.35-.35-3-8)
        near(p.left:GetHeight(),36-3.35-.35-3-8)
        -- The band's inner edges as measured on Forever's windows: the opaque metal ends on the bar's edges.
        near(band:GetLeft()+4.4,ui.bar:GetLeft());near(band:GetTop()+3.35,ui.bar:GetTop())
        near(band:GetLeft()+band:GetWidth()-.5,ui.bar:GetLeft()+ui.bar:GetWidth())
        for _,t in pairs(p) do eq(t.layer,'OVERLAY');eq(t.parent,band) end
        -- Its pieces cut too short: the whole frame look stays flat.
        local short={};for k,v in pairs(Mock.foreverAtlases) do short[k]=v end
        short['_UI-Frame-Metal-EdgeTop']={width=32,height=18,tilesHorizontally=true}
        ui:ApplyTheme('soundstone');Mock.atlases=short;ui:ApplyTheme('forever');eq(ui.art.window,false)
        eq(ui.bar.window.border.shown,false);eq(ui.bar.flatPlate.edge.shown,true);eq(ui.panel.flatPlate.edge.shown,true)
        anchored(ui.grip,1,{'LEFT',3,0});eq(ui.barControls.music.width,68)
        -- Each piece the cut reads must reach exactly as far as the cut: at its need it frames, one unit less it does not.
        for key,need in pairs({['UI-Frame-Metal-CornerTopLeft']=19,['UI-Frame-Metal-CornerTopRight']=19,['_UI-Frame-Metal-EdgeTop']=19,
                ['UI-Frame-Metal-CornerBottomLeft']=16,['UI-Frame-Metal-CornerBottomRight']=16}) do
            for _,h in ipairs({need,need-1}) do
                local set={};for k,v in pairs(Mock.foreverAtlases) do set[k]=v end
                local info={};for k,v in pairs(Mock.foreverAtlases[key]) do info[k]=v end;info.height=h;set[key]=info
                ui:ApplyTheme('soundstone');Mock.atlases=set;ui:ApplyTheme('forever');eq(ui.art.window,h==need)
                eq(ui.bar.window.border.shown,h==need);eq(ui.bar.flatPlate.edge.shown,h~=need)
            end
        end
    end)
end)

test('the frame controls do what the sprite controls do',function()
    if not Mock.expectForever then return end
    withArt(function()
        local c=ui.frameControls
        A:SetView('expanded');c.close:Fire('OnClick','LeftButton');eq(A.db.viewMode,'compact')
        A:SetView('expanded');c.mode:Fire('OnClick','LeftButton');eq(A.db.viewMode,'compact')
        A:SetView('expanded');c.settings:Fire('OnClick','LeftButton');eq(ui.menu:IsShown(),true)
        ui.menuClose:Fire('OnClick','LeftButton');eq(ui.menu:IsShown(),false)
        c.close:Fire('OnEnter');eq(Mock.tooltip.owner,c.close);eq(Mock.tooltip.text,A.L.COMPACT);eq(Mock.tooltip.line,'Esc');c.close:Fire('OnLeave')
        c.hide:Fire('OnEnter');eq(Mock.tooltip.text,A.L.HIDE);c.hide:Fire('OnLeave');eq(Mock.tooltip.shown,false)
        c.hide:Fire('OnClick','LeftButton');eq(A.db.showBar,false);A:SetVisible(true);eq(A.db.showBar,true)
        local bc=ui.barFrameControls
        A:SetView('compact');bc.mode:Fire('OnClick','LeftButton');eq(A.db.viewMode,'expanded')
        A:SetView('compact');bc.settings:Fire('OnClick','LeftButton');eq(ui.menu:IsShown(),true);bc.settings:Fire('OnClick','LeftButton');eq(ui.menu:IsShown(),false)
        bc.mode:Fire('OnEnter');eq(Mock.tooltip.owner,bc.mode);eq(Mock.tooltip.text,A.L.EXPAND);bc.mode:Fire('OnLeave')
        bc.settings:Fire('OnEnter');eq(Mock.tooltip.text,A.L.SETTINGS);bc.settings:Fire('OnLeave');eq(Mock.tooltip.shown,false)
        A:SetView('expanded')
        -- Escape still closes the options first, then the window.
        ui:ToggleMenu();Mock.pressEscape();eq(ui.menu:IsShown(),false);eq(A.db.viewMode,'expanded')
        Mock.pressEscape();eq(A.db.viewMode,'compact')
        A:SetView(saved.view)
    end)
end)

test('framed and back: every sprite-layout region returns exactly, nothing moves',function()
    if not Mock.expectForever then return end
    ui:ApplyTheme('soundstone');A:SetView('expanded');ui:ToggleMenu()
    local before=snapshot();local position=A.db.position;local x,y=ui.root:GetLeft(),ui.root:GetTop()
    Mock.atlases=Mock.foreverAtlases;ui:ApplyTheme('forever');eq(ui.art.window,true)
    near(ui.root:GetLeft(),x);near(ui.root:GetTop(),y);eq(ui.panel.width,300);eq(ui.panel.height,160);eq(ui.menu.height,236)
    -- Without the art again (a later client), the same objects fall back to the flat look.
    ui:ApplyTheme('soundstone');Mock.atlases=nil;ui:ApplyTheme('forever');eq(ui.art.window,nil)
    eq(ui.panel.window.border.shown,false);eq(ui.panel.flatPlate.edge.shown,true);eq(ui.bar.window.border.shown,false);eq(ui.bar.flatPlate.edge.shown,true)
    eq(ui.close.shown,true);eq(ui.frameControls.close.shown,false);eq(ui.rows.master.height,42)
    for _,ctrl in pairs(ui.barControls) do if ctrl.rule then eq(ctrl.rule.shown,true) end end
    ui:ApplyTheme('soundstone');eq(A.db.position,position);near(ui.root:GetLeft(),x);near(ui.root:GetTop(),y)
    local function same(reference)
        local after=snapshot()
        for o,state in pairs(reference) do if o~='shown' then
            eq(o.shown,reference.shown[o])
            if o:IsVisible() then assert(after[o]==state,'changed: '..tostring(o.kind)..' '..state..' -> '..tostring(after[o])) end
        end end
        -- Everything the client art added is out of sight again.
        for _,o in ipairs(Mock.objects) do if reference[o]==nil then assert(not o:IsVisible(),'still visible: '..tostring(o.kind)) end end
    end
    same(before);same(pristine)
    eq(ui.panelHeader.level,ui.panel.level+1);eq(ui.scaleSlider.track.height,8)
    -- The compact bar, the default view, after a framed round trip there.
    ui:CloseMenus();A:SetView('compact')
    Mock.atlases=Mock.foreverAtlases;ui:ApplyTheme('forever');eq(ui.bar.window.border.shown,true);ui:ApplyTheme('soundstone');Mock.atlases=nil
    same(pristineCompact)
    A:SetView(saved.view)
end)

-- Each piece falls back on its own when the client lacks its art.
local function without(names)
    local set={}
    for k,v in pairs(Mock.foreverAtlases) do set[k]=v end
    for _,name in ipairs(names) do set[name]=nil end
    return set
end
test('without part of the art, only that piece falls back to the flat look',function()
    if not Mock.expectForever then return end
    ui:ApplyTheme('soundstone');Mock.atlases=without({'UI-Frame-Metal-CornerTopLeft'});ui:ApplyTheme('forever')
    eq(ui.art.window,false);eq(ui.art.track,true)
    for _,frame in ipairs(plates) do eq(frame.flatPlate.fill.shown,true);eq(frame.flatPlate.edge.shown,true) end
    eq(ui.close.shown,true);eq(ui.panelGrip.shown,true);eq(ui.rows.master.height,42);eq(ui.barControls.master.width,68)
    if ui.windowsBuilt then eq(ui.panel.window.border.shown,false);eq(ui.bar.window.border.shown,false);eq(ui.frameControls.close.shown,false) end
    for _,ctrl in pairs(ui.barControls) do if ctrl.rule then eq(ctrl.rule.shown,true) end end
    ui:ApplyTheme('soundstone');Mock.atlases=without({'Minimal_SliderBar_Right','UI-HUD-ActionBar-IconFrame-Down'});ui:ApplyTheme('forever')
    eq(ui.art.track,false);eq(ui.art.slot,false)
    for _,s in ipairs(ui.sliders) do
        eq(s.track.flatWell.ground.shown,true);eq(s.track.height,8)
        if s.track.art then eq(s.track.art.left.shown,false) end
    end
    local b=ui.rows.master.iconButton;eq(b.flatWell.ground.shown,true)
    if b.slot then eq(b.slot.normal.shown,false);b:Fire('OnEnter');eq(b.slot.highlight.shown,false);b:Fire('OnLeave') end
    ui:ApplyTheme('soundstone');Mock.atlases=nil
end)

test('grabbing the framed window lifts the frame and its controls above the action buttons',function()
    if not Mock.expectForever then return end
    withArt(function()
        A.db.locked=false;A:SetView('expanded')
        Mock.leftMouseDown=true;ui.panelHeader:Fire('OnDragStart');eq(ui.dragging,true)
        local border=ui.panel.window.border
        assert(border.level>500 and ui.frameControls.close.level>border.level and ui.panelHeader.level>border.level,'frame and controls above the buttons')
        Mock.leftMouseDown=false;ui.panelHeader:Fire('OnDragStop');Mock.finishPlacement();eq(ui.dragging,false)
        A:SetView(saved.view)
    end)
end)

ui:ApplyTheme();A:SetScale(saved.scale);A:SetView(saved.view)
return count
