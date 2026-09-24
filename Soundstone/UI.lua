local _, A = ...
local C,L,Layout=A.Compat,A.L,A.Layout
local UI={}; A.UI=UI
local unpack=unpack or table.unpack
local WHITE='Interface\\Buttons\\WHITE8X8'
local MEDIA='Interface\\AddOns\\Soundstone\\Media\\'
local ids={master='Master',sfx='Sfx',music='Music',logo='Logo'}

local function font(parent,text,size,gold)
    local f=parent:CreateFontString(nil,'OVERLAY')
    f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',size or 10,'')
    f:SetTextColor(gold and 1 or .96,gold and .81 or .94,gold and .26 or .87)
    f:SetText(text or ''); return f
end
local function flat(parent,color,width,height)
    local t=parent:CreateTexture(nil,'ARTWORK');t:SetTexture(WHITE)
    t:SetVertexColor(unpack(color));t:SetSize(width,height);return t
end
local function sprite(parent,name,layer)
    local t=parent:CreateTexture(nil,layer or 'ARTWORK')
    t:SetTexture(MEDIA..name..'.tga');t:SetTexCoord(unpack(A.Assets[name].uv))
    return t
end
-- Frame components use fixed-size corners, stretched edges and a separate center.
local function skin(frame,name,cornerOverride)
    frame.skinName=name
    local pieces={}
    for y=1,3 do for x=1,3 do
        local t=frame:CreateTexture(nil,'BACKGROUND')
        pieces[#pieces+1]={t=t,x=x,y=y}
    end end
    frame.skinPieces=pieces
    local function resize()
        local name=frame.skinName
        local meta=A.Assets[name];local u=meta.uv
        local sourceCorner=name:find('Classic') and 52 or 23
        local corner=name:find('Classic') and 10 or 7
        if name=='Toggle' or name=='ToggleRed' then sourceCorner=14;corner=4 end
        corner=cornerOverride or corner
        local du=(u[2]-u[1])*sourceCorner/meta.width
        local dv=(u[4]-u[3])*sourceCorner/meta.height
        local xs={u[1],u[1]+du,u[2]-du,u[2]}
        local ys={u[3],u[3]+dv,u[4]-dv,u[4]}
        local c=C.Pixel(corner,frame);frame.skinCorner=c;local w,h=frame:GetWidth(),frame:GetHeight()
        for _,p in ipairs(pieces) do
            p.t:SetTexture(MEDIA..name..'.tga');p.t:SetTexCoord(xs[p.x],xs[p.x+1],ys[p.y],ys[p.y+1])
            local left=p.x==1 and 0 or (p.x==2 and c or w-c)
            local top=p.y==1 and 0 or (p.y==2 and c or h-c)
            p.t:ClearAllPoints();p.t:SetPoint('TOPLEFT',C.Pixel(left,frame),-C.Pixel(top,frame))
            p.t:SetSize(p.x==2 and math.max(1,w-2*c) or c,p.y==2 and math.max(1,h-2*c) or c)
        end
    end
    function frame:SetSkin(value) if self.skinName~=value then self.skinName=value;resize() end end
    frame:HookScript('OnSizeChanged',resize);frame.Reskin=resize;resize()
end
local function icon(parent,id,size)
    local f=CreateFrame('Frame',nil,parent)
    local name=ids[id];local m=A.Assets[name];local max=math.max(m.width,m.height)
    f.texture=sprite(f,name);f.texture:SetPoint('CENTER')
    function f:SetIconSize(value)
        self:SetSize(value,value);self.texture:SetSize(value*m.width/max,value*m.height/max)
    end
    f:SetIconSize(size)
    function f:SetMuted(value) self.texture:SetDesaturated(value);self.texture:SetAlpha(value and .66 or 1) end
    return f
end
local function hideTip() if GameTooltip then GameTooltip:Hide() end end
local function tip(owner,title,text)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,'ANCHOR_TOP');GameTooltip:SetText(title,1,.82,.3)
    if text then GameTooltip:AddLine(text,.94,.93,.88,true) end;GameTooltip:Show()
end
local function textureButton(parent,name,w,h,text,onClick)
    local b=CreateFrame('Button',nil,parent);b:SetSize(w,h)
    if name=='Toggle' or name=='ToggleRed' then
        skin(b,name)
        b.image={SetVertexColor=function(_,...) for _,p in ipairs(b.skinPieces) do p.t:SetVertexColor(...) end end}
    else b.image=sprite(b,name,'BACKGROUND');b.image:SetAllPoints() end
    b.text=font(b,text,10,true);b.text:SetPoint('CENTER')
    b:SetScript('OnEnter',function() b.image:SetVertexColor(1,.94,.75); end)
    b:SetScript('OnLeave',function() b.image:SetVertexColor(1,1,1);hideTip() end)
    b:SetScript('OnMouseDown',function() b.image:SetVertexColor(.65,.65,.65) end)
    b:SetScript('OnMouseUp',function() b.image:SetVertexColor(1,1,1) end)
    b:SetScript('OnClick',onClick);return b
end
-- Reuse the client's button states, typography and native red/gold treatment.
local function nativeButton(parent,w,h,text,onClick)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(w,h);b:SetText(text or '')
    b.text=b:GetFontString();b.text:ClearAllPoints();b.text:SetPoint('CENTER')
    b.text:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',10,'');b.text:SetWordWrap(false)
    b:SetScript('OnClick',onClick);return b
end
local function actionButton(parent,name,title,onClick)
    local b=CreateFrame('Button',nil,parent);b:SetSize(19,19)
    if name then
        b.plate=sprite(b,'ActionNormal','BACKGROUND');b.plate:SetAllPoints()
        b.image=sprite(b,name);b.image:SetSize(17,17)
        local hovered,pressed=false,false
        local function update()
            local down=hovered and pressed
            local state=down and 'ActionPressed' or (hovered and 'ActionHover' or 'ActionNormal')
            b.plate:SetTexture(MEDIA..state..'.tga')
            local brightness=down and .7 or (hovered and 1 or .9)
            b.image:SetVertexColor(brightness,brightness,brightness)
            b.image:ClearAllPoints();b.image:SetPoint('CENTER',0,down and -1 or 0)
        end
        update()
        b:SetScript('OnEnter',function()
            -- A release outside the button may not deliver its OnMouseUp script.
            if pressed and IsMouseButtonDown and not IsMouseButtonDown('LeftButton') then pressed=false end
            hovered=true;update();tip(b,title)
        end)
        b:SetScript('OnLeave',function() hovered=false;update();hideTip() end)
        b:SetScript('OnMouseDown',function(_,button) if button=='LeftButton' then pressed=true;update() end end)
        b:SetScript('OnMouseUp',function() pressed=false;update() end)
        b:SetScript('OnHide',function() hovered=false;pressed=false;update();hideTip() end)
    else
        b.image=b:CreateTexture(nil,'ARTWORK');b.image:SetTexture('Interface\\WorldMap\\GEAR_64GREY');b.image:SetAllPoints()
        local function normal() b.image:SetVertexColor(.9,.8,.57) end
        normal()
        b:SetScript('OnEnter',function() b.image:SetVertexColor(1,1,1);tip(b,title) end)
        b:SetScript('OnLeave',function() normal();hideTip() end)
        b:SetScript('OnMouseDown',function() b.image:SetVertexColor(.6,.55,.4) end)
        b:SetScript('OnMouseUp',normal)
    end
    b:RegisterForClicks('LeftButtonUp')
    b:SetScript('OnClick',onClick);return b
end
local function gearButton(parent)
    return actionButton(parent,nil,L.SETTINGS,function() UI:ToggleMenu() end)
end
local function headerButton(parent,name,title,onClick,detail)
    local b=CreateFrame('Button',nil,parent);b:SetSize(Layout.headerButton,Layout.headerButton)
    b.image=sprite(b,name);b.image:SetAllPoints()
    local hovered,pressed=false,false
    local function update()
        if hovered and pressed then b.image:SetVertexColor(.65,.65,.65)
        elseif hovered then b.image:SetVertexColor(1,.94,.75)
        else b.image:SetVertexColor(1,1,1) end
    end
    b:SetScript('OnEnter',function()
        if pressed and IsMouseButtonDown and not IsMouseButtonDown('LeftButton') then pressed=false end
        hovered=true;update();tip(b,title,detail)
    end)
    b:SetScript('OnLeave',function() hovered=false;update();hideTip() end)
    b:SetScript('OnMouseDown',function(_,button) if button=='LeftButton' then pressed=true;update() end end)
    b:SetScript('OnMouseUp',function() pressed=false;update() end)
    b:SetScript('OnHide',function() hovered=false;pressed=false;update();hideTip() end)
    b:RegisterForClicks('LeftButtonUp');b:SetScript('OnClick',onClick);update();return b
end
function UI:ChannelTip(owner,id,context)
    local s=A.audio:Get(id)
    local state=s.available and (s.audible and L.ON or L.OFF) or L.UNAVAILABLE
    local lines={state..(s.percent and ' · '..s.percent..'%' or '')}
    if s.reason and s.reason~='OFF' then lines[1]=lines[1]..' — '..L[s.reason] end
    if id=='sfx' and context~='compact' then lines[#lines+1]=L.TIP_SFX end
    lines[#lines+1]=context=='compact' and L.TIP_COMPACT or (context=='slider' and L.TIP_SLIDER or L.TIP_EXPANDED)
    lines[#lines+1]=L.WHEEL_HELP
    tip(owner,L[s.channel.label],table.concat(lines,'\n'))
end
local function wire(target,id,click,context)
    target:EnableMouseWheel(true)
    if click then
        target:RegisterForClicks('LeftButtonUp','RightButtonUp')
        target:SetScript('OnClick',function(_,mouse)
            if mouse=='RightButton' then A:SetView('expanded') else A:Toggle(id) end
        end)
    end
    target:SetScript('OnMouseWheel',function(_,delta) A:Step(id,delta) end)
    target:HookScript('OnEnter',function(self) UI:ChannelTip(self,id,context or (click and 'expanded' or 'slider')) end)
    target:HookScript('OnLeave',hideTip)
end
function UI:CancelPlacement()
    if self.placementJob then
        local job=self.placementJob
        self.placementJob=nil;self.root:SetScript('OnUpdate',nil)
        if A.db.position==job.requested then
            A.db.position=job.origin
        end
    end
end
function UI:FinishDrag()
    self:CancelPlacement()
    A:SavePosition(self.root)
    local origin=self.dragOrigin or A.db.position
    self.dragOrigin=nil;self.dragging=false;self.suppressUntil=C.Now()+.15;self:ApplyLayout()
    self:BeginPlacement(origin)
end
function UI:BeginPlacement(origin,fallbackView)
    if not A.db.avoidOverlap or not self.root:IsShown() then return end
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    local scale=A.db.uiScale
    local job=A.Placement.Start(self.root,A.db.position.x+sw/2,A.db.position.y+sh/2,
        self.root:GetWidth()*scale,self.root:GetHeight()*scale,sw,sh)
    job.origin=origin;job.requested=A.db.position
    job.view=A.db.viewMode;job.scale=A.db.uiScale
    job.sw=sw;job.sh=sh;job.parentScale=UIParent:GetEffectiveScale()
    self.placementJob=job
    self.root:SetScript('OnUpdate',function()
        if UI.placementJob~=job then return end
        local done,x,y,status=job:Step()
        if not done then return end
        UI.placementJob=nil;UI.root:SetScript('OnUpdate',nil);A.Placement.lastStats=job.stats
        if x then A.db.position={x=x-sw/2,y=y-sh/2}
        else
            A.db.position=origin
            if fallbackView then A.db.viewMode=fallbackView end
            A:Print(status=='no-space' and L.NO_FREE_SPACE or L.PLACEMENT_UNAVAILABLE)
        end
        UI:Refresh()
    end)
end
local function movable(handle,menuClick)
    handle:EnableMouse(true);handle:RegisterForDrag('LeftButton')
    handle:SetScript('OnDragStart',function()
        if not A.db.locked then UI:CancelPlacement();UI:ApplyLayout();UI:CloseMenus();UI.dragOrigin={x=A.db.position.x,y=A.db.position.y};UI.root:StartMoving();UI.dragging=true;hideTip() end
    end)
    handle:SetScript('OnDragStop',function()
        UI.root:StopMovingOrSizing()
        if UI.dragging then UI:FinishDrag() end
    end)
    if menuClick then
        handle:SetScript('OnClick',function()
            if not UI.suppressUntil or C.Now()>=UI.suppressUntil then UI:ToggleMenu() end
        end)
    end
end
local function dots(parent,size,gap)
    local result={}
    for row=0,2 do for col=0,1 do
        result[#result+1]=sprite(parent,'Rivet')
    end end
    function parent:AlignDots()
        local d=C.Pixel(size,self);local step=C.Pixel(gap,self)
        local x=C.Pixel((self:GetWidth()-step-d)/2,self)
        local y=C.Pixel((self:GetHeight()-2*step-d)/2,self)
        for i,t in ipairs(result) do
            local col=(i-1)%2;local row=math.floor((i-1)/2)
            t:ClearAllPoints();t:SetSize(d,d);t:SetPoint('TOPLEFT',x+col*step,-y-row*step)
        end
    end
    parent:AlignDots()
    return result
end
function UI:CreateBar()
    local b=CreateFrame('Frame','SoundstoneBar',self.root);self.bar=b
    b:SetSize(Layout.compact.width,Layout.compact.height);b:SetPoint('TOPLEFT');skin(b,self.theme..'Bar')
    local grip=CreateFrame('Button',nil,b);self.grip=grip
    grip:SetSize(19,28);grip:SetPoint('LEFT',3,0);self.gripDots=dots(grip,3.1,5.3)
    movable(grip)
    self.barSettings=gearButton(b);self.barSettings:SetPoint('LEFT',24,0)
    self.barMode=actionButton(b,'Expand',L.EXPAND,function() A:SetView('expanded') end);self.barMode:SetPoint('LEFT',45,0)
    grip:SetScript('OnEnter',function(self) tip(self,'Soundstone',L.DRAG_HELP) end);grip:SetScript('OnLeave',hideTip)
    self.barControls={}
    for i,ch in ipairs(A.Audio.channels) do
        local c=CreateFrame('Button',nil,b);c:SetSize(68,28);c:SetPoint('LEFT',66+(i-1)*68,0)
        c.icon=icon(c,ch.id,22);c.icon:SetPoint('LEFT',4,0)
        c.value=font(c,'',11);c.value:SetPoint('LEFT',31,0);c.value:SetWidth(34);c.value:SetJustifyH('RIGHT');c.value:SetWordWrap(false)
        if i>1 then local sep=flat(c,{.58,.43,.19,.65},.6,26);sep:SetPoint('LEFT',0,0) end
        wire(c,ch.id,true,'compact');self.barControls[ch.id]=c
    end
end
local function slider(parent,width,callback)
    local s=CreateFrame('Slider',nil,parent);s:SetSize(width,20);s:SetOrientation('HORIZONTAL')
    s:SetMinMaxValues(0,100);s:SetValueStep(1)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    -- Decoration sits below the slider frame so it cannot cover its thumb.
    local track=CreateFrame('Frame',nil,parent);track:SetPoint('LEFT',s,'LEFT');track:SetPoint('RIGHT',s,'RIGHT');track:SetHeight(8);skin(track,'Toggle',2)
    local status=CreateFrame('StatusBar',nil,parent);status:SetPoint('LEFT',s,'LEFT',3,0);status:SetPoint('RIGHT',s,'RIGHT',-3,0);status:SetHeight(3)
    track:SetFrameLevel(parent:GetFrameLevel()+1);status:SetFrameLevel(parent:GetFrameLevel()+2);s:SetFrameLevel(parent:GetFrameLevel()+3)
    status:SetStatusBarTexture(WHITE);status:SetStatusBarColor(1,.69,.13);status:SetMinMaxValues(0,100)
    local name=C.RetailStyle() and 'GoldThumb' or 'SilverThumb'
    s:SetThumbTexture(MEDIA..name..'.tga')
    local thumb=s:GetThumbTexture();thumb:SetTexCoord(unpack(A.Assets[name].uv));thumb:SetSize(10,18);thumb:SetDrawLayer('OVERLAY',7);thumb:SetBlendMode('BLEND')
    s:SetScript('OnValueChanged',function(_,value) if not UI.refreshing then callback(value) end end)
    s.fill=status;s.track=track;return s
end
function UI:CreatePanel()
    local p=CreateFrame('Frame','SoundstonePanel',self.root);self.panel=p
    p:SetSize(Layout.expanded.width,Layout.expanded.height);p:SetPoint('TOPLEFT');skin(p,self.theme..'Panel')
    local header=CreateFrame('Button',nil,p);self.panelHeader=header;header:SetPoint('TOPLEFT',72,-4);header:SetSize(156,21);movable(header)
    local title=font(header,'Soundstone – Azeroth Audio',14,true);self.panelTitle=title;title:SetPoint('CENTER')
    local titleSize=14
    while title:GetStringWidth()>152 and titleSize>10 do
        titleSize=titleSize-.5;title:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',titleSize,'')
    end
    if title:GetStringWidth()>152 then title:SetText('Soundstone') end
    title:SetWordWrap(false)
    header:SetScript('OnEnter',function(self) tip(self,'Soundstone – Azeroth Audio',L.DRAG_HELP) end)
    header:SetScript('OnLeave',hideTip)
    self.panelGrip=CreateFrame('Button',nil,p);self.panelGrip:SetSize(16,21);self.panelGrip:SetPoint('TOPLEFT',7,-4)
    self.panelGripDots=dots(self.panelGrip,3.1,5.3);movable(self.panelGrip)
    self.panelGrip:SetScript('OnEnter',function(self) tip(self,'Soundstone',L.DRAG_HELP) end);self.panelGrip:SetScript('OnLeave',hideTip)
    self.panelSettings=gearButton(p);self.panelSettings:SetPoint('TOPLEFT',25,-5)
    local close=headerButton(p,'HeaderClose',L.COMPACT,function() A:SetView('compact') end,'Esc');self.close=close
    close:SetPoint('TOPRIGHT',-5,-4)
    self.panelMode=headerButton(p,'HeaderCompact',L.COMPACT,function() A:SetView('compact') end)
    self.panelMode:SetPoint('RIGHT',close,'LEFT',-Layout.headerGap,0)
    self.panelHide=headerButton(p,'HeaderHide',L.HIDE,function() A:SetVisible(false) end)
    self.panelHide:SetPoint('RIGHT',self.panelMode,'LEFT',-Layout.headerGap,0)
    local separator=flat(p,{.67,.64,.56,.55},286,1);separator:SetPoint('TOPLEFT',7,-27)
    self.rows={}
    for i,ch in ipairs(A.Audio.channels) do
        local row=CreateFrame('Frame',nil,p);row:SetSize(276,42);row:SetPoint('TOPLEFT',12,-29-(i-1)*42)
        row.iconButton=CreateFrame('Button',nil,row);row.iconButton:SetSize(25,25);row.iconButton:SetPoint('LEFT')
        if not C.RetailStyle() then skin(row.iconButton,'ClassicPanel',3) end
        row.icon=icon(row.iconButton,ch.id,18);row.icon:SetPoint('CENTER');wire(row.iconButton,ch.id,true)
        row.name=font(row,L[ch.label],10);row.name:SetPoint('LEFT',30,0);row.name:SetWidth(69);row.name:SetJustifyH('LEFT')
        row.toggle=nativeButton(row,34,20,'',function() A:Toggle(ch.id) end);row.toggle:SetPoint('LEFT',99,0);wire(row.toggle,ch.id,true)
        row.slider=slider(row,98,function(value) A:SetVolume(ch.id,value) end);row.slider:SetPoint('LEFT',143,0)
        row.fill=row.slider.fill;wire(row.slider,ch.id,false)
        row.value=font(row,'',10);row.value:SetPoint('RIGHT');row.value:SetWidth(32);row.value:SetJustifyH('RIGHT')
        if i<3 then local sep=flat(row,{.55,.52,.45,.3},272,.6);sep:SetPoint('BOTTOM',0,0) end
        self.rows[ch.id]=row
    end
    local footer=CreateFrame('Frame',nil,p);self.footer=footer;footer:SetPoint('BOTTOMRIGHT',-10,5);footer:SetAlpha(.55)
    self.version=font(footer,'v'..C.Version(),7.5);self.version:SetSize(self.version:GetStringWidth(),8);self.version:SetPoint('LEFT')
    self.footerHeart=sprite(footer,'Heart');self.footerHeart:SetSize(8,8);self.footerHeart:SetVertexColor(.95,.3,.38);self.footerHeart:SetPoint('LEFT',self.version,'RIGHT',3,0)
    self.author=font(footer,'by krebs3r',7.5);self.author:SetSize(self.author:GetStringWidth(),8);self.author:SetPoint('LEFT',self.footerHeart,'RIGHT',3,0)
    footer:SetSize(self.version:GetWidth()+self.author:GetWidth()+14,8)
end
function UI:SyncEscape()
    if not self.escape then return end
    self.syncEscape=true
    -- The native menu manager consumes Escape itself before special frames.
    local nativeOpen=self.outputDropdown.native and self.outputDropdown:IsOpen()
    self.escape:SetShown(A.db.showBar and not nativeOpen and (A.db.viewMode=='expanded' or self.menu:IsShown()))
    self.syncEscape=false
end
function UI:Escape()
    if self.outputDropdown:IsOpen() then self.outputDropdown:Close()
    elseif self.menu:IsShown() then self.menu:Hide()
    else A:SetView('compact') end
    self:SyncEscape()
end
function UI:CloseMenus()
    if self.menu then self.menu:Hide();self.outputDropdown:Close();self:SyncEscape() end
    hideTip()
end
function UI:ToggleMenu()
    if self.menu:IsShown() then self:CloseMenus() else
        self.menu:Show();self:Refresh();self:RefreshDevices();self:PositionMenus();self:SyncEscape()
    end
end
function UI:ActivePopup()
    return self.menu
end
function UI:PositionMenus()
    if not self.menu then return end
    for _,popup in ipairs({self.menu}) do
        popup:ClearAllPoints()
        local gap=C.Pixel(Layout.menuGap,popup)
        if self.menuOpensUp then popup:SetPoint('BOTTOMLEFT',self.root,'TOPLEFT',0,gap)
        else popup:SetPoint('TOPLEFT',self.root,'BOTTOMLEFT',0,-gap) end
        local scale=A.db.uiScale
        if (self.root:GetHeight()+popup:GetHeight()+Layout.menuGap)*scale>UIParent:GetHeight() then
            local px,py=UIParent:GetCenter()
            local x,y=Layout.Clamp(popup:GetLeft()*scale-px,popup:GetTop()*scale-py,
                popup:GetWidth()*scale,popup:GetHeight()*scale,UIParent:GetWidth(),UIParent:GetHeight())
            popup:ClearAllPoints();popup:SetPoint('TOPLEFT',UIParent,'CENTER',C.Pixel(x/scale,popup),C.Pixel(y/scale,popup))
        end
    end
    if self.outputDropdown then self.outputDropdown:Position() end
end
function UI:ShowScaleValue(percent)
    self.scaleValue:SetText(percent..' %');self.scaleSlider.fill:SetValue((percent-75)/75*100)
end
function UI:CommitScale()
    local pending=self.pendingScale;self.pendingScale=nil
    if pending then A:SetScale(pending/100) end
end
function UI:CancelScale()
    self.pendingScale=nil
    if self.scaleSlider then
        local refreshing=self.refreshing;self.refreshing=true
        self.scaleSlider:SetValue(A.db.uiScale*100);self:ShowScaleValue(math.floor(A.db.uiScale*100+.5));self.refreshing=refreshing
    end
end
function UI:CreateMenu()
    local menu=CreateFrame('Frame','SoundstoneMenu',self.root);self.menu=menu;self.options=menu
    menu:SetSize(Layout.options.width,Layout.options.height);menu:SetFrameStrata('DIALOG');menu:EnableMouse(true);skin(menu,self.theme..'Panel');menu:Hide()
    local width=Layout.options.width-20
    local title=font(menu,L.SETTINGS,12,true);title:SetPoint('TOPLEFT',10,-8)
    local close=textureButton(menu,'Close',18,18,'',function() UI:CloseMenus() end);close:SetPoint('TOPRIGHT',-7,-6)
    local outputLabel=font(menu,L.OUTPUT,10,true);outputLabel:SetPoint('TOPLEFT',10,-31)
    self.outputDropdown=A.Dropdown.New(menu,width,function() UI:SyncEscape() end,tip,hideTip)
    self.deviceButton=self.outputDropdown.field
    self.deviceButton:SetPoint('TOPLEFT',10,-44)
    local scaleLabel=font(menu,L.SIZE,10,true);scaleLabel:SetPoint('TOPLEFT',10,-74)
    self.scaleSlider=slider(menu,width-48,function(value) UI.pendingScale=math.floor(value+.5);UI:ShowScaleValue(UI.pendingScale) end)
    self.scaleSlider:SetMinMaxValues(75,150);self.scaleSlider:SetPoint('TOPLEFT',10,-86)
    self.scaleSlider:SetScript('OnMouseUp',function(_,button) if button=='LeftButton' then UI:CommitScale() end end)
    self.scaleSlider:SetScript('OnHide',function() UI:CancelScale() end)
    self.scaleValue=font(menu,'',10);self.scaleValue:SetPoint('TOPRIGHT',-10,-91)
    self.scaleSlider:SetScript('OnEnter',function(self) tip(self,L.SIZE,L.SCALE_RELEASE) end)
    self.scaleSlider:SetScript('OnLeave',hideTip)
    menu:HookScript('OnHide',function() UI:CancelScale();if UI.root and UI.rows then UI:ApplyLayout() end end)
    self.checks={}
    for i,entry in ipairs({{'showMinimap',L.SHOW_MINIMAP},{'locked',L.LOCK},{'avoidOverlap',L.AVOID_OVERLAP}}) do
        local key=entry[1];local c=CreateFrame('CheckButton',nil,menu,'UICheckButtonTemplate')
        c:SetSize(24,24);c:SetPoint('TOPLEFT',10,-110-(i-1)*24)
        c.label=font(c,entry[2],10);c.label:SetPoint('LEFT',c,'RIGHT',2,0)
        if key=='avoidOverlap' then
            c:SetScript('OnEnter',function(self) tip(self,L.AVOID_OVERLAP,L.AVOID_HELP) end);c:SetScript('OnLeave',hideTip)
        end
        c:SetScript('OnClick',function(self) A.db[key]=self:GetChecked() and true or false;UI:Refresh() end);self.checks[key]=c
    end
    self.resetSize=nativeButton(menu,width,20,L.RESET_SIZE,function() A:SetScale(1) end);self.resetSize:SetPoint('TOPLEFT',10,-186)
    self.resetPosition=nativeButton(menu,width,20,L.RESET,function() A:ResetPositions() end);self.resetPosition:SetPoint('TOPLEFT',10,-210)
end
function UI:RefreshDevices()
    if self.outputDropdown then self.outputDropdown:Refresh() end
end
function UI:ApplyLayout()
    if not self.root then return end
    local job=self.placementJob
    -- Audio refreshes do not invalidate an in-flight placement of the same
    -- geometry. Explicit moves, resize, hide and option changes still cancel it.
    if job and (A.db.position~=job.requested or A.db.viewMode~=job.view or A.db.uiScale~=job.scale
        or UIParent:GetWidth()~=job.sw or UIParent:GetHeight()~=job.sh or UIParent:GetEffectiveScale()~=job.parentScale
        or not A.db.showBar or not A.db.avoidOverlap) then self:CancelPlacement() end
    local view=Layout.View(A.db.viewMode)
    self.root:SetScale(A.db.uiScale);self.root:SetSize(view.width,view.height)
    local x,y=Layout.Clamp(A.db.position.x,A.db.position.y,view.width*A.db.uiScale,view.height*A.db.uiScale,UIParent:GetWidth(),UIParent:GetHeight())
    self.menuOpensUp=false
    local popup=self:ActivePopup()
    if popup and popup:IsShown() then
        y,self.menuOpensUp=Layout.MenuPlacement(y,view.height*A.db.uiScale,popup:GetHeight()*A.db.uiScale,
            C.Pixel(Layout.menuGap,self.menu)*A.db.uiScale,UIParent:GetHeight())
    end
    self.anchorX,self.anchorY=x,y
    self.root:ClearAllPoints();self.root:SetPoint('TOPLEFT',UIParent,'CENTER',C.Pixel(x/A.db.uiScale,self.root),C.Pixel(y/A.db.uiScale,self.root))
    for _,frame in ipairs({self.bar,self.panel,self.menu}) do if frame and frame.Reskin then frame.Reskin() end end
    for _,row in pairs(self.rows) do
        local b=row.iconButton
        if b.Reskin then b:Reskin() end
        -- Reserve the Classic border plus a pixel-aligned gap in both designs.
        local inset=(b.skinCorner or C.Pixel(3,b))+C.Pixel(1,b)
        row.icon:SetIconSize(math.max(1,math.min(18,b:GetWidth()-2*inset)))
    end
    self.grip:AlignDots();self.panelGrip:AlignDots()
    self:PositionMenus()
end
function UI:PositionMinimap()
    if not self.minimap then return end
    local angle=math.rad(A.db.minimapAngle);local x,y=math.cos(angle),math.sin(angle)
    if GetMinimapShape and GetMinimapShape()=='SQUARE' then local scale=1/math.max(math.abs(x),math.abs(y));x,y=x*scale,y*scale end
    self.minimap:ClearAllPoints();self.minimap:SetPoint('CENTER',Minimap,'CENTER',x*(Minimap:GetWidth()/2+5),y*(Minimap:GetHeight()/2+5))
end
function UI:CreateMinimap()
    if not Minimap then return end
    local b=CreateFrame('Button','SoundstoneMinimapButton',Minimap);self.minimap=b;b:SetSize(33,33);b:SetFrameStrata('MEDIUM');b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetTexture('Interface\\Minimap\\UI-Minimap-Background');bg:SetAllPoints()
    local brand=icon(b,'logo',20);brand:SetPoint('CENTER');b.icon=brand.texture
    local border=b:CreateTexture(nil,'OVERLAY');border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder');border:SetSize(54,54);border:SetPoint('TOPLEFT')
    b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:RegisterForDrag('LeftButton')
    b:SetScript('OnClick',function(_,mouse)
        if b.suppressUntil and C.Now()<b.suppressUntil then return end
        if mouse=='RightButton' then A:Command('bar') else A:TogglePanel() end
    end)
    b:SetScript('OnEnter',function(self) tip(self,'Soundstone',L.MINIMAP_HELP..'\n'..L.MINIMAP_DRAG) end);b:SetScript('OnLeave',hideTip)
    b:SetScript('OnDragStart',function()
        if A.db.locked then return end
        hideTip();b:SetScript('OnUpdate',function()
            local mx,my=Minimap:GetCenter();local cx,cy=GetCursorPosition();local scale=Minimap:GetEffectiveScale()
            A.db.minimapAngle=math.deg(math.atan2(cy/scale-my,cx/scale-mx))%360;UI:PositionMinimap()
        end)
    end)
    b:SetScript('OnDragStop',function() b:SetScript('OnUpdate',nil);b.suppressUntil=C.Now()+.15 end)
    b:SetScript('OnHide',function() b:SetScript('OnUpdate',nil) end)
    Minimap:HookScript('OnSizeChanged',function() UI:PositionMinimap() end);self:PositionMinimap()
end
local function rightClick(...)
    for i=1,select('#',...) do
        local value=select(i,...)
        if value=='RightButton' or (type(value)=='table' and value.buttonName=='RightButton') then return true end
    end
    return false
end
function UI:CreateCompartment()
    if not C.HasAddonCompartment() then return end
    local owner=function(frame) return type(frame)=='table' and frame or AddonCompartmentFrame end
    local ok=pcall(AddonCompartmentFrame.RegisterAddon,AddonCompartmentFrame,{
        text='Soundstone',icon='Interface\\AddOns\\Soundstone\\Media\\Logo.tga',
        notCheckable=true,registerForAnyClick=true,
        func=function(...) if rightClick(...) then A:Command('bar') else A:TogglePanel() end end,
        funcOnEnter=function(frame) tip(owner(frame),'Soundstone',L.COMPARTMENT_HELP) end,
        funcOnLeave=hideTip,
    })
    self.compartment=ok or nil
end
function UI:Refresh()
    if not A.audio or not self.root or not self.menu then return end
    if A.audio.changing then return end
    self.refreshing=true
    for _,ch in ipairs(A.Audio.channels) do
        local s=A.audio:Get(ch.id);local b,row=self.barControls[ch.id],self.rows[ch.id]
        local text=s.percent and (s.percent..' %') or '-- %'
        b.value:SetText(text);b.icon:SetMuted(not s.audible);row.icon:SetMuted(not s.audible);row.value:SetText(text)
        row.toggle.text:SetText(s.available and (s.audible and L.ON or L.OFF) or '--')
        row.toggle:SetEnabled(s.available);row.iconButton:SetEnabled(s.available)
        row.slider:EnableMouse(s.adjustable);row.slider:EnableMouseWheel(s.adjustable);row.slider:SetAlpha(s.adjustable and 1 or .35)
        row.fill:SetAlpha(s.adjustable and 1 or .35);row.slider.track:SetAlpha(s.adjustable and 1 or .35)
        row.slider:SetValue(s.percent or 0);row.fill:SetValue(s.percent or 0)
    end
    self.bar:SetShown(A.db.showBar and A.db.viewMode=='compact');self.panel:SetShown(A.db.showBar and A.db.viewMode=='expanded');self.root:SetShown(A.db.showBar)
    if self.minimap then self.minimap:SetShown(A.db.showMinimap) end
    local scalePercent=self.pendingScale or math.floor(A.db.uiScale*100+.5)
    self.scaleSlider:SetValue(scalePercent);self:ShowScaleValue(scalePercent)
    for key,c in pairs(self.checks) do c:SetChecked(A.db[key]) end
    self.refreshing=false;self:ApplyLayout();self:SyncEscape()
end
function UI:Create()
    self.theme=C.RetailStyle() and 'Retail' or 'Classic'
    self.root=CreateFrame('Frame','SoundstoneRoot',UIParent);self.root:SetFrameStrata('MEDIUM');self.root:SetMovable(true);self.root:SetClampedToScreen(true)
    self:CreateBar();self:CreatePanel();self:CreateMenu();self:CreateMinimap();self:CreateCompartment()
    self.escape=CreateFrame('Frame','SoundstoneEscapeHandler',UIParent);self.escape:SetSize(1,1);self.escape:Hide()
    table.insert(UISpecialFrames,'SoundstoneEscapeHandler')
    self.escape:SetScript('OnHide',function() if not UI.syncEscape then UI:Escape() end end)
    self.root:HookScript('OnHide',function()
        UI:CancelPlacement()
        if UI.dragging then UI.root:StopMovingOrSizing();UI:FinishDrag() end
        UI:CloseMenus()
    end)
    self:RefreshDevices();self:Refresh()
end
