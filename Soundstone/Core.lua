local addonName, A = ...
Soundstone = A
local L, C = A.L, A.Compat
local validPoints = { CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true,
    TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true }
local defaults = {
    bar = { point = "CENTER", x = 0, y = -180 },
    panel = { point = "CENTER", x = 0, y = 0 },
}

local function number(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or math.abs(value) == math.huge then return fallback end
    return value
end

function A:Print(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc4dSoundstone:|r " .. text) end
end

function A:Result(ok, err)
    if not ok and (not self.lastError or C.Now() - self.lastError > 1) then
        self:Print(L[err] or L.WRITE_ERROR)
        self.lastError = C.Now()
    end
    return ok
end

function A:Toggle(id)
    if self.audio then return self:Result(self.audio:Toggle(id)) end
end

function A:SetVolume(id, value)
    if self.audio then return self:Result(self.audio:SetVolume(id, value)) end
end

function A:Step(id, delta)
    if self.audio then return self:Result(self.audio:Step(id, delta, IsShiftKeyDown and IsShiftKeyDown())) end
end

function A:TogglePanel()
    if not self.UI.panel then return end
    self.UI.panel:SetShown(not self.UI.panel:IsShown())
end

function A:RestorePosition(frame, key)
    local pos = self.db.positions[key] or defaults[key]
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
end

function A:SavePosition(frame, key)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if not validPoints[point] then return end
    -- Store a center anchor so relative-frame changes never leak into saved state.
    local cx, cy = frame:GetCenter()
    local px, py = UIParent:GetCenter()
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if cx and cy and px and py then
        self.db.positions[key] = { point = "CENTER", x = cx * scale - px, y = cy * scale - py }
    elseif point == relativePoint then
        self.db.positions[key] = { point = point, x = x, y = y }
    end
end

function A:ResetPositions()
    self.db.positions = {}
    self.db.minimapAngle = 225
    if self.UI.bar then self:RestorePosition(self.UI.bar, "bar") end
    if self.UI.panel then self:RestorePosition(self.UI.panel, "panel") end
    self.UI:PositionMinimap()
end

function A:Command(message)
    local cmd, argument = (message or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "" then self:TogglePanel()
    elseif cmd == "bar" then self.db.showBar = not self.db.showBar; self.UI:Refresh()
    elseif cmd == "minimap" then self.db.showMinimap = not self.db.showMinimap; self.UI:Refresh()
    elseif cmd == "lock" then self.db.locked = not self.db.locked; self.UI:Refresh()
    elseif cmd == "reset" then self:ResetPositions()
    elseif cmd == "help" then self:Print(L.HELP)
    elseif cmd == "master" or cmd == "sfx" or cmd == "music" then
        if argument == "on" or argument == "off" then self:Result(self.audio:SetEnabled(cmd, argument == "on"))
        elseif argument == "" or argument == "toggle" then self:Toggle(cmd)
        elseif tonumber(argument) then self:SetVolume(cmd, tonumber(argument))
        else self:Print(L.BAD_COMMAND) end
    else self:Print(L.BAD_COMMAND) end
end

function A:Initialize()
    if self.initialized then return end
    self.initialized = true
    if type(SoundstoneDB) ~= "table" then SoundstoneDB = {} end
    self.db = SoundstoneDB
    local db = self.db
    db.schema = 1
    for key, default in pairs({ showBar = true, showMinimap = true, locked = false }) do
        if type(db[key]) ~= "boolean" then db[key] = default end
    end
    db.minimapAngle = number(db.minimapAngle, 225) % 360
    if type(db.positions) ~= "table" then db.positions = {} end
    for key, pos in pairs(db.positions) do
        if not defaults[key] or type(pos) ~= "table" or not validPoints[pos.point] then db.positions[key] = nil
        else
            pos.x = math.max(-10000, math.min(10000, number(pos.x, 0)))
            pos.y = math.max(-10000, math.min(10000, number(pos.y, 0)))
        end
    end
    self.audio = self.Audio.New(C, function() self.UI:Refresh() end)
    self.UI:Create()
    SLASH_SOUNDSTONE1, SLASH_SOUNDSTONE2 = "/soundstone", "/azeraudio"
    SlashCmdList.SOUNDSTONE = function(message) self:Command(message) end
    if not db.welcomed then self:Print(L.WELCOME); db.welcomed = true end
end

local events = CreateFrame("Frame")
A.events = events
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("CVAR_UPDATE")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" and arg == addonName then
        -- Login initializes the mixer only after WoW has loaded the audio CVars.
        if IsLoggedIn and IsLoggedIn() then A:Initialize() end
    elseif event == "PLAYER_LOGIN" then A:Initialize()
    elseif A.initialized and event == "PLAYER_ENTERING_WORLD" then
        A.UI:PositionMinimap(); A.UI:Refresh()
    elseif A.initialized and event == "CVAR_UPDATE" then
        if not arg or tostring(arg):lower():find("sound", 1, true) then A.UI:Refresh() end
    elseif A.initialized and event == "DISPLAY_SIZE_CHANGED" then
        A:RestorePosition(A.UI.bar, "bar"); A:RestorePosition(A.UI.panel, "panel")
    end
end)
