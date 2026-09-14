local _, A = ...
local Layout = {width=300, compactHeight=45, expandedHeight=160, minScale=.75, maxScale=1.5}
A.Layout = Layout
function Layout.Number(value, fallback)
    local n=tonumber(value)
    if not n or n~=n or n==math.huge or n==-math.huge then return fallback end
    return n
end
function Layout.Scale(value)
    return math.max(Layout.minScale,math.min(Layout.maxScale,Layout.Number(value,1)))
end
function Layout.Clamp(x,y,width,height,screenWidth,screenHeight)
    local left,right=-screenWidth/2,screenWidth/2-width
    local bottom,top=-screenHeight/2+height,screenHeight/2
    return math.max(left,math.min(math.max(left,right),x)),math.min(top,math.max(math.min(bottom,top),y))
end
function Layout.LegacyPosition(pos, width, height)
    pos=type(pos)=='table' and pos or {point='CENTER',x=0,y=-180}
    local point=type(pos.point)=='string' and pos.point or 'CENTER'
    local x,y=Layout.Number(pos.x,0),Layout.Number(pos.y,-180)
    if point:find('LEFT') then x=x-width/2 elseif point:find('RIGHT') then x=x+width/2 end
    if point:find('TOP') then y=y+height/2 elseif point:find('BOTTOM') then y=y-height/2 end
    if not point:find('LEFT') then x=x-(point:find('RIGHT') and 336 or 168) end
    if not point:find('TOP') then y=y+(point:find('BOTTOM') and 46 or 23) end
    return {x=x,y=y}
end
