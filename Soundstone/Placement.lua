local _, A = ...
local P={};A.Placement=P

-- Coordinates use UIParent units, with y denoting the top of the moving frame.
-- Search obstacle edges and merge blocked vertical intervals at each x. This
-- finds the closest free top-left without sampling every pixel or moving other UI.
function P.Find(x,y,w,h,sw,sh,obstacles,gap)
    if w>sw or h>sh then return nil end
    gap=gap or 2
    local xs={math.max(0,math.min(sw-w,x)),0,sw-w}
    for _,r in ipairs(obstacles) do
        xs[#xs+1]=r.left-w-gap;xs[#xs+1]=r.right+gap
    end
    local bestX,bestY,bestDistance
    local seen={}
    for _,cx in ipairs(xs) do if cx>=0 and cx<=sw-w and not seen[cx] then
        seen[cx]=true
        local intervals={}
        for _,r in ipairs(obstacles) do
            if cx<r.right+gap and cx+w>r.left-gap then
                intervals[#intervals+1]={r.bottom-gap,r.top+h+gap}
            end
        end
        table.sort(intervals,function(a,b) return a[1]<b[1] end)
        local function consider(low,high)
            if low>high then return end
            local cy=math.max(low,math.min(high,y))
            local distance=(cx-x)^2+(cy-y)^2
            if not bestDistance or distance<bestDistance then bestX,bestY,bestDistance=cx,cy,distance end
        end
        local low=h
        for _,interval in ipairs(intervals) do
            if interval[2]>low and interval[1]<sh then
                if interval[1]>=low then consider(low,math.min(sh,interval[1])) end
                low=math.max(low,interval[2])
                if low>sh then break end
            end
        end
        consider(low,sh)
    end end
    return bestX,bestY
end

local function public(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
local function number(value)
    value=public(value)
    if type(value)=='number' and value==value and math.abs(value)<math.huge then return value end
end
local function inspect(frame,root,screenWidth,screenHeight)
    if frame==UIParent or frame==WorldFrame or frame==GameTooltip then return end
    if frame.IsForbidden and public(frame:IsForbidden())~=false then return end
    if not public(frame:IsVisible()) then return end
    local ancestor=frame
    for i=1,100 do
        if ancestor==root then return end
        ancestor=public(ancestor:GetParent());if not ancestor then break end
        if i==100 then return end
    end
    local mouse=frame.IsMouseEnabled and public(frame:IsMouseEnabled())
    local movable=frame.IsMovable and public(frame:IsMovable())
    if not mouse and not movable and frame~=Minimap then return end
    if frame.GetEffectiveAlpha then
        local alpha=number(frame:GetEffectiveAlpha());if not alpha or alpha<=0 then return end
    end
    local scale=number(frame:GetEffectiveScale())
    local left,top=number(frame:GetLeft()),number(frame:GetTop())
    local width,height=number(frame:GetWidth()),number(frame:GetHeight())
    if not scale or scale<=0 or not left or not top or not width or not height then return end
    scale=scale/UIParent:GetEffectiveScale()
    left,top,width,height=left*scale,top*scale,width*scale,height*scale
    -- Ignore game-sized input containers; their individual controls still count.
    if width<1 or height<1 or width*height>screenWidth*screenHeight*.85 then return end
    if left>=screenWidth or left+width<=0 or top<=0 or top-height>=screenHeight then return end
    return {left=left,right=left+width,top=top,bottom=top-height}
end
function P.Collect(root)
    if type(EnumerateFrames)~='function' then return nil end
    local results,frame,seen={},nil,{}
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    while true do
        local ok,nextFrame=pcall(EnumerateFrames,frame)
        if not ok then return nil end
        frame=public(nextFrame);if not frame then break end
        if seen[frame] then return nil end;seen[frame]=true
        local readable,rect=pcall(inspect,frame,root,sw,sh)
        if readable and rect then results[#results+1]=rect end
    end
    return results
end
