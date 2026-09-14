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
local function skin(frame,name)
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
        local du=(u[2]-u[1])*sourceCorner/meta.width
        local dv=(u[4]-u[3])*sourceCorner/meta.height
        local xs={u[1],u[1]+du,u[2]-du,u[2]}
        local ys={u[3],u[3]+dv,u[4]-dv,u[4]}
        local c=C.Pixel(corner,frame); local w,h=frame:GetWidth(),frame:GetHeight()
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
    local f=CreateFrame('Frame',nil,parent);f:SetSize(size,size)
    local name=ids[id];local m=A.Assets[name];local max=math.max(m.width,m.height)
    f.texture=sprite(f,name);f.texture:SetPoint('CENTER')
    f.texture:SetSize(size*m.width/max,size*m.height/max)
    f.slash=flat(f,{.94,.14,.18,1},size*1.15,2.1);f.slash:SetPoint('CENTER');f.slash:SetRotation(math.pi/4);f.slash:Hide()
    function f:SetMuted(value) self.texture:SetDesaturated(value);self.texture:SetAlpha(value and .66 or 1);self.slash:SetShown(value) end
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
function UI:ChannelTip(owner,id)
    local s=A.audio:Get(id)
    local text=(s.percent and string.format(L.SAVED,s.percent)..'\n' or '')..(s.reason and L[s.reason]..'\n' or '')
    tip(owner,L[s.channel.label],text..L[s.channel.help]..'\n'..L.TOGGLE_HELP..'\n'..L.WHEEL_HELP)
end
local function wire(target,id,click)
    target:EnableMouseWheel(true)
    if click then
        target:RegisterForClicks('LeftButtonUp','RightButtonUp')
        target:SetScript('OnClick',function(_,mouse)
            if mouse=='RightButton' then A:SetView('expanded') else A:Toggle(id) end
        end)
    end
    target:SetScript('OnMouseWheel',function(_,delta) A:Step(id,delta) end)
    target:HookScript('OnEnter',function(self) UI:ChannelTip(self,id) end)
    target:HookScript('OnLeave',hideTip)
end
local function movable(handle,menuClick)
    handle:EnableMouse(true);handle:RegisterForDrag('LeftButton')
    handle:SetScript('OnDragStart',function()
        if not A.db.locked then UI:CloseMenus();UI.root:StartMoving();UI.dragging=true;hideTip() end
    end)
    handle:SetScript('OnDragStop',function()
        UI.root:StopMovingOrSizing()
        if UI.dragging then A:SavePosition(UI.root);UI.dragging=false;UI.suppressUntil=C.Now()+.15;UI:ApplyLayout() end
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
        local t=sprite(parent,'Rivet');t:SetSize(size,size);t:SetPoint('CENTER',(col-.5)*gap,(1-row)*gap);result[#result+1]=t
    end end
    return result
end
function UI:CreateBar()
    local b=CreateFrame('Frame','SoundstoneBar',self.root);self.bar=b
    b:SetSize(300,45);b:SetPoint('TOPLEFT');skin(b,self.theme..'Bar')
    local grip=CreateFrame('Button',nil,b);self.grip=grip
    grip:SetSize(21,35);grip:SetPoint('LEFT',3,0);self.gripDots=dots(grip,3.1,5.3)
    movable(grip,true)
    grip:SetScript('OnEnter',function(self) tip(self,'Soundstone',L.DRAG_HELP) end);grip:SetScript('OnLeave',hideTip)
    self.barControls={}
    for i,ch in ipairs(A.Audio.channels) do
        local c=CreateFrame('Button',nil,b);c:SetSize(90,35);c:SetPoint('LEFT',23+(i-1)*90,0)
        c.icon=icon(c,ch.id,24);c.icon:SetPoint('LEFT',5,0)
        c.value=font(c,'',12);c.value:SetPoint('RIGHT',-8,0)
        if i>1 then local sep=flat(c,{.58,.43,.19,.65},.6,26);sep:SetPoint('LEFT',0,0) end
        wire(c,ch.id,true);self.barControls[ch.id]=c
    end
end
local function slider(parent,width,callback)
    local s=CreateFrame('Slider',nil,parent);s:SetSize(width,20);s:SetOrientation('HORIZONTAL')
    s:SetMinMaxValues(0,100);s:SetValueStep(1)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    -- Decoration sits below the slider frame so it cannot cover its thumb.
    local track=CreateFrame('Frame',nil,parent);track:SetPoint('LEFT',s,'LEFT');track:SetPoint('RIGHT',s,'RIGHT');track:SetHeight(8);skin(track,'Toggle')
    local status=CreateFrame('StatusBar',nil,parent);status:SetPoint('LEFT',s,'LEFT',3,0);status:SetPoint('RIGHT',s,'RIGHT',-3,0);status:SetHeight(3)
    track:SetFrameLevel(parent:GetFrameLevel()+1);status:SetFrameLevel(parent:GetFrameLevel()+2);s:SetFrameLevel(parent:GetFrameLevel()+3)
    status:SetStatusBarTexture(WHITE);status:SetStatusBarColor(1,.69,.13);status:SetMinMaxValues(0,100)
    local name=C.IsRetail() and 'GoldThumb' or 'SilverThumb'
    s:SetThumbTexture(MEDIA..name..'.tga')
    local thumb=s:GetThumbTexture();thumb:SetTexCoord(unpack(A.Assets[name].uv));thumb:SetSize(10,18)
    s:SetScript('OnValueChanged',function(_,value) if not UI.refreshing then callback(value) end end)
    s.fill=status;s.track=track;return s
end
function UI:CreatePanel()
    local p=CreateFrame('Frame','SoundstonePanel',self.root);self.panel=p
    p:SetSize(300,160);p:SetPoint('TOPLEFT');skin(p,self.theme..'Panel')
    local header=CreateFrame('Button',nil,p);header:SetPoint('TOPLEFT',25,-4);header:SetSize(246,21);movable(header)
    local title=font(header,'Soundstone',14,true);title:SetPoint('CENTER')
    local menu=CreateFrame('Button',nil,p);menu:SetSize(18,19);menu:SetPoint('TOPLEFT',7,-5);dots(menu,2.5,4.1)
    menu:SetScript('OnClick',function() UI:ToggleMenu() end)
    menu:SetScript('OnEnter',function(self) tip(self,L.SETTINGS) end);menu:SetScript('OnLeave',hideTip)
    local close=textureButton(p,'Close',20,20,'',function() A:SetView('compact') end);self.close=close
    close:SetPoint('TOPRIGHT',-5,-4)
    close:HookScript('OnEnter',function(self) tip(self,L.COMPACT,'Esc') end)
    local separator=flat(p,{.67,.64,.56,.55},286,1);separator:SetPoint('TOPLEFT',7,-27)
    self.rows={}
    for i,ch in ipairs(A.Audio.channels) do
        local row=CreateFrame('Frame',nil,p);row:SetSize(276,42);row:SetPoint('TOPLEFT',12,-29-(i-1)*42)
        row.iconButton=CreateFrame('Button',nil,row);row.iconButton:SetSize(25,32);row.iconButton:SetPoint('LEFT')
        if not C.IsRetail() then skin(row.iconButton,'ClassicPanel') end
        row.icon=icon(row.iconButton,ch.id,24);row.icon:SetPoint('CENTER');wire(row.iconButton,ch.id,true)
        row.name=font(row,L[ch.label],10);row.name:SetPoint('LEFT',30,0);row.name:SetWidth(69);row.name:SetJustifyH('LEFT')
        row.toggle=textureButton(row,'Toggle',34,18,'',function() A:Toggle(ch.id) end);row.toggle:SetPoint('LEFT',99,0);wire(row.toggle,ch.id,true)
        row.slider=slider(row,98,function(value) A:SetVolume(ch.id,value) end);row.slider:SetPoint('LEFT',143,0)
        row.fill=row.slider.fill;wire(row.slider,ch.id,false)
        row.value=font(row,'',10);row.value:SetPoint('RIGHT');row.value:SetWidth(32);row.value:SetJustifyH('RIGHT')
        if i<3 then local sep=flat(row,{.55,.52,.45,.3},272,.6);sep:SetPoint('BOTTOM',0,0) end
        self.rows[ch.id]=row
    end
end
function UI:SyncEscape()
    self.syncEscape=true
    self.escape:SetShown(A.db.showBar and (A.db.viewMode=='expanded' or self.menu:IsShown() or self.deviceMenu:IsShown()))
    self.syncEscape=false
end
function UI:Escape()
    if self.deviceMenu:IsShown() then self.deviceMenu:Hide()
    elseif self.menu:IsShown() then self.menu:Hide()
    else A:SetView('compact') end
    self:SyncEscape()
end
function UI:CloseMenus()
    if self.menu then self.menu:Hide();self.deviceMenu:Hide();self:SyncEscape() end
end
function UI:ToggleMenu()
    if self.menu:IsShown() then self:CloseMenus() else
        self.menu:Show();self:RefreshDevices();self:PositionMenus();self:SyncEscape()
    end
end
function UI:PositionMenus()
    if not self.menu then return end
    local scale=A.db.uiScale;local pw,ph=UIParent:GetWidth(),UIParent:GetHeight()
    local x,y=self.anchorX or 0,self.anchorY or 0
    local function place(frame,offset)
        local left,top=Layout.Clamp(x+offset*scale,y,frame:GetWidth()*scale,frame:GetHeight()*scale,pw,ph)
        frame:ClearAllPoints();frame:SetPoint('TOPLEFT',UIParent,'CENTER',C.Pixel(left/scale,frame),C.Pixel(top/scale,frame))
    end
    local width=self.menu:GetWidth()*scale
    place(self.menu,x+(304*scale)+width>pw/2 and -244 or 304)
    -- Device list opens on top of the options popup; Escape returns to options.
    place(self.deviceMenu,0)
end
function UI:CreateMenu()
    local menu=CreateFrame('Frame','SoundstoneMenu',self.root);self.menu=menu;self.options=menu
    menu:SetSize(240,224);menu:SetFrameStrata('DIALOG');menu:EnableMouse(true);skin(menu,self.theme..'Panel');menu:Hide()
    self.modeButton=textureButton(menu,'Toggle',216,22,'',function() A:TogglePanel() end);self.modeButton:SetPoint('TOPLEFT',12,-12)
    local outputLabel=font(menu,L.OUTPUT,10,true);outputLabel:SetPoint('TOPLEFT',12,-43)
    self.deviceButton=textureButton(menu,'Toggle',216,24,'',function()
        UI:RefreshDevices();UI.deviceMenu:Show();UI:PositionMenus();UI:SyncEscape()
    end)
    self.deviceButton:SetPoint('TOPLEFT',12,-58);self.deviceButton.text:SetWidth(196);self.deviceButton.text:SetWordWrap(false)
    self.deviceButton:HookScript('OnEnter',function(self) tip(self,L.OUTPUT,UI.deviceState and UI.deviceState.selected and UI.deviceState.selected.name or L.DEVICE_UNAVAILABLE) end)
    local scaleLabel=font(menu,L.SIZE,10,true);scaleLabel:SetPoint('TOPLEFT',12,-94)
    self.scaleSlider=slider(menu,159,function(value) A:SetScale(math.floor(value+.5)/100) end)
    self.scaleSlider:SetMinMaxValues(75,150);self.scaleSlider:SetPoint('TOPLEFT',14,-109)
    self.scaleValue=font(menu,'',10);self.scaleValue:SetPoint('TOPRIGHT',-15,-114)
    self.checks={}
    for i,entry in ipairs({{'showMinimap',L.SHOW_MINIMAP},{'locked',L.LOCK}}) do
        local key=entry[1];local c=CreateFrame('CheckButton',nil,menu,'UICheckButtonTemplate')
        c:SetSize(22,22);c:SetPoint('TOPLEFT',10,-137-(i-1)*23)
        c.label=font(c,entry[2],10);c.label:SetPoint('LEFT',c,'RIGHT',2,0)
        c:SetScript('OnClick',function(self) A.db[key]=self:GetChecked() and true or false;UI:Refresh() end);self.checks[key]=c
    end
    local reset=textureButton(menu,'Toggle',106,20,L.RESET_SIZE,function() A:SetScale(1) end);reset:SetPoint('BOTTOMLEFT',12,13)
    local position=textureButton(menu,'Toggle',106,20,L.RESET,function() A:ResetPositions() end);position:SetPoint('BOTTOMRIGHT',-12,13)
    reset.text:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',9,'');position.text:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',9,'')
    local deviceMenu=CreateFrame('Frame','SoundstoneDevices',self.root);self.deviceMenu=deviceMenu
    deviceMenu:SetSize(300,166);deviceMenu:SetFrameStrata('FULLSCREEN_DIALOG');deviceMenu:EnableMouse(true);skin(deviceMenu,self.theme..'Panel');deviceMenu:Hide()
    local title=font(deviceMenu,L.OUTPUT,11,true);title:SetPoint('TOPLEFT',12,-10)
    local back=textureButton(deviceMenu,'Close',17,17,'',function() deviceMenu:Hide();UI:SyncEscape() end);back:SetPoint('TOPRIGHT',-7,-6)
    self.deviceRows={};self.deviceOffset=0
    for i=1,6 do
        local b=CreateFrame('Button',nil,deviceMenu);b:SetSize(274,19);b:SetPoint('TOPLEFT',13,-32-(i-1)*19)
        b.text=font(b,'',10);b.text:SetPoint('LEFT',2,0);b.text:SetWidth(267);b.text:SetJustifyH('LEFT');b.text:SetWordWrap(false)
        local hi=flat(b,{1,.75,.25,.12},274,19);hi:Hide()
        b:SetScript('OnEnter',function(self) hi:Show();if self.item then tip(self,self.item.name) end end)
        b:SetScript('OnLeave',function() hi:Hide();hideTip() end)
        b:SetScript('OnClick',function(self)
            if self.item then
                local ok,err=A.devices:Select(self.item.index,self.item.name);A:Result(ok,err)
                if ok then deviceMenu:Hide();UI:SyncEscape() else UI:RefreshDevices() end
            end
        end)
        self.deviceRows[i]=b
    end
    self.deviceFoot=font(deviceMenu,'',9);self.deviceFoot:SetPoint('BOTTOM',0,8)
    deviceMenu:EnableMouseWheel(true);deviceMenu:SetScript('OnMouseWheel',function(_,delta)
        local count=UI.deviceState and #UI.deviceState.items or 0
        UI.deviceOffset=math.max(0,math.min(math.max(0,count-6),UI.deviceOffset-delta));UI:RefreshDevices()
    end)
end
function UI:RefreshDevices()
    if not self.deviceButton then return end
    local state=A.devices:Get();self.deviceState=state
    self.deviceButton.text:SetText(state.selected and state.selected.name or (state.available and L.DEVICE_GONE or L.DEVICE_UNAVAILABLE))
    self.deviceButton:SetEnabled(state.available and #state.items>0)
    self.deviceOffset=math.min(self.deviceOffset,math.max(0,#state.items-6))
    for i,b in ipairs(self.deviceRows) do
        b.item=state.items[i+self.deviceOffset];b:SetShown(b.item~=nil)
        if b.item then b.text:SetText((b.item.index==state.current and '|cffffd04a> ' or '  ')..b.item.name..'|r') end
    end
    self.deviceFoot:SetText(#state.items==0 and (state.available and L.DEVICE_GONE or L.DEVICE_UNAVAILABLE) or (#state.items>6 and L.DEVICE_SCROLL or ''))
end
function UI:ApplyLayout()
    if not self.root then return end
    local height=A.db.viewMode=='expanded' and 160 or 45
    self.root:SetScale(A.db.uiScale);self.root:SetSize(300,height)
    local x,y=Layout.Clamp(A.db.position.x,A.db.position.y,300*A.db.uiScale,height*A.db.uiScale,UIParent:GetWidth(),UIParent:GetHeight())
    self.anchorX,self.anchorY=x,y
    self.root:ClearAllPoints();self.root:SetPoint('TOPLEFT',UIParent,'CENTER',C.Pixel(x/A.db.uiScale,self.root),C.Pixel(y/A.db.uiScale,self.root))
    for _,frame in ipairs({self.bar,self.panel,self.menu,self.deviceMenu}) do if frame and frame.Reskin then frame.Reskin() end end
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
    local brand=icon(b,'logo',27);brand:SetPoint('CENTER');b.icon=brand.texture
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
function UI:Refresh()
    if not A.audio or not self.root or not self.menu then return end
    self.refreshing=true
    for _,ch in ipairs(A.Audio.channels) do
        local s=A.audio:Get(ch.id);local b,row=self.barControls[ch.id],self.rows[ch.id]
        local text=s.percent and (s.percent..' %') or '-- %'
        b.value:SetText(text);b.icon:SetMuted(not s.audible);row.icon:SetMuted(not s.audible);row.value:SetText(text)
        row.toggle.text:SetText(s.togglable and (s.enabled and L.ON or L.OFF) or '--')
        local toggleName=(not C.IsRetail() or not s.enabled) and 'ToggleRed' or 'Toggle'
        row.toggle:SetSkin(toggleName)
        row.toggle:SetEnabled(s.togglable);row.iconButton:SetEnabled(s.togglable)
        row.slider:EnableMouse(s.adjustable);row.slider:EnableMouseWheel(s.adjustable);row.slider:SetAlpha(s.adjustable and 1 or .35)
        row.fill:SetAlpha(s.adjustable and 1 or .35);row.slider.track:SetAlpha(s.adjustable and 1 or .35)
        row.slider:SetValue(s.percent or 0);row.fill:SetValue(s.percent or 0)
    end
    self.bar:SetShown(A.db.showBar and A.db.viewMode=='compact');self.panel:SetShown(A.db.showBar and A.db.viewMode=='expanded');self.root:SetShown(A.db.showBar)
    if self.minimap then self.minimap:SetShown(A.db.showMinimap) end
    self.modeButton.text:SetText(A.db.viewMode=='expanded' and L.COMPACT or L.EXPAND)
    self.scaleSlider:SetValue(A.db.uiScale*100);self.scaleSlider.fill:SetValue((A.db.uiScale-.75)/.75*100)
    self.scaleValue:SetText(math.floor(A.db.uiScale*100+.5)..' %')
    for key,c in pairs(self.checks) do c:SetChecked(A.db[key]) end
    self.refreshing=false;self:ApplyLayout();self:SyncEscape()
end
function UI:Create()
    self.theme=C.IsRetail() and 'Retail' or 'Classic'
    self.root=CreateFrame('Frame','SoundstoneRoot',UIParent);self.root:SetFrameStrata('MEDIUM');self.root:SetMovable(true);self.root:SetClampedToScreen(true)
    self:CreateBar();self:CreatePanel();self:CreateMenu();self:CreateMinimap()
    self.escape=CreateFrame('Frame','SoundstoneEscapeHandler',UIParent);self.escape:SetSize(1,1);self.escape:Hide()
    table.insert(UISpecialFrames,'SoundstoneEscapeHandler')
    self.escape:SetScript('OnHide',function() if not UI.syncEscape then UI:Escape() end end)
    self.root:HookScript('OnHide',function()
        if UI.dragging then UI.root:StopMovingOrSizing();A:SavePosition(UI.root);UI.dragging=false end
        UI:CloseMenus()
    end)
    self:RefreshDevices();self:Refresh()
end
