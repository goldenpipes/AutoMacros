-- AutoMacros: Items and macros: bag scan, choosing items, macro text, finding,
-- writing and deleting our macros.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- Item info: this client may return a table or the classic multiple returns.
-- Returns name, required level, link.
function ItemInfo(id)
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
-- icon, the class and subclass names, and where it is worn ("INVTYPE_FINGER",
-- "" for things not worn). nil when there is no data.
function ItemInstant(id)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not fn then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, id)
    if not ok or a == nil then return nil end
    if type(a) == "table" then
        return a.classID, a.subclassID or a.subClassID, a.iconFileID or a.icon, a.itemType, a.itemSubType,
            a.itemEquipLoc or a.equipLoc
    end
    return f, g, e, b, c, d
end

function ItemRef(id)
    local name = ItemInfo(id)
    if type(name) == "string" and name ~= "" then return name end
    return "item:" .. id
end

lastScrolls = {}   -- untranslated scrolls from the last bag scan, in bag order
lastLocs = {}      -- item ID -> { bag, slot } of its first stack in the last scan
flyoutItems = {}  -- macro name -> usable items from the last scan, best first

function ScanBags()
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
function Candidates(have, setName)
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
function Chosen(m, list)
    if #list == 0 then return nil end
    local want = Picks()[m.name]
    if want then
        for _, e in ipairs(list) do
            if (e.pick or e.id) == want then return e.id, e end
        end
    end
    return list[1].id, list[1]
end

-- a spell's name (or nil), on clients with either spell API
function SpellName(id)
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

function KnowsSpell(id)
    local known = IsPlayerSpell or IsSpellKnown
    if not known then return false end
    local ok, k = pcall(known, id)
    return ok and k and true or false
end

-- For the Restore Health / Restore Mana buttons (set hpot / mpot): the name of
-- the Create Healthstone / Conjure Mana Gem spell this character knows (best
-- rank), or nil; and whether you carry one already.
function MadeCreate(set, have)
    local made = MADE[set]
    if not made then return nil, false end
    local carried = false
    for id in pairs(have or {}) do
        if made.rank[id] then carried = true end
    end
    for _, spellID in ipairs(made.spells) do
        local name = KnowsSpell(spellID) and SpellName(spellID)
        if name then return name, carried end
    end
    return nil, carried
end

function UseBody(id)
    return "#showtooltip " .. ItemRef(id) .. "\n/use item:" .. id
end

-- Weapon stones and oils: use the item, then put it on the main hand (16), or
-- the off hand (17) with Shift held.
function WeaponBody(id)
    return UseBody(id) .. "\n/use [mod:shift] 17; 16"
end

-- An icon: entry.icon, or the icon of item entry.item (a placeholder, say).
function IconFor(entry)
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
function EmptyBody(label)
    return "/amac empty No " .. label .. " in inventory."
end

-- Comprehend Scroll (Mage). With untranslated scrolls in your bags the button
-- becomes "cast Comprehend Scroll on that scroll"; with none it just shows the
-- spell. /amac next moves to the next scroll when the current one can't be read.
SCROLL_SPELL = 1296017

function ScrollSpellKnown()
    if KnowsSpell(SCROLL_SPELL) then return true end
    -- ranks have their own spell IDs, so also accept the name being in the spellbook
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, "Comprehend Scroll")
        if ok and info then return true end
    end
    return false
end

function ScrollBody(m, scrolls)
    local _, class = UnitClass("player")
    if class ~= "MAGE" or not ScrollSpellKnown() then return nil, nil end
    local spell = SpellName(SCROLL_SPELL) or "Comprehend Scroll"
    local id = Chosen(m, scrolls)
    if id then
        return "#showtooltip item:" .. id .. "\n/cast " .. spell .. "\n/use item:" .. id, id
    end
    return "#showtooltip " .. spell .. "\n/cast " .. spell, nil
end

function NextScroll()
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
function SpellIcon(id)
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

-- The spells of button m you know, in its order. byName (Professions): one
-- per spell name, the last known rank in the list (they go up), at the place
-- of the first, so "Alchemy" shows once whatever ranks the game counts as known.
-- Its pick (what the popout saves) is the name, so a rank-up keeps your choice.
function KnownSpells(m)
    local list, at = {}, {}
    for _, id in ipairs(m.spells or {}) do
        if KnowsSpell(id) then
            local name = m.byName and SpellName(id)
            if name and at[name] then
                list[at[name]].id = id
            else
                list[#list + 1] = { id = id, pick = name or nil }
                if name then at[name] = #list end
            end
        end
    end
    return list
end

function SpellBody(id)
    local name = SpellName(id)
    if not name then return nil end
    return "#showtooltip " .. name .. "\n/cast " .. name
end

-- Gear that only works worn (teleport rings, cloaks, trinkets): shown grey in
-- the flyout until equipped, and equipped by clicking it there.
function IsEquippable(id)
    local fn = (C_Item and C_Item.IsEquippableItem) or IsEquippableItem
    if not fn then return false end
    local ok, r = pcall(fn, id)
    return ok and r == true
end

function IsEquipped(id)
    local fn = (C_Item and C_Item.IsEquippedItem) or IsEquippedItem
    if not fn then return false end
    local ok, r = pcall(fn, id)
    return ok and r == true
end

function NeedsEquip(id)
    return IsEquippable(id) and not IsEquipped(id)
end

function EquipByID(id)
    local fn = (C_Item and C_Item.EquipItemByName) or EquipItemByName
    if not fn then return false end
    return (pcall(fn, id))
end

-- Hearth/Teleport, in this order: hearth items ready to use (Hearthstone
-- first), the teleport spells you know, then gear that has to be put on first,
-- so the automatic choice is always something that works straight away.
-- Spells are saved as negative picks.
function TravelOptions(m, have)
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
function BodyMatches(m, body)
    if type(body) ~= "string" then return false end
    if m.special == "scroll" then return body:find("Comprehend", 1, true) ~= nil end
    if m.kind == "spells" then return body:find("/cast", 1, true) ~= nil end
    if m.kind == "travel" and body:find("/cast", 1, true) then return true end
    -- empty-state text, in any of the forms used by different versions
    local stem = m.label:gsub("s$", "")
    if body:find("No " .. stem, 1, true) then return true end
    -- Restore Health / Mana making a healthstone or mana gem; Bandage casting Cannibalize
    if (MADE[m.set] or m.spells) and body:find("/cast", 1, true) then return true end
    local id = tonumber(body:match("item:(%d+)"))
    return m.set ~= nil and id ~= nil and InSet(m.set, id)
end

-- The slot of m's macro, or nil. checked: a macro found by name must also look
-- like this category's (a remembered slot always has to).
-- The game keeps macros in name order, so creating or renaming one ("Water" <->
-- "No Water") moves others to new slots: a remembered slot only counts while
-- the macro there still has one of this category's names.
function FindMacro(m, checked)
    -- its names (the macros are named after their category, or were once)
    local names = { m.title, m.empty, m.name }
    for _, n in ipairs(m.oldNames or {}) do names[#names + 1] = n end
    -- 1. the slot remembered last time, if it still holds this macro
    local saved = MacroSlots()[m.name]
    if saved then
        local name, _, body = GetMacroInfo(saved)
        if name and BodyMatches(m, body) then
            for _, n in ipairs(names) do
                if name == n then return saved end
            end
        end
    end
    -- 2. by name
    for _, n in ipairs(names) do
        local idx = GetMacroIndexByName(n)
        if idx and idx > 0 and (not checked or BodyMatches(m, GetMacroBody(idx))) then return idx end
    end
end

function WantedName(m, active)
    return active and m.title or m.empty
end

function Remember(m, idx)
    if type(idx) == "number" then MacroSlots()[m.name] = idx end
end

function Apply(m, body, icon, active)
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
toDelete = {}

-- Deletes a category's macro (it also leaves every action bar it was on). Only
-- a macro whose text still looks like the category's is touched, so one of your
-- own that happens to share the name is left alone.
function DeleteManaged(m)
    local idx = FindMacro(m)
    if not idx then return end
    if not BodyMatches(m, GetMacroBody(idx)) then
        Note(m.title .. ": macro " .. tostring(GetMacroInfo(idx)) .. " left alone - it does not look like one of ours")
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
    Note(m.title .. ": macro deleted")
end
