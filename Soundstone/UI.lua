local _, A = ...
local C, L = A.Compat, A.L
local UI = {}
A.UI = UI
local GOLD = { 1, 0.80, 0.30 }
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ATLAS = "Interface\\AddOns\\Soundstone\\Media\\Icons.tga"
-- Each coordinate selects an isolated glyph in the packaged two-by-two atlas.
local uv = {
    logo = { 0.015, 0.498, 0.05, 0.47 },
    master = { 0.555, 0.935, 0.13, 0.43 },
    sfx = { 0.10, 0.46, 0.55, 0.90 },
    music = { 0.585, 0.90, 0.545, 0.90 },
}
local unpack = unpack or table.unpack

local function label(parent, text, size)
    local font = parent:CreateFontString(nil, "OVERLAY", size or "GameFontNormal")
    font:SetText(text)
    if size and size:find("Highlight", 1, true) then font:SetTextColor(0.95, 0.93, 0.87)
    else font:SetTextColor(unpack(GOLD)) end
    return font
end

local function fill(parent, r, g, b, a, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(WHITE)
    t:SetVertexColor(r, g, b, a or 1)
    t:SetAllPoints()
    return t
end

local function skin(frame, small)
    local classic = not C.IsRetail()
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = WHITE,
            edgeFile = classic and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 32, edgeSize = classic and (small and 16 or 24) or 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        if classic then frame:SetBackdropColor(0.035, 0.032, 0.028, 1)
        else
            frame:SetBackdropColor(0.055, 0.064, 0.075, 1)
            frame:SetBackdropBorderColor(0.72, 0.58, 0.32, 1)
        end
    else
        fill(frame, 0.055, 0.064, 0.075, 0.97)
    end
end

local function line(parent, x, y, width)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE)
    t:SetVertexColor(0.6, 0.47, 0.24, 0.32)
    t:SetSize(width, 1)
    t:SetPoint("TOPLEFT", x, y)
end

local function icon(parent, id, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    f.texture = f:CreateTexture(nil, "ARTWORK")
    f.texture:SetAllPoints()
    f.texture:SetTexture(ATLAS)
    f.texture:SetTexCoord(unpack(uv[id]))
    -- A black-matte atlas uses additive blending, avoiding rectangular backgrounds.
    f.texture:SetBlendMode("ADD")
    f.slash = f:CreateTexture(nil, "OVERLAY")
    f.slash:SetTexture(WHITE)
    f.slash:SetVertexColor(1, 0.22, 0.22, 1)
    f.slash:SetSize(size * 1.05, math.max(2, size / 11))
    f.slash:SetPoint("CENTER")
    f.slash:SetRotation(math.pi / 4)
    f.slash:Hide()
    function f:SetMuted(muted)
        self.texture:SetDesaturated(muted)
        self.texture:SetAlpha(muted and 0.55 or 1)
        self.slash:SetShown(muted)
    end
    return f
end

local function button(parent, text, width, height, onClick)
    local b = C.Frame("Button", nil, parent)
    b:SetSize(width, height)
    skin(b, true)
    b.text = label(b, text, "GameFontNormalSmall")
    b.text:SetPoint("CENTER")
    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetTexture(WHITE)
    hover:SetVertexColor(1, 0.8, 0.3, 0.13)
    hover:SetPoint("TOPLEFT", 4, -4)
    hover:SetPoint("BOTTOMRIGHT", -4, 4)
    b:SetScript("OnClick", onClick)
    return b
end

local function hideTip() if GameTooltip then GameTooltip:Hide() end end
local function basicTip(owner, title, text)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(title, 1, 0.82, 0.3)
    GameTooltip:AddLine(text, 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end

function UI:ChannelTip(owner, id)
    if not GameTooltip then return end
    local state = A.audio:Get(id)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(L[state.channel.label], 1, 0.82, 0.3)
    if state.percent then GameTooltip:AddLine(string.format(L.SAVED, state.percent), 1, 1, 1) end
    if state.reason then GameTooltip:AddLine(L[state.reason], 1, 0.4, 0.35) end
    GameTooltip:AddLine(L[state.channel.help], 0.85, 0.85, 0.85, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.TOGGLE_HELP, 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine(L.WHEEL_HELP, 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end

local function wireChannel(target, id, click)
    target:EnableMouseWheel(true)
    if click then
        target:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        target:SetScript("OnClick", function(_, mouse)
            if mouse == "RightButton" then A:TogglePanel() else A:Toggle(id) end
        end)
    end
    target:SetScript("OnMouseWheel", function(_, delta) A:Step(id, delta) end)
    target:SetScript("OnEnter", function(self) UI:ChannelTip(self, id) end)
    target:SetScript("OnLeave", hideTip)
end

local function movable(frame, handle, key)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if not A.db.locked then frame:StartMoving(); frame.dragging = true; hideTip() end
    end)
    handle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if frame.dragging then A:SavePosition(frame, key); frame.dragging = false end
    end)
    frame:HookScript("OnHide", function()
        if frame.dragging then frame:StopMovingOrSizing(); A:SavePosition(frame, key); frame.dragging = false end
    end)
end

function UI:CreateBar()
    local bar = C.Frame("Frame", "SoundstoneBar", UIParent)
    self.bar = bar
    bar:SetSize(336, 46)
    bar:SetFrameStrata("MEDIUM")
    skin(bar, true)
    A:RestorePosition(bar, "bar")
    local grip = CreateFrame("Button", nil, bar)
    grip:SetSize(22, 34)
    grip:SetPoint("LEFT", 3, 0)
    local gripText = label(grip, "::", "GameFontNormalLarge")
    gripText:SetPoint("CENTER")
    gripText:SetTextColor(0.65, 0.61, 0.51)
    movable(bar, grip, "bar")
    grip:RegisterForClicks("RightButtonUp")
    grip:SetScript("OnClick", function() A:TogglePanel() end)
    grip:SetScript("OnEnter", function(self) basicTip(self, "Soundstone", A.db.locked and L.LOCKED_HELP or L.DRAG_HELP) end)
    grip:SetScript("OnLeave", hideTip)
    self.barControls = {}
    for i, channel in ipairs(A.Audio.channels) do
        local b = CreateFrame("Button", nil, bar)
        b:SetSize(100, 34)
        b:SetPoint("LEFT", 25 + (i - 1) * 100, 0)
        b.icon = icon(b, channel.id, 27)
        b.icon:SetPoint("LEFT", 4, 0)
        b.value = label(b, "", "GameFontHighlight")
        b.value:SetPoint("RIGHT", -8, 0)
        if i > 1 then
            local separator = b:CreateTexture(nil, "ARTWORK")
            separator:SetTexture(WHITE)
            separator:SetVertexColor(0.62, 0.48, 0.25, 0.4)
            separator:SetSize(1, 25)
            separator:SetPoint("LEFT", 0, 0)
        end
        wireChannel(b, channel.id, true)
        self.barControls[channel.id] = b
    end
end

function UI:CreatePanel()
    local panel = C.Frame("Frame", "SoundstonePanel", UIParent)
    self.panel = panel
    panel:SetSize(500, 280)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    skin(panel)
    A:RestorePosition(panel, "panel")
    panel:Hide()
    table.insert(UISpecialFrames, "SoundstonePanel")
    local header = CreateFrame("Button", nil, panel)
    header:SetPoint("TOPLEFT", 12, -6)
    header:SetPoint("TOPRIGHT", -44, -6)
    header:SetHeight(40)
    movable(panel, header, "panel")
    local brand = icon(header, "logo", 32)
    brand:SetPoint("LEFT", 3, 0)
    local title = label(header, "Soundstone", "GameFontNormalLarge")
    title:SetPoint("LEFT", brand, "RIGHT", 9, 0)
    local close = button(panel, "X", 28, 27, function() panel:Hide() end)
    close:SetPoint("TOPRIGHT", -9, -9)
    close:SetScript("OnEnter", function(self) basicTip(self, L.CLOSE, "Esc") end)
    close:SetScript("OnLeave", hideTip)
    line(panel, 15, -48, 470)
    self.rows = {}
    for i, channel in ipairs(A.Audio.channels) do
        local id = channel.id
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(464, 54)
        row:SetPoint("TOPLEFT", 18, -54 - (i - 1) * 56)
        row.iconButton = CreateFrame("Button", nil, row)
        row.iconButton:SetSize(36, 40)
        row.iconButton:SetPoint("LEFT", 0, 0)
        row.icon = icon(row.iconButton, id, 30)
        row.icon:SetPoint("CENTER")
        wireChannel(row.iconButton, id, true)
        row.name = label(row, L[channel.label], "GameFontHighlight")
        row.name:SetPoint("LEFT", 43, 0)
        row.name:SetWidth(116)
        row.name:SetJustifyH("LEFT")
        row.toggle = button(row, "", 47, 28, function() A:Toggle(id) end)
        row.toggle:SetPoint("LEFT", 161, 0)
        wireChannel(row.toggle, id, true)
        local slider = CreateFrame("Slider", nil, row)
        row.slider = slider
        slider:SetSize(169, 22)
        slider:SetPoint("LEFT", 220, 0)
        slider:SetOrientation("HORIZONTAL")
        slider:SetMinMaxValues(0, 100)
        slider:SetValueStep(1)
        if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
        local track = C.Frame("Frame", nil, slider)
        track:SetPoint("LEFT", 0, 0)
        track:SetPoint("RIGHT", 0, 0)
        track:SetHeight(12)
        track:SetFrameLevel(slider:GetFrameLevel())
        fill(track, 0.12, 0.115, 0.10, 1)
        local recess = track:CreateTexture(nil, "ARTWORK")
        recess:SetTexture(WHITE)
        recess:SetVertexColor(0.02, 0.02, 0.02, 1)
        recess:SetPoint("TOPLEFT", 1, -1)
        recess:SetPoint("BOTTOMRIGHT", -1, 1)
        local status = CreateFrame("StatusBar", nil, slider)
        row.fill = status
        status:SetPoint("LEFT", 5, 0)
        status:SetPoint("RIGHT", -5, 0)
        status:SetHeight(4)
        status:SetMinMaxValues(0, 100)
        status:SetStatusBarTexture(WHITE)
        status:SetStatusBarColor(0.94, 0.65, 0.15)
        status:SetFrameLevel(slider:GetFrameLevel())
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(24, 25)
        slider:SetScript("OnValueChanged", function(_, value)
            if not UI.refreshing then A:SetVolume(id, value) end
        end)
        wireChannel(slider, id, false)
        row.value = label(row, "", "GameFontHighlight")
        row.value:SetPoint("RIGHT", 0, 0)
        row.value:SetWidth(67)
        row.value:SetJustifyH("RIGHT")
        if i < 3 then line(row, 1, -54, 462) end
        self.rows[id] = row
    end
    self.note = label(panel, L.MUTED_NOTE, "GameFontHighlightSmall")
    self.note:SetPoint("TOPLEFT", 20, -237)
    self.note:SetWidth(330)
    self.note:SetJustifyH("LEFT")
    local options = button(panel, L.SETTINGS, 96, 27, function()
        UI.optionsOpen = not UI.optionsOpen
        UI.options:SetShown(UI.optionsOpen)
        panel:SetHeight(UI.optionsOpen and 412 or 280)
    end)
    options:SetPoint("TOPRIGHT", -15, -231)
    self:CreateOptions()
    panel:SetScript("OnShow", function() UI:Refresh() end)
end

function UI:CreateOptions()
    local box = CreateFrame("Frame", nil, self.panel)
    self.options = box
    box:SetPoint("TOPLEFT", 16, -276)
    box:SetSize(468, 120)
    box:Hide()
    line(box, 0, 0, 468)
    self.checks = {}
    for i, entry in ipairs({ { "showBar", L.SHOW_BAR }, { "showMinimap", L.SHOW_MINIMAP }, { "locked", L.LOCK } }) do
        local key = entry[1]
        local check = CreateFrame("CheckButton", nil, box, "UICheckButtonTemplate")
        check:SetSize(26, 26)
        check:SetPoint("TOPLEFT", 0, -7 - (i - 1) * 31)
        check.label = label(check, entry[2], "GameFontHighlight")
        check.label:SetPoint("LEFT", check, "RIGHT", 3, 0)
        check:SetScript("OnClick", function(self) A.db[key] = self:GetChecked() and true or false; UI:Refresh() end)
        self.checks[key] = check
    end
    local reset = button(box, L.RESET, 189, 28, function() A:ResetPositions() end)
    reset:SetPoint("BOTTOMRIGHT", -2, 8)
end

function UI:PositionMinimap()
    if not self.minimap then return end
    local angle = math.rad(A.db.minimapAngle)
    local x, y = math.cos(angle), math.sin(angle)
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape == "SQUARE" then
        local scale = 1 / math.max(math.abs(x), math.abs(y))
        x, y = x * scale, y * scale
    end
    self.minimap:ClearAllPoints()
    self.minimap:SetPoint("CENTER", Minimap, "CENTER", x * (Minimap:GetWidth() / 2 + 5), y * (Minimap:GetHeight() / 2 + 5))
end

function UI:CreateMinimap()
    if not Minimap then return end
    local b = CreateFrame("Button", "SoundstoneMinimapButton", Minimap)
    self.minimap = b
    b:SetSize(33, 33)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    local background = b:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetAllPoints()
    local brand = icon(b, "logo", 27)
    brand:SetPoint("CENTER", 0, 0)
    b.icon = brand.texture
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick", function(_, mouse)
        if b.suppressUntil and C.Now() < b.suppressUntil then return end
        if mouse == "RightButton" then A.db.showBar = not A.db.showBar; UI:Refresh()
        else A:TogglePanel() end
    end)
    b:SetScript("OnEnter", function(self)
        basicTip(self, "Soundstone - Azeroth Audio", L.MINIMAP_HELP .. "\n" .. (A.db.locked and L.LOCKED_HELP or L.MINIMAP_DRAG))
    end)
    b:SetScript("OnLeave", hideTip)
    b:SetScript("OnDragStart", function()
        if A.db.locked then return end
        hideTip()
        b:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local dx, dy = cx / scale - mx, cy / scale - my
            -- WoW's math.atan2 is present across the supported clients.
            A.db.minimapAngle = math.deg(math.atan2(dy, dx)) % 360
            UI:PositionMinimap()
        end)
    end)
    b:SetScript("OnDragStop", function() b:SetScript("OnUpdate", nil); b.suppressUntil = C.Now() + 0.1 end)
    b:SetScript("OnHide", function() b:SetScript("OnUpdate", nil); b.suppressUntil = nil end)
    if Minimap.HookScript then Minimap:HookScript("OnSizeChanged", function() UI:PositionMinimap() end) end
    self:PositionMinimap()
end

function UI:Refresh()
    if not A.audio or not self.bar then return end
    self.refreshing = true
    for _, channel in ipairs(A.Audio.channels) do
        local state = A.audio:Get(channel.id)
        local text = state.percent and (state.percent .. " %") or "-- %"
        local b, row = self.barControls[channel.id], self.rows[channel.id]
        b.value:SetText(text)
        b.icon:SetMuted(not state.audible)
        row.icon:SetMuted(not state.audible)
        row.value:SetText(text)
        row.toggle.text:SetText(state.togglable and (state.enabled and L.ON or L.OFF) or "--")
        row.toggle:SetEnabled(state.togglable)
        row.iconButton:SetEnabled(state.togglable)
        if row.toggle.SetBackdropColor then
            local red = not state.enabled or not C.IsRetail()
            row.toggle:SetBackdropColor(red and 0.42 or 0.09, 0.04, 0.035, 1)
        end
        row.slider:EnableMouse(state.adjustable)
        row.slider:EnableMouseWheel(state.adjustable)
        row.slider:SetValue(state.percent or 0)
        row.slider:SetAlpha(state.adjustable and 1 or 0.35)
        row.fill:SetValue(state.percent or 0)
    end
    local master = A.audio:Get("master")
    self.note:SetText(master.reason and L[master.reason] or L.MUTED_NOTE)
    self.bar:SetShown(A.db.showBar)
    if self.minimap then self.minimap:SetShown(A.db.showMinimap) end
    for key, check in pairs(self.checks) do check:SetChecked(A.db[key]) end
    self.refreshing = false
end

function UI:Create()
    self:CreateBar()
    self:CreatePanel()
    self:CreateMinimap()
    self:Refresh()
end
