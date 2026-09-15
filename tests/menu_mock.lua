-- Bounded simulation of the public Blizzard_Menu contracts used by Soundstone.
-- Pooling, intrinsic input and ESC ownership deliberately differ from the fallback.
local create=CreateFrame
DropdownButtonMixin={Event={OnMenuOpen='OnMenuOpen',OnMenuClose='OnMenuClose'}}
WowStyle1DropdownMixin={}
AnchorUtil={CreateAnchor=function(...) return {...} end}
MenuResponse={Close=1}
local manager={}
Menu={GetManager=function() return manager end}
function manager:HandleESC()
    if self.active then self.active:CloseMenu();return true end
    return false
end
function manager:GlobalMouseDown(focus)
    if not self.active then return end
    local f=focus
    while f do if f==self.active or f==self.active.menu then return end;f=f:GetParent() end
    self.active:CloseMenu()
end
local function description()
    local root={entries={}}
    function root:SetMinimumWidth(v) self.minWidth=v end
    function root:SetMaximumWidth(v) self.maxWidth=v end
    function root:SetScrollMode(v) self.scrollExtent=v end
    function root:CreateRadio(label,selected,responder,data)
        local radio={label=label,selected=selected,responder=responder,data=data}
        function radio:SetTooltip(fn) self.tooltip=fn end
        function radio:AddInitializer(fn) self.initializer=fn end
        self.entries[#self.entries+1]=radio;return radio
    end
    return root
end
local function render(f)
    local menu,root=f.menu,f.description
    for _,b in ipairs(menu.rows or {}) do b:Hide() end
    menu.rows={};menu.visibleRows={};menu.offset=menu.offset or 0
    menu.offset=math.min(menu.offset,math.max(0,#root.entries-6))
    local total=0
    for _,r in ipairs(root.entries) do
        local b=create('Button',nil,menu);b.fontString=b:CreateFontString(nil,'OVERLAY');b.fontString:SetText(r.label)
        -- Blizzard's compositor rejects even LOOKING UP SetFont on a pooled menu label.
        local methods=getmetatable(b.fontString).__index
        setmetatable(b.fontString,{__index=function(_,key)
            assert(key~='SetFont',"Use of function 'SetFont' is disallowed. (Index)")
            return methods[key]
        end})
        b.item=r.data;b.selected=r.selected(r.data);b.description=r
        local w,h=r.initializer(b);b:SetSize(w,h);total=total+h
        b:SetScript('OnEnter',function() r.tooltip(GameTooltip);GameTooltip:Show() end)
        b:SetScript('OnClick',function()
            menu.responding=true
            local response=r.responder(r.data)
            menu.responding=false
            if response==MenuResponse.Close then f:CloseMenu() end
        end)
        table.insert(menu.rows,b)
    end
    for i,b in ipairs(menu.rows) do
        local visible=i>menu.offset and i<=menu.offset+6;b:SetShown(visible)
        if visible then table.insert(menu.visibleRows,b);b:SetPoint('TOPLEFT',8,-8-(i-menu.offset-1)*20) end
    end
    -- Native MenuStyle1 has an 8-unit top and 15-unit bottom inset.
    menu:SetSize(root.maxWidth,23+math.min(total,root.scrollExtent))
    menu.scrollable=total>root.scrollExtent
end
function CreateFrame(kind,name,parent,template)
    local f=create(kind,name,parent,template)
    if kind~='DropdownButton' then return f end
    assert(template=='WowStyle1DropdownTemplate')
    f.Text=f:CreateFontString(nil,'OVERLAY');f.callbacks={}
    function f:RegisterCallback(event,fn,owner) self.callbacks[event]={fn,owner} end
    function f:Trigger(event) local cb=self.callbacks[event];if cb then cb[1](cb[2],self) end end
    function f:SetMenuAnchor(v) self.menuAnchor=v end
    function f:OverrideText(v) self.Text:SetText(v) end
    function f:SetupMenu(fn) self.generator=fn;self:GenerateMenu() end
    function f:GenerateMenu()
        assert(not self.menu or not self.menu.responding,'Regenerated a native menu during its active responder')
        self.generations=(self.generations or 0)+1
        self.description=description();self.generator(self,self.description)
        if self.menu then render(self) end
    end
    function f:IsMenuOpen() return self.menu~=nil end
    function f:OpenMenu()
        if not self.enabled or self.menu then return end
        self:GenerateMenu()
        if #self.description.entries==0 then return end
        if manager.active then manager.active:CloseMenu() end
        self.menu=create('Frame',nil,nil);self.menu:SetScale(UIParent:GetEffectiveScale())
        self.menu:SetFrameStrata('FULLSCREEN_DIALOG');self.menu:EnableMouseWheel(true)
        manager.active=self;render(self)
        self.menu:SetScript('OnMouseWheel',function(menu,delta)
            menu.offset=math.max(0,math.min(math.max(0,#menu.rows-6),menu.offset-delta));render(self)
        end)
        self:Trigger('OnMenuOpen')
    end
    function f:CloseMenu()
        if not self.menu then return end
        self.menu:Hide();self.menu=nil;manager.active=nil;self:Trigger('OnMenuClose')
    end
    f:SetScript('OnMouseDown',function() if f:IsMenuOpen() then f:CloseMenu() else f:OpenMenu() end end)
    f:EnableMouseWheel(false)
    return f
end
