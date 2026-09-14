-- Deliberately bounded frame double: unknown methods fail instead of silently succeeding.
Mock = { objects = {}, writes = {}, messages = {}, time = 10, locale = 'deDE', retail = true }
local methods = {}
local function object(kind, name, parent)
    local o = setmetatable({ kind=kind, name=name, parent=parent, scripts={}, points={}, shown=true,
        width=0, height=0, level=1, enabled=true, alpha=1 }, { __index = methods })
    table.insert(Mock.objects, o)
    if name then _G[name] = o end
    return o
end
function methods:SetSize(w,h) local changed=self.width~=w or self.height~=h;self.width,self.height=w,h;if changed then self:Fire('OnSizeChanged',w,h) end end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) table.insert(self.points, {...}) end
function methods:GetPoint(i) return unpack(self.points[i or 1] or {}) end
function methods:ClearAllPoints() self.points={} end
function methods:SetAllPoints(...) self.allPoints={...} end
function methods:SetScale(v) self.scale=v end
function methods:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
local function coordinates(o)
    if o==UIParent then return 0,0,o.width*o:GetEffectiveScale(),o.height*o:GetEffectiveScale() end
    local p=o.points[1] or {'CENTER'};local point,relative,rpoint,x,y=p[1],p[2],p[3],p[4],p[5]
    if type(relative)~='table' then x,y=relative,rpoint;relative=o.parent or UIParent;rpoint=point end
    local l,b,w,h=coordinates(relative)
    local function fraction(s) return s:find('LEFT') and 0 or (s:find('RIGHT') and 1 or .5),s:find('BOTTOM') and 0 or (s:find('TOP') and 1 or .5) end
    local rx,ry=fraction(rpoint or point);local ax,ay=fraction(point)
    local scale=o:GetEffectiveScale();local ow,oh=o.width*scale,o.height*scale
    return l+w*rx+(x or 0)*scale-ow*ax,b+h*ry+(y or 0)*scale-oh*ay,ow,oh
end
function methods:GetCenter() local l,b,w,h=coordinates(self);local s=self:GetEffectiveScale();return (l+w/2)/s,(b+h/2)/s end
function methods:GetLeft() local l=coordinates(self);return l/self:GetEffectiveScale() end
function methods:GetTop() local _,b,_,h=coordinates(self);return (b+h)/self:GetEffectiveScale() end
function methods:SetFont(path,size,flags) self.fontPath,self.fontSize=path,size end
function methods:SetWordWrap(value) self.wordWrap=value end
function methods:SetScript(event, fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:HookScript(event,fn)
    local old=self.scripts[event]
    self.scripts[event]=function(...) if old then old(...) end; fn(...) end
end
function methods:Fire(event, ...) if self.scripts[event] then return self.scripts[event](self,...) end end
function methods:RegisterEvent(event) self.events=self.events or {}; self.events[event]=true end
function methods:SetShown(value)
    local old=self.shown; self.shown=not not value
    if old~=self.shown then self:Fire(self.shown and 'OnShow' or 'OnHide') end
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:IsShown() return self.shown end
function methods:SetBackdrop(value) self.backdrop=value end
function methods:SetBackdropColor(...) self.backdropColor={...} end
function methods:SetBackdropBorderColor(...) self.backdropBorderColor={...} end
function methods:SetFrameStrata(v) self.strata=v end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level end
function methods:EnableMouse(v) self.mouse=v end
function methods:EnableMouseWheel(v) self.wheel=v end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:RegisterForDrag(...) self.drags={...} end
function methods:SetMovable(v) self.movable=v end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:SetEnabled(v) self.enabled=v end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:CreateTexture(name,layer) local t=object('Texture',name,self); t.layer=layer; return t end
function methods:CreateFontString(name,layer,font) local t=object('FontString',name,self); t.layer=layer; t.font=font; return t end
function methods:SetText(text) self.textValue=tostring(text) end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetJustifyH(v) self.justify=v end
function methods:SetTexture(v) self.texturePath=v end
function methods:SetTexCoord(...) self.uv={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetBlendMode(v) self.blend=v end
function methods:SetRotation(v) self.rotation=v end
function methods:SetDesaturated(v) self.desaturated=v end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetMinMaxValues(a,b) self.min,self.max=a,b end
function methods:SetOrientation(v) self.orientation=v end
function methods:SetValueStep(v) self.step=v end
function methods:SetObeyStepOnDrag(v) self.obeyStep=v end
function methods:SetValue(v)
    if self.value==v then return end
    self.value=v; self:Fire('OnValueChanged',v)
end
function methods:GetValue() return self.value end
function methods:SetStatusBarTexture(v) self.statusTexture=v end
function methods:SetStatusBarColor(...) self.statusColor={...} end
function methods:SetThumbTexture(v) self.thumb=object('Texture',nil,self); self.thumb:SetTexture(v) end
function methods:GetThumbTexture() return self.thumb end

function CreateFrame(kind,name,parent,template) local o=object(kind,name,parent); o.template=template; return o end
UIParent=object('Frame','UIParent'); UIParent:SetSize(1920,1080)
Minimap=object('Frame','Minimap',UIParent); Minimap:SetSize(140,140)
BackdropTemplateMixin={}
UISpecialFrames={}
SlashCmdList={}
WOW_PROJECT_MAINLINE=1
WOW_PROJECT_ID=1
function GetLocale() return Mock.locale end
function GetTime() return Mock.time end
function IsShiftKeyDown() return Mock.shift or false end
function IsLoggedIn() return false end
function GetMinimapShape() return Mock.minimapShape or 'ROUND' end
function GetCursorPosition() return 1000,600 end
function GetPhysicalScreenSize() return Mock.physicalWidth or 1920,Mock.physicalHeight or 1080 end
DEFAULT_CHAT_FRAME={AddMessage=function(_,v) table.insert(Mock.messages,v) end}
GameTooltip={SetOwner=function() end, SetText=function() end, AddLine=function() end, Show=function() end, Hide=function() end}

Mock.cvars={Sound_MasterVolume='0.8',Sound_SFXVolume='0.6',Sound_MusicVolume='0.25',
    Sound_EnableAllSound='1',Sound_EnableSFX='1',Sound_EnableMusic='1',Sound_AmbienceVolume='0.45',Sound_DialogVolume='0.9',Sound_OutputDriverIndex='0'}
Mock.devices={'System Default','Speakers','Headset'};Mock.restarts=0
function Sound_GameSystem_GetNumOutputDrivers() if Mock.deviceError then error('unavailable') end;return #Mock.devices end
function Sound_GameSystem_GetOutputDriverNameByIndex(i) return Mock.devices[i+1] end
function Sound_GameSystem_RestartSoundSystem() if Mock.restartError then error('restart denied') end;Mock.restarts=Mock.restarts+1 end
function Mock.read(name) if Mock.throwRead then error('missing API') end; return Mock.cvars[name] end
function Mock.write(name,value)
    if Mock.throwWrite then error('restricted write') end
    if Mock.rejectWrite then return false end
    table.insert(Mock.writes,{name,value})
    if not Mock.ignoreWrite then Mock.cvars[name]=tostring(value) end
    -- Fire synchronously, as the client can, to catch UI feedback loops.
    for _,o in ipairs(Mock.objects) do if o.events and o.events.CVAR_UPDATE then o:Fire('OnEvent','CVAR_UPDATE',name,tostring(value)) end end
    if Mock.legacyReturn then return nil end
    return true
end
C_CVar={GetCVar=Mock.read,SetCVar=Mock.write}
GetCVar=Mock.read
SetCVar=Mock.write
