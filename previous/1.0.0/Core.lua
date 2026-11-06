-- AutoMacros 1.0.0 for WoW Forever, Classic Era, TBC Anniversary, MoP Classic and
-- retail (Midnight); one addon for all of them, see the .toc's Interface line.
-- Keeps one macro per category pointed at the best matching item in your bags,
-- so the macro can be dragged onto any action bar. Macros are only rewritten
-- out of combat. There are no built-in item lists: items are sorted by what the
-- game says about them (Learning.lua) and the result is saved.
--
-- The addon is split over the files the .toc lists, loaded in that order. They
-- share one table (the addon's own, ns): a name set at a file's top level, like
-- `function Update()` or `MACROS = {}`, is seen by every file; `local` is for
-- what only one file or function uses. The game's own functions come from _G.
-- This file: shared data and helpers: spell and item lists, saved data, style
-- values, colours, the buttons (CATALOG), on/off per character, chat output.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- The game's functions that hand back an object (C_ClassColor.GetClassColor
-- gives a color) look up its mixin by name in the calling code's environment
-- without falling back to _G: "unable to find mixin or metatable (ColorMixin)"
-- (0.104.1, Class color mode). So the game's mixins are copied in, once.
for name, value in pairs(_G) do
    if type(name) == "string" and type(value) == "table" and name:sub(-5) == "Mixin" then rawset(ns, name, value) end
end

DATA = {}   -- item lists of your own categories (/amac custom), set name -> { [id] = true }

function ToSet(list)
    local set = {}
    for _, id in ipairs(list) do set[id] = true end
    return set
end

HEARTHSTONE = 6948
-- The spell and item ID lists that differ between games (TRAVEL_SPELLS,
-- PROFESSION_SPELLS, TRACKING_SPELLS, PORTAL_SPELLS, HS_RANK, CREATE_HS,
-- MANA_GEM_RANK, CONJURE_GEM, WATER_RANK, CONJURE_WATER, FOOD_RANK,
-- CONJURE_FOOD) are in Games\<game>\Lists.lua; only the running game's file
-- sets them (Game.lua).

-- What a button can make for you, and so makes when you carry none:
-- healthstones (Warlock), mana gems and conjured water and food (Mage).
-- rightClick: a right-click on the button always makes more.
MADE = {
    hpot = { rank = HS_RANK, spells = CREATE_HS },
    mpot = { rank = MANA_GEM_RANK, spells = CONJURE_GEM },
    water = WATER_RANK and { rank = WATER_RANK, spells = CONJURE_WATER, rightClick = true } or nil,
    food = FOOD_RANK and { rank = FOOD_RANK, spells = CONJURE_FOOD, rightClick = true } or nil,
}

QUESTION_MARK = 134400

-- this AutoMacros's version, from its .toc ("0.139.0"), or nil
function AddonVersion()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if not meta then return nil end
    local ok, v = pcall(meta, ADDON, "Version")
    return ok and type(v) == "string" and v ~= "" and v or nil
end

-- false for a "secret" value: retail (12.0+) may hand addons text or numbers
-- they can't read, compare or use as a table key (tooltip lines, in combat
-- say). Older clients have no such values.
function Readable(v)
    if issecretvalue and issecretvalue(v) then return false end
    return true
end

-- Shown text is written in US English; a British English (enGB) client gets
-- the British spelling instead.
function Loc(s)
    if type(s) == "string" and GetLocale and GetLocale() == "enGB" then
        s = s:gsub("([Cc])olor", "%1olour")
    end
    return s
end

function DB()
    _G.AutoMacrosDB = _G.AutoMacrosDB or {}   -- (the real global: the game saves it)
    return _G.AutoMacrosDB
end

function CharKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "?")
end

-- What you picked in a flyout is remembered per character, since the shared
-- (general) macros show different items on every character.
function Picks()
    local db = DB()
    db.picks = db.picks or {}
    local key = CharKey()
    db.picks[key] = db.picks[key] or {}
    return db.picks[key]
end

-- The macro slot each button's macro was last found at, per character (macro
-- name -> index). Wiped after a macro is deleted, as the slots after it move up.
function MacroSlots()
    local db = DB()
    if type(db.idx) ~= "table" then db.idx = {} end
    local key = CharKey()
    if type(db.idx[key]) ~= "table" then db.idx[key] = {} end
    return db.idx[key]
end

-- Which buttons are on, per character (button key -> true / false; nil = not
-- set yet, see Enabled). Before 0.89.0 it was one list for the whole account
-- (db.enabled): the first time this runs it is copied to every character the
-- addon knows (from idx and picks), then dropped.
function OnOff()
    local db = DB()
    if type(db.enabledBy) ~= "table" then db.enabledBy = {} end
    if type(db.enabled) == "table" then
        local chars = { [CharKey()] = true }
        for _, t in ipairs({ db.idx, db.picks }) do
            if type(t) == "table" then for k in pairs(t) do chars[k] = true end end
        end
        for k in pairs(chars) do
            if type(db.enabledBy[k]) ~= "table" then
                local copy = {}
                for key, v in pairs(db.enabled) do copy[key] = v end
                db.enabledBy[k] = copy
            end
        end
        db.enabled = nil
    end
    local key = CharKey()
    if type(db.enabledBy[key]) ~= "table" then db.enabledBy[key] = {} end
    return db.enabledBy[key]
end

-- ---------------------------------------------------------------------------
-- Saved data. AutoMacrosDB is the saved-variables table. The game fills it in
-- after this file has run, so it is always read through DB() and never kept in
-- a local. Layout:
--   schema            data version (see Init)
--   sessions          how many times this data has been loaded (/amac status)
--   style             look and feel, shared by all characters (only changed values)
--   idx / picks       macro slot and flyout choice, per character
--   enabledBy         which categories are on, per character (was enabled, account-wide)
--   custom            your own categories
--   learned           items sorted into categories, by the addon or by hand
--   recipes           per character: what its known recipes make and need (UI.ScanRecipes)
--   ignored           consumables checked and found to belong nowhere (see LearnNew)
--   glow, noFlyout, stockTooltip, showNames, quiet, noEmptyMsg   on/off options
--   noComboFallback   Food / Water do not borrow Food & Drink items when out (0.136.0)
-- ---------------------------------------------------------------------------
SCHEMA = 2
CLASSIFIER = 21 -- raise when the learning rules change, so items are checked again

STYLE_DEFAULTS = {
    glowColor = { 1, 0.15, 0.15, 1 }, glowThickness = 3, glowTexture = "solid",
    glowPulse = true, glowSpeed = 0.7,
    tabColor = { 1, 0.82, 0, 0.95 },
    tabWidth = 18, tabHeight = 3, tabTexture = "solid",
    flyoutArt = true,   -- the popup's background: Blizzard's action bar art
    entrySpacing = 2, itemScale = 100,   -- itemScale: Item size in percent, like Edit Mode's Icon Size
    selectedSize = 2, selectedColor = { 1, 0.82, 0, 1 },
    -- entryHover (the hover color) follows your action bars: set below EUIButtonLook
    closeDelay = 0.3,
    tooltipColor = { 1, 0.3, 0.3, 1 },
    euiSkin = true,
}

function Style(key)
    local s = DB().style
    local v
    if type(s) == "table" then v = s[key] end   -- (a false value must survive, so no "and/or" here)
    if v == nil then v = STYLE_DEFAULTS[key] end
    if type(v) == "function" then v = v() end   -- a default worked out when asked (entryHover)
    return v
end

-- EllesmereUI styling. skin is the table EllesmereUI hands to RegisterSkin; it
-- stays nil when EllesmereUI is not installed or skinning is off for this addon.
-- (skin)
-- (ApplyStyle: defined with the flyout code)

function SkinActive()
    return skin ~= nil and Style("euiSkin") ~= false
end

-- EllesmereUI's accent colour: its custom or class colour, whichever is chosen
-- in its Global Settings. nil when EllesmereUI is not loaded. The skin hands it
-- over when skinning is on; otherwise it is read from EllesmereUI directly.
function EUIAccent()
    if skin and skin.GetAccentColor then
        local ok, r, g, b = pcall(skin.GetAccentColor)
        if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then return r, g, b end
    end
    local c = EllesmereUI and EllesmereUI.ELLESMERE_GREEN
    if type(c) == "table" and type(c.r) == "number" and type(c.g) == "number" and type(c.b) == "number" then
        return c.r, c.g, c.b
    end
    return nil
end

function AccentRGB()
    local r, g, b = EUIAccent()
    if r then return r, g, b end
    return 1, 0.82, 0
end

-- Every colour setting has a mode, saved as style[<key>Mode]:
--   default  the built-in colour (STYLE_DEFAULTS)
--   accent   EllesmereUI's accent colour (falls back to default without it)
--   custom   picked by hand, saved as style[<key>]
--   class    the logged-in character's class color
-- Opacity is shared by all of them and comes from style[<key>] or the default.
COLOR_MODES = {
    { key = "default", label = "Default" },
    { key = "accent", label = "EllesmereUI accent" },
    { key = "custom", label = "Custom" },
    { key = "class", label = "Class" },
}

function ColorMode(key)
    local s = DB().style
    local m = type(s) == "table" and s[key .. "Mode"] or nil
    -- EllesmereUI accent without EllesmereUI: drawn as Default, so it reads
    -- Default too (the dropdown has no accent choice then, and showed nothing);
    -- the saved choice stays for when EllesmereUI is back
    if m == "accent" and not EUIAccent() then return "default" end
    if m then return m end
    if type(s) == "table" and s[key] ~= nil then return "custom" end   -- picked before modes existed
    return "default"
end

function ColorModeChoices()
    local list = {}
    for _, m in ipairs(COLOR_MODES) do
        if m.key ~= "accent" or EUIAccent() then list[#list + 1] = m end
    end
    return list
end

-- the colour actually drawn for a colour setting, as { r, g, b, a }
function StyleColor(key)
    local c = Style(key)
    local mode = ColorMode(key)
    if mode == "accent" then
        local r, g, b = EUIAccent()
        if r then return { r, g, b, c[4] or 1 } end
    elseif mode == "class" then
        local _, class = UnitClass("player")
        local cc
        if class and C_ClassColor and C_ClassColor.GetClassColor then
            local ok, r = pcall(C_ClassColor.GetClassColor, class)
            if ok then cc = r end
        end
        cc = cc or (class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
        if cc then return { cc.r, cc.g, cc.b, c[4] or 1 } end
    end
    if mode ~= "custom" then
        local d = STYLE_DEFAULTS[key]
        if type(d) == "function" then d = d() end   -- worked out when asked (entryHover)
        return { d[1], d[2], d[3], c[4] or d[4] or 1 }
    end
    return c
end

function SetStyle(key, value)
    local db = DB()
    if type(db.style) ~= "table" then db.style = {} end
    if type(value) == "table" then value = { value[1], value[2], value[3], value[4] } end
    db.style[key] = value
    if ApplyStyle then ApplyStyle() end
end

-- Saves the mode a colour has now, so that saving its value (opacity, say)
-- does not turn it into a custom colour.
function PinMode(key)
    local s = DB().style
    if type(s) ~= "table" or s[key .. "Mode"] == nil then SetStyle(key .. "Mode", ColorMode(key)) end
end

-- Saves a picked colour. It becomes the custom colour, unless only the opacity
-- changed (or a picker was cancelled), which keeps the mode as it was.
function SetColor(key, r, g, b, a)
    PinMode(key)
    local c = Style(key)
    local same = math.abs(c[1] - r) < 0.002 and math.abs(c[2] - g) < 0.002 and math.abs(c[3] - b) < 0.002
    SetStyle(key, { r, g, b, a or c[4] or 1 })
    if not same then SetStyle(key .. "Mode", "custom") end
end

function ResetStyle()
    DB().style = nil
    if ApplyStyle then ApplyStyle() end
end

-- Textures for borders and tabs. "solid" is a plain colour; the others are
-- picture files tinted with the colour. LibSharedMedia status bars are offered
-- too when that library is loaded.
TEXTURES = {
    { key = "solid", label = Loc("Solid color") },
    { key = "glow", label = "Soft glow", glow = true },   -- drawn by StyleGlow (Blizzard's item-border glow)
    { key = "bar", label = "Status bar", path = "Interface\\TargetingFrame\\UI-StatusBar" },
}

-- forGlow: the highlight's choices, solid or soft glow (a picture border makes
-- no sense there); otherwise the flyout indicator's, every texture but the glow
function TextureChoices(forGlow)
    if forGlow then return { TEXTURES[1], TEXTURES[2] } end
    local list = {}
    for _, t in ipairs(TEXTURES) do
        if not t.glow then list[#list + 1] = t end
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.HashTable then
        local ok, tbl = pcall(LSM.HashTable, LSM, "statusbar")
        if ok and type(tbl) == "table" then
            local names = {}
            for n in pairs(tbl) do names[#names + 1] = n end
            table.sort(names)
            for _, n in ipairs(names) do list[#list + 1] = { key = "lsm:" .. n, label = n, path = tbl[n] } end
        end
    end
    return list
end

function TextureInfo(key)
    for _, t in ipairs(TEXTURES) do
        if t.key == key then return t end
    end
    local name = type(key) == "string" and key:match("^lsm:(.+)$")
    if name then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM and LSM.Fetch then
            local ok, path = pcall(LSM.Fetch, LSM, "statusbar", name, true)
            if ok and path then return { key = key, path = path } end
        end
    end
    return TEXTURES[1]
end

function Paint(tex, key, c)
    local info = TextureInfo(key)
    c = c or { 1, 1, 1, 1 }
    if info.path and not info.glow then
        pcall(tex.SetTexture, tex, info.path)
        pcall(tex.SetVertexColor, tex, c[1], c[2], c[3], c[4] or 1)
    else
        pcall(tex.SetVertexColor, tex, 1, 1, 1, 1)
        tex:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    end
end

-- four textures drawn as a rectangle border just inside a frame
function MakeEdges(frame, layer)
    local e = {}
    for i = 1, 4 do e[i] = frame:CreateTexture(nil, layer or "OVERLAY") end
    return e
end

-- One physical screen pixel in frame's own units. Sizes the player sets as
-- pixels (borders, spacing, the flyout indicator) go through this, so a 1 is
-- exactly one pixel whatever the UI scale.
function PixelSize(frame)
    local h
    if GetPhysicalScreenSize then
        local ok, _, ph = pcall(GetPhysicalScreenSize)
        if ok then h = ph end
    end
    if type(h) ~= "number" or h <= 0 then return 1 end
    local s = frame and frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    if type(s) ~= "number" or s <= 0 then s = 1 end
    return 768 / h / s
end

-- v (in frame's units) rounded to whole screen pixels
function Snap(frame, v)
    local px = PixelSize(frame)
    return math.floor(v / px + 0.5) * px
end

-- v in UI units (the units EllesmereUI's Icon Size and the action bars use),
-- in frame's own units and on whole pixels. Sizes that go with the button (item
-- size, indicator width) use these; thicknesses are screen pixels.
function BarUnits(frame, v)
    local s = frame and frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    local u = UIParent and UIParent:GetEffectiveScale() or 1
    if type(s) ~= "number" or s <= 0 then s = 1 end
    return Snap(frame, v * u / s)
end

-- the four edge textures as a border t screen pixels thick
function PlaceEdges(e, frame, t)
    if not t or t <= 0 then
        for i = 1, 4 do e[i]:Hide() end
        return
    end
    t = t * PixelSize(frame)
    for i = 1, 4 do e[i]:ClearAllPoints(); e[i]:Show() end
    e[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    e[1]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    e[1]:SetHeight(t)
    e[2]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    e[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    e[2]:SetHeight(t)
    e[3]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -t)
    e[3]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, t)
    e[3]:SetWidth(t)
    e[4]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -t)
    e[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, t)
    e[4]:SetWidth(t)
end

-- Items sorted into categories: db.learned (see "Learning new items" below),
-- plus DATA for your own categories.
learnedIdx = {}   -- set name -> { [itemID] = true }

-- ---- the one Buffs button ----
-- Per character (db.oneBuff[char]): one Buffs button instead of the stat,
-- armor, resistance and other-buff buttons. It takes the stats the character
-- chose (db.buffStats[char] = { intellect = true, ... }), else its class's.
BUFF_STATS = { "agility", "intellect", "spirit", "stamina", "strength" }
CLASS_BUFF_STATS = {
    MAGE = { "intellect", "spirit", "stamina" },
    WARLOCK = { "intellect", "spirit", "stamina" },
    PRIEST = { "intellect", "spirit", "stamina" },
    WARRIOR = { "strength", "agility", "stamina" },
    ROGUE = { "strength", "agility", "stamina" },
    HUNTER = { "agility", "intellect", "stamina" },
    PALADIN = BUFF_STATS, SHAMAN = BUFF_STATS, DRUID = BUFF_STATS,   -- (either kind)
    DEATHKNIGHT = { "strength", "stamina" },
    DEMONHUNTER = { "agility", "stamina" },
    MONK = { "agility", "stamina" },
    EVOKER = { "intellect", "stamina" },
}

function OneBuff()
    local t = DB().oneBuff
    return type(t) == "table" and t[CharKey()] == true
end

-- Every kind of buff the Buffs button can take, in the order of its
-- checkboxes (a part p is the set buff_<p>, and the separate button with that
-- part). Besides its stats, every class starts with armor, resistance, haste
-- and other buffs; spell power only the classes that cast (SPELL_CLASSES).
BUFF_PARTS = { "agility", "intellect", "spirit", "stamina", "strength",
    "armor", "resistance", "haste", "spellpower", "other" }
SPELL_CLASSES = { MAGE = true, WARLOCK = true, PRIEST = true, PALADIN = true, SHAMAN = true,
    DRUID = true, EVOKER = true }

-- the parts the Buffs button takes for this character: { part = true }. The
-- class's start, then what this character ticked or unticked
-- (db.buffStats[char][part] = true / false).
function BuffParts()
    local _, class = UnitClass("player")
    local out = {}
    for _, s in ipairs(CLASS_BUFF_STATS[class] or BUFF_STATS) do out[s] = true end
    out.armor, out.resistance, out.haste, out.other = true, true, true, true
    if SPELL_CLASSES[class] then out.spellpower = true end
    local t = DB().buffStats
    local mine = type(t) == "table" and t[CharKey()]
    if type(mine) == "table" then
        for part, on in pairs(mine) do out[part] = on and true or nil end
    end
    return out
end

-- not offered while the other kind of buff button is in use
function HiddenButton(e)
    if e.buffPart then return OneBuff() end
    if e.oneBuff then return not OneBuff() end
    return false
end

function InSet(setName, id)
    if setName == "buff_class" then   -- the Buffs button: every part this character takes
        for part in pairs(BuffParts()) do
            if InSet("buff_" .. part, id) then return true end
        end
        return false
    end
    local set = DATA[setName]
    if set and set[id] then return true end
    local made = MADE[setName]   -- healthstones and mana gems, whatever learning made of them
    if made and made.rank[id] then return true end
    local l = learnedIdx[setName]
    return l ~= nil and l[id] == true
end

function RebuildLearned()
    for k in pairs(learnedIdx) do learnedIdx[k] = nil end
    local learned = DB().learned
    if type(learned) ~= "table" then return end
    for id, rec in pairs(learned) do
        if type(rec) == "table" and type(rec.sets) == "table" then
            -- an item on both Food and Water (sorted by hand, or saved before
            -- 0.136.0) restores health and mana: it is Food & Drink's
            local food, water = false, false
            for _, s in ipairs(rec.sets) do
                if s == "food" then food = true elseif s == "water" then water = true end
            end
            for _, s in ipairs(rec.sets) do
                if food and water and (s == "food" or s == "water") then s = "combo" end
                learnedIdx[s] = learnedIdx[s] or {}
                learnedIdx[s][id] = true
            end
        end
    end
end

-- Every button the addon can make. A button only exists once its category is
-- switched on (/amac add <key>, the settings, or by itself the first time you
-- carry its items: see Enabled and AutoEnable).
--   scope "character": goes in the character-specific macro tab (class buttons)
--   scope "general":   goes in the general macro tab, shared by all characters
--                      (the addon rewrites it for whoever is logged in)
--   name:   the id used in saved data; title / empty: the macro name when it has
--           an item / when it is empty (16 characters at most)
--   placeholder: the icon shown when nothing is in your bags, { item = <itemID> }
--           for an item's icon or { icon = <iconFileID> } (1339440 is a red X)
CATALOG = {
    -- Anything that restores health / mana: potions, healthstones, mana gems,
    -- runes, Whipper Root Tuber, ... (Rejuvenation Potions are on both). A
    -- Warlock / Mage who carries no healthstone / mana gem makes one (see MADE).
    -- Were Health Potion + Healthstone and Mana Potion until 0.95.0: the potion
    -- macros carry on (renamed), the Healthstone one is deleted.
    { key = "healthpot", alias = "healthstone", name = "AM_HealthPot", title = "Restore Health", empty = "No Health Items",
      label = "health potions or stones", set = "hpot", oldNames = { "Health Potion", "No Health Potion" },
      default = true, placeholder = { item = 3371 } },   -- Empty Vial
    { key = "manapot", name = "AM_ManaPot", title = "Restore Mana", empty = "No Mana Items",
      label = "mana potions or gems", set = "mpot", oldNames = { "Mana Potion", "No Mana Potion" },
      default = true, placeholder = { item = 3371 } },
    { key = "food", name = "AM_Food", title = "Food", empty = "No Food", label = "food", set = "food", default = true,
      placeholder = { item = 4540 } },   -- Tough Hunk of Bread
    { key = "water", name = "AM_Water", title = "Water", empty = "No Water", label = "water", set = "water", default = true,
      placeholder = { item = 159 } },    -- Refreshing Spring Water
    -- food and drink in one, restores health and mana while you sit (Enriched
    -- Manna Biscuit, ...): its own button, never on Food or Water, except that
    -- when you carry no food (water) those buttons use it instead (the fallback,
    -- on unless noComboFallback; see UpdateCore). Since 0.136.0.
    { key = "combo", name = "AM_Combo", title = "Food & Drink", empty = "No Food & Drink", label = "food & drink",
      set = "combo", default = true, placeholder = { item = 13724 } },   -- Enriched Manna Biscuit
    { key = "comprehend", name = "AM_Scroll", title = "Comprehend", empty = "Comprehend", label = "scrolls",
      special = "scroll", class = "MAGE", scope = "character", default = true },
    -- spells: after the bandages, for whoever knows them (Undead: Cannibalize)
    { key = "bandage", name = "AM_Bandage", title = "Bandage", empty = "No Bandage", label = "bandages",
      set = "bandage", spells = { 20577 }, placeholder = { item = 1251 } },
    -- Anything whose "Use:" cures or removes a debuff: poison, disease, bleeding,
    -- curse, magic, stuns and snares. Potions, First Aid's Anti-Venom, poultices
    -- and tourniquets (Forever), quest rewards like Jungle Remedy. Was the
    -- Anti-Venom button (same macro, renamed; 0.97.0 briefly had separate
    -- disease and bleed buttons too).
    { key = "cure", alias = "antivenom", name = "AM_AntiVenom", title = "Debuff Cure", empty = "No Debuff Cure",
      label = "debuff cures", set = "cure",
      oldNames = { "Anti-Venom", "No Anti-Venom", "Disease Cure", "No Disease Cure", "Bleed Cure", "No Bleed Cure" },
      placeholder = { item = 9030 } },   -- Restorative Potion
    -- One button per buff, whatever the item is (elixir, scroll, potion, Juju,
    -- E'ko, Blasted Lands quest rewards, ...). Until 0.92.0 scrolls and elixirs
    -- had a button each; the elixir buttons' macros carry on as these (same
    -- saved name, renamed: oldNames), the scroll buttons' are deleted (see
    -- UI.MergeBuffButtons).
    -- buffPart: hidden while the character uses the one Buffs button instead
    -- (OneBuff, see below); part: its checkbox there (BUFF_PARTS, set buff_<part>)
    { key = "agility", alias = "agielixir", name = "AM_ElxAgi", title = "Agility Buff", empty = "No Agi Buff",
      label = "agility buffs", set = "buff_agility", oldNames = { "Agility Elixir", "No Agi Elixir" },
      buffPart = true, part = "agility", placeholder = { item = 2457 } },
    { key = "intellect", alias = "intelixir", name = "AM_ElxInt", title = "Intellect Buff", empty = "No Int Buff",
      label = "intellect buffs", set = "buff_intellect", oldNames = { "Intellect Elixir", "No Int Elixir" },
      buffPart = true, part = "intellect", placeholder = { item = 3383 } },
    { key = "stamina", alias = "staelixir", name = "AM_ElxSta", title = "Stamina Buff", empty = "No Sta Buff",
      label = "stamina buffs", set = "buff_stamina", oldNames = { "Stamina Elixir", "No Sta Elixir" },
      buffPart = true, part = "stamina", placeholder = { item = 13453 } },
    { key = "strength", alias = "strelixir", name = "AM_ElxStr", title = "Strength Buff", empty = "No Str Buff",
      label = "strength buffs", set = "buff_strength", oldNames = { "Strength Elixir", "No Str Elixir" },
      buffPart = true, part = "strength", placeholder = { item = 2454 } },
    { key = "spirit", name = "AM_Spirit", title = "Spirit Buff", empty = "No Spirit Buff", label = "spirit buffs",
      set = "buff_spirit", buffPart = true, part = "spirit", placeholder = { item = 1181 } },   -- Scroll of Spirit
    -- raises Armor or Defense (Scroll of Protection, Elixirs of Defense). Was
    -- "Protection" in 0.92.0, with the resistance items in it too.
    { key = "armor", alias = "protection", name = "AM_Protection", title = "Armor Buff", empty = "No Armor Buff",
      label = "armor buffs", set = "buff_armor", oldNames = { "Protection", "No Protection" },
      buffPart = true, part = "armor", placeholder = { item = 3013 } },   -- Scroll of Protection
    -- raises a resistance, or absorbs one school's damage (the Fire, Frost,
    -- Nature, Shadow, Arcane and Holy Protection Potions)
    { key = "resistance", name = "AM_Resist", title = "Resistance", empty = "No Resistance",
      label = "resistance", set = "buff_resistance", buffPart = true, part = "resistance",
      placeholder = { item = 6049 } },   -- Fire Protection Potion
    -- raises spell damage or healing (Greater Arcane Elixir, Shadow Power,
    -- Firepower), and haste (attack or casting speed): own buttons since
    -- 0.139.0, they were Other Buffs before
    { key = "spellpower", name = "AM_SpellPower", title = "Spell Power", empty = "No Spell Power",
      label = "spell power buffs", set = "buff_spellpower", buffPart = true, part = "spellpower",
      placeholder = { item = 13454 } },   -- Greater Arcane Elixir
    { key = "haste", name = "AM_Haste", title = "Haste Buff", empty = "No Haste Buff", label = "haste buffs",
      set = "buff_haste", buffPart = true, part = "haste", placeholder = { item = 2459 } },   -- Swiftness Potion
    -- movement, immunity and escapes (Swiftness, Free Action, invisibility, water
    -- breathing): not a buff kind, so never on the one Buffs button
    { key = "utility", name = "AM_Utility", title = "Utility Buff", empty = "No Utility Buff",
      label = "utility buffs", set = "buff_utility", placeholder = { item = 5634 } },   -- Free Action Potion
    -- used on an enemy: nets, glue, Bag of Marbles, Magic Dust, Glowing Wax Stick
    { key = "enemydebuff", name = "AM_EnemyDebuff", title = "Enemy Debuff", empty = "No Enemy Debuff",
      label = "enemy debuff items", set = "enemy_debuff", placeholder = { item = 835 } },   -- Large Rope Net
    -- anything else a "Use:" line raises: attack power, crit, ...
    { key = "otherbuff", name = "AM_OtherBuff", title = "Other Buffs", empty = "No Other Buffs", label = "other buffs",
      set = "buff_other", buffPart = true, part = "other", placeholder = { item = 12820 } },   -- Winterfall Firewater
    -- All of the above that suits this character, on one button, instead of
    -- them (only while OneBuff() is on): the parts it ticked (BuffParts).
    -- Character tab: what it holds is per character.
    { key = "buffs", name = "AM_Buffs", title = "Buffs", empty = "No Buffs", label = "buffs",
      set = "buff_class", oneBuff = true, scope = "character", placeholder = { item = 2458 } },
    { key = "explosives", name = "AM_Explosive", title = "Explosive", empty = "No Explosives", label = "explosives",
      set = "explosives", placeholder = { item = 4358 } },
    { key = "ragepot", name = "AM_RagePot", title = "Rage Potion", empty = "No Rage Potion", label = "rage potions",
      set = "rage", placeholder = { item = 5631 } },
    { key = "bufffood", name = "AM_BuffFood", title = "Buff Food", empty = "No Buff Food", label = "buff food",
      set = "food_buff", placeholder = { item = 2680 } },
    { key = "flask", name = "AM_Flask", title = "Flask", empty = "No Flask", label = "flasks",
      set = "flask", placeholder = { item = 13510 } },
    -- weapon: the macro also applies it to the main hand (off hand with Shift)
    { key = "weaponbuff", name = "AM_WeaponBuff", title = "Weapon Buff", empty = "No Weapon Buff",
      label = "weapon stones or oils", set = "weapon_buff", weapon = true, placeholder = { item = 2862 } },
    -- One button for every class: hearth items and the class's teleport spells.
    -- It took over the mage-only Teleports button (same name in saved data, so
    -- that macro is kept); alias lets "/amac add teleports" still work.
    { key = "travel", alias = "teleports", name = "AM_Teleport", title = "Hearth/Teleport", empty = "No Hearthstone",
      label = "hearthstone or teleport", kind = "travel", set = "travel", spells = TRAVEL_SPELLS,
      oldNames = { "Teleports" }, placeholder = { item = HEARTHSTONE }, default = true },
    -- quest items you use to do the quest ("Use: Place the totem at ..."): a quest
    -- item, or one marked "Quest Item", with a "Use:" line and no other button
    { key = "questitem", name = "AM_QuestItem", title = "Quest Item", empty = "No Quest Item",
      label = "usable quest items", set = "quest", placeholder = { item = 1307 } },   -- Gold Pickup Schedule
    { key = "portals", name = "AM_Portal", title = "Portals", empty = "Portals", label = "portals",
      kind = "spells", spells = PORTAL_SPELLS, class = "MAGE", scope = "character" },
    -- every profession window you know (each at its highest rank); clicking one
    -- in the popout opens it. On by itself once you know one (autoSpells).
    { key = "professions", name = "AM_Profession", title = "Professions", empty = "Professions",
      label = "professions", kind = "spells", spells = PROFESSION_SPELLS, byName = true, autoSpells = true,
      scope = "character" },
    -- every tracking spell you know (your class's, your race's, gathering);
    -- clicking one in the popout switches to it. On by itself once you know one.
    -- tracking: the one switched on is always the button's (ChosenFor).
    { key = "tracking", name = "AM_Tracking", title = "Tracking", empty = "Tracking",
      label = "tracking", kind = "spells", spells = TRACKING_SPELLS, byName = true, autoSpells = true,
      tracking = true, scope = "character" },
}

MACROS = {}            -- the categories in use for this character (rebuilt by RebuildMacros)
ALL = {}               -- every category, built-in and custom, for /amac list
EMPTY_MESSAGE = {}     -- macro name when empty -> tooltip message

-- On or off as you set it on this character. Untouched, your own categories
-- and the mage scroll button are on; item buttons stay off until you first
-- carry their items (AutoEnable then switches them on for good).
function Enabled(e)
    if e.oneBuff then return OneBuff() end   -- (the Buffs button is on exactly while buffs are combined)
    local on = OnOff()
    if on[e.key] ~= nil then return on[e.key] end
    if e.custom or e.special == "scroll" then return e.default == true end
    return false
end

-- What a button of your own holds, in your order: { { kind = "item" | "spell",
-- id = n }, ... } (c.list). Before 0.112.0 a button held one kind only (c.kind
-- = items | spells, c.ids); those are turned into a list here, once, keeping
-- the macro tab they were in (spells went in the character tab).
function CustomThings(c)
    if type(c.list) ~= "table" then
        local kind = c.kind == "spells" and "spell" or "item"
        c.list = {}
        for _, id in ipairs(type(c.ids) == "table" and c.ids or {}) do c.list[#c.list + 1] = { kind = kind, id = id } end
        if kind == "spell" and not c.scope then c.scope = "character" end
        c.kind, c.ids = nil, nil
    end
    return c.list
end

-- Categories you made yourself (the Buttons page, /amac custom): kept in the saved data.
function CustomEntries()
    local list = {}
    local custom = DB().custom
    if type(custom) ~= "table" then return list end
    local keys = {}
    for k in pairs(custom) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local c = custom[k]
        local things = type(c) == "table" and CustomThings(c) or {}
        if #things > 0 then
            local title = tostring(c.title or k):sub(1, 16)
            -- order: its items and spells as you arranged them (UpdateCore goes by it);
            -- set and spells: the same split up, for counting and recognising its macro
            local e = {
                key = k, custom = true, name = "AM_C_" .. k, title = title,
                empty = ("No " .. title):sub(1, 16), label = tostring(c.title or k):lower(), default = true,
                oldNames = type(c.oldNames) == "table" and c.oldNames or nil,   -- (renamed on the Buttons page)
                order = things, set = "custom_" .. k, spells = {}, scope = c.scope,
            }
            local items = {}
            for _, t in ipairs(things) do
                if t.kind == "spell" then e.spells[#e.spells + 1] = t.id else items[#items + 1] = t.id end
            end
            DATA[e.set] = ToSet(items)
            if #e.spells == 0 then e.spells = nil end   -- (BodyMatches: only then does /cast count as ours)
            local first = things[1]
            e.placeholder = first.kind == "spell" and { icon = SpellIcon(first.id) } or { item = first.id }
            list[#list + 1] = e
        end
    end
    return list
end

function RebuildMacros()
    for i = #MACROS, 1, -1 do MACROS[i] = nil end
    for i = #ALL, 1, -1 do ALL[i] = nil end
    for k in pairs(EMPTY_MESSAGE) do EMPTY_MESSAGE[k] = nil end
    local _, class = UnitClass("player")
    -- (the stat buttons or the one Buffs button, whichever this character uses)
    for _, e in ipairs(CATALOG) do
        if not HiddenButton(e) then ALL[#ALL + 1] = e end
    end
    for _, e in ipairs(CustomEntries()) do ALL[#ALL + 1] = e end
    for _, e in ipairs(ALL) do
        if e.set then EMPTY_MESSAGE[e.empty] = "No " .. e.label .. " in inventory." end
        if Enabled(e) and (not e.class or e.class == class) then MACROS[#MACROS + 1] = e end
    end
end
pcall(RebuildMacros)

report = {}   -- last result per macro name, for /automacros

function Print(msg)
    print("|cff66ccffAutoMacros:|r " .. Loc(tostring(msg)))
end

-- What the addon tells you by itself (items learned, buttons turned on, macros
-- removed): hidden with General > Chat > "Show info messages" off (db.quiet).
-- Replies to /amac commands and problems you need to act on always use Print.
function Note(msg)
    if not DB().quiet then Print(msg) end
end

-- A failure in one part (button scan, highlight, flyout) is reported once and
-- never stops the rest of the addon.
-- (lastErrorText)
function Fail(where, err)
    err = tostring(err)
    report.lastError = where .. ": " .. err
    if err ~= lastErrorText then
        lastErrorText = err
        Print("error in " .. where .. ": " .. err)
    end
end
