-- AutoMacros 0.26.0 for WoW Forever (interface 16001)
-- Keeps one macro per category pointed at the best matching item in your bags,
-- so the macro can be dragged onto any action bar. Macros are only rewritten
-- out of combat. Item lists come from AutoBar's camelot data.

local ADDON = ...
local DATA = {}

local function ToSet(list)
    local set = {}
    for _, id in ipairs(list) do set[id] = true end
    return set
end

DATA.food = ToSet({
    117, 414, 422, 761, 961, 1113, 1114, 1119, 1165, 1321, 1326, 1487,
    1707, 2070, 2287, 2679, 3770, 3771, 3927, 4418, 4536, 4537, 4538, 4539,
    4540, 4541, 4542, 4544, 4599, 4601, 4602, 4604, 4605, 4606, 4607, 4608,
    4656, 5057, 5066, 5349, 5478, 5525, 5526, 5845, 6299, 6458, 6807, 7097,
    7228, 8075, 8076, 8543, 8932, 8948, 8950, 8952, 8953, 9681, 11109, 11415,
    11444, 12238, 12763, 13546, 13755, 13893, 16166, 16167, 16168, 16169, 16170, 16171,
    16766, 17119, 17344, 17406, 17407, 17408, 18255, 18632, 18633, 18635, 19223, 19224,
    19225, 19304, 19305, 19306, 21030, 21031, 21033, 21552, 22324, 22895, 23160, 249796,
    250081, 251917, 252022, 252023, 252026, 252028, 252029, 252030, 252032, 260623, 260624, 260625,
    260627, 260628, 267474, 278117, 278118, 278119, 278120, 278121, 278122, 278265, 278569,
})
DATA.water = ToSet({
    159, 1179, 1205, 1267, 1268, 1645, 1708, 2071, 2136, 2288, 3772, 3773,
    4791, 5350, 8077, 8078, 8079, 8766, 9451, 17404, 18300, 19299, 19300, 23161,
    227813, 231778, 252027, 252031, 285359,
})
DATA.hpot = ToSet({
    118, 858, 929, 1710, 3928, 4596, 13446, 17348, 17349, 18839, 22829, 23579,
    23822, 28100, 31676, 31838, 31839, 31852, 31853, 32763, 32784, 32904, 32905, 32910,
    32947, 33092, 33447, 33934, 39327, 39671, 39971, 41166, 43531, 43569, 45277, 57191,
    63144, 63300, 64994, 76097, 80040, 88416, 92954, 92979, 109223, 115498, 117415, 118916,
    118917, 127834, 129196, 136569, 138486, 140351, 142325, 144396, 152494, 152615, 156634, 167917,
    169451,
})
DATA.mpot = ToSet({
    2455, 3087, 3385, 3827, 6149, 13443, 13444, 17351, 17352, 18253, 18841, 22832,
    22850, 23578, 23823, 28101, 31677, 31840, 31841, 31854, 31855, 32762, 32783, 32902,
    32903, 32909, 32948, 33093, 33448, 33935, 34440, 35287, 40067, 40087, 42545, 43530,
    43570, 45276, 57192, 57193, 57194, 63145, 64993, 76092, 76098, 109221, 109222, 118262,
    118278, 127835, 127846, 140347, 152495, 152561, 168502,
})

DATA.bandage = ToSet({
    1251, 2581, 3530, 3531, 6450, 6451, 8544, 8545, 14529, 14530, 21990, 21991,
    34721, 34722, 53049, 53050, 53051, 72985, 72986, 111603, 133940, 133942, 136653, 142332,
    158381, 158382, 173191, 173192,
})
DATA.antivenom = ToSet({
    2633, 3386, 6452, 6453, 9030, 12586, 13462, 19440, 25550, 31437,
})
DATA.scroll_agility = ToSet({
    1477, 3012, 4425, 10309, 27498, 33457, 43463, 43464,
})
DATA.elixir_agility = ToSet({
    2457, 3390, 8412, 8949, 9187, 13452, 22831, 28104, 32598, 32599, 33208, 47499,
    58087, 58145, 58149, 65455, 75525, 76089, 118630,
})
DATA.scroll_intellect = ToSet({
    955, 2290, 4419, 10308, 12458, 27499, 33458, 37091, 37092,
})
DATA.elixir_intellect = ToSet({
    3383, 8423, 9179, 13447, 13511, 28104, 32067, 32596, 32600, 32601, 33208, 47499,
    58086, 58149, 65455, 75525, 76093, 118632,
})
DATA.scroll_stamina = ToSet({
    1180, 1711, 4422, 10307, 27502, 33461, 37093, 37094,
})
DATA.elixir_stamina = ToSet({
    13453, 17048, 20709, 21114, 21151, 28104, 30615, 32596, 32597, 32598, 32599, 32600,
    32601, 33208, 58085, 65455,
})
DATA.scroll_strength = ToSet({
    954, 2289, 4426, 10310, 12451, 27503, 33462, 43465, 43466,
})
DATA.elixir_strength = ToSet({
    2454, 3391, 6662, 8410, 9206, 13453, 22824, 22828, 22837, 28104, 32597, 32598,
    33208, 47499, 58088, 58146, 58149, 65455, 75525, 76095, 118631,
})

-- Healthstone ranks: 1 Minor, 2 Lesser, 3 Healthstone, 4 Greater, 5 Major.
-- Talent variants share the rank; the higher ID is the talented one.
local HS_RANK = {
    [5512] = 1, [19004] = 1, [19005] = 1,
    [5511] = 2, [19006] = 2, [19007] = 2,
    [5509] = 3, [19008] = 3, [19009] = 3,
    [5510] = 4, [19010] = 4, [19011] = 4,
    [9421] = 5, [19012] = 5, [19013] = 5,
}
-- Create Healthstone spells, best rank first.
local CREATE_HS = { 11730, 11729, 5699, 6202, 6201 }


local QUESTION_MARK = 134400

local function DB()
    AutoMacrosDB = AutoMacrosDB or {}
    return AutoMacrosDB
end

local function CharKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "?")
end

-- What you picked in a flyout is remembered per character, since the shared
-- (general) macros show different items on every character.
local function Picks()
    local db = DB()
    db.picks = db.picks or {}
    local key = CharKey()
    db.picks[key] = db.picks[key] or {}
    return db.picks[key]
end

-- ---------------------------------------------------------------------------
-- Saved data. AutoMacrosDB is the saved-variables table. The game fills it in
-- after this file has run, so it is always read through DB() and never kept in
-- a local. Layout:
--   schema            data version (see Init)
--   sessions          how many times this data has been loaded (/amac status)
--   style             look and feel, shared by all characters (only changed values)
--   idx / picks       macro slot and flyout choice, per character
--   enabled / custom  which categories are on, and your own categories
--   learned           items sorted into categories, by the addon or by hand
--   ignored           consumables checked and found to belong nowhere
--   glow, noFlyout, stockTooltip, showNames, learnOff   on/off options
-- ---------------------------------------------------------------------------
local SCHEMA = 2
local CLASSIFIER = 1   -- raise when the learning rules change, so items are checked again

local STYLE_DEFAULTS = {
    glowColor = { 1, 0.15, 0.15, 1 }, glowThickness = 3, glowTexture = "solid",
    glowPulse = true, glowSpeed = 0.7,
    tabColor = { 1, 0.82, 0, 0.95 }, tabHoverColor = { 1, 1, 1, 1 },
    tabWidth = 18, tabHeight = 7, tabTexture = "solid",
    flyoutBg = { 0, 0, 0, 0.65 }, flyoutBorderColor = { 0, 0, 0, 1 }, flyoutBorderSize = 1,
    entrySize = 34, entrySpacing = 2,
    entryBorderColor = { 0.1, 0.1, 0.1, 1 }, selectedColor = { 1, 0.82, 0, 1 }, entryHover = { 1, 1, 1, 0.25 },
    closeDelay = 0.3,
    tooltipColor = { 1, 0.3, 0.3, 1 },
    euiSkin = true, euiAccent = false,
}

local function Style(key)
    local s = DB().style
    local v
    if type(s) == "table" then v = s[key] end   -- (a false value must survive, so no "and/or" here)
    if v == nil then v = STYLE_DEFAULTS[key] end
    return v
end

-- EllesmereUI styling. skin is the table EllesmereUI hands to RegisterSkin; it
-- stays nil when EllesmereUI is not installed or skinning is off for this addon.
local skin
local ApplyStyle   -- defined with the flyout code

local function SkinActive()
    return skin ~= nil and Style("euiSkin") ~= false
end

-- EllesmereUI's accent colour: its custom or class colour, whichever is chosen
-- in its Global Settings. nil when EllesmereUI is not loaded. The skin hands it
-- over when skinning is on; otherwise it is read from EllesmereUI directly.
local function EUIAccent()
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

local function AccentRGB()
    local r, g, b = EUIAccent()
    if r then return r, g, b end
    return 1, 0.82, 0
end

-- Every colour setting has a mode, saved as style[<key>Mode]:
--   default  the built-in colour (STYLE_DEFAULTS)
--   accent   EllesmereUI's accent colour (falls back to default without it)
--   custom   picked by hand, saved as style[<key>]
-- Opacity is shared by all three and comes from style[<key>] or the default.
local COLOR_MODES = {
    { key = "default", label = "Default" },
    { key = "accent", label = "EllesmereUI accent" },
    { key = "custom", label = "Custom" },
}

-- colours that followed the accent with 0.25.0's "EllesmereUI accent colour" switch
local ACCENT_KEYS = { tabColor = true, selectedColor = true, flyoutBorderColor = true }

local function ColorMode(key)
    local s = DB().style
    local m = type(s) == "table" and s[key .. "Mode"] or nil
    if m then return m end
    if type(s) == "table" and s[key] ~= nil then return "custom" end   -- picked before modes existed
    if ACCENT_KEYS[key] and Style("euiAccent") then return "accent" end
    return "default"
end

local function ColorModeChoices()
    local list = {}
    for _, m in ipairs(COLOR_MODES) do
        if m.key ~= "accent" or EUIAccent() then list[#list + 1] = m end
    end
    return list
end

-- the colour actually drawn for a colour setting, as { r, g, b, a }
local function StyleColor(key)
    local c = Style(key)
    local mode = ColorMode(key)
    if mode == "accent" then
        local r, g, b = EUIAccent()
        if r then return { r, g, b, c[4] or 1 } end
    end
    if mode ~= "custom" then
        local d = STYLE_DEFAULTS[key]
        return { d[1], d[2], d[3], c[4] or d[4] or 1 }
    end
    return c
end

local function SetStyle(key, value)
    local db = DB()
    if type(db.style) ~= "table" then db.style = {} end
    if type(value) == "table" then value = { value[1], value[2], value[3], value[4] } end
    db.style[key] = value
    if ApplyStyle then ApplyStyle() end
end

-- Saves the mode a colour has now, so that saving its value (opacity, say)
-- does not turn it into a custom colour.
local function PinMode(key)
    local s = DB().style
    if type(s) ~= "table" or s[key .. "Mode"] == nil then SetStyle(key .. "Mode", ColorMode(key)) end
end

-- Saves a picked colour. It becomes the custom colour, unless only the opacity
-- changed (or a picker was cancelled), which keeps the mode as it was.
local function SetColor(key, r, g, b, a)
    PinMode(key)
    local c = Style(key)
    local same = math.abs(c[1] - r) < 0.002 and math.abs(c[2] - g) < 0.002 and math.abs(c[3] - b) < 0.002
    SetStyle(key, { r, g, b, a or c[4] or 1 })
    if not same then SetStyle(key .. "Mode", "custom") end
end

local function ResetStyle()
    DB().style = nil
    if ApplyStyle then ApplyStyle() end
end

-- Textures for borders and tabs. "solid" is a plain colour; the others are
-- picture files tinted with the colour. LibSharedMedia status bars are offered
-- too when that library is loaded.
local TEXTURES = {
    { key = "solid", label = "Solid colour" },
    { key = "glow", label = "Soft glow", path = "Interface\\Buttons\\UI-ActionButton-Border", glow = true },
    { key = "bar", label = "Status bar", path = "Interface\\TargetingFrame\\UI-StatusBar" },
}

local function TextureChoices(withGlow)
    local list = {}
    for _, t in ipairs(TEXTURES) do
        if withGlow or not t.glow then list[#list + 1] = t end
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

local function TextureInfo(key)
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

local function Paint(tex, key, c)
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
local function MakeEdges(frame, layer)
    local e = {}
    for i = 1, 4 do e[i] = frame:CreateTexture(nil, layer or "OVERLAY") end
    return e
end

local function PlaceEdges(e, frame, t)
    if not t or t <= 0 then
        for i = 1, 4 do e[i]:Hide() end
        return
    end
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

-- Items sorted into categories. Built-in lists come from DATA; the rest from
-- db.learned (see "Learning new items" below).
local learnedIdx = {}   -- set name -> { [itemID] = true }

local function InSet(setName, id)
    local set = DATA[setName]
    if set and set[id] then return true end
    local l = learnedIdx[setName]
    return l ~= nil and l[id] == true
end

local function RebuildLearned()
    for k in pairs(learnedIdx) do learnedIdx[k] = nil end
    local learned = DB().learned
    if type(learned) ~= "table" then return end
    for id, rec in pairs(learned) do
        if type(rec) == "table" and type(rec.sets) == "table" then
            for _, s in ipairs(rec.sets) do
                learnedIdx[s] = learnedIdx[s] or {}
                learnedIdx[s][id] = true
            end
        end
    end
end

-- Every button the addon can make. A button only exists once its category is
-- switched on (/amac add <key>); the ones marked default are on from the start.
--   scope "character": goes in the character-specific macro tab (class buttons)
--   scope "general":   goes in the general macro tab, shared by all characters
--                      (the addon rewrites it for whoever is logged in)
--   name:   the id used in saved data; title / empty: the macro name when it has
--           an item / when it is empty (16 characters at most)
local CATALOG = {
    { key = "healthstone", name = "AM_Healthstone", title = "Healthstone", empty = "No Healthstone", label = "Healthstones",
      special = "healthstone", scope = "character", default = true },
    { key = "healthpot", name = "AM_HealthPot", title = "Health Potion", empty = "No Health Potion", label = "health potions",
      set = "hpot", default = true },
    { key = "manapot", name = "AM_ManaPot", title = "Mana Potion", empty = "No Mana Potion", label = "mana potions",
      set = "mpot", default = true },
    { key = "food", name = "AM_Food", title = "Food", empty = "No Food", label = "food", set = "food", default = true },
    { key = "water", name = "AM_Water", title = "Water", empty = "No Water", label = "water", set = "water", default = true },
    { key = "comprehend", name = "AM_Scroll", title = "Comprehend", empty = "Comprehend", label = "scrolls",
      special = "scroll", class = "MAGE", scope = "character", default = true },
    { key = "bandage", name = "AM_Bandage", title = "Bandage", empty = "No Bandage", label = "bandages",
      set = "bandage", placeholder = { item = 1251 } },
    { key = "antivenom", name = "AM_AntiVenom", title = "Anti-Venom", empty = "No Anti-Venom", label = "anti-venom",
      set = "antivenom", placeholder = { item = 2633 } },
    { key = "agiscroll", name = "AM_ScrAgi", title = "Agility Scroll", empty = "No Agi Scroll", label = "agility scrolls",
      set = "scroll_agility", placeholder = { item = 3012 } },
    { key = "intscroll", name = "AM_ScrInt", title = "Intellect Scroll", empty = "No Int Scroll", label = "intellect scrolls",
      set = "scroll_intellect", placeholder = { item = 955 } },
    { key = "stascroll", name = "AM_ScrSta", title = "Stamina Scroll", empty = "No Sta Scroll", label = "stamina scrolls",
      set = "scroll_stamina", placeholder = { item = 1180 } },
    { key = "strscroll", name = "AM_ScrStr", title = "Strength Scroll", empty = "No Str Scroll", label = "strength scrolls",
      set = "scroll_strength", placeholder = { item = 954 } },
    { key = "agielixir", name = "AM_ElxAgi", title = "Agility Elixir", empty = "No Agi Elixir", label = "agility elixirs",
      set = "elixir_agility", placeholder = { item = 2457 } },
    { key = "intelixir", name = "AM_ElxInt", title = "Intellect Elixir", empty = "No Int Elixir", label = "intellect elixirs",
      set = "elixir_intellect", placeholder = { item = 3383 } },
    { key = "staelixir", name = "AM_ElxSta", title = "Stamina Elixir", empty = "No Sta Elixir", label = "stamina elixirs",
      set = "elixir_stamina", placeholder = { item = 13453 } },
    { key = "strelixir", name = "AM_ElxStr", title = "Strength Elixir", empty = "No Str Elixir", label = "strength elixirs",
      set = "elixir_strength", placeholder = { item = 2454 } },
    { key = "teleports", name = "AM_Teleport", title = "Teleports", empty = "Teleports", label = "teleports",
      kind = "spells", spells = { 3561, 3567, 3562, 3563, 3565, 3566 }, class = "MAGE", scope = "character" },
    { key = "portals", name = "AM_Portal", title = "Portals", empty = "Portals", label = "portals",
      kind = "spells", spells = { 10059, 11417, 11416, 11418, 11419, 11420 }, class = "MAGE", scope = "character" },
}

local MACROS = {}            -- the categories in use for this character (rebuilt by RebuildMacros)
local ALL = {}               -- every category, built-in and custom, for /amac list
local EMPTY_MESSAGE = {}     -- macro name when empty -> tooltip message

local function Enabled(e)
    local on = DB().enabled
    if on and on[e.key] ~= nil then return on[e.key] end
    return e.default == true
end

-- Categories you made yourself (/amac custom): kept in the saved data.
local function CustomEntries()
    local list = {}
    local custom = DB().custom
    if type(custom) ~= "table" then return list end
    local keys = {}
    for k in pairs(custom) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local c = custom[k]
        if type(c) == "table" and type(c.ids) == "table" and #c.ids > 0 then
            local title = tostring(c.title or k):sub(1, 16)
            local e = {
                key = k, custom = true, name = "AM_C_" .. k, title = title,
                empty = ("No " .. title):sub(1, 16), label = tostring(c.title or k):lower(), default = true,
            }
            if c.kind == "spells" then
                e.kind, e.spells, e.scope = "spells", c.ids, "character"
            else
                e.set = "custom_" .. k
                e.placeholder = { item = c.ids[1] }
                DATA[e.set] = ToSet(c.ids)
            end
            list[#list + 1] = e
        end
    end
    return list
end

local function RebuildMacros()
    for i = #MACROS, 1, -1 do MACROS[i] = nil end
    for i = #ALL, 1, -1 do ALL[i] = nil end
    for k in pairs(EMPTY_MESSAGE) do EMPTY_MESSAGE[k] = nil end
    local _, class = UnitClass("player")
    for _, e in ipairs(CATALOG) do ALL[#ALL + 1] = e end
    for _, e in ipairs(CustomEntries()) do ALL[#ALL + 1] = e end
    for _, e in ipairs(ALL) do
        if e.set then EMPTY_MESSAGE[e.empty] = "No " .. e.label .. " in inventory." end
        if Enabled(e) and (not e.class or e.class == class) then MACROS[#MACROS + 1] = e end
    end
end
pcall(RebuildMacros)

local report = {}   -- last result per macro name, for /automacros

local function Print(msg)
    print("|cff66ccffAutoMacros:|r " .. tostring(msg))
end

-- A failure in one part (button scan, highlight, flyout) is reported once and
-- never stops the rest of the addon.
local lastErrorText
local function Fail(where, err)
    err = tostring(err)
    report.lastError = where .. ": " .. err
    if err ~= lastErrorText then
        lastErrorText = err
        Print("error in " .. where .. ": " .. err)
    end
end

-- Item info: this client may return a table or the classic multiple returns.
local function ItemInfo(id)
    local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not fn then return nil end
    local ok, a, b, c, d, e = pcall(fn, id)
    if not ok or a == nil then return nil end
    if type(a) == "table" then
        return a.itemName or a.name, a.itemMinLevel or a.minLevel or a.requiredLevel
    end
    return a, e
end

local function ItemRef(id)
    local name = ItemInfo(id)
    if type(name) == "string" and name ~= "" then return name end
    return "item:" .. id
end

local lastScrolls = {}   -- untranslated scrolls from the last bag scan, in bag order
local lastLocs = {}      -- item ID -> { bag, slot } of its first stack in the last scan
local flyoutItems = {}  -- macro name -> usable items from the last scan, best first

local function ScanBags()
    local have, scrolls, seen, locs = {}, {}, {}, {}
    local C = C_Container
    local getSlots = (C and C.GetContainerNumSlots) or GetContainerNumSlots
    local getID = (C and C.GetContainerItemID) or GetContainerItemID
    local getLink = (C and C.GetContainerItemLink) or GetContainerItemLink
    if not (getSlots and getID) then return have, false, scrolls, locs end
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        local n = getSlots(bag)
        if type(n) == "table" then n = n.numSlots or n.slots or n[1] end
        for slot = 1, (tonumber(n) or 0) do
            local id = getID(bag, slot)
            if type(id) == "table" then id = id.itemID end
            if type(id) == "number" then
                have[id] = true
                if not locs[id] then locs[id] = { bag, slot } end
                -- untranslated scrolls are named in capitals: "Scroll: KWYJIBO"
                if getLink and not seen[id] then
                    local link = getLink(bag, slot)
                    local name = type(link) == "string" and link:match("%[(.-)%]")
                    if name and name:match("^Scroll: [%u%s'%-]+$") then
                        seen[id] = true
                        scrolls[#scrolls + 1] = { id = id, name = name }
                    end
                end
            end
        end
    end
    return have, true, scrolls, locs
end

-- Every usable item of a category that is in your bags, best first.
local function Candidates(have, setName)
    local level = UnitLevel("player") or 1
    local list = {}
    for id in pairs(have) do
        if InSet(setName, id) then
            local _, minLevel = ItemInfo(id)
            minLevel = tonumber(minLevel) or 0
            if minLevel <= level then
                list[#list + 1] = { id = id, score = minLevel * 10000000 + id }
            end
        end
    end
    table.sort(list, function(x, y) return x.score > y.score end)
    return list
end

-- The item a macro uses: the one you picked in the flyout if it is still in
-- your bags, otherwise the best one.
local function Chosen(m, list)
    if #list == 0 then return nil end
    local db = DB()
    local want = Picks()[m.name]
    if not want then want = db.pick and db.pick[m.name] end               -- older versions
    if not want and m.special == "scroll" then want = db.scrollPick end   -- older versions
    if want then
        for _, e in ipairs(list) do
            if e.id == want then return e.id end
        end
    end
    return list[1].id
end

local function BestHealthstone(have)
    local bestID, bestScore
    for id in pairs(have) do
        local rank = HS_RANK[id]
        if rank then
            local score = rank * 1000000 + id
            if not bestScore or score > bestScore then bestID, bestScore = id, score end
        end
    end
    return bestID
end

local function CreateSpellName()
    local known = IsPlayerSpell or IsSpellKnown
    if not known then return nil end
    for _, spellID in ipairs(CREATE_HS) do
        local ok, isKnown = pcall(known, spellID)
        if ok and isKnown then
            local name
            if C_Spell and C_Spell.GetSpellInfo then
                local ok2, info = pcall(C_Spell.GetSpellInfo, spellID)
                if ok2 then name = type(info) == "table" and info.name or info end
            end
            if not name and GetSpellInfo then name = GetSpellInfo(spellID) end
            if type(name) == "string" then return name end
        end
    end
end

local function UseBody(id)
    return "#showtooltip " .. ItemRef(id) .. "\n/use item:" .. id
end

-- Placeholder icon shown when a category has nothing in your bags: the icon of
-- an in-game item. Use { item = <itemID> } for an item's icon, or
-- { icon = <iconFileID> } for a raw icon ID (for example 1339440, the red X).
local PLACEHOLDER = {
    AM_Healthstone = { item = 5509 },   -- Healthstone
    AM_HealthPot   = { item = 3371 },   -- Empty Vial
    AM_ManaPot     = { item = 3371 },   -- Empty Vial
    AM_Food        = { item = 4540 },   -- Tough Hunk of Bread
    AM_Water       = { item = 159 },    -- Refreshing Spring Water
}

local function IconFor(entry)
    if not entry then return QUESTION_MARK end
    if entry.icon then return entry.icon end
    local icon
    local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if instant then
        local ok, a, b, c, d, e = pcall(instant, entry.item)
        if ok then
            if type(a) == "table" then icon = a.iconFileID or a.icon else icon = e end
        end
    end
    if not icon then
        local getIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
        if getIcon then
            local ok, r = pcall(getIcon, entry.item)
            if ok then icon = r end
        end
    end
    return icon or QUESTION_MARK
end

-- No #showtooltip here, so the macro's own icon (the placeholder) is what shows.
-- What clicking an empty button does:
--   "say"   - the macro text is just the message, so a click speaks it in /say
--             and anyone nearby sees it
--   "print" - shows the message, in red, in your own chat window (nobody else sees it)
--   "none"  - does nothing
-- The tooltip message comes from the tooltip code below, not from the macro.
local EMPTY_CLICK = "say"

local function EmptyBody(label)
    local message = "No " .. label .. " in inventory."
    if EMPTY_CLICK == "print" then
        return '/run print("|cffff4d4d' .. message .. '|r")'
    elseif EMPTY_CLICK == "say" then
        return message
    end
    return ""
end

local function SameBody(current, body)
    current = current or ""
    if body == "" then return current:match("^%s*$") ~= nil end
    return current == body
end

local function HealthstoneBody(have)
    local id = BestHealthstone(have)
    local create = CreateSpellName()
    if id and create then
        return "#showtooltip [mod:shift] " .. create .. "; " .. ItemRef(id)
            .. "\n/cast [mod:shift] " .. create
            .. "\n/use [nomod] item:" .. id, id
    elseif id then
        return UseBody(id), id
    elseif create then
        return "#showtooltip " .. create .. "\n/cast " .. create, nil
    end
    return nil, nil
end

-- Comprehend Scroll (Mage). With untranslated scrolls in your bags the button
-- becomes "cast Comprehend Scroll on that scroll"; with none it just shows the
-- spell. /amac next moves to the next scroll when the current one can't be read.
local SCROLL_SPELL = 1296017

local function ScrollSpellName()
    local name
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, SCROLL_SPELL)
        if ok then name = type(info) == "table" and info.name or info end
    end
    if not name and GetSpellInfo then
        local ok, n = pcall(GetSpellInfo, SCROLL_SPELL)
        if ok then name = n end
    end
    return type(name) == "string" and name or "Comprehend Scroll"
end

local function ScrollSpellKnown()
    local known = IsPlayerSpell or IsSpellKnown
    if known then
        local ok, k = pcall(known, SCROLL_SPELL)
        if ok and k then return true end
    end
    -- ranks have their own spell IDs, so also accept the name being in the spellbook
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, "Comprehend Scroll")
        if ok and info then return true end
    end
    return false
end

local function ScrollBody(m, scrolls)
    local _, class = UnitClass("player")
    if class ~= "MAGE" or not ScrollSpellKnown() then return nil, nil end
    local spell = ScrollSpellName()
    local id = Chosen(m, scrolls)
    if id then
        return "#showtooltip item:" .. id .. "\n/cast " .. spell .. "\n/use item:" .. id, id
    end
    return "#showtooltip " .. spell .. "\n/cast " .. spell, nil
end

local function NextScroll()
    if #lastScrolls < 2 then return nil end
    local current = Chosen({ name = "AM_Scroll", special = "scroll" }, lastScrolls)
    local idx = 1
    for i, sc in ipairs(lastScrolls) do
        if sc.id == current then idx = i break end
    end
    local nxt = lastScrolls[idx % #lastScrolls + 1]
    Picks().AM_Scroll = nxt.id
    return nxt.name
end

-- Spell categories (mage teleports and portals): the known spells of a list.
local function SpellName(id)
    local name
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, id)
        if ok then name = type(info) == "table" and info.name or info end
    end
    if not name and GetSpellInfo then
        local ok, n = pcall(GetSpellInfo, id)
        if ok then name = n end
    end
    return type(name) == "string" and name or nil
end

local function SpellIcon(id)
    local icon
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, r = pcall(C_Spell.GetSpellTexture, id)
        if ok then icon = r end
    end
    if not icon and GetSpellTexture then
        local ok, r = pcall(GetSpellTexture, id)
        if ok then icon = r end
    end
    return icon or QUESTION_MARK
end

local function KnownSpells(m)
    local list = {}
    local known = IsPlayerSpell or IsSpellKnown
    if not known then return list end
    for _, id in ipairs(m.spells or {}) do
        local ok, k = pcall(known, id)
        if ok and k then list[#list + 1] = { id = id } end
    end
    return list
end

local function SpellBody(id)
    local name = SpellName(id)
    if not name then return nil end
    return "#showtooltip " .. name .. "\n/cast " .. name
end

-- The macro we remembered at a slot is only trusted if its text still looks like
-- this category's.
local function BodyMatches(m, body)
    if type(body) ~= "string" then return false end
    if m.special == "scroll" then return body:find("Comprehend", 1, true) ~= nil end
    if m.kind == "spells" then return body:find("/cast", 1, true) ~= nil end
    -- empty-state text, in any of the forms used by different versions
    local stem = m.label:gsub("s$", "")
    if body:find("No " .. stem, 1, true) then return true end
    local id = tonumber(body:match("item:(%d+)"))
    if m.set then return id ~= nil and InSet(m.set, id) end
    return (id ~= nil and HS_RANK[id] ~= nil) or body:find("Create Healthstone", 1, true) ~= nil
end

local function FindMacro(m)
    local db = DB()
    db.idx = db.idx or {}
    local key = CharKey()
    db.idx[key] = db.idx[key] or {}

    -- 1. the slot remembered last time, if it still holds this macro
    local saved = db.idx[key][m.name]
    if saved then
        local name, _, body = GetMacroInfo(saved)
        if name and BodyMatches(m, body) then return saved end
    end
    -- 2. its name (the macros are named after their category)
    for _, n in ipairs({ m.title, m.empty, m.name }) do
        local idx = GetMacroIndexByName(n)
        if idx and idx > 0 then return idx end
    end
end

local function WantedName(m, active)
    return active and m.title or m.empty
end

local function Remember(m, idx)
    if type(idx) ~= "number" then return end
    local db = DB()
    db.idx = db.idx or {}
    local key = CharKey()
    db.idx[key] = db.idx[key] or {}
    db.idx[key][m.name] = idx
end

local function Apply(m, body, icon, active)
    if not body then return "skipped" end
    if #body > 255 then return "too long (" .. #body .. " bytes)" end
    icon = icon or QUESTION_MARK
    local want = WantedName(m, active)
    local idx = FindMacro(m)
    if not idx then
        local perChar = m.scope == "character"   -- class buttons: character tab; the rest: general tab
        local ok, result = pcall(CreateMacro, want, icon, body, perChar)
        if not ok and body == "" then
            ok, result = pcall(CreateMacro, want, icon, " ", perChar)   -- some clients refuse an empty body
        end
        if not ok then return "create failed: " .. tostring(result) end
        Remember(m, result)
        return "created"
    end
    local curName, curIcon = GetMacroInfo(idx)
    local db = DB()
    -- with #showtooltip the shown icon is the item's, and the client may report that
    -- instead of the macro's own, so only the placeholder icons are compared
    local sameIcon = active or type(curIcon) ~= "number" or curIcon == icon
    local sameName = curName == want
    if not sameName or not SameBody(GetMacroBody(idx), body) or not sameIcon then
        local ok, result = pcall(EditMacro, idx, want, icon, body)
        if not ok and body == "" then
            ok, result = pcall(EditMacro, idx, want, icon, " ")
        end
        if not ok then return "edit failed: " .. tostring(result) end
        Remember(m, type(result) == "number" and result or idx)
        return "updated"
    end
    Remember(m, idx)
    return "unchanged"
end

-- ---------------------------------------------------------------------------
-- Highlight: a pulsing border on any action button holding a macro whose
-- category is empty. It only touches our own frames, so it also works in combat.
-- Colour, thickness, texture and pulse come from the saved style.
-- ---------------------------------------------------------------------------
local function StyleGlow(g, button)
    local c = StyleColor("glowColor")
    local key = Style("glowTexture")
    local info = TextureInfo(key)
    local t = Style("glowThickness")
    local off = math.max(1, t - 1)   -- thick borders grow outwards
    g:ClearAllPoints()
    g:SetPoint("TOPLEFT", button, "TOPLEFT", -off, off)
    g:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", off, -off)
    if info.glow then
        for i = 1, 4 do g.edges[i]:Hide() end
        local w = button.GetWidth and button:GetWidth() or 36
        if type(w) ~= "number" or w <= 0 then w = 36 end
        local size = w * (1.4 + t * 0.1)
        g.soft:ClearAllPoints()
        g.soft:SetPoint("CENTER", button, "CENTER", 0, 0)
        g.soft:SetSize(size, size)
        g.soft:SetTexture(info.path)
        pcall(g.soft.SetBlendMode, g.soft, "ADD")
        g.soft:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        g.soft:Show()
    else
        g.soft:Hide()
        for i = 1, 4 do Paint(g.edges[i], key, c) end
        PlaceEdges(g.edges, g, t)
    end
    if g.anim then pcall(g.anim.SetDuration, g.anim, Style("glowSpeed")) end
    if g.pulse and g:IsShown() then
        if Style("glowPulse") then
            local playing = false
            pcall(function() playing = g.pulse:IsPlaying() end)
            if not playing then g.pulse:Play() end
        else
            g.pulse:Stop()
            g:SetAlpha(1)
        end
    end
end

-- the small tab on a button that has a flyout
local function StyleArrow(a, hover)
    a:SetSize(Style("tabWidth"), Style("tabHeight"))
    Paint(a.tex, Style("tabTexture"), hover and StyleColor("tabHoverColor") or StyleColor("tabColor"))
end

-- the popup frame: our own background and border, or the EllesmereUI panel look
local function StyleFlyout(f)
    local skinned = false
    if SkinActive() and skin.Panel then skinned = pcall(skin.Panel, f, {}) end
    f.skinned = skinned
    if skinned then
        f.bg:Hide()
        for i = 1, 4 do f.edges[i]:Hide() end
    else
        local c = StyleColor("flyoutBg")
        f.bg:Show()
        f.bg:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        local bc = StyleColor("flyoutBorderColor")
        for i = 1, 4 do f.edges[i]:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 1) end
        PlaceEdges(f.edges, f, Style("flyoutBorderSize"))
    end
end

-- one item button in the popup
local function StyleEntry(e)
    local size = Style("entrySize")
    e:SetSize(size, size)
    local c = e.selected and StyleColor("selectedColor") or StyleColor("entryBorderColor")
    e.border:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    local h = StyleColor("entryHover")
    e.hl:SetColorTexture(h[1], h[2], h[3], h[4] or 1)
    if SkinActive() then
        if skin.SquareIcon and not e.squared then e.squared = pcall(skin.SquareIcon, e.icon, e) end
        e.border:SetAlpha((e.squared and not e.selected) and 0 or 1)
        if skin.GetFont then
            local ok, font = pcall(skin.GetFont)
            if ok and type(font) == "string" then pcall(e.count.SetFont, e.count, font, 11, "OUTLINE") end
        end
    else
        e.border:SetAlpha(1)
    end
end

local buttons = {}        -- action buttons found on screen
local glows = {}          -- button -> border frame
local emptyMacro = {}     -- macro index -> macro while its category is empty
local macroAt = {}        -- macro index -> macro, for every macro we manage
local RefreshArrows, MacroOnButton   -- defined with the flyout, below
local emptyName = {}      -- macro name -> true while its category is empty

-- Which action slot a button shows. Handles Blizzard bars and the common bar
-- addons (Bartender, ElvUI, Dominos), which use LibActionButton.
local function ButtonSlot(f)
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
local BUTTON_NAMES = {
    { "ActionButton%d", 12 }, { "MultiBarBottomLeftButton%d", 12 }, { "MultiBarBottomRightButton%d", 12 },
    { "MultiBarRightButton%d", 12 }, { "MultiBarLeftButton%d", 12 },
    { "MultiBar5Button%d", 12 }, { "MultiBar6Button%d", 12 }, { "MultiBar7Button%d", 12 },
    { "BT4Button%d", 180 }, { "DominosActionButton%d", 180 },
}

local function CollectButtons()
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

local function SafeCollect()
    local ok, res = pcall(CollectButtons)
    if ok then buttons = res else Fail("button scan", res) end
end

local function GlowFor(button)
    local g = glows[button]
    if g then return g end
    g = CreateFrame("Frame", nil, button)
    g:SetFrameLevel((button:GetFrameLevel() or 1) + 10)
    g.edges = MakeEdges(g, "OVERLAY")
    g.soft = g:CreateTexture(nil, "OVERLAY")
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

local function ShowGlow(button, on)
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

local function RefreshGlow()
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

local function SetEmpty(emptyState)
    emptyMacro = {}
    emptyName = {}
    macroAt = {}
    local db = DB()
    local saved = db.idx and db.idx[CharKey()]
    if saved then
        for _, m in ipairs(MACROS) do
            local idx = saved[m.name]
            if idx then
                macroAt[idx] = m
                if emptyState[m.name] then
                    emptyMacro[idx] = m
                    emptyName[m.name] = true
                end
            end
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
local function CleanTooltip(tip)
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

-- /amac items: what the game itself says about each consumable in your bags (its
-- item class and subclass, and the "Restores ..." line of its tooltip). This is
-- read-only and exists to see whether items can be sorted into food, water and
-- potions from the client's own data instead of from fixed lists.
-- ---------------------------------------------------------------------------
-- Learning new items. An item that is in none of the built-in lists is sorted
-- by what the game says about it: its item class (language independent) and the
-- "Use:" lines of its tooltip. The result is saved in db.learned, so each item
-- is only examined once. Anything the rules get wrong can be corrected by hand
-- with /amac assign and /amac unassign, and hand-made entries always win.
--   consumable, subclass Bandage            -> bandage
--   Food & Drink, "Use:" restores health    -> food;  restores mana -> water
--   Potion,       "Use:" restores health    -> health potion; mana -> mana potion
--   Potion / Elixir / Flask, "Use:" raises Strength, Agility, Stamina or Intellect
--                                           -> that stat's elixir button
--   Scroll,       "Use:" raises one of those -> that stat's scroll button
-- ---------------------------------------------------------------------------
local LEARNABLE = {
    "food", "water", "hpot", "mpot", "bandage", "antivenom",
    "scroll_agility", "scroll_intellect", "scroll_stamina", "scroll_strength",
    "elixir_agility", "elixir_intellect", "elixir_stamina", "elixir_strength",
}
local STAT_KEYS = { "strength", "agility", "stamina", "intellect" }   -- SPELL_STAT1..4_NAME

local function ItemClass(id)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not fn then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, id)
    if not ok or a == nil then return nil end
    if type(a) == "table" then return a.classID, a.subclassID or a.subClassID end
    return f, g
end

local scanTip
local function TooltipLines(id)
    if not scanTip then
        local ok, t = pcall(CreateFrame, "GameTooltip", "AutoMacrosScanTip", nil, "GameTooltipTemplate")
        if not ok or not t then return nil end
        scanTip = t
    end
    pcall(scanTip.SetOwner, scanTip, UIParent, "ANCHOR_NONE")
    local ok = pcall(scanTip.SetItemByID, scanTip, id)
    if not ok then pcall(scanTip.SetHyperlink, scanTip, "item:" .. id) end
    local lines = {}
    for i = 1, scanTip:NumLines() do
        local fs = _G["AutoMacrosScanTipTextLeft" .. i]
        local text = fs and fs:GetText()
        if type(text) == "string" then lines[#lines + 1] = text end
    end
    return lines
end

local function TooltipSummary(id)
    local lines = TooltipLines(id)
    if not lines then return "(no scan tooltip)" end
    local found = {}
    for _, text in ipairs(lines) do
        if text:find("Restores") or text:find("Use:") or text:find("Must remain") then
            found[#found + 1] = text:sub(1, 90)
        end
    end
    return #found > 0 and table.concat(found, " | ") or "(no Restores/Use line)"
end

local function HasWord(low, ...)
    for i = 1, select("#", ...) do
        local w = select(i, ...)
        if type(w) == "string" and w ~= "" and low:find(w:lower(), 1, true) then return true end
    end
    return false
end

-- Returns a list of set names (empty: belongs nowhere), or nil when the game has
-- not delivered the item's data yet (it is tried again on the next update).
local function Classify(id)
    local class, sub = ItemClass(id)
    if class == nil then return nil end
    if class ~= 0 then return {} end
    if sub == 7 then return { "bandage" } end
    if sub ~= 1 and sub ~= 2 and sub ~= 3 and sub ~= 4 and sub ~= 5 then return {} end
    local lines = TooltipLines(id)
    if not lines or #lines < 2 or lines[1] == RETRIEVING_ITEM_INFO then return nil end
    local use = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    local health, mana, stats = false, false, {}
    for _, text in ipairs(lines) do
        if text:find(use, 1, true) and text:find("%d") then
            local low = text:lower()
            if HasWord(low, "health", HEALTH) then health = true end
            if HasWord(low, "mana", MANA) then mana = true end
            for i, key in ipairs(STAT_KEYS) do
                local name = _G["SPELL_STAT" .. i .. "_NAME"] or (key:sub(1, 1):upper() .. key:sub(2))
                if text:find(name, 1, true) then stats[key] = true end
            end
        end
    end
    local sets = {}
    if sub == 5 then
        if health then sets[#sets + 1] = "food" end
        if mana then sets[#sets + 1] = "water" end
    elseif sub == 1 and (health or mana) then
        if health then sets[#sets + 1] = "hpot" end
        if mana then sets[#sets + 1] = "mpot" end
    elseif sub == 4 then
        for _, key in ipairs(STAT_KEYS) do
            if stats[key] then sets[#sets + 1] = "scroll_" .. key end
        end
    elseif sub == 1 or sub == 2 or sub == 3 then
        for _, key in ipairs(STAT_KEYS) do
            if stats[key] then sets[#sets + 1] = "elixir_" .. key end
        end
    end
    return sets
end

local function InBuiltInList(id)
    for _, s in ipairs(LEARNABLE) do
        if DATA[s] and DATA[s][id] then return true end
    end
    return false
end

local function SetTitle(setName)
    for _, e in ipairs(ALL) do
        if e.set == setName then return e.title, e.key end
    end
    return setName
end

local sessionDone = {}   -- item IDs not worth looking at again this session
local attempts = {}      -- item ID -> tries while the game had no data for it

local function LearnNew(have)
    local db = DB()
    if db.learnOff then return end
    local budget, changed = 40, false
    for id in pairs(have) do
        if budget <= 0 then break end
        local known = type(db.learned) == "table" and db.learned[id]
        local skip = known or sessionDone[id] or (type(db.ignored) == "table" and db.ignored[id] == CLASSIFIER)
        if not skip and InBuiltInList(id) then
            sessionDone[id] = true
            skip = true
        end
        if not skip then
            local class = ItemClass(id)
            if class ~= nil and class ~= 0 then
                sessionDone[id] = true            -- not a consumable
            elseif class == 0 then
                budget = budget - 1
                local sets = Classify(id)
                if sets == nil then
                    attempts[id] = (attempts[id] or 0) + 1
                    if attempts[id] > 20 then sessionDone[id] = true end
                elseif #sets == 0 then
                    if type(db.ignored) ~= "table" then db.ignored = {} end
                    db.ignored[id] = CLASSIFIER
                else
                    if type(db.learned) ~= "table" then db.learned = {} end
                    db.learned[id] = { sets = sets, how = "auto" }
                    changed = true
                    local titles = {}
                    for _, s in ipairs(sets) do titles[#titles + 1] = (SetTitle(s)) end
                    Print("learned " .. ItemRef(id) .. " as " .. table.concat(titles, " + ")
                        .. " (/amac unassign " .. id .. " if that is wrong)")
                end
            end
        end
    end
    if changed then RebuildLearned() end
end

local function ItemClassInfo(id)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not fn then return "no GetItemInfoInstant" end
    local ok, a, b, c, d, e, f, g = pcall(fn, id)
    if not ok or a == nil then return "no data" end
    if type(a) == "table" then
        return string.format("class=%s sub=%s (%s / %s)", tostring(a.classID), tostring(a.subclassID or a.subClassID),
            tostring(a.itemType), tostring(a.itemSubType))
    end
    return string.format("class=%s sub=%s (%s / %s)", tostring(f), tostring(g), tostring(b), tostring(c))
end

local pending, timerSet, glowTimerSet = false, false, false

local function UpdateCore()
    timerSet = false
    pcall(RebuildMacros)
    local have, scanned, scrolls, locs = ScanBags()
    if not scanned then
        report.error = "bag API not available"
        return
    end
    lastScrolls = scrolls
    lastLocs = locs or {}
    RebuildLearned()
    local okLearn, errLearn = pcall(LearnNew, have)
    if not okLearn then Fail("learning", errLearn) end
    report.error = nil
    local inCombat = InCombatLockdown()
    pending = inCombat   -- macros are only rewritten out of combat
    local emptyState = {}
    for _, m in ipairs(MACROS) do
        local body, id
        if m.special == "scroll" then
            flyoutItems[m.name] = scrolls
            body, id = ScrollBody(m, scrolls)
        elseif m.special == "healthstone" then
            body, id = HealthstoneBody(have)
        elseif m.kind == "spells" then
            local list = KnownSpells(m)
            flyoutItems[m.name] = list
            id = Chosen(m, list)
            body = id and SpellBody(id) or nil
        else
            local list = Candidates(have, m.set)
            flyoutItems[m.name] = list
            id = Chosen(m, list)
            body = id and UseBody(id) or EmptyBody(m.label)
        end
        -- spell and scroll buttons show the spell when there is nothing to use, so they are never "empty"
        emptyState[m.name] = (id == nil) and m.kind ~= "spells" and m.special ~= "scroll"
        if not inCombat then
            -- "?" and the real name while #showtooltip drives the icon; the
            -- placeholder icon and "No ..." name when it is not used.
            local active = body ~= nil and body:sub(1, 12) == "#showtooltip"
            local icon = QUESTION_MARK
            if body and not active then
                icon = IconFor(PLACEHOLDER[m.name] or m.placeholder)
            end
            local result = Apply(m, body, icon, active)
            report[m.name] = { id = id, result = result, size = body and #body or 0 }
        end
    end
    local ok, err = pcall(SetEmpty, emptyState)
    if not ok then Fail("highlight/flyout", err) end
end

local function Update()
    local ok, err = pcall(UpdateCore)
    if not ok then Fail("update", err) end
end

-- ---------------------------------------------------------------------------
-- Flyout: hover a button whose category has two or more usable items in your
-- bags and a popup of those items appears above it, each with the game's own
-- item tooltip. Click an item to make it the macro's default (picking the best
-- item goes back to automatic). A small gold tab on the button shows that a popup
-- is available. Choosing rewrites the macro, so in combat the change is applied
-- when combat ends.
-- ---------------------------------------------------------------------------
local MAX_ENTRIES = 10
local arrows = {}      -- action button -> tab
local entries = {}     -- pooled item buttons in the popup
local hooked = {}      -- action buttons we have hooked OnEnter/OnLeave on
local flyout           -- the shared popup frame

local function CountOf(id)
    local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not fn then return nil end
    local ok, n = pcall(fn, id)
    return ok and tonumber(n) or nil
end

local function ChooseItem(m, id)
    Picks()[m.name] = id          -- nil goes back to automatic
    if InCombatLockdown() then
        Print(m.title .. ": will change when combat ends")
    end
    Update()                      -- in combat this only queues the macro rewrite
end

-- The popup stays open while the mouse is over the button, its tab or the popup.
-- This is tracked from enter/leave events rather than by asking where the mouse
-- is, so it does not depend on the client being able to answer that.
local function AnyOver()
    if not flyout or not flyout.over then return false end
    for _, on in pairs(flyout.over) do
        if on then return true end
    end
    return false
end

local function SetOver(frame, on)
    if frame and flyout and flyout.over then flyout.over[frame] = on or nil end
end

-- The game's own tooltip for an item in the popup. Tried in order: the item's
-- real bag slot (exactly what the bag shows), then by item ID, then by link.
local function ShowItemTooltip(owner, id, loc)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local function filled()
        return GameTooltip.NumLines and GameTooltip:NumLines() > 0
    end
    if loc and GameTooltip.SetBagItem then
        local getID = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID
        local ok, here = pcall(getID, loc[1], loc[2])
        if ok and here == id then
            pcall(GameTooltip.SetBagItem, GameTooltip, loc[1], loc[2])
            if filled() then GameTooltip:Show() return end
        end
    end
    if GameTooltip.SetItemByID then
        pcall(GameTooltip.SetItemByID, GameTooltip, id)
        if filled() then GameTooltip:Show() return end
    end
    local link
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if info then
        local ok, a, b = pcall(info, id)
        if ok then
            if type(a) == "table" then link = a.hyperlink or a.itemLink else link = b end
        end
    end
    if type(link) == "string" then pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
    if not filled() then pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. id) end
    if not filled() then GameTooltip:AddLine(ItemRef(id)) end
    GameTooltip:Show()
end

local function ShowSpellTooltip(owner, id)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local function filled()
        return GameTooltip.NumLines and GameTooltip:NumLines() > 0
    end
    if GameTooltip.SetSpellByID then
        pcall(GameTooltip.SetSpellByID, GameTooltip, id)
        if filled() then GameTooltip:Show() return end
    end
    pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. id)
    if not filled() then GameTooltip:AddLine(SpellName(id) or ("spell " .. id)) end
    GameTooltip:Show()
end

local function BuildFlyout()
    if flyout then return flyout end
    flyout = CreateFrame("Frame", "AutoMacrosFlyout", UIParent)
    flyout.over = {}
    flyout:SetFrameStrata("DIALOG")
    flyout:SetClampedToScreen(true)
    if flyout.EnableMouse then flyout:EnableMouse(true) end
    flyout.bg = flyout:CreateTexture(nil, "BACKGROUND")
    flyout.bg:SetAllPoints()
    flyout.edges = MakeEdges(flyout, "BORDER")
    StyleFlyout(flyout)
    flyout:SetScript("OnEnter", function(self) SetOver(self, true) end)
    flyout:SetScript("OnLeave", function(self) SetOver(self, false) end)
    flyout:SetScript("OnUpdate", function(self, elapsed)
        if self.sticky then return end          -- opened by /amac flyout test
        if AnyOver() then
            self.idle = 0
        else
            self.idle = (self.idle or 0) + elapsed
            if self.idle > Style("closeDelay") then self:Hide() end
        end
    end)
    -- a click anywhere else closes it too
    flyout:SetScript("OnEvent", function(self)
        if self.sticky then return end
        if self:IsShown() and not AnyOver() then self:Hide() end
    end)
    pcall(flyout.RegisterEvent, flyout, "GLOBAL_MOUSE_DOWN")
    if UISpecialFrames then table.insert(UISpecialFrames, "AutoMacrosFlyout") end
    flyout:Hide()
    return flyout
end

local function Entry(i)
    local e = entries[i]
    if e then return e end
    e = CreateFrame("Button", nil, flyout)
    e:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    e.border = e:CreateTexture(nil, "BACKGROUND")
    e.border:SetAllPoints()
    e.icon = e:CreateTexture(nil, "ARTWORK")
    e.icon:SetPoint("TOPLEFT", 2, -2)
    e.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    local ok, fs = pcall(e.CreateFontString, e, nil, "OVERLAY", "NumberFontNormal")
    if not ok or not fs then fs = e:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") end
    fs:SetPoint("BOTTOMRIGHT", -3, 3)
    e.count = fs
    e.hl = e:CreateTexture(nil, "HIGHLIGHT")
    e.hl:SetAllPoints()
    e:SetScript("OnClick", function(self)
        local m = flyout.macro
        if not m then return end
        if m.preview then flyout:Hide() return end
        -- the best item is what "automatic" already uses, so picking it clears the choice
        local list = flyoutItems[m.name]
        local automatic = list and list[1] and list[1].id == self.itemID
        ChooseItem(m, (not automatic) and self.itemID or nil)
        flyout:Hide()
    end)
    e:SetScript("OnEnter", function(self)
        SetOver(self, true)
        if self.kind == "spell" then
            ShowSpellTooltip(self, self.itemID)
        else
            ShowItemTooltip(self, self.itemID, self.loc)
        end
    end)
    e:SetScript("OnLeave", function(self)
        SetOver(self, false)
        GameTooltip:Hide()
    end)
    StyleEntry(e)
    entries[i] = e
    return e
end

-- sizes and places the item buttons and the popup from the saved style
local function LayoutFlyout()
    if not flyout then return end
    local size, gap = Style("entrySize"), Style("entrySpacing")
    local n = flyout.count or 0
    for i = 1, n do
        local e = entries[i]
        if e then
            e:SetSize(size, size)
            e:ClearAllPoints()
            e:SetPoint("BOTTOM", flyout, "BOTTOM", 0, 4 + (i - 1) * (size + gap))   -- best nearest the button
        end
    end
    flyout:SetSize(size + 8, 8 + n * (size + gap) - gap)
end

-- button is the action button to open over (nil: middle of the screen, for
-- /amac flyout test). source is the frame the mouse is on. toggle closes the
-- popup if it is already open for this button (clicking the tab).
local function OpenFlyout(button, m, source, toggle)
    local list = flyoutItems[m.name]
    if not list or #list < 2 then return end
    BuildFlyout()
    if button and flyout:IsShown() and flyout.button == button and flyout.macro == m then
        if toggle then flyout:Hide() else SetOver(source, true) end
        return
    end
    flyout.macro, flyout.button = m, button
    flyout.over = {}
    flyout.sticky = (button == nil)
    SetOver(source, true)
    local chosen = m.previewChosen or Chosen(m, list)
    local n = math.min(#list, MAX_ENTRIES)
    for i = 1, n do
        local e = Entry(i)
        local isSpell = m.kind == "spells"
        e.kind = isSpell and "spell" or "item"
        e.itemID = list[i].id
        e.loc = (not isSpell) and lastLocs[list[i].id] or nil
        e.icon:SetTexture(isSpell and SpellIcon(list[i].id) or IconFor({ item = list[i].id }))
        local count = (not isSpell) and CountOf(list[i].id) or nil
        e.count:SetText((count and count > 1) and tostring(count) or "")
        e.selected = (list[i].id == chosen)               -- highlighted border: the one in use
        StyleEntry(e)
        e:Show()
    end
    for i = n + 1, #entries do entries[i]:Hide() end
    flyout.count = n
    LayoutFlyout()
    flyout:ClearAllPoints()
    if button then
        flyout:SetPoint("BOTTOM", arrows[button] or button, "TOP", 0, 0)
    else
        flyout:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    flyout.idle = 0
    flyout:Show()
end

local function SafeOpen(...)
    local ok, err = pcall(OpenFlyout, ...)
    if not ok then Print("flyout error: " .. tostring(err)) end
end

-- the macro on an action button, if it is one of ours
-- The macro on an action button, if it is one of ours. A macro with no
-- #showtooltip reports its own index; one whose #showtooltip resolves to an item
-- reports that item instead, so those are recognised by the macro's name, checked
-- against the macro we keep at the slot we remembered.
MacroOnButton = function(b)
    local ok, slot = pcall(ButtonSlot, b)
    if not (ok and slot) then return nil end
    local kind, id = GetActionInfo(slot)
    if kind ~= "macro" then return nil end
    local m = macroAt[id]
    if m then return m end
    local text = GetActionText and GetActionText(slot)
    if type(text) == "string" and text ~= "" then
        for idx, mm in pairs(macroAt) do
            local name = GetMacroInfo(idx)
            if name == text then return mm end
        end
    end
    return nil
end

local function OnButtonEnter(b)
    if DB().noFlyout then return end
    local m = MacroOnButton(b)
    if not m then return end
    local list = flyoutItems[m.name]
    if list and #list >= 2 then SafeOpen(b, m, b) end
end

local function OnButtonLeave(b)
    SetOver(b, false)
end

local function HookButton(b)
    if hooked[b] then return end
    hooked[b] = true
    pcall(b.HookScript, b, "OnEnter", OnButtonEnter)
    pcall(b.HookScript, b, "OnLeave", OnButtonLeave)
end

local function ArrowFor(button)
    local a = arrows[button]
    if a then return a end
    local ok, frame = pcall(CreateFrame, "Button", nil, button)
    if not ok or not frame then return nil end
    a = frame
    a.button = button
    a:SetFrameLevel((button:GetFrameLevel() or 1) + 12)
    a:SetPoint("BOTTOM", button, "TOP", 0, -3)
    a.tex = a:CreateTexture(nil, "OVERLAY")
    a.tex:SetAllPoints()
    StyleArrow(a, false)
    a:RegisterForClicks("LeftButtonUp")
    a:SetScript("OnClick", function(self)
        if self.macro then SafeOpen(self.button, self.macro, self, true) end
    end)
    a:SetScript("OnEnter", function(self)
        StyleArrow(self, true)
        if self.macro and not DB().noFlyout then SafeOpen(self.button, self.macro, self) end
    end)
    a:SetScript("OnLeave", function(self)
        StyleArrow(self, false)
        SetOver(self, false)
    end)
    a:Hide()
    arrows[button] = a
    return a
end

-- The macro name drawn on a button is a text on the button, so it can be hidden
-- there without touching the macro. Only buttons holding one of our macros are
-- touched, and their label is restored if the macro is moved off them.
local hiddenLabel = {}   -- action button -> its label, while we are hiding it

local function LabelOf(b)
    local candidates = { b.Name }
    local bn = b.GetName and b:GetName()
    if bn then candidates[#candidates + 1] = _G[bn .. "Name"] end
    candidates[#candidates + 1] = b.macro
    candidates[#candidates + 1] = b.MacroName
    for _, fs in pairs(candidates) do
        if type(fs) == "table" and fs.SetAlpha and fs.GetObjectType and fs:GetObjectType() == "FontString" then
            return fs
        end
    end
    return nil
end

local function ApplyLabel(b, mine)
    if mine and not DB().showNames then
        local fs = hiddenLabel[b] or LabelOf(b)
        if fs then
            fs:SetAlpha(0)
            hiddenLabel[b] = fs
        end
    elseif hiddenLabel[b] then
        hiddenLabel[b]:SetAlpha(1)
        hiddenLabel[b] = nil
    end
end

RefreshArrows = function()
    local enabled = DB().noFlyout ~= true
    local tabs = 0
    report.onBar = {}
    for _, b in ipairs(buttons) do
        HookButton(b)
        local mine = MacroOnButton(b)
        ApplyLabel(b, mine)
        local m = enabled and mine or nil
        if m then report.onBar[m.name] = (report.onBar[m.name] or 0) + 1 end
        local list = m and flyoutItems[m.name]
        if list and #list >= 2 then
            local a = ArrowFor(b)
            if a then
                a.macro = m
                a:Show()
                tabs = tabs + 1
            end
        else
            local a = arrows[b]
            if a then
                a.macro = nil
                a:Hide()
            end
        end
    end
    report.tabs = tabs
    if flyout and flyout:IsShown() and flyout.button then
        local list = flyout.macro and flyoutItems[flyout.macro.name]
        if not list or #list < 2 or not enabled then flyout:Hide() end
    end
end

-- ---------------------------------------------------------------------------
-- Look and feel, and the options window. ApplyStyle redraws everything that
-- has been built (highlights, tabs, popup) after a setting changes.
-- ---------------------------------------------------------------------------
local StyleOptions   -- defined below

ApplyStyle = function()
    for button, g in pairs(glows) do StyleGlow(g, button) end
    for button, a in pairs(arrows) do StyleArrow(a, false) end
    if flyout then
        StyleFlyout(flyout)
        for _, e in ipairs(entries) do StyleEntry(e) end
        LayoutFlyout()
    end
    if StyleOptions then StyleOptions() end
end

-- A popup with made-up potions, to see the styling without needing items.
local PREVIEW = { name = "AM_Preview", title = "Preview", label = "preview", preview = true, previewChosen = 929 }

local function PreviewFlyout(anchor)
    flyoutItems[PREVIEW.name] = { { id = 118 }, { id = 929 }, { id = 1710 }, { id = 3928 } }
    if flyout and flyout:IsShown() then flyout:Hide() end
    OpenFlyout(nil, PREVIEW, nil)
    if anchor and flyout and flyout:IsShown() then
        flyout:ClearAllPoints()
        flyout:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
    end
end

local function Refresh()
    pcall(SafeCollect)
    Update()
end

-- ---- small widgets (no templates, so they look the same on every client) ----
local ROW = 26

local function MakeLabel(parent, text, x, y, w)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(w or 180)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

local function Box(b)   -- grey outline with a dark inside
    local edge = b:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints()
    edge:SetColorTexture(0.5, 0.5, 0.5, 1)
    local inner = b:CreateTexture(nil, "BORDER")
    inner:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    inner:SetColorTexture(0.05, 0.05, 0.05, 1)
    return inner
end

local function MakeToggle(parent, x, y, get, set)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(18, 18)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    Box(b)
    local tick = b:CreateTexture(nil, "ARTWORK")
    tick:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
    tick:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
    b.refresh = function()
        local r, g, bl = AccentRGB()
        tick:SetColorTexture(r, g, bl, 1)
        if get() then tick:Show() else tick:Hide() end
    end
    b:SetScript("OnClick", function() set(not get()); b.refresh() end)
    b.refresh()
    return b
end

local function MakeSlider(parent, x, y, width, min, max, step, get, set)
    local s = CreateFrame("Frame", nil, parent)
    s:SetSize(width, 18)
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:EnableMouse(true)
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", s, "LEFT", 0, 0)
    track:SetPoint("RIGHT", s, "RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.25, 0.25, 0.25, 1)
    local fill = s:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", s, "LEFT", 0, 0)
    fill:SetHeight(4)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 14)
    local value = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("LEFT", s, "RIGHT", 8, 0)
    local fmt = (step >= 1) and "%d" or (step >= 0.1) and "%.1f" or "%.2f"
    local function paint(v)
        local frac = (max > min) and (v - min) / (max - min) or 0
        if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
        local r, g, b = AccentRGB()
        fill:SetColorTexture(r, g, b, 1)
        fill:SetWidth(math.max(1, frac * width))
        thumb:SetColorTexture(1, 1, 1, 1)
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", s, "LEFT", frac * width, 0)
        value:SetText(string.format(fmt, v))
    end
    local function fromCursor()
        local scale = s:GetEffectiveScale() or 1
        local cx = (GetCursorPosition() or 0) / scale
        local frac = (cx - (s:GetLeft() or 0)) / width
        if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
        local v = min + frac * (max - min)
        v = math.floor(v / step + 0.5) * step
        v = tonumber(string.format("%.4f", v))
        if v < min then v = min elseif v > max then v = max end
        paint(v)
        if v ~= s.last then
            s.last = v
            set(v)
        end
    end
    s:SetScript("OnMouseDown", function(self) self.drag = true; fromCursor() end)
    s:SetScript("OnMouseUp", function(self) self.drag = nil end)
    s:SetScript("OnHide", function(self) self.drag = nil end)
    s:SetScript("OnUpdate", function(self)
        if not self.drag then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then self.drag = nil return end
        fromCursor()
    end)
    s.refresh = function()
        local v = tonumber(get()) or min
        s.last = v
        paint(v)
    end
    s.refresh()
    return s
end

-- the colour picker differs between client versions, so both forms are handled
local function PickColor(r, g, b, onChange, onCancel)
    local function read()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        onChange(nr, ng, nb)
    end
    local function cancel()
        if onCancel then onCancel() else onChange(r, g, b) end
    end
    pcall(function() ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG") end)
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false, swatchFunc = read, cancelFunc = cancel })
    else
        ColorPickerFrame.func = read
        ColorPickerFrame.cancelFunc = cancel
        ColorPickerFrame.opacityFunc = nil
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = { r = r, g = g, b = b }
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

local MakeChoice   -- defined below

-- One colour setting: a box that cycles Default / EllesmereUI accent / Custom,
-- a swatch with the colour in use (clicking it picks a custom colour) and, for
-- colours that can be see-through, an opacity slider.
local function MakeColor(parent, x, y, key, hasAlpha)
    local b
    local mode = MakeChoice(parent, x, y, 120, ColorModeChoices,
        function() return ColorMode(key) end,
        function(v) SetStyle(key .. "Mode", v); if b then b.refresh() end end)
    b = CreateFrame("Button", nil, parent)
    b:SetSize(36, 18)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 128, y)
    local inner = Box(b)
    local sw = b:CreateTexture(nil, "ARTWORK")
    sw:SetPoint("TOPLEFT", inner, "TOPLEFT", 1, -1)
    sw:SetPoint("BOTTOMRIGHT", inner, "BOTTOMRIGHT", -1, 1)
    local alpha
    b.refresh = function()
        mode.refresh()
        local c = StyleColor(key)
        sw:SetColorTexture(c[1], c[2], c[3], 1)
        if alpha then alpha.refresh() end
    end
    b:SetScript("OnClick", function()
        local c = StyleColor(key)
        local s = DB().style
        local oldValue = type(s) == "table" and s[key] or nil
        local oldMode = type(s) == "table" and s[key .. "Mode"] or nil
        local ok, err = pcall(PickColor, c[1], c[2], c[3], function(r, g, bl)
            SetColor(key, r, g, bl)
            b.refresh()
        end, function()   -- cancelled: put back what was saved before
            SetStyle(key, oldValue)
            SetStyle(key .. "Mode", oldMode)
            b.refresh()
        end)
        if not ok then Fail("colour picker", err) end
    end)
    if hasAlpha then
        alpha = MakeSlider(parent, x + 174, y, 80, 0, 1, 0.05,
            function() return Style(key)[4] or 1 end,
            function(v)
                PinMode(key)
                local c = Style(key)
                SetStyle(key, { c[1], c[2], c[3], v })
            end)
    end
    b.refresh()
    return b
end

MakeChoice = function(parent, x, y, width, list, get, set)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 18)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    Box(b)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local function index(l)
        local cur = get()
        for i, v in ipairs(l) do
            if v.key == cur then return i end
        end
        return 1
    end
    b.refresh = function()
        local l = list()
        local v = l[index(l)]
        fs:SetText(v and v.label or "?")
    end
    b:SetScript("OnClick", function(self, button)
        local l = list()
        local i = index(l)
        if button == "RightButton" then
            i = i - 1
            if i < 1 then i = #l end
        else
            i = i + 1
            if i > #l then i = 1 end
        end
        set(l[i].key)
        self.refresh()
    end)
    b.refresh()
    return b
end

local function MakeButton(parent, x, y, width, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 22)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local inner = Box(b)
    inner:SetColorTexture(0.15, 0.15, 0.15, 1)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    fs:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

-- A sample action button, so a change can be seen on the spot.
local function MakePreview(parent, x, y, kind)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(36, 36)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 10, y - 16)
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(IconFor({ item = 929 }))
    if kind == "glow" then
        ShowGlow(f, true)
    else
        local a = ArrowFor(f)
        if a then a:Show() end
    end
    return f
end

-- ---- the settings, in groups shown one after another on a single page ----
local function SToggle(label, key)
    return { type = "toggle", label = label,
        get = function() return Style(key) and true or false end,
        set = function(v) SetStyle(key, v) end }
end

local function LearnedSummary()
    local learned = DB().learned
    local n, auto, lines = 0, 0, {}
    if type(learned) == "table" then
        local ids = {}
        for id in pairs(learned) do ids[#ids + 1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local rec = learned[id]
            n = n + 1
            if type(rec) ~= "table" or rec.how ~= "manual" then auto = auto + 1 end
            if #lines < 4 and type(rec) == "table" then
                local t = {}
                for _, s in ipairs(rec.sets or {}) do t[#t + 1] = (SetTitle(s)) end
                lines[#lines + 1] = ItemRef(id) .. " - " .. table.concat(t, ", ")
            end
        end
    end
    local head = string.format("Learned items: %d (%d automatic, %d by hand). /amac learned lists them all.", n, auto, n - auto)
    return head .. (#lines > 0 and ("\n" .. table.concat(lines, "\n")) or "")
end

local GROUPS = {
    { name = "Highlight", preview = "glow", items = {
        { type = "toggle", label = "Highlight empty buttons",
            get = function() return DB().glow ~= false end,
            set = function(v) DB().glow = v; RefreshGlow() end },
        { type = "color", label = "Colour", key = "glowColor", alpha = true },
        { type = "range", label = "Thickness", key = "glowThickness", min = 1, max = 8, step = 1 },
        { type = "choice", label = "Texture", key = "glowTexture", list = function() return TextureChoices(true) end },
        SToggle("Pulse", "glowPulse"),
        { type = "range", label = "Pulse time (seconds)", key = "glowSpeed", min = 0.2, max = 2, step = 0.1 },
    } },
    { name = "Tab", preview = "tab", items = {
        { type = "toggle", label = "Open the flyout on hover",
            get = function() return not DB().noFlyout end,
            set = function(v) DB().noFlyout = not v; Refresh() end },
        { type = "color", label = "Tab colour", key = "tabColor", alpha = true },
        { type = "color", label = "Tab colour on hover", key = "tabHoverColor", alpha = true },
        { type = "range", label = "Tab width", key = "tabWidth", min = 8, max = 40, step = 1 },
        { type = "range", label = "Tab height", key = "tabHeight", min = 3, max = 16, step = 1 },
        { type = "choice", label = "Tab texture", key = "tabTexture", list = function() return TextureChoices(false) end },
    } },
    { name = "Popup", items = {
        { type = "button", label = "Show a preview popup", action = function(anchor) PreviewFlyout(anchor) end },
        { type = "color", label = "Background", key = "flyoutBg", alpha = true },
        { type = "color", label = "Border", key = "flyoutBorderColor", alpha = true },
        { type = "range", label = "Border size", key = "flyoutBorderSize", min = 0, max = 4, step = 1 },
        { type = "range", label = "Item size", key = "entrySize", min = 24, max = 56, step = 1 },
        { type = "range", label = "Item spacing", key = "entrySpacing", min = 0, max = 10, step = 1 },
        { type = "color", label = "Item border", key = "entryBorderColor", alpha = true },
        { type = "color", label = "Chosen item border", key = "selectedColor", alpha = true },
        { type = "color", label = "Item hover", key = "entryHover", alpha = true },
        { type = "range", label = "Close delay (seconds)", key = "closeDelay", min = 0.1, max = 1.5, step = 0.1 },
    } },
    { name = "General", items = {
        { type = "toggle", label = "Clean \"No X in inventory\" tooltip",
            get = function() return not DB().stockTooltip end, set = function(v) DB().stockTooltip = not v end },
        { type = "color", label = "Empty tooltip colour", key = "tooltipColor" },
        { type = "toggle", label = "Hide macro names on buttons",
            get = function() return not DB().showNames end,
            set = function(v) DB().showNames = not v; Refresh() end },
        { type = "toggle", label = "Learn new items automatically",
            get = function() return not DB().learnOff end,
            set = function(v) DB().learnOff = (not v) or nil; if v then Update() end end },
        { type = "text", text = LearnedSummary },
        { type = "eui", items = {
            SToggle("Use EllesmereUI styling", "euiSkin"),
        } },
        { type = "button", label = "Reset appearance", action = function() ResetStyle() end, refreshAll = true },
    } },
}

-- Re-reads the values shown on our EllesmereUI page while it is on screen.
local function RefreshEUIPage()
    local E = EllesmereUI
    if not (E and E.RefreshPage and E.GetActiveModule and E.GetPluginModuleKey) then return end
    pcall(function()
        if E:GetActiveModule() == E.GetPluginModuleKey("AutoMacros", "options") then E:RefreshPage() end
    end)
end

-- Builds one group of settings into parent, starting at y0 (negative = down),
-- and returns the y below its last row. native: parent is an EllesmereUI page,
-- so EllesmereUI's own widgets are used (any that fail fall back to ours).
local function BuildPage(parent, group, x0, y0, native)
    local y = y0
    parent.amRefreshers = parent.amRefreshers or {}
    local refreshers = parent.amRefreshers
    local W = native and EllesmereUI and EllesmereUI.Widgets or nil
    local prebuild = native and EllesmereUI.IsSearchPrebuild and EllesmereUI.IsSearchPrebuild()
    -- one EllesmereUI widget: returns its height, or nil when it could not be made
    local function Native(name, ...)
        if not (W and W[name]) then return nil end
        local ok, f, h = pcall(W[name], W, parent, ...)
        if ok and f then return (type(h) == "number") and h or 50 end
        return nil
    end
    local headerH = Native("SectionHeader", group.name, y)
    if headerH then
        y = y - headerH
    else
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y)
        title:SetText(group.name)
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y - 22)
        line:SetSize(480, 1)
        local function paintLine()
            local r, g, b = AccentRGB()
            line:SetColorTexture(r, g, b, 0.6)
        end
        paintLine()
        refreshers[#refreshers + 1] = paintLine
        y = y - 32
    end
    if group.preview and not prebuild then
        MakePreview(parent, x0, y, group.preview)
        local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", parent, "TOPLEFT", x0 + 70, y - 22)
        hint:SetWidth(300)
        hint:SetJustifyH("LEFT")
        hint:SetText("A sample button: changes show here straight away.")
        y = y - 62
    end
    local items = {}
    for _, item in ipairs(group.items) do
        if item.type == "eui" then
            if EllesmereUI then
                for _, sub in ipairs(item.items) do items[#items + 1] = sub end
            end
        else
            items[#items + 1] = item
        end
    end
    local ctlX = x0 + 190
    for _, item in ipairs(items) do
        local rowH
        if item.type == "toggle" then
            rowH = Native("Toggle", item.label, y, item.get, item.set)
            if not rowH then
                MakeLabel(parent, item.label, x0, y - 2)
                refreshers[#refreshers + 1] = MakeToggle(parent, ctlX, y, item.get, item.set).refresh
            end
        elseif item.type == "color" then
            local key = item.key
            local values, order = {}, {}
            for _, m in ipairs(ColorModeChoices()) do
                values[m.key] = m.label
                order[#order + 1] = m.key
            end
            -- mode on the left, the custom colour on the right; picking a
            -- colour there switches the mode to Custom
            rowH = Native("DualRow", y,
                { type = "dropdown", text = item.label, values = values, order = order,
                  getValue = function() return ColorMode(key) end,
                  setValue = function(v) SetStyle(key .. "Mode", v) end },
                { type = "colorpicker", text = "Custom colour", hasAlpha = item.alpha,
                  getValue = function() local c = Style(key); return c[1], c[2], c[3], c[4] or 1 end,
                  setValue = function(r, g, b, a)
                      SetColor(key, r, g, b, item.alpha and a or nil)
                      RefreshEUIPage()
                  end })
            if not rowH then
                MakeLabel(parent, item.label, x0, y - 2)
                refreshers[#refreshers + 1] = MakeColor(parent, ctlX, y, key, item.alpha).refresh
            end
        elseif item.type == "range" then
            local get = function() return Style(item.key) end
            local set = function(v) SetStyle(item.key, v) end
            rowH = Native("Slider", item.label, y, item.min, item.max, item.step, get, set)
            if not rowH then
                MakeLabel(parent, item.label, x0, y - 2)
                refreshers[#refreshers + 1] = MakeSlider(parent, ctlX, y, 130, item.min, item.max, item.step, get, set).refresh
            end
        elseif item.type == "choice" then
            local get = function() return Style(item.key) end
            local set = function(v) SetStyle(item.key, v) end
            local values, order = {}, {}
            for _, t in ipairs(item.list()) do
                values[t.key] = t.label
                order[#order + 1] = t.key
            end
            rowH = Native("Dropdown", item.label, y, values, get, set, order)
            if not rowH then
                MakeLabel(parent, item.label, x0, y - 2)
                refreshers[#refreshers + 1] = MakeChoice(parent, ctlX, y, 150, item.list, get, set).refresh
            end
        elseif item.type == "button" then
            local function after()
                if item.refreshAll then
                    if parent.amRefresh then parent.amRefresh() end
                    RefreshEUIPage()
                end
            end
            rowH = Native("Button", item.label, y, function() item.action(nil); after() end)
            if not rowH then
                local b
                b = MakeButton(parent, x0, y, 170, item.label, function() item.action(b); after() end)
                rowH = 30
            end
        elseif item.type == "text" then
            local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y - 2)
            fs:SetWidth(380)
            fs:SetJustifyH("LEFT")
            refreshers[#refreshers + 1] = function() fs:SetText(item.text()) end
            fs:SetText(item.text())
            rowH = 70
        end
        y = y - (rowH or ROW)
    end
    parent.amRefresh = function()
        for _, f in ipairs(refreshers) do f() end
    end
    return y
end

-- ---- the stand-alone window: /amac options ----
-- Every group is on one page, which scrolls with the mouse wheel.
local optionsPanel
local OPT_W, OPT_H = 540, 560

-- the thin bar on the right showing how far down the page is scrolled
local function UpdateScrollBar()
    local p = optionsPanel
    if not p then return end
    local scroll, bar = p.scroll, p.bar
    local range = scroll:GetVerticalScrollRange() or 0
    local h = scroll:GetHeight() or 0
    if range <= 0 or h <= 0 then bar:Hide() return end
    local bh = math.max(20, h * h / (h + range))
    local pos = (scroll:GetVerticalScroll() or 0) / range
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, -pos * (h - bh))
    bar:SetHeight(bh)
    local r, g, b = AccentRGB()
    bar:SetColorTexture(r, g, b, 0.8)
    bar:Show()
end

local function BuildOptions()
    if optionsPanel then return optionsPanel end
    local p = CreateFrame("Frame", "AutoMacrosOptions", UIParent)
    optionsPanel = p
    p:SetSize(OPT_W, OPT_H)
    p:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    p:SetFrameStrata("DIALOG")
    p:SetClampedToScreen(true)
    p:EnableMouse(true)
    p:SetMovable(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", function(self) self:StartMoving() end)
    p:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    p.bg = p:CreateTexture(nil, "BACKGROUND")
    p.bg:SetAllPoints()
    p.edges = MakeEdges(p, "BORDER")
    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -14)
    title:SetText("AutoMacros")
    local close = MakeButton(p, OPT_W - 16 - 24, -12, 24, "X", function() p:Hide() end)
    local scroll = CreateFrame("ScrollFrame", nil, p)
    scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -48)
    scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -24, 16)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(OPT_W - 40, 10)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        local v = (self:GetVerticalScroll() or 0) - delta * 40
        if v > range then v = range end
        if v < 0 then v = 0 end
        self:SetVerticalScroll(v)
        UpdateScrollBar()
    end)
    p.scroll, p.content = scroll, content
    p.bar = p:CreateTexture(nil, "ARTWORK")
    p.bar:SetWidth(3)
    p.bar:Hide()
    p:SetScript("OnShow", function()
        if not content.built then
            content.built = true
            local y = 0
            for _, group in ipairs(GROUPS) do
                y = BuildPage(content, group, 0, y, false) - 14
            end
            content:SetHeight(-y)
        end
        if content.amRefresh then content.amRefresh() end
        UpdateScrollBar()
        -- the scroll range is only known once the page has been laid out
        if C_Timer and C_Timer.After then C_Timer.After(0, UpdateScrollBar) end
    end)
    p:SetScript("OnHide", function()
        if flyout and flyout:IsShown() and flyout.macro == PREVIEW then flyout:Hide() end
    end)
    if UISpecialFrames then table.insert(UISpecialFrames, "AutoMacrosOptions") end
    p:Hide()
    StyleOptions()
    return p
end

StyleOptions = function()
    local p = optionsPanel
    if not p then return end
    local skinned = false
    if SkinActive() and skin.Panel then skinned = pcall(skin.Panel, p, {}) end
    if skinned then
        p.bg:Hide()
        for i = 1, 4 do p.edges[i]:Hide() end
    else
        p.bg:Show()
        p.bg:SetColorTexture(0.06, 0.06, 0.06, 0.96)
        for i = 1, 4 do p.edges[i]:SetColorTexture(0.4, 0.4, 0.4, 1) end
        PlaceEdges(p.edges, p, 1)
    end
    if p:IsShown() then
        if p.content.amRefresh then p.content.amRefresh() end
        UpdateScrollBar()
    end
end

-- ---- EllesmereUI: a page in its settings, and its look for the popup ----
-- Only the published EllesmereUI interfaces are used (RegisterSkin and
-- RegisterPlugin); everything is wrapped so a change on their side cannot
-- break this addon.
local skinRegistered, pluginRegistered = false, false

local function RegisterEUI()
    if not EllesmereUI then return end
    if not skinRegistered and EllesmereUI.RegisterSkin then
        skinRegistered = true
        local ok, err = pcall(EllesmereUI.RegisterSkin, "AutoMacros", function(S)
            skin = S
            if S.OnLooksChanged then pcall(S.OnLooksChanged, function() ApplyStyle() end) end
            ApplyStyle()
        end)
        if not ok then Fail("EllesmereUI skin", err) end
    end
    if not pluginRegistered and EllesmereUI.RegisterPlugin then
        pluginRegistered = true
        local ok, res = pcall(EllesmereUI.RegisterPlugin, "AutoMacros", {
            label = "AutoMacros",
            position = "bottom",
            modules = { {
                key = "options",
                title = "AutoMacros",
                description = "Empty-button highlight, flyout tab, popup and item learning",
                pages = { "Settings" },   -- one page with every group, no tabs
                buildPage = function(_, parent, yOffset)
                    local y = yOffset or 0
                    for _, group in ipairs(GROUPS) do
                        local ok2, newY = pcall(BuildPage, parent, group, 20, y, true)
                        if not ok2 then
                            Fail("EllesmereUI page", newY)
                            break
                        end
                        y = newY
                    end
                    return math.abs(y)
                end,
                onReset = function() ResetStyle(); RefreshEUIPage() end,
            } },
        })
        -- (a refused spec returns false and EllesmereUI reports why; trying
        -- again would only be refused again, so that is left alone)
        if not ok then
            pluginRegistered = false
            Fail("EllesmereUI page", res)
        end
    end
end
pcall(RegisterEUI)

local function OpenOptions(standalone)
    if not standalone and pluginRegistered and EllesmereUI and EllesmereUI.OpenPlugin then
        local ok, opened = pcall(EllesmereUI.OpenPlugin, "AutoMacros")
        if ok and opened then return end
    end
    local p = BuildOptions()
    if p:IsShown() then p:Hide() else p:Show() end
end

local function Schedule()
    if timerSet then return end
    timerSet = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, Update)
    else
        Update()
    end
end

-- Bar events only need the highlight redrawn, not the macros rewritten.
local function ScheduleGlow()
    if glowTimerSet then return end
    glowTimerSet = true
    local function run()
        glowTimerSet = false
        RefreshGlow()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.3, run) else run() end
end

-- Runs once per login. The saved data is already loaded by now.
local function Init()
    local db = DB()
    report.priorSessions = tonumber(db.sessions) or 0
    db.sessions = report.priorSessions + 1
    if (tonumber(db.schema) or 0) < SCHEMA then
        db.schema = SCHEMA   -- version 2 added style, learned and ignored; older data needs no conversion
    end
    if db.classifier ~= CLASSIFIER then
        -- the learning rules changed: forget automatic results, keep hand-made ones
        if type(db.learned) == "table" then
            for id, rec in pairs(db.learned) do
                if type(rec) ~= "table" or rec.how ~= "manual" then db.learned[id] = nil end
            end
        end
        db.ignored = nil
        db.classifier = CLASSIFIER
    end
    pcall(RegisterEUI)   -- in case EllesmereUI loaded after this addon
end

local BAR_EVENTS = {
    ACTIONBAR_SLOT_CHANGED = true, ACTIONBAR_PAGE_CHANGED = true,
    UPDATE_BONUS_ACTIONBAR = true, UPDATE_SHAPESHIFT_FORM = true,
}

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local ok, err = pcall(Init)
        if not ok then Fail("startup", err) end
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if pending then Schedule() end
    elseif BAR_EVENTS[event] then
        ScheduleGlow()
    else
        if event == "PLAYER_ENTERING_WORLD" and C_Timer and C_Timer.After then
            -- bar addons build their buttons a moment after login
            C_Timer.After(3, function()
                SafeCollect()
                local ok, err = pcall(RefreshGlow)
                if not ok then Fail("highlight/flyout", err) end
            end)
        end
        Schedule()
    end
end)
for _, event in ipairs({
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED",
    "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP",
    "GET_ITEM_INFO_RECEIVED",
    "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED",
    "UPDATE_BONUS_ACTIONBAR", "UPDATE_SHAPESHIFT_FORM",
}) do
    pcall(frame.RegisterEvent, frame, event)   -- skip events this client lacks
end

SLASH_AUTOMACROS1 = "/automacros"
SLASH_AUTOMACROS2 = "/amac"
SlashCmdList["AUTOMACROS"] = function(msg)
    msg = msg and msg:lower() or ""
    local function find(key)
        for _, e in ipairs(ALL) do
            if e.key == key then return e end
        end
    end
    if msg:match("^%s*list") then
        pcall(RebuildMacros)
        for _, e in ipairs(ALL) do
            local on = Enabled(e) and (not e.class or select(2, UnitClass("player")) == e.class)
            Print(string.format("%s %s - %s (%s tab%s)%s", on and "[on] " or "[off]", e.key, e.title,
                e.scope == "character" and "character" or "general", e.class and (", " .. e.class:lower() .. " only") or "",
                e.custom and " - custom" or ""))
        end
        Print("/amac add <name>, /amac remove <name>, /amac custom <name> <items|spells> <id,id,...>")
        Print("/amac options, /amac assign <item> <name>, /amac unassign <item>, /amac learned, /amac status")
        return
    elseif msg:match("^%s*add%s+") or msg:match("^%s*remove%s+") then
        local verb, key = msg:match("^%s*(%a+)%s+(%S+)")
        local e = find(key)
        if not e then
            Print("no category called " .. key .. " - /amac list shows them")
            return
        end
        local db = DB()
        db.enabled = db.enabled or {}
        db.enabled[e.key] = (verb == "add")
        Print(e.title .. (verb == "add" and ": on" or ": off (its macro is left where it is)"))
        if verb == "add" and e.class and select(2, UnitClass("player")) ~= e.class then
            Print(e.title .. " is a " .. e.class:lower() .. " button, so it will not appear on this character")
        end
    elseif msg:match("^%s*custom%s+") then
        local name, rest = msg:match("^%s*custom%s+([%w_]+)%s*(.*)$")
        local db = DB()
        if not name then
            Print("usage: /amac custom <name> <items|spells> <id,id,...>   or   /amac custom <name> delete")
            return
        end
        if rest:match("^delete") then
            if db.custom then db.custom[name] = nil end
            Print("custom category " .. name .. " removed (its macro is left where it is)")
        else
            local kind, idtext = rest:match("^(%a+)%s+(.+)$")
            kind = kind and (kind:sub(1, 5) == "spell" and "spells" or kind:sub(1, 4) == "item" and "items" or nil)
            local ids = {}
            for n in (idtext or ""):gmatch("%d+") do ids[#ids + 1] = tonumber(n) end
            if not kind or #ids == 0 then
                Print("usage: /amac custom <name> <items|spells> <id,id,...>   (example: /amac custom jungle items 2633,3386)")
                return
            end
            db.custom = db.custom or {}
            db.custom[name] = { title = name:sub(1, 1):upper() .. name:sub(2), kind = kind, ids = ids }
            Print("custom category " .. name .. ": " .. #ids .. " " .. kind .. " - it appears on your next update")
        end
    elseif msg:match("^%s*options") or msg:match("^%s*config") or msg:match("^%s*opt") then
        local ok, err = pcall(OpenOptions, msg:find("classic", 1, true) ~= nil or msg:find("standalone", 1, true) ~= nil)
        if not ok then Fail("options window", err) end
        return
    elseif msg:match("^%s*style%s+reset") then
        ResetStyle()
        Print("look and feel back to the defaults")
        return
    elseif msg:match("^%s*assign%s+") or msg:match("^%s*unassign%s+") then
        local verb, rest = msg:match("^%s*(%a+)%s+(.+)$")
        local id = tonumber(rest:match("item:(%d+)")) or tonumber(rest:match("%d+"))
        if not id then
            Print("usage: /amac assign <item id or item link> <category>   or   /amac unassign <item id or link>")
            return
        end
        local db = DB()
        if verb == "unassign" then
            if type(db.learned) == "table" then db.learned[id] = nil end
            if type(db.ignored) ~= "table" then db.ignored = {} end
            db.ignored[id] = CLASSIFIER   -- and do not learn it again by itself
            RebuildLearned()
            Print(ItemRef(id) .. " [" .. id .. "] removed from the learned items")
        else
            local keyword = rest:gsub("|c%x+|hitem:[^|]*|h%[.-%]|h|r", " "):match("%a[%w_]*")
            local e = keyword and find(keyword)
            if not e or not e.set then
                Print("assign needs an item category: " .. "/amac list shows them (spell categories cannot take items)")
                return
            end
            if type(db.learned) ~= "table" then db.learned = {} end
            local rec = db.learned[id]
            if type(rec) ~= "table" or rec.how ~= "manual" then rec = { sets = {}, how = "manual" } end
            local have = false
            for _, s in ipairs(rec.sets) do if s == e.set then have = true end end
            if not have then rec.sets[#rec.sets + 1] = e.set end
            db.learned[id] = rec
            if type(db.ignored) == "table" then db.ignored[id] = nil end
            RebuildLearned()
            Print(ItemRef(id) .. " [" .. id .. "] now counts as " .. e.title .. (Enabled(e) and "" or (" (the button is off: /amac add " .. e.key .. ")")))
        end
    elseif msg:match("^%s*learned") then
        local learned = DB().learned
        local ids = {}
        if type(learned) == "table" then for id in pairs(learned) do ids[#ids + 1] = id end end
        table.sort(ids)
        if #ids == 0 then
            Print("nothing learned yet - items missing from the built-in lists are sorted as you pick them up")
        else
            for i, id in ipairs(ids) do
                local rec = learned[id]
                local t = {}
                for _, s in ipairs(rec.sets or {}) do t[#t + 1] = (SetTitle(s)) end
                Print(string.format("[%d] %s - %s (%s)", id, ItemRef(id), table.concat(t, ", "), rec.how or "?"))
                if i >= 30 then Print("(first 30 shown of " .. #ids .. ")") break end
            end
        end
        return
    elseif msg:match("^%s*learn") then
        local db = DB()
        if msg:find("off", 1, true) then db.learnOff = true
        elseif msg:find("on", 1, true) then db.learnOff = nil
        else db.learnOff = (not db.learnOff) or nil end
        Print("learning new items: " .. (db.learnOff and "off" or "on"))
        return
    elseif msg:match("^%s*status") then
        local db = DB()
        local n = 0
        if type(db.learned) == "table" then for _ in pairs(db.learned) do n = n + 1 end end
        local styled = 0
        if type(db.style) == "table" then for _ in pairs(db.style) do styled = styled + 1 end end
        Print(string.format("saved data: schema %s, loaded %s time(s) (%s)", tostring(db.schema), tostring(db.sessions),
            (report.priorSessions or 0) > 0 and "restored from the last session" or "new, or not restored from the last session"))
        Print(string.format("style settings changed: %d, learned items: %d, EllesmereUI: %s", styled, n,
            skin and "styling the popup" or (EllesmereUI and "found, not skinning (turn it on in EllesmereUI)" or "not installed")))
        return
    elseif msg:match("^%s*next") then
        local name = NextScroll()
        Print(name and ("Comprehend button: " .. name) or "fewer than two untranslated scrolls in your bags")
    elseif msg:match("^%s*items") then
        Update()
        local ids = {}
        for id in pairs(lastLocs) do ids[#ids + 1] = id end
        table.sort(ids)
        local shown = 0
        for _, id in ipairs(ids) do
            local info = ItemClassInfo(id)
            if info:find("class=0 ", 1, true) or info:find("class=nil", 1, true) or info:find("no ", 1, true) then
                Print(string.format("[%d] %s: %s - %s", id, ItemRef(id), info, TooltipSummary(id)))
                shown = shown + 1
                if shown >= 20 then Print("(first 20 shown)") break end
            end
        end
        if shown == 0 then Print("no consumables found in your bags") end
        return
    elseif msg:match("^%s*debug") then
        SafeCollect()
        Update()
        Print(string.format("frame walk: %s, frames seen: %d, action buttons found: %d",
            EnumerateFrames and "available" or "NOT available", report.enumerated or 0, #buttons))
        local shown = 0
        for _, b in ipairs(buttons) do
            local ok, slot = pcall(ButtonSlot, b)
            local kind, id
            if ok and slot then kind, id = GetActionInfo(slot) end
            if kind == "macro" or shown < 3 then
                local name = b.GetName and b:GetName() or "unnamed"
                local text = (kind == "macro" and GetActionText) and GetActionText(slot) or nil
                local mine = kind == "macro" and MacroOnButton(b) or nil
                Print(string.format("  button %s: slot %s holds %s %s%s%s", tostring(name), tostring(slot),
                    tostring(kind), tostring(id), text and (' named "' .. tostring(text) .. '"') or "",
                    mine and (" = ours: " .. mine.title) or ""))
                shown = shown + 1
            end
            if shown >= 8 then break end
        end
        for _, m in ipairs(MACROS) do
            local saved = DB().idx and DB().idx[CharKey()] and DB().idx[CharKey()][m.name]
            local list = flyoutItems[m.name]
            Print(string.format("  %s: macro slot %s, %s item(s), on a bar %dx", m.title, tostring(saved),
                list and #list or "?", (report.onBar and report.onBar[m.name]) or 0))
        end
        local probe = _G["ActionButton1"]
        if probe then
            local a = probe.GetAttribute and probe:GetAttribute("action")
            Print(string.format("  ActionButton1: .action=%s attribute=%s GetAction=%s",
                tostring(probe.action), tostring(a), probe.GetAction and "yes" or "no"))
        else
            Print("  ActionButton1 does not exist")
        end
        Print(string.format("  saved data: schema %s, session %s, restored %s", tostring(DB().schema),
            tostring(DB().sessions), (report.priorSessions or 0) > 0 and "yes" or "no"))
        Print("  last error: " .. tostring(report.lastError))
        return
    elseif msg:match("^%s*flyout%s+test") then
        Update()
        local opened = false
        for _, m in ipairs(MACROS) do
            local list = flyoutItems[m.name]
            if not opened and list and #list >= 2 then
                local ok, err = pcall(OpenFlyout, nil, m, nil)
                Print(ok and ("test popup opened for " .. m.title .. " (" .. #list .. " items)")
                    or ("test popup failed: " .. tostring(err)))
                opened = true
            end
        end
        if not opened then Print("no category has two or more items in your bags") end
    elseif msg:match("^%s*flyout") then
        local db = DB()
        db.noFlyout = not db.noFlyout
        Print("item flyout tabs: " .. (db.noFlyout and "off" or "on"))
    elseif msg:match("^%s*names") then
        local db = DB()
        db.showNames = not db.showNames
        Print("macro names on the buttons: " .. (db.showNames and "shown" or "hidden"))
    elseif msg:match("^%s*tooltip") then
        local db = DB()
        db.stockTooltip = not db.stockTooltip
        Print("empty-button tooltip: " .. (db.stockTooltip and "stock (shows the macro text)" or "clean message"))
    elseif msg:match("^%s*glow") then
        local db = DB()
        db.glow = (db.glow == false)   -- on by default; this flips it
        Print("empty-button highlight: " .. (db.glow == false and "off" or "on"))
    end
    SafeCollect()   -- also rescans the action bars
    if InCombatLockdown() then
        Print("in combat - macros update when combat ends")
        Update()   -- still refreshes the highlight; macros are left alone
        return
    end
    Update()
    if report.error then Print(report.error) return end
    for _, m in ipairs(MACROS) do
        local r = report[m.name]
        if r and r.result ~= "skipped" then
            local what = r.id and (ItemRef(r.id) .. " [" .. r.id .. "]") or "nothing in bags"
            Print(m.name .. ": " .. what .. " - " .. r.result .. " (" .. r.size .. "/255 bytes)")
        end
    end
    Print("action buttons found: " .. #buttons .. ", highlighted: " .. (report.glowing or 0) .. ", flyout tabs: " .. (report.tabs or 0))
    local parts = {}
    for _, m in ipairs(MACROS) do
        local list = flyoutItems[m.name]
        if list then
            parts[#parts + 1] = m.title .. ": " .. #list .. " item" .. (#list == 1 and "" or "s")
                .. ", on a bar " .. ((report.onBar and report.onBar[m.name]) or 0) .. "x"
        end
    end
    Print("flyout - " .. table.concat(parts, "; "))
end
