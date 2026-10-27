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
--   (Classic Era files nearly all consumables as plain "Consumable", so the
--    next ones go by the text; the subclass is used where a client has one)
--   consumable, subclass Bandage or "Heals 301 damage over 7 sec."  -> bandage
--   consumable, subclass Flask or "one flask" / "persists through death" -> flask
--   consumable, tooltip says "well fed"      -> buff food
--   consumable, "must remain seated", restores health -> food;  mana -> water
--   consumable, "Use:" gives rage            -> rage potion
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
--   other trade goods and reagents, "Use:" restores health / mana -> restore
--     health / mana (runes); "Use:" mentions your weapon -> weapon buff
--     (Classic Era's sharpening stones and oils; not devices); absorbs damage
--     -> resistance (Frozen Rune, deflectors)
--   quest and misc items (often quest rewards): restoring and buffs, as above
--   a quest item ("Quest Item" or the quest class) with a "Use:" line and no
--     button above                         -> quest item (before weapon buff
--                                             and explosives)
-- Gear (rings, cloaks, trinkets) only counts for teleporting; other item
-- classes are skipped.
-- ---------------------------------------------------------------------------
-- item classes worth a look: consumable, armour, reagent (Classic Era files
-- Anti-Venom there), trade goods, quest (Juju and E'ko are quest items), miscellaneous
LOOKED_AT = { [0] = true, [4] = true, [5] = true, [7] = true, [12] = true, [15] = true }
-- gear only counts when it teleports you, and only these slots ever do
TELEPORT_SLOTS = { INVTYPE_FINGER = true, INVTYPE_TRINKET = true, INVTYPE_CLOAK = true, INVTYPE_NECK = true,
    INVTYPE_TABARD = true }

-- Armour that is not worn at all ("" / INVTYPE_NON_EQUIP / Classic Era's
-- INVTYPE_NON_EQUIP_IGNORE): Classic files usable odds and ends there (Mana
-- Agate is 4.0), so those count like consumables.
function NotWorn(slot)
    return slot == nil or slot == "" or slot == "INVTYPE_NON_EQUIP" or slot == "INVTYPE_NON_EQUIP_IGNORE"
end

-- Worth reading the tooltip of? Known without asking the server: its class is
-- one of LOOKED_AT, and gear only in a slot that can teleport (not chest,
-- legs, boots, ...) or not worn at all. nil when the game does not know the item.
function WorthALook(id)
    local class, _, _, _, _, slot = ItemInstant(id)
    if class == nil then return nil end
    if not LOOKED_AT[class] then return false end
    if class == 4 and not (TELEPORT_SLOTS[slot] or NotWorn(slot)) then return false end
    return true
end
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
    local class, sub, _, _, _, slot = ItemInstant(id)
    if class == nil then return nil end
    local sig = class * 1000 + (tonumber(sub) or 0)
    if WorthALook(id) == false then return {}, sig end
    if class == 0 and sub == 7 then return { "bandage" }, sig end
    if class == 0 and sub == 3 then return { "flask" }, sig end
    if class == 7 and sub == 2 then return { "explosives" }, sig end
    -- (other trade goods only count when they restore health or mana: Demonic and Dark Runes)
    local lines = TooltipLines(id)
    -- (one line is enough: a plain reagent's tooltip can be just its name; the
    -- sell price is not a text line. Before 0.108.2 those counted as not loaded.)
    if not lines or #lines < 1 or lines[1] == "" or lines[1] == RETRIEVING_ITEM_INFO then return nil end
    local use = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    local health, mana, rage, damage, weapon, travel, wellFed = false, false, false, false, false, false, false
    local stats, hasUse, restore, buff, armor, resist, seated = {}, false, false, false, false, false, false
    local cure = false   -- removes a debuff
    -- Classic Era files nearly every consumable as plain "Consumable" (subclass
    -- 0), not Food & Drink, Potion, Bandage, Flask: those are known by their text
    local bandaged, flask = false, false
    -- a quest item: the quest class, or "Quest Item" in its tooltip
    local quest = class == 12
    -- applied to gear for good: "Permanently enchant ...", "Permanently adds ..." (no button)
    local permanent = false
    for _, text in ipairs(lines) do
        local low = text:lower()
        if text:find(use, 1, true) then hasUse = true end
        if text == (ITEM_BIND_QUEST or "Quest Item") or low == "quest item" then quest = true end
        if low:find("well fed", 1, true) or text:find(use, 1, true) then
            for i = 1, #low do
                local c = low:byte(i)
                if c < 48 or c > 57 then sig = (sig * 31 + c) % 2147483629 end
            end
        end
        if low:find("well fed", 1, true) then wellFed = true end
        if text:find(use, 1, true) then
            if HasWord(low, "teleport", "returns you to") then travel = true end
            -- ("Coats a sword or dagger with poison"; not a Steel Weapon Chain, which
            -- "attaches a chain to your weapon" for good)
            if HasWord(low, "weapon", "coats a") and not HasWord(low, "attach") then weapon = true end
            -- "Cures 1 poison effect", "Target is cured of diseases", "Removes 1 magic,
            -- curse, poison or disease effect", "cured of bleeds" (Forever's tourniquets),
            -- stuns and snares ("removes existing stun and movement impairing effects")
            -- ("removing 1 disease effect": Cleansing Water; "Removes 1 negative spell
            -- effect": Moist Towelette; "Cures the user of Brood Affliction")
            if (HasWord(low, "cure", "remov", "neutraliz", "dispel")
                and HasWord(low, "poison", "disease", "bleed", "curse", "magic", "stun", "impair", "snare",
                    "root", "harmful", "negative", "affliction"))
                or HasWord(low, "cures the user", "cure for the") then
                cure = true
            end
            -- real food and drink: "Must remain seated while eating"
            if HasWord(low, "seated", "while eating", "while drinking") then seated = true end
            -- "You can only have the effect of one flask at a time. This effect persists through death."
            if HasWord(low, "one flask", "persists through death") then flask = true end
            if HasWord(low, "perman") then permanent = true end   -- (also a test item's "Permantly")
            if text:find("%d") then
                if HasWord(low, "health", HEALTH) then health = true end
                if HasWord(low, "mana", MANA) then mana = true end
                if low:find("%f[%a]rage%f[%A]") then rage = true end   -- the word, not "average"
                if HasWord(low, "damage") then damage = true end
                -- a potion that heals, not one that raises health ("heals 2100 health and
                -- 2100 mana": Greater Dreamless Sleep; bandages, "heals 301 damage", go first)
                -- (not a Mechanical Repair Kit: "restores 700 health to a friendly mechanical target")
                if HasWord(low, "restore", "heals") and not HasWord(low, "mechanical") then restore = true end
                -- a bandage: "Heals 301 damage over 7 sec."
                if HasWord(low, "heals") and HasWord(low, "damage") then bandaged = true end
                -- raises something for a while (not "permanently", like an armor kit)
                -- (and not a fishing lure: "increases fishing by 25")
                -- ("regenerate 20 health every 5 sec for 1 hour": Troll's Blood, Mageblood)
                -- (and utility potions: "Gives the imbiber lesser invisibility", "Allows the
                -- Imbiber to breathe water", "Lets you walk on water", "Imbiber is immune
                -- to physical attacks", "Shows the location of all nearby undead")
                if HasWord(low, "increase", "improve", "grant", "raise", "regenerate", "gives the imbiber",
                        "gives you", "allows the imbiber", "lets you", "is immune", "shows the location")
                    and not HasWord(low, "perman", "fishing") then buff = true end
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
    if class == 4 and not NotWorn(slot) then return {}, sig end   -- gear (rings, cloaks, trinkets): only teleports count
    if permanent then return {}, sig end    -- enchants and kits put on gear
    -- a cure, from anything you carry: potions, First Aid's poultices and
    -- tourniquets (trade goods), quest rewards
    if cure and not quest then return { "cure" }, sig end   -- (a quest item that "cures a sickly animal" is the quest's)
    local sets = {}
    local restoring = restore and (health or mana) and not weapon   -- (not mana oils)
    -- something you use to do a quest ("Use: Place the totem at ..."), unless it
    -- fits a button that helps you (restoring, buffs): those come first
    local questUse = quest and hasUse
    -- other trade goods and reagents: runes and the like ("Restores 900 to 1500
    -- mana"), on Classic Era sharpening stones and oils (7.0, "Increase sharp
    -- weapon damage"), Frozen Rune and Engineering's deflectors ("Absorbs 500
    -- fire damage"). Not devices (7.3) for weapons: Goblin Dragon Gun.
    if class == 7 or class == 5 then
        if restoring then
            return (health and mana) and { "hpot", "mpot" } or { health and "hpot" or "mpot" }, sig
        end
        if questUse then return { "quest" }, sig end
        if weapon and hasUse and sub ~= 3 then return { "weapon_buff" }, sig end
        if resist then return { "buff_resistance" }, sig end
        return {}, sig
    end
    -- quest and misc items (quest rewards are often one or the other) count
    -- for what helps you: restoring health or mana, and buffs; or as quest items
    if class == 12 or class == 15 then sub = -1 end
    local own = sub ~= -1   -- a consumable (not a quest or misc item)
    if not own and not (restoring or next(stats) or armor or resist or buff or questUse) then
        -- a quest or misc item that does none of that
    elseif seated and (health or mana) and not wellFed then
        -- food and drink, also from quests (Clara's Fresh Apple): you sit to eat
        -- it ("Must remain seated while eating"); buff food is below
        if health then sets[#sets + 1] = "food" end
        if mana then sets[#sets + 1] = "water" end
    elseif own and bandaged then
        sets[#sets + 1] = "bandage"
    elseif own and flask then
        sets[#sets + 1] = "flask"
    elseif own and wellFed then
        sets[#sets + 1] = "food_buff"
    elseif own and rage then
        sets[#sets + 1] = "rage"
    elseif sub ~= 6 and restoring then
        -- at once, no sitting: potions, healthstones, mana gems, runes, Whipper
        -- Root Tuber (filed with food) ... (Rejuvenation Potions go on both)
        if health then sets[#sets + 1] = "hpot" end
        if mana then sets[#sets + 1] = "mpot" end
    elseif sub ~= 6 and next(stats) then   -- (6: item enhancements, worn on gear)
        for _, key in ipairs(STAT_KEYS) do
            if stats[key] then sets[#sets + 1] = "buff_" .. key end
        end
    elseif sub ~= 6 and (resist or armor) then
        if resist then sets[#sets + 1] = "buff_resistance" end
        if armor then sets[#sets + 1] = "buff_armor" end
    elseif questUse then
        -- (before weapon and explosives: "throw it at the wagon" is the quest's)
        sets[#sets + 1] = "quest"
    elseif weapon and own then
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
            local worth = WorthALook(id)
            if worth == false then
                sessionDone[id] = true            -- nothing any button uses
            elseif worth ~= nil then
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

-- ---------------------------------------------------------------------------
-- /amac test [first] [last]: runs the learning rules over every item ID in a
-- range (default 1-25000, all of vanilla) using this client's own item data,
-- to find items the rules put on the wrong button or miss. Nothing is learned
-- or changed; the result goes to db.test (saved on /reload or logout):
--   build, interface, first, last, counts[set] = how many
--   items[id]   = "sets | class.sub | name | Use: ..."   sorted onto a button
--   unsorted[id] = the same with "-"   a consumable, reagent, trade good or misc item with a "Use:"
--                                     line that fits no button (possible misses)
--   missing     = IDs the server says do not exist (unused items in the game files)
--   noanswer    = IDs the server never answered for (TEST_TRIES questions)
--   notext      = IDs it answered for, but whose "Use:" text never came
--   addon       = the AutoMacros version that ran it
-- Steps: find the IDs worth a look (WorthALook, no server needed); ask the
-- server for them with at most TEST_INFLIGHT questions out at once (asked too
-- fast, the server drops them: the first run got 31 of 11,476), and sort each
-- one as its answer arrives (GET_ITEM_INFO_RECEIVED / ITEM_DATA_LOAD_RESULT say
-- found or not; items the game already has are sorted straight away). No
-- answer in TEST_RETRY seconds: asked again, TEST_TRIES times in all. Items in
-- but without their "Use:" text yet: looked at again, for TEST_QUIET seconds.
-- ---------------------------------------------------------------------------
TEST_STEP = 20      -- items whose "Use:" text is looked at again per tick
TEST_TICK = 0.25    -- seconds between ticks
TEST_INFLIGHT = 50  -- questions out to the server at once (more go out as answers come back)
TEST_RETRY = 10     -- seconds without an answer before an item is asked again
TEST_TRIES = 3      -- times an item is asked before it counts as no data
TEST_QUIET = 30     -- seconds an item may wait for its "Use:" text

-- "sets | class.sub | name | Use: ... | well fed ..." for the saved result
function TestLine(id, sets)
    local class, sub = ItemInstant(id)
    local lines = TooltipLines(id) or {}
    local parts = { #sets > 0 and table.concat(sets, "+") or "-", tostring(class) .. "." .. tostring(sub), lines[1] or "?" }
    local use = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    for _, text in ipairs(lines) do
        if text:find(use, 1, true) or text:lower():find("well fed", 1, true) then parts[#parts + 1] = text end
    end
    return table.concat(parts, " | ")
end

-- The test's progress window: a bar over the whole run (finding 10%, asking
-- the server 30%, sorting 60%), what it is doing with a count, and Stop (Close
-- once it is done). Draggable.
function TestBar()
    if testBar then return testBar end
    local f = CreateFrame("Frame", "AutoMacrosTestBar", UIParent)
    f:SetSize(340, 52)
    f:SetPoint("TOP", UIParent, "TOP", 0, -120)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
    f.title:SetText("AutoMacros rules test")
    f.bar = CreateFrame("StatusBar", nil, f)
    f.bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 8)
    f.bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 8)
    f.bar:SetHeight(16)
    f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.bar:SetStatusBarColor(0.2, 0.6, 1)
    f.bar:SetMinMaxValues(0, 1)
    local back = f.bar:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0.15, 0.15, 0.15, 1)
    f.text = f.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("CENTER")
    local ok, b = pcall(CreateFrame, "Button", nil, f, "UIPanelButtonTemplate")
    if not ok or not b then
        b = CreateFrame("Button", nil, f)
        b:SetNormalFontObject("GameFontNormalSmall")
    end
    b:SetSize(64, 20)
    b:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -4)
    b:SetText("Stop")
    b:SetScript("OnClick", function()
        if testRun then testRun.stop = true else f:Hide() end
    end)
    f.button = b
    testBar = f
    return f
end

-- the bar and its text for where test run is now
function TestBarUpdate(run)
    local f = TestBar()
    local span, found = run.last - run.first + 1, #run.found
    local frac, text
    if run.next <= run.last then
        frac = 0.1 * (run.next - run.first) / span
        text = string.format("Finding items: %d / %d", run.next - run.first, span)
    else
        -- answered: sorted, or the server says it does not exist
        frac = 0.1 + 0.9 * run.answered / math.max(1, found)
        if run.asked < found then
            text = string.format("Asking the server: %d answered of %d", run.answered, found)
        else
            text = string.format("Waiting for answers: %d / %d", run.answered, found)
        end
    end
    f.bar:SetValue(math.min(1, frac))
    f.text:SetText(text)
    f.button:SetText("Stop")
    f:Show()
end

-- the end: a full bar with the summary, and Close
function TestBarDone(text)
    local f = TestBar()
    f.bar:SetValue(1)
    f.text:SetText(text)
    f.button:SetText("Close")
    f:Show()
end

-- One item is finished with (sorted, missing or given up on): off every list.
function TestDone(run, id)
    if run.pending[id] then run.inflight = run.inflight - 1 end
    run.pending[id], run.spell[id], run.waiting[id] = nil, nil, nil
    run.answered = run.answered + 1
    run.lastProgress = GetTime()
end

-- An item whose data is in: sorted into the result. false when its "Use:"
-- text has not come yet (Classify has asked for it; it is looked at again).
function TestSort(run, id)
    local res = run.res
    local ok, sets = pcall(Classify, id)
    if not ok then sets = {} end   -- (a rule failed on this item: kept as unsorted, with its text)
    if sets == nil then
        -- the item is in (no question out for it any more); its spell text is not
        if run.pending[id] then run.pending[id] = nil; run.inflight = run.inflight - 1 end
        run.spell[id] = run.spell[id] or GetTime()
        return false
    end
    TestDone(run, id)
    if #sets > 0 then
        res.items[id] = TestLine(id, sets)
        for _, s in ipairs(sets) do res.counts[s] = (res.counts[s] or 0) + 1 end
    else
        local class = ItemInstant(id)
        if class == 0 or class == 5 or class == 7 or class == 15 then
            local line = TestLine(id, sets)
            if line:find(ITEM_SPELL_TRIGGER_ONUSE or "Use:", 1, true) then res.unsorted[id] = line end
        end
    end
    return true
end

-- The server's answer for one item (GET_ITEM_INFO_RECEIVED, ITEM_DATA_LOAD_RESULT):
-- found -> sort it; not found -> it does not exist, nothing to wait for.
function TestAnswer(id, success)
    local run = testRun
    id = tonumber(id)
    if not run or not id or not run.waiting[id] then return end
    if success == false then
        TestDone(run, id)
        run.res.missing[#run.res.missing + 1] = id
        return
    end
    TestSort(run, id)
end

function RulesTest(first, last)
    if testRun then Print("the rules test is already running (/amac test stop)") return end
    first, last = first or 1, last or 25000
    local version, build, _, iface = GetBuildInfo()
    local res = { build = tostring(version) .. " " .. tostring(build), interface = iface, first = first, last = last,
        counts = {}, items = {}, unsorted = {}, missing = {}, noanswer = {}, notext = {} }
    -- (which AutoMacros ran it: results from different versions are compared)
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if meta then
        local okMeta, v = pcall(meta, ADDON, "Version")
        if okMeta then res.addon = v end
    end
    -- waiting: not finished; pending: a question out (time asked), tries; spell:
    -- in, but its "Use:" text not yet (since when)
    local run = { res = res, first = first, last = last, next = first, found = {}, asked = 0, answered = 0,
        waiting = {}, pending = {}, tries = {}, spell = {}, inflight = 0, lastProgress = GetTime() }
    testRun = run
    if not testEvents then   -- the server's answers
        testEvents = CreateFrame("Frame")
        for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT" }) do
            pcall(testEvents.RegisterEvent, testEvents, event)   -- (a client may lack one)
        end
        testEvents:SetScript("OnEvent", function(_, _, id, success) TestAnswer(id, success) end)
    end
    local request = (C_Item and C_Item.RequestLoadItemDataByID) or GetItemInfo
    -- the game has the item already: no answer will come, so it is sorted at once
    local function cached(id)
        if C_Item and C_Item.IsItemDataCachedByID then
            local ok, r = pcall(C_Item.IsItemDataCachedByID, id)
            if ok then return r end
        end
        return GetItemInfo(id) ~= nil
    end
    local function ask(id)
        if not run.pending[id] then run.inflight = run.inflight + 1 end
        run.pending[id] = GetTime()
        run.tries[id] = (run.tries[id] or 0) + 1
        pcall(request, id)
    end
    -- why: "noanswer" (the server never answered) or "notext" (it did, but the
    -- "Use:" text never came)
    local function giveUp(id, why)
        TestDone(run, id)
        res[why][#res[why] + 1] = id
    end
    Print(string.format("rules test: items %d-%d on %s. Stay logged in; it takes a few minutes (/amac test stop)",
        first, last, res.build))
    local function finish(note)
        testRun = nil
        for id in pairs(run.waiting) do
            local why = run.spell[id] and "notext" or "noanswer"
            res[why][#res[why] + 1] = id
        end
        table.sort(res.noanswer)
        table.sort(res.notext)
        DB().test = res
        local sorted, unsorted = 0, 0
        for _ in pairs(res.items) do sorted = sorted + 1 end
        for _ in pairs(res.unsorted) do unsorted = unsorted + 1 end
        Print(string.format("rules test %s: %d items looked at, %d sorted onto buttons, %d with a Use: line on none,"
            .. " %d do not exist, %d never answered, %d without their Use: text. /reload to save it to disk.", note,
            #run.found, sorted, unsorted, #res.missing, #res.noanswer, #res.notext))
        TestBarDone(string.format("%s: %d sorted, %d on none - /reload to save", note == "done" and "Done" or "Stopped",
            sorted, unsorted))
    end
    local function step()
        if run.stop then return finish("stopped") end
        local now = GetTime()
        -- 1. which IDs are worth a look (the client knows without the server)
        if run.next <= last then
            for _ = 1, 1000 do
                local id = run.next
                if id > last then break end
                run.next = id + 1
                if WorthALook(id) then run.found[#run.found + 1] = id end
            end
            if run.next > last then
                Print(string.format("rules test: %d items to look at, asking the server for them...", #run.found))
                run.lastProgress = now
            end
            return TEST_TICK
        end
        -- 2. questions with no answer for a while: the data may be in without an
        -- event; else ask again, at most TEST_TRIES times
        for id, at in pairs(run.pending) do
            if now - at > TEST_RETRY then
                if cached(id) then TestSort(run, id)
                elseif run.tries[id] >= TEST_TRIES then giveUp(id, "noanswer")
                else ask(id) end
            end
        end
        -- 3. new questions, while fewer than TEST_INFLIGHT are out (the server's
        -- pace: one goes out as an answer comes back)
        while run.inflight < TEST_INFLIGHT and run.asked < #run.found do
            run.asked = run.asked + 1
            local id = run.found[run.asked]
            run.waiting[id] = true
            if cached(id) then TestSort(run, id) else ask(id) end
        end
        -- 4. items in, but their "Use:" text still on its way: look again, give up after TEST_QUIET
        local n = 0
        for id, since in pairs(run.spell) do
            if not TestSort(run, id) and now - since > TEST_QUIET then giveUp(id, "notext") end
            n = n + 1
            if n >= TEST_STEP then break end
        end
        if run.asked >= #run.found and not next(run.waiting) then return finish("done") end
        if now - run.lastProgress > 2 * TEST_QUIET then return finish("done") end   -- (nothing at all for a minute)
        return TEST_TICK
    end
    local function tick()
        local ok, wait = pcall(step)
        if not ok then
            testRun = nil
            Fail("rules test", wait)
            TestBarDone("Stopped by an error (see chat)")
        elseif wait and testRun == run then
            pcall(TestBarUpdate, run)
            C_Timer.After(wait, tick)
        end
    end
    tick()
end
