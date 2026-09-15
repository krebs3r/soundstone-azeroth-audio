local _, A = ...
local P={};A.Placement=P

local function tick(checkpoint) if checkpoint then checkpoint() end end
-- Lua 5.1 cannot yield from table.sort's C callback. Merge in small Lua steps
-- when running in the placement coroutine, including large overlapping sets.
local function sortIntervals(items,checkpoint)
    if not checkpoint then table.sort(items,function(a,b) return a[1]<b[1] end);return items end
    local n,span=#items,1
    local work={}
    while span<n do
        for first=1,n,span*2 do
            local mid,last=math.min(first+span-1,n),math.min(first+span*2-1,n)
            local left,right=first,mid+1
            for target=first,last do
                if left<=mid and (right>last or items[left][1]<=items[right][1]) then
                    work[target]=items[left];left=left+1
                else work[target]=items[right];right=right+1 end
                checkpoint()
            end
        end
        items,work=work,items;span=span*2
    end
    return items
end

-- Coordinates use UIParent units, with y denoting the top of the moving frame.
-- Search obstacle edges and merge blocked vertical intervals at each x. This
-- finds the closest free top-left without sampling every pixel or moving other UI.
function P.Find(x,y,w,h,sw,sh,obstacles,gap,checkpoint)
    if w>sw or h>sh then return nil end
    gap=gap or 2
    local clampedX,clampedY=math.max(0,math.min(sw-w,x)),math.max(h,math.min(sh,y))
    local free=true
    for _,r in ipairs(obstacles) do
        tick(checkpoint)
        if clampedX<r.right+gap and clampedX+w>r.left-gap and clampedY>r.bottom-gap and clampedY-h<r.top+gap then
            free=false;break
        end
    end
    if free then return clampedX,clampedY end
    local xs={clampedX,0,sw-w}
    for _,r in ipairs(obstacles) do
        tick(checkpoint)
        xs[#xs+1]=r.left-w-gap;xs[#xs+1]=r.right+gap
    end
    local bestX,bestY,bestDistance
    local seen={}
    for _,cx in ipairs(xs) do
        tick(checkpoint)
        if cx>=0 and cx<=sw-w and not seen[cx] and (not bestDistance or (cx-x)^2<=bestDistance) then
        seen[cx]=true
        local intervals={}
        for _,r in ipairs(obstacles) do
            tick(checkpoint)
            if cx<r.right+gap and cx+w>r.left-gap then
                intervals[#intervals+1]={r.bottom-gap,r.top+h+gap}
            end
        end
        intervals=sortIntervals(intervals,checkpoint)
        local function consider(low,high)
            if low>high then return end
            local cy=math.max(low,math.min(high,y))
            local distance=(cx-x)^2+(cy-y)^2
            if not bestDistance or distance<bestDistance then bestX,bestY,bestDistance=cx,cy,distance end
        end
        local low=h
        for _,interval in ipairs(intervals) do
            tick(checkpoint)
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
local function inspect(frame,root,screenWidth,screenHeight,known)
    if frame==UIParent or frame==WorldFrame or frame==GameTooltip then return end
    if frame.IsForbidden and public(frame:IsForbidden())~=false then return end
    if not public(frame:IsVisible()) then return end
    if not known then
        local mouse=frame.IsMouseEnabled and public(frame:IsMouseEnabled())
        local movable=frame.IsMovable and public(frame:IsMovable())
        if not mouse and not movable and frame~=Minimap then return end
    end
    local ancestor=frame
    for i=1,100 do
        if ancestor==root then return end
        ancestor=public(ancestor:GetParent());if not ancestor then break end
        if i==100 then return end
    end
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
-- Reserve the visible bar containers even when they do not receive mouse input.
-- Modern action buttons can be inaccessible while their layout container is
-- readable. Never read protected button state or change another addon's frames.
local bars={'MainActionBar','MainMenuBar','MultiBarBottomLeft','MultiBarBottomRight',
    'MultiBarLeft','MultiBarRight','MultiBar5','MultiBar6','MultiBar7','PetActionBar',
    'PetActionBarFrame','StanceBar','StanceBarFrame','PossessActionBar','PossessBarFrame',
    'OverrideActionBar','ExtraActionBarFrame'}
local function children(frame,root)
    if frame==root or frame==GameTooltip then return end
    if frame.IsForbidden and public(frame:IsForbidden())~=false then return end
    if not public(frame:IsVisible()) then return end
    return {frame:GetChildren()}
end
function P.Collect(root,checkpoint,stats)
    local results,seen={},{}
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    stats=stats or {};stats.scanned=0;stats.known=0;stats.obstacles=0
    local covered={}
    for _,name in ipairs(bars) do
        local known=_G[name]
        if known then
            local readable,rect=pcall(inspect,known,root,sw,sh,true)
            if readable and rect then
                results[#results+1]=rect;covered[#covered+1]=rect;seen[known]=true
                stats.known=stats.known+1
            end
        end
        tick(checkpoint)
    end
    -- Walk visible UI trees, pruning hidden/own/reserved subtrees. A global
    -- EnumerateFrames walk also visits every inactive pooled frame in the client.
    local stack={UIParent}
    if WorldFrame then stack[#stack+1]=WorldFrame end
    local visited={}
    while #stack>0 do
        local frame=stack[#stack];stack[#stack]=nil
        if not visited[frame] then
            visited[frame]=true
            stats.scanned=stats.scanned+1
            if not seen[frame] then
                local readable,rect=pcall(inspect,frame,root,sw,sh)
                if readable and rect then
                    local contained=false
                    for _,bar in ipairs(covered) do
                        if rect.left>=bar.left and rect.right<=bar.right and rect.bottom>=bar.bottom and rect.top<=bar.top then
                            contained=true;break
                        end
                    end
                    if not contained then results[#results+1]=rect end
                end
                local ok,list=pcall(children,frame,root)
                if not ok and frame==UIParent then return nil end
                if ok and list then
                    for _,child in ipairs(list) do
                        child=public(child)
                        if child then stack[#stack+1]=child end
                        tick(checkpoint)
                    end
                end
            end
        end
        tick(checkpoint)
    end
    stats.obstacles=#results
    return results
end

-- Each resume has both a work limit and a soft 2 ms budget. The game can draw
-- between resumes. Profiling never resets the shared debug timer.
function P.Start(root,x,y,w,h,sw,sh)
    local job={stats={steps=0,maxSliceMs=0}}
    local began=A.Compat.Now()
    local operations,started
    local function checkpoint()
        operations=operations+1
        local elapsed=debugprofilestop and debugprofilestop()-started or 0
        if operations>=200 or elapsed>=2 then coroutine.yield() end
    end
    job.thread=coroutine.create(function()
        local obstacles=P.Collect(root,checkpoint,job.stats)
        if not obstacles then return nil,nil,'unavailable' end
        local px,py=P.Find(x,y,w,h,sw,sh,obstacles,3,checkpoint)
        return px,py,px and 'placed' or 'no-space'
    end)
    function job:Step()
        if A.Compat.Now()-began>2 then self.stats.status='unavailable';return true,nil,nil,'unavailable' end
        operations=0;started=debugprofilestop and debugprofilestop() or 0
        self.stats.steps=self.stats.steps+1
        local ok,px,py,status=coroutine.resume(self.thread)
        if debugprofilestop then self.stats.maxSliceMs=math.max(self.stats.maxSliceMs,debugprofilestop()-started) end
        if not ok then self.stats.status='unavailable';return true,nil,nil,'unavailable' end
        if coroutine.status(self.thread)=='dead' then self.stats.status=status;return true,px,py,status end
        return false
    end
    return job
end
