local A=Soundstone
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function test(name,fn) fn();count=count+1;print('PASS '..name) end

if not AddonCompartmentFrame then
    test('clients without an Addons menu keep only the minimap button',function()
        eq(A.UI.compartment,nil);eq(#Mock.compartment,0);eq(A.UI.minimap:IsShown(),A.db.showMinimap)
    end)
    return count
end

test('Addons menu entry is registered once with logo and tooltip',function()
    eq(A.UI.compartment,true);eq(#Mock.compartment,1)
    local info=Mock.compartment[1]
    eq(info.text,'Soundstone');eq(info.icon,'Interface\\AddOns\\Soundstone\\Media\\Logo.tga')
    eq(info.notCheckable,true);eq(info.registerForAnyClick,true)
    info.funcOnEnter(A.UI.bar);eq(Mock.tooltip.shown,true);eq(Mock.tooltip.owner,A.UI.bar);eq(Mock.tooltip.line,A.L.COMPARTMENT_HELP)
    info.funcOnLeave(A.UI.bar);eq(Mock.tooltip.shown,false)
    info.funcOnEnter(nil);eq(Mock.tooltip.owner,AddonCompartmentFrame);info.funcOnLeave()
end)

test('Addons menu left-click changes view and right-click shows/hides',function()
    local info=Mock.compartment[1]
    for _,input in ipairs({{buttonName='LeftButton'},'LeftButton'}) do
        A:SetView('compact');info.func(A.UI.bar,input);eq(A.db.viewMode,'expanded');A:SetView('compact')
    end
    info.func(A.UI.bar,{buttonName='RightButton'});eq(A.db.showBar,false);eq(A.UI.root:IsShown(),false)
    assert(Mock.messages[#Mock.messages]:find(A.L.HIDDEN_COMPARTMENT,1,true))
    info.func(A.UI.bar,{buttonName='LeftButton'});eq(A.db.showBar,true);eq(A.db.viewMode,'compact')
    info.func('Soundstone','RightButton');eq(A.db.showBar,false);info.func('Soundstone','RightButton');eq(A.db.showBar,true)
end)

test('minimap button stays available as an option next to the Addons menu',function()
    local shown=A.db.showMinimap
    A:Command('minimap');eq(A.UI.minimap:IsShown(),not shown);A:Command('minimap');eq(A.UI.minimap:IsShown(),shown)
end)
return count
