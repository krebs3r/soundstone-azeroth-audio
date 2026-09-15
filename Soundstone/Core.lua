local addonName, A = ...
Soundstone = A
local L,C,Layout=A.L,A.Compat,A.Layout
function A:Print(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffcc4dSoundstone:|r '..text) end
end
function A:Result(ok,err)
    if not ok and (not self.lastError or C.Now()-self.lastError>1) then
        self:Print(L[err] or L.WRITE_ERROR); self.lastError=C.Now()
    end
    return ok
end
function A:Toggle(id) if self.audio then return self:Result(self.audio:Toggle(id)) end end
function A:SetVolume(id,value) if self.audio then return self:Result(self.audio:SetVolume(id,value)) end end
function A:Step(id,delta) if self.audio then return self:Result(self.audio:Step(id,delta,IsShiftKeyDown and IsShiftKeyDown())) end end
function A:SetView(mode)
    self.UI:CancelPlacement()
    local previous=self.db.viewMode
    local origin=self.db.position
    self.db.viewMode=mode=='expanded' and 'expanded' or 'compact'
    self.db.showBar=true
    self.UI:CloseMenus(); self.UI:Refresh()
    if previous=='compact' and self.db.viewMode=='expanded' then self.UI:BeginPlacement(origin,previous) end
end
function A:TogglePanel()
    if not self.db.showBar then self:SetVisible(true)
    else self:SetView(self.db.viewMode=='expanded' and 'compact' or 'expanded') end
end
function A:SetVisible(visible)
    local wasVisible=self.db.showBar
    self.db.showBar=visible and true or false
    self.UI:CancelScale();self.UI:CloseMenus();self.UI:Refresh()
    if wasVisible and not self.db.showBar then self:Print(L.HIDDEN) end
end
function A:SetScale(value)
    self.UI.pendingScale=nil
    self.db.uiScale=Layout.Scale(value); self.UI:ApplyLayout(); self.UI:Refresh()
end
function A:SavePosition(frame)
    local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local px,py=UIParent:GetCenter()
    local x,y=frame:GetLeft(),frame:GetTop()
    if x and y and px and py then self.db.position={x=x*scale-px,y=y*scale-py} end
end
function A:ResetPositions()
    self.db.position=Layout.LegacyPosition(nil,UIParent:GetWidth(),UIParent:GetHeight())
    self.db.minimapAngle=225; self.UI:ApplyLayout(); self.UI:PositionMinimap()
end
function A:Command(message)
    local cmd,arg=(message or ''):lower():match('^%s*(%S*)%s*(.-)%s*$')
    if cmd=='' then self:TogglePanel()
    elseif cmd=='compact' or cmd=='expand' then self:SetView(cmd=='expand' and 'expanded' or 'compact')
    elseif cmd=='hide' or cmd=='show' then self:SetVisible(cmd=='show')
    elseif cmd=='bar' then self:SetVisible(not self.db.showBar)
    elseif cmd=='minimap' then self.db.showMinimap=not self.db.showMinimap; self.UI:Refresh()
    elseif cmd=='lock' then self.db.locked=not self.db.locked; self.UI:Refresh()
    elseif cmd=='reset' then self:ResetPositions()
    elseif cmd=='scale' and tonumber(arg) then self:SetScale(tonumber(arg)/100)
    elseif cmd=='help' then self:Print(L.HELP)
    elseif cmd=='master' or cmd=='sfx' or cmd=='music' then
        if arg=='on' or arg=='off' then self:Result(self.audio:SetEnabled(cmd,arg=='on'))
        elseif arg=='' or arg=='toggle' then self:Toggle(cmd)
        elseif tonumber(arg) then self:SetVolume(cmd,tonumber(arg))
        else self:Print(L.BAD_COMMAND) end
    else self:Print(L.BAD_COMMAND) end
end
function A:Initialize()
    if self.initialized then return end
    self.initialized=true
    if type(SoundstoneDB)~='table' then SoundstoneDB={} end
    self.db=SoundstoneDB
    local db=self.db
    for key,value in pairs({showBar=true,showMinimap=true,locked=false,avoidOverlap=true}) do
        if type(db[key])~='boolean' then db[key]=value end
    end
    if db.schema~=2 or type(db.position)~='table' then
        local old=type(db.positions)=='table' and db.positions.bar
        db.position=Layout.LegacyPosition(old,UIParent:GetWidth(),UIParent:GetHeight())
    end
    db.position.x=Layout.Number(db.position.x,-168); db.position.y=Layout.Number(db.position.y,-157)
    db.viewMode=db.viewMode=='expanded' and 'expanded' or 'compact'
    db.uiScale=Layout.Scale(db.uiScale)
    db.minimapAngle=Layout.Number(db.minimapAngle,225)%360
    db.schema=2; db.positions=nil
    self.audio=self.Audio.New(C,function() self.UI:Refresh() end,db.lastVolumes)
    db.lastVolumes=self.audio.history
    self.devices=self.Devices.New(C,function() self.UI:RefreshDevices() end)
    self.UI:Create()
    SLASH_SOUNDSTONE1,SLASH_SOUNDSTONE2='/soundstone','/azeraudio'
    SlashCmdList.SOUNDSTONE=function(message) self:Command(message) end
    if not db.welcomed then self:Print(L.WELCOME);db.welcomed=true end
end
local events=CreateFrame('Frame')
A.events=events
for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','PLAYER_ENTERING_WORLD','CVAR_UPDATE','DISPLAY_SIZE_CHANGED','UI_SCALE_CHANGED','SOUND_DEVICE_UPDATE'}) do
    pcall(events.RegisterEvent,events,event)
end
events:SetScript('OnEvent',function(_,event,arg)
    if event=='ADDON_LOADED' and arg==addonName then
        if IsLoggedIn and IsLoggedIn() then A:Initialize() end
    elseif event=='PLAYER_LOGIN' then A:Initialize()
    elseif A.initialized then
        if event=='CVAR_UPDATE' then
            local name=tostring(arg or ''):lower()
            if name=='' or name:find('sound',1,true) then A.UI:Refresh() end
            if name=='' or name=='sound_outputdriverindex' then A.UI:RefreshDevices() end
            if name=='uiscale' or name=='useuiscale' then A.UI:ApplyLayout() end
        elseif event=='SOUND_DEVICE_UPDATE' then A.UI:RefreshDevices()
        elseif event=='PLAYER_ENTERING_WORLD' or event=='DISPLAY_SIZE_CHANGED' or event=='UI_SCALE_CHANGED' then
            A.UI:ApplyLayout(); A.UI:PositionMinimap(); A.UI:Refresh()
        end
    end
end)
