-- Pure audio model. The adapter keeps client APIs out of the state logic.
local _, A = ...
local Audio = {}
Audio.__index = Audio
A.Audio = Audio

Audio.channels = {
    { id = "master", label = "MASTER", volume = "Sound_MasterVolume", enabled = "Sound_EnableAllSound", help = "MASTER_HELP" },
    { id = "sfx", label = "SFX", volume = "Sound_SFXVolume", enabled = "Sound_EnableSFX", help = "SFX_HELP" },
    { id = "music", label = "MUSIC", volume = "Sound_MusicVolume", enabled = "Sound_EnableMusic", help = "MUSIC_HELP" },
}
local byID = {}
for _, channel in ipairs(Audio.channels) do byID[channel.id] = channel end

local function finite(value)
    value = tonumber(value)
    if value and value == value and value ~= math.huge and value ~= -math.huge then return value end
end

function Audio.Percent(value)
    value = finite(value)
    if not value then return nil end
    return math.floor(math.max(0, math.min(100, value)) + 0.5)
end

function Audio.New(adapter, changed)
    return setmetatable({ adapter = adapter, changed = changed }, Audio)
end

function Audio:Get(id)
    local channel = byID[id]
    if not channel then return nil end
    local rawVolume = finite(self.adapter.Read(channel.volume))
    local enabledValue = self.adapter.Read(channel.enabled)
    local rawEnabled = tostring(enabledValue)
    local state = {
        id = id, channel = channel,
        adjustable = rawVolume ~= nil,
        togglable = rawEnabled == "0" or rawEnabled == "1",
        enabled = rawEnabled == "1",
        percent = rawVolume and Audio.Percent(rawVolume * 100) or nil,
    }
    state.available = state.adjustable and state.togglable
    state.audible = state.available and state.enabled and state.percent > 0
    if not state.available then state.reason = "UNAVAILABLE"
    elseif not state.enabled then state.reason = "OFF"
    elseif state.percent == 0 then state.reason = "ZERO" end
    if id ~= "master" then
        local master = self:Get("master")
        if master.togglable and not master.enabled then
            state.audible = false
            if state.available and state.enabled then state.reason = "MASTER_OFF" end
        elseif master.adjustable and master.percent == 0 then
            state.audible = false
            if state.available and state.enabled then state.reason = "MASTER_ZERO" end
        end
    end
    return state
end

function Audio:Commit(name, value)
    local accepted = self.adapter.Write(name, value)
    local actual = finite(self.adapter.Read(name))
    local ok = accepted and actual ~= nil and math.abs(actual - tonumber(value)) < 0.0001
    if self.changed then self.changed() end
    if ok then return true end
    return false, "WRITE_ERROR"
end

function Audio:SetVolume(id, value)
    local state = self:Get(id)
    local percent = Audio.Percent(value)
    if not state or not state.adjustable or not percent then return false, "READ_ERROR" end
    return self:Commit(state.channel.volume, string.format("%.2f", percent / 100))
end

function Audio:SetEnabled(id, enabled)
    local state = self:Get(id)
    if not state or not state.togglable then return false, "READ_ERROR" end
    return self:Commit(state.channel.enabled, enabled and "1" or "0")
end

function Audio:Toggle(id)
    local state = self:Get(id)
    if not state then return false, "READ_ERROR" end
    return self:SetEnabled(id, not state.enabled)
end

function Audio:Step(id, delta, fine)
    local state = self:Get(id)
    if not state or not state.adjustable then return false, "READ_ERROR" end
    return self:SetVolume(id, state.percent + delta * (fine and 1 or 5))
end
