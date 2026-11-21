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

-- Re-reads the values shown on our EllesmereUI page while it is on screen;
-- rebuild: builds the page again (rows added or gone, e.g. your own buttons).
function RefreshEUIPage(rebuild)
    local E = EllesmereUI
    if not (E and E.RefreshPage and E.GetActiveModule and E.GetPluginModuleKey) then return end
    pcall(function()
        if E:GetActiveModule() == E.GetPluginModuleKey("AutoMacros", "options") then E:RefreshPage(rebuild) end
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
        if first.macroIcon then return first.macroIcon end
        if first.icon then return first.icon end
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
    -- the Buffs button: on and off with combining (its icon, /amac add buffs)
    if e.oneBuff then return UI.SetOneBuff(on) end
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
    elseif e.kind == "fishing" then
        parts.bags = #FishingList(have)
    elseif e.kind == "trinket" then
        parts.bags = #TrinketList(e.slot, have)
    elseif e.kind == "weapons" then
        parts.bags = SwapBody(have) and 1 or 0
    elseif e.kind == "spells" then   -- (Portals, Professions)
        parts.spells = #KnownSpells(e)
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

-- the name of the profession whose window is open, or nil
function UI.OpenProfession()
    local T = C_TradeSkillUI
    if T and T.GetBaseProfessionInfo then
        local ok, info = pcall(T.GetBaseProfessionInfo)
        if ok and type(info) == "table" and info.professionName then return info.professionName end
    end
    if GetTradeSkillLine then
        local ok, name = pcall(GetTradeSkillLine)
        if ok and type(name) == "string" then return name end
    end
end

function UI.ScanRecipes()
    local db = DB()
    if type(db.recipes) ~= "table" then db.recipes = {} end
    local mine = type(db.recipes[CharKey()]) == "table" and db.recipes[CharKey()] or {}
    db.recipes[CharKey()] = mine
    -- the Cooking window: also every ingredient of a recipe that still gives
    -- you skill (orange, yellow or green), kept off the food buttons (CookingReagent)
    local skillUp = UI.OpenProfession() == CookingName() and {} or nil
    local gray = skillUp and {}   -- (and of a gray recipe: no skill left in it)
    local function ItemOf(link) return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil end
    local T = C_TradeSkillUI
    if T and T.GetAllRecipeIDs and T.GetRecipeSchematic and T.GetRecipeInfo then
        -- retail: recipe IDs, each with its made item and reagent slots
        for _, recipeID in ipairs(T.GetAllRecipeIDs() or {}) do
            local info = T.GetRecipeInfo(recipeID)
            local s = info and info.learned and T.GetRecipeSchematic(recipeID, false)
            if s and s.outputItemID then
                -- (relativeDifficulty 3 = trivial, gray: no skill)
                local gives = skillUp and info.relativeDifficulty ~= nil and info.relativeDifficulty ~= 3
                local need = {}
                for _, slot in ipairs(s.reagentSlotSchematics or {}) do
                    if slot.required ~= false then   -- (not optional or finishing reagents)
                        local ids = {}
                        for _, r in ipairs(slot.reagents or {}) do
                            if r.itemID then
                                ids[#ids + 1] = r.itemID
                                if gives then skillUp[r.itemID] = true
                                elseif gray and info.relativeDifficulty == 3 then gray[r.itemID] = true end
                            end
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
                local gives = skillUp and (kind == "optimal" or kind == "medium" or kind == "easy")
                local need = {}
                for r = 1, GetTradeSkillNumReagents(i) or 0 do
                    local _, _, count = GetTradeSkillReagentInfo(i, r)
                    local reagent = ItemOf(GetTradeSkillReagentItemLink(i, r))
                    if reagent and count then
                        need[#need + 1] = { ids = { reagent }, n = count }
                        if gives then skillUp[reagent] = true
                        elseif gray and kind == "trivial" then gray[reagent] = true end
                    end
                end
                mine[made] = need
            end
        end
    end
    if skillUp then
        -- (the whole list again each time: a recipe gone gray lets its ingredients back)
        if type(db.cookSkillUp) ~= "table" then db.cookSkillUp = {} end
        db.cookSkillUp[CharKey()] = skillUp
        -- gray: only in gray recipes (one that still gives skill keeps it off the food buttons)
        for id in pairs(gray) do
            if skillUp[id] then gray[id] = nil end
        end
        if type(db.cookGray) ~= "table" then db.cookGray = {} end
        db.cookGray[CharKey()] = gray
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
    -- (asked first: Classic Era's SetAtlas says nothing for an atlas it lacks,
    -- which left an empty, invisible glow there before 0.117.2)
    local atlas = "spellbook-item-unassigned-glow"
    local okInfo, info = pcall(function() return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) end)
    local ok, found = false, false
    if okInfo and info then ok, found = pcall(g.SetAtlas, g, atlas) end
    if not ok or found == false or not (g.GetAtlas and g:GetAtlas()) then
        g:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    end
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
    haste = "Haste",
}
function UI.Name(e)
    return UI.SHORT[e.key] or e.title
end

-- How the Buttons tab groups them (each group is shown A-Z, see
-- UI.ButtonSections). Anything not listed goes under Other.
UI.BUTTON_GROUPS = {
    { name = "Recovery", keys = { "healthpot", "manapot", "ragepot", "bandage", "cure" } },
    { name = "Food & Drink", keys = { "food", "water", "combo", "bufffood" } },
    { name = "Buffs and Debuffs", buffs = true, keys = { "agility", "intellect", "stamina", "strength", "spirit",
        "armor", "resistance", "haste", "spellpower", "otherbuff", "buffs", "flask", "weaponbuff", "enemydebuff" } },
    { name = "Utility", keys = { "travel", "questitem", "explosives", "professions", "tracking", "utility",
        "openable", "fishing" } },
    { name = "Gear", keys = { "trinket1", "trinket2", "weaponswap" } },
    { name = "Class", keys = { "portals", "comprehend", "pets", "aspects" } },
    { name = "Group", keys = { "marker" } },
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

-- One Buffs button instead of the stat / armor / resistance / other buttons,
-- for this character. Their macros go (their on/off is kept, so switching
-- back brings them back); the Buffs button is on while this is (Enabled).
function UI.SetOneBuff(on)
    local db = DB()
    if type(db.oneBuff) ~= "table" then db.oneBuff = {} end
    db.oneBuff[CharKey()] = on and true or nil
    for _, e in ipairs(CATALOG) do
        if (on and e.buffPart) or (not on and e.oneBuff) then toDelete[e.key] = e end
    end
    if InCombatLockdown() then Note("buff buttons will change when combat ends") end
    UI.CustomChanged()   -- (macros, the Buttons page and EllesmereUI's page built again)
end

-- a part on or off for this character's Buffs button; saved as true or false
-- (the rest keep following the class's defaults, see BuffParts)
function UI.SetBuffPart(part, on)
    local db = DB()
    if type(db.buffStats) ~= "table" then db.buffStats = {} end
    local mine = db.buffStats[CharKey()]
    if type(mine) ~= "table" then mine = {}; db.buffStats[CharKey()] = mine end
    mine[part] = on and true or false
    Refresh()
    RefreshHeaders()
    RefreshEUIPage()
end

UI.PART_NAMES = { agility = "Agility", intellect = "Intellect", spirit = "Spirit", stamina = "Stamina",
    strength = "Strength", armor = "Armor", resistance = "Resistance", haste = "Haste",
    spellpower = "Spell Power", other = "Other" }

-- "Intellect, Spirit, Stamina +4": what the Buffs button takes, short
function UI.BuffSummary()
    local on, names = BuffParts(), {}
    for _, part in ipairs(BUFF_PARTS) do
        if on[part] then names[#names + 1] = UI.PART_NAMES[part] end
    end
    if #names == 0 then return "None" end
    if #names <= 3 then return table.concat(names, ", ") end
    return names[1] .. ", " .. names[2] .. ", " .. names[3] .. " +" .. (#names - 3)
end

-- the top of the Buffs section: the toggle (it is the Buffs button's on/off,
-- see Enabled), and while it is on, which kinds of buff the button takes:
-- filters, in one dropdown where each is ticked or not
function UI.BuffChoiceItems()
    local items = {
        -- (half while it is alone: on EllesmereUI's page its switch then sits in a
        -- half-width row, by its label; while on, the Buff types dropdown shares its row)
        { type = "toggle", label = "Combine class-related buffs into one button", half = not OneBuff(),
          get = function() return OneBuff() end, set = function(v) UI.SetOneBuff(v) end },
    }
    if OneBuff() then
        items[#items + 1] = { type = "multi", label = "Buff types",
            list = function()
                local list = {}
                for _, part in ipairs(BUFF_PARTS) do list[#list + 1] = { key = part, label = UI.PART_NAMES[part] } end
                return list
            end,
            isOn = function(part) return BuffParts()[part] == true end,
            set = function(part, on) UI.SetBuffPart(part, on) end,
            summary = UI.BuffSummary }
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
                -- (the Buffs button's switch is up by the combine toggle instead)
                if not e.oneBuff then list[#list + 1] = e end
                placed[key] = true
            end
        end
        add(g.name, list)
        -- Buffs: the choice between the stat buttons and one Buffs button first
        if g.buffs and sections[#sections] and sections[#sections].name == g.name then
            local items = sections[#sections].items
            for i, item in ipairs(UI.BuffChoiceItems()) do table.insert(items, i, item) end
            -- and last, what Other Buffs (and the Other buff type) takes
            items[#items + 1] = { type = "text", height = 30, text = function()
                return "Other: buffs that fit none of the above, such as attack power, regeneration or crit." end }
        end
    end
    local custom, other = {}, {}
    for _, e in ipairs(UI.AvailableButtons()) do
        if e.custom then custom[#custom + 1] = e
        elseif not placed[e.key] then other[#other + 1] = e end
    end
    add("Other", other)
    -- your own buttons last, one editable row each (Custom.lua)
    if #custom > 0 then
        sections[#sections + 1] = { name = "Custom", items = { { type = "customrows" } } }
    end
    return sections
end

-- ---- preview strips (the top of each tab) ----
-- Each builder fills frame f (width wide) and returns its height. They are run
-- again to refresh, so they only create their parts the first time.
UI.HEADERS = {}

-- the flyout preview's note: under it, or across the bottom of its page
UI.FLYOUT_NOTE = "Hover an item to see the hover color. The highlighted border marks the one in use."

-- The way button e's popout opens: the direction you chose, or on Automatic
-- the way it opens on your bars (nil when it is on none, or off).
function UI.DirShown(e)
    local dir = POPOUT.Chosen(e)
    if dir ~= "auto" then return dir, false end
    return Enabled(e) and report.barDir and report.barDir[e.name] or nil, true
end

UI.DIR_NAMES = { auto = "Automatic", up = "up", down = "down", left = "left", right = "right" }

-- ---- the Popout page's "Per-Button Overrides" section ----
-- Pick one of your buttons that are on, then set its popout's direction and
-- what clicking an item in it does (the same as right-click / Shift+right-click
-- on its icon on the Buttons page). UI.popoutKey: the button picked.
UI.popoutKey = nil

-- the button picked, or nil while it is "Example" (the default: the page's
-- demo then shows a made-up popout with the global settings)
function UI.PopoutEntry()
    for _, e in ipairs(UI.EnabledButtons()) do
        if e.key == UI.popoutKey then return e end
    end
end

-- which buttons are on, and which one is picked (the Popout page is built
-- again when it changes: the rows below the Button choice come and go)
function UI.EnabledStamp()
    local keys = {}
    for _, e in ipairs(UI.EnabledButtons()) do keys[#keys + 1] = e.key end
    local e = UI.PopoutEntry()
    return table.concat(keys, ",") .. "|" .. (e and e.key or "")
end

UI.DIR_CHOICES = {
    { key = "auto", label = "Automatic" }, { key = "up", label = "Up" }, { key = "right", label = "Right" },
    { key = "down", label = "Down" }, { key = "left", label = "Left" },
}

-- after a change here: the popouts, the Buttons page's tabs, and this page
function UI.PopoutChanged()
    pcall(PrepareSecure)
    Refresh()
    RefreshHeaders()
    UI.RefreshPanels()
    RefreshEUIPage()
end

function UI.EachButtonItems()
    if #UI.EnabledButtons() == 0 then
        return { { type = "text", height = 30, text = function() return "Turn a button on to set its popout here." end } }
    end
    local items = {
        -- "Example" first: the demo shows a made-up popout; pick a button and it
        -- shows that button's popout, and its own settings appear below
        { type = "choice", label = "Button",
            list = function()
                local list = { { key = "_example", label = "Example" } }
                for _, e in ipairs(UI.EnabledButtons()) do list[#list + 1] = { key = e.key, label = e.title } end
                return list
            end,
            get = function() local e = UI.PopoutEntry(); return e and e.key or "_example" end,
            set = function(v)
                UI.popoutKey = (v ~= "_example") and v or nil
                UI.PopoutChanged()
                RefreshEUIPage(true)   -- (its rows change)
            end },
    }
    if not UI.PopoutEntry() then
        items[#items + 1] = { type = "text", height = 30, text = function()
            return "Pick one of your buttons to give its popout its own settings." end }
        return items
    end
    for _, item in ipairs(UI.OwnPopoutItems()) do items[#items + 1] = item end
    return items
end

-- the picked button's own popout settings (UI.EachButtonItems)
function UI.OwnPopoutItems()
    return {
        { type = "choice", label = "Opens", list = function() return UI.DIR_CHOICES end,
            get = function() local e = UI.PopoutEntry(); return e and POPOUT.Chosen(e) or "auto" end,
            set = function(v)
                local e = UI.PopoutEntry()
                if not e then return end
                local db = DB()
                if type(db.popDir) ~= "table" then db.popDir = {} end
                db.popDir[e.key] = (v ~= "auto") and v or nil
                UI.PopoutChanged()
            end },
        { type = "choice", label = "Clicking an item",
            list = function()
                local list = { { key = "default", label = "Global" } }
                for _, c in ipairs(POPOUT_CLICKS) do list[#list + 1] = c end
                return list
            end,
            get = function() local e = UI.PopoutEntry(); return e and OwnPopoutClick(e) or "default" end,
            set = function(v)
                local e = UI.PopoutEntry()
                if not e then return end
                local db = DB()
                if type(db.popClick) ~= "table" then db.popClick = {} end
                db.popClick[e.key] = (v ~= "default") and v or nil
                UI.PopoutChanged()
            end },
        -- its own hover color ("Global" = the one under Global Behavior)
        { type = "color", label = "Hover", key = "entryHover_" .. UI.PopoutEntry().key, alpha = true },
        -- (100 in the middle: half size left, double right, stops at 50)
        (function()
            local it = UI.OwnPopoutNumber("Item size", "popSize", "itemScale", 0, 200, 10, "%d%%")
            it.floor = 50
            return it
        end)(),
        UI.OwnPopoutNumber("Item spacing", "popGap", "entrySpacing", 0, 10, 1, nil,
            function() return BLIZZ_ART.PopupArt() end),   -- (as the global one: the bar's gap with the background on)
        { type = "button", label = "Use global size and spacing",
            action = function()
                local e = UI.PopoutEntry()
                if not e then return end
                for _, dbKey in ipairs({ "popSize", "popGap" }) do
                    local t = DB()[dbKey]
                    if type(t) == "table" then t[e.key] = nil end
                end
                UI.PopoutChanged()
            end },
    }
end

-- a slider for one of the picked button's own popout numbers (saved in
-- db[dbKey][button key], read by PopoutSize / PopoutGap). It shows the
-- button's own value, or the global one (styleKey) until it is moved.
function UI.OwnPopoutNumber(label, dbKey, styleKey, lo, hi, step, fmt, disabled)
    return { type = "range", label = label, min = lo, max = hi, step = step, fmt = fmt, disabled = disabled,
        get = function()
            local e = UI.PopoutEntry()
            local t = DB()[dbKey]
            local v = e and type(t) == "table" and tonumber(t[e.key])
            return v or tonumber(Style(styleKey)) or lo
        end,
        set = function(v)
            local e = UI.PopoutEntry()
            if not e then return end
            local db = DB()
            if type(db[dbKey]) ~= "table" then db[dbKey] = {} end
            db[dbKey][e.key] = tonumber(v)
            pcall(PrepareSecure)   -- (the popouts and the demo; the page stays as it is while you drag)
            RefreshHeaders()
        end }
end

-- "Clicking an item: Use only (set by you)", "... Use and set (Popout page)"
function UI.ClickText(e)
    local label = {}
    for _, c in ipairs(POPOUT_CLICKS) do label[c.key] = c.label end
    local own = OwnPopoutClick(e)
    return "Clicking an item: " .. label[PopoutClick(e)] .. (own and " (set by you)" or " (Popout page)")
end

-- "Popout: opens up (Automatic)", "Popout: opens left (set by you)"
function UI.DirText(e)
    local dir, auto = UI.DirShown(e)
    if auto and not dir then return "Popout: Automatic (toward the middle of the screen)" end
    return "Popout: opens " .. UI.DIR_NAMES[dir] .. (auto and " (Automatic)" or " (set by you)")
end

-- On an icon of the Buttons page: a tab on the edge its popout opens from, as
-- on your bars (in the popout indicator's color), a little fainter while it is
-- on Automatic (the tooltip says which).
function UI.DirMark(b, e, size)
    if not b.dirTab then
        b.dirTab = b:CreateTexture(nil, "OVERLAY", nil, 7)
        if b.dirTab.SetIgnoreParentAlpha then pcall(b.dirTab.SetIgnoreParentAlpha, b.dirTab, true) end
    end
    local dir, auto = UI.DirShown(e)
    local t = b.dirTab
    t:ClearAllPoints()
    if not dir then t:Hide() return end
    local c = StyleColor("tabColor")
    t:SetColorTexture(c[1], c[2], c[3], auto and 0.6 or 1)
    local len, thick = math.floor(size * 0.5), 3
    local point = { up = "TOP", down = "BOTTOM", left = "LEFT", right = "RIGHT" }
    t:SetPoint(point[dir], b, point[dir], 0, 0)
    if dir == "up" or dir == "down" then t:SetSize(len, thick) else t:SetSize(thick, len) end
    t:Show()
end

-- Buttons: every button's icon, grey when it is off; clicking one turns it on or
-- off, right-clicking changes which way its popout opens. Last a + to make a button of your own (drop an item or spell on it);
-- dropping one on your own button's icon adds it there.
UI.HEADERS.buttons = function(f, width)
    local size, gap = 36, 6
    local list = UI.AvailableButtons()
    local perRow = math.max(1, math.floor((width - 40 + gap) / (size + gap)))
    local slots = #list + 1   -- (the + takes a place in the row too)
    local rows = math.ceil(slots / perRow)
    local function place(b, i)
        local row, col = math.floor((i - 1) / perRow), (i - 1) % perRow
        local inRow = (row == rows - 1) and (slots - row * perRow) or perRow
        local left = (width - (inRow * (size + gap) - gap)) / 2
        BLIZZ_ART.Point(b, "TOPLEFT", f, "TOPLEFT", left + col * (size + gap), -16 - row * (size + gap))
    end
    f.icons = f.icons or {}
    for i, e in ipairs(list) do
        local b = f.icons[i]
        if not b then
            b = UI.SampleButton(f, size)
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:SetScript("OnClick", function(self, button)
                if button == "RightButton" and IsShiftKeyDown() then   -- what clicking an item does
                    NextPopoutClick(self.entry)
                    if GameTooltip:GetOwner() == self then self:GetScript("OnEnter")(self) end   -- (its line)
                    return
                end
                if button == "RightButton" then   -- the next popout direction
                    POPOUT.Next(self.entry)
                    Refresh()          -- (the tabs on your bars move)
                    RefreshHeaders()
                    if GameTooltip:GetOwner() == self then self:GetScript("OnEnter")(self) end   -- (its Popout line)
                    return
                end
                if self.entry.custom and UI.CursorThing() then return UI.AddToIcon(self) end
                UI.SetEnabled(self.entry, not Enabled(self.entry))
            end)
            b:SetScript("OnReceiveDrag", function(self) UI.AddToIcon(self) end)
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
                GameTooltip:AddLine(UI.DirText(self.entry), 1, 1, 1)
                GameTooltip:AddLine(UI.ClickText(self.entry), 1, 1, 1)
                GameTooltip:AddLine("Drag onto an action bar to place it", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("Right-click to change which way its popout opens", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("Shift+right-click to change what clicking an item does", 0.7, 0.7, 0.7)
                if self.entry.custom then
                    GameTooltip:AddLine("Drop an item or spell on it to add it", 0.7, 0.7, 0.7)
                end
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            f.icons[i] = b
        end
        b.entry = e
        b.icon:SetTexture(UI.CategoryIcon(e))
        UI.StyleSample(b)   -- (sizes it, so before placing)
        place(b, i)
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
        UI.DirMark(b, e, size)
        b:Show()
    end
    for i = #list + 1, #f.icons do f.icons[i]:Hide() end
    if not f.newSlot then
        f.newSlot = UI.DropSlot(f, size, function(kind, id) UI.CustomCreate(kind, id) end, UI.NEW_BUTTON_TIP,
            function() UI.ShowDrop(nil) end)
    end
    UI.StyleSample(f.newSlot)
    place(f.newSlot, slots)
    f.newSlot:Show()
    f.hint = f.hint or UI.SmallText(f, "Click an icon to turn it on or off for this character, or drag it onto an action bar. Right-click to change which way its popout opens (the tab on its edge shows it), Shift+right-click what clicking an item in it does. The green number is how many you have or can make. A glowing icon has items but isn't on any of your bars yet.")
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

-- What the Popout page's demo shows: the button picked under Per-Button
-- Overrides (its popout as it is now: items, counts, the one in use), or with
-- "Example" picked a made-up one. Returns the list of { icon, count, selected }
-- and the button's icon.
UI.DEMO_ITEMS = { 929, 1710, 3928 }   -- (healing potions)

function UI.DemoPopout()
    local e = UI.PopoutEntry()
    local list = e and flyoutItems[e.name]
    if e and type(list) == "table" and #list > 0 then
        local _, chosenEntry = ChosenFor(e, list)
        -- (Use only marks none, as the real popout)
        local chosen = PopoutClick(e) ~= "use" and chosenEntry and (chosenEntry.pick or chosenEntry.id)
        local shown, icon = {}, nil
        for i = 1, math.min(#list, 10) do
            local it = list[i]
            local isSpell = e.kind == "spells" or it.spell == true
            local count = (not isSpell) and CountOf(it.id) or nil
            local s = { icon = it.macroIcon or (isSpell and SpellIcon(it.id) or IconFor({ item = it.id })),
                count = (count and count > 1) and tostring(count) or "",
                selected = chosen ~= nil and (it.pick or it.id) == chosen and e.kind ~= "icons" }
            shown[i] = s
            if s.selected or not icon then icon = s.icon end
        end
        return shown, icon
    end
    local shown = {}
    for i, id in ipairs(UI.DEMO_ITEMS) do
        shown[i] = { icon = IconFor({ item = id }), count = i == 1 and "5" or "", selected = i == 1 }
    end
    return shown, shown[1].icon
end

-- Flyout: a button with its tab and an open popup drawn with the current look
-- (the picked button's own size and spacing, see UI.DemoPopout).
UI.HEADERS.flyout = function(f, width)
    if not f.btn then
        f.btn = UI.SampleButton(f, 40, IconFor({ item = UI.DEMO_ITEMS[1] }))
        local a = ArrowFor(f.btn)
        if a then a:Show() end
        f.arrow = a
        local pop = CreateFrame("Frame", nil, f)
        pop.items = {}
        f.pop = pop
        f.hint = UI.SmallText(f, UI.FLYOUT_NOTE)
    end
    local e = UI.PopoutEntry()
    BLIZZ_ART.scaleFor, BLIZZ_ART.gapFor = PopoutSize(e), PopoutGap(e)
    BLIZZ_ART.hoverFor = e and ("entryHover_" .. e.key)
    local ok, h = pcall(UI.LayoutDemo, f, width)
    BLIZZ_ART.scaleFor, BLIZZ_ART.gapFor, BLIZZ_ART.hoverFor = nil, nil, nil
    if not ok then error(h, 0) end
    return h
end

function UI.LayoutDemo(f, width)
    local shown, btnIcon = UI.DemoPopout()
    local pop = f.pop
    for i, s in ipairs(shown) do
        local e = pop.items[i]
        if not e then
            e = ItemButton(pop)
            pop.items[i] = e
        end
        e.icon:SetTexture(s.icon)
        e.count:SetText(s.count)
        e.selected = s.selected
        e:Show()
    end
    for i = #shown + 1, #pop.items do pop.items[i]:Hide() end
    if f.btn.icon and btnIcon then f.btn.icon:SetTexture(btnIcon) end
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
    for i = 1, #shown do StyleEntry(pop.items[i]) end
    LayoutFlyout(pop, pop.items, #shown, f.btn, f.arrow)   -- same layout as the real popup
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
