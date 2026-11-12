-- AutoMacros: The action bars: popout direction, finding action buttons, the empty
-- highlight on them, the empty-button tooltip.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---- popout direction ----
-- Which way a button's popout opens: up, down, left or right. Chosen per
-- button in the settings (db.popDir[key]), or on Automatic worked out from
-- where the button is on screen.
POPOUT = {
    DIRS = { { key = "auto", label = "Automatic" }, { key = "up", label = "Up" },
        { key = "down", label = "Down" }, { key = "left", label = "Left" }, { key = "right", label = "Right" } },
    AWAY = { left = "right", right = "left", bottom = "up", top = "down" },   -- from the nearest edge
}

-- a button's centre and size in screen pixels (nil when it is not laid out)
function POPOUT.Rect(b)
    local l, bottom, w, h = b:GetRect()
    if not l then return nil end
    local s = b:GetEffectiveScale()
    return (l + w / 2) * s, (bottom + h / 2) * s, w * s, h * s
end

-- How action button b sits: "column" (a vertical bar), "row" (a horizontal
-- bar), or nil (a grid, a lone button, not laid out); and its centre in
-- screen pixels.
function POPOUT.Layout(b)
    local x, y, w, h = POPOUT.Rect(b)
    if not x then return nil end
    local column, row = false, false
    for _, o in ipairs(buttons) do
        -- (visible ones only: 1.2.0 briefly counted a bar's hidden slots too, and
        -- Automatic stopped finding vertical bars on Forever)
        if o ~= b and o:IsVisible() then
            local ox, oy = POPOUT.Rect(o)
            if ox then
                local dx, dy = math.abs(ox - x), math.abs(oy - y)
                if dx < w * 0.5 and dy > h * 0.5 and dy < h * 1.8 then column = true end
                if dy < h * 0.5 and dx > w * 0.5 and dx < w * 1.8 then row = true end
            end
        end
    end
    local layout = (column and not row and "column") or (row and not column and "row") or nil
    return layout, x, y
end

-- Whether a popout of n items opening `dir` from button b would stay clear of
-- every other visible action button and on the screen.
function POPOUT.Clear(b, dir, n)
    local x, y, w, h = POPOUT.Rect(b)
    if not x then return false end
    local s = UIParent:GetEffectiveScale()
    local sw, sh = UIParent:GetWidth() * s, UIParent:GetHeight() * s
    local across = dir == "left" or dir == "right"
    local size = across and w or h
    local reach = n * size + size * 0.5   -- (its items, and the gap to the button)
    local room = ({ left = x - w / 2, right = sw - x - w / 2, down = y - h / 2, up = sh - y - h / 2 })[dir]
    if room < reach then return false end
    for _, o in ipairs(buttons) do
        if o ~= b and o:IsVisible() then
            local ox, oy, ow, oh = POPOUT.Rect(o)
            if ox then
                local along = ({ left = x - ox, right = ox - x, down = y - oy, up = oy - y })[dir]
                local side = across and math.abs(oy - y) or math.abs(ox - x)
                local half = across and (h + oh) / 2 or (w + ow) / 2
                if along > 0 and along < reach + size / 2 and side < half * 0.9 then return false end
            end
        end
    end
    return true
end

-- Automatic for button b with a popout of n items (default 4): the first of
-- these ways it can open clear of other action buttons and on screen (see
-- POPOUT.Clear), else the first of them anyway.
-- In a column (a vertical bar): sideways, toward the middle of the screen
-- first, then the other side, then up or down. In a row (a horizontal bar): up
-- or down, toward the middle first, then sideways. A grid or lone button: away
-- from the nearest screen edge first.
-- (Lewis, 1.2.0: bars not at the screen's edge, popouts should go sideways
-- rather than over another bar's buttons.)
function POPOUT.Auto(b, n)
    local order = POPOUT.Order(b)
    if not order then return "up" end
    n = tonumber(n) or 4
    for _, dir in ipairs(order) do
        local ok, clear = pcall(POPOUT.Clear, b, dir, n)
        if ok and clear then return dir end
    end
    return order[1]
end

-- The ways Automatic tries for button b, best first, by the shape of its bar
-- and where it is on screen (nil when b is not laid out). order[1] alone, with
-- no look at what is in the way, is what POPOUT.CheckLayout compares.
function POPOUT.Order(b)
    local layout, x, y = POPOUT.Layout(b)
    if not x then return nil end
    local s = UIParent:GetEffectiveScale()
    local sw, sh = UIParent:GetWidth() * s, UIParent:GetHeight() * s
    local inX = x < sw / 2 and "right" or "left"   -- toward the middle, sideways
    local inY = y < sh / 2 and "up" or "down"      -- toward the middle, up or down
    local outX = inX == "right" and "left" or "right"
    local outY = inY == "up" and "down" or "up"
    local order
    if layout == "column" then
        order = { inX, outX, inY, outY }
    elseif layout == "row" then
        order = { inY, outY, inX, outX }
    else
        local near, best
        for edge, d in pairs({ left = x, right = sw - x, bottom = y, top = sh - y }) do
            if not best or d < best then near, best = edge, d end
        end
        local away = POPOUT.AWAY[near]
        if away == "left" or away == "right" then order = { away, inY, outY, outX }
        else order = { away, inX, outX, outY } end
    end
    return order
end

-- What right-clicking a button on the Buttons page goes through.
POPOUT.CYCLE = { "auto", "up", "right", "down", "left" }

-- button e's direction as you set it: up / down / left / right, or "auto"
function POPOUT.Chosen(e)
    local set = type(DB().popDir) == "table" and DB().popDir[e.key]
    if set == "up" or set == "down" or set == "left" or set == "right" then return set end
    return "auto"
end

-- the next one after the current (Automatic is not saved)
function POPOUT.Next(e)
    local now, nxt = POPOUT.Chosen(e), "auto"
    for i, d in ipairs(POPOUT.CYCLE) do
        if d == now then nxt = POPOUT.CYCLE[i % #POPOUT.CYCLE + 1] end
    end
    local db = DB()
    if type(db.popDir) ~= "table" then db.popDir = {} end
    db.popDir[e.key] = (nxt ~= "auto") and nxt or nil
    return nxt
end

-- Button m is on action button b (the first of its on your bars): when it has
-- gone from a vertical bar to a horizontal one or back since last time, a
-- direction set by hand (which suited the old bar) goes back to Automatic.
-- The bar's kind is Automatic's first choice there (POPOUT.Order, by shape and
-- place, not by what is in the way): sideways = "column", up / down = "row".
-- (POPOUT.Layout alone has no answer for a bar it can't tell, so a move from
-- such a bar went unnoticed: Lewis's Food button.) db.popLayout[key] = the last one seen.
function POPOUT.CheckLayout(b, m)
    -- (the bar's shape only: something else in the way of the popout is no move)
    local ok, order = pcall(POPOUT.Order, b)
    local pref = ok and order and order[1]
    local layout = pref and ((pref == "left" or pref == "right") and "column" or "row") or nil
    local okA, auto = pcall(POPOUT.Auto, b, POPOUT.Count(m))
    report.barLayout = report.barLayout or {}
    report.barLayout[m.name] = layout and (layout .. ", opens " .. tostring(okA and auto)) or ("? " .. tostring(order))   -- (/amac debug)
    if not layout or not POPOUT.Rect(b) then return end   -- (not laid out: no answer)
    local db = DB()
    if type(db.popLayout) ~= "table" then db.popLayout = {} end
    local was = db.popLayout[m.key]
    db.popLayout[m.key] = layout
    if was and was ~= layout and type(db.popDir) == "table" and db.popDir[m.key] then
        db.popDir[m.key] = nil
        Note(m.title .. ": moved to a " .. (layout == "column" and "vertical" or "horizontal")
            .. " bar, popout direction back to Automatic")
    end
end

-- The direction for our button m's popout on action button b.
function POPOUT.Direction(b, m)
    local set = m and type(DB().popDir) == "table" and DB().popDir[m.key]
    if set == "up" or set == "down" or set == "left" or set == "right" then return set end
    local ok, dir = pcall(POPOUT.Auto, b, POPOUT.Count(m))
    return ok and dir or "up"
end

-- How many items button m's popout shows (at most 10), for POPOUT.Auto
function POPOUT.Count(m)
    local list = m and flyoutItems[m.name]
    return list and math.max(1, math.min(#list, MAX_ENTRIES or 10)) or nil
end

-- The popup items' size in frame f's units: Item size, a percentage like Edit
-- Mode's Icon Size, of a stock action button (Blizzard's template at its own
-- size); with EllesmereUI's look, of your EllesmereUI buttons.
function BLIZZ_ART.ItemSize(f)
    -- 100% = your action bar buttons' size (the one the popout opens from, while
    -- it is worked out: BLIZZ_ART.barFor), with either look: EllesmereUI's 32 px
    -- buttons give 32 px items, not Blizzard's template size
    local base = BLIZZ_ART.BarButtonSize(BLIZZ_ART.barFor) or BLIZZ_ART.native or 36
    -- (BLIZZ_ART.scaleFor: one button's own Item size while its popout is worked out, see PopoutLook)
    return BarUnits(f, base * (tonumber(BLIZZ_ART.scaleFor or Style("itemScale")) or 100) / 100)
end
glows = {}          -- button -> border frame
macroAt = {}        -- macro index -> macro, for every macro we manage
-- (RefreshArrows, MacroOnButton: defined with the flyout, below)
emptyName = {}      -- macro name -> true while its category is empty

-- Which action slot a button shows. Handles Blizzard bars and the common bar
-- addons (Bartender, ElvUI, Dominos), which use LibActionButton.
function ButtonSlot(f)
    local t = f:GetObjectType()
    if t ~= "CheckButton" and t ~= "Button" then return nil end
    if f.GetAction then
        local ok, a, b = pcall(f.GetAction, f)
        if ok then
            if type(a) == "number" then return a end
            if a == "action" and type(b) == "number" then return b end
        end
    end
    if type(f.action) == "number" then return f.action end
    if f.GetAttribute then
        local ok, a = pcall(f.GetAttribute, f, "action")
        if ok and type(a) == "number" and a > 0 then return a end
    end
    return nil
end

-- Buttons are found two ways: by walking every frame, and by the global names
-- the Blizzard bars and common bar addons use, in case the walk is unavailable
-- or incomplete (some simulators).
BUTTON_NAMES = {
    { "ActionButton%d", 12 }, { "MultiBarBottomLeftButton%d", 12 }, { "MultiBarBottomRightButton%d", 12 },
    { "MultiBarRightButton%d", 12 }, { "MultiBarLeftButton%d", 12 },
    { "MultiBar5Button%d", 12 }, { "MultiBar6Button%d", 12 }, { "MultiBar7Button%d", 12 },
    { "BT4Button%d", 180 }, { "DominosActionButton%d", 180 },
}

function CollectButtons()
    local list, seen = {}, {}
    report.enumerated = 0
    local function add(f)
        if type(f) ~= "table" or seen[f] or not f.GetObjectType then return end
        local ok, slot = pcall(ButtonSlot, f)
        if ok and slot then
            seen[f] = true
            list[#list + 1] = f
        end
    end
    if EnumerateFrames then
        local ok, err = pcall(function()
            local f = EnumerateFrames()
            while f do
                report.enumerated = report.enumerated + 1
                local skip = f.IsForbidden and f:IsForbidden()
                if not skip then add(f) end
                f = EnumerateFrames(f)
            end
        end)
        if not ok then Fail("frame walk", err) end
    end
    for _, def in ipairs(BUTTON_NAMES) do
        for i = 1, def[2] do add(_G[def[1]:format(i)]) end
    end
    for bar = 1, 15 do
        for i = 1, 12 do add(_G["ElvUI_Bar" .. bar .. "Button" .. i]) end
    end
    return list
end

function SafeCollect()
    local ok, res = pcall(CollectButtons)
    if ok then buttons = res else Fail("button scan", res) end
end

function GlowFor(button)
    local g = glows[button]
    if g then return g end
    g = CreateFrame("Frame", nil, button)
    g:SetFrameLevel((button:GetFrameLevel() or 1) + 10)
    g.edges = MakeEdges(g, "OVERLAY")
    pcall(function()   -- pulse; if the animation API differs it just stays solid
        local ag = g:CreateAnimationGroup()
        local anim = ag:CreateAnimation("Alpha")
        if anim.SetFromAlpha then
            anim:SetFromAlpha(1)
            anim:SetToAlpha(0.25)
        else
            anim:SetChange(-0.75)
        end
        anim:SetDuration(0.7)
        ag:SetLooping("BOUNCE")
        g.pulse = ag
        g.anim = anim
    end)
    g:Hide()
    glows[button] = g
    StyleGlow(g, button)
    return g
end

function ShowGlow(button, on)
    if not on then
        local g = glows[button]
        if g and g:IsShown() then
            if g.pulse then g.pulse:Stop() end
            g:Hide()
        end
        return
    end
    local g = GlowFor(button)
    if not g:IsShown() then
        g:Show()
        if g.pulse and Style("glowPulse") then
            g.pulse:Play()
        else
            g:SetAlpha(1)
        end
    end
end

function RefreshGlow()
    local enabled = DB().glow ~= false
    local count = 0
    for _, b in ipairs(buttons) do
        local on = false
        if enabled then
            local m = MacroOnButton(b)
            on = m ~= nil and emptyName[m.name] == true
        end
        ShowGlow(b, on)
        if on then count = count + 1 end
    end
    report.glowing = count
    if RefreshArrows then RefreshArrows() end
end

function SetEmpty(emptyState)
    emptyName = {}
    macroAt = {}
    -- found again rather than read from the remembered slots: renaming a macro
    -- earlier in this update may have moved the others (see FindMacro)
    for _, m in ipairs(MACROS) do
        local idx = FindMacro(m)
        if idx then
            Remember(m, idx)
            macroAt[idx] = m
            if emptyState[m.name] then emptyName[m.name] = true end
        end
    end
    RefreshGlow()
end

-- Tooltip: a clean red message for an empty category. The empty macros have no
-- text, so the tooltip is recognised by the macro's name ("No Water" and so on)
-- and replaced.
--
-- The game rebuilds an action button's tooltip many times a second, and not
-- always through SetAction, so a one-off edit gets overwritten and the tooltip
-- flickers between the two. The replacement is therefore done every time the
-- tooltip is built, with a per-frame check as a backstop.
function CleanTooltip(tip)
    if DB().stockTooltip then return end
    local name = tip.GetName and tip:GetName()
    if not name then return end
    local message
    local lines = tip:NumLines()
    for i = 1, lines do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        -- (a secret line can't be looked up, and isn't one of ours anyway)
        if type(text) == "string" and Readable(text) and EMPTY_MESSAGE[text] then
            message = EMPTY_MESSAGE[text]
            break
        end
    end
    if not message then
        -- no readable name (blank macro names): go by the button the mouse is on
        local owner = tip.GetOwner and tip:GetOwner()
        if owner and owner ~= UIParent then
            local ok, m = pcall(MacroOnButton, owner)
            if ok and m and not m.special and emptyName[m.name] then
                message = "No " .. m.label .. " in inventory."
            end
        end
    end
    if not message then return end
    local first = _G[name .. "TextLeft1"]
    local firstText = first and first:GetText()
    if lines == 1 and Readable(firstText) and firstText == message then return end
    tip:ClearLines()
    local tc = StyleColor("tooltipColor")
    tip:AddLine(message, tc[1], tc[2], tc[3])
    tip:Show()
end

-- Tooltip: on a Water or Food button whose right-click conjures (rightCast, set
-- by UpdateCore), a last line saying so. Added once per build (the game builds
-- an action tooltip afresh each time), skipped if it is there already.
function RightClickHint(tip)
    local owner = tip.GetOwner and tip:GetOwner()
    if not owner or owner == UIParent then return end
    local ok, m = pcall(MacroOnButton, owner)
    local spell = ok and m and rightCast[m.name]
    if not spell then return end
    local line = Loc("Right-click: ") .. spell
    local name = tip:GetName()
    for i = 1, tip:NumLines() do
        local fs = name and _G[name .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        if Readable(text) and text == line then return end
    end
    tip:AddLine(line, 0.25, 1, 0.25)
    tip:Show()
end

if GameTooltip then
    -- every time the tooltip is (re)built from data
    -- (each call pcall'd: whatever the game puts in a tooltip, our tidy-up must
    -- never throw an error into the game's own tooltip code)
    local function clean(tip) pcall(CleanTooltip, tip) end
    -- (a build: the tidy-up, then the right-click line; not on every frame)
    local function built(tip)
        clean(tip)
        pcall(RightClickHint, tip)
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        pcall(TooltipDataProcessor.AddTooltipPostCall, TooltipDataProcessor.AllTypes,
            function(tip) if tip == GameTooltip then built(tip) end end)
    end
    -- older style tooltip building
    if hooksecurefunc then
        pcall(hooksecurefunc, GameTooltip, "SetAction", built)
    end
    -- backstop: undo it if the stock text comes back between rebuilds
    pcall(GameTooltip.HookScript, GameTooltip, "OnUpdate", clean)
end
