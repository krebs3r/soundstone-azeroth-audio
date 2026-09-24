local A=Soundstone
local d=A.UI.outputDropdown
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b,tolerance) assert(math.abs(a-b)<(tolerance or .00001),tostring(a)..' !~= '..tostring(b)) end
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local function open()
    A.UI:CloseMenus();A:SetView('expanded');A.UI:ToggleMenu();Mock.clickDropdown(d);eq(d:IsOpen(),true)
end
local function rows() return Mock.dropdownRows(d) end
local function selected(row) return d.native and row.selected or (not d.native and row.check:IsShown()) end

test('native and fallback dropdowns use the intended field and attached list',function()
    Mock.devices={'System Default','Speakers','Headset'};Mock.cvars.Sound_OutputDriverIndex='0'
    A:SetScale(1);A:ResetPositions();open()
    eq(d.field.template,d.native and 'WowStyle1DropdownTemplate' or 'UIDropDownMenuTemplate')
    eq(d.field:GetWidth(),256);eq(d.field:GetHeight(),24);eq(d.list:GetWidth(),256)
    eq(d.list:GetHeight(),d.native and 83 or 76);eq(A.UI.deviceMenu,nil)
    near(d.list:GetLeft(),d.field:GetLeft(),A.Compat.Pixel(1,d.field)+.001)
    near(d.list:GetTop(),d.field:GetTop()-26,A.Compat.Pixel(1,d.field)+.001)
    eq(#rows(),d.native and 3 or 6)
    for i=1,3 do eq(rows()[i]:GetHeight(),20);eq(selected(rows()[i]),i==1) end
    if d.native then eq(d.field.description.scrollExtent,120);eq(A.UI.escape:IsShown(),false)
    else eq(d.list.backdrop.edgeFile,'Interface\\Tooltips\\UI-Tooltip-Border');eq(A.UI.escape:IsShown(),true) end
end)

test('menu labels use a shared font object across opening, selection and regeneration',function()
    local font=d.field.Text.fontObject
    eq(font.kind,'Font');eq(font.fontSize,10)
    for pass=1,3 do
        if not d:IsOpen() then Mock.clickDropdown(d) end
        for i=1,3 do
            local label=d.native and rows()[i].fontString or rows()[i].text
            eq(label.fontObject,font);eq(label.fontSize,10)
            eq(label.justifyV,'MIDDLE');eq(label.wordWrap,false);eq(label.maxLines,1)
        end
        rows()[2]:Fire('OnClick');eq(d:IsOpen(),false)
        Mock.clickDropdown(d);A.events:Fire('OnEvent','SOUND_DEVICE_UPDATE')
    end
    Mock.cvars.Sound_OutputDriverIndex='0';A.UI:RefreshDevices()
end)

test('field toggling and outside clicks close only the attached list',function()
    Mock.clickDropdown(d);eq(d:IsOpen(),false);eq(A.UI.menu:IsShown(),true)
    Mock.clickDropdown(d);Mock.outsideClick(rows()[1]);eq(d:IsOpen(),true)
    Mock.outsideClick(d.clickTarget);eq(d:IsOpen(),true)
    A.UI.scaleSlider:SetValue(125)
    Mock.outsideClick(A.UI.resetPosition);eq(d:IsOpen(),false)
    eq(A.UI.menu:IsShown(),true);eq(A.UI.pendingScale,125);eq(A.db.uiScale,1)
    Mock.clickDropdown(d);Mock.outsideClick(UIParent);eq(d:IsOpen(),false)
    if not d.native then
        local foci=GetMouseFoci;GetMouseFoci=nil
        Mock.clickDropdown(d);Mock.outsideClick(rows()[2]);eq(d:IsOpen(),true)
        Mock.outsideClick(UIParent);eq(d:IsOpen(),false);GetMouseFoci=foci
    end
end)

test('Escape consumes exactly one layer and cancels size only when options close',function()
    open();A.UI.scaleSlider:SetValue(150)
    Mock.pressEscape();eq(d:IsOpen(),false);eq(A.UI.menu:IsShown(),true);eq(A.UI.pendingScale,150)
    Mock.pressEscape();eq(A.UI.menu:IsShown(),false);eq(A.db.viewMode,'expanded');eq(A.UI.pendingScale,nil)
    Mock.pressEscape();eq(A.db.viewMode,'compact');eq(A.db.uiScale,1)
end)

test('list selection uses readback and one restart, including synchronous CVAR_UPDATE',function()
    open();local before,restarts=#Mock.writes,Mock.restarts
    rows()[3]:Fire('OnClick');eq(d:IsOpen(),false);eq(d.field.Text.textValue,'Headset')
    eq(#Mock.writes,before+1);eq(Mock.restarts,restarts+1);eq(A.UI.menu:IsShown(),true)
    Mock.clickDropdown(d);eq(selected(rows()[3]),true);rows()[3]:Fire('OnClick')
    eq(#Mock.writes,before+1);eq(Mock.restarts,restarts+1)
    Mock.clickDropdown(d);Mock.rejectWrite=true;rows()[2]:Fire('OnClick');Mock.rejectWrite=false
    eq(d:IsOpen(),false);eq(d.field.Text.textValue,'Headset');eq(Mock.restarts,restarts+1)
    Mock.clickDropdown(d);eq(selected(rows()[3]),true);eq(selected(rows()[2]),false)
end)

test('device loss and index reuse during an open list never choose a stale row',function()
    local before,restarts=#Mock.writes,Mock.restarts
    local stale=rows()[2]
    Mock.devices={'System Default','Replacement','Headset'}
    stale:Fire('OnClick');eq(d:IsOpen(),false);eq(#Mock.writes,before);eq(Mock.restarts,restarts)
    eq(d.field.Text.textValue,'Headset')
    Mock.clickDropdown(d);eq(rows()[2].item.name,'Replacement')
    Mock.devices={'System Default'};A.events:Fire('OnEvent','SOUND_DEVICE_UPDATE')
    eq(d:IsOpen(),true);eq(d.state.selected,nil);eq(selected(rows()[1]),false)
    eq(d.field.Text.textValue,A.L.DEVICE_GONE)
    Mock.devices={};A.events:Fire('OnEvent','SOUND_DEVICE_UPDATE')
    eq(d:IsOpen(),false);eq(d.clickTarget:IsEnabled(),false)
    Mock.devices={'System Default','Speakers','Headset'};Mock.cvars.Sound_OutputDriverIndex='0'
    A.UI:RefreshDevices();eq(d.clickTarget:IsEnabled(),true)
end)

test('open lists refresh external selections and complete names without writes',function()
    local long='USB Audio – '..string.rep('Long output device name ',8)
    Mock.devices={'System Default',long,'Headset'};open()
    local before=#Mock.writes
    Mock.cvars.Sound_OutputDriverIndex='1';A.events:Fire('OnEvent','CVAR_UPDATE','Sound_OutputDriverIndex')
    eq(d:IsOpen(),true);eq(d.field.Text.textValue,long);eq(selected(rows()[2]),true)
    local label=d.native and rows()[2].fontString or rows()[2].text
    eq(label.wordWrap,false);eq(label.justifyV,'MIDDLE');assert(label:GetWidth()<236)
    rows()[2]:Fire('OnEnter');eq(Mock.tooltip.text,long)
    Mock.clickDropdown(d);d.clickTarget:Fire('OnEnter');eq(Mock.tooltip.line,long)
    eq(#Mock.writes,before)
end)

test('scrolling exposes only six rows and never rotates the selected device',function()
    Mock.devices={'System Default','Speakers','Headset','USB 1','USB 2','USB 3','USB 4','USB 5','USB 6'}
    open();local before=#Mock.writes
    eq(d.list:GetHeight(),d.native and 143 or 136)
    d.list:Fire('OnMouseWheel',-100);eq(rows()[6].item.name,'USB 6')
    d.list:Fire('OnMouseWheel',100);eq(rows()[1].item.name,'System Default')
    eq(#Mock.writes,before);eq(d.state.current,1)
    if d.native then eq(d.field.wheel,false);eq(d.list.scrollable,true)
    else eq(d.scrollbar:IsShown(),true);d.scrollbar:SetValue(2);eq(rows()[1].item.name,'Headset') end
    d:Close();eq(d.clickTarget.wheel==true,false);eq(#Mock.writes,before)
end)

test('attached lists flip upwards at bottom edges throughout the scale matrix',function()
    for _,resolution in ipairs({{1920,1080},{2560,1440}}) do
        Mock.physicalWidth,Mock.physicalHeight=resolution[1],resolution[2]
        local factor=768/resolution[2]
        for _,ws in ipairs({.65,.85,1}) do for _,s in ipairs({.75,1,1.5}) do
            UIParent:SetScale(ws);UIParent:SetSize(resolution[1]*factor/ws,768/ws)
            A:SetScale(s);open()
            -- Exercise a field close to the lower screen edge, independent of the options clamp.
            d.field:ClearAllPoints();d.field:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',10,45)
            d:Position();eq(d.opensUp,true);near(d.list:GetEffectiveScale(),ws*s)
            near(d.list:GetTop()-d.list:GetHeight(),d.field:GetTop()+2,A.Compat.Pixel(1,d.field)+.001)
            near(d.list:GetLeft(),d.field:GetLeft(),A.Compat.Pixel(1,d.field)+.001)
            d:Close();d.field:ClearAllPoints();d.field:SetPoint('TOPLEFT',10,-44)
        end end
    end
    UIParent:SetScale(1);UIParent:SetSize(1920,1080);Mock.physicalWidth,Mock.physicalHeight=1920,1080
    A:SetScale(1);A:ResetPositions()
end)

test('view changes, options closure and hiding close dropdowns in both backends',function()
    for _,close in ipairs({function() A.UI.panelMode:Fire('OnClick') end,function() A.UI:CloseMenus() end,function() A:Command('hide') end}) do
        open();A.UI.scaleSlider:SetValue(150);close()
        eq(d:IsOpen(),false);eq(A.UI.pendingScale,nil);eq(A.db.uiScale,1)
    end
    A:Command('show');A:SetView('compact')
    Mock.devices={'System Default','Speakers','Headset'};Mock.cvars.Sound_OutputDriverIndex='1';A.UI:RefreshDevices()
end)
test('Windows-1252 device names are shown as UTF-8 and stay selectable',function()
    local C=A.Compat
    eq(C.Utf8('Kopfh\195\182rer'),'Kopfh\195\182rer');eq(C.Utf8('Speakers'),'Speakers')
    eq(C.Utf8('Kopfh\246rer'),'Kopfh\195\182rer');eq(C.Utf8('\128 \150 \255'),'\226\130\172 \226\128\147 \195\191')
    eq(C.Utf8('\195'),'\195\131');eq(C.Utf8('\129'),'\239\191\189')
    Mock.devices={'System Default','Kopfh\246rer (DAC)'};Mock.cvars.Sound_OutputDriverIndex='0';A.UI:RefreshDevices()
    local items=A.devices:Get().items;eq(items[2].name,'Kopfh\195\182rer (DAC)')
    eq(A.devices:Select(1,items[2].name),true);eq(Mock.cvars.Sound_OutputDriverIndex,'1')
    Mock.devices={'System Default','Speakers','Headset'};Mock.cvars.Sound_OutputDriverIndex='1';A.UI:RefreshDevices()
end)
return count
