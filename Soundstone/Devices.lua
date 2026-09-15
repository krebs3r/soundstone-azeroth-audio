local _, A = ...
local Devices = {}
Devices.__index = Devices
A.Devices = Devices

function Devices.New(adapter, changed)
    return setmetatable({adapter=adapter, changed=changed}, Devices)
end

function Devices:Get()
    local list = self.adapter.OutputDevices()
    local current = tonumber(self.adapter.Read('Sound_OutputDriverIndex'))
    local state = {items=list or {}, current=current, available=list ~= nil, selected=nil}
    for _, item in ipairs(state.items) do
        if item.index == current then state.selected=item end
    end
    return state
end

function Devices:Select(index, expectedName)
    if self.changing then return false, 'DEVICE_BUSY' end
    local state = self:Get()
    local selected
    for _, item in ipairs(state.items) do
        if item.index == index and item.name == expectedName then selected=item; break end
    end
    if not selected then return false, 'DEVICE_GONE' end
    if state.current == index then return true end
    if not self.adapter.CanRestartSound() then return false, 'DEVICE_UNAVAILABLE' end
    self.changing = true
    local ok = self.adapter.Write('Sound_OutputDriverIndex', index)
    ok = ok and tonumber(self.adapter.Read('Sound_OutputDriverIndex')) == index
    local restarted = ok and self.adapter.RestartSound()
    local retained = restarted and tonumber(self.adapter.Read('Sound_OutputDriverIndex')) == index
    self.changing = false
    if self.changed then self.changed() end
    if not ok then return false, 'WRITE_ERROR' end
    if not restarted then return false, 'DEVICE_RESTART_ERROR' end
    if not retained then return false, 'WRITE_ERROR' end
    return true
end
