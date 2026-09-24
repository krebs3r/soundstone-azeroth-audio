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

-- WoW: Forever runs the Retail API (project MAINLINE) under interface 16xxx.
function C.IsForever()
    if type(GetBuildInfo) ~= "function" then return false end
    local ok, _, _, _, interface = pcall(GetBuildInfo)
    return ok and type(interface) == "number" and interface >= 16000 and interface < 17000
end

-- Retail artwork only for modern Retail; Forever keeps the Classic look.
function C.RetailStyle()
    return C.IsRetail() and not C.IsForever()
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

-- Some clients (seen in the WoW: Forever beta) return Windows-1252 device names.
-- Valid UTF-8 is returned unchanged; anything else is converted byte by byte.
local cp1252={[128]=0x20AC,[130]=0x201A,[131]=0x0192,[132]=0x201E,[133]=0x2026,[134]=0x2020,[135]=0x2021,
    [136]=0x02C6,[137]=0x2030,[138]=0x0160,[139]=0x2039,[140]=0x0152,[142]=0x017D,[145]=0x2018,[146]=0x2019,
    [147]=0x201C,[148]=0x201D,[149]=0x2022,[150]=0x2013,[151]=0x2014,[152]=0x02DC,[153]=0x2122,[154]=0x0161,
    [155]=0x203A,[156]=0x0153,[158]=0x017E,[159]=0x0178}
local function validUtf8(text)
    local i,n=1,#text
    while i<=n do
        local c=text:byte(i);local len
        if c<0x80 then len=1 elseif c>=0xC2 and c<=0xDF then len=2 elseif c>=0xE0 and c<=0xEF then len=3
        elseif c>=0xF0 and c<=0xF4 then len=4 else return false end
        if i+len-1>n then return false end
        for j=i+1,i+len-1 do local b=text:byte(j);if b<0x80 or b>0xBF then return false end end
        i=i+len
    end
    return true
end
local function encode(code)
    if code<0x80 then return string.char(code)
    elseif code<0x800 then return string.char(0xC0+math.floor(code/64),0x80+code%64) end
    return string.char(0xE0+math.floor(code/4096),0x80+math.floor(code/64)%64,0x80+code%64)
end
function C.Utf8(text)
    if validUtf8(text) then return text end
    return (text:gsub('[\128-\255]',function(ch) local b=ch:byte();return encode(cp1252[b] or (b>=0xA0 and b) or 0xFFFD) end))
end

function C.OutputDevices()
    if type(Sound_GameSystem_GetNumOutputDrivers)~='function' or type(Sound_GameSystem_GetOutputDriverNameByIndex)~='function' then return nil end
    local ok,count=pcall(Sound_GameSystem_GetNumOutputDrivers)
    if not ok or type(count)~='number' or count<0 or count>256 or count~=math.floor(count) then return nil end
    local items={}
    for i=0,count-1 do
        local read,name=pcall(Sound_GameSystem_GetOutputDriverNameByIndex,i)
        if read and type(name)=='string' and name~='' then items[#items+1]={index=i,name=C.Utf8(name)} end
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
