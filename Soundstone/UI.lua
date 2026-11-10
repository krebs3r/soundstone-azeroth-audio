local _, A = ...
local C,L,Layout,T=A.Compat,A.L,A.Layout,A.Theme
local UI={}; A.UI=UI
local unpack=unpack or table.unpack
local WHITE='Interface\\Buttons\\WHITE8X8'
local MEDIA='Interface\\AddOns\\Soundstone\\Media\\'
local ids={master='Master',sfx='Sfx',music='Music',logo='Logo'}
local SIDES={'top','bottom','left','right'}

local function font(parent,text,size,gold)
    local f=parent:CreateFontString(nil,'OVERLAY')
    f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',size or 10,'')
    T.Paint(f,gold and 'title' or 'text','text')
    f:SetText(text or ''); return f
end
-- Glyphs snap to whole pixels, so text needs more UI units at small effective scales (e.g.
-- pixel-perfect UI scaling). Shrink it until it fits, as Blizzard's AutoScalingFontStringMixin does.
-- Text exactly as wide as its field can still be cut off (Blizzard pads such widths), so keep a unit spare.
local function textWidth(f) return (f.GetUnboundedStringWidth or f.GetStringWidth)(f) end
local function fit(f,size,minSize,width)
    f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',size,'')
    while size>minSize and textWidth(f)>width-1 do
        size=size-.5;f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',size,'')
    end
end
-- Dividers keep their units under the sprite skins and become one physical pixel across under
-- Forever's look (UI:SizeTheme).
local rules={}
local function rule(parent,key,width,height,axis,...)
    local t=parent:CreateTexture(nil,'ARTWORK');t:SetTexture(WHITE)
    T.Paint(t,key,'vertex');t:SetSize(width,height);t:SetPoint(...)
    rules[#rules+1]={t=t,axis=axis,width=width,height=height,anchor={...}};return t
end
-- Regions placed differently inside Forever's window frame keep both layouts: the sprite layout set
-- here, the frame's own added once the frame is built (UI:BuildWindows). size may be nil.
local places={}
local function place(region,size,...)
    local entry={region=region,sprite={size=size,points={{...}}}}
    places[#places+1]=entry;region.places=entry
    if size then region:SetSize(size[1],size[2]) end
    region:SetPoint(...)
end
local function framePlace(region,size,...) region.places.frame={size=size,points={...}} end
local function applyPlaces(framed)
    for _,entry in ipairs(places) do
        local layout=framed and entry.frame or entry.sprite
        local r=entry.region;r:ClearAllPoints()
        if layout.size then r:SetSize(layout.size[1],layout.size[2]) end
        for _,p in ipairs(layout.points) do r:SetPoint(unpack(p)) end
    end
end
-- A region's offset that moves its left (or top) edge onto a whole physical pixel; 0 before it has a position.
local function toPixel(region,edge)
    local d=T.Pixel(region);local v=edge=='left' and region:GetLeft() or region:GetTop()
    if type(v)~='number' or (issecretvalue and issecretvalue(v)) then return 0 end
    return math.floor(v/d+.5)*d-v
end
-- Forever's look: four lines on a frame's outermost physical pixels, inset by a number of pixels.
local function lines(host,layer)
    local o={}
    for _,side in ipairs(SIDES) do local t=host:CreateTexture(nil,layer);t:SetTexture(WHITE);o[side]=t end
    return o
end
-- The frame's rectangle rounded to whole physical pixels, as offsets from its top left. Frames can end
-- between pixels (276 units are 517.5 px at 1.875 px per unit), where a one-pixel line could come out
-- doubled or missing. Before the frame has a position, its own rectangle is used.
local function pixelBox(frame)
    local d=T.Pixel(frame)
    local l,t,w,h=frame:GetLeft(),frame:GetTop(),frame:GetWidth(),frame:GetHeight()
    if type(l)~='number' or type(t)~='number' or (issecretvalue and (issecretvalue(l) or issecretvalue(t))) then return d,0,0,w,h end
    local function snap(v) return math.floor(v/d+.5)*d end
    local left,top=snap(l),snap(t)
    return d,left-l,top-t,snap(l+w)-left,top-snap(t-h)
end
-- Line on the outermost pixels (inset 0) or the next ones (inset 1); a ground fills the same rectangle.
local function placeLines(o,frame,inset,ground)
    local d,x,y,w,h=pixelBox(frame);local i=d*inset
    local function put(t,px,py,pw,ph)
        t:ClearAllPoints();t:SetPoint('TOPLEFT',frame,'TOPLEFT',px,py);t:SetSize(math.max(0,pw),math.max(0,ph))
    end
    put(o.top,x+i,y-i,w-2*i,d);put(o.bottom,x+i,y-h+i+d,w-2*i,d)
    put(o.left,x+i,y-i-d,d,h-2*i-2*d);put(o.right,x+w-i-d,y-i-d,d,h-2*i-2*d)
    if ground then put(ground,x,y,w,h) end
end
local function paintLines(o,top,side,bottom)
    T.Paint(o.top,top,'vertex');T.Paint(o.left,side,'vertex');T.Paint(o.right,side,'vertex');T.Paint(o.bottom,bottom,'vertex')
end
local function showLines(o,shown) for _,side in ipairs(SIDES) do o[side]:SetShown(shown) end end
-- A flat well for a control: band ground and a one-pixel outline. Built only for Forever's look.
local function well(frame)
    local w={frame=frame}
    w.ground=frame:CreateTexture(nil,'BACKGROUND');w.ground:SetTexture(WHITE);w.ground:SetAllPoints()
    T.Paint(w.ground,'band','vertex')
    w.line=lines(frame,'BORDER');paintLines(w.line,'lineBottom','lineBottom','lineBottom')
    function w:SetShown(shown) self.ground:SetShown(shown);showLines(self.line,shown) end
    function w:SetLine(key) paintLines(self.line,key,key,key) end
    frame.flatWell=w;return w
end
local function hideSkin(frame,hidden)
    for _,piece in ipairs(frame.skinPieces or {}) do piece.t:SetShown(not hidden) end
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
            -- Forever's look: the well's outline turns accent on hover and stays so while pressed.
            if b.flatWell then b.flatWell:SetLine(hovered and 'accent' or 'lineBottom') end
            local brightness=down and .7 or (hovered and 1 or .9)
            b.image:SetVertexColor(brightness,brightness,brightness)
            b.image:ClearAllPoints();b.image:SetPoint('CENTER',0,down and -1 or 0)
        end
        b.Restyle=update
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
        -- The tints are read from the theme when the pointer arrives, so they follow the look applied.
        local function tint(key) local c=T.Color(key);b.image:SetVertexColor(c[1],c[2],c[3]) end
        local hovered=false
        local function normal() tint('gear') end
        normal()
        -- Applying a look under the pointer keeps the hover tint; the mouse scripts behave as in 0.3.8.
        b.Restyle=function() tint(hovered and 'gearHover' or 'gear') end
        b:SetScript('OnEnter',function() hovered=true;tint('gearHover');tip(b,title) end)
        b:SetScript('OnLeave',function() hovered=false;normal();hideTip() end)
        b:SetScript('OnMouseDown',function() tint('gearPressed') end)
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
-- A grabbed Soundstone comes to the front and stays there, as a clicked Blizzard window does. Action
-- buttons draw their key and count text at frame level 500 and the end caps at up to 120; Soundstone is
-- created just above UIParent, so dragged across an action bar its plate fell behind the buttons while
-- its icons stayed in front. Every frame of the tree is set explicitly, keeping its offset to the root:
-- Raise alone lifted only the root, which draws nothing itself.
local FRONT_LEVEL=600
function UI:BringToFront()
    local delta=FRONT_LEVEL-self.root:GetFrameLevel()
    if delta<=0 then return end
    local levels={}
    local function collect(frame)
        levels[#levels+1]={frame,frame:GetFrameLevel()}
        for _,child in ipairs({frame:GetChildren()}) do collect(child) end
    end
    collect(self.root)
    -- Parents first, each to an absolute level: the result is the same whether or not the client
    -- moves children along with their parent.
    for _,entry in ipairs(levels) do entry[1]:SetFrameLevel(entry[2]+delta) end
end
-- Move from the displayed rect. Re-anchoring first would pull the bar away from the cursor.
function UI:StartDrag()
    if A.db.locked then return end
    if self.dragging then self:StopDrag() end
    -- An unchecked drop or expansion falls back to the last verified position and view. The
    -- bar stays where it is shown because ApplyLayout waits until the drag ends.
    local job=self.placementJob
    self.dragFallbackView=job and A.db.position==job.requested and job.fallbackView or nil
    self:CancelPlacement()
    self.dragging=true;self.dragOrigin={x=A.db.position.x,y=A.db.position.y}
    self:BringToFront()
    self:CloseMenus();self.root:StartMoving()
    -- A release the handle never sees (e.g. outside the game window) still ends the drag.
    self.root:SetScript('OnUpdate',function()
        if IsMouseButtonDown and not IsMouseButtonDown('LeftButton') then UI:StopDrag() end
    end)
end
function UI:StopDrag()
    if not self.dragging then return end
    self.root:SetScript('OnUpdate',nil);self.root:StopMovingOrSizing()
    -- StartMoving marks the root user-placed; SoundstoneDB alone stores its position.
    if self.root.SetUserPlaced then pcall(self.root.SetUserPlaced,self.root,false) end
    self:FinishDrag()
end
function UI:FinishDrag()
    self:CancelPlacement()
    A:SavePosition(self.root)
    local origin,fallbackView=self.dragOrigin or A.db.position,self.dragFallbackView
    self.dragOrigin=nil;self.dragFallbackView=nil;self.dragging=false;self.suppressUntil=C.Now()+.15;self:ApplyLayout()
    self:BeginPlacement(origin,fallbackView)
end
function UI:BeginPlacement(origin,fallbackView)
    -- OnUpdate does not run while hidden, so a check could only time out there.
    if not A.db.avoidOverlap or not A.db.showBar or not self.root:IsVisible() then return end
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    local scale=A.db.uiScale
    local job=A.Placement.Start(self.root,A.db.position.x+sw/2,A.db.position.y+sh/2,
        self.root:GetWidth()*scale,self.root:GetHeight()*scale,sw,sh)
    job.origin=origin;job.requested=A.db.position;job.fallbackView=fallbackView
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
    handle:SetScript('OnDragStart',function() UI:StartDrag() end)
    handle:SetScript('OnDragStop',function() UI:StopDrag() end)
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
        -- Forever's look: flat squares of two units, whole pixels, on the rivets' centers.
        if self.squares then
            local px=T.Pixel(self);local s=math.max(1,math.floor(C.Pixel(2,self)/px+.5))*px;local offset=C.Pixel((d-s)/2,self)
            for i,t in ipairs(self.squares) do
                local col=(i-1)%2;local row=math.floor((i-1)/2)
                local sx,sy=x+col*step+offset,-y-row*step-offset
                t:ClearAllPoints();t:SetSize(s,s);t:SetPoint('TOPLEFT',sx,sy)
                -- Whole screen pixels, not just whole pixels from the grip's own corner.
                local dx,dy=toPixel(t,'left'),toPixel(t,'top')
                if dx~=0 or dy~=0 then t:ClearAllPoints();t:SetPoint('TOPLEFT',sx+dx,sy+dy) end
            end
        end
    end
    function parent:SquareDots()
        if self.squares then return self.squares end
        self.squares={}
        for i=1,#result do
            local t=self:CreateTexture(nil,'ARTWORK');t:SetTexture(WHITE);T.Paint(t,'muted','vertex');self.squares[i]=t
        end
        self:AlignDots();return self.squares
    end
    parent.rivets=result
    parent:AlignDots()
    return result
end
function UI:CreateBar()
    local b=CreateFrame('Frame','SoundstoneBar',self.root);self.bar=b
    b:SetSize(Layout.compact.width,Layout.compact.height);b:SetPoint('TOPLEFT');skin(b,self.theme..'Bar')
    -- A view switch during a drag hides its handle before OnDragStop can arrive.
    b:HookScript('OnHide',function() UI:StopDrag() end)
    local grip=CreateFrame('Button',nil,b);self.grip=grip
    place(grip,{19,28},'LEFT',3,0);self.gripDots=dots(grip,3.1,5.3)
    movable(grip)
    self.barSettings=gearButton(b);place(self.barSettings,nil,'LEFT',24,0)
    self.barMode=actionButton(b,'Expand',L.EXPAND,function() A:SetView('expanded') end);place(self.barMode,nil,'LEFT',45,0)
    grip:SetScript('OnEnter',function(self) tip(self,'Soundstone',L.DRAG_HELP) end);grip:SetScript('OnLeave',hideTip)
    self.barControls={}
    for i,ch in ipairs(A.Audio.channels) do
        local c=CreateFrame('Button',nil,b);place(c,{68,28},'LEFT',66+(i-1)*68,0)
        c.icon=icon(c,ch.id,22);c.icon:SetPoint('LEFT',4,0)
        c.value=font(c,'',11);place(c.value,nil,'LEFT',28,0);c.value:SetWidth(38);c.value:SetJustifyH('RIGHT');c.value:SetWordWrap(false)
        if i>1 then c.rule=rule(c,'divider',.6,26,'width','LEFT',0,0) end
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
    s.thumbName=C.RetailStyle() and 'GoldThumb' or 'SilverThumb'
    s:SetThumbTexture(MEDIA..s.thumbName..'.tga')
    local thumb=s:GetThumbTexture();thumb:SetTexCoord(unpack(A.Assets[s.thumbName].uv));thumb:SetSize(10,18);thumb:SetDrawLayer('OVERLAY',7);thumb:SetBlendMode('BLEND')
    s:SetScript('OnValueChanged',function(_,value) if not UI.refreshing then callback(value) end end)
    s.fill=status;s.track=track;UI.sliders[#UI.sliders+1]=s;return s
end
-- Forever's look takes the client's own settings-slider thumb, at the atlas's size; every other case,
-- and a client that does not know the atlas, keeps the sprite exactly as 0.3.8 sets it.
local function setThumb(s,forever)
    local thumb=s:GetThumbTexture()
    -- resetTexCoords: SetAtlas keeps earlier texture coordinates, here the sprite's sub-rectangle.
    if forever and thumb and T.HasAtlas(T.thumbAtlas) and pcall(thumb.SetAtlas,thumb,T.thumbAtlas,true,nil,true) then
        s.thumbAtlas=true;thumb:SetDrawLayer('OVERLAY',7);thumb:SetBlendMode('BLEND');return
    end
    if not s.thumbAtlas then return end
    s.thumbAtlas=nil;s:SetThumbTexture(MEDIA..s.thumbName..'.tga')
    thumb=s:GetThumbTexture();thumb:SetTexCoord(unpack(A.Assets[s.thumbName].uv));thumb:SetSize(10,18);thumb:SetDrawLayer('OVERLAY',7);thumb:SetBlendMode('BLEND')
end
function UI:CreatePanel()
    local p=CreateFrame('Frame','SoundstonePanel',self.root);self.panel=p
    p:SetSize(Layout.expanded.width,Layout.expanded.height);p:SetPoint('TOPLEFT');skin(p,self.theme..'Panel')
    p:HookScript('OnHide',function() UI:StopDrag() end)
    local header=CreateFrame('Button',nil,p);self.panelHeader=header;place(header,{156,21},'TOPLEFT',72,-4);movable(header)
    local title=font(header,'Soundstone – Azeroth Audio',14,true);self.panelTitle=title;place(title,nil,'CENTER')
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
    self.headerRule=rule(p,'headerRule',286,1,'height','TOPLEFT',7,-27)
    self.rows={}
    for i,ch in ipairs(A.Audio.channels) do
        local row=CreateFrame('Frame',nil,p);place(row,{276,42},'TOPLEFT',12,-29-(i-1)*42)
        row.iconButton=CreateFrame('Button',nil,row);row.iconButton:SetSize(25,25);row.iconButton:SetPoint('LEFT')
        if not C.RetailStyle() then skin(row.iconButton,'ClassicPanel',3) end
        row.icon=icon(row.iconButton,ch.id,18);row.icon:SetPoint('CENTER');wire(row.iconButton,ch.id,true)
        row.name=font(row,L[ch.label],10);row.name:SetPoint('LEFT',30,0);row.name:SetWidth(69);row.name:SetJustifyH('LEFT');row.name:SetWordWrap(false)
        row.toggle=nativeButton(row,34,20,'',function() A:Toggle(ch.id) end);row.toggle:SetPoint('LEFT',99,0);wire(row.toggle,ch.id,true)
        row.slider=slider(row,98,function(value) A:SetVolume(ch.id,value) end);row.slider:SetPoint('LEFT',143,0)
        row.fill=row.slider.fill;wire(row.slider,ch.id,false)
        row.value=font(row,'',10);row.value:SetPoint('RIGHT');row.value:SetWidth(32);row.value:SetJustifyH('RIGHT');row.value:SetWordWrap(false)
        if i<3 then rule(row,'rowRule',272,.6,'height','BOTTOM',0,0) end
        self.rows[ch.id]=row
    end
    local footer=CreateFrame('Frame',nil,p);self.footer=footer;place(footer,nil,'BOTTOMRIGHT',-10,5);footer:SetAlpha(T.Color('footerAlpha'))
    self.version=font(footer,'v'..C.Version(),7.5);self.version:SetHeight(8);self.version:SetPoint('LEFT');self.version:SetJustifyH('RIGHT')
    self.footerHeart=sprite(footer,'Heart');self.footerHeart:SetSize(8,8);self.footerHeart:SetVertexColor(.95,.3,.38);self.footerHeart:SetPoint('LEFT',self.version,'RIGHT',3,0)
    self.author=font(footer,'by krebs3r',7.5);self.author:SetHeight(8);self.author:SetPoint('LEFT',self.footerHeart,'RIGHT',3,0);self.author:SetJustifyH('LEFT')
    T.Paint(self.version,'footer','text');T.Paint(self.author,'footer','text')
    footer:SetHeight(8)
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
    -- Lines snap to the pixels the frames now cover; ApplyLayout ends here as well.
    self:SizeTheme()
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
    local title=font(menu,L.SETTINGS,12,true);title:SetPoint('TOPLEFT',10,-8);self.menuTitle=title
    local close=textureButton(menu,'Close',18,18,'',function() UI:CloseMenus() end);close:SetPoint('TOPRIGHT',-7,-6);self.menuSpriteClose=close
    local outputLabel=font(menu,L.OUTPUT,10,true);place(outputLabel,nil,'TOPLEFT',10,-31);self.outputLabel=outputLabel
    self.outputDropdown=A.Dropdown.New(menu,width,function() UI:SyncEscape() end,tip,hideTip)
    self.deviceButton=self.outputDropdown.field
    self.deviceButton:SetPoint('TOPLEFT',10,-44)
    local scaleLabel=font(menu,L.SIZE,10,true);place(scaleLabel,nil,'TOPLEFT',10,-74);self.scaleLabel=scaleLabel
    self.scaleSlider=slider(menu,width-48,function(value) UI.pendingScale=math.floor(value+.5);UI:ShowScaleValue(UI.pendingScale) end)
    self.scaleSlider:SetMinMaxValues(75,150);place(self.scaleSlider,nil,'TOPLEFT',10,-86)
    self.scaleSlider:SetScript('OnMouseUp',function(_,button) if button=='LeftButton' then UI:CommitScale() end end)
    self.scaleSlider:SetScript('OnHide',function() UI:CancelScale() end)
    self.scaleValue=font(menu,'',10);place(self.scaleValue,nil,'TOPRIGHT',-10,-91)
    self.scaleSlider:SetScript('OnEnter',function(self) tip(self,L.SIZE,L.SCALE_RELEASE) end)
    self.scaleSlider:SetScript('OnLeave',hideTip)
    menu:HookScript('OnHide',function() UI:CancelScale();if UI.root and UI.rows then UI:ApplyLayout() end end)
    self.checks={}
    for i,entry in ipairs({{'showMinimap',L.SHOW_MINIMAP},{'locked',L.LOCK},{'avoidOverlap',L.AVOID_OVERLAP}}) do
        local key=entry[1];local c=CreateFrame('CheckButton',nil,menu,'UICheckButtonTemplate')
        place(c,{24,24},'TOPLEFT',10,-110-(i-1)*24)
        c.label=font(c,entry[2],10);c.label:SetPoint('LEFT',c,'RIGHT',2,0)
        if key=='avoidOverlap' then
            c:SetScript('OnEnter',function(self) tip(self,L.AVOID_OVERLAP,L.AVOID_HELP) end);c:SetScript('OnLeave',hideTip)
        end
        c:SetScript('OnClick',function(self) A.db[key]=self:GetChecked() and true or false;UI:Refresh() end);self.checks[key]=c
    end
    self.resetSize=nativeButton(menu,width,20,L.RESET_SIZE,function() A:SetScale(1) end);place(self.resetSize,nil,'TOPLEFT',10,-186)
    self.resetPosition=nativeButton(menu,width,20,L.RESET,function() A:ResetPositions() end);place(self.resetPosition,nil,'TOPLEFT',10,-210)
end
function UI:RefreshDevices()
    if self.outputDropdown then self.outputDropdown:Refresh() end
end
function UI:ApplyLayout()
    if not self.root then return end
    -- The client moves the root during a drag; FinishDrag applies the layout afterwards.
    if self.dragging then return end
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
    self:PositionMenus();self:FitText()
end
-- Forever's pieces are built the first time that look is applied; under 'soundstone' they never exist.
function UI:BuildForever()
    if self.foreverBuilt then return end
    self.foreverBuilt=true
    for _,frame in ipairs({self.bar,self.panel,self.menu}) do
        local plate={}
        plate.fill=frame:CreateTexture(nil,'BACKGROUND');plate.fill:SetTexture(WHITE);plate.fill:SetAllPoints()
        T.Paint(plate.fill,'plate','vertex')
        -- Lines and band lie on a frame of their own above the content, as Umbra's rim does: a child's
        -- art (e.g. the device field's template) cannot cover them. It takes no mouse.
        local edge=CreateFrame('Frame',nil,frame);edge:SetAllPoints();edge:SetFrameLevel(frame:GetFrameLevel()+10);edge:EnableMouse(false)
        plate.edge=edge;plate.line=lines(edge,'OVERLAY');plate.band=lines(edge,'OVERLAY')
        paintLines(plate.line,'lineTop','lineSide','lineBottom');paintLines(plate.band,'band','band','band')
        frame.flatPlate=plate
    end
    for _,row in pairs(self.rows) do well(row.iconButton) end
    for _,s in ipairs(self.sliders) do well(s.track) end
    for _,b in ipairs({self.barMode}) do well(b);b.Restyle() end
    for _,grip in ipairs({self.grip,self.panelGrip}) do grip:SquareDots() end
end
-- Forever's window frame on the panel and the options, as Baganator wears it there: Blizzard's
-- ButtonFrameTemplateNoPortrait nine-slice with the client's own ground and top streaks. The border is
-- anchored so its opaque metal ends flush with the frame (measured at 1.3125 px per unit on Baganator's
-- bag, whose saved rect pins its frame, and on Blizzard's Settings window): the art starts 4.4 units
-- inside its box on the left and 3.35 above it, and ends 0.5 / 0.35 beyond it on the right and bottom.
local BORDER={left=-4.4,top=-3.35,right=.5,bottom=.35}
-- Forever's close button: Blizzard's art and place (28x28 at TOPRIGHT 0,3 of the border) with
-- Soundstone's own action; the stock OnClick would hide the frame through HideUIPanel.
local function closeButton(parent,border,onClick,title,detail)
    local b=CreateFrame('Button',nil,parent);b:SetSize(28,28);b:SetPoint('TOPRIGHT',border,'TOPRIGHT',0,3)
    local art=T.window.close
    b:SetNormalAtlas(art.normal);b:SetPushedAtlas(art.pushed);b:SetHighlightAtlas(art.highlight,'ADD')
    b:RegisterForClicks('LeftButtonUp');b:SetScript('OnClick',onClick)
    if title then b:SetScript('OnEnter',function() tip(b,title,detail) end) end
    b:SetScript('OnLeave',hideTip);return b
end
-- A header button as Baganator's on Forever: UIPanelButtonTemplate at 32x22 with a gold symbol. Forever's
-- button art sits 0.8 units below its rectangle's centre (bevel from 2.3 to 21.3 units down on a 22-unit
-- button, measured on Baganator's), so the symbol takes the art's centre. In game at 1.3125 pixels per
-- unit that leaves 3 rows of the 20-row red face above the 15-row symbol and 2 below, as close to the
-- middle as whole pixels allow. On the rectangle's centre it was 1 above and 4 below; one pixel below
-- the art's centre, 4 above and 1 below.
local SYMBOL_DROP=.8
local function frameButton(parent,title,onClick,texture,size)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(32,22);b:SetText('')
    b.symbol=texture(b);b.symbol:SetSize(size,size);b.symbol:SetPoint('CENTER',0,-SYMBOL_DROP);T.Paint(b.symbol,'buttonIcon','vertex')
    b:SetScript('OnEnter',function() tip(b,title) end);b:SetScript('OnLeave',hideTip)
    b:RegisterForClicks('LeftButtonUp');b:SetScript('OnClick',onClick);return b
end
function UI:BuildWindows()
    if self.windowsBuilt then return end
    self.windowsBuilt=true
    for _,frame in ipairs({self.panel,self.menu}) do
        local w={}
        local border=CreateFrame('Frame',nil,frame);w.border=border
        border:SetPoint('TOPLEFT',BORDER.left,BORDER.top);border:SetPoint('BOTTOMRIGHT',BORDER.right,BORDER.bottom)
        -- Above the content, as Blizzard's NineSlice (500) is; the header controls sit above it in turn.
        border:SetFrameLevel(frame:GetFrameLevel()+10);border:EnableMouse(false)
        NineSliceUtil.ApplyLayoutByName(border,T.window.layout)
        -- Forever crops the bottom corners of short frames so they cannot overlap the top ones (only Forever has it).
        if type(NineSliceUtil.UpdateCornerCropping)=='function' then
            pcall(NineSliceUtil.UpdateCornerCropping,{NineSlice=border,layoutType=T.window.layout},frame:GetHeight()+BORDER.top-BORDER.bottom)
        end
        -- ButtonFrameTemplate's ground: tiled rock and the streaks under the title strip; both end under the band.
        w.ground=frame:CreateTexture(nil,'BACKGROUND',nil,-6);w.ground:SetTexture(T.window.background,'REPEAT','REPEAT')
        w.ground:SetHorizTile(true);w.ground:SetVertTile(true)
        w.ground:SetPoint('TOPLEFT',border,'TOPLEFT',7,-21);w.ground:SetPoint('BOTTOMRIGHT',border,'BOTTOMRIGHT',-2,2)
        if T.HasAtlas(T.window.streaks) then
            w.streaks=frame:CreateTexture(nil,'BACKGROUND',nil,-5);w.streaks:SetAtlas(T.window.streaks);w.streaks:SetHeight(43);w.streaks:SetHorizTile(true)
            w.streaks:SetPoint('TOPLEFT',border,'TOPLEFT',6,-21);w.streaks:SetPoint('TOPRIGHT',border,'TOPRIGHT',-2,-21)
        end
        frame.window=w
    end
    local p,border=self.panel,self.panel.window.border
    -- Baganator's header on Forever: first button at TOPLEFT (8,1), the right group against the close button.
    local c={}
    c.close=closeButton(p,border,function() A:SetView('compact') end,L.COMPACT,'Esc')
    c.mode=frameButton(p,L.COMPACT,function() A:SetView('compact') end,function(b) return sprite(b,'Collapse') end,16)
    c.mode:SetPoint('TOPRIGHT',border,'TOPRIGHT',-28,1)
    c.hide=frameButton(p,L.HIDE,function() A:SetVisible(false) end,function(b) return sprite(b,'EyeOff') end,16)
    c.hide:SetPoint('TOPRIGHT',c.mode,'TOPLEFT',0,0)
    c.settings=frameButton(p,L.SETTINGS,function() UI:ToggleMenu() end,function(b)
        local t=b:CreateTexture(nil,'ARTWORK');t:SetTexture('Interface\\WorldMap\\GEAR_64GREY');return t
    end,17)
    c.settings:SetPoint('TOPLEFT',border,'TOPLEFT',8,1)
    for _,b in pairs(c) do b:SetFrameLevel(p:GetFrameLevel()+12) end
    self.frameControls=c
    local m,mb=self.menu,self.menu.window.border
    self.menuClose=closeButton(m,mb,function() UI:CloseMenus() end);self.menuClose:SetFrameLevel(m:GetFrameLevel()+12)
    -- Blizzard's window title: GameFontNormal centred on the frame, 6 units below the border's top.
    local top=CreateFrame('Frame',nil,m);top:SetAllPoints(mb);top:SetFrameLevel(m:GetFrameLevel()+12);top:EnableMouse(false)
    self.menuFrameTitle=font(top,L.SETTINGS,12,true);self.menuFrameTitle:SetPoint('TOP',mb,'TOP',0,-6);self.menuTitleFrame=top
    -- The title strip drags the window, between the gear and the hide button.
    framePlace(self.panelHeader,nil,{'TOPLEFT',border,'TOPLEFT',40,1},{'BOTTOMRIGHT',border,'TOPRIGHT',-92,-21})
    framePlace(self.panelTitle,nil,{'TOP',self.panelHeader,'TOP',0,-7})
    -- Below the separator (29 units down) and above the bottom band (8.3 units up): rows of 37.
    for i,ch in ipairs(A.Audio.channels) do framePlace(self.rows[ch.id],{276,37},{'TOPLEFT',12,-30-(i-1)*37}) end
    framePlace(self.footer,nil,{'BOTTOMRIGHT',-12,10})
    framePlace(self.outputLabel,nil,{'TOPLEFT',10,-32})
    framePlace(self.scaleLabel,nil,{'TOPLEFT',10,-73})
    framePlace(self.scaleSlider,nil,{'TOPLEFT',10,-85})
    framePlace(self.scaleValue,nil,{'TOPRIGHT',-10,-90})
    for i,key in ipairs({'showMinimap','locked','avoidOverlap'}) do framePlace(self.checks[key],{24,24},{'TOPLEFT',10,-107-(i-1)*23}) end
    framePlace(self.resetSize,nil,{'TOPLEFT',10,-181})
    framePlace(self.resetPosition,nil,{'TOPLEFT',10,-204})
    -- The bar: inside the band (6.1 units, plus about 2.5 of shade). Gear and Expand become the mixer
    -- header's red buttons, at the template's narrowest (two 12-unit caps), and the channels take 64 units
    -- each, so the last value ends 2.6 units before the shade. Vertically each piece's visible art sits on
    -- the middle of the band's opening (measured in game at 1.3125 px per unit): the buttons' art lies
    -- 0.8 units low in their rectangle, so they sit 1 unit up; the channel icons' ink lies about half a
    -- pixel high in theirs, so the channels sit half a unit down; the grip's squares are centred.
    self:BuildBarBand(NineSliceUtil.GetLayout and NineSliceUtil.GetLayout(T.window.layout) or NineSliceLayouts[T.window.layout])
    framePlace(self.grip,{19,28},{'LEFT',5,0})
    local b=self.bar;local bc={}
    bc.settings=frameButton(b,L.SETTINGS,function() UI:ToggleMenu() end,function(button)
        local t=button:CreateTexture(nil,'ARTWORK');t:SetTexture('Interface\\WorldMap\\GEAR_64GREY');return t
    end,15)
    bc.settings:SetSize(24,22);bc.settings:SetPoint('LEFT',25,1)
    bc.mode=frameButton(b,L.EXPAND,function() A:SetView('expanded') end,function(button) return sprite(button,'Expand') end,14)
    bc.mode:SetSize(24,22);bc.mode:SetPoint('LEFT',49,1)
    self.barFrameControls=bc
    for i,ch in ipairs(A.Audio.channels) do
        local c=self.barControls[ch.id];framePlace(c,{64,28},{'LEFT',75+(i-1)*64,-.5})
        -- The value keeps its 2-unit gap to the next channel's divider.
        framePlace(c.value,nil,{'LEFT',24,0})
    end
end
-- The bar wears the same frame without its title strip. Blizzard's own pieces of the layout are cut to
-- their metal band, as Forever's UpdateCornerCropping cuts the corners of short frames: the top pieces
-- keep 8 units from 5 above the box's top (glow included) to 3 below it, where the band's inner black
-- line ends (2.81 measured); the bottom corners keep their lowest units up to 8 above the box's bottom
-- (band and its inner shade end at 7.95). The sides run between them, anchored as NineSlice anchors them.
function UI:BuildBarBand(layout)
    local b=self.bar;local border=CreateFrame('Frame',nil,b)
    border:SetPoint('TOPLEFT',BORDER.left,BORDER.top);border:SetPoint('BOTTOMRIGHT',BORDER.right,BORDER.bottom)
    border:SetFrameLevel(b:GetFrameLevel()+10);border:EnableMouse(false)
    local function piece(key,from,to,tile)
        local p=layout[key];local info=T.AtlasInfo(p.atlas)
        local t=border:CreateTexture(nil,'OVERLAY')
        -- Texture coordinates set before SetAtlas apply within the atlas (NineSlice mirrors pieces this way).
        t:SetTexCoord(0,1,(from or 0)/info.height,(to or info.height)/info.height)
        if tile=='h' then t:SetHorizTile(info.tilesHorizontally or false) elseif tile=='v' then t:SetVertTile(info.tilesVertically or false) end
        t:SetAtlas(p.atlas)
        if t.SetSnapToPixelGrid then t:SetTexelSnappingBias(0);t:SetSnapToPixelGrid(false) end
        return t,p,info
    end
    local w={}
    local top=layout.TopLeftCorner.y or 0
    local tl,tlp,tli=piece('TopLeftCorner',top-5,top+3);tl:SetSize(tli.width,8);tl:SetPoint('TOPLEFT',border,'TOPLEFT',tlp.x or 0,5)
    local tr,trp,tri=piece('TopRightCorner',top-5,top+3);tr:SetSize(tri.width,8);tr:SetPoint('TOPRIGHT',border,'TOPRIGHT',trp.x or 0,5)
    local te=piece('TopEdge',top-5,top+3,'h');te:SetHeight(8);te:SetPoint('TOPLEFT',tl,'TOPRIGHT');te:SetPoint('TOPRIGHT',tr,'TOPLEFT')
    local function bottomCorner(key,point)
        local p=layout[key];local keep=8-(p.y or 0);local info=T.AtlasInfo(p.atlas)
        local t=piece(key,info.height-keep,info.height);t:SetSize(info.width,keep);t:SetPoint(point,border,point,p.x or 0,p.y or 0)
        return t,keep
    end
    local bl,keep=bottomCorner('BottomLeftCorner','BOTTOMLEFT');local br=bottomCorner('BottomRightCorner','BOTTOMRIGHT')
    local beInfo=T.AtlasInfo(layout.BottomEdge.atlas);local edge=math.min(beInfo.height,keep)
    local be=piece('BottomEdge',beInfo.height-edge,beInfo.height,'h');be:SetHeight(edge)
    be:SetPoint('BOTTOMLEFT',bl,'BOTTOMRIGHT');be:SetPoint('BOTTOMRIGHT',br,'BOTTOMLEFT')
    local le,_,lei=piece('LeftEdge',nil,nil,'v');le:SetWidth(lei.width);le:SetPoint('TOPLEFT',tl,'BOTTOMLEFT');le:SetPoint('BOTTOMLEFT',bl,'TOPLEFT')
    local re,_,rei=piece('RightEdge',nil,nil,'v');re:SetWidth(rei.width);re:SetPoint('TOPRIGHT',tr,'BOTTOMRIGHT');re:SetPoint('BOTTOMRIGHT',br,'TOPRIGHT')
    border.pieces={topLeft=tl,topRight=tr,top=te,bottomLeft=bl,bottomRight=br,bottom=be,left=le,right=re}
    w.border=border
    -- The windows' ground; their streaks pressed into a short shade under the band, as the art shades
    -- the other three sides.
    w.ground=b:CreateTexture(nil,'BACKGROUND',nil,-6);w.ground:SetTexture(T.window.background,'REPEAT','REPEAT')
    w.ground:SetHorizTile(true);w.ground:SetVertTile(true)
    w.ground:SetPoint('TOPLEFT',border,'TOPLEFT',7,-2);w.ground:SetPoint('BOTTOMRIGHT',border,'BOTTOMRIGHT',-2,2)
    if T.HasAtlas(T.window.streaks) then
        w.streaks=b:CreateTexture(nil,'BACKGROUND',nil,-5);w.streaks:SetAtlas(T.window.streaks);w.streaks:SetHeight(4);w.streaks:SetHorizTile(true)
        w.streaks:SetPoint('TOPLEFT',border,'TOPLEFT',6,-2.8);w.streaks:SetPoint('TOPRIGHT',border,'TOPRIGHT',-2,-2.8)
    end
    b.window=w
end
-- Forever's settings-slider track (MinimalSliderTemplate's three pieces at their atlas size).
local function buildTrack(s)
    local t=s.track;local a={}
    a.left=t:CreateTexture(nil,'ARTWORK');a.left:SetAtlas(T.track.left,true);a.left:SetPoint('LEFT')
    a.right=t:CreateTexture(nil,'ARTWORK');a.right:SetAtlas(T.track.right,true);a.right:SetPoint('RIGHT')
    a.middle=t:CreateTexture(nil,'ARTWORK');a.middle:SetAtlas(T.track.middle,true)
    a.middle:SetPoint('TOPLEFT',a.left,'TOPRIGHT');a.middle:SetPoint('TOPRIGHT',a.right,'TOPLEFT')
    t.art=a
end
local function showTrack(s,shown)
    for _,tex in pairs(s.track.art) do tex:SetShown(shown) end
    local info=shown and T.AtlasInfo(T.track.left)
    s.track:SetHeight(info and info.height or 8)
    -- The fill keeps clear of the pill's rounded ends: its interior starts about 4 units in.
    local inset=shown and 4 or 3
    s.fill:ClearAllPoints();s.fill:SetPoint('LEFT',s,'LEFT',inset,0);s.fill:SetPoint('RIGHT',s,'RIGHT',-inset,0)
end
-- Forever's action-button frame around a channel icon: Blizzard's 46:45 frame on the button's top left,
-- its pushed art while held, its highlight on hover. Its middle is open, so the plate shows through.
local function buildSlot(b)
    local slot={}
    for key,atlas in pairs(T.slot) do
        local t=b:CreateTexture(nil,'OVERLAY');t:SetAtlas(atlas);t:SetSize(25*46/45,25);t:SetPoint('TOPLEFT');slot[key]=t
    end
    slot.highlight:SetBlendMode('ADD')
    local hovered,pressed=false,false
    function slot:Update()
        self.normal:SetShown(self.on and not (hovered and pressed));self.pushed:SetShown(self.on and hovered and pressed)
        self.highlight:SetShown(self.on and hovered)
    end
    b:HookScript('OnEnter',function()
        if pressed and IsMouseButtonDown and not IsMouseButtonDown('LeftButton') then pressed=false end
        hovered=true;slot:Update()
    end)
    b:HookScript('OnLeave',function() hovered=false;slot:Update() end)
    b:HookScript('OnMouseDown',function(_,button) if button=='LeftButton' and b:IsEnabled() then pressed=true;slot:Update() end end)
    b:HookScript('OnMouseUp',function() pressed=false;slot:Update() end)
    b:HookScript('OnHide',function() hovered=false;pressed=false;slot:Update() end)
    b.slot=slot
end
-- Applies a look where the UI stands. Soundstone applies its client's look once, at creation; the tests
-- also apply the other one and back, which keeps both looks' pieces and anchors exact. Nothing moves: no
-- frame size or saved position changes, and a running placement check keeps its inputs. Inside Forever's
-- window frame the controls take that frame's places, and the sprite layout returns exactly with the sprites.
function UI:ApplyTheme(name)
    name=name or T.Resolve()
    if name==self.themeName then return end
    self.themeName=name;T.Use(name)
    local forever=name=='forever'
    local art=forever and T.Art() or {};self.art=art
    if forever then self:BuildForever() end
    if art.window then self:BuildWindows() end
    if art.track then for _,s in ipairs(self.sliders) do if not s.track.art then buildTrack(s) end end end
    if art.slot then for _,row in pairs(self.rows) do if not row.iconButton.slot then buildSlot(row.iconButton) end end end
    local framed=art.window and true or false
    for _,frame in ipairs({self.bar,self.panel,self.menu}) do
        hideSkin(frame,forever)
        if frame.flatPlate then frame.flatPlate.fill:SetShown(forever and not framed);frame.flatPlate.edge:SetShown(forever and not framed) end
        if frame.window then for _,piece in pairs(frame.window) do piece:SetShown(framed) end end
    end
    for _,b in ipairs({self.close,self.panelMode,self.panelHide,self.panelSettings,self.panelGrip,self.headerRule,self.menuTitle,self.menuSpriteClose,
            self.barSettings,self.barMode}) do
        b:SetShown(not framed)
    end
    if self.frameControls then
        for _,b in pairs(self.frameControls) do b:SetShown(framed) end
        self.menuClose:SetShown(framed);self.menuTitleFrame:SetShown(framed)
        for _,b in pairs(self.barFrameControls) do b:SetShown(framed) end
    end
    -- The title rides above the frame's title strip.
    self.panelHeader:SetFrameLevel(self.panel:GetFrameLevel()+(framed and 12 or 1))
    if self.windowsBuilt then applyPlaces(framed) end
    for _,row in pairs(self.rows) do
        local b=row.iconButton;local slot=art.slot and b.slot and true or false
        hideSkin(b,forever)
        if b.flatWell then b.flatWell:SetShown(forever and not slot) end
        if b.slot then b.slot.on=slot;b.slot:Update() end
    end
    for _,s in ipairs(self.sliders) do
        local track=art.track and s.track.art and true or false
        hideSkin(s.track,forever);if s.track.flatWell then s.track.flatWell:SetShown(forever and not track) end
        if s.track.art then showTrack(s,track) end
        setThumb(s,forever)
    end
    for _,b in ipairs({self.barMode}) do
        b.plate:SetShown(not forever);if b.flatWell then b.flatWell:SetShown(forever) end
    end
    for _,grip in ipairs({self.grip,self.panelGrip}) do
        for _,t in ipairs(grip.rivets) do t:SetShown(not forever) end
        for _,t in ipairs(grip.squares or {}) do t:SetShown(forever) end
    end
    if not forever then
        for _,r in ipairs(rules) do r.t:SetSize(r.width,r.height);r.t:ClearAllPoints();r.t:SetPoint(unpack(r.anchor)) end
    end
    self.footer:SetAlpha(T.Color('footerAlpha'))
    T.Repaint()
    for _,b in ipairs({self.barMode,self.barSettings,self.panelSettings}) do b.Restyle() end
    -- Sized here as well: during a drag ApplyLayout returns at once and lays out only afterwards.
    self:SizeTheme();self.grip:AlignDots();self.panelGrip:AlignDots();self:FitText()
end
-- One physical pixel for every line under Forever's look; measured again on each layout, which runs
-- after UI scale, display size, Soundstone's own scale and UIParent changes.
function UI:SizeTheme()
    if self.themeName~='forever' then return end
    for _,frame in ipairs({self.bar,self.panel,self.menu}) do
        local plate=frame.flatPlate;placeLines(plate.line,frame,0,plate.fill);placeLines(plate.band,frame,1)
    end
    for _,b in ipairs({self.barMode,self.rows.master.iconButton,self.rows.sfx.iconButton,self.rows.music.iconButton}) do
        placeLines(b.flatWell.line,b,0,b.flatWell.ground)
    end
    for _,s in ipairs(self.sliders) do placeLines(s.track.flatWell.line,s.track,0,s.track.flatWell.ground) end
    -- Dividers: one pixel across, and that pixel a whole one on screen (their anchors can fall between pixels).
    for _,r in ipairs(rules) do
        local d=T.Pixel(r.t);local point,x,y=r.anchor[1],r.anchor[2],r.anchor[3]
        if r.axis=='width' then r.t:SetSize(d,r.height) else r.t:SetSize(r.width,d) end
        r.t:ClearAllPoints();r.t:SetPoint(point,x,y)
        local dx,dy=0,0
        if r.axis=='width' then dx=toPixel(r.t,'left') else dy=toPixel(r.t,'top') end
        if dx~=0 or dy~=0 then r.t:ClearAllPoints();r.t:SetPoint(point,x+dx,y+dy) end
    end
end
-- Text widths depend on the effective scale, so fit again after each layout and value change.
function UI:FitText()
    -- In Forever's frame the title takes the client's window-title size (12) between gear and hide.
    local title=self.panelTitle;local framed=self.art and self.art.window and self.windowsBuilt
    local size,width=14,152
    -- The strip's width from the frame's own size: an anchored rect may not be resolved yet.
    if framed then size,width=12,self.panel:GetWidth()+BORDER.right-BORDER.left-132-4 end
    title:SetText('Soundstone – Azeroth Audio');fit(title,size,10,width)
    if textWidth(title)>width then title:SetText('Soundstone') end
    for _,ch in ipairs(A.Audio.channels) do
        local row=self.rows[ch.id]
        fit(self.barControls[ch.id].value,11,9,38);fit(row.value,10,8,32);fit(row.name,10,8,69)
    end
    for _,f in ipairs({self.version,self.author}) do f:SetWidth(textWidth(f)+1) end
    self.footer:SetWidth(self.version:GetWidth()+self.author:GetWidth()+14)
end
-- Scale events fire inside a uiScale CVar write, and pixel-perfect addons call UIParent:SetScale
-- right after it. Clamping then would keep the bar inside the passing UIParent size, so lay out
-- once on the next frame. A hidden root lays out when shown again.
function UI:QueueLayout()
    if not self.root:IsVisible() then return end
    self.watch:SetScript('OnUpdate',function(watch) watch:SetScript('OnUpdate',nil);UI:ApplyLayout() end)
end
function UI:PositionMinimap()
    if not self.minimap then return end
    local angle=math.rad(A.db.minimapAngle);local x,y=math.cos(angle),math.sin(angle)
    if GetMinimapShape and GetMinimapShape()=='SQUARE' then local scale=1/math.max(math.abs(x),math.abs(y));x,y=x*scale,y*scale end
    self.minimap:ClearAllPoints();self.minimap:SetPoint('CENTER',Minimap,'CENTER',x*(Minimap:GetWidth()/2+5),y*(Minimap:GetHeight()/2+5))
end
function UI:CreateMinimap()
    if not Minimap then return end
    local b=CreateFrame('Button','SoundstoneMinimapButton',Minimap);self.minimap=b;b:SetSize(31,31);b:SetFrameStrata('MEDIUM');b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    -- Blizzard's tracking-button geometry, as used by LibDBIcon and Hourstone. The border's
    -- transparent padding differs between Retail and the Classic families.
    local retail=C.RetailStyle()
    local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetTexture('Interface\\Minimap\\UI-Minimap-Background')
    bg:SetSize(retail and 24 or 20,retail and 24 or 20)
    if retail then bg:SetPoint('CENTER') else bg:SetPoint('TOPLEFT',7,-5) end
    local brand=icon(b,'logo',retail and 18 or 17);b.icon=brand.texture
    if retail then brand:SetPoint('CENTER') else brand:SetPoint('TOPLEFT',7,-6) end
    local border=b:CreateTexture(nil,'OVERLAY');border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
    border:SetSize(retail and 50 or 53,retail and 50 or 53);border:SetPoint('TOPLEFT')
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
-- Audio changes only update values; they never move or re-skin the window.
function UI:RefreshAudio()
    if not A.audio or not self.root or not self.menu then return end
    if A.audio.changing then return end
    local refreshing=self.refreshing;self.refreshing=true
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
    self.refreshing=refreshing;self:FitText()
end
function UI:Refresh()
    if not A.audio or not self.root or not self.menu then return end
    if A.audio.changing then return end
    self:RefreshAudio()
    self.refreshing=true
    self.bar:SetShown(A.db.showBar and A.db.viewMode=='compact');self.panel:SetShown(A.db.showBar and A.db.viewMode=='expanded');self.root:SetShown(A.db.showBar)
    if self.minimap then self.minimap:SetShown(A.db.showMinimap) end
    local scalePercent=self.pendingScale or math.floor(A.db.uiScale*100+.5)
    self.scaleSlider:SetValue(scalePercent);self:ShowScaleValue(scalePercent)
    for key,c in pairs(self.checks) do c:SetChecked(A.db[key]) end
    self.refreshing=false;self:ApplyLayout();self:SyncEscape()
end
function UI:Create()
    -- self.theme names the sprite skin; self.themeName the look in force ('soundstone' or 'forever').
    self.theme=C.RetailStyle() and 'Retail' or 'Classic'
    T.Use('soundstone');self.themeName='soundstone';self.sliders={}
    self.root=CreateFrame('Frame','SoundstoneRoot',UIParent);self.root:SetFrameStrata('MEDIUM');self.root:SetMovable(true);self.root:SetClampedToScreen(true)
    -- Runs queued layouts; the root's own OnUpdate belongs to dragging and placement checks.
    self.watch=CreateFrame('Frame',nil,self.root)
    -- Keep the client's layout cache (layout-local.txt) from saving a second position.
    if self.root.SetDontSavePosition then self.root:SetDontSavePosition(true) end
    self:CreateBar();self:CreatePanel();self:CreateMenu();self:CreateMinimap();self:CreateCompartment()
    self.escape=CreateFrame('Frame','SoundstoneEscapeHandler',UIParent);self.escape:SetSize(1,1);self.escape:Hide()
    table.insert(UISpecialFrames,'SoundstoneEscapeHandler')
    self.escape:SetScript('OnHide',function() if not UI.syncEscape then UI:Escape() end end)
    self.root:HookScript('OnHide',function()
        UI.watch:SetScript('OnUpdate',nil);UI:CancelPlacement();UI:StopDrag();UI:CloseMenus()
    end)
    -- Hiding can revert an unchecked position; show the saved one again (e.g. after Alt+Z).
    self.root:HookScript('OnShow',function() UI:ApplyLayout() end)
    -- Addons may resize UIParent or set its scale directly (e.g. below the uiScale CVar's minimum),
    -- which fires no scale event; re-clamp to the new size.
    UIParent:HookScript('OnSizeChanged',function() UI:QueueLayout() end)
    if hooksecurefunc then hooksecurefunc(UIParent,'SetScale',function() UI:QueueLayout() end) end
    self:ApplyTheme()
    self:RefreshDevices();self:Refresh()
end
