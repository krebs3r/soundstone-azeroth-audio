local _, A = ...
local C=A.Compat
local T={};A.Theme=T

-- Two looks for Soundstone's own surfaces, chosen by the client, not by the player. 'soundstone' is the
-- sprite skin every release has worn (Retail art on Retail, Classic art elsewhere) and paints exactly the
-- colors 0.3.8 used. 'forever' is WoW: Forever's own look, on the Forever client only: the windows wear
-- the client's bronze window frame, as Forever's own windows do, and the bar the same frame without its
-- title strip; where a piece of that art is missing, a flat near-black plate with a one-pixel bronze line
-- stands in. A look changes the surface, never the information: the volume fill, the values, the mute
-- state of an icon and every Blizzard control keep their look. The values and their origins are in
-- docs/FOREVER-THEME-PLAN.md.
local function rgb(r,g,b,a) return {r/255,g/255,b/255,a} end
local MUTED=rgb(166,160,148)
T.palettes={
    soundstone={
        text={.96,.94,.87},title={1,.81,.26},footer={.96,.94,.87},footerAlpha=.55,
        gear={.9,.8,.57},gearHover={1,1,1},gearPressed={.6,.55,.4},
        divider={.58,.43,.19,.65},headerRule={.67,.64,.56,.55},rowRule={.55,.52,.45,.3},
    },
    forever={
        text=rgb(240,233,218),title={1,210/255,0},footer=MUTED,footerAlpha=.85,
        -- The gear texture is gray; pressed keeps 0.3.8's pressed/normal ratio of about 0.67.
        gear=MUTED,gearHover=rgb(240,204,140),gearPressed=rgb(111,107,99),
        divider=rgb(104,80,52),headerRule=rgb(166,160,148,.35),rowRule=rgb(166,160,148,.18),
        plate=rgb(21,18,15,.96),band=rgb(10,8,6),muted=MUTED,
        -- Lit from the top and darker toward the bottom, as Forever's own device list; Umbra's values.
        lineTop=rgb(154,128,92),lineSide=rgb(128,104,72),lineBottom=rgb(104,80,52),accent=rgb(240,204,140),
        -- Symbols on the red header buttons: gold, as Baganator's on Forever (about 213/159/32).
        buttonIcon=rgb(255,230,128),
    },
}
T.thumbAtlas='Minimal_SliderBar_Button'
-- Forever's own art. Other clients ship different art under some of these names (Mists, the
-- Anniversary realms and Era draw ButtonFrameTemplateNoPortrait with their own border), so it is used
-- on the Forever client only, and the other clients never take the 'forever' look; on Forever, a piece
-- whose art is missing falls back to the flat look.
T.window={layout='ButtonFrameTemplateNoPortrait',background='Interface\\FrameGeneral\\UI-Background-Rock',
    streaks='_UI-Frame-TopTileStreaks',close={normal='RedButton-Exit',pushed='RedButton-exit-pressed',highlight='RedButton-Highlight'}}
T.track={left='Minimal_SliderBar_Left',middle='_Minimal_SliderBar_Middle',right='Minimal_SliderBar_Right'}
T.slot={normal='UI-HUD-ActionBar-IconFrame',pushed='UI-HUD-ActionBar-IconFrame-Down',highlight='UI-HUD-ActionBar-IconFrame-Mouseover'}

function T.Resolve()
    return C.IsForever() and 'forever' or 'soundstone'
end

-- Window titles take the client's own gold. Its value comes from client data (C_UIColor), not from
-- the UI source; the fallback is Blizzard's |cffffd200.
local function clientGold()
    local color=NORMAL_FONT_COLOR
    if type(color)=='table' and type(color.GetRGB)=='function' then
        local ok,r,g,b=pcall(color.GetRGB,color)
        if ok and type(r)=='number' and type(g)=='number' and type(b)=='number' then return {r,g,b} end
    end
    return {1,210/255,0}
end

T.name='soundstone';T.colors=T.palettes.soundstone
function T.Use(name)
    T.name=name;T.colors=T.palettes[name] or T.palettes.soundstone
    if name=='forever' then T.palettes.forever.title=clientGold() end
end
function T.Color(key) return T.colors[key] end

-- Regions remember the palette key they are painted from, so applying a look paints them again.
-- Weak keys: a region that is gone is forgotten.
local painted=setmetatable({},{__mode='k'})
local function apply(region,entry)
    local c=T.colors[entry.key]
    if not c then return end
    local set=entry.method=='text' and region.SetTextColor or region.SetVertexColor
    if c[4] then set(region,c[1],c[2],c[3],c[4]) else set(region,c[1],c[2],c[3]) end
end
-- method is 'text' for a FontString and 'vertex' for a texture.
function T.Paint(region,key,method)
    local entry={key=key,method=method}
    painted[region]=entry;apply(region,entry)
    return region
end
-- Each region inside pcall, as in Umbra: a region can refuse a recolor; the rest carry on.
function T.Repaint()
    for region,entry in pairs(painted) do pcall(apply,region,entry) end
end

-- One physical pixel in a region's units, from PixelUtil's factor (768 / physical height) and the
-- effective scale. Without PixelUtil the physical height is read directly, as C.Pixel does.
function T.Pixel(region)
    local factor
    if type(PixelUtil)=='table' and type(PixelUtil.GetPixelToUIUnitFactor)=='function' then
        factor=PixelUtil.GetPixelToUIUnitFactor()
    elseif type(GetPhysicalScreenSize)=='function' then
        local _,height=GetPhysicalScreenSize()
        if type(height)=='number' and height>0 then factor=768/height end
    end
    local scale=region:GetEffectiveScale()
    if issecretvalue and (issecretvalue(scale) or issecretvalue(factor)) then return 1 end
    if type(factor)~='number' or type(scale)~='number' or scale<=0 then return 1 end
    return factor/scale
end

-- The client's own settings-slider thumb; on Forever a copper diamond. Unknown atlases keep the sprite.
function T.HasAtlas(name)
    if not (C_Texture and type(C_Texture.GetAtlasInfo)=='function') then return false end
    local ok,info=pcall(C_Texture.GetAtlasInfo,name)
    return ok and info~=nil
end
function T.AtlasInfo(name)
    if not (C_Texture and type(C_Texture.GetAtlasInfo)=='function') then return nil end
    local ok,info=pcall(C_Texture.GetAtlasInfo,name)
    return ok and type(info)=='table' and info or nil
end
local function hasAll(list)
    for _,name in pairs(list) do if not T.HasAtlas(name) then return false end end
    return true
end
-- Which of Forever's own pieces the client can draw: the window frame (on the windows and, cut to its
-- band, on the bar), the slider track and the icon slots. Each falls back to the flat look on its own.
function T.Art()
    local art={}
    if not C.IsForever() then return art end
    local util,layouts=NineSliceUtil,NineSliceLayouts
    local layout=type(layouts)=='table' and layouts[T.window.layout]
    if type(util)=='table' and type(util.ApplyLayoutByName)=='function' and type(layout)=='table' and hasAll(T.window.close) then
        art.window=true
        for _,piece in pairs(layout) do
            if type(piece)=='table' and piece.atlas and not T.HasAtlas(piece.atlas) then art.window=false end
        end
        -- The bar keeps the top pieces' band (to 3 units below the frame's top) and the bottom corners'
        -- lowest 8 units above the frame's bottom: the pieces must reach that far.
        local function reaches(key,need)
            local piece=layout[key];local info=type(piece)=='table' and piece.atlas and T.AtlasInfo(piece.atlas)
            return info and type(info.height)=='number' and type(info.width)=='number' and info.height>=need or false
        end
        if art.window then
            local top=type(layout.TopLeftCorner)=='table' and (layout.TopLeftCorner.y or 0) or 0
            local bottom=type(layout.BottomLeftCorner)=='table' and (layout.BottomLeftCorner.y or 0) or 0
            art.window=reaches('TopLeftCorner',top+3) and reaches('TopRightCorner',top+3) and reaches('TopEdge',top+3)
                and reaches('BottomLeftCorner',8-bottom) and reaches('BottomRightCorner',8-bottom) and reaches('BottomEdge',1)
                and reaches('LeftEdge',1) and reaches('RightEdge',1)
        end
    end
    art.track=hasAll(T.track)
    art.slot=hasAll(T.slot)
    return art
end
