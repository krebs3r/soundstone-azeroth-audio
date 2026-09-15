local A=Soundstone
local passed=0
local original={cvars=Mock.cvars,writes=Mock.writes,audio=A.audio,history=A.audio.history}
local function copy(t) local result={};for k,v in pairs(t) do result[k]=v end;return result end
local base={Sound_EnableAllSound='1',Sound_EnableMusic='1',Sound_EnableSFX='1',Sound_EnableAmbience='1',Sound_EnableDialog='1',
    Sound_MasterVolume='0.8',Sound_MusicVolume='0.25',Sound_SFXVolume='0.6',Sound_AmbienceVolume='0.45',Sound_DialogVolume='0.9',
    Sound_OutputDriverIndex='0',VoiceChatMasterVolumeScale='0.7',Sound_EnablePetSounds='0',Sound_EnableErrorSpeech='0'}
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function number(name) return tonumber(Mock.cvars[name]) end
local function reset()
    A.audio=original.audio;A.audio.history={};A.db.lastVolumes=A.audio.history
    Mock.cvars=copy(base);Mock.writes={};Mock.writeAttempts=0;Mock.rejectAt=nil;Mock.rejectValues=nil;Mock.afterWrite=nil
    A.UI:Refresh()
end
local function test(name,fn) reset();fn();passed=passed+1;print('PASS '..name) end
local function display(id,on)
    eq(A.UI.rows[id].toggle.text.textValue,on and A.L.ON or A.L.OFF)
    eq(A.UI.rows[id].icon.texture.desaturated,not on)
    eq(A.UI.barControls[id].icon.texture.desaturated,not on)
    eq(A.audio:Get(id).audible,on)
end
local function same(before)
    for key,value in pairs(before) do eq(Mock.cvars[key],value) end
end
test('master mute updates every button and restores the remembered individual selection',function()
    Mock.cvars.Sound_EnableMusic='0';A.UI:Refresh();local before=copy(Mock.cvars)
    A.UI.rows.master.toggle:Fire('OnClick','LeftButton')
    for _,id in ipairs({'master','sfx','music'}) do display(id,false) end
    eq(number('Sound_EnableSFX'),1);eq(number('Sound_EnableAmbience'),1);eq(number('Sound_EnableDialog'),1)
    eq(A.UI.rows.sfx.value.textValue,'60 %');eq(A.UI.rows.music.value.textValue,'25 %')
    A.UI.rows.master.toggle:Fire('OnClick','LeftButton');display('master',true);display('sfx',true);display('music',false)
    same(before)
end)
test('192 switch/zero combinations use the same effective state for display and toggling',function()
    for m=0,1 do for fx=0,1 do for music=0,1 do for mv=0,1 do for fv=0,1 do for uv=0,1 do
        for _,target in ipairs({'master','sfx','music'}) do
            reset()
            Mock.cvars.Sound_EnableAllSound=tostring(m);Mock.cvars.Sound_EnableMusic=tostring(music)
            for _,key in ipairs({'SFX','Ambience','Dialog'}) do Mock.cvars['Sound_Enable'..key]=tostring(fx);Mock.cvars['Sound_'..key..'Volume']=tostring(fv*.6) end
            Mock.cvars.Sound_MasterVolume=tostring(mv*.8);Mock.cvars.Sound_MusicVolume=tostring(uv*.25);A.UI:Refresh()
            local gate=m==1 and mv==1
            local audible={sfx=gate and fx==1 and fv==1,music=gate and music==1 and uv==1}
            audible.master=audible.sfx or audible.music
            for id,on in pairs(audible) do display(id,on) end
            eq(A.audio:Toggle(target),true);display(target,not audible[target])
            if target~='master' and not audible[target] then
                display('master',true)
                if not gate then display(target=='music' and 'sfx' or 'music',false) end
            end
            eq(Mock.cvars.VoiceChatMasterVolumeScale,base.VoiceChatMasterVolumeScale)
            eq(Mock.cvars.Sound_EnablePetSounds,'0');eq(Mock.cvars.Sound_EnableErrorSpeech,'0')
        end
    end end end end end end
end)
test('music-only activation silences the sound group before opening either kind of master gate',function()
    for _,gate in ipairs({'Sound_EnableAllSound','Sound_MasterVolume'}) do
        reset();Mock.cvars[gate]='0';A.UI:Refresh()
        Mock.afterWrite=function()
            if number('Sound_EnableAllSound')==1 and number('Sound_MasterVolume')>0 then
                for _,key in ipairs({'SFX','Ambience','Dialog'}) do eq(number('Sound_Enable'..key),0) end
            end
        end
        A.UI.barControls.music:Fire('OnClick','LeftButton');Mock.afterWrite=nil
        display('music',true);display('sfx',false);display('master',true)
    end
end)
test('sound-only activation includes ambience/dialogue and preserves their positive levels',function()
    Mock.cvars.Sound_EnableAllSound='0';A.UI:Refresh()
    A:Command('sfx on')
    display('sfx',true);display('music',false);display('master',true)
    eq(number('Sound_EnableAmbience'),1);eq(number('Sound_EnableDialog'),1)
    eq(number('Sound_SFXVolume'),.6);eq(number('Sound_AmbienceVolume'),.45);eq(number('Sound_DialogVolume'),.9)
    A:Command('sfx off');display('sfx',false);display('master',false)
    eq(number('Sound_EnableAmbience'),0);eq(number('Sound_EnableDialog'),0)
end)
test('compact icon, mixer icon, mixer button and slash commands share activation behavior',function()
    for _,action in ipairs({function() A.UI.barControls.music:Fire('OnClick','LeftButton') end,
        function() A.UI.rows.music.iconButton:Fire('OnClick','LeftButton') end,
        function() A.UI.rows.music.toggle:Fire('OnClick','LeftButton') end,
        function() A:Command('music on') end,function() A:Command('music toggle') end,
        function() A:Toggle('music') end}) do
        reset();Mock.cvars.Sound_EnableAllSound='0';A.UI:Refresh();action()
        display('music',true);display('sfx',false);display('master',true)
    end
end)
test('the sound-group slider changes all three levels without enabling muted switches',function()
    A.audio:SetEnabled('sfx',false);A.audio:SetEnabled('master',false)
    A.UI.rows.sfx.slider:SetValue(35)
    for _,key in ipairs({'SFX','Ambience','Dialog'}) do eq(number('Sound_'..key..'Volume'),.35);eq(number('Sound_Enable'..key),0) end
    eq(number('Sound_MusicVolume'),.25);eq(number('Sound_EnableAllSound'),0)
    A.UI.barControls.sfx:Fire('OnMouseWheel',1)
    for _,key in ipairs({'SFX','Ambience','Dialog'}) do eq(number('Sound_'..key..'Volume'),.4) end
end)
test('zero-volume activation restores observed external values across a model reload',function()
    Mock.cvars.Sound_MusicVolume='0.137';A.events:Fire('OnEvent','CVAR_UPDATE','Sound_MusicVolume')
    Mock.cvars.Sound_MusicVolume='0';Mock.cvars.Sound_MasterVolume='0';A.UI:Refresh()
    local history=A.db.lastVolumes;local before=#Mock.writes
    A.audio=A.Audio.New(A.Compat,function() A.UI:Refresh() end,history);A.UI:Refresh()
    eq(#Mock.writes,before);eq(A.audio:Toggle('music'),true)
    eq(number('Sound_MusicVolume'),.137);eq(number('Sound_MasterVolume'),.8);display('sfx',false)
end)
test('first-start zero values and corrupt history use bounded defaults only upon enabling',function()
    Mock.cvars.Sound_MasterVolume='0';Mock.cvars.Sound_MusicVolume='0'
    A.audio=A.Audio.New(A.Compat,function() A.UI:Refresh() end,{master=0/0,music=-4,unknown=1,sfx='bad'})
    A.db.lastVolumes=A.audio.history;A.UI:Refresh();eq(#Mock.writes,0)
    eq(A.audio:Toggle('music'),true);eq(number('Sound_MasterVolume'),.5);eq(number('Sound_MusicVolume'),.25)
    eq(A.audio.history.unknown,nil)
end)
test('enabling master when all channels are individually off restores usable sound',function()
    for _,key in ipairs({'SFX','Ambience','Dialog','Music'}) do Mock.cvars['Sound_Enable'..key]='0';Mock.cvars['Sound_'..key..'Volume']='0' end
    A.UI:Refresh();display('master',false);eq(A.audio:Toggle('master'),true)
    display('master',true);display('sfx',true);display('music',true)
    eq(number('Sound_SFXVolume'),.6);eq(number('Sound_AmbienceVolume'),.45);eq(number('Sound_DialogVolume'),.9)
end)
test('mixed external group settings display active when any member can play',function()
    Mock.cvars.Sound_EnableSFX='0';Mock.cvars.Sound_EnableDialog='0';Mock.cvars.Sound_EnableMusic='0'
    A.events:Fire('OnEvent','CVAR_UPDATE','Sound_EnableSFX')
    display('sfx',true);display('master',true);eq(A.audio:Get('sfx').reason,'GROUP_PARTIAL');eq(#Mock.writes,0)
    A.UI.rows.sfx.toggle:Fire('OnEnter');assert(Mock.tooltip.line:find(A.L.TIP_SFX,1,true))
    eq(A.audio:Toggle('sfx'),true);display('master',false);display('sfx',false)
end)
test('explicit on/off commands are idempotent and do not resurrect unrelated zero-volume music',function()
    Mock.cvars.Sound_MusicVolume='0';A.UI:Refresh();eq(A.audio:SetEnabled('master',true),true);eq(#Mock.writes,0)
    eq(number('Sound_MusicVolume'),0)
    eq(A.audio:SetEnabled('music',false),true);local n=#Mock.writes
    eq(A.audio:SetEnabled('music',false),true);eq(#Mock.writes,n)
    eq(A.audio:SetEnabled('music',true),true);n=#Mock.writes
    eq(A.audio:SetEnabled('music',true),true);eq(#Mock.writes,n)
end)
test('every write position rolls back across solo activation, all-on, group mute and group volume',function()
    local cases={
        {setup=function() Mock.cvars.Sound_EnableAllSound='0';Mock.cvars.Sound_MasterVolume='0';Mock.cvars.Sound_EnableMusic='0';Mock.cvars.Sound_MusicVolume='0' end,run=function() return A.audio:SetEnabled('music',true) end},
        {setup=function() Mock.cvars.Sound_EnableAllSound='0';for _,k in ipairs({'SFX','Ambience','Dialog'}) do Mock.cvars['Sound_Enable'..k]='0';Mock.cvars['Sound_'..k..'Volume']='0' end end,run=function() return A.audio:SetEnabled('sfx',true) end},
        {setup=function() Mock.cvars.Sound_EnableAllSound='0';Mock.cvars.Sound_MasterVolume='0';for _,k in ipairs({'SFX','Ambience','Dialog','Music'}) do Mock.cvars['Sound_Enable'..k]='0';Mock.cvars['Sound_'..k..'Volume']='0' end end,run=function() return A.audio:SetEnabled('master',true) end},
        {setup=function() end,run=function() return A.audio:SetEnabled('sfx',false) end},
        {setup=function() end,run=function() return A.audio:SetVolume('sfx',35) end},
    }
    for _,case in ipairs(cases) do
        reset();case.setup();A.UI:Refresh();eq(case.run(),true);local writes=Mock.writeAttempts
        for fail=1,writes do
            reset();case.setup();A.UI:Refresh();local before=copy(Mock.cvars)
            Mock.rejectAt=fail;local ok,err=case.run();Mock.rejectAt=nil
            eq(ok,false);eq(err,'WRITE_ERROR');same(before)
            for _,id in ipairs({'master','sfx','music'}) do display(id,A.audio:Get(id).audible) end
        end
    end
end)
test('synchronous CVar callbacks cannot expose intermediate button states or corrupt volume history',function()
    Mock.cvars.Sound_EnableAllSound='0';Mock.cvars.Sound_MusicVolume='0';A.UI:Refresh()
    Mock.afterWrite=function()
        for _,id in ipairs({'master','sfx','music'}) do eq(A.UI.rows[id].toggle.text.textValue,A.L.OFF) end
        eq(A.db.lastVolumes.music,.25)
    end
    eq(A.audio:SetEnabled('music',true),true);Mock.afterWrite=nil;display('music',true);display('sfx',false)
end)
test('failed rollback reports the actual settings instead of claiming a successful activation',function()
    Mock.cvars.Sound_EnableAllSound='0';A.UI:Refresh()
    Mock.rejectAt=2;Mock.rejectValues={Sound_EnableSFX=1}
    local ok,err=A.audio:SetEnabled('music',true)
    Mock.rejectAt=nil;Mock.rejectValues=nil
    eq(ok,false);eq(err,'AUDIO_RESTORE_ERROR');eq(number('Sound_EnableSFX'),0);eq(number('Sound_EnableAmbience'),1)
    display('master',false);display('music',false);display('sfx',false)
end)
test('missing required APIs fail before writing while unsupported optional members are skipped',function()
    Mock.cvars.Sound_MasterVolume=nil;A.UI:Refresh();eq(A.audio:SetEnabled('music',true),false);eq(#Mock.writes,0)
    eq(A.UI.rows.music.toggle.text.textValue,'--')
    reset();Mock.cvars.Sound_EnableAllSound='0'
    Mock.cvars.Sound_EnableAmbience=nil;Mock.cvars.Sound_AmbienceVolume=nil
    Mock.cvars.Sound_EnableDialog=nil;Mock.cvars.Sound_DialogVolume=nil
    eq(A.audio:SetEnabled('music',true),true);eq(number('Sound_EnableSFX'),0)
end)
A.audio=original.audio;A.audio.history=original.history;A.db.lastVolumes=original.history
Mock.cvars=original.cvars;Mock.writes=original.writes;Mock.rejectAt=nil;Mock.rejectValues=nil;Mock.afterWrite=nil
A.UI:Refresh()
return passed
