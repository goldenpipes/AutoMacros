-- AutoMacros 0.88.2 for WoW Forever, Classic Era, TBC Anniversary, MoP Classic and
-- retail (Midnight); one file for all of them, see the .toc's Interface line.
-- Keeps one macro per category pointed at the best matching item in your bags,
-- so the macro can be dragged onto any action bar. Macros are only rewritten
-- out of combat. There are no built-in item lists: items are sorted by what the
-- game says about them (see "Learning new items") and the result is saved.

local ADDON = ...
local DATA = {}   -- item lists of your own categories (/amac custom), set name -> { [id] = true }

local function ToSet(list)
    local set = {}
    for _, id in ipairs(list) do set[id] = true end
    return set
end

local HEARTHSTONE = 6948
-- Spells on the Hearth/Teleport button, for whichever class knows them, on any
-- game version (spells you don't know are left out): Astral Recall (Shaman),
-- Teleport: Moonglade and Dreamwalk (Druid), Death Gate, Zen Pilgrimage, then
-- the mage teleports: vanilla cities, TBC, Wrath, Cata, MoP, Legion, WoD, BfA,
-- Shadowlands, Dragonflight, The War Within.
local TRAVEL_SPELLS = {
    556, 18960, 193753, 50977, 126892,
    3561, 3562, 3565, 3567, 3563, 3566,
    32271, 32272, 33690, 35715, 49359, 49358,
    53140, 88342, 88344, 132621, 132627, 120145,
    224869, 176248, 176242, 281403, 281404,
    344587, 395277, 446540,
}
-- Mage portals, in the same order (the first one is the button's icon).
local PORTAL_SPELLS = {
    10059, 11417, 11416, 11418, 11419, 11420,
    32266, 32267, 33691, 35717, 49360, 49361,
    53142, 88345, 88346, 132620, 132626, 120146,
    224871, 176246, 176244, 281400, 281402,
    344597, 395289, 446534,
}

-- Healthstone ranks: 1 Minor, 2 Lesser, 3 Healthstone, 4 Greater, 5 Major,
-- 6 Master (TBC). Talent variants share the rank; the higher ID is the
-- talented one. Since Wrath there is one Healthstone (5512, rank 1 here) and on
-- retail the Demonic Healthstone (224464, talent).
local HS_RANK = {
    [5512] = 1, [19004] = 1, [19005] = 1, [224464] = 1,
    [5511] = 2, [19006] = 2, [19007] = 2,
    [5509] = 3, [19008] = 3, [19009] = 3,
    [5510] = 4, [19010] = 4, [19011] = 4,
    [9421] = 5, [19012] = 5, [19013] = 5,
    [22103] = 6, [22104] = 6, [22105] = 6,
}
-- Create Healthstone spells, best rank first (6201 is also the only one since Wrath).
local CREATE_HS = { 27230, 11730, 11729, 5699, 6202, 6201 }


local QUESTION_MARK = 134400

-- Shown text is written in US English; a British English (enGB) client gets
-- the British spelling instead.
local function Loc(s)
    if type(s) == "string" and GetLocale and GetLocale() == "enGB" then
        s = s:gsub("([Cc])olor", "%1olour")
    end
    return s
end

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

-- The macro slot each button's macro was last found at, per character (macro
-- name -> index). Wiped after a macro is deleted, as the slots after it move up.
local function MacroSlots()
    local db = DB()
    if type(db.idx) ~= "table" then db.idx = {} end
    local key = CharKey()
    if type(db.idx[key]) ~= "table" then db.idx[key] = {} end
    return db.idx[key]
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
--   ignored           consumables checked and found to belong nowhere (see LearnNew)
--   glow, noFlyout, stockTooltip, showNames   on/off options
-- ---------------------------------------------------------------------------
local SCHEMA = 2
local CLASSIFIER = 4   -- raise when the learning rules change, so items are checked again

local STYLE_DEFAULTS = {
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

local function Style(key)
    local s = DB().style
    local v
    if type(s) == "table" then v = s[key] end   -- (a false value must survive, so no "and/or" here)
    if v == nil then v = STYLE_DEFAULTS[key] end
    if type(v) == "function" then v = v() end   -- a default worked out when asked (entryHover)
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
--   class    the logged-in character's class color
-- Opacity is shared by all of them and comes from style[<key>] or the default.
local COLOR_MODES = {
    { key = "default", label = "Default" },
    { key = "accent", label = "EllesmereUI accent" },
    { key = "custom", label = "Custom" },
    { key = "class", label = "Class" },
}

local function ColorMode(key)
    local s = DB().style
    local m = type(s) == "table" and s[key .. "Mode"] or nil
    if m then return m end
    if type(s) == "table" and s[key] ~= nil then return "custom" end   -- picked before modes existed
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
    elseif mode == "class" then
        local _, class = UnitClass("player")
        local cc = class and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
            or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]))
        if cc then return { cc.r, cc.g, cc.b, c[4] or 1 } end
    end
    if mode ~= "custom" then
        local d = STYLE_DEFAULTS[key]
        if type(d) == "function" then d = d() end   -- worked out when asked (entryHover)
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
    { key = "solid", label = Loc("Solid color") },
    { key = "glow", label = "Soft glow", glow = true },   -- drawn by StyleGlow (Blizzard's item-border glow)
    { key = "bar", label = "Status bar", path = "Interface\\TargetingFrame\\UI-StatusBar" },
}

-- forGlow: the highlight's choices, solid or soft glow (a picture border makes
-- no sense there); otherwise the flyout indicator's, every texture but the glow
local function TextureChoices(forGlow)
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

-- Items sorted into categories: db.learned (see "Learning new items" below),
-- plus DATA for your own categories.
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
--   placeholder: the icon shown when nothing is in your bags, { item = <itemID> }
--           for an item's icon or { icon = <iconFileID> } (1339440 is a red X)
local CATALOG = {
    { key = "healthstone", name = "AM_Healthstone", title = "Healthstone", empty = "No Healthstone", label = "Healthstones",
      special = "healthstone", scope = "character", default = true, placeholder = { item = 5509 } },
    { key = "healthpot", name = "AM_HealthPot", title = "Health Potion", empty = "No Health Potion", label = "health potions",
      set = "hpot", default = true, placeholder = { item = 3371 } },   -- Empty Vial
    { key = "manapot", name = "AM_ManaPot", title = "Mana Potion", empty = "No Mana Potion", label = "mana potions",
      set = "mpot", default = true, placeholder = { item = 3371 } },
    { key = "food", name = "AM_Food", title = "Food", empty = "No Food", label = "food", set = "food", default = true,
      placeholder = { item = 4540 } },   -- Tough Hunk of Bread
    { key = "water", name = "AM_Water", title = "Water", empty = "No Water", label = "water", set = "water", default = true,
      placeholder = { item = 159 } },    -- Refreshing Spring Water
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
      kind = "spells", spells = PORTAL_SPELLS, class = "MAGE", scope = "character" },
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
    print("|cff66ccffAutoMacros:|r " .. Loc(tostring(msg)))
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
-- Returns name, required level, link.
local function ItemInfo(id)
    local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not fn then return nil end
    local ok, a, b, c, d, e = pcall(fn, id)
    if not ok or a == nil then return nil end
    if type(a) == "table" then
        return a.itemName or a.name, a.itemMinLevel or a.minLevel or a.requiredLevel, a.hyperlink or a.itemLink
    end
    return a, e, b
end

-- What the game knows about an item without loading it: class, subclass,
-- icon, and the class and subclass names. nil when there is no data.
local function ItemInstant(id)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not fn then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, id)
    if not ok or a == nil then return nil end
    if type(a) == "table" then
        return a.classID, a.subclassID or a.subClassID, a.iconFileID or a.icon, a.itemType, a.itemSubType
    end
    return f, g, e, b, c
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
    local want = Picks()[m.name]
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

-- a spell's name (or nil), on clients with either spell API
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

local function KnowsSpell(id)
    local known = IsPlayerSpell or IsSpellKnown
    if not known then return false end
    local ok, k = pcall(known, id)
    return ok and k and true or false
end

local function CreateSpellName()
    for _, spellID in ipairs(CREATE_HS) do
        local name = KnowsSpell(spellID) and SpellName(spellID)
        if name then return name end
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

-- An icon: entry.icon, or the icon of item entry.item (a placeholder, say).
local function IconFor(entry)
    if not entry then return QUESTION_MARK end
    if entry.icon then return entry.icon end
    local _, _, icon = ItemInstant(entry.item)
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
-- Clicking an empty button runs "/amac empty <message>", which prints the
-- message in your own chat only (a plain text line would be said in /say for
-- everyone nearby; /run would need the game's script permission). The tooltip
-- message comes from the tooltip code below, not from the macro.
local function EmptyBody(label)
    return "/amac empty No " .. label .. " in inventory."
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

local function ScrollSpellKnown()
    if KnowsSpell(SCROLL_SPELL) then return true end
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
    local spell = SpellName(SCROLL_SPELL) or "Comprehend Scroll"
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
    for _, id in ipairs(m.spells or {}) do
        if KnowsSpell(id) then list[#list + 1] = { id = id } end
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

-- The slot of m's macro, or nil. checked: a macro found by name must also look
-- like this category's (a remembered slot always has to).
local function FindMacro(m, checked)
    -- 1. the slot remembered last time, if it still holds this macro
    local saved = MacroSlots()[m.name]
    if saved then
        local name, _, body = GetMacroInfo(saved)
        if name and BodyMatches(m, body) then return saved end
    end
    -- 2. its name (the macros are named after their category, or were once)
    local names = { m.title, m.empty, m.name }
    for _, n in ipairs(m.oldNames or {}) do names[#names + 1] = n end
    for _, n in ipairs(names) do
        local idx = GetMacroIndexByName(n)
        if idx and idx > 0 and (not checked or BodyMatches(m, GetMacroBody(idx))) then return idx end
    end
end

local function WantedName(m, active)
    return active and m.title or m.empty
end

local function Remember(m, idx)
    if type(idx) == "number" then MacroSlots()[m.name] = idx end
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
        if not ok then return "create failed: " .. tostring(result) end
        -- kept for /automacros: macros that had to be made again this session
        -- were not found from last time (lost on reload, or deleted)
        report.created = report.created or {}
        report.created[#report.created + 1] = want
        Remember(m, result)
        return "created"
    end
    local curName, curIcon = GetMacroInfo(idx)
    -- with #showtooltip the shown icon is the item's, and the client may report that
    -- instead of the macro's own, so only the placeholder icons are compared
    local sameIcon = active or type(curIcon) ~= "number" or curIcon == icon
    local sameName = curName == want
    if not sameName or (GetMacroBody(idx) or "") ~= body or not sameIcon then
        local ok, result = pcall(EditMacro, idx, want, icon, body)
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

-- ---- action button art, shared by the popup items and the settings demos ----
-- Blizzard's own textures, used when EllesmereUI is not drawing the buttons.
local BLIZZ_ART = {
    frame = "Interface\\Buttons\\UI-Quickslot2",
    hover = { kind = "tex", path = "Interface\\Buttons\\ButtonHilight-Square", blend = "ADD", r = 1, g = 1, b = 1 },
    push = { kind = "tex", path = "Interface\\Buttons\\UI-Quickslot-Depress", r = 1, g = 1, b = 1 },
    borderPx = { none = 0, thin = 1, normal = 2, heavy = 3, strong = 4 },
}

-- Popup items and settings previews are made from Blizzard's own
-- ActionButtonTemplate where the client has it (b.native = its size), so with
-- Blizzard's look they are the game's buttons exactly: frame, icon mask, hover,
-- pushed and checked art. They change size the way Edit Mode's Icon Size does,
-- by scale, never by stretching the art. Under EllesmereUI's look (and on a
-- client without the template) they are sized normally and drawn by us.
function BLIZZ_ART.Size(b, size)
    if b.native and not b.euiLook then
        b.k = size / b.native
        b:SetScale(b.k)
        b:SetSize(b.native, b.native)
    else
        b.k = 1
        b:SetScale(1)
        b:SetSize(size, size)
    end
end

-- SetPoint for such a button, with x and y in its parent's units (a scaled
-- frame reads its offsets in its own, scaled units)
function BLIZZ_ART.Point(b, point, rel, relPoint, x, y)
    local k = b.k or 1
    b:ClearAllPoints()
    b:SetPoint(point, rel, relPoint, x / k, y / k)
end

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
            -- a button's highlight texture is drawn added on (a glow over the
            -- icon); its pushed texture is drawn normally
            if prefix == "highlight" then spec.blend = "ADD" end
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

-- Blizzard's action buttons (retail's, with an icon mask) have cut corners:
-- in the art (uiactionbar2x, the frame is 88 px wide) the straight top edge
-- starts 9 px in from each side, and the frame is drawn 46 wide on a 45 wide
-- button, so each corner takes this much of the button's width (about 10.4%).
-- EllesmereUI's and classic's buttons are square.
BLIZZ_ART.CORNER = (9 / 88) * (46 / 45)
function BLIZZ_ART.Rounded()
    local b = _G.ActionButton1
    return not EUIButtonLook() and b ~= nil and b.IconMask ~= nil
end

-- A solid border in the shape of Blizzard's buttons around frame g's edge,
-- size thick (in g's units), color c, its corners cut cut back: straight edges
-- that stop where the corners are cut, and each cut corner drawn as a pixel
-- staircase (as Blizzard's art is), one size x size square per screen pixel
-- along it, so it is crisp at any thickness. All thickens inwards.
function BLIZZ_ART.CutBorder(g, cut, size, c)
    local px = PixelSize(g)
    local n = math.max(1, math.floor(cut / px + 0.5))   -- the cut, in whole pixels
    cut = n * px
    local e = g.edges
    for i = 1, 4 do
        e[i]:ClearAllPoints()
        Paint(e[i], "solid", c)
        e[i]:Show()
    end
    e[1]:SetPoint("TOPLEFT", g, "TOPLEFT", cut, 0); e[1]:SetPoint("TOPRIGHT", g, "TOPRIGHT", -cut, 0); e[1]:SetHeight(size)
    e[2]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", cut, 0); e[2]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", -cut, 0); e[2]:SetHeight(size)
    e[3]:SetPoint("TOPLEFT", g, "TOPLEFT", 0, -cut); e[3]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 0, cut); e[3]:SetWidth(size)
    e[4]:SetPoint("TOPRIGHT", g, "TOPRIGHT", 0, -cut); e[4]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", 0, cut); e[4]:SetWidth(size)
    -- each corner: the pixels just inside the cut, (x, y) with x + y = n - 1
    -- counted from that corner, each grown size x size towards the inside
    local corners = { { "TOPLEFT", 1, -1 }, { "TOPRIGHT", -1, -1 }, { "BOTTOMLEFT", 1, 1 }, { "BOTTOMRIGHT", -1, 1 } }
    g.cells = g.cells or {}
    local used = 0
    for _, cn in ipairs(corners) do
        local point, sx, sy = cn[1], cn[2], cn[3]   -- (sx, sy: towards the inside)
        for x = 0, n - 1 do
            used = used + 1
            local t = g.cells[used]
            if not t then
                t = g:CreateTexture(nil, "OVERLAY")
                g.cells[used] = t
            end
            Paint(t, "solid", c)
            t:ClearAllPoints()
            t:SetSize(size, size)
            t:SetPoint(point, g, point, sx * x * px, sy * (n - 1 - x) * px)
            t:Show()
        end
    end
    for i = used + 1, #g.cells do g.cells[i]:Hide() end
end

-- the flyout indicator's height in screen pixels: 1 to 5 (more looks clunky)
function BLIZZ_ART.TabHeight()
    return math.max(1, math.min(5, tonumber(Style("tabHeight")) or 3))
end

-- The small tab on a button that has a flyout. Width is UI units (like the
-- button), height screen pixels; never wider than the button's straight top
-- edge (between rounded corners), and placed on whole pixels so its edges stay sharp.
local function StyleArrow(a)
    local px = PixelSize(a)
    local b = a.button
    local bw = b and b:GetWidth() or 0
    if type(bw) ~= "number" or bw <= 0 then bw = 36 end
    local bwPx = math.floor(bw / px + 0.5)
    local maxPx = bwPx
    if BLIZZ_ART.Rounded() then maxPx = math.floor(bwPx * (1 - 2 * BLIZZ_ART.CORNER)) end
    local wPx = math.min(math.floor(BarUnits(a, Style("tabWidth")) / px + 0.5), maxPx)
    a:SetSize(math.max(wPx, 0.01) * px, BLIZZ_ART.TabHeight() * px)   -- 0: nothing to see
    if b then
        a:ClearAllPoints()
        a:SetPoint("BOTTOMLEFT", b, "TOPLEFT", math.floor((bwPx - wPx) / 2) * px, -3 * px)
    end
    Paint(a.tex, Style("tabTexture"), StyleColor("tabColor"))
end

-- The hover color's Default: your action bars' hover
-- color, EllesmereUI's (its Bar Animations page) or Blizzard's pale yellow.
-- Its opacity is only used by fill hovers.
STYLE_DEFAULTS.entryHover = function()
    local look = EUIButtonLook()
    local h = look and look.hover
    if h and h.kind ~= "none" then return { h.r, h.g, h.b, 1 } end
    return { 1, 0.93, 0.6, 1 }
end

-- The Hover setting, for everything we draw like an action button (popup
-- items, settings previews), put into StyleButtonArt's options o. On Default,
-- your action bars' own hover; otherwise their kind of hover (EllesmereUI's
-- glow, fill or border; Blizzard's texture, desaturated) in that color. Its
-- opacity applies in every mode (o.hoverAlpha with Blizzard's look).
local function ApplyHover(o)
    local c = StyleColor("entryHover")
    local alpha = c[4] or 1
    local tint = ColorMode("entryHover") ~= "default"
    local h = o.look and o.look.hover
    if h then
        if tint then h.r, h.g, h.b = c[1], c[2], c[3] end
        h.a = (h.a or 1) * alpha
    else
        o.hoverAlpha = alpha
        if tint then o.hover = c end
    end
    return o
end

-- ---------------------------------------------------------------------------
-- Highlight: a pulsing border on any action button holding a macro whose
-- category is empty. It only touches our own frames, so it also works in combat.
-- Colour, thickness, texture and pulse come from the saved style. Two looks:
-- a solid border, or a soft glow inside the button.
-- ---------------------------------------------------------------------------

-- tex as colour c fading to clear: full at the button's edge (side "top",
-- "bottom", "left" or "right"), clear towards the middle
local function FadeEdge(tex, side, c)
    local a = c[4] or 1
    local orient = (side == "top" or side == "bottom") and "VERTICAL" or "HORIZONTAL"
    -- VERTICAL runs bottom to top, HORIZONTAL left to right
    local a1, a2 = a, 0
    if side == "top" or side == "right" then a1, a2 = 0, a end
    pcall(tex.SetVertexColor, tex, 1, 1, 1, 1)
    tex:SetColorTexture(1, 1, 1, 1)
    local ok = false
    if CreateColor then
        ok = pcall(tex.SetGradient, tex, orient, CreateColor(c[1], c[2], c[3], a1), CreateColor(c[1], c[2], c[3], a2))
    end
    if not ok and tex.SetGradientAlpha then
        ok = pcall(tex.SetGradientAlpha, tex, orient, c[1], c[2], c[3], a1, c[1], c[2], c[3], a2)
    end
    if not ok then tex:SetColorTexture(c[1], c[2], c[3], a * 0.5) end   -- no gradients: a faint band
end

-- Blizzard's item-border glow, used for the soft glow on Blizzard's buttons
BLIZZ_ART.GLOW = "Interface\\Buttons\\UI-ActionButton-Border"

local function StyleGlow(g, button)
    local c = StyleColor("glowColor")
    local t = math.max(1, math.min(5, tonumber(Style("glowThickness")) or 3))   -- 1 to 5
    local px = PixelSize(button)
    local soft = TextureInfo(Style("glowTexture")).glow
    local look = EUIButtonLook()
    local rounded = BLIZZ_ART.Rounded()   -- retail's buttons: cut corners
    -- always inside the button (inside EllesmereUI's border for its soft glow)
    local inset = (soft and look) and look.size * px or 0
    g:ClearAllPoints()
    g:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    g:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
    for i = 1, 4 do g.edges[i]:Hide() end
    if g.soft then g.soft:Hide() end
    for _, cell in ipairs(g.cells or {}) do cell:Hide() end
    if soft and look then
        -- EllesmereUI's square buttons: fading in from the edges over the icon,
        -- thickness x3 screen pixels deep
        local w = button:GetWidth()
        if type(w) ~= "number" or w <= 0 then w = 36 end
        local d = math.min(t * 3 * px, w * 0.45)
        local e = g.edges
        for i = 1, 4 do e[i]:ClearAllPoints(); e[i]:Show() end
        e[1]:SetPoint("TOPLEFT", g, "TOPLEFT", 0, 0); e[1]:SetPoint("TOPRIGHT", g, "TOPRIGHT", 0, 0); e[1]:SetHeight(d)
        e[2]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 0, 0); e[2]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", 0, 0); e[2]:SetHeight(d)
        e[3]:SetPoint("TOPLEFT", g, "TOPLEFT", 0, 0); e[3]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 0, 0); e[3]:SetWidth(d)
        e[4]:SetPoint("TOPRIGHT", g, "TOPRIGHT", 0, 0); e[4]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", 0, 0); e[4]:SetWidth(d)
        for i, side in ipairs({ "top", "bottom", "left", "right" }) do FadeEdge(e[i], side, c) end
    elseif soft then
        -- Blizzard's item-border glow over the button, tinted. Its ring sits on
        -- the button's edge; showing more of the art around it (less cropped)
        -- makes the glow reach further in, so thickness sets the crop. Drawn
        -- added on, so opacity dims the color itself. Clipped to the button's
        -- shape on retail.
        if not g.soft then g.soft = g:CreateTexture(nil, "OVERLAY") end
        local s = g.soft
        s:SetTexture(BLIZZ_ART.GLOW)
        pcall(s.SetBlendMode, s, "ADD")
        local crop = math.max(0.02, 0.21 - (t - 1) * 0.035)
        s:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
        s:ClearAllPoints()
        s:SetAllPoints(g)
        local a = c[4] or 1
        s:SetVertexColor(c[1] * a, c[2] * a, c[3] * a, 1)   -- (its ring is already rounded)
        s:Show()
    elseif rounded then
        -- On the button's frame ring. In the frame art (88 px wide in
        -- uiactionbar2x, drawn 46 wide on a 45 wide button) the grey ring starts
        -- 1 px in from the edge and the corners are cut 9 px back; so: in from
        -- the button by one art pixel, corners cut 8 more, on whole screen pixels.
        local w = button:GetWidth()
        if type(w) ~= "number" or w <= 0 then w = 36 end
        local unit = w * (46 / 45) / 88   -- one pixel of the art, in the button's units
        local ins = math.max(px, Snap(g, unit))
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", button, "TOPLEFT", ins, -ins)
        g:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -ins, ins)
        BLIZZ_ART.CutBorder(g, Snap(g, unit * 8), math.max(px, Snap(g, t * px)), c)
    else
        -- square buttons: a plain border, thickening inwards
        for i = 1, 4 do Paint(g.edges[i], "solid", c) end
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

-- Gives button b (with b.icon) the parts StyleButtonArt draws with when the
-- game's own art is not used: slot background, frame, border, selected
-- border, hover and pushed layers.
local function ButtonArt(b)
    b.slot = b:CreateTexture(nil, "BACKGROUND", nil, -8)   -- under the icon
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
    -- a recolored texture is greyed first, so the color is not mixed with its own
    pcall(tex.SetDesaturated, tex, spec.desat and true or false)
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
-- nil for Blizzard's. o.size: its size (see BLIZZ_ART.Size). With Blizzard's
-- look, o.hover recolors the hover. o.sel (+ o.selSize): the selected item's
-- border, in the button's own shape with Blizzard's look (its checked art),
-- square with EllesmereUI's.
BLIZZ_ART.none = { kind = "none" }   -- no hover or pushed effect of ours
local function StyleButtonArt(b, o)
    local look = o.look
    b.euiLook = look and true or nil
    if o.size then b.want = o.size end
    if b.want then BLIZZ_ART.Size(b, b.want) end
    local tpl = b.native ~= nil   -- made from Blizzard's template
    if tpl then
        -- the template's own art: shown with Blizzard's look, hidden under EllesmereUI's
        local blizz = not look
        for _, t in ipairs({ b:GetNormalTexture(), b:GetHighlightTexture(), b:GetPushedTexture() }) do
            if t then t:SetAlpha(blizz and 1 or 0) end
        end
        if b.SlotBackground then b.SlotBackground:SetShown(blizz) end
        if b.IconMask and b.masked ~= blizz then
            pcall(blizz and b.icon.AddMaskTexture or b.icon.RemoveMaskTexture, b.icon, b.IconMask)
            b.masked = blizz
        end
        -- selected: the template's checked border, as a pet bar button shows
        -- its active state; o.selTint recolors it with the selected color
        local ct = b:GetCheckedTexture()
        if ct then
            local c = (not look) and o.sel
            b.amChecked = c and true or false
            b:SetChecked(b.amChecked)
            ct:SetAlpha(c and 1 or 0)
            if c then
                local tint = o.selTint and c or nil
                pcall(ct.SetDesaturated, ct, tint and true or false)
                -- (its opacity applies on Default too)
                if tint then ct:SetVertexColor(c[1], c[2], c[3], c[4] or 1) else ct:SetVertexColor(1, 1, 1, c[4] or 1) end
            end
        end
    end
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
        PlaceEdges(b.edges, b, 0)
        if tpl then
            b.normal:Hide()
            -- the template's own hover and pushed art; o.hover recolors the hover
            local ht = b:GetHighlightTexture()
            if ht then
                pcall(ht.SetDesaturated, ht, o.hover and true or false)
                local h = o.hover or { 1, 1, 1 }
                ht:SetVertexColor(h[1], h[2], h[3], o.hoverAlpha or 1)
            end
            PaintInteraction(b.hl, b.hlEdges, b, BLIZZ_ART.none)
            PaintInteraction(b.push, b.pushEdges, b.pushLayer, BLIZZ_ART.none)
        else   -- no template on this client: Blizzard's classic frame and hover
            b.normal:SetSize(b:GetWidth() * 66 / 36, b:GetHeight() * 66 / 36)
            b.normal:Show()
            local hover = { kind = "tex", path = BLIZZ_ART.hover.path, blend = BLIZZ_ART.hover.blend,
                r = 1, g = 1, b = 1, a = o.hoverAlpha }
            if o.hover then
                hover.r, hover.g, hover.b, hover.desat = o.hover[1], o.hover[2], o.hover[3], true
            end
            b.hl:ClearAllPoints()
            b.hl:SetAllPoints(b)
            b.push:ClearAllPoints()
            b.push:SetAllPoints(b)
            PaintInteraction(b.hl, b.hlEdges, b, hover)
            PaintInteraction(b.push, b.pushEdges, b.pushLayer, BLIZZ_ART.push)
        end
    end
    -- our own square selected border: EllesmereUI's look, or no template
    if o.sel and not (tpl and not look) then
        for i = 1, 4 do b.sel[i]:SetColorTexture(o.sel[1], o.sel[2], o.sel[3], o.sel[4] or 1) end
        PlaceEdges(b.sel, b, o.selSize or 2)
    else
        PlaceEdges(b.sel, b, 0)
    end
end

-- One item button in the popup: Blizzard's own action button, or with
-- EllesmereUI's look one like your EllesmereUI bars. Hover: see ApplyHover.
local function StyleEntry(e)
    -- in the popup's units (the item itself may be scaled), on whole pixels
    local o = ApplyHover({ look = EUIButtonLook(), size = BLIZZ_ART.ItemSize(e:GetParent()) })
    if e.selected then
        o.sel, o.selSize = StyleColor("selectedColor"), Style("selectedSize")
        o.selTint = ColorMode("selectedColor") ~= "default"   -- Default: Blizzard's own color
    end
    StyleButtonArt(e, o)
    if SkinActive() and skin.GetFont then
        local ok, font = pcall(skin.GetFont)
        if ok and type(font) == "string" then pcall(e.count.SetFont, e.count, font, 11, "OUTLINE") end
    end
end

-- The main action bar's frame art (MainActionBar / MainMenuBar .BorderArt,
-- what Edit Mode's Hide Bar Art turns off) on texture t, with its nine-slice
-- margins so it frames any size; false when this client has none.
function BLIZZ_ART.BarArt(t)
    local bar = _G.MainActionBar or _G.MainMenuBar
    local art = bar and bar.BorderArt
    local atlas = art and art.GetAtlas and art:GetAtlas()
    if type(atlas) ~= "string" or atlas == "" then return false end
    local ok, found = pcall(t.SetAtlas, t, atlas)
    if not ok or found == false then return false end
    t:SetVertexColor(1, 1, 1, 1)
    if art.GetTextureSliceMargins and t.SetTextureSliceMargins then
        local okM, l, top, r, bottom = pcall(art.GetTextureSliceMargins, art)
        if okM and l then
            pcall(t.SetTextureSliceMargins, t, l, top, r, bottom)
            if art.GetTextureSliceMode then pcall(t.SetTextureSliceMode, t, art:GetTextureSliceMode()) end
        end
    end
    return true
end

-- true while the popup shows a background (Blizzard's look, switched on)
function BLIZZ_ART.PopupArt()
    return not EUIButtonLook() and Style("flyoutArt") ~= false
end

-- How far the bar art reaches past the main bar's buttons on each side (left,
-- top, right, bottom), in frame f's units, so the popup's art sits around its
-- items the same way. 4 each when the bar cannot be read.
function BLIZZ_ART.BarInsets(f)
    local ok, l, t, r, b = pcall(function()
        local bar = _G.MainActionBar or _G.MainMenuBar
        local art = bar.BorderArt
        local left, top, right, bottom
        for i = 1, 12 do
            local btn = _G["ActionButton" .. i]
            if btn and btn:GetLeft() then
                left = math.min(left or btn:GetLeft(), btn:GetLeft())
                right = math.max(right or btn:GetRight(), btn:GetRight())
                top = math.max(top or btn:GetTop(), btn:GetTop())
                bottom = math.min(bottom or btn:GetBottom(), btn:GetBottom())
            end
        end
        local k = _G.ActionButton1:GetEffectiveScale() / f:GetEffectiveScale()
        return (left - art:GetLeft()) * k, (art:GetTop() - top) * k,
            (art:GetRight() - right) * k, (bottom - art:GetBottom()) * k
    end)
    local function sane(v) return (type(v) == "number" and v >= 0 and v <= 30) and v or 4 end
    if not ok then return 4, 4, 4, 4 end
    return sane(l), sane(t), sane(r), sane(b)
end

-- The space the main bar leaves between its buttons (ActionButton1 to 2, side
-- by side or stacked), in frame f's units; 0 when it cannot be read.
function BLIZZ_ART.BarGap(f)
    local ok, g = pcall(function()
        local a, b = _G.ActionButton1, _G.ActionButton2
        local k = a:GetEffectiveScale() / f:GetEffectiveScale()
        return math.max(b:GetLeft() - a:GetRight(), a:GetBottom() - b:GetTop()) * k
    end)
    if ok and type(g) == "number" and g >= 0 and g <= 20 then return g end
    return 0
end

-- How much smaller (or bigger) the popup's items are than the main bar's
-- buttons. The popup's bar art, dividers and spacing scale by this, as a whole
-- bar does with Edit Mode's Icon Size. 1 when the bar cannot be read.
function BLIZZ_ART.ArtScale(f)
    local ok, s = pcall(function()
        local b = _G.ActionButton1
        return BLIZZ_ART.ItemSize(f) / (b:GetWidth() * b:GetEffectiveScale() / f:GetEffectiveScale())
    end)
    if ok and type(s) == "number" and s > 0.1 and s < 10 then return s end
    return 1
end

-- A divider the main bar uses between buttons stacked one above the other (a
-- vertical bar in Edit Mode): a frame from its VerticalDividersPool, one in use
-- if the bar is vertical now, otherwise a spare one. nil when there is none.
function BLIZZ_ART.DividerSource()
    local bar = _G.MainActionBar or _G.MainMenuBar
    local pool = bar and bar.VerticalDividersPool
    if not pool then return nil end
    local function pick(a, b)   -- pools hand out (object, true) or (index, object)
        if type(a) == "table" and a.GetRegions then return a end
        if type(b) == "table" and b.GetRegions then return b end
    end
    local found
    pcall(function() for a, b in pool:EnumerateActive() do found = found or pick(a, b) end end)
    if not found and pool.EnumerateInactive then
        pcall(function() for a, b in pool:EnumerateInactive() do found = found or pick(a, b) end end)
    end
    return found
end

-- Gives our frame dst a copy of Blizzard frame src's textures: the same art,
-- draw layers, colors, sizes and anchors (to the frame and to each other).
function BLIZZ_ART.Clone(src, dst)
    local made, list = {}, {}
    for _, r in ipairs({ src:GetRegions() }) do
        if r:GetObjectType() == "Texture" then
            local layer, sub = r:GetDrawLayer()
            local t = dst:CreateTexture(nil, layer, nil, sub)
            local atlas = r:GetAtlas()
            if type(atlas) == "string" and atlas ~= "" then
                t:SetAtlas(atlas)
            else
                t:SetTexture(r:GetTexture())
                t:SetTexCoord(r:GetTexCoord())
            end
            pcall(t.SetBlendMode, t, r:GetBlendMode())
            t:SetVertexColor(r:GetVertexColor())
            t:SetShown(r:IsShown())
            made[r] = t
            list[#list + 1] = r
        end
    end
    for _, r in ipairs(list) do
        local t = made[r]
        t:SetSize(r:GetWidth(), r:GetHeight())   -- (anchors on both sides win over this)
        local n = r:GetNumPoints()
        for i = 1, n do
            local point, rel, relPoint, x, y = r:GetPoint(i)
            rel = (rel == nil or rel == src) and dst or made[rel]
            if rel then t:SetPoint(point, rel, relPoint, x, y) end
        end
        if n == 0 then t:SetAllPoints(dst) end
    end
    return #list > 0
end

-- Draws the main bar's divider between the n items stacked in popup f (size
-- tall, gap apart, the first pad up from the bottom): copies of one of its
-- dividers, at its scale. Hidden when on is false or there is none to copy.
function BLIZZ_ART.Dividers(f, on, n, size, gap, pad)
    f.dividers = f.dividers or {}
    local src = on and BLIZZ_ART.DividerSource()
    if src and not f.dividerLayer then   -- above the items, as on the bar
        f.dividerLayer = CreateFrame("Frame", nil, f)
        f.dividerLayer:SetAllPoints()
        f.dividerLayer:SetFrameLevel(f:GetFrameLevel() + 10)
    end
    local k, w, h = 1, 0, 0
    if src then
        -- the bar's scale, times how much the items differ from its buttons
        k = src:GetEffectiveScale() / f:GetEffectiveScale() * BLIZZ_ART.ArtScale(f)
        w, h = src:GetWidth() or 0, src:GetHeight() or 0
        if w <= 0 or h <= 0 then   -- a spare one is not laid out: item wide, as tall as its art
            w = size / k
            for _, r in ipairs({ src:GetRegions() }) do h = math.max(h, r:GetHeight() or 0) end
        end
    end
    for i = 1, math.max(#f.dividers, n - 1) do
        local d = f.dividers[i]
        if src and i <= n - 1 then
            if not d then
                d = CreateFrame("Frame", nil, f.dividerLayer)
                if not pcall(BLIZZ_ART.Clone, src, d) then d.broken = true end
                f.dividers[i] = d
            end
            d:SetScale(k)
            d:SetSize(w, h)
            d:ClearAllPoints()
            d:SetPoint("CENTER", f, "BOTTOM", 0, (pad + i * (size + gap) - gap / 2) / k)
            d:SetShown(not d.broken)
        elseif d then
            d:Hide()
        end
    end
end

-- The popup frame. With Blizzard's look its background is the action bar's
-- frame art, switched by "Show background" like the bar art in Edit Mode (a
-- client without that art gets a plain dark backing). With EllesmereUI's look
-- it is see-through, so the items stand on their own like buttons on its bars.
-- The art sits on its own frame, scaled with the items (BLIZZ_ART.ArtScale).
local function StyleFlyout(f)
    if not BLIZZ_ART.PopupArt() then
        if f.art then f.art:Hide() end
        return
    end
    if not f.art then
        f.art = CreateFrame("Frame", nil, f)
        f.art:SetFrameLevel(f:GetFrameLevel())   -- under the items
        f.art.tex = f.art:CreateTexture(nil, "BACKGROUND")
        f.art.tex:SetAllPoints()
    end
    local t = f.art.tex
    if not BLIZZ_ART.BarArt(t) then
        pcall(t.SetVertexColor, t, 1, 1, 1, 1)
        t:SetColorTexture(0, 0, 0, 0.5)
    end
    -- around the items, reaching out past them as the bar art does (the
    -- offsets are in the art frame's own, scaled units, so they scale too)
    local l, top, r, b = BLIZZ_ART.BarInsets(f)
    f.art:SetScale(BLIZZ_ART.ArtScale(f))
    f.art:ClearAllPoints()
    f.art:SetPoint("TOPLEFT", f, "TOPLEFT", -l, top)
    f.art:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", r, -b)
    f.art:Show()
end

local buttons = {}        -- action buttons found on screen

-- The width and height of your action buttons in UI units, the number
-- EllesmereUI's Icon Size shows (its border is inside the button, so it is
-- included), as they are on screen (bars may be scaled).
function BLIZZ_ART.BarButtonSize()
    local b = buttons[1] or _G.ActionButton1
    local w, h = b and b:GetWidth(), b and b:GetHeight()
    if type(w) ~= "number" or w <= 0 then return 45, 45 end
    if type(h) ~= "number" or h <= 0 then h = w end
    local k = b:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return math.max(8, math.floor(w * k + 0.5)), math.max(8, math.floor(h * k + 0.5))
end

-- The popup items' size in frame f's units: Item size, a percentage like Edit
-- Mode's Icon Size, of a stock action button (Blizzard's template at its own
-- size); with EllesmereUI's look, of your EllesmereUI buttons.
function BLIZZ_ART.ItemSize(f)
    local base = EUIButtonLook() and (BLIZZ_ART.BarButtonSize()) or BLIZZ_ART.native or 36
    return BarUnits(f, base * (tonumber(Style("itemScale")) or 100) / 100)
end
local glows = {}          -- button -> border frame
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
    emptyName = {}
    macroAt = {}
    local saved = MacroSlots()
    for _, m in ipairs(MACROS) do
        local idx = saved[m.name]
        if idx then
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

-- ---------------------------------------------------------------------------
-- Learning new items. Every item you carry is sorted
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
-- item classes worth a look: consumable, armour, trade goods, miscellaneous
local LOOKED_AT = { [0] = true, [4] = true, [7] = true, [15] = true }
local STAT_KEYS = { "strength", "agility", "stamina", "intellect" }   -- SPELL_STAT1..4_NAME

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

local function HasWord(low, ...)
    for i = 1, select("#", ...) do
        local w = select(i, ...)
        if type(w) == "string" and w ~= "" and low:find(w:lower(), 1, true) then return true end
    end
    return false
end

-- Returns a list of set names (empty: belongs nowhere), or nil when the game has
-- not delivered the item's data yet, or not its "Use:" text (tried again a
-- second later, see Update).
-- The second result is the item's signature: a number made from everything the
-- rules looked at (class, subclass, the "Use:" and "well fed" lines with their
-- numbers left out, so cooldowns and scaling do not count). LearnNew compares
-- it once a session to notice an item Blizzard has changed.
local function Classify(id)
    local class, sub = ItemInstant(id)
    if class == nil then return nil end
    local sig = class * 1000 + (tonumber(sub) or 0)
    if not LOOKED_AT[class] then return {}, sig end
    if class == 0 and sub == 7 then return { "bandage" }, sig end
    if class == 0 and sub == 3 then return { "flask" }, sig end
    if class == 7 and sub == 2 then return { "explosives" }, sig end
    if class == 7 then return {}, sig end
    local lines = TooltipLines(id)
    if not lines or #lines < 2 or lines[1] == RETRIEVING_ITEM_INFO then return nil end
    local use = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    local health, mana, rage, damage, weapon, travel, wellFed, cure = false, false, false, false, false, false, false, false
    local stats, hasUse = {}, false
    for _, text in ipairs(lines) do
        local low = text:lower()
        if text:find(use, 1, true) then hasUse = true end
        if low:find("well fed", 1, true) or text:find(use, 1, true) then
            for i = 1, #low do
                local c = low:byte(i)
                if c < 48 or c > 57 then sig = (sig * 31 + c) % 2147483629 end
            end
        end
        if low:find("well fed", 1, true) then wellFed = true end
        if text:find(use, 1, true) then
            if HasWord(low, "teleport", "returns you to") then travel = true end
            if HasWord(low, "weapon") then weapon = true end
            if HasWord(low, "poison") and HasWord(low, "cure", "remove") then cure = true end
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
    if not hasUse then
        -- The item has a use effect but its "Use:" text has not arrived yet (the
        -- game loads the spell's text after the item): ask for it, try again later.
        local getSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell
        local ok, _, spellID = pcall(getSpell, id)
        if ok and spellID then
            if C_Spell and C_Spell.RequestLoadSpellData then pcall(C_Spell.RequestLoadSpellData, spellID) end
            return nil
        end
    end
    if travel then return { "travel" }, sig end
    if class ~= 0 then return {}, sig end     -- armour and misc items: only teleports count
    if cure then return { "antivenom" }, sig end   -- "Use: Cures 1 poison effect ..."
    local sets = {}
    if sub == 5 then
        if wellFed then return { "food_buff" }, sig end
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
    return sets, sig
end

local function SetTitle(setName)
    for _, e in ipairs(ALL) do
        if e.set == setName then return e.title, e.key end
    end
    return setName
end

local sessionDone = {}   -- item IDs not worth looking at again this session
local attempts = {}      -- item ID -> tries while the game had no data for it

-- Each item is sorted once and the result saved with its signature (see
-- Classify). Once a session, the first time an item is in your bags, its
-- signature is worked out again; only when it differs (Blizzard changed the
-- item) is the item sorted again. Hand-made results (/amac assign, unassign)
-- are never touched. Saved as:
--   learned[id] = { sets = {...}, how = "auto" | "manual", sig = n }
--   ignored[id] = { sig = n }   checked, belongs nowhere
--   ignored[id] = "manual"      /amac unassign
-- (Before 0.85.0 both kinds of ignored were a number; those count as automatic
-- and are checked once more.)
-- Returns true while items are left to look at (no data yet, or over budget).
local function LearnNew(have)
    local db = DB()
    local budget, changed, waiting = 40, false, false
    for id in pairs(have) do
        if budget <= 0 then waiting = true break end
        local rec = type(db.learned) == "table" and db.learned[id] or nil
        local ign = type(db.ignored) == "table" and db.ignored[id] or nil
        local manual = (type(rec) == "table" and rec.how == "manual") or ign == "manual"
        if not sessionDone[id] and manual then
            sessionDone[id] = true
        end
        if not sessionDone[id] then
            local class = ItemInstant(id)
            if class ~= nil and not LOOKED_AT[class] then
                sessionDone[id] = true            -- nothing any button uses
            elseif class ~= nil then
                budget = budget - 1
                local sets, sig = Classify(id)
                if sets == nil then
                    attempts[id] = (attempts[id] or 0) + 1
                    if attempts[id] > 20 then sessionDone[id] = true else waiting = true end
                else
                    sessionDone[id] = true
                    local old = type(rec) == "table" and rec or (type(ign) == "table" and ign) or nil
                    if not (old and old.sig == sig) then
                        -- new, changed, or saved before signatures (then usually the same result)
                        local before = old and old.sets and table.concat(old.sets, "+") or ""
                        if type(db.learned) ~= "table" then db.learned = {} end
                        if type(db.ignored) ~= "table" then db.ignored = {} end
                        if #sets == 0 then
                            db.learned[id], db.ignored[id] = nil, { sig = sig }
                        else
                            db.learned[id], db.ignored[id] = { sets = sets, how = "auto", sig = sig }, nil
                        end
                        if table.concat(sets, "+") ~= before then
                            changed = true
                            local titles = {}
                            for _, s in ipairs(sets) do titles[#titles + 1] = (SetTitle(s)) end
                            if #sets == 0 then
                                Print(ItemRef(id) .. " has changed and no longer fits any button")
                            else
                                Print((old and old.sets and "relearned " or "learned ") .. ItemRef(id) .. " as " .. table.concat(titles, " + ")
                                    .. " (/amac unassign " .. id .. " if that is wrong)")
                            end
                        end
                    end
                end
            end
        end
    end
    if changed then RebuildLearned() end
    return waiting
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
            local made = FindMacro(e, true) ~= nil
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
    report.learnWaiting = okLearn and errLearn or nil
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
                icon = IconFor(m.placeholder)
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
    -- items still waiting for their data: look again in a second
    if report.learnWaiting and not report.learnRetry and C_Timer and C_Timer.After then
        report.learnRetry = true
        C_Timer.After(1, function() report.learnRetry = nil; Update() end)
    end
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
-- The game's own tooltip for an entry in the popup. A spell: by its ID, then
-- its link. An item, tried in order: its real bag slot (exactly what the bag
-- shows), then by item ID, then by link.
local function ShowEntryTooltip(owner, id, loc, isSpell)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local function filled()
        return GameTooltip.NumLines and GameTooltip:NumLines() > 0
    end
    if isSpell then
        if GameTooltip.SetSpellByID then pcall(GameTooltip.SetSpellByID, GameTooltip, id) end
        if not filled() then pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. id) end
        if not filled() then GameTooltip:AddLine(SpellName(id) or ("spell " .. id)) end
        GameTooltip:Show()
        return
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
    local _, _, link = ItemInfo(id)
    if type(link) == "string" then pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
    if not filled() then pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. id) end
    if not filled() then GameTooltip:AddLine(ItemRef(id)) end
    GameTooltip:Show()
end

local function BuildFlyout()
    if flyout then return flyout end
    flyout = CreateFrame("Frame", "AutoMacrosFlyout", UIParent)
    flyout.over = {}
    flyout:SetFrameStrata("DIALOG")
    flyout:SetClampedToScreen(true)
    if flyout.EnableMouse then flyout:EnableMouse(true) end
    StyleFlyout(flyout)
    flyout:SetScript("OnEnter", function(self) SetOver(self, true) end)
    flyout:SetScript("OnLeave", function(self) SetOver(self, false) end)    flyout:SetScript("OnUpdate", function(self, elapsed)
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

-- An item button for a popup (the real one, or the settings demo): icon, the
-- action button art and a stack count. StyleEntry dresses it.
-- Made from Blizzard's own ActionButtonTemplate where the client has it, so it
-- is the game's action button (see BLIZZ_ART.Size); a plain button otherwise.
local function ItemButton(parent)
    local ok, e = pcall(CreateFrame, "CheckButton", nil, parent, "ActionButtonTemplate")
    if ok and e and (e.icon or e.Icon) then
        e.icon = e.icon or e.Icon
        local w = e:GetWidth()
        e.native = (type(w) == "number" and w > 0) and w or 36
        BLIZZ_ART.native = BLIZZ_ART.native or e.native   -- a stock button's size (Item size 100%)
        e.masked = e.IconMask and true or nil   -- the template masks its icon itself
        e.count = e.Count
        -- clicking a checkbutton flips its checked look; only "selected" sets it
        e:SetScript("PostClick", function(self) self:SetChecked(self.amChecked or false) end)
    else
        e = CreateFrame("Button", nil, parent)
        e.icon = e:CreateTexture(nil, "ARTWORK")
        e.icon:SetAllPoints()
    end
    ButtonArt(e)
    if not e.count then
        local okFs, fs = pcall(e.CreateFontString, e, nil, "OVERLAY", "NumberFontNormal")
        if not okFs or not fs then fs = e:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") end
        fs:SetPoint("BOTTOMRIGHT", -3, 3)
        e.count = fs
    end
    return e
end

local function Entry(i)
    local e = entries[i]
    if e then return e end
    e = ItemButton(flyout)
    e:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
        ShowEntryTooltip(self, self.itemID, self.loc, self.kind == "spell")
        if self.unequipped then
            GameTooltip:AddLine("Not equipped - click to put it on", 1, 0.82, 0)
            GameTooltip:Show()
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
    local size = BLIZZ_ART.ItemSize(f)
    -- With the background on, the items sit as on the main bar: its gap between
    -- buttons, touching the popup's edge with the art reaching out past them
    -- (StyleFlyout). Without, Item spacing between and around them.
    local art = BLIZZ_ART.PopupArt()
    local gap = art and Snap(f, BLIZZ_ART.BarGap(f) * BLIZZ_ART.ArtScale(f)) or Style("entrySpacing") * px
    local pad = art and 0 or gap
    for i = 1, n do   -- (StyleEntry has sized them)
        local e = list[i]
        if e then BLIZZ_ART.Point(e, "BOTTOMLEFT", f, "BOTTOMLEFT", pad, pad + (i - 1) * (size + gap)) end
    end
    f:SetSize(size + 2 * pad, 2 * pad + n * (size + gap) - gap)
    BLIZZ_ART.Dividers(f, art, n, size, gap, pad)
    button = button or (f == flyout and f.button)
    if not button then return end
    arrow = arrow or arrows[button]
    local ratio = button:GetEffectiveScale() / f:GetEffectiveScale()
    local x = Snap(f, (button:GetWidth() * ratio - f:GetWidth()) / 2)
    local y = 0
    if arrow and arrow:IsShown() then   -- the indicator overlaps the button by 3px (StyleArrow)
        y = math.max(0, BLIZZ_ART.TabHeight() - 3) * px
    end
    if art then   -- clear of the art below the items too
        local _, _, _, below = BLIZZ_ART.BarInsets(f)
        y = y + Snap(f, below * BLIZZ_ART.ArtScale(f))
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
    StyleArrow(a)
    a:RegisterForClicks("LeftButtonUp")
    a:SetScript("OnClick", function(self)
        if self.macro then SafeOpen(self.button, self.macro, self, true) end
    end)
    a:SetScript("OnEnter", function(self)
        if self.macro and not DB().noFlyout then SafeOpen(self.button, self.macro, self) end
    end)
    a:SetScript("OnLeave", function(self) SetOver(self, false) end)
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
    for _, a in pairs(arrows) do StyleArrow(a) end
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

-- ---- small widgets ----
-- Blizzard's own (checkbox, slider, dropdown, button), so the settings look
-- like the game's. A client without one of those templates gets a plain
-- home-made widget instead. Each is placed by its left middle on the row's
-- middle (y - 8, the middle of a label set at y - 2), so it lines up with its text.
local ROW = 36

-- CreateFrame with a template, or nil when this client lacks it. named: some
-- older templates find their parts by the frame's global name.
local Template
do
    local count = 0
    Template = function(kind, parent, template, named)
        count = count + 1
        local name = named and ("AutoMacrosWidget" .. count) or nil
        local ok, f = pcall(CreateFrame, kind, name, parent, template)
        if ok and f then return f end
        return nil
    end
end

local function MakeLabel(parent, text, x, y, w)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")   -- gold, as Blizzard's option labels
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(w or 180)
    fs:SetJustifyH("LEFT")
    fs:SetText(Loc(text))
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
    local cb = Template("CheckButton", parent, "UICheckButtonTemplate")
    if cb then
        cb:SetSize(26, 26)
        cb:SetPoint("LEFT", parent, "TOPLEFT", x - 4, y - 8)
        cb.refresh = function() cb:SetChecked(get() and true or false) end
        cb:SetScript("OnClick", function(self)
            set(self:GetChecked() and true or false)
            if PlaySound and SOUNDKIT then
                pcall(PlaySound, self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
                    or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            end
        end)
        cb.refresh()
        return cb
    end
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

-- fmt: how the value is shown (default by step: 3, 0.3, 0.25)
local function MakeSlider(parent, x, y, width, min, max, step, get, set, fmt)
    fmt = fmt or (step >= 1) and "%d" or (step >= 0.1) and "%.1f" or "%.2f"
    local function snap(v) return tonumber(string.format("%.4f", math.floor(v / step + 0.5) * step)) end
    -- retail's (and newer classic's) slider with - and + steppers
    local M = MinimalSliderWithSteppersMixin
    local ms = M and Template("Frame", parent, "MinimalSliderWithSteppersTemplate")
    if ms then
        local ok = pcall(function()
            ms:SetWidth(width + 30)
            ms:SetPoint("LEFT", parent, "TOPLEFT", x, y - 8)
            local show = function(v) return string.format(fmt, v) end
            local formatters = { [M.Label.Right] = CreateMinimalSliderFormatter
                and CreateMinimalSliderFormatter(M.Label.Right, show) or show }
            ms:Init(tonumber(get()) or min, min, max, math.max(1, math.floor((max - min) / step + 0.5)), formatters)
            ms:RegisterCallback(M.Event.OnValueChanged, function(_, v)
                v = snap(v)
                if ms.quiet or v == ms.last then return end
                ms.last = v
                set(v)
            end, ms)
        end)
        if ok then
            ms.refresh = function()
                local v = tonumber(get()) or min
                ms.last, ms.quiet = v, true
                pcall(ms.SetValue, ms, v)
                ms.quiet = nil
            end
            ms.refresh()
            return ms
        end
        ms:Hide()
    end
    -- older clients' options slider
    local old = Template("Slider", parent, "OptionsSliderTemplate", true)
    if old then
        old:SetWidth(width)
        old:SetPoint("LEFT", parent, "TOPLEFT", x, y - 8)
        old:SetMinMaxValues(min, max)
        old:SetValueStep(step)
        pcall(old.SetObeyStepOnDrag, old, true)
        for _, part in ipairs({ "Low", "High", "Text" }) do
            local r = _G[old:GetName() .. part]
            if r then r:SetText("") end
        end
        local value = old:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetPoint("LEFT", old, "RIGHT", 8, 0)
        old:SetScript("OnValueChanged", function(self, v)
            v = snap(v)
            value:SetText(string.format(fmt, v))
            if self.quiet or v == self.last then return end
            self.last = v
            set(v)
        end)
        old.refresh = function()
            local v = tonumber(get()) or min
            old.last, old.quiet = v, true
            old:SetValue(v)
            old.quiet = nil
            value:SetText(string.format(fmt, v))
        end
        old.refresh()
        return old
    end
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
        local v = snap(min + frac * (max - min))
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

-- Where the parts of a row go, from the control column, so every value lines up:
-- a color's mode dropdown (dropW), then its swatch, then a short slider (at
-- shortX, shortW wide: opacity, Close delay); full sliders run from the column
-- to where the short ones end (fullW). Narrower beside a preview column.
local function RowLayout(parent)
    local narrow = parent.amNarrow
    local dropW = narrow and 90 or 100
    local shortX, shortW = dropW + 40, narrow and 60 or 80
    return { dropW = dropW, shortX = shortX, shortW = shortW, fullW = shortX + shortW }
end

-- One colour setting: a box that cycles Default / EllesmereUI accent / Custom,
-- a swatch with the colour in use (clicking it picks a custom colour) and, for
-- colours that can be see-through, an opacity slider.
local function MakeColor(parent, x, y, key, hasAlpha)
    local b
    local L = RowLayout(parent)
    local dw = L.dropW
    local mode = MakeChoice(parent, x, y, dw, ColorModeChoices,
        function() return ColorMode(key) end,
        function(v) SetStyle(key .. "Mode", v); if b then b.refresh() end end)
    -- the swatch Blizzard uses for chat colors: a white-edged square in the color
    b = CreateFrame("Button", nil, parent)
    b:SetSize(22, 22)
    b:SetPoint("LEFT", parent, "TOPLEFT", x + dw + 8, y - 8)
    local edge = b:CreateTexture(nil, "BACKGROUND")
    edge:SetSize(18, 18)
    edge:SetPoint("CENTER", b, "CENTER", 0, 0)
    edge:SetColorTexture(1, 1, 1, 1)
    local sw = b:CreateTexture(nil, "ARTWORK")
    sw:SetAllPoints()
    sw:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    local alpha
    b.refresh = function()
        mode.refresh()
        local c = StyleColor(key)
        sw:SetVertexColor(c[1], c[2], c[3], 1)
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
        if not ok then Fail("color picker", err) end
    end)
    if hasAlpha then
        alpha = MakeSlider(parent, x + L.shortX, y, L.shortW, 0, 1, 0.05,
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
    local function labelOf()
        for _, t in ipairs(list()) do
            if t.key == get() then return t.label end
        end
        return "?"
    end
    -- retail's dropdown menu
    local dd = Template("DropdownButton", parent, "WowStyle1DropdownTemplate")
    if dd and dd.SetupMenu then
        dd:SetWidth(width)
        dd:SetPoint("LEFT", parent, "TOPLEFT", x, y - 8)
        dd:SetupMenu(function(_, root)
            for _, t in ipairs(list()) do
                root:CreateRadio(t.label, function() return get() == t.key end, function() set(t.key) end, t.key)
            end
        end)
        dd.refresh = function() pcall(dd.GenerateMenu, dd) end
        return dd
    end
    if dd then dd:Hide() end
    -- older clients' dropdown
    local old = UIDropDownMenu_Initialize and Template("Frame", parent, "UIDropDownMenuTemplate", true)
    if old then
        old:SetPoint("LEFT", parent, "TOPLEFT", x - 16, y - 8)
        pcall(UIDropDownMenu_SetWidth, old, width)
        old.refresh = function() pcall(UIDropDownMenu_SetText, old, labelOf()) end
        UIDropDownMenu_Initialize(old, function()
            for _, t in ipairs(list()) do
                local info = UIDropDownMenu_CreateInfo()
                info.text, info.checked = t.label, get() == t.key
                info.func = function() set(t.key); old.refresh() end
                UIDropDownMenu_AddButton(info)
            end
        end)
        old.refresh()
        return old
    end
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
    local pb = Template("Button", parent, "UIPanelButtonTemplate")
    if pb then
        pb:SetSize(width, 22)
        pb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        pb:SetText(Loc(text))
        pb:SetScript("OnClick", onClick)
        return pb
    end
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
-- EllesmereUI page (one to a row on our page in Blizzard's options window).
-- ---------------------------------------------------------------------------
local UI = {}   -- the settings code's own helpers, kept in one table so this file stays
                -- under Lua's limit of 200 local variables at the top level

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

UI.ButtonSize = BLIZZ_ART.BarButtonSize   -- (the demo button's size)

-- the widest the flyout indicator goes: your buttons' width, or on Blizzard's
-- rounded buttons the straight part of their top edge
function UI.TabMaxWidth()
    local w = UI.ButtonSize()
    if BLIZZ_ART.Rounded() then w = math.floor(w * (1 - 2 * BLIZZ_ART.CORNER)) end
    return w
end

-- a setting's number, or what its function returns (a slider's max, say)
function UI.Num(v)
    if type(v) == "function" then return v() end
    return v
end

-- Items listed in pairs where they can share a row: on the EllesmereUI page
-- two toggles, sliders or dropdowns next to each other go side by side.
-- An item with when = function shows only while it returns true.
local PAGES = {
    -- previewH: the preview strip's fixed height on Blizzard's pages (see UI.FitHeader);
    -- previewSide = "right": the preview in a column right of the settings instead
    { name = "Buttons", header = "buttons", previewH = 140, sections = UI.ButtonSections },
    { name = "Highlight", header = "glow", previewH = 120, sections = {
        { name = "Highlight", items = {
            { type = "toggle", label = "Highlight empty buttons",
                get = function() return DB().glow ~= false end,
                set = function(v) DB().glow = v; RefreshGlow() end },
            -- one row: "Pulse [x]   Pulse time <slider>"
            { type = "row", items = {
                UI.SToggle("Pulse", "glowPulse"),
                { type = "range", label = "Pulse time", key = "glowSpeed", min = 0.2, max = 2, step = 0.1 },
            } },
            { type = "color", label = "Color", key = "glowColor", alpha = true },
            -- solid: the border's width, inside the button; soft glow: how far it reaches in
            { type = "range", label = "Thickness", key = "glowThickness", min = 1, max = 5, step = 1 },
            { type = "choice", label = "Texture", key = "glowTexture", list = function() return TextureChoices(true) end },
        } },
    } },
    { name = "Flyout", header = "flyout", previewSide = "right", sections = {
        { name = "Behaviour", items = {
            -- one row: "Flyout on hover [x]   Close delay <slider>"
            { type = "row", items = {
                { type = "toggle", label = "Flyout on hover",
                    get = function() return not DB().noFlyout end,
                    set = function(v) DB().noFlyout = not v; Refresh() end },
                { type = "range", label = "Close delay", key = "closeDelay", min = 0.1, max = 1.5, step = 0.1 },
            } },
        } },
        { name = "Flyout indicator", items = {
            { type = "color", label = "Color", key = "tabColor", alpha = true },
            { type = "range", label = "Width", key = "tabWidth", min = 0, max = UI.TabMaxWidth, step = 1 },
            { type = "range", label = "Height (pixels)", key = "tabHeight", min = 1, max = 5, step = 1 },
            { type = "choice", label = "Texture", key = "tabTexture", list = function() return TextureChoices(false) end },
        } },
        { name = "Items", items = {
            -- with EllesmereUI's look the items copy its Action Bars settings
            { type = "text", height = 34, when = function() return EUIButtonLook() ~= nil end,
                text = function() return "Items look like your EllesmereUI action bars: border, icon zoom, and the hover"
                    .. " and pushed effects from its Bar Animations page." end },
            -- the hover on everything drawn like an action button (items, previews);
            -- Default is your action bars' own hover; its opacity applies to every mode
            { type = "color", label = "Hover", key = "entryHover", alpha = true },
            -- with Blizzard's look the selected item shows the button's checked
            -- border (as the pet bar marks its active button), Default its own color
            { type = "color", label = "Selected border", key = "selectedColor", alpha = true },
            { type = "range", label = "Selected border size", key = "selectedSize", min = 1, max = 6, step = 1,
                when = function() return EUIButtonLook() ~= nil end },
            { type = "range", label = "Item size", key = "itemScale", min = 50, max = 200, step = 10, fmt = "%d%%" },
            -- the popup's background: Blizzard's action bar art, on or off as the
            -- bar art can be in Edit Mode (EllesmereUI's look has none)
            { type = "toggle", label = "Show background", when = UI.BlizzLook,
                get = function() return Style("flyoutArt") ~= false end,
                set = function(v) SetStyle("flyoutArt", v) end },
            -- greyed out with the bar background on: the items then use the main bar's spacing
            { type = "range", label = "Item spacing", key = "entrySpacing", min = 0, max = 10, step = 1,
                disabled = function() return BLIZZ_ART.PopupArt() end },
        } },
    } },
    { name = "General", sections = {
        { name = "Tooltips and labels", items = {
            { type = "toggle", label = "Clean \"No X in inventory\" tooltip",
                get = function() return not DB().stockTooltip end, set = function(v) DB().stockTooltip = not v end },
            { type = "toggle", label = "Hide macro names on buttons",
                get = function() return not DB().showNames end,
                set = function(v) DB().showNames = not v; Refresh() end },
            { type = "color", label = "Tooltip text color", key = "tooltipColor" },
        } },
        { name = "Item learning", items = {
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

-- a tab's sections; one with when = function shows only while it returns true
function UI.PageSections(page)
    local all = page.sections
    if type(all) == "function" then all = all() end
    local list = {}
    for _, section in ipairs(all) do
        if not section.when or section.when() then list[#list + 1] = section end
    end
    return list
end

-- the settings' labels in the reader's spelling (see Loc), done once
function UI.LocItems(items)
    for _, item in ipairs(items) do
        item.label = Loc(item.label)
        if item.items then UI.LocItems(item.items) end
    end
end
for _, page in ipairs(PAGES) do
    if type(page.sections) == "table" then
        for _, section in ipairs(page.sections) do UI.LocItems(section.items) end
    end
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

-- Greys out (or brings back) a setting on our pages, as Blizzard's do for
-- options that do not apply: its label grey, its control faded and not usable.
function UI.SetWidgetEnabled(w, label, on)
    if w.SetEnabled then
        pcall(w.SetEnabled, w, on)
    elseif w.Enable and w.Disable then
        if on then w:Enable() else w:Disable() end
    end
    if w.EnableMouse then pcall(w.EnableMouse, w, on) end   -- (home-made slider)
    w:SetAlpha(on and 1 or 0.5)
    if label then label:SetFontObject(on and "GameFontNormal" or "GameFontDisable") end
end

-- a dropdown's values (key -> label) and their order, from a { key, label } list
function UI.Choices(list)
    local values, order = {}, {}
    for _, t in ipairs(list) do
        values[t.key] = t.label
        order[#order + 1] = t.key
    end
    return values, order
end

-- The EllesmereUI widget config for a toggle, slider, dropdown or colour mode
-- (a DualRow half); the widgets on Blizzard's options page use its get/set too.
function UI.NativeCfg(item)
    if item.type == "color" then
        local key = item.key
        local values, order = UI.Choices(ColorModeChoices())
        return { type = "dropdown", text = item.label, values = values, order = order,
            getValue = function() return ColorMode(key) end,
            setValue = function(v) SetStyle(key .. "Mode", v); RefreshEUIPage() end }
    end
    if item.type == "toggle" then
        return { type = "toggle", text = item.label, getValue = item.get, setValue = item.set }
    end
    local get = function() return Style(item.key) end
    local set = function(v) SetStyle(item.key, v) end
    if item.type == "range" then
        return { type = "slider", text = item.label, min = item.min, max = UI.Num(item.max), step = item.step,
            getValue = get, setValue = set }
    end
    local values, order = UI.Choices(item.list())
    return { type = "dropdown", text = item.label, values = values, order = order, getValue = get, setValue = set }
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
        -- as a subsection heading on Blizzard's options pages: large white text
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y - 10)
        title:SetText(Loc(group.name))
        y = y - 40
    end
    local items = {}
    for _, item in ipairs(group.items) do
        if item.when and not item.when() then
            -- not shown with the current look
        elseif item.type == "eui" or (item.type == "row" and W) then
            -- (EllesmereUI's page pairs a row's items by itself)
            if item.type == "row" or EllesmereUI then
                for _, sub in ipairs(item.items) do items[#items + 1] = sub end
            end
        else
            items[#items + 1] = item
        end
    end
    -- as on Blizzard's options pages: gold labels indented under the heading,
    -- every control in one column further right
    -- (a narrow page, beside a preview column, sets parent.amNarrow: controls
    -- start sooner and the wide rows are more compact)
    local lx = native and x0 or x0 + 30
    local ctlX = native and x0 + 190 or x0 + (parent.amNarrow and 170 or 240)

    -- one item on a row of its own; returns the row's height
    local function BuildItem(item)
        local rowH
        if item.type == "toggle" then
            rowH = Native("Toggle", item.label, y, item.get, item.set)
            if not rowH then
                MakeLabel(parent, item.label, lx, y - 2)
                refreshers[#refreshers + 1] = MakeToggle(parent, ctlX, y, item.get, item.set).refresh
            end
        elseif item.type == "color" then
            local key = item.key
            -- mode on the left, the custom colour on the right; picking a
            -- colour there switches the mode to Custom
            rowH = Native("DualRow", y, UI.NativeCfg(item),
                { type = "colorpicker", text = Loc("Custom color"), hasAlpha = item.alpha,
                  getValue = function() local c = Style(key); return c[1], c[2], c[3], c[4] or 1 end,
                  setValue = function(r, g, b, a)
                      SetColor(key, r, g, b, item.alpha and a or nil)
                      RefreshEUIPage()
                  end })
            if not rowH then
                MakeLabel(parent, item.label, lx, y - 2)
                refreshers[#refreshers + 1] = MakeColor(parent, ctlX, y, key, item.alpha).refresh
            end
        elseif item.type == "range" then
            local c = UI.NativeCfg(item)
            rowH = Native("Slider", item.label, y, c.min, c.max, c.step, c.getValue, c.setValue)
            if not rowH then
                local fs = MakeLabel(parent, item.label, lx, y - 2)
                -- as wide as a color row, so its value lines up with the opacity values
                local s = MakeSlider(parent, ctlX, y, RowLayout(parent).fullW, c.min, c.max, c.step,
                    c.getValue, c.setValue, item.fmt)
                refreshers[#refreshers + 1] = s.refresh
                if item.disabled then   -- greyed out while it does not apply
                    local function update() UI.SetWidgetEnabled(s, fs, not item.disabled()) end
                    update()
                    refreshers[#refreshers + 1] = update
                end
            end
        elseif item.type == "choice" then
            local c = UI.NativeCfg(item)
            rowH = Native("Dropdown", item.label, y, c.values, c.getValue, c.setValue, c.order)
            if not rowH then
                MakeLabel(parent, item.label, lx, y - 2)
                refreshers[#refreshers + 1] = MakeChoice(parent, ctlX, y, 150, item.list, c.getValue, c.setValue).refresh
            end
        elseif item.type == "button" then
            local function after()
                if item.refreshAll then RefreshOptions() end
            end
            rowH = Native("Button", item.label, y, function() item.action(nil); after() end)
            if not rowH then
                local b
                b = MakeButton(parent, lx, y, 170, item.label, function() item.action(b); after() end)
                rowH = 30
            end
        elseif item.type == "row" then
            -- a checkbox and a slider side by side: "Label [x]   Label <slider>"
            local a, s = item.items[1], item.items[2]
            MakeLabel(parent, a.label, lx, y - 2)
            refreshers[#refreshers + 1] = MakeToggle(parent, ctlX, y, a.get, a.set).refresh
            -- its slider where a color row's opacity slider is, the same width
            local L = RowLayout(parent)
            MakeLabel(parent, s.label, ctlX + 40, y - 2, L.shortX - 40)
            local c = UI.NativeCfg(s)
            refreshers[#refreshers + 1] = MakeSlider(parent, ctlX + L.shortX, y, L.shortW,
                c.min, c.max, c.step, c.getValue, c.setValue).refresh
        elseif item.type == "text" then
            local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", lx, y - 4)
            fs:SetWidth((parent:GetWidth() or UI.CONTENT_W) - lx - 20)
            fs:SetJustifyH("LEFT")
            refreshers[#refreshers + 1] = function() fs:SetText(Loc(item.text())) end
            fs:SetText(Loc(item.text()))
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
                            local x = lx + j * 170
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

-- ---- Blizzard's settings: Esc > Options > AddOns > AutoMacros ----
-- One canvas page per tab in the game's own options window, nested in its tree
-- under AutoMacros (which opens the first tab): a fixed-height preview strip,
-- then the settings, built from Blizzard's widgets. /amac options opens it (or
-- EllesmereUI's page while that is installed).
UI.CONTENT_W = 560
UI.SIDE_W, UI.LEFT_W = 120, 480   -- a page with its preview in a right-hand column
UI.panels = {}   -- per tab: { frame, host (preview strip), scroll, content, built }

function UI.ShowPanel(i)
    local pn, page = UI.panels[i], PAGES[i]
    if pn.content.amNarrow then   -- a side column: as tall as the page
        pn.host.fixedH = math.max(100, pn.host:GetHeight() or 0)
    end
    if page.header then UI.ShowHeader(page.header, pn.host, pn.host:GetWidth()) end
    if not pn.built then
        pn.built = true
        local y = 0
        for _, section in ipairs(UI.PageSections(page)) do
            y = BuildPage(pn.content, section, 0, y, false) - 10
        end
        pn.content:SetHeight(math.max(1, -y))
    end
    pn.scroll:SetVerticalScroll(0)
    if pn.content.amRefresh then pn.content.amRefresh() end
    -- the scroll bar only if needed, once the page has its size
    UI.FitScroll(pn)
    if C_Timer and C_Timer.After then C_Timer.After(0, function() UI.FitScroll(pn) end) end
end

-- a scrolling area under host, or left of it with side: Blizzard's scroll
-- frame with its scroll bar, content width wide
function UI.MakeScroll(p, host, side, width)
    local scroll = Template("ScrollFrame", p, "ScrollFrameTemplate")
        or Template("ScrollFrame", p, "UIPanelScrollFrameTemplate", true)
    if not scroll then
        scroll = CreateFrame("ScrollFrame", nil, p)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            local v = math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 40))
            self:SetVerticalScroll(v)
        end)
    end
    if side then
        scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -50)
        scroll:SetPoint("BOTTOMRIGHT", host, "BOTTOMLEFT", -30, 0)
    else
        scroll:SetPoint("TOPLEFT", host, "BOTTOMLEFT", 0, -8)
        scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -30, 10)
    end
    -- no scroll bar while everything fits (Blizzard's scroll frames read these
    -- whenever the scroll range changes; retail's and the older one's names)
    scroll.scrollBarHideIfUnscrollable, scroll.scrollBarHideable = true, true
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(width, 10)
    content.amNarrow = side or nil   -- (BuildPage lays a narrow page out more compactly)
    scroll:SetScrollChild(content)
    return scroll, content
end

-- Shows the page's scroll bar only when its settings do not fit (also done
-- here, in case a client ignores the flags above).
function UI.FitScroll(pn)
    local bar = pn.scroll.ScrollBar or (pn.scroll:GetName() and _G[pn.scroll:GetName() .. "ScrollBar"])
    if not bar then return end
    local fits = (pn.content:GetHeight() or 0) <= (pn.scroll:GetHeight() or 0) + 1
    bar:SetShown(not fits)
end

-- the canvas page for tab i (the first is AutoMacros itself)
function UI.MakePanel(i)
    local page = PAGES[i]
    local p = CreateFrame("Frame", "AutoMacrosOptions" .. i)   -- the options window sizes and shows it
    p.name = (i == 1) and "AutoMacros" or Loc(page.name)        -- (the older options window reads
    if i > 1 then p.parent = "AutoMacros" end                   -- name and parent)
    local ok, title = pcall(p.CreateFontString, p, nil, "ARTWORK", "GameFontHighlightHuge")
    if not ok or not title then title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge") end
    title:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -15)
    title:SetText(p.name)
    -- The preview keeps its size whatever the settings do (see UI.FitHeader):
    -- a strip on top, or with previewSide a column on the right, settings left.
    local side = page.header and page.previewSide == "right"
    local host = CreateFrame("Frame", nil, p)
    if side then
        -- the preview's note across the bottom of the page, under both columns
        local note = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        note:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 14, 12)
        note:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -14, 12)
        note:SetJustifyH("CENTER")
        note:SetText(Loc(UI.FLYOUT_NOTE))
        host.noteBelow = true
        host:SetPoint("TOPRIGHT", p, "TOPRIGHT", -14, -50)
        host:SetPoint("BOTTOMRIGHT", note, "TOPRIGHT", 0, 10)
        host:SetWidth(UI.SIDE_W)
    else
        host:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -50)
        host:SetSize(UI.CONTENT_W, page.header and page.previewH or 1)
    end
    host.fixedH = page.header and page.previewH or nil
    local width = side and UI.LEFT_W or UI.CONTENT_W
    local scroll, content = UI.MakeScroll(p, host, side, width)
    UI.panels[i] = { frame = p, host = host, scroll = scroll, content = content, width = width }
    p:SetScript("OnShow", function() UI.ShowPanel(i) end)
    p:Hide()
    return p
end

-- Adds the pages to the game's options window, once.
function UI.RegisterBlizzPanel()
    if UI.blizzRegistered then return end
    UI.blizzRegistered = true
    for i in ipairs(PAGES) do UI.MakePanel(i) end
    local main = UI.panels[1].frame
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, main, "AutoMacros")
        if ok and cat then
            for i = 2, #PAGES do
                pcall(Settings.RegisterCanvasLayoutSubcategory, cat, UI.panels[i].frame, UI.panels[i].frame.name)
            end
            pcall(Settings.RegisterAddOnCategory, cat)
            UI.blizzCategory = cat
            return
        end
    end
    if InterfaceOptions_AddCategory then
        for _, pn in ipairs(UI.panels) do pcall(InterfaceOptions_AddCategory, pn.frame) end
    end
end

-- the settings on whichever of our pages is on screen
function UI.RefreshPanels()
    for _, pn in ipairs(UI.panels) do
        if pn.frame:IsVisible() and pn.content.amRefresh then pn.content.amRefresh() end
    end
end

-- Brings everything on screen up to date after a change made elsewhere.
RefreshOptions = function()
    UI.RefreshPanels()
    RefreshHeaders()
    RefreshEUIPage()
end

-- after a style change: our pages and the previews (EllesmereUI refreshes its own)
StyleOptions = function()
    RefreshHeaders()
    UI.RefreshPanels()
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

-- EllesmereUI's page when it is installed, unless blizzard (/amac options blizzard)
local function OpenOptions(blizzard)
    if not blizzard and UI.pluginRegistered and EllesmereUI and EllesmereUI.OpenPlugin then
        local ok, opened = pcall(EllesmereUI.OpenPlugin, "AutoMacros")
        if ok and opened then return end
    end
    -- the game's options window, at our page
    UI.RegisterBlizzPanel()
    local cat = UI.blizzCategory
    if cat and Settings and Settings.OpenToCategory then
        local ok = pcall(Settings.OpenToCategory, cat.GetID and cat:GetID() or cat)
        if ok then return end
    end
    if InterfaceOptionsFrame_OpenToCategory then
        -- (called twice: the first call can stop at the AddOns list)
        pcall(InterfaceOptionsFrame_OpenToCategory, UI.panels[1].frame)
        pcall(InterfaceOptionsFrame_OpenToCategory, UI.panels[1].frame)
        return
    end
    Print("this client has no options window to open")
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
-- checked by hand, but only while it matters: while something is on the cursor
-- and for 3 seconds after (a drop onto a bar). Then what each button holds is
-- compared twice a second, and on any change the highlight and flyout tabs are
-- redrawn. The rest of the time the only cost is a cursor check four times a
-- second. When no buttons have been found yet, the search for them is
-- repeated every 10 seconds.
local barSeen, sinceCheck, sinceCollect, watchUntil = {}, 0, 0, 0

-- true when any button holds something else than at the last check (kind, id
-- and text per button, kept in barSeen; no strings are built)
local function BarChanged()
    local changed, n = false, 0
    for _, b in ipairs(buttons) do
        local ok, slot = pcall(ButtonSlot, b)
        if ok and slot then
            local kind, id = GetActionInfo(slot)
            local text = GetActionText and GetActionText(slot) or false
            local i = n * 3
            if barSeen[i + 1] ~= (kind or false) or barSeen[i + 2] ~= (id or false) or barSeen[i + 3] ~= text then
                barSeen[i + 1], barSeen[i + 2], barSeen[i + 3] = kind or false, id or false, text
                changed = true
            end
            n = n + 1
        end
    end
    for i = n * 3 + 1, #barSeen do barSeen[i] = nil; changed = true end
    return changed
end

local function WatchBars(elapsed)
    sinceCheck = sinceCheck + elapsed
    if sinceCheck < 0.25 then return end
    local step = sinceCheck
    sinceCheck = 0
    if #buttons == 0 then
        sinceCollect = sinceCollect + step
        if sinceCollect < 10 then return end
        sinceCollect = 0
        SafeCollect()
        if #buttons == 0 then return end
    end
    local now = GetTime()
    if GetCursorInfo then
        local ok, what = pcall(GetCursorInfo)
        if ok and what then watchUntil = now + 3 end
    end
    if now > watchUntil then return end
    if math.floor(now * 2) == math.floor((now - step) * 2) then return end   -- compare twice a second
    local ok, changed = pcall(BarChanged)
    if ok and changed then
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
        if type(db.ignored) == "table" then
            for id, v in pairs(db.ignored) do
                if v ~= "manual" then db.ignored[id] = nil end   -- keep /amac unassign
            end
        end
        db.classifier = CLASSIFIER
    end
    db.audit, db.learnOff = nil, nil   -- gone in 0.87.0 (no built-in lists; learning is always on)
    pcall(RegisterEUI)   -- in case EllesmereUI loaded after this addon
    local okPanel, errPanel = pcall(UI.RegisterBlizzPanel)   -- Esc > Options > AddOns
    if not okPanel then Fail("options page", errPanel) end
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
    -- an empty button was clicked (see EmptyBody): its message, for you only
    local message = msg and msg:match("^%s*[Ee][Mm][Pp][Tt][Yy]%s+(.+)$")
    if message then
        local c = StyleColor("tooltipColor")
        local function hex(v) return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5) end
        print(string.format("|cff%02x%02x%02x%s|r", hex(c[1]), hex(c[2]), hex(c[3]), Loc(message)))
        return
    end
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
        Print(e.title .. (verb == "add" and ": on" or ": off - its macro is deleted"))
        UI.SetEnabled(e, verb == "add")   -- the same as the settings checkbox
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
        local ok, err = pcall(OpenOptions, msg:find("blizz", 1, true) ~= nil or msg:find("standalone", 1, true) ~= nil)
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
            db.ignored[id] = "manual"   -- and do not learn it again by itself
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
            Print("nothing learned yet - items are sorted as you pick them up")
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
    elseif msg:match("^%s*art") then
        -- read-only: the bar art Blizzard draws on its action buttons and main
        -- bar (dividers, frame), to match the popup's background to it
        local function show(owner, label)
            if not owner then Print(label .. ": not found") return end
            local seen, n = {}, 0
            local function line(key, t)
                if seen[t] or not (t.GetObjectType and t:GetObjectType() == "Texture") then return end
                seen[t] = true
                local atlas = t.GetAtlas and t:GetAtlas() or ""
                local file = t.GetTexture and t:GetTexture() or ""
                local text = (tostring(key) .. " " .. tostring(atlas)):lower()
                if text:find("divider", 1, true) or text:find("art", 1, true) or text:find("frame", 1, true) then
                    n = n + 1
                    Print(string.format("  %s.%s: atlas=%s file=%s %.1fx%.1f %s", label, tostring(key), tostring(atlas),
                        tostring(file), t:GetWidth() or 0, t:GetHeight() or 0, t:IsShown() and "shown" or "hidden"))
                end
            end
            for key, v in pairs(owner) do
                if type(v) == "table" then pcall(line, key, v) end
            end
            for _, r in ipairs({ owner:GetRegions() }) do pcall(line, "(region)", r) end
            if n == 0 then Print(label .. ": no divider/art textures") end
        end
        show(_G.ActionButton1, "ActionButton1")
        local bar = _G.MainActionBar or _G.MainMenuBar
        show(bar, "MainBar")
        if not bar then return end
        -- frame pools on the bar (the dividers come from one) and their templates
        for key, v in pairs(bar) do
            if type(v) == "table" and type(v.Acquire) == "function" then
                local tpl = v.frameTemplate or v.template
                local active = 0
                pcall(function() for _ in v:EnumerateActive() do active = active + 1 end end)
                Print(string.format("  pool MainBar.%s: template=%s type=%s active=%d", tostring(key),
                    tostring(tpl), tostring(v.frameType), active))
            end
        end
        -- unnamed child frames that are not buttons (a divider is one): their pieces
        local shown = 0
        for _, child in ipairs({ bar:GetChildren() }) do
            local name = child.GetName and child:GetName()
            local isButton = child.GetObjectType and child:GetObjectType():find("Button")
            if not name and not isButton and shown < 4 then
                shown = shown + 1
                Print(string.format("  child frame %d: %.1fx%.1f %s", shown, child:GetWidth() or 0,
                    child:GetHeight() or 0, child:IsShown() and "shown" or "hidden"))
                for key, v in pairs(child) do
                    if type(v) == "table" and v.GetObjectType and v:GetObjectType() == "Texture" then
                        Print(string.format("    .%s: atlas=%s %.1fx%.1f", tostring(key),
                            tostring(v.GetAtlas and v:GetAtlas()), v:GetWidth() or 0, v:GetHeight() or 0))
                    end
                end
            end
        end
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
            local saved = MacroSlots()[m.name]
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
