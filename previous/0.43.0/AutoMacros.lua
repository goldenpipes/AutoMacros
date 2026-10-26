-- AutoMacros 0.43.0 for WoW Forever (interface 16001; also loads in retail for testing)
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
-- AutoBar: Misc.Explosives.Engineering, Misc.Explosives.Other, Muffin.Explosives
DATA.explosives = ToSet({
    4358, 4360, 4365, 4370, 4374, 4378, 4380, 4384, 4390, 4394, 4403, 6714,
    10507, 10514, 10562, 10586, 15993, 16005, 16040, 18588, 18641, 23736, 23737, 23826,
    23827, 32413, 40536, 40771, 41119, 4598, 11566, 23841, 215127, 215168, 221325,
})
-- AutoBar: Muffin.Potion.Rage
DATA.rage = ToSet({
    5631, 5633, 13442, 54642, 116275, 118704, 144398,
})
-- AutoBar: Muffin.Food.Health.Buff, Muffin.Food.Mana.Buff, Muffin.Food.Combo.Buff
DATA.food_buff = ToSet({
    724, 733, 787, 1017, 1082, 2680, 2681, 2682, 2683, 2684, 2685, 2687,
    2888, 3220, 3662, 3663, 3664, 3665, 3666, 3726, 3727, 3728, 3729, 4457,
    4592, 4593, 4594, 5095, 5472, 5474, 5476, 5477, 5479, 5480, 5527, 6038,
    6290, 6316, 6887, 6888, 6890, 7806, 7807, 7808, 8364, 8957, 11584, 11950,
    12209, 12210, 12212, 12213, 12214, 12215, 12216, 12218, 12224, 13810, 13851, 13927,
    13928, 13929, 13930, 13931, 13932, 13933, 13934, 13935, 16971, 17197, 17198, 17222,
    18045, 18254, 20074, 20452, 21023, 21072, 21217, 206177, 232436, 232438, 238637, 238638,
    238639, 238641, 238642, 248613, 250065, 250066, 250067, 250068, 250069, 250070, 250071, 250072,
    250073, 250074, 250075, 250076, 250077, 250078, 250079, 250080, 263509, 263512, 267341, 268912,
    268913, 274971, 274976, 286152, 10841, 13813, 19318, 249865, 249867, 249868, 249869, 249870,
    249871, 249873, 249874, 249875, 249876, 23176,
})
-- AutoBar: Muffin.Flask
DATA.flask = ToSet({
    13510, 13511, 13512, 13513, 274273, 274274, 274275, 274276,
})
-- AutoBar: Consumable.Weapon Buff (sharpening and weight stones, mana and wizard oils, misc)
DATA.weapon_buff = ToSet({
    2862, 2863, 2871, 7964, 12404, 18262, 23122, 23528, 23529, 171436, 171437, 172038,
    3239, 3240, 3241, 7965, 12643, 28420, 28421, 171438, 171439,
    20745, 20747, 20748, 22521, 20744, 20746, 20749, 20750, 22522,
    3824, 3829, 23123, 31535, 34538, 34539, 44065, 171286, 243733, 243734,
})
-- AutoBar: Misc.Hearth and Muffin.Misc.Hearth. Hearthstone, the engineering
-- teleporters (Everlook, Gadgetzan, ...) and the rings, cloaks and tabards that
-- teleport you; worn ones count too (see ScanBags).
DATA.travel = ToSet({
    6948, 227925, 18984, 18986, 22589, 22630, 22631, 22632, 28585, 30542, 30544, 32757,
    35230, 37118, 37863, 40585, 40586, 44314, 44315, 44934, 44935, 45688, 45689, 45690,
    45691, 46874, 48933, 48954, 48955, 48956, 48957, 50287, 51557, 51558, 51559, 51560,
    52251, 54452, 58487, 63206, 63207, 63352, 63353, 63378, 63379, 64457, 64488, 65274,
    65360, 87215, 87548, 95050, 95051, 95567, 95568, 103678, 110560, 112059, 118662, 118663,
    118907, 118908, 128353, 140192, 141016, 141605, 166559, 166560, 205255,
})
local HEARTHSTONE = 6948
-- Spells on the Hearth/Teleport button, for whichever class knows them: Astral
-- Recall (Shaman), Teleport: Moonglade (Druid), Death Gate, Zen Pilgrimage and
-- the mage city teleports.
local TRAVEL_SPELLS = {
    556, 18960, 50977, 126892,
    3561, 3562, 3565, 32271, 3567, 3563, 3566, 32272, 33690, 35715,
}

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
local CLASSIFIER = 2   -- raise when the learning rules change, so items are checked again

local STYLE_DEFAULTS = {
    glowColor = { 1, 0.15, 0.15, 1 }, glowThickness = 3, glowTexture = "solid",
    glowPulse = true, glowSpeed = 0.7,
    tabColor = { 1, 0.82, 0, 0.95 }, tabHoverColor = { 1, 1, 1, 1 },
    tabWidth = 18, tabHeight = 7, tabTexture = "solid",
    flyoutBg = { 0, 0, 0, 0.65 }, flyoutBorderColor = { 0, 0, 0, 1 }, flyoutBorderSize = 1,
    entrySpacing = 2,   -- itemSize (pixels) defaults to your action buttons' width, set with the settings code
    entryBorderColor = { 0.1, 0.1, 0.1, 1 }, entryBorderSize = 2, selectedSize = 2, selectedColor = { 1, 0.82, 0, 1 }, entryHover = { 1, 1, 1, 0.25 },
    closeDelay = 0.3,
    tooltipColor = { 1, 0.3, 0.3, 1 },
    euiSkin = true, euiAccent = false,
}

local function Style(key)
    local s = DB().style
    local v
    if type(s) == "table" then v = s[key] end   -- (a false value must survive, so no "and/or" here)
    if v == nil then v = STYLE_DEFAULTS[key] end
    if type(v) == "function" then v = v() end   -- a default worked out when asked (itemSize)
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

-- One physical screen pixel in frame's own units. Sizes the player sets as
-- pixels (borders, spacing, the flyout indicator) go through this, so a 1 is
-- exactly one pixel whatever the UI scale.
local function PixelSize(frame)
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
local function Snap(frame, v)
    local px = PixelSize(frame)
    return math.floor(v / px + 0.5) * px
end

-- v in UI units (the units EllesmereUI's Icon Size and the action bars use),
-- in frame's own units and on whole pixels. Sizes that go with the button (item
-- size, indicator width) use these; thicknesses are screen pixels.
local function BarUnits(frame, v)
    local s = frame and frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    local u = UIParent and UIParent:GetEffectiveScale() or 1
    if type(s) ~= "number" or s <= 0 then s = 1 end
    return Snap(frame, v * u / s)
end

-- the four edge textures as a border t screen pixels thick
local function PlaceEdges(e, frame, t)
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
-- switched on (/amac add <key>, the settings, or by itself the first time you
-- carry its items: see Enabled and AutoEnable).
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
    { key = "portals", name = "AM_Portal", title = "Portals", empty = "Portals", label = "portals",
      kind = "spells", spells = { 10059, 11417, 11416, 11418, 11419, 11420 }, class = "MAGE", scope = "character" },
}

local MACROS = {}            -- the categories in use for this character (rebuilt by RebuildMacros)
local ALL = {}               -- every category, built-in and custom, for /amac list
local EMPTY_MESSAGE = {}     -- macro name when empty -> tooltip message

-- On or off as you set it. Untouched, your own categories and the mage scroll
-- button are on; item buttons stay off until you first carry their items
-- (AutoEnable then switches them on for good).
local function Enabled(e)
    local on = DB().enabled
    if on and on[e.key] ~= nil then return on[e.key] end
    if e.custom or e.special == "scroll" then return e.default == true end
    return false
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
    -- worn items count too: teleport trinkets, rings and cloaks only work equipped
    if GetInventoryItemID then
        for invSlot = 1, 19 do
            local ok, id = pcall(GetInventoryItemID, "player", invSlot)
            if ok and type(id) == "number" then have[id] = true end
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
-- your bags, otherwise the best one. Returns its ID and its list entry. An
-- entry's pick (when set) is what the flyout saves, so a spell and an item with
-- the same number stay apart on the Hearth/Teleport button.
local function Chosen(m, list)
    if #list == 0 then return nil end
    local db = DB()
    local want = Picks()[m.name]
    if not want then want = db.pick and db.pick[m.name] end               -- older versions
    if not want and m.special == "scroll" then want = db.scrollPick end   -- older versions
    if want then
        for _, e in ipairs(list) do
            if (e.pick or e.id) == want then return e.id, e end
        end
    end
    return list[1].id, list[1]
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

-- Weapon stones and oils: use the item, then put it on the main hand (16), or
-- the off hand (17) with Shift held.
local function WeaponBody(id)
    return UseBody(id) .. "\n/use [mod:shift] 17; 16"
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

-- Gear that only works worn (teleport rings, cloaks, trinkets): shown grey in
-- the flyout until equipped, and equipped by clicking it there.
local function IsEquippable(id)
    local fn = (C_Item and C_Item.IsEquippableItem) or IsEquippableItem
    if not fn then return false end
    local ok, r = pcall(fn, id)
    return ok and r == true
end

local function IsEquipped(id)
    local fn = (C_Item and C_Item.IsEquippedItem) or IsEquippedItem
    if not fn then return false end
    local ok, r = pcall(fn, id)
    return ok and r == true
end

local function NeedsEquip(id)
    return IsEquippable(id) and not IsEquipped(id)
end

local function EquipByID(id)
    local fn = (C_Item and C_Item.EquipItemByName) or EquipItemByName
    if not fn then return false end
    return (pcall(fn, id))
end

-- Hearth/Teleport, in this order: hearth items ready to use (Hearthstone
-- first), the teleport spells you know, then gear that has to be put on first,
-- so the automatic choice is always something that works straight away.
-- Spells are saved as negative picks.
local function TravelOptions(m, have)
    local ready, gear = {}, {}
    for _, e in ipairs(Candidates(have, m.set)) do
        if NeedsEquip(e.id) then gear[#gear + 1] = e else ready[#ready + 1] = e end
    end
    table.sort(ready, function(x, y)
        if (x.id == HEARTHSTONE) ~= (y.id == HEARTHSTONE) then return x.id == HEARTHSTONE end
        return x.score > y.score
    end)
    local list = ready
    for _, s in ipairs(KnownSpells(m)) do
        list[#list + 1] = { id = s.id, spell = true, pick = -s.id }
    end
    for _, e in ipairs(gear) do list[#list + 1] = e end
    return list
end

-- The macro we remembered at a slot is only trusted if its text still looks like
-- this category's.
local function BodyMatches(m, body)
    if type(body) ~= "string" then return false end
    if m.special == "scroll" then return body:find("Comprehend", 1, true) ~= nil end
    if m.kind == "spells" then return body:find("/cast", 1, true) ~= nil end
    if m.kind == "travel" and body:find("/cast", 1, true) then return true end
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
    -- 2. its name (the macros are named after their category, or were once)
    local names = { m.title, m.empty, m.name }
    for _, n in ipairs(m.oldNames or {}) do names[#names + 1] = n end
    for _, n in ipairs(names) do
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
        -- kept for /automacros: macros that had to be made again this session
        -- were not found from last time (lost on reload, or deleted)
        report.created = report.created or {}
        report.created[#report.created + 1] = want
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

-- Buttons switched off whose macro is still to be deleted. Macros cannot be
-- changed in combat, so this waits for the next update out of combat.
local toDelete = {}

-- Deletes a category's macro (it also leaves every action bar it was on). Only
-- a macro whose text still looks like the category's is touched, so one of your
-- own that happens to share the name is left alone.
local function DeleteManaged(m)
    local idx = FindMacro(m)
    if not idx then return end
    if not BodyMatches(m, GetMacroBody(idx)) then
        Print(m.title .. ": macro " .. tostring(GetMacroInfo(idx)) .. " left alone - it does not look like one of ours")
        return
    end
    local ok, err = pcall(DeleteMacro, idx)
    if not ok then
        Fail("deleting " .. m.title, err)
        return
    end
    -- the macros after it have moved up one place, so every remembered slot is
    -- dropped and found again by name on the next update
    DB().idx = {}
    Print(m.title .. ": macro deleted")
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
    -- thick borders grow outwards; one pixel tighter than before 0.37.0 so the
    -- border lies over the action button's own 1px border instead of outside it
    -- (thickness and offset are screen pixels)
    local off = (math.max(1, t - 1) - 1) * PixelSize(button)
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
    -- width is UI units (like the button), height screen pixels; never wider
    -- than the button, and placed on whole pixels so its edges stay sharp
    local px = PixelSize(a)
    local b = a.button
    local bw = b and b:GetWidth() or 0
    if type(bw) ~= "number" or bw <= 0 then bw = 36 end
    local bwPx = math.floor(bw / px + 0.5)
    local wPx = math.min(math.floor(BarUnits(a, Style("tabWidth")) / px + 0.5), bwPx)
    a:SetSize(math.max(wPx, 0.01) * px, Style("tabHeight") * px)   -- 0: nothing to see
    if b then
        a:ClearAllPoints()
        a:SetPoint("BOTTOMLEFT", b, "TOPLEFT", math.floor((bwPx - wPx) / 2) * px, -3 * px)
    end
    Paint(a.tex, Style("tabTexture"), hover and StyleColor("tabHoverColor") or StyleColor("tabColor"))
end

-- ---- action button art, shared by the popup items and the settings demos ----
-- Blizzard's own textures, used when EllesmereUI is not drawing the buttons.
local BLIZZ_ART = {
    frame = "Interface\\Buttons\\UI-Quickslot2",
    hover = { kind = "tex", path = "Interface\\Buttons\\ButtonHilight-Square", blend = "ADD", r = 1, g = 1, b = 1 },
    push = { kind = "tex", path = "Interface\\Buttons\\UI-Quickslot-Depress", r = 1, g = 1, b = 1 },
    borderPx = { none = 0, thin = 1, normal = 2, heavy = 3, strong = 4 },
}

-- How EllesmereUI draws action buttons, or nil for Blizzard's art: nil without
-- EllesmereUI, with its styling turned off here, or when its Action Bars module
-- is set to the Blizzard or classic look. Border, icon zoom and slot background
-- come from Action Bar 1; hover and pushed effects from its Bar Animations page
-- (Highlight/Pushed Type 1-3 its textures, 4 a fill, 5 a border, 6 none). Without
-- the Action Bars module, EllesmereUI's defaults.
local function EUIButtonLook()
    if not EllesmereUI or Style("euiSkin") == false then return nil end
    local look = { zoom = 0.055, bg = { 0.15, 0.15, 0.15, 0.5 }, border = { 0, 0, 0, 1 }, size = 1,
        hover = { kind = "fill", r = 1, g = 1, b = 1, a = 0.15 }, push = { kind = "fill", r = 1, g = 1, b = 1, a = 0.25 } }
    local lite = EllesmereUI.Lite
    local ok, eab = false, nil
    if type(lite) == "table" and lite.GetAddon then ok, eab = pcall(lite.GetAddon, "EllesmereUIActionBars", true) end
    local p = ok and type(eab) == "table" and type(eab.db) == "table" and eab.db.profile
    if type(p) ~= "table" then return look end
    if p.useClassicStyle or p.useBlizzardStyle or p.squareIcons == false then return nil end
    local _, class = UnitClass("player")
    local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local s = type(p.bars) == "table" and type(p.bars.MainBar) == "table" and p.bars.MainBar or {}
    local zoom = tonumber(s.iconZoom or p.iconZoom)
    if zoom then look.zoom = zoom / 100 end
    local bg = p.slotBgColor
    if type(bg) == "table" then look.bg = { bg.r or 0.15, bg.g or 0.15, bg.b or 0.15, (tonumber(p.slotBgOpacity) or 50) / 100 } end
    local c = s.borderColor
    if type(c) == "table" then look.border = { c.r or 0, c.g or 0, c.b or 0, c.a or 1 } end
    if s.borderClassColor and cc then look.border = { cc.r, cc.g, cc.b, look.border[4] } end
    look.size = tonumber(s.borderThicknessPx) or BLIZZ_ART.borderPx[s.borderThickness or "thin"] or 1
    -- hover ("highlight") and pushed, as its Bar Animations page sets them
    local function interaction(prefix)
        local t = tonumber(p[prefix .. "TextureType"]) or 2
        local col = type(p[prefix .. "CustomColor"]) == "table" and p[prefix .. "CustomColor"] or {}
        local spec = { r = col.r or 0.973, g = col.g or 0.839, b = col.b or 0.604, a = 1,
            size = tonumber(p[prefix .. "BorderSize"]) or 4 }
        if p[prefix .. "UseClassColor"] and cc then spec.r, spec.g, spec.b = cc.r, cc.g, cc.b end
        if t <= 3 then
            spec.kind = "tex"
            spec.path = "Interface\\AddOns\\EllesmereUIActionBars\\Media\\highlight-" .. (t + 1) .. ".png"
        elseif t == 4 then
            spec.kind, spec.a = "fill", 0.35
        elseif t == 5 then
            spec.kind = "edge"
        else
            spec.kind = "none"
        end
        return spec
    end
    look.hover = interaction("highlight")
    look.push = interaction("pushed")
    return look
end

-- Gives button b (with b.icon) the parts StyleButtonArt draws with: slot
-- background, Blizzard frame, border, selected border, hover and pushed layers.
local function ButtonArt(b)
    b.slot = b:CreateTexture(nil, "BACKGROUND")
    b.slot:SetAllPoints()
    b.normal = b:CreateTexture(nil, "ARTWORK", nil, 1)
    b.normal:SetTexture(BLIZZ_ART.frame)
    b.normal:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.edges = MakeEdges(b, "OVERLAY")
    b.sel = MakeEdges(b, "OVERLAY")
    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
    b.hl:SetAllPoints()
    b.hlEdges = MakeEdges(b, "HIGHLIGHT")
    local pl = CreateFrame("Frame", nil, b)   -- shown while the mouse button is down
    pl:SetAllPoints()
    pl:SetFrameLevel((b:GetFrameLevel() or 1) + 2)
    pl:Hide()
    b.push = pl:CreateTexture(nil, "OVERLAY")
    b.push:SetAllPoints()
    b.pushEdges = MakeEdges(pl, "OVERLAY")
    b.pushLayer = pl
    b:HookScript("OnMouseDown", function(self) self.pushLayer:Show() end)
    b:HookScript("OnMouseUp", function(self) self.pushLayer:Hide() end)
    b:HookScript("OnHide", function(self) self.pushLayer:Hide() end)
end

-- one hover or pushed effect: a texture, a fill, a border or nothing
local function PaintInteraction(tex, edges, owner, spec)
    PlaceEdges(edges, owner, 0)
    tex:Hide()
    if spec.kind == "tex" then
        tex:SetTexture(spec.path)
        tex:SetTexCoord(0, 1, 0, 1)
        pcall(tex.SetBlendMode, tex, spec.blend or "BLEND")
        tex:SetVertexColor(spec.r, spec.g, spec.b, spec.a or 1)
        tex:Show()
    elseif spec.kind == "fill" then
        tex:SetVertexColor(1, 1, 1, 1)
        pcall(tex.SetBlendMode, tex, "BLEND")
        tex:SetColorTexture(spec.r, spec.g, spec.b, spec.a or 0.35)
        tex:Show()
    elseif spec.kind == "edge" then
        for i = 1, 4 do edges[i]:SetColorTexture(spec.r, spec.g, spec.b, spec.a or 1) end
        PlaceEdges(edges, owner, spec.size or 2)
    end
end

-- Draws b like an action button. o.look: EllesmereUI's look (EUIButtonLook) or
-- nil for Blizzard's. Without it, o.border (+ o.size) swaps Blizzard's frame
-- for a flat border and o.hover swaps its hover glow for a flat colour.
-- o.sel (+ o.selSize): a border marking the selected item, drawn over the rest.
local function StyleButtonArt(b, o)
    local look = o.look
    if look then
        b.normal:Hide()
        b.slot:SetColorTexture(look.bg[1], look.bg[2], look.bg[3], look.bg[4])
        b.slot:Show()
        b.icon:SetTexCoord(look.zoom, 1 - look.zoom, look.zoom, 1 - look.zoom)
        for i = 1, 4 do b.edges[i]:SetColorTexture(look.border[1], look.border[2], look.border[3], look.border[4]) end
        PlaceEdges(b.edges, b, look.size)
        -- hover and pushed fill the icon inside the border, as on EllesmereUI's bars
        local t = look.size * PixelSize(b)
        for _, tex in ipairs({ b.hl, b.push }) do
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", b, "TOPLEFT", t, -t)
            tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -t, t)
        end
        PaintInteraction(b.hl, b.hlEdges, b, look.hover)
        PaintInteraction(b.push, b.pushEdges, b.pushLayer, look.push)
    else
        b.slot:Hide()
        b.icon:SetTexCoord(0, 1, 0, 1)
        b.hl:ClearAllPoints()
        b.hl:SetAllPoints(b)
        b.push:ClearAllPoints()
        b.push:SetAllPoints(b)
        if o.border then
            b.normal:Hide()
            for i = 1, 4 do b.edges[i]:SetColorTexture(o.border[1], o.border[2], o.border[3], o.border[4] or 1) end
            PlaceEdges(b.edges, b, o.size or 2)
        else
            local w = b:GetWidth()
            if type(w) ~= "number" or w <= 0 then w = 36 end
            b.normal:SetSize(w * 66 / 36, w * 66 / 36)
            b.normal:Show()
            PlaceEdges(b.edges, b, 0)
        end
        local h = o.hover
        PaintInteraction(b.hl, b.hlEdges, b,
            h and { kind = "fill", r = h[1], g = h[2], b = h[3], a = h[4] or 1 } or BLIZZ_ART.hover)
        PaintInteraction(b.push, b.pushEdges, b.pushLayer, BLIZZ_ART.push)
    end
    if o.sel then
        for i = 1, 4 do b.sel[i]:SetColorTexture(o.sel[1], o.sel[2], o.sel[3], o.sel[4] or 1) end
        PlaceEdges(b.sel, b, o.selSize or 2)
    else
        PlaceEdges(b.sel, b, 0)
    end
end

-- One item button in the popup. With EllesmereUI's look it matches your action
-- bars exactly; without, Blizzard's art unless the item border or hover colour
-- is set away from Default. The selected border is always ours.
local function StyleEntry(e)
    local size = BarUnits(e, Style("itemSize"))   -- whole pixels, so every border is even
    e:SetSize(size, size)
    local o = { look = EUIButtonLook() }
    if not o.look then
        if ColorMode("entryBorderColor") ~= "default" then
            o.border, o.size = StyleColor("entryBorderColor"), Style("entryBorderSize")
        end
        if ColorMode("entryHover") ~= "default" then o.hover = StyleColor("entryHover") end
    end
    if e.selected then o.sel, o.selSize = StyleColor("selectedColor"), Style("selectedSize") end
    StyleButtonArt(e, o)
    if SkinActive() and skin.GetFont then
        local ok, font = pcall(skin.GetFont)
        if ok and type(font) == "string" then pcall(e.count.SetFont, e.count, font, 11, "OUTLINE") end
    end
end

-- the popup frame: always our own background and border, so every colour
-- setting works. (EllesmereUI's skin.Panel is not used: it fades the frame's
-- own textures and adds an outline of its own that no setting reached.) With
-- EllesmereUI's button look, Default background and border are see-through,
-- so the items stand on their own like buttons on a bar, each with its border.
local function StyleFlyout(f)
    local look = EUIButtonLook()
    local c = StyleColor("flyoutBg")
    if ColorMode("flyoutBg") == "default" then
        if look then
            c = { 0, 0, 0, 0 }
        elseif SkinActive() and skin.GetPanelColor then
            local ok, r, g, b, a = pcall(skin.GetPanelColor)
            if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
                c = { r, g, b, type(a) == "number" and a or c[4] }
            end
        end
    end
    f.bg:Show()
    f.bg:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    local bc = StyleColor("flyoutBorderColor")
    if look and ColorMode("flyoutBorderColor") == "default" then bc = { 0, 0, 0, 0 } end
    for i = 1, 4 do f.edges[i]:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 1) end
    PlaceEdges(f.edges, f, Style("flyoutBorderSize"))
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
--   any item,     "Use:" teleports you / returns you home -> hearth/teleport
--   consumable, subclass Bandage            -> bandage
--   consumable, subclass Flask              -> flask
--   Food & Drink, tooltip says "well fed"   -> buff food
--   Food & Drink, "Use:" restores health    -> food;  restores mana -> water
--   Potion,       "Use:" gives rage         -> rage potion
--   Potion,       "Use:" restores health    -> health potion; mana -> mana potion
--   Potion / Elixir, "Use:" raises Strength, Agility, Stamina or Intellect
--                                           -> that stat's elixir button
--   Scroll,       "Use:" raises one of those -> that stat's scroll button
--   Item Enhancement / other consumable, "Use:" mentions your weapon
--                                           -> weapon buff
--   other consumable, "Use:" does damage    -> explosives (retail files them here)
--   Trade Goods, subclass Explosives        -> explosives (classic files them here)
-- Items of other classes are only checked for teleporting: misc items and
-- armour (rings, cloaks, trinkets); anything else is skipped.
-- ---------------------------------------------------------------------------
local LEARNABLE = {
    "food", "water", "hpot", "mpot", "bandage", "antivenom",
    "scroll_agility", "scroll_intellect", "scroll_stamina", "scroll_strength",
    "elixir_agility", "elixir_intellect", "elixir_stamina", "elixir_strength",
    "explosives", "rage", "food_buff", "flask", "weapon_buff", "travel",
}
-- item classes worth a look: consumable, armour, trade goods, miscellaneous
local LOOKED_AT = { [0] = true, [4] = true, [7] = true, [15] = true }
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
    if not LOOKED_AT[class] then return {} end
    if class == 0 and sub == 7 then return { "bandage" } end
    if class == 0 and sub == 3 then return { "flask" } end
    if class == 7 and sub == 2 then return { "explosives" } end
    if class == 7 then return {} end
    local lines = TooltipLines(id)
    if not lines or #lines < 2 or lines[1] == RETRIEVING_ITEM_INFO then return nil end
    local use = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    local health, mana, rage, damage, weapon, travel, wellFed = false, false, false, false, false, false, false
    local stats = {}
    for _, text in ipairs(lines) do
        local low = text:lower()
        if low:find("well fed", 1, true) then wellFed = true end
        if text:find(use, 1, true) then
            if HasWord(low, "teleport", "returns you to") then travel = true end
            if HasWord(low, "weapon") then weapon = true end
            if text:find("%d") then
                if HasWord(low, "health", HEALTH) then health = true end
                if HasWord(low, "mana", MANA) then mana = true end
                if low:find("%f[%a]rage%f[%A]") then rage = true end   -- the word, not "average"
                if HasWord(low, "damage") then damage = true end
                for i, key in ipairs(STAT_KEYS) do
                    local name = _G["SPELL_STAT" .. i .. "_NAME"] or (key:sub(1, 1):upper() .. key:sub(2))
                    if text:find(name, 1, true) then stats[key] = true end
                end
            end
        end
    end
    if travel then return { "travel" } end
    if class ~= 0 then return {} end          -- armour and misc items: only teleports count
    local sets = {}
    if sub == 5 then
        if wellFed then return { "food_buff" } end
        if health then sets[#sets + 1] = "food" end
        if mana then sets[#sets + 1] = "water" end
    elseif sub == 1 and rage then
        sets[#sets + 1] = "rage"
    elseif sub == 1 and (health or mana) then
        if health then sets[#sets + 1] = "hpot" end
        if mana then sets[#sets + 1] = "mpot" end
    elseif sub == 4 then
        for _, key in ipairs(STAT_KEYS) do
            if stats[key] then sets[#sets + 1] = "scroll_" .. key end
        end
    elseif sub == 1 or sub == 2 then
        for _, key in ipairs(STAT_KEYS) do
            if stats[key] then sets[#sets + 1] = "elixir_" .. key end
        end
    elseif weapon then
        sets[#sets + 1] = "weapon_buff"
    elseif sub == 0 and damage then
        sets[#sets + 1] = "explosives"
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
            if class ~= nil and not LOOKED_AT[class] then
                sessionDone[id] = true            -- nothing any button uses
            elseif class ~= nil then
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

-- Switches on, for good, every item button you have not set yourself once you
-- carry something for it, and any whose macro an earlier version already made
-- (so nobody loses a button from their bars). Returns true when one changed.
local function AutoEnable(have)
    local db = DB()
    local _, class = UnitClass("player")
    local changed = false
    for _, e in ipairs(ALL) do
        local saved = type(db.enabled) == "table" and db.enabled[e.key]
        if saved == nil and not e.custom and e.special ~= "scroll" and e.kind ~= "spells"
            and (not e.class or e.class == class) then
            local stocked
            if e.special == "healthstone" then
                stocked = BestHealthstone(have) ~= nil or class == "WARLOCK"
            elseif e.kind == "travel" then
                stocked = #TravelOptions(e, have) > 0
            elseif e.set then
                stocked = #Candidates(have, e.set) > 0
            end
            local made = false
            local key = CharKey()
            local idx = type(db.idx) == "table" and type(db.idx[key]) == "table" and db.idx[key][e.name]
            if idx then made = BodyMatches(e, GetMacroBody(idx)) end
            -- slots are forgotten after a delete, so look the macro up by name too
            for _, n in ipairs({ e.title, e.empty }) do
                local i = not made and GetMacroIndexByName(n)
                if i and i > 0 then made = BodyMatches(e, GetMacroBody(i)) end
            end
            if stocked or made then
                db.enabled = db.enabled or {}
                db.enabled[e.key] = true
                changed = true
                if stocked and not made then Print(e.title .. ": turned on (you are carrying some)") end
            end
        end
    end
    return changed
end

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
    local okAuto, autoChanged = pcall(AutoEnable, have)
    if not okAuto then Fail("switching buttons on", autoChanged)
    elseif autoChanged then pcall(RebuildMacros) end
    report.error = nil
    local inCombat = InCombatLockdown()
    pending = inCombat   -- macros are only rewritten out of combat
    if not inCombat then
        for key, e in pairs(toDelete) do
            toDelete[key] = nil
            -- skipped if it was switched back on in the meantime
            if not Enabled(e) or e.removed then DeleteManaged(e) end
        end
    end
    local emptyState = {}
    for _, m in ipairs(MACROS) do
        local body, id, spellUsed
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
        elseif m.kind == "travel" then
            local list = TravelOptions(m, have)
            flyoutItems[m.name] = list
            local entry
            id, entry = Chosen(m, list)
            spellUsed = entry ~= nil and entry.spell == true
            if not id then
                body = EmptyBody(m.label)
            elseif spellUsed then
                body = SpellBody(id)
            else
                body = UseBody(id)
            end
        else
            local list = Candidates(have, m.set)
            flyoutItems[m.name] = list
            id = Chosen(m, list)
            if not id then
                body = EmptyBody(m.label)
            elseif m.weapon then
                body = WeaponBody(id)
            else
                body = UseBody(id)
            end
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
            report[m.name] = { id = id, spell = spellUsed, result = result, size = body and #body or 0 }
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
        if AnyOver() then
            self.idle = 0
        else
            self.idle = (self.idle or 0) + elapsed
            if self.idle > Style("closeDelay") then self:Hide() end
        end
    end)
    -- a click anywhere else closes it too
    flyout:SetScript("OnEvent", function(self)
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
    e.icon = e:CreateTexture(nil, "ARTWORK")
    e.icon:SetAllPoints()
    ButtonArt(e)
    local ok, fs = pcall(e.CreateFontString, e, nil, "OVERLAY", "NumberFontNormal")
    if not ok or not fs then fs = e:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") end
    fs:SetPoint("BOTTOMRIGHT", -3, 3)
    e.count = fs
    e:SetScript("OnClick", function(self)
        local m = flyout.macro
        if not m then return end
        -- the best item is what "automatic" already uses, so picking it clears the choice
        -- gear that is not worn yet is put on, so the button can show its cooldown
        if self.unequipped then
            if InCombatLockdown() then
                Print(ItemRef(self.itemID) .. ": cannot be equipped in combat")
            elseif not EquipByID(self.itemID) then
                Print(ItemRef(self.itemID) .. ": could not be equipped")
            end
        end
        local list = flyoutItems[m.name]
        local automatic = list and list[1] and (list[1].pick or list[1].id) == self.pick
        ChooseItem(m, (not automatic) and self.pick or nil)
        flyout:Hide()
    end)
    e:SetScript("OnEnter", function(self)
        SetOver(self, true)
        if self.kind == "spell" then
            ShowSpellTooltip(self, self.itemID)
        else
            ShowItemTooltip(self, self.itemID, self.loc)
            if self.unequipped then
                GameTooltip:AddLine("Not equipped - click to put it on", 1, 0.82, 0)
                GameTooltip:Show()
            end
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

-- Sizes and places the item buttons in popup f (default: the real one) from the
-- saved style, all on whole screen pixels so spacing and borders come out even:
-- item spacing and the popup border are pixels, the first (best) item is nearest
-- the button. With button, the popup is also put centred over it, just above its
-- flyout indicator (arrow). The settings demo uses this too.
local function LayoutFlyout(f, list, n, button, arrow)
    f = f or flyout
    if not f then return end
    list = list or entries
    n = n or f.count or 0
    local px = PixelSize(f)
    local size = BarUnits(f, Style("itemSize"))
    local gap = Style("entrySpacing") * px
    local pad = (Style("flyoutBorderSize") + Style("entrySpacing")) * px
    for i = 1, n do
        local e = list[i]
        if e then
            e:SetSize(size, size)
            e:ClearAllPoints()
            e:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", pad, pad + (i - 1) * (size + gap))
        end
    end
    f:SetSize(size + 2 * pad, 2 * pad + n * (size + gap) - gap)
    button = button or (f == flyout and f.button)
    if not button then return end
    arrow = arrow or arrows[button]
    local ratio = button:GetEffectiveScale() / f:GetEffectiveScale()
    local x = Snap(f, (button:GetWidth() * ratio - f:GetWidth()) / 2)
    local y = 0
    if arrow and arrow:IsShown() then   -- the indicator overlaps the button by 3px (StyleArrow)
        y = math.max(0, Style("tabHeight") - 3) * PixelSize(button) * ratio
        y = Snap(f, y)
    end
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", button, "TOPLEFT", x, y)
end

-- button is the action button to open over. source is the frame the mouse is
-- on. toggle closes the popup if it is already open for this button (clicking the tab).
local function OpenFlyout(button, m, source, toggle)
    local list = flyoutItems[m.name]
    if not button or not list or #list < 2 then return end
    BuildFlyout()
    if flyout:IsShown() and flyout.button == button and flyout.macro == m then
        if toggle then flyout:Hide() else SetOver(source, true) end
        return
    end
    flyout.macro, flyout.button = m, button
    flyout.over = {}
    SetOver(source, true)
    local _, chosenEntry = Chosen(m, list)
    local chosen = chosenEntry and (chosenEntry.pick or chosenEntry.id)
    local n = math.min(#list, MAX_ENTRIES)
    for i = 1, n do
        local e = Entry(i)
        local isSpell = m.kind == "spells" or list[i].spell == true   -- the Hearth/Teleport button has both
        e.kind = isSpell and "spell" or "item"
        e.itemID = list[i].id
        e.pick = list[i].pick or list[i].id
        e.loc = (not isSpell) and lastLocs[list[i].id] or nil
        e.icon:SetTexture(isSpell and SpellIcon(list[i].id) or IconFor({ item = list[i].id }))
        e.unequipped = (not isSpell) and NeedsEquip(list[i].id)   -- grey until worn
        pcall(e.icon.SetDesaturated, e.icon, e.unequipped and true or false)
        local count = (not isSpell) and CountOf(list[i].id) or nil
        e.count:SetText((count and count > 1) and tostring(count) or "")
        e.selected = (e.pick == chosen)                   -- highlighted border: the one in use
        StyleEntry(e)
        e:Show()
    end
    for i = n + 1, #entries do entries[i]:Hide() end
    flyout.count = n
    LayoutFlyout()   -- also places it over the button
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

-- ---------------------------------------------------------------------------
-- Settings: tabs laid out after EllesmereUI's Cooldown Manager pages. Each tab
-- has a preview strip at the top and its settings below, two to a row on the
-- EllesmereUI page (one to a row in the stand-alone window).
-- ---------------------------------------------------------------------------
local UI = {}   -- the settings code's own helpers, kept in one table so this file stays
                -- under Lua's limit of 200 local variables at the top level
local optionsPanel   -- the stand-alone window, built on first use

-- Re-reads the values shown on our EllesmereUI page while it is on screen.
local function RefreshEUIPage()
    local E = EllesmereUI
    if not (E and E.RefreshPage and E.GetActiveModule and E.GetPluginModuleKey) then return end
    pcall(function()
        if E:GetActiveModule() == E.GetPluginModuleKey("AutoMacros", "options") then E:RefreshPage() end
    end)
end

-- Dresses a preview button like a real action button (see EUIButtonLook).
-- Run again on every refresh, so switching EllesmereUI styling shows at once.
function UI.StyleSample(b)
    StyleButtonArt(b, { look = EUIButtonLook() })
end

-- A preview button the size of an action button, drawn like the real ones.
function UI.SampleButton(parent, size, icon)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(size, size)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()
    f.icon:SetTexture(icon or QUESTION_MARK)
    ButtonArt(f)
    UI.StyleSample(f)
    return f
end

function UI.SmallText(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetText(text)
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
    return IconFor(PLACEHOLDER[e.name] or e.placeholder)
end

local RefreshHeaders, RefreshOptions   -- defined below

-- Turns a button on or off, the same as /amac add and /amac remove.
function UI.SetEnabled(e, on)
    local db = DB()
    db.enabled = db.enabled or {}
    db.enabled[e.key] = on and true or false
    if not on then
        toDelete[e.key] = e   -- its macro goes on the next update
        if InCombatLockdown() then Print(e.title .. ": macro will be deleted when combat ends") end
    end
    Refresh()
    RefreshHeaders()
    RefreshOptions()
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

-- How the Buttons tab sorts them. Anything not listed goes under Other.
UI.BUTTON_GROUPS = {
    { name = "Recovery", keys = { "healthstone", "healthpot", "manapot", "ragepot", "bandage", "antivenom" } },
    { name = "Food & Drink", keys = { "food", "water", "bufffood" } },
    { name = "Buffs", keys = { "flask", "weaponbuff", "agielixir", "intelixir", "staelixir", "strelixir",
        "agiscroll", "intscroll", "stascroll", "strscroll" } },
    { name = "Utility", keys = { "travel", "explosives" } },
    { name = "Class", keys = { "portals", "comprehend" } },
}

-- The Buttons tab: one section per group, each a grid of checkboxes.
function UI.ButtonSections()
    local byKey, placed = {}, {}
    for _, e in ipairs(UI.AvailableButtons()) do byKey[e.key] = e end
    local sections = {}
    local function add(name, list)
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
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f, "TOPLEFT", left + col * (size + gap), -16 - row * (size + gap))
        b.icon:SetTexture(UI.CategoryIcon(e))
        UI.StyleSample(b)
        local on = Enabled(e)
        pcall(b.icon.SetDesaturated, b.icon, not on)
        b:SetAlpha(on and 1 or 0.5)
        b:Show()
    end
    for i = #list + 1, #f.icons do f.icons[i]:Hide() end
    f.hint = f.hint or UI.SmallText(f, "Click an icon to turn its button on or off (off deletes its macro). Drag one onto an action bar.")
    f.hint:ClearAllPoints()
    f.hint:SetPoint("TOP", f, "TOP", 0, -16 - rows * (size + gap) - 4)
    return 16 + rows * (size + gap) + 30
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
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f, "TOPLEFT", left + (i - 1) * 100, -20)
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
        pop.bg = pop:CreateTexture(nil, "BACKGROUND")
        pop.bg:SetAllPoints()
        pop.edges = MakeEdges(pop, "BORDER")
        pop.items = {}
        for i, id in ipairs({ 929, 1710, 3928 }) do
            local e = CreateFrame("Button", nil, pop)
            e:SetSize(34, 34)   -- LayoutFlyout sizes it
            e.icon = e:CreateTexture(nil, "ARTWORK")
            e.icon:SetAllPoints()
            e.icon:SetTexture(IconFor({ item = id }))
            ButtonArt(e)
            e.count = e:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            e.count:SetPoint("BOTTOMRIGHT", -3, 3)
            e.count:SetText(i == 1 and "5" or "")
            e.selected = (i == 1)   -- the one in use
            pop.items[i] = e
        end
        f.pop = pop
        f.hint = UI.SmallText(f, "Hover an item to see the hover colour. The highlighted border marks the one in use.")
    end
    -- the sample is the size of your action buttons on screen (whatever the
    -- settings window's scale), so the indicator and items compare
    local px = PixelSize(f)
    local bw, bh = UI.ButtonSize()
    bw, bh = BarUnits(f, bw), BarUnits(f, bh)
    f.btn:SetSize(bw, bh)
    UI.StyleSample(f.btn)
    f.btn:ClearAllPoints()
    f.btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", Snap(f, (width - bw) / 2), Snap(f, 34))
    if f.arrow then StyleArrow(f.arrow, false) end
    local pop = f.pop
    StyleFlyout(pop)
    for _, e in ipairs(pop.items) do StyleEntry(e) end
    LayoutFlyout(pop, pop.items, #pop.items, f.btn, f.arrow)   -- same layout as the real popup
    f.hint:ClearAllPoints()
    f.hint:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    return 34 + bh + Style("tabHeight") * px + 3 + pop:GetHeight() + 16
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
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    f:SetWidth(width)
    local ok, h = pcall(UI.HEADERS[key], f, width)
    if not ok then
        Fail("options preview", h)
        h = 1
    end
    f.h = h
    f:SetHeight(h)
    f:Show()
    return h
end

RefreshHeaders = function()
    for _, f in pairs(UI.headerFrames) do
        if f:IsVisible() then
            local ok, h = pcall(UI.HEADERS[f.key], f, f.width)
            if ok and h ~= f.h then
                f.h = h
                f:SetHeight(h)
                if f.onResize then pcall(f.onResize, h) end
            end
        end
    end
end

-- ---- the settings ----
function UI.SToggle(label, key)
    return { type = "toggle", label = label,
        get = function() return Style(key) and true or false end,
        set = function(v) SetStyle(key, v) end }
end

function UI.LearnedSummary()
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

-- true while buttons use Blizzard's art (no EllesmereUI look): for settings
-- that only apply then (an item's "when")
function UI.BlizzLook() return EUIButtonLook() == nil end

-- The width and height of your action buttons in UI units, the number
-- EllesmereUI's Icon Size shows (its border is inside the button, so it is
-- included): the widest the flyout indicator goes, the default item size, and
-- the size of the settings demo button.
function UI.ButtonSize()
    local b = buttons[1] or _G.ActionButton1
    local w, h = b and b:GetWidth(), b and b:GetHeight()
    if type(w) ~= "number" or w <= 0 then return 45, 45 end
    if type(h) ~= "number" or h <= 0 then h = w end
    local k = b:GetEffectiveScale() / UIParent:GetEffectiveScale()   -- bars may be scaled (EllesmereUI's stock styles)
    return math.max(8, math.floor(w * k + 0.5)), math.max(8, math.floor(h * k + 0.5))
end
STYLE_DEFAULTS.itemSize = function() return (UI.ButtonSize()) end   -- until you move the slider

-- the largest item size offered: a little over your action buttons
function UI.MaxItemSize() return UI.ButtonSize() + 16 end

-- a setting's number, or what its function returns (a slider's max, say)
function UI.Num(v)
    if type(v) == "function" then return v() end
    return v
end

-- Items listed in pairs where they can share a row: on the EllesmereUI page
-- two toggles, sliders or dropdowns next to each other go side by side.
-- An item with when = function shows only while it returns true.
local PAGES = {
    { name = "Buttons", header = "buttons", sections = UI.ButtonSections },
    { name = "Highlight", header = "glow", sections = {
        { name = "Highlight", items = {
            { type = "toggle", label = "Highlight empty buttons",
                get = function() return DB().glow ~= false end,
                set = function(v) DB().glow = v; RefreshGlow() end },
            UI.SToggle("Pulse", "glowPulse"),
            { type = "color", label = "Colour", key = "glowColor", alpha = true },
            { type = "range", label = "Thickness", key = "glowThickness", min = 1, max = 8, step = 1 },
            { type = "range", label = "Pulse time (seconds)", key = "glowSpeed", min = 0.2, max = 2, step = 0.1 },
            { type = "choice", label = "Texture", key = "glowTexture", list = function() return TextureChoices(true) end },
        } },
    } },
    { name = "Flyout", header = "flyout", sections = {
        { name = "Behaviour", items = {
            { type = "toggle", label = "Open the flyout on hover",
                get = function() return not DB().noFlyout end,
                set = function(v) DB().noFlyout = not v; Refresh() end },
            { type = "range", label = "Close delay (seconds)", key = "closeDelay", min = 0.1, max = 1.5, step = 0.1 },
        } },
        { name = "Flyout indicator", items = {
            { type = "color", label = "Colour", key = "tabColor", alpha = true },
            { type = "color", label = "Hover colour", key = "tabHoverColor", alpha = true },
            { type = "range", label = "Width", key = "tabWidth", min = 0, max = function() return (UI.ButtonSize()) end, step = 1 },
            { type = "range", label = "Height (pixels)", key = "tabHeight", min = 3, max = 16, step = 1 },
            { type = "choice", label = "Texture", key = "tabTexture", list = function() return TextureChoices(false) end },
        } },
        { name = "Popup", items = {
            { type = "color", label = "Background", key = "flyoutBg", alpha = true },
            { type = "color", label = "Border", key = "flyoutBorderColor", alpha = true },
            { type = "range", label = "Border size", key = "flyoutBorderSize", min = 0, max = 4, step = 1 },
        } },
        { name = "Items", items = {
            -- with EllesmereUI's look the items copy its Action Bars settings, so
            -- only the Blizzard look has its own border and hover options
            { type = "text", height = 34, when = function() return EUIButtonLook() ~= nil end,
                text = function() return "Items look like your EllesmereUI action bars: border, icon zoom, and the hover"
                    .. " and pushed effects from its Bar Animations page." end },
            { type = "text", height = 34, when = UI.BlizzLook,
                text = function() return "Item border and hover colour on Default use Blizzard's action button art." end },
            { type = "color", label = "Item border", key = "entryBorderColor", alpha = true, when = UI.BlizzLook },
            { type = "range", label = "Border size", key = "entryBorderSize", min = 0, max = 6, step = 1, when = UI.BlizzLook },
            { type = "color", label = "Hover colour", key = "entryHover", alpha = true, when = UI.BlizzLook },
            { type = "color", label = "Selected border", key = "selectedColor", alpha = true },
            { type = "range", label = "Selected border size", key = "selectedSize", min = 1, max = 6, step = 1 },
            { type = "range", label = "Item size", key = "itemSize", min = 16, max = UI.MaxItemSize, step = 1 },
            { type = "range", label = "Item spacing", key = "entrySpacing", min = 0, max = 10, step = 1 },
        } },
    } },
    { name = "General", sections = {
        { name = "Tooltips and labels", items = {
            { type = "toggle", label = "Clean \"No X in inventory\" tooltip",
                get = function() return not DB().stockTooltip end, set = function(v) DB().stockTooltip = not v end },
            { type = "toggle", label = "Hide macro names on buttons",
                get = function() return not DB().showNames end,
                set = function(v) DB().showNames = not v; Refresh() end },
            { type = "color", label = "Empty tooltip colour", key = "tooltipColor" },
        } },
        { name = "Item learning", items = {
            { type = "toggle", label = "Learn new items automatically",
                get = function() return not DB().learnOff end,
                set = function(v) DB().learnOff = (not v) or nil; if v then Update() end end },
            { type = "text", text = UI.LearnedSummary },
        } },
        { name = "Appearance", items = {
            { type = "eui", items = {
                { type = "toggle", label = "Use EllesmereUI styling",
                    get = function() return Style("euiSkin") and true or false end,
                    set = function(v)
                        SetStyle("euiSkin", v)
                        -- the Flyout tab shows different item options for each look
                        if EllesmereUI and EllesmereUI.RefreshPage then pcall(EllesmereUI.RefreshPage, EllesmereUI, true) end
                        RefreshOptions()
                    end },
            } },
            { type = "button", label = "Reset appearance", action = function() ResetStyle() end, refreshAll = true },
        } },
    } },
}

function UI.PageSections(page)
    if type(page.sections) == "function" then return page.sections() end
    return page.sections
end

UI.PAIRABLE = { toggle = true, range = true, choice = true }

-- Colours share a row too when EllesmereUI can put a swatch next to a dropdown,
-- as its Action Bars page does: mode dropdown with the colour swatch beside it.
function UI.Pairable(item)
    if UI.PAIRABLE[item.type] then return true end
    return item.type == "color" and EllesmereUI and EllesmereUI.BuildColorSwatch ~= nil
end

-- The colour swatch inside one half of a DualRow, left of its dropdown. It
-- shows the colour drawn now; picking one switches the mode to Custom.
function UI.InlineSwatch(region, item)
    if item.type ~= "color" or type(region) ~= "table" or not region._control then return end
    local key = item.key
    local ok, sw, refresh = pcall(EllesmereUI.BuildColorSwatch, region, region:GetFrameLevel() + 5,
        function() local c = StyleColor(key); return c[1], c[2], c[3], c[4] or 1 end,
        function(r, g, b, a)
            SetColor(key, r, g, b, item.alpha and a or nil)
            RefreshEUIPage()
        end, item.alpha and true or false, 20)
    if not ok or type(sw) ~= "table" then return end
    pcall(function()
        sw:ClearAllPoints()
        sw:SetPoint("RIGHT", region._control, "LEFT", -12, 0)
        region._lastInline = sw
    end)
    if type(refresh) == "function" and EllesmereUI.RegisterWidgetRefresh then
        pcall(EllesmereUI.RegisterWidgetRefresh, function() pcall(refresh) end)
    end
end

-- the EllesmereUI DualRow half for a toggle, slider, dropdown or colour mode
function UI.NativeCfg(item)
    if item.type == "color" then
        local key = item.key
        local values, order = {}, {}
        for _, m in ipairs(ColorModeChoices()) do
            values[m.key] = m.label
            order[#order + 1] = m.key
        end
        return { type = "dropdown", text = item.label, values = values, order = order,
            getValue = function() return ColorMode(key) end,
            setValue = function(v) SetStyle(key .. "Mode", v); RefreshEUIPage() end }
    end
    if item.type == "toggle" then
        return { type = "toggle", text = item.label, getValue = item.get, setValue = item.set }
    elseif item.type == "range" then
        return { type = "slider", text = item.label, min = item.min, max = UI.Num(item.max), step = item.step,
            getValue = function() return Style(item.key) end, setValue = function(v) SetStyle(item.key, v) end }
    end
    local values, order = {}, {}
    for _, t in ipairs(item.list()) do
        values[t.key] = t.label
        order[#order + 1] = t.key
    end
    return { type = "dropdown", text = item.label, values = values, order = order,
        getValue = function() return Style(item.key) end, setValue = function(v) SetStyle(item.key, v) end }
end

-- Builds one section into parent, starting at y0 (negative = down), and returns
-- the y below its last row. native: parent is an EllesmereUI page, so its own
-- widgets are used (any that fail fall back to ours).
local function BuildPage(parent, group, x0, y0, native)
    local y = y0
    parent.amRefreshers = parent.amRefreshers or {}
    local refreshers = parent.amRefreshers
    local W = native and EllesmereUI and EllesmereUI.Widgets or nil
    -- one EllesmereUI widget: returns its height and frame, or nil when it could not be made
    local function Native(name, ...)
        if not (W and W[name]) then return nil end
        local ok, f, h = pcall(W[name], W, parent, ...)
        if ok and f then return (type(h) == "number") and h or 50, f end
        return nil
    end
    local headerH = Native("SectionHeader", group.name:upper(), y)
    if headerH then
        y = y - headerH
    else
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y - 6)
        title:SetText(group.name:upper())
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y - 24)
        line:SetSize(500, 1)
        local function paintLine()
            local r, g, b = AccentRGB()
            line:SetColorTexture(r, g, b, 0.6)
        end
        paintLine()
        refreshers[#refreshers + 1] = paintLine
        y = y - 34
    end
    local items = {}
    for _, item in ipairs(group.items) do
        if item.when and not item.when() then
            -- not shown with the current look
        elseif item.type == "eui" then
            if EllesmereUI then
                for _, sub in ipairs(item.items) do items[#items + 1] = sub end
            end
        else
            items[#items + 1] = item
        end
    end
    local ctlX = x0 + 190

    -- one item on a row of its own; returns the row's height
    local function BuildItem(item)
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
            rowH = Native("Slider", item.label, y, item.min, UI.Num(item.max), item.step, get, set)
            if not rowH then
                MakeLabel(parent, item.label, x0, y - 2)
                refreshers[#refreshers + 1] = MakeSlider(parent, ctlX, y, 130, item.min, UI.Num(item.max), item.step, get, set).refresh
            end
        elseif item.type == "choice" then
            local get = function() return Style(item.key) end
            local set = function(v) SetStyle(item.key, v) end
            local cfg = UI.NativeCfg(item)
            rowH = Native("Dropdown", item.label, y, cfg.values, get, set, cfg.order)
            if not rowH then
                MakeLabel(parent, item.label, x0, y - 2)
                refreshers[#refreshers + 1] = MakeChoice(parent, ctlX, y, 150, item.list, get, set).refresh
            end
        elseif item.type == "button" then
            local function after()
                if item.refreshAll then RefreshOptions() end
            end
            rowH = Native("Button", item.label, y, function() item.action(nil); after() end)
            if not rowH then
                local b
                b = MakeButton(parent, x0, y, 170, item.label, function() item.action(b); after() end)
                rowH = 30
            end
        elseif item.type == "text" then
            local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y - 4)
            fs:SetWidth(480)
            fs:SetJustifyH("LEFT")
            refreshers[#refreshers + 1] = function() fs:SetText(item.text()) end
            fs:SetText(item.text())
            rowH = item.height or 70
        elseif item.type == "buttongrid" then
            -- three checkboxes to a row
            local h = 0
            for i = 1, #item.entries, 3 do
                local cfgs = {}
                for j = 0, 2 do
                    local e = item.entries[i + j]
                    if e then
                        cfgs[j + 1] = { type = "toggle", text = e.title .. (e.custom and " (custom)" or ""),
                            getValue = function() return Enabled(e) end,
                            setValue = function(v) UI.SetEnabled(e, v) end }
                    end
                end
                local th = Native("TripleRow", y - h, cfgs[1], cfgs[2], cfgs[3], { 0.34, 0.33 })
                if not th then
                    for j = 0, 2 do
                        local e = item.entries[i + j]
                        if e then
                            local x = x0 + j * 168
                            refreshers[#refreshers + 1] = MakeToggle(parent, x, y - h,
                                function() return Enabled(e) end, function(v) UI.SetEnabled(e, v) end).refresh
                            MakeLabel(parent, e.title .. (e.custom and " (custom)" or ""), x + 26, y - h - 2, 138)
                        end
                    end
                    th = ROW
                end
                h = h + th
            end
            rowH = h
        end
        return rowH or ROW
    end

    local i = 1
    while i <= #items do
        local item, nxt = items[i], items[i + 1]
        local rowH
        if W and UI.Pairable(item) and nxt and UI.Pairable(nxt) then
            local row
            rowH, row = Native("DualRow", y, UI.NativeCfg(item), UI.NativeCfg(nxt))
            if rowH then
                UI.InlineSwatch(row and row._leftRegion, item)
                UI.InlineSwatch(row and row._rightRegion, nxt)
                i = i + 1
            end
        end
        rowH = rowH or BuildItem(item)
        y = y - rowH
        i = i + 1
    end
    parent.amRefresh = function()
        for _, f in ipairs(refreshers) do f() end
    end
    return y
end

-- ---- the stand-alone window: /amac options ----
UI.OPT_W, UI.OPT_H = 580, 640
UI.CONTENT_W = UI.OPT_W - 40

-- the thin bar on the right showing how far down the page is scrolled
function UI.UpdateScrollBar()
    local p = optionsPanel
    local pg = p and p.pages and p.current and p.pages[p.current]
    if not pg then return end
    local scroll, bar = pg.scroll, p.bar
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

function UI.PaintTabs()
    local p = optionsPanel
    if not p then return end
    local r, g, b = AccentRGB()
    for j, t in ipairs(p.tabs) do
        if j == p.current then
            t.bar:SetColorTexture(r, g, b, 1)
            t.text:SetTextColor(1, 1, 1)
        else
            t.bar:SetColorTexture(0.3, 0.3, 0.3, 0)
            t.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end
end

function UI.ShowTab(i)
    local p = optionsPanel
    local page = PAGES[i]
    p.current = i
    for j, pg in ipairs(p.pages) do
        if j ~= i then pg.scroll:Hide() end
    end
    for _, f in pairs(UI.headerFrames) do
        if f:GetParent() == p.headerHost and f.key ~= page.header then f:Hide() end
    end
    local h = 1
    if page.header then
        h = UI.ShowHeader(page.header, p.headerHost, UI.CONTENT_W, function(nh)
            p.headerHost:SetHeight(math.max(1, nh))
            UI.UpdateScrollBar()
        end)
    end
    p.headerHost:SetHeight(math.max(1, h))
    local pg = p.pages[i]
    if not pg.built then
        pg.built = true
        local y = 0
        for _, section in ipairs(UI.PageSections(page)) do
            y = BuildPage(pg.content, section, 0, y, false) - 10
        end
        pg.content:SetHeight(math.max(1, -y))
    end
    pg.scroll:SetVerticalScroll(0)
    pg.scroll:Show()
    if pg.content.amRefresh then pg.content.amRefresh() end
    UI.PaintTabs()
    UI.UpdateScrollBar()
    -- the scroll range is only known once the page has been laid out
    if C_Timer and C_Timer.After then C_Timer.After(0, UI.UpdateScrollBar) end
end

function UI.BuildOptions()
    if optionsPanel then return optionsPanel end
    local p = CreateFrame("Frame", "AutoMacrosOptions", UIParent)
    optionsPanel = p
    p:SetSize(UI.OPT_W, UI.OPT_H)
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
    MakeButton(p, UI.OPT_W - 16 - 24, -12, 24, "X", function() p:Hide() end)
    -- tabs
    p.tabs, p.pages = {}, {}
    local x = 16
    for i, page in ipairs(PAGES) do
        local t = CreateFrame("Button", nil, p)
        t.text = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t.text:SetPoint("CENTER", t, "CENTER", 0, 2)
        t.text:SetText(page.name)
        local w = math.max(70, (t.text:GetStringWidth() or 60) + 24)
        t:SetSize(w, 26)
        t:SetPoint("TOPLEFT", p, "TOPLEFT", x, -42)
        x = x + w + 4
        t.bar = t:CreateTexture(nil, "ARTWORK")
        t.bar:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 6, 0)
        t.bar:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -6, 0)
        t.bar:SetHeight(2)
        t:SetScript("OnClick", function() UI.ShowTab(i) end)
        p.tabs[i] = t
    end
    local line = p:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -69)
    line:SetPoint("TOPRIGHT", p, "TOPRIGHT", -16, -69)
    line:SetHeight(1)
    line:SetColorTexture(1, 1, 1, 0.1)
    -- the preview strip, then the settings, which scroll with the mouse wheel
    p.headerHost = CreateFrame("Frame", nil, p)
    p.headerHost:SetPoint("TOPLEFT", p, "TOPLEFT", 20, -74)
    p.headerHost:SetSize(UI.CONTENT_W, 1)
    for i in ipairs(PAGES) do
        local scroll = CreateFrame("ScrollFrame", nil, p)
        scroll:SetPoint("TOPLEFT", p.headerHost, "BOTTOMLEFT", -4, -8)
        scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -24, 16)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(UI.CONTENT_W, 10)
        scroll:SetScrollChild(content)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            local v = (self:GetVerticalScroll() or 0) - delta * 40
            if v > range then v = range end
            if v < 0 then v = 0 end
            self:SetVerticalScroll(v)
            UI.UpdateScrollBar()
        end)
        scroll:Hide()
        p.pages[i] = { scroll = scroll, content = content }
    end
    p.bar = p:CreateTexture(nil, "ARTWORK")
    p.bar:SetWidth(3)
    p.bar:Hide()
    p:SetScript("OnShow", function() UI.ShowTab(p.current or 1) end)
    if UISpecialFrames then table.insert(UISpecialFrames, "AutoMacrosOptions") end
    p:Hide()
    StyleOptions()
    return p
end

-- Brings everything on screen up to date after a change made elsewhere.
RefreshOptions = function()
    local p = optionsPanel
    if p and p:IsShown() and p.current then
        local pg = p.pages[p.current]
        if pg.content.amRefresh then pg.content.amRefresh() end
    end
    RefreshHeaders()
    RefreshEUIPage()
end

StyleOptions = function()
    RefreshHeaders()
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
    if p:IsShown() and p.current then
        local pg = p.pages[p.current]
        if pg.content.amRefresh then pg.content.amRefresh() end
        UI.PaintTabs()
        UI.UpdateScrollBar()
    end
end

-- ---- EllesmereUI: a page in its settings, and its look for the popup ----
-- Only the published EllesmereUI interfaces are used (RegisterSkin and
-- RegisterPlugin); everything is wrapped so a change on their side cannot
-- break this addon.
UI.skinRegistered, UI.pluginRegistered = false, false

function UI.FindPage(name)
    for _, page in ipairs(PAGES) do
        if page.name == name then return page end
    end
end

-- The preview strip builder for an EllesmereUI page (nil: the page has none).
-- One function per page, kept, as EllesmereUI caches the header by builder.
UI.euiHeaders = {}
function UI.EUIHeader(pageName)
    local page = UI.FindPage(pageName)
    if not (page and page.header) then return nil end
    local hb = UI.euiHeaders[pageName]
    if not hb then
        hb = function(host, width)
            return UI.ShowHeader(page.header, host, width, function(h)
                if EllesmereUI.UpdateContentHeaderHeight then
                    pcall(EllesmereUI.UpdateContentHeaderHeight, EllesmereUI, h)
                end
            end)
        end
        UI.euiHeaders[pageName] = hb
    end
    return hb
end

local function RegisterEUI()
    if not EllesmereUI then return end
    if not UI.skinRegistered and EllesmereUI.RegisterSkin then
        UI.skinRegistered = true
        local ok, err = pcall(EllesmereUI.RegisterSkin, "AutoMacros", function(S)
            skin = S
            if S.OnLooksChanged then pcall(S.OnLooksChanged, function() ApplyStyle() end) end
            ApplyStyle()
        end)
        if not ok then Fail("EllesmereUI skin", err) end
    end
    if not UI.pluginRegistered and EllesmereUI.RegisterPlugin then
        UI.pluginRegistered = true
        local names = {}
        for _, page in ipairs(PAGES) do names[#names + 1] = page.name end
        local ok, res = pcall(EllesmereUI.RegisterPlugin, "AutoMacros", {
            label = "AutoMacros",
            position = "bottom",
            modules = { {
                key = "options",
                title = "AutoMacros",
                description = "Consumable and teleport macros: buttons, highlight, flyout and item learning",
                pages = names,
                buildPage = function(pageName, parent, yOffset)
                    local y = yOffset or 0
                    local page = UI.FindPage(pageName)
                    if not page then return math.abs(y) end
                    -- EllesmereUI's own pages draw their preview strip from inside
                    -- the page build (getHeaderBuilder only brings it back when a
                    -- cached page is shown again), so this page does the same
                    local hb = UI.EUIHeader(pageName)
                    local prebuild = EllesmereUI.IsSearchPrebuild and EllesmereUI.IsSearchPrebuild()
                    if hb and not prebuild and EllesmereUI.SetContentHeader then
                        local okH, errH = pcall(EllesmereUI.SetContentHeader, EllesmereUI, hb)
                        if not okH then Fail("EllesmereUI preview", errH) end
                    end
                    for _, section in ipairs(UI.PageSections(page)) do
                        local ok2, newY = pcall(BuildPage, parent, section, 20, y, true)
                        if not ok2 then
                            Fail("EllesmereUI page", newY)
                            break
                        end
                        y = newY
                    end
                    return math.abs(y)
                end,
                -- the same builder again, when a cached page comes back
                getHeaderBuilder = function(pageName) return UI.EUIHeader(pageName) end,
                onReset = function() ResetStyle(); RefreshOptions() end,
            } },
        })
        -- (a refused spec returns false and EllesmereUI reports why; trying
        -- again would only be refused again, so that is left alone)
        if not ok then
            UI.pluginRegistered = false
            Fail("EllesmereUI page", res)
        end
    end
end
pcall(RegisterEUI)

local function OpenOptions(standalone)
    if not standalone and UI.pluginRegistered and EllesmereUI and EllesmereUI.OpenPlugin then
        local ok, opened = pcall(EllesmereUI.OpenPlugin, "AutoMacros")
        if ok and opened then return end
    end
    local p = UI.BuildOptions()
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

-- Not every client reports each change to the action bars (the uiforever
-- simulator can miss a macro being dropped on a button), so the bars are also
-- checked once a second: when what any button holds has changed, the highlight
-- and flyout tabs are redrawn. When no buttons have been found yet, the search
-- for them is repeated every 10 seconds.
local barSig, sinceCheck, sinceCollect = nil, 0, 0

local function BarSignature()
    local parts = {}
    for _, b in ipairs(buttons) do
        local ok, slot = pcall(ButtonSlot, b)
        if ok and slot then
            local kind, id = GetActionInfo(slot)
            local text = GetActionText and GetActionText(slot) or ""
            parts[#parts + 1] = tostring(kind) .. ":" .. tostring(id) .. ":" .. tostring(text)
        end
    end
    return table.concat(parts, "|")
end

local function WatchBars(elapsed)
    sinceCheck = sinceCheck + elapsed
    if sinceCheck < 1 then return end
    sinceCheck = 0
    if #buttons == 0 then
        sinceCollect = sinceCollect + 1
        if sinceCollect < 10 then return end
        sinceCollect = 0
        SafeCollect()
    end
    local ok, sig = pcall(BarSignature)
    if ok and sig ~= barSig then
        barSig = sig
        local ok2, err = pcall(RefreshGlow)
        if not ok2 then Fail("highlight/flyout", err) end
    end
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
frame:SetScript("OnUpdate", function(_, elapsed) WatchBars(elapsed) end)
for _, event in ipairs({
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED",
    "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP",
    "GET_ITEM_INFO_RECEIVED", "PLAYER_EQUIPMENT_CHANGED",
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
            if e.key == key or e.alias == key then return e end
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
        if verb ~= "add" then toDelete[e.key] = e end
        Print(e.title .. (verb == "add" and ": on" or (": off - its macro is deleted"
            .. (InCombatLockdown() and " when combat ends" or ""))))
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
            local e = find(name)
            if e and e.custom then
                e.removed = true
                toDelete[e.key] = e
            end
            if db.custom then db.custom[name] = nil end
            Print("custom category " .. name .. " removed, and its macro with it")
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
            local what = "nothing in bags"
            if r.id then what = (r.spell and (SpellName(r.id) or "spell") or ItemRef(r.id)) .. " [" .. r.id .. "]" end
            Print(m.name .. ": " .. what .. " - " .. r.result .. " (" .. r.size .. "/255 bytes)")
        end
    end
    Print("action buttons found: " .. #buttons .. ", highlighted: " .. (report.glowing or 0) .. ", flyout tabs: " .. (report.tabs or 0))
    local general, perChar = GetNumMacros()
    Print(string.format("macros: %s general, %s character; made new this session: %s", tostring(general),
        tostring(perChar), report.created and table.concat(report.created, ", ") or "none (all found from last time)"))
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
