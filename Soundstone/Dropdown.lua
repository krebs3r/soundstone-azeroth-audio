local _, A = ...
local C,L=A.Compat,A.L
local Dropdown={};A.Dropdown=Dropdown
local Controller={};Controller.__index=Controller
local ROW,MAX_ROWS,PADDING=20,6,8
local dropdownFont

function Controller:IsOpen()
    return self.native and self.field:IsMenuOpen() or (not self.native and self.list:IsShown())
end
function Controller:Label()
    local s=self.state
    return s.selected and s.selected.name or (s.available and L.DEVICE_GONE or L.DEVICE_UNAVAILABLE)
end
function Controller:ReadState()
    self.state=A.devices:Get()
    local enabled=self.state.available and #self.state.items>0
    self.clickTarget:SetEnabled(enabled)
    self.field.Text:SetAlpha(enabled and 1 or .45)
    if self.native then self.field:OverrideText(self:Label()) else self.field.Text:SetText(self:Label()) end
end
function Controller:Position()
    local list=self.list
    if not list or not self:IsOpen() then return end
    -- Blizzard pools menu frames outside UIParent: match our effective scale explicitly.
    local scale=self.field:GetEffectiveScale()
    local parent=list:GetParent()
    list:SetScale(scale/(parent and parent:GetEffectiveScale() or 1))
    local ratio=UIParent:GetEffectiveScale()/scale
    local sw,sh=UIParent:GetWidth()*ratio,UIParent:GetHeight()*ratio
    local left,top=self.field:GetLeft(),self.field:GetTop()
    if not left or not top then return end
    local below=top-self.field:GetHeight()-2
    self.opensUp=below<list:GetHeight()
    top=self.opensUp and top+2+list:GetHeight() or below
    left=math.max(0,math.min(sw-list:GetWidth(),left))
    top=math.max(list:GetHeight(),math.min(sh,top))
    list:ClearAllPoints()
    list:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',C.Pixel(left,list),C.Pixel(top,list))
end
function Controller:Close()
    if self.native then self.field:CloseMenu() else self.list:Hide() end
    self.hideTip();self.changed()
end
function Controller:Open()
    self.hideTip()
    if self.native then self.field:OpenMenu() else
        self:Refresh()
        if not self.state.available or #self.state.items==0 then return end
        self.list:Show();self:Position();self.changed()
    end
end
function Controller:Toggle()
    if self:IsOpen() then self:Close() else self:Open() end
end
function Controller:Select(item)
    -- CVAR_UPDATE can fire inside Select. Do not recycle a native menu's active row.
    self.selecting=true
    local ok,err=A.devices:Select(item.index,item.name)
    self.selecting=false
    self:ReadState();A:Result(ok,err)
    if not self.native then self:Close() end
    -- Native radio responders close through the menu manager, after response handling.
    return MenuResponse and MenuResponse.Close or nil
end
function Controller:Refresh()
    if self.selecting then return end
    self:ReadState()
    if self.native then
        self.field:GenerateMenu()
    else
        self.offset=math.min(self.offset,math.max(0,#self.state.items-MAX_ROWS))
        self:RenderRows()
    end
    if #self.state.items==0 then self:Close() else self:Position() end
end
function Controller:RenderRows()
    local count=#self.state.items
    self.list:SetHeight(PADDING*2+ROW*math.min(MAX_ROWS,math.max(1,count)))
    self.scrollbar:SetShown(count>MAX_ROWS)
    self.updatingScroll=true
    self.scrollbar:SetMinMaxValues(0,math.max(0,count-MAX_ROWS));self.scrollbar:SetValue(self.offset)
    self.updatingScroll=false
    for i,b in ipairs(self.rows) do
        b.item=self.state.items[self.offset+i];b:SetShown(b.item~=nil)
        b:SetWidth(self.width-PADDING*2-(count>MAX_ROWS and 14 or 0))
        if b.item then
            b.text:SetText(b.item.name);b.check:SetShown(b.item.index==self.state.current)
        end
    end
end
function Controller:Scroll(delta)
    if not self:IsOpen() then return end
    self.offset=math.max(0,math.min(math.max(0,#self.state.items-MAX_ROWS),self.offset-delta))
    self:RenderRows()
end
local function inside(frame,ancestor)
    while frame do
        if frame==ancestor then return true end
        frame=frame.GetParent and frame:GetParent()
    end
    return false
end
function Controller:OutsideClick()
    if not self:IsOpen() then return end
    local focus=GetMouseFoci and GetMouseFoci() or {GetMouseFocus and GetMouseFocus()}
    for _,frame in ipairs(focus) do
        if inside(frame,self.field) or inside(frame,self.list) then return end
    end
    self:Close()
end
local function textStyle(text)
    -- Pooled Blizzard menu labels forbid SetFont; only assign an existing Font object.
    text:SetFontObject(dropdownFont)
    text:SetJustifyH('LEFT');text:SetJustifyV('MIDDLE');text:SetWordWrap(false);text:SetMaxLines(1)
end
local function native(self)
    local f=self.field
    f:SetMenuAnchor(AnchorUtil.CreateAnchor('TOPLEFT',f,'BOTTOMLEFT',0,-2))
    f:EnableMouseWheel(false)
    f:RegisterCallback(DropdownButtonMixin.Event.OnMenuOpen,function()
        self.list=f.menu;self.hideTip();self:Position();self.changed()
    end,self)
    f:RegisterCallback(DropdownButtonMixin.Event.OnMenuClose,function()
        self.list=nil;self.hideTip();self.changed()
    end,self)
    f:SetupMenu(function(_,root)
        self:ReadState()
        root:SetMinimumWidth(self.width);root:SetMaximumWidth(self.width)
        root:SetScrollMode(ROW*MAX_ROWS)
        for _,entry in ipairs(self.state.items) do
            local item=entry
            local radio=root:CreateRadio(item.name,function(data)
                return self.state.current==data.index and self.state.selected and self.state.selected.name==data.name
            end,function(data) return self:Select(data) end,item)
            radio:SetTooltip(function(tooltip) tooltip:SetText(item.name) end)
            radio:AddInitializer(function(button)
                local label=button.fontString
                textStyle(label)
                label:ClearAllPoints();label:SetPoint('TOPLEFT',button,'TOPLEFT',20,0)
                label:SetPoint('BOTTOMRIGHT',button,'BOTTOMRIGHT',-4,0)
                return self.width-PADDING*2,ROW
            end)
        end
    end)
end
local function fallback(self)
    local f=self.field
    f.Left:ClearAllPoints();f.Left:SetPoint('TOPLEFT',-16,17);f.Middle:SetWidth(self.width-18)
    f.Button:ClearAllPoints();f.Button:SetAllPoints(f)
    f.Button:SetScript('OnClick',function() self:Toggle() end)
    local list=CreateFrame('Frame',nil,f,BackdropTemplateMixin and 'BackdropTemplate' or nil);self.list=list
    list:SetSize(self.width,76);list:SetFrameStrata('FULLSCREEN_DIALOG');list:EnableMouse(true);list:Hide()
    list:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
        tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    list:SetBackdropColor(.07,.06,.04,.98);list:SetBackdropBorderColor(.85,.78,.6,1)
    list:HookScript('OnHide',function() self.hideTip();self.changed() end)
    local scroll=CreateFrame('Slider',nil,list);self.scrollbar=scroll
    scroll:SetWidth(10);scroll:SetPoint('TOPRIGHT',-4,-PADDING);scroll:SetPoint('BOTTOMRIGHT',-4,PADDING)
    scroll:SetOrientation('VERTICAL');scroll:SetValueStep(1)
    if scroll.SetObeyStepOnDrag then scroll:SetObeyStepOnDrag(true) end
    scroll:SetThumbTexture('Interface\\Buttons\\UI-ScrollBar-Knob');scroll:GetThumbTexture():SetSize(10,20)
    scroll:SetScript('OnValueChanged',function(_,value)
        if self.updatingScroll then return end
        self.offset=math.floor(value+.5);self:RenderRows()
    end)
    self.rows={};self.offset=0
    for i=1,MAX_ROWS do
        local b=CreateFrame('Button',nil,list);self.rows[i]=b
        b:SetSize(self.width-PADDING*2,ROW);b:SetPoint('TOPLEFT',PADDING,-PADDING-(i-1)*ROW)
        b:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight','ADD')
        b.check=b:CreateTexture(nil,'ARTWORK');b.check:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
        b.check:SetSize(16,16);b.check:SetPoint('LEFT',0,0)
        b.text=b:CreateFontString(nil,'OVERLAY');textStyle(b.text);b.text:SetTextColor(1,.82,.45)
        b.text:SetPoint('TOPLEFT',20,0);b.text:SetPoint('BOTTOMRIGHT',-4,0)
        b:SetScript('OnEnter',function() if b.item then self.tip(b,b.item.name) end end)
        b:SetScript('OnLeave',self.hideTip)
        b:SetScript('OnClick',function() if b.item then self:Select(b.item) end end)
    end
    list:EnableMouseWheel(true);list:SetScript('OnMouseWheel',function(_,delta) self:Scroll(delta) end)
    f:RegisterEvent('GLOBAL_MOUSE_DOWN');f:SetScript('OnEvent',function() self:OutsideClick() end)
end
function Dropdown.New(parent,width,changed,tip,hideTip)
    if not dropdownFont then
        dropdownFont=CreateFont('SoundstoneDropdownFont')
        dropdownFont:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',10,'')
    end
    local self=setmetatable({width=width,changed=changed,tip=tip,hideTip=hideTip},Controller)
    self.native=Menu and Menu.GetManager and DropdownButtonMixin and WowStyle1DropdownMixin and AnchorUtil and true or false
    local f=CreateFrame(self.native and 'DropdownButton' or 'Frame','SoundstoneOutputDropdown',parent,
        self.native and 'WowStyle1DropdownTemplate' or 'UIDropDownMenuTemplate')
    self.field=f;self.clickTarget=self.native and f or f.Button
    f:SetSize(width,24);f.text=f.Text
    if self.native then native(self) else fallback(self) end
    f.Text:ClearAllPoints();f.Text:SetPoint('TOPLEFT',self.clickTarget,'TOPLEFT',7,0)
    f.Text:SetPoint('BOTTOMRIGHT',self.clickTarget,'BOTTOMRIGHT',-31,0);textStyle(f.Text)
    self.clickTarget:HookScript('OnEnter',function(b) self.tip(b,L.OUTPUT,self:Label()) end)
    self.clickTarget:HookScript('OnLeave',hideTip)
    parent:HookScript('OnHide',function() self:Close() end)
    f:HookScript('OnHide',function() self:Close() end)
    self:ReadState()
    return self
end
