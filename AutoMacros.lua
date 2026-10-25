-- AutoMacros 0.24.0 for WoW Forever (interface 16001)
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
local function Candidates(have, set)
    local level = UnitLevel("player") or 1
    local list = {}
    for id in pairs(have) do
        if set[id] then
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
    if m.set then return id ~= nil and DATA[m.set][id] == true end
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
-- Highlight: a pulsing red border on any action button holding a macro whose
-- category is empty. It only touches our own frames, so it also works in combat.
-- ---------------------------------------------------------------------------
local GLOW_COLOR = { 1, 0.15, 0.15 }
local GLOW_THICKNESS = 3
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
    g:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    g:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    local r, gr, b = GLOW_COLOR[1], GLOW_COLOR[2], GLOW_COLOR[3]
    local function Edge(p1, p2, w, h)
        local tex = g:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(r, gr, b, 1)
        tex:SetPoint(p1, g, p1)
        tex:SetPoint(p2, g, p2)
        if w then tex:SetWidth(w) end
        if h then tex:SetHeight(h) end
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, GLOW_THICKNESS)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, GLOW_THICKNESS)
    Edge("TOPLEFT", "BOTTOMLEFT", GLOW_THICKNESS, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", GLOW_THICKNESS, nil)
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
    end)
    g:Hide()
    glows[button] = g
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
        if g.pulse then g.pulse:Play() end
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
local TOOLTIP_COLOR = { 1, 0.3, 0.3 }

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
    tip:AddLine(message, TOOLTIP_COLOR[1], TOOLTIP_COLOR[2], TOOLTIP_COLOR[3])
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
local scanTip
local function TooltipSummary(id)
    if not scanTip then
        local ok, t = pcall(CreateFrame, "GameTooltip", "AutoMacrosScanTip", nil, "GameTooltipTemplate")
        if not ok or not t then return "(no scan tooltip)" end
        scanTip = t
    end
    pcall(scanTip.SetOwner, scanTip, UIParent, "ANCHOR_NONE")
    local ok = pcall(scanTip.SetItemByID, scanTip, id)
    if not ok then pcall(scanTip.SetHyperlink, scanTip, "item:" .. id) end
    local found = {}
    for i = 1, scanTip:NumLines() do
        local fs = _G["AutoMacrosScanTipTextLeft" .. i]
        local text = fs and fs:GetText()
        if type(text) == "string" and (text:find("Restores") or text:find("Use:") or text:find("Must remain")) then
            found[#found + 1] = text:sub(1, 90)
        end
    end
    return #found > 0 and table.concat(found, " | ") or "(no Restores/Use line)"
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
            local list = Candidates(have, DATA[m.set] or {})
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
local ENTRY_SIZE = 34
local MAX_ENTRIES = 10
local CLOSE_DELAY = 0.3
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
    local bg = flyout:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.65)
    flyout:SetScript("OnEnter", function(self) SetOver(self, true) end)
    flyout:SetScript("OnLeave", function(self) SetOver(self, false) end)
    flyout:SetScript("OnUpdate", function(self, elapsed)
        if self.sticky then return end          -- opened by /amac flyout test
        if AnyOver() then
            self.idle = 0
        else
            self.idle = (self.idle or 0) + elapsed
            if self.idle > CLOSE_DELAY then self:Hide() end
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
    e:SetSize(ENTRY_SIZE, ENTRY_SIZE)
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
    local hl = e:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.25)
    e:SetScript("OnClick", function(self)
        local m = flyout.macro
        if not m then return end
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
    entries[i] = e
    return e
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
    local chosen = Chosen(m, list)
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
        if list[i].id == chosen then
            e.border:SetColorTexture(1, 0.82, 0, 1)       -- gold: the one in use
        else
            e.border:SetColorTexture(0.1, 0.1, 0.1, 1)
        end
        e:ClearAllPoints()
        e:SetPoint("BOTTOM", flyout, "BOTTOM", 0, 4 + (i - 1) * (ENTRY_SIZE + 2))   -- best nearest the button
        e:Show()
    end
    for i = n + 1, #entries do entries[i]:Hide() end
    flyout:SetSize(ENTRY_SIZE + 8, 8 + n * (ENTRY_SIZE + 2) - 2)
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
    a:SetSize(18, 7)
    a:SetPoint("BOTTOM", button, "TOP", 0, -3)
    a.tex = a:CreateTexture(nil, "OVERLAY")
    a.tex:SetAllPoints()
    a.tex:SetColorTexture(1, 0.82, 0, 0.95)
    a:RegisterForClicks("LeftButtonUp")
    a:SetScript("OnClick", function(self)
        if self.macro then SafeOpen(self.button, self.macro, self, true) end
    end)
    a:SetScript("OnEnter", function(self)
        self.tex:SetColorTexture(1, 1, 1, 1)
        if self.macro and not DB().noFlyout then SafeOpen(self.button, self.macro, self) end
    end)
    a:SetScript("OnLeave", function(self)
        self.tex:SetColorTexture(1, 0.82, 0, 0.95)
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

local BAR_EVENTS = {
    ACTIONBAR_SLOT_CHANGED = true, ACTIONBAR_PAGE_CHANGED = true,
    UPDATE_BONUS_ACTIONBAR = true, UPDATE_SHAPESHIFT_FORM = true,
}

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event)
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
