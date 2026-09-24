local _, A = ...
local C = {}
A.Compat = C

function C.Read(name)
    local fn = C_CVar and C_CVar.GetCVar or GetCVar
    if not fn then return nil end
    local ok, value = pcall(fn, name)
    if ok then return value end
    return nil
end

function C.Write(name, value)
    local fn = C_CVar and C_CVar.SetCVar or SetCVar
    if not fn then return false end
    local ok, result = pcall(fn, name, tostring(value))
    return ok and result ~= false
end

function C.IsRetail()
    return WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end

function C.HasAddonCompartment()
    return type(AddonCompartmentFrame) == "table" and type(AddonCompartmentFrame.RegisterAddon) == "function"
end

function C.Frame(kind, name, parent)
    return CreateFrame(kind, name, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
end

function C.Now()
    return GetTime and GetTime() or 0
end

function C.Version()
    local read=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    if read then local ok,value=pcall(read,'Soundstone','Version');if ok and value then return value end end
    return 'dev'
end

function C.OutputDevices()
    if type(Sound_GameSystem_GetNumOutputDrivers)~='function' or type(Sound_GameSystem_GetOutputDriverNameByIndex)~='function' then return nil end
    local ok,count=pcall(Sound_GameSystem_GetNumOutputDrivers)
    if not ok or type(count)~='number' or count<0 or count>256 or count~=math.floor(count) then return nil end
    local items={}
    for i=0,count-1 do
        local read,name=pcall(Sound_GameSystem_GetOutputDriverNameByIndex,i)
        if read and type(name)=='string' and name~='' then items[#items+1]={index=i,name=name} end
    end
    return items
end
function C.CanRestartSound() return type(Sound_GameSystem_RestartSoundSystem)=='function' end
function C.RestartSound()
    if not C.CanRestartSound() then return false end
    local ok,value=pcall(Sound_GameSystem_RestartSoundSystem)
    return ok and value~=false
end
function C.Pixel(value, frame)
    if PixelUtil and PixelUtil.GetNearestPixelSize then return PixelUtil.GetNearestPixelSize(value,frame:GetEffectiveScale()) end
    local height=768
    if GetPhysicalScreenSize then local _,h=GetPhysicalScreenSize();height=h or 768 end
    local scale=frame:GetEffectiveScale()*height/768
    return math.floor(value*scale+.5)/scale
end
