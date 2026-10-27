-- AutoMacros: Settings, part 1: the Buttons page (available counts, recipes, the
-- not-on-your-bars glow), popout directions, the preview strips.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---------------------------------------------------------------------------
-- Settings: tabs laid out after EllesmereUI's Cooldown Manager pages. Each tab
-- has a preview strip at the top and its settings below, two to a row on the
-- EllesmereUI page (one to a row on our page in Blizzard's options window).
-- ---------------------------------------------------------------------------
UI = {}   -- the settings code's own helpers, kept together in one table

-- Re-reads the values shown on our EllesmereUI page while it is on screen.
function RefreshEUIPage()
    local E = EllesmereUI
    if not (E and E.RefreshPage and E.GetActiveModule and E.GetPluginModuleKey) then return end
    pcall(function()
        if E:GetActiveModule() == E.GetPluginModuleKey("AutoMacros", "options") then E:RefreshPage() end
    end)
end

-- Dresses a preview button like a real action button (see EUIButtonLook).
-- Run again on every refresh, so switching EllesmereUI styling shows at once.
function UI.StyleSample(b)
    StyleButtonArt(b, ApplyHover({ look = EUIButtonLook() }))
end

-- A preview button the size of an action button, drawn like the real ones.
function UI.SampleButton(parent, size, icon)
    local f = ItemButton(parent)
    f.want = size
    f.icon:SetTexture(icon or QUESTION_MARK)
    UI.StyleSample(f)
    return f
end

function UI.SmallText(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetText(Loc(text))
    return fs
end

-- ---- the buttons (categories) ----

-- every button this character can have (class buttons only on that class)
function UI.AvailableButtons()
    pcall(RebuildMacros)
    local _, class = UnitClass("player")
    local list = {}
    for _, e in ipairs(ALL) do
        if not e.class or e.class == class then list[#list + 1] = e end
    end
    return list
end

-- The icon a button shows now: its current item or spell, or its placeholder.
function UI.CategoryIcon(e)
    local list = flyoutItems[e.name]
    local first = list and list[1]
    if first then
        if e.kind == "spells" or first.spell then return SpellIcon(first.id) end
        return IconFor({ item = first.id })
    end
    if e.special == "scroll" then return SpellIcon(SCROLL_SPELL) end
    if e.kind == "spells" and e.spells then return SpellIcon(e.spells[1]) end
    return IconFor(e.placeholder)
end

-- (RefreshHeaders, RefreshOptions: defined below)

-- Turns a button on or off, the same as /amac add and /amac remove.
function UI.SetEnabled(e, on)
    OnOff()[e.key] = on and true or false
    if not on then
        toDelete[e.key] = e   -- its macro goes on the next update
        if InCombatLockdown() then Note(e.title .. ": macro will be deleted when combat ends") end
    end
    Refresh()
    RefreshHeaders()
    RefreshOptions()
end

-- How many different things a button that is off could use (0 when it is on):
-- the settings show it as "N available", so you know it is worth turning on.
function UI.CouldUse(e)
    if Enabled(e) or not report.have then return 0 end
    local ok, n = pcall(UI.Available, e, report.have)
    return ok and n or 0
end

-- The things counted, and where they come from (the second result): bags =
-- items you carry; spells = spells of the button you know (teleports,
-- Cannibalize); create = a healthstone or mana gem you can conjure and carry
-- none of; craft = what your known recipes make when you carry every reagent
-- (First Aid's bandages and potions, Alchemy, Cooking, ...).
function UI.Available(e, have)
    local parts = { bags = 0, spells = 0, create = 0, craft = 0 }
    if e.kind == "travel" then
        for _, o in ipairs(TravelOptions(e, have)) do
            if o.spell then parts.spells = parts.spells + 1 else parts.bags = parts.bags + 1 end
        end
    elseif e.set then
        local counted = {}
        for _, c in ipairs(Candidates(have, e.set)) do
            counted[c.id] = true
            parts.bags = parts.bags + 1
        end
        parts.spells = #KnownSpells(e)
        local create, carried = MadeCreate(e.set, have)
        if create and not carried then parts.create = 1 end
        local recipes = type(DB().recipes) == "table" and DB().recipes[CharKey()]
        for id, need in pairs(type(recipes) == "table" and recipes or {}) do
            if not counted[id] and InSet(e.set, id) and UI.CanCraft(need) then parts.craft = parts.craft + 1 end
        end
    end
    return parts.bags + parts.spells + parts.create + parts.craft, parts
end

-- "1 available in bags", "3 available as spells", "4 available: 1 in bags, 3 spells"
function UI.AvailableText(n, parts)
    local list = {}
    if parts.bags > 0 then list[#list + 1] = { parts.bags, "in bags", parts.bags .. " in bags" } end
    if parts.spells > 0 then
        list[#list + 1] = { parts.spells, "as spells", parts.spells .. (parts.spells == 1 and " spell" or " spells") }
    end
    if parts.create > 0 then list[#list + 1] = { parts.create, "to create", parts.create .. " to create" } end
    if parts.craft > 0 then list[#list + 1] = { parts.craft, "to craft", parts.craft .. " to craft" } end
    if #list == 1 then
        local kind = list[1][2]
        if kind == "as spells" and n == 1 then kind = "as a spell" end
        return n .. " available " .. kind
    end
    local shown = {}
    for _, p in ipairs(list) do shown[#shown + 1] = p[3] end
    return n .. " available: " .. table.concat(shown, ", ")
end

-- true when your bags hold every reagent a recipe needs (need: see UI.ScanRecipes)
function UI.CanCraft(need)
    if type(need) ~= "table" then return false end
    for _, r in ipairs(need) do
        local got = 0
        for _, id in ipairs(r.ids or {}) do got = got + (CountOf(id) or 0) end
        if got < (r.n or 1) then return false end
    end
    return true
end

-- Your recipes, read while a profession window is open (the game shows them
-- nowhere else), kept per character: db.recipes[char][made item ID] = list of
-- { ids = { reagent item IDs, any of them }, n = how many }. Updated each time
-- a window is open; recipes you know only (retail lists the rest too).
-- A profession window's events (retail sends many while one is open, the
-- first before its list is filled in): one read a second after the last.
function UI.QueueScan()
    if UI.scanQueued then return end
    UI.scanQueued = true
    local function run()
        UI.scanQueued = nil
        local ok, err = pcall(UI.ScanRecipes)
        if not ok then Fail("reading your recipes", err) end
        Update()   -- the settings' "available" counts
    end
    if C_Timer and C_Timer.After then C_Timer.After(1, run) else run() end
end

function UI.ScanRecipes()
    local db = DB()
    if type(db.recipes) ~= "table" then db.recipes = {} end
    local mine = type(db.recipes[CharKey()]) == "table" and db.recipes[CharKey()] or {}
    db.recipes[CharKey()] = mine
    local function ItemOf(link) return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil end
    local T = C_TradeSkillUI
    if T and T.GetAllRecipeIDs and T.GetRecipeSchematic and T.GetRecipeInfo then
        -- retail: recipe IDs, each with its made item and reagent slots
        for _, recipeID in ipairs(T.GetAllRecipeIDs() or {}) do
            local info = T.GetRecipeInfo(recipeID)
            local s = info and info.learned and T.GetRecipeSchematic(recipeID, false)
            if s and s.outputItemID then
                local need = {}
                for _, slot in ipairs(s.reagentSlotSchematics or {}) do
                    if slot.required ~= false then   -- (not optional or finishing reagents)
                        local ids = {}
                        for _, r in ipairs(slot.reagents or {}) do
                            if r.itemID then ids[#ids + 1] = r.itemID end
                        end
                        if #ids > 0 then need[#need + 1] = { ids = ids, n = slot.quantityRequired or 1 } end
                    end
                end
                mine[s.outputItemID] = need
            end
        end
    elseif GetNumTradeSkills and GetTradeSkillInfo then
        -- the older clients: the window's list, headers skipped
        for i = 1, GetNumTradeSkills() or 0 do
            local _, kind = GetTradeSkillInfo(i)
            local made = kind and kind ~= "header" and kind ~= "subheader" and ItemOf(GetTradeSkillItemLink(i))
            if made then
                local need = {}
                for r = 1, GetTradeSkillNumReagents(i) or 0 do
                    local _, _, count = GetTradeSkillReagentInfo(i, r)
                    local reagent = ItemOf(GetTradeSkillReagentItemLink(i, r))
                    if reagent and count then need[#need + 1] = { ids = { reagent }, n = count } end
                end
                mine[made] = need
            end
        end
    end
end

UI.HAVE_COLOR = "|cff40ff40"   -- the "in bags" note

-- true when you carry items for a button but it is on none of the action bars
-- on screen (as the spellbook marks spells missing from your bars)
function UI.NotOnBars(e)
    if not report.have then return false end
    local ok, n = pcall(Stocked, e, report.have)
    if not ok or n == 0 then return false end
    return ((report.onBar or {})[e.name] or 0) == 0
end

-- The spellbook's "not on your action bars" glow on settings icon b: its
-- atlas, added on, a little past the button, pulsing between half and full
-- (Blizzard_SpellBookItem.xml, ActionBarHighlight). Older clients without that
-- art get the classic checked-button highlight.
function UI.UnplacedGlow(b)
    if b.unplaced then return b.unplaced end
    local g = b:CreateTexture(nil, "OVERLAY", nil, 7)
    local ok, found = pcall(g.SetAtlas, g, "spellbook-item-unassigned-glow")
    if not ok or found == false then g:SetTexture("Interface\\Buttons\\CheckButtonHilight") end
    g:SetBlendMode("ADD")
    g:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 3)
    g:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 3, -3)
    -- bright even on a button that is off (drawn at half alpha)
    if g.SetIgnoreParentAlpha then pcall(g.SetIgnoreParentAlpha, g, true) end
    local anim = g:CreateAnimationGroup()
    anim:SetLooping("REPEAT")
    for i, step in ipairs({ { 0.5, 1, "OUT" }, { 1, 0.5, "IN" } }) do
        local a = anim:CreateAnimation("Alpha")
        pcall(a.SetFromAlpha, a, step[1])
        pcall(a.SetToAlpha, a, step[2])
        a:SetDuration(0.5)
        a:SetOrder(i)
        pcall(a.SetSmoothing, a, step[3])
    end
    g.anim = anim
    g:Hide()
    b.unplaced = g
    return g
end

-- the tooltip line for it, in the spellbook's light blue
function UI.AddNotOnBarsLine(tip)
    local c = LIGHTBLUE_FONT_COLOR
    local r, g, b = 0.53, 0.67, 1
    if c and c.GetRGB then r, g, b = c:GetRGB() end
    tip:AddLine("Not on your action bars - drag it onto one", r, g, b)
end

-- Puts a button's macro on the cursor, to drop on any action bar (Blizzard's,
-- EllesmereUI's, ...). A button that is off is switched on first, which makes
-- its macro straight away. Bars cannot be changed in combat, so not then.
function UI.PickUp(e)
    if not e then return end
    if InCombatLockdown() then
        Print("buttons cannot be placed on action bars in combat")
        return
    end
    if not Enabled(e) then UI.SetEnabled(e, true) else Update() end
    local idx = FindMacro(e)
    if not idx then
        Print(e.title .. ": its macro could not be made (are your macro slots full?)")
        return
    end
    local ok, err = pcall(PickupMacro, idx)
    if not ok then Fail("picking up " .. e.title, err) end
end

-- Names on the settings pages, where the section already says what kind of
-- button it is (Recovery, Buffs): "Agility", not "Agility Buff". The macros
-- keep their full names (title): a bare "Agility" or "Health" could clash with
-- a macro of your own.
UI.SHORT = {
    healthpot = "Health", manapot = "Mana", ragepot = "Rage",
    agility = "Agility", intellect = "Intellect", stamina = "Stamina", strength = "Strength",
    spirit = "Spirit", armor = "Armor", otherbuff = "Other", weaponbuff = "Weapon", cure = "Cure",
}
function UI.Name(e)
    return UI.SHORT[e.key] or e.title
end

-- How the Buttons tab groups them (each group is shown A-Z, see
-- UI.ButtonSections). Anything not listed goes under Other.
UI.BUTTON_GROUPS = {
    { name = "Recovery", keys = { "healthpot", "manapot", "ragepot", "bandage", "cure" } },
    { name = "Food & Drink", keys = { "food", "water", "bufffood" } },
    { name = "Buffs", keys = { "agility", "intellect", "stamina", "strength", "spirit", "armor",
        "resistance", "otherbuff", "flask", "weaponbuff" } },
    { name = "Utility", keys = { "travel", "questitem", "explosives" } },
    { name = "Class", keys = { "portals", "comprehend" } },
}

-- the buttons switched on for this character
function UI.EnabledButtons()
    local list = {}
    for _, e in ipairs(UI.AvailableButtons()) do
        if Enabled(e) then list[#list + 1] = e end
    end
    return list
end

-- which buttons the Buttons page lists (your own included, with their names):
-- it is built again when this changes (see UI.ShowPanel)
function UI.ButtonsStamp()
    local keys = {}
    for _, e in ipairs(UI.AvailableButtons()) do keys[#keys + 1] = e.key .. "=" .. tostring(e.title) end
    return table.concat(keys, ",")
end

-- which buttons the Direction section lists: the page is built again when this
-- changes (see UI.ShowPanel)
function UI.DirectionStamp()
    local keys = {}
    for _, e in ipairs(UI.EnabledButtons()) do keys[#keys + 1] = e.key end
    return table.concat(keys, ",")
end

-- The Popout page's Direction section: a note, then a dropdown per button that
-- is on (Automatic, Up, Down, Left, Right), saved in db.popDir (Automatic = not saved).
function UI.DirectionItems()
    local items = { { type = "text", height = 50, text = function()
        return "Automatic opens away from the screen edge: to the right on a bar down the left side,"
            .. " to the left on the right side, up from a bar at the bottom, down from one at the top."
    end } }
    local list = UI.EnabledButtons()
    if #list == 0 then
        items[#items + 1] = { type = "text", height = 24,
            text = function() return "No buttons are on yet (see the AutoMacros page)." end }
    end
    for _, e in ipairs(list) do
        items[#items + 1] = { type = "choice", label = e.title, list = function() return POPOUT.DIRS end,
            get = function()
                local d = DB().popDir
                return type(d) == "table" and d[e.key] or "auto"
            end,
            set = function(v)
                local db = DB()
                if type(db.popDir) ~= "table" then db.popDir = {} end
                db.popDir[e.key] = (v ~= "auto") and v or nil
                Refresh()   -- the indicators move to their new side
            end }
    end
    return items
end

-- The Buttons tab: one section per group, each a grid of checkboxes in
-- alphabetical order of the names shown.
function UI.ButtonSections()
    local byKey, placed = {}, {}
    for _, e in ipairs(UI.AvailableButtons()) do byKey[e.key] = e end
    local sections = {}
    local function add(name, list)
        table.sort(list, function(a, b)
            return tostring(Loc(UI.Name(a))):lower() < tostring(Loc(UI.Name(b))):lower()
        end)
        if #list > 0 then sections[#sections + 1] = { name = name, items = { { type = "buttongrid", entries = list } } } end
    end
    for _, g in ipairs(UI.BUTTON_GROUPS) do
        local list = {}
        for _, key in ipairs(g.keys) do
            local e = byKey[key]
            if e and not e.custom then
                list[#list + 1] = e
                placed[key] = true
            end
        end
        add(g.name, list)
    end
    local custom, other = {}, {}
    for _, e in ipairs(UI.AvailableButtons()) do
        if e.custom then custom[#custom + 1] = e
        elseif not placed[e.key] then other[#other + 1] = e end
    end
    add("Custom", custom)
    add("Other", other)
    return sections
end

-- ---- preview strips (the top of each tab) ----
-- Each builder fills frame f (width wide) and returns its height. They are run
-- again to refresh, so they only create their parts the first time.
UI.HEADERS = {}

-- the flyout preview's note: under it, or across the bottom of its page
UI.FLYOUT_NOTE = "Hover an item to see the hover color. The highlighted border marks the one in use."

-- Buttons: every button's icon, grey when it is off; clicking one turns it on or off.
UI.HEADERS.buttons = function(f, width)
    local size, gap = 36, 6
    local list = UI.AvailableButtons()
    local perRow = math.max(1, math.floor((width - 40 + gap) / (size + gap)))
    local rows = math.ceil(#list / perRow)
    f.icons = f.icons or {}
    for i, e in ipairs(list) do
        local b = f.icons[i]
        if not b then
            b = UI.SampleButton(f, size)
            b:SetScript("OnClick", function(self) UI.SetEnabled(self.entry, not Enabled(self.entry)) end)
            b:RegisterForDrag("LeftButton")
            b:SetScript("OnDragStart", function(self) UI.PickUp(self.entry) end)
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(self.entry.title)
                GameTooltip:AddLine(Enabled(self.entry) and "On - click to turn off" or "Off - click to turn on", 1, 0.82, 0)
                if UI.CouldUse(self.entry) > 0 then   -- (off, with something available)
                    local ok, n, parts = pcall(UI.Available, self.entry, report.have)
                    if ok then GameTooltip:AddLine(UI.AvailableText(n, parts), 0.25, 1, 0.25) end
                end
                if UI.NotOnBars(self.entry) then UI.AddNotOnBarsLine(GameTooltip) end
                GameTooltip:AddLine("Drag onto an action bar to place it", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            f.icons[i] = b
        end
        b.entry = e
        local row, col = math.floor((i - 1) / perRow), (i - 1) % perRow
        local inRow = (row == rows - 1) and (#list - row * perRow) or perRow
        local left = (width - (inRow * (size + gap) - gap)) / 2
        b.icon:SetTexture(UI.CategoryIcon(e))
        UI.StyleSample(b)   -- (sizes it, so before placing)
        BLIZZ_ART.Point(b, "TOPLEFT", f, "TOPLEFT", left + col * (size + gap), -16 - row * (size + gap))
        local on = Enabled(e)
        pcall(b.icon.SetDesaturated, b.icon, not on)
        b:SetAlpha(on and 1 or 0.5)
        -- off, but you carry items for it: a green count in the corner
        local n = UI.CouldUse(e)
        if not b.have then
            b.have = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            b.have:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
            b.have:SetTextColor(0.25, 1, 0.25)
            -- the button is at half alpha when off: keep the count bright
            if b.have.SetIgnoreParentAlpha then pcall(b.have.SetIgnoreParentAlpha, b.have, true) end
        end
        b.have:SetText(n > 0 and n or "")
        -- you carry items for it but it is on none of your bars: the spellbook's glow
        local g = UI.UnplacedGlow(b)
        local loose = UI.NotOnBars(e)
        g:SetShown(loose)
        if loose and not g.anim:IsPlaying() then g.anim:Play() elseif not loose then g.anim:Stop() end
        b:Show()
    end
    for i = #list + 1, #f.icons do f.icons[i]:Hide() end
    f.hint = f.hint or UI.SmallText(f, "Click an icon to turn it on or off for this character; drag it onto an action bar. Green number: how many are available (in bags, spells, or yours to create or craft). Glow: you carry some, but it is on none of your bars.")
    f.hint:ClearAllPoints()
    f.hint:SetWidth(width - 20)
    f.hint:SetPoint("TOP", f, "TOP", 0, -16 - rows * (size + gap) - 4)
    return 16 + rows * (size + gap) + 4 + math.max(26, (f.hint:GetStringHeight() or 12) + 8)
end

-- Highlight: an empty button with the highlight next to one in stock.
UI.HEADERS.glow = function(f, width)
    if not f.samples then
        f.samples = {}
        local defs = { { "Empty", 3371, true }, { "In stock", 929, false } }
        for i, d in ipairs(defs) do
            local b = UI.SampleButton(f, 40, IconFor({ item = d[2] }))
            b.label = UI.SmallText(f, d[1])
            b.label:SetPoint("TOP", b, "BOTTOM", 0, -6)
            if d[3] then ShowGlow(b, true) end
            f.samples[i] = b
        end
        f.hint = UI.SmallText(f, "Buttons whose category is empty get this border. Changes show here straight away.")
    end
    local left = width / 2 - 70
    for i, b in ipairs(f.samples) do
        UI.StyleSample(b)
        BLIZZ_ART.Point(b, "TOPLEFT", f, "TOPLEFT", left + (i - 1) * 100, -20)
    end
    f.hint:ClearAllPoints()
    f.hint:SetPoint("TOP", f, "TOP", 0, -90)
    return 116
end

-- Flyout: a button with its tab and an open popup drawn with the current look.
UI.HEADERS.flyout = function(f, width)
    if not f.btn then
        f.btn = UI.SampleButton(f, 40, IconFor({ item = 929 }))
        local a = ArrowFor(f.btn)
        if a then a:Show() end
        f.arrow = a
        local pop = CreateFrame("Frame", nil, f)
        pop.items = {}
        for i, id in ipairs({ 929, 1710, 3928 }) do
            local e = ItemButton(pop)
            e.icon:SetTexture(IconFor({ item = id }))
            e.count:SetText(i == 1 and "5" or "")
            e.selected = (i == 1)   -- the one in use
            pop.items[i] = e
        end
        f.pop = pop
        f.hint = UI.SmallText(f, UI.FLYOUT_NOTE)
    end
    -- the sample is the size of your action buttons on screen (whatever the
    -- settings window's scale), so the indicator and items compare
    local px = PixelSize(f)
    local bw, bh = UI.ButtonSize()
    bw, bh = BarUnits(f, bw), BarUnits(f, bh)
    -- the hint at the bottom, under the sample button; a preview in a side
    -- column has it as a note across the bottom of the page instead (MakePanel)
    local base = 12
    f.hint:ClearAllPoints()
    if f:GetParent() and f:GetParent().noteBelow then
        f.hint:Hide()
    else
        f.hint:SetWidth(width - 10)
        f.hint:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
        f.hint:Show()
        base = 10 + (f.hint:GetStringHeight() or 12) + 12
    end
    f.btn.want = bw
    UI.StyleSample(f.btn)
    BLIZZ_ART.Point(f.btn, "BOTTOMLEFT", f, "BOTTOMLEFT", Snap(f, (width - bw) / 2), Snap(f, base))
    if f.arrow then StyleArrow(f.arrow) end
    local pop = f.pop
    StyleFlyout(pop)
    for _, e in ipairs(pop.items) do StyleEntry(e) end
    LayoutFlyout(pop, pop.items, #pop.items, f.btn, f.arrow)   -- same layout as the real popup
    local extra = 0
    if BLIZZ_ART.PopupArt() then   -- the art reaches past the popup above and below
        local _, top, _, below = BLIZZ_ART.BarInsets(pop)
        extra = (top + 2 * below) * BLIZZ_ART.ArtScale(pop)
    end
    return base + bh + BLIZZ_ART.TabHeight() * px + 3 + pop:GetHeight() + extra + 16
end

UI.headerFrames = {}   -- one per preview and width it is shown at

-- Shows the preview strip key in host. onResize(h) is called when a later
-- refresh changes its height (a bigger popup, say).
function UI.ShowHeader(key, host, width, onResize)
    width = math.floor(width or 500)
    local id = key .. ":" .. width
    local f = UI.headerFrames[id]
    if not f then
        f = CreateFrame("Frame", nil, host)
        f.key, f.width = key, width
        UI.headerFrames[id] = f
    end
    f.onResize = onResize
    f:SetParent(host)
    f:SetWidth(width)
    local ok, h = pcall(UI.HEADERS[key], f, width)
    if not ok then
        Fail("options preview", h)
        h = 1
    end
    f.h = h
    f:SetHeight(h)
    UI.FitHeader(f)
    f:Show()
    return h
end

-- A host with fixedH (our Blizzard pages) keeps its height: a preview taller
-- than that is shrunk to fit, centred, so changing a setting never moves the
-- settings below it. Other hosts take the preview at its own size.
function UI.FitHeader(f)
    local host = f:GetParent()
    local fixed = host and host.fixedH
    f:ClearAllPoints()
    if fixed then
        f:SetScale(math.min(1, fixed / math.max(1, f.h or 1)))
        f:SetPoint("TOP", host, "TOP", 0, 0)
    else
        f:SetScale(1)
        f:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    end
end

RefreshHeaders = function()
    for _, f in pairs(UI.headerFrames) do
        if f:IsVisible() then
            local ok, h = pcall(UI.HEADERS[f.key], f, f.width)
            if ok and h ~= f.h then
                f.h = h
                f:SetHeight(h)
                UI.FitHeader(f)
                if f.onResize then pcall(f.onResize, h) end
            end
        end
    end
end
