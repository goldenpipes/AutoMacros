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

-- Automatic: a button in a column (another action button straight above or
-- below it, none beside it), as on a bar at the side of the screen, opens
-- away from the nearer side: right on the left half, left on the right half.
-- One in a row opens up in the lower half of the screen, down in the upper
-- half. Anything else (a grid, a lone button) opens away from the nearest edge.
function POPOUT.Auto(b)
    local x, y, w, h = POPOUT.Rect(b)
    if not x then return "up" end
    local s = UIParent:GetEffectiveScale()
    local sw, sh = UIParent:GetWidth() * s, UIParent:GetHeight() * s
    local column, row = false, false
    for _, o in ipairs(buttons) do
        if o ~= b and o:IsVisible() then
            local ox, oy = POPOUT.Rect(o)
            if ox then
                local dx, dy = math.abs(ox - x), math.abs(oy - y)
                if dx < w * 0.5 and dy > h * 0.5 and dy < h * 1.8 then column = true end
                if dy < h * 0.5 and dx > w * 0.5 and dx < w * 1.8 then row = true end
            end
        end
    end
    if column and not row then return x < sw / 2 and "right" or "left" end
    if row and not column then return y < sh / 2 and "up" or "down" end
    local near, best
    for edge, d in pairs({ left = x, right = sw - x, bottom = y, top = sh - y }) do
        if not best or d < best then near, best = edge, d end
    end
    return POPOUT.AWAY[near]
end

-- The direction for our button m's popout on action button b.
function POPOUT.Direction(b, m)
    local set = m and type(DB().popDir) == "table" and DB().popDir[m.key]
    if set == "up" or set == "down" or set == "left" or set == "right" then return set end
    local ok, dir = pcall(POPOUT.Auto, b)
    return ok and dir or "up"
end

-- The popup items' size in frame f's units: Item size, a percentage like Edit
-- Mode's Icon Size, of a stock action button (Blizzard's template at its own
-- size); with EllesmereUI's look, of your EllesmereUI buttons.
function BLIZZ_ART.ItemSize(f)
    local base = EUIButtonLook() and (BLIZZ_ART.BarButtonSize()) or BLIZZ_ART.native or 36
    return BarUnits(f, base * (tonumber(Style("itemScale")) or 100) / 100)
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
        if type(text) == "string" and EMPTY_MESSAGE[text] then
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
    if lines == 1 and first and first:GetText() == message then return end
    tip:ClearLines()
    local tc = StyleColor("tooltipColor")
    tip:AddLine(message, tc[1], tc[2], tc[3])
    tip:Show()
end

if GameTooltip then
    -- every time the tooltip is (re)built from data
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        pcall(TooltipDataProcessor.AddTooltipPostCall, TooltipDataProcessor.AllTypes,
            function(tip) if tip == GameTooltip then CleanTooltip(tip) end end)
    end
    -- older style tooltip building
    if hooksecurefunc then
        pcall(hooksecurefunc, GameTooltip, "SetAction", CleanTooltip)
    end
    -- backstop: undo it if the stock text comes back between rebuilds
    pcall(GameTooltip.HookScript, GameTooltip, "OnUpdate", CleanTooltip)
end
