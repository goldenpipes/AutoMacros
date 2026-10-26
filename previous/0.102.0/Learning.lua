-- AutoMacros: Learning: reading tooltips and sorting items onto buttons.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---------------------------------------------------------------------------
-- Learning new items. Every item you carry is sorted
-- by what the game says about it: its item class (language independent) and the
-- "Use:" lines of its tooltip. The result is saved in db.learned, so each item
-- is only examined once. Anything the rules get wrong can be corrected by hand
-- with /amac assign and /amac unassign, and hand-made entries always win.
--   any item,     "Use:" teleports you / returns you home -> hearth/teleport
--   any item but gear, "Use:" cures or removes poison, disease, bleeding,
--     curse, magic, stuns or snares       -> debuff cure (Jungle Remedy,
--                    Restorative Potion; First Aid's poultices and tourniquets
--                    are trade goods)
--   consumable, subclass Bandage            -> bandage
--   consumable, subclass Flask              -> flask
--   Food & Drink, tooltip says "well fed"   -> buff food
--   Food & Drink, "Use:" restores health    -> food;  restores mana -> water
--   Potion,       "Use:" gives rage         -> rage potion
--   any other consumable, "Use:" restores health -> restore health; mana -> restore mana
--                    (potions, healthstones, mana gems, runes; Rejuvenation: both)
--   any other consumable (elixir, scroll, potion, Juju, E'ko, quest rewards),
--     "Use:" raises Strength, Agility, Stamina, Intellect or Spirit
--                                           -> that stat's buff button
--                    ("maximum health", Fortitude elixirs, counts as Stamina)
--   any other consumable, "Use:" raises Armor or Defense
--                                           -> armor buff (Scroll of Protection, Elixir of Defense)
--   any other consumable, "Use:" raises a resistance or absorbs damage
--                                           -> resistance (protection potions, Gift of Arthas)
--   Item Enhancement / other consumable, "Use:" mentions your weapon
--                                           -> weapon buff
--   other consumable, "Use:" does damage    -> explosives (retail files them here)
--   other consumable, "Use:" increases / improves / grants / raises anything
--     else (armor, attack power, crit, resistance, speed, ...) -> other buffs
--   Trade Goods, subclass Explosives        -> explosives (classic files them here)
--   other trade goods, "Use:" restores health / mana -> restore health / mana (runes)
--   quest and misc items (often quest rewards): restoring and buffs, as above
-- Gear (rings, cloaks, trinkets) only counts for teleporting; other item
-- classes are skipped.
-- ---------------------------------------------------------------------------
-- item classes worth a look: consumable, armour, trade goods, quest (Juju and
-- E'ko are quest items), miscellaneous
LOOKED_AT = { [0] = true, [4] = true, [7] = true, [12] = true, [15] = true }
STAT_KEYS = { "strength", "agility", "stamina", "intellect", "spirit" }   -- SPELL_STAT1..5_NAME

-- (scanTip)
function TooltipLines(id)
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

function HasWord(low, ...)
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
function Classify(id)
    local class, sub = ItemInstant(id)
    if class == nil then return nil end
    local sig = class * 1000 + (tonumber(sub) or 0)
    if not LOOKED_AT[class] then return {}, sig end
    if class == 0 and sub == 7 then return { "bandage" }, sig end
    if class == 0 and sub == 3 then return { "flask" }, sig end
    if class == 7 and sub == 2 then return { "explosives" }, sig end
    -- (other trade goods only count when they restore health or mana: Demonic and Dark Runes)
    local lines = TooltipLines(id)
    if not lines or #lines < 2 or lines[1] == RETRIEVING_ITEM_INFO then return nil end
    local use = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    local health, mana, rage, damage, weapon, travel, wellFed = false, false, false, false, false, false, false
    local stats, hasUse, restore, buff, armor, resist, seated = {}, false, false, false, false, false, false
    local cure = false   -- removes a debuff
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
            -- "Cures 1 poison effect", "Target is cured of diseases", "Removes 1 magic,
            -- curse, poison or disease effect", "cured of bleeds" (Forever's tourniquets),
            -- stuns and snares ("removes existing stun and movement impairing effects")
            if HasWord(low, "cure", "remove", "neutralize", "dispel")
                and HasWord(low, "poison", "disease", "bleed", "curse", "magic", "stun", "impair", "snare",
                    "root", "harmful") then
                cure = true
            end
            -- real food and drink: "Must remain seated while eating"
            if HasWord(low, "seated", "while eating", "while drinking") then seated = true end
            if text:find("%d") then
                if HasWord(low, "health", HEALTH) then health = true end
                if HasWord(low, "mana", MANA) then mana = true end
                if low:find("%f[%a]rage%f[%A]") then rage = true end   -- the word, not "average"
                if HasWord(low, "damage") then damage = true end
                if HasWord(low, "restore") then restore = true end   -- a potion that heals, not one that raises health
                -- raises something for a while (not "permanently", like an armor kit)
                -- (and not a fishing lure: "increases fishing by 25")
                if HasWord(low, "increase", "improve", "grant", "raise")
                    and not HasWord(low, "permanent", "fishing") then buff = true end
                if buff and HasWord(low, "armor", ARMOR, "defense") then armor = true end
                -- raises a resistance, or a protection potion: "Absorbs 1950 to 3250 fire damage"
                if (buff and HasWord(low, "resist")) or (HasWord(low, "absorb") and damage) then resist = true end
                for i, key in ipairs(STAT_KEYS) do
                    local name = _G["SPELL_STAT" .. i .. "_NAME"] or (key:sub(1, 1):upper() .. key:sub(2))
                    if text:find(name, 1, true) then stats[key] = true end
                end
                -- Fortitude elixirs raise maximum health, not Stamina: the nearest button
                if low:find("maximum health", 1, true) then stats.stamina = true end
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
    if class == 4 then return {}, sig end   -- gear (rings, cloaks, trinkets): only teleports count
    -- a cure, from anything you carry: potions, First Aid's poultices and
    -- tourniquets (trade goods), quest rewards
    if cure then return { "cure" }, sig end
    local sets = {}
    local restoring = restore and (health or mana) and not weapon   -- (not mana oils)
    if class == 7 then   -- other trade goods: only runes and the like, "Restores 900 to 1500 mana"
        if not restoring then return {}, sig end
        return (health and mana) and { "hpot", "mpot" } or { health and "hpot" or "mpot" }, sig
    end
    -- quest and misc items (quest rewards are often one or the other) count
    -- for what helps you: restoring health or mana, and buffs
    if class == 12 or class == 15 then sub = -1 end
    if sub == -1 and not (restoring or next(stats) or armor or resist or buff) then
        -- a quest or misc item that does none of that
    elseif sub == 5 and restoring and not seated and not wellFed then
        -- in Food & Drink but works at once, like a potion: Whipper Root Tuber
        if health then sets[#sets + 1] = "hpot" end
        if mana then sets[#sets + 1] = "mpot" end
    elseif sub == 5 then
        if wellFed then return { "food_buff" }, sig end
        if health then sets[#sets + 1] = "food" end
        if mana then sets[#sets + 1] = "water" end
    elseif sub == 1 and rage then
        sets[#sets + 1] = "rage"
    elseif sub ~= 6 and restoring then
        -- potions, healthstones, mana gems, runes, ... (food, flasks and
        -- bandages were sorted above; Rejuvenation Potions go on both)
        if health then sets[#sets + 1] = "hpot" end
        if mana then sets[#sets + 1] = "mpot" end
    elseif sub ~= 6 and next(stats) then   -- (6: item enhancements, worn on gear)
        for _, key in ipairs(STAT_KEYS) do
            if stats[key] then sets[#sets + 1] = "buff_" .. key end
        end
    elseif sub ~= 6 and (resist or armor) then
        if resist then sets[#sets + 1] = "buff_resistance" end
        if armor then sets[#sets + 1] = "buff_armor" end
    elseif weapon and sub ~= -1 then
        sets[#sets + 1] = "weapon_buff"
    elseif sub == 0 and damage and not buff then
        sets[#sets + 1] = "explosives"
    elseif sub ~= 6 and buff then
        sets[#sets + 1] = "buff_other"
    end
    return sets, sig
end

function SetTitle(setName)
    for _, e in ipairs(ALL) do
        if e.set == setName then return e.title, e.key end
    end
    return setName
end

sessionDone = {}   -- item IDs not worth looking at again this session
attempts = {}      -- item ID -> tries while the game had no data for it

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
-- loud: the items to tell you about (those in your bags; things your recipes
-- make are sorted quietly); nil = all.
function LearnNew(have, loud)
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
                        end
                        if table.concat(sets, "+") ~= before and (not loud or loud[id]) then
                            local titles = {}
                            for _, s in ipairs(sets) do titles[#titles + 1] = (SetTitle(s)) end
                            if #sets == 0 then
                                Note(ItemRef(id) .. " has changed and no longer fits any button")
                            else
                                Note((old and old.sets and "relearned " or "learned ") .. ItemRef(id) .. " as " .. table.concat(titles, " + ")
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
