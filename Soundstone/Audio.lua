-- Audio state and commands share one view of the effective output path.
local _, A = ...
local Audio={};Audio.__index=Audio;A.Audio=Audio
Audio.channels={
    {id='master',label='MASTER',volume='Sound_MasterVolume',enabled='Sound_EnableAllSound',help='MASTER_HELP'},
    {id='sfx',label='SFX',volume='Sound_SFXVolume',enabled='Sound_EnableSFX',help='SFX_HELP'},
    {id='music',label='MUSIC',volume='Sound_MusicVolume',enabled='Sound_EnableMusic',help='MUSIC_HELP'},
}
local definitions={
    master={volume='Sound_MasterVolume',enabled='Sound_EnableAllSound',label='MASTER',fallback=.5},
    sfx={volume='Sound_SFXVolume',enabled='Sound_EnableSFX',label='EFFECTS',fallback=.5},
    ambience={volume='Sound_AmbienceVolume',enabled='Sound_EnableAmbience',label='AMBIENCE',fallback=.5},
    dialog={volume='Sound_DialogVolume',enabled='Sound_EnableDialog',label='DIALOG',fallback=.5},
    music={volume='Sound_MusicVolume',enabled='Sound_EnableMusic',label='MUSIC',fallback=.25},
}
local order={'master','sfx','ambience','dialog','music'}
local byID={};for _,channel in ipairs(Audio.channels) do byID[channel.id]=channel end
local function finite(value)
    value=tonumber(value)
    if value and value==value and value~=math.huge and value~=-math.huge then return value end
end
function Audio.Percent(value)
    value=finite(value)
    if value then return math.floor(math.max(0,math.min(100,value))+.5) end
end
function Audio.New(adapter,changed,history)
    local self=setmetatable({adapter=adapter,changed=changed,history=type(history)=='table' and history or {}},Audio)
    for key,value in pairs(self.history) do
        local number=finite(value)
        if not definitions[key] or not number or number<=0 or number>1 then self.history[key]=nil else self.history[key]=number end
    end
    return self
end
function Audio:Snapshot()
    local snapshot={}
    for _,id in ipairs(order) do
        local def=definitions[id]
        local volume=finite(self.adapter.Read(def.volume))
        local switch=tostring(self.adapter.Read(def.enabled))
        local member={id=id,definition=def,volume=volume,enabled=switch=='1',togglable=switch=='0' or switch=='1'}
        member.available=member.togglable and volume~=nil
        member.audible=member.available and member.enabled and volume>0
        snapshot[id]=member
        if not self.changing and volume and volume>0 and volume<=1 then self.history[id]=volume end
    end
    return snapshot
end
local function group(snapshot,id)
    if id~='sfx' then return {snapshot[id]} end
    local members={snapshot.sfx}
    -- Optional channels are included when the client exposes their switches.
    for _,key in ipairs({'ambience','dialog'}) do
        if snapshot[key].togglable then members[#members+1]=snapshot[key] end
    end
    return members
end
local function anyAudible(snapshot)
    for _,id in ipairs({'sfx','ambience','dialog','music'}) do if snapshot[id].audible then return true end end
    return false
end
function Audio:Get(id)
    local channel=byID[id];if not channel then return nil end
    local snapshot=self:Snapshot();local primary=snapshot[id];local master=snapshot.master
    local members=group(snapshot,id)
    local state={id=id,channel=channel,members=members,adjustable=primary.volume~=nil,
        togglable=primary.togglable,enabled=primary.enabled,available=primary.available,
        percent=primary.volume and Audio.Percent(primary.volume*100) or nil}
    local localAudible=false;local allAudible=true
    for _,member in ipairs(members) do
        state.available=state.available and member.available
        localAudible=localAudible or member.audible;allAudible=allAudible and member.audible
    end
    if id~='master' then state.available=state.available and master.available end
    local open=master.available and master.enabled and master.volume>0
    state.audible=state.available and open and (id=='master' and anyAudible(snapshot) or id~='master' and localAudible) or false
    for _,member in ipairs(members) do member.effective=member.audible and open end
    if not state.available then state.reason='UNAVAILABLE'
    elseif not master.enabled then state.reason=id=='master' and 'OFF' or 'MASTER_OFF'
    elseif master.volume==0 then state.reason=id=='master' and 'ZERO' or 'MASTER_ZERO'
    elseif not state.audible then state.reason=primary.volume==0 and 'ZERO' or 'OFF'
    elseif not allAudible then state.reason='GROUP_PARTIAL' end
    return state
end
local function equal(a,b)
    a,b=finite(a),finite(b)
    return a~=nil and b~=nil and math.abs(a-b)<.000001
end
-- Preflight, ordered writes, readback and reverse rollback. No UI refresh observes a half-written group.
function Audio:Apply(operations,postcondition)
    if self.changing then return false,'AUDIO_BUSY' end
    local changes={}
    for _,op in ipairs(operations) do
        op.before=self.adapter.Read(op.name)
        if not finite(op.before) then return false,'READ_ERROR' end
        if not equal(op.before,op.value) then changes[#changes+1]=op end
    end
    self.changing=true
    local attempted={};local ok=true
    for _,op in ipairs(changes) do
        attempted[#attempted+1]=op
        local accepted=self.adapter.Write(op.name,op.value)
        if not accepted or not equal(self.adapter.Read(op.name),op.value) then ok=false;break end
    end
    if ok then
        for _,op in ipairs(operations) do if not equal(self.adapter.Read(op.name),op.value) then ok=false;break end end
    end
    if ok and postcondition then ok=postcondition() and true or false end
    local restored=true
    if not ok then
        for i=#attempted,1,-1 do
            local op=attempted[i]
            if not equal(self.adapter.Read(op.name),op.before) then self.adapter.Write(op.name,op.before) end
        end
        for _,op in ipairs(attempted) do if not equal(self.adapter.Read(op.name),op.before) then restored=false end end
    end
    self.changing=false
    self:Snapshot()
    if self.changed then self.changed() end
    if ok then return true end
    return false,restored and 'WRITE_ERROR' or 'AUDIO_RESTORE_ERROR'
end
local function add(operations,name,value) operations[#operations+1]={name=name,value=tostring(value)} end
function Audio:RestoreVolume(operations,member)
    if member.volume==0 then
        local value=self.history[member.id] or member.definition.fallback
        add(operations,member.definition.volume,string.format('%.6f',value))
    end
end
function Audio:SetVolume(id,value)
    local state=self:Get(id);local percent=Audio.Percent(value)
    if not state or not state.adjustable or not percent then return false,'READ_ERROR' end
    local operations={}
    for _,member in ipairs(state.members) do
        if member.volume==nil then return false,'READ_ERROR' end
        add(operations,member.definition.volume,string.format('%.2f',percent/100))
    end
    return self:Apply(operations)
end
function Audio:SetEnabled(id,enabled)
    local state=self:Get(id)
    if not state or not state.available then return false,'READ_ERROR' end
    if enabled and id=='master' and state.audible then return true end
    local snapshot=self:Snapshot();local master=snapshot.master;local operations={}
    if not enabled then
        for _,member in ipairs(group(snapshot,id)) do add(operations,member.definition.enabled,'0') end
    elseif id=='master' then
        -- Restore the saved channel selection. If everything is individually off, turn both groups on.
        local anyEnabled=false
        for _,key in ipairs({'sfx','ambience','dialog','music'}) do
            anyEnabled=anyEnabled or snapshot[key].available and snapshot[key].enabled
        end
        for _,key in ipairs({'sfx','ambience','dialog','music'}) do
            local member=snapshot[key]
            if member.available and (member.enabled or not anyEnabled) then
                self:RestoreVolume(operations,member);add(operations,member.definition.enabled,'1')
            end
        end
        self:RestoreVolume(operations,master)
        add(operations,master.definition.enabled,'1')
    else
        local blocked=not master.enabled or master.volume==0
        -- Mute the other group BEFORE reopening the shared master path.
        if blocked then
            for _,member in ipairs(group(snapshot,id=='music' and 'sfx' or 'music')) do
                if not member.togglable then return false,'READ_ERROR' end
                add(operations,member.definition.enabled,'0')
            end
        end
        for _,member in ipairs(group(snapshot,id)) do
            if not member.available then return false,'READ_ERROR' end
            self:RestoreVolume(operations,member);add(operations,member.definition.enabled,'1')
        end
        self:RestoreVolume(operations,master)
        add(operations,master.definition.enabled,'1')
    end
    return self:Apply(operations,function() return self:Get(id).audible==(enabled and true or false) end)
end
function Audio:Toggle(id)
    local state=self:Get(id)
    if not state then return false,'READ_ERROR' end
    return self:SetEnabled(id,not state.audible)
end
function Audio:Step(id,delta,fine)
    local state=self:Get(id)
    if not state or not state.adjustable then return false,'READ_ERROR' end
    return self:SetVolume(id,state.percent+delta*(fine and 1 or 5))
end
