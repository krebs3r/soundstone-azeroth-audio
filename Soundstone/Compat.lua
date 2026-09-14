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

function C.Frame(kind, name, parent)
    return CreateFrame(kind, name, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
end

function C.Now()
    return GetTime and GetTime() or 0
end
