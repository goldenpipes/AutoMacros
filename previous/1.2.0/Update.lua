-- AutoMacros: Switching buttons on, and the update that rewrites the macros.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

pending, timerSet, glowTimerSet = false, false, false
-- macro name -> the spell a right-click on it casts (Water, Food: Conjure ...)
rightCast = {}

-- How many different items you carry for a button (travel: also the teleport
-- spells you know; Professions: the profession windows you know); 0 = none.
function Stocked(e, have)
    if e.kind == "travel" then return #TravelOptions(e, have) end
    if e.kind == "fishing" then   -- (poles only: lures alone don't switch it on)
        local n = 0
        for _, f in ipairs(FishingList(have)) do if f.pole then n = n + 1 end end
        return n
    end
    if e.kind == "trinket" then   -- (trinkets with a Use effect: passive ones alone don't switch it on)
        local n = 0
        for _, t in ipairs(TrinketList(e.slot, have)) do if HasUse(t.id) then n = n + 1 end end
        return n
    end
    if e.kind == "weapons" then return SwapBody(have) and 1 or 0 end   -- (once both sets are known)
    if e.autoSpells then return #KnownSpells(e) end
    if e.set then return #Candidates(have, e.set) end
    return 0
end

-- Switches on, for good, every item button this character has not set once
-- it carries something for it (Professions: once it knows one), and any of its
-- own (character tab) macros an earlier version already made (so nobody loses
-- a button from their bars). Returns true when one changed.
function AutoEnable(have)
    local on = OnOff()
    local _, class = UnitClass("player")
    local changed = false
    for _, e in ipairs(ALL) do
        if on[e.key] == nil and not e.custom and e.special ~= "scroll" and (e.kind ~= "spells" or e.autoSpells)
            and (not e.class or e.class == class) then
            -- (or it can make something for it: a Warlock's healthstones, a Mage's mana gems)
            local stocked = Stocked(e, have) > 0 or MadeCreate(e.set, have) ~= nil
            local made = e.scope == "character" and FindMacro(e, true) ~= nil
            if stocked or made then
                on[e.key] = true
                changed = true
                if stocked and not made then
                    Note(e.title .. (e.autoSpells and ": turned on (you know some)" or ": turned on (you are carrying some)"))
                end
            end
        end
    end
    return changed
end

function UpdateCore()
    timerSet = false
    pcall(RebuildMacros)
    local have, scanned, scrolls, locs = ScanBags()
    if not scanned then
        report.error = "bag API not available"
        return
    end
    lastScrolls = scrolls
    lastLocs = locs or {}
    report.have = have   -- for the settings page (UI.CouldUse)
    RebuildLearned()
    -- what is in your bags, and quietly what your known recipes make (see UI.ScanRecipes)
    local look = have
    local recipes = type(DB().recipes) == "table" and DB().recipes[CharKey()]
    if type(recipes) == "table" and next(recipes) then
        look = {}
        for id in pairs(have) do look[id] = true end
        for id in pairs(recipes) do look[id] = true end
    end
    local okLearn, errLearn = pcall(LearnNew, look, have)
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
            -- skipped if it was switched back on in the meantime. A shared
            -- (general tab) macro stays while another character has it on.
            -- (hidden: a stat button while this character uses the one Buffs
            -- button, or that button while it doesn't; its on/off stays as it was)
            local off = not Enabled(e) or HiddenButton(e)
            local elsewhere = false
            if not e.removed and e.scope ~= "character" then
                for char, t in pairs(DB().enabledBy or {}) do
                    if char ~= CharKey() and type(t) == "table" and t[e.key] then elsewhere = true end
                end
            end
            if elsewhere and off then
                Note(e.title .. ": off on this character (its macro stays: another character uses it)")
            elseif off or e.removed then
                DeleteManaged(e)
            end
        end
    end
    local emptyState = {}
    for _, m in ipairs(MACROS) do
        local body, id, spellUsed, making
        if m.special == "scroll" then
            flyoutItems[m.name] = scrolls
            body, id = ScrollBody(m, scrolls)
        elseif m.kind == "spells" then
            local list = KnownSpells(m)
            flyoutItems[m.name] = list
            id = ChosenFor(m, list)   -- (Tracking: the one switched on)
            body = id and SpellBody(id) or nil
        elseif m.order then
            -- a button of your own: what you carry or know of it, in your order
            local list = {}
            for _, t in ipairs(m.order) do
                if t.kind == "spell" then
                    if KnowsSpell(t.id) then list[#list + 1] = { id = t.id, spell = true, pick = -t.id } end
                elseif have[t.id] then
                    list[#list + 1] = { id = t.id }
                end
            end
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
        elseif m.kind == "fishing" then
            -- your fishing pole on and off (FishBody); lures and the rest are only in the popout
            local list = FishingList(have)
            flyoutItems[m.name] = list
            local poles = {}
            for _, e in ipairs(list) do if e.pole then poles[#poles + 1] = e end end
            id = Chosen(m, poles)
            body = id and FishBody(id, have) or EmptyBody(m.label)
        elseif m.kind == "trinket" then
            -- uses the trinket worn in its slot; the popout wears another there
            local list, worn = TrinketList(m.slot, have)
            flyoutItems[m.name] = list
            body, id = TrinketBody(m.slot, list, worn)
            body = body or EmptyBody(m.label)
        elseif m.kind == "weapons" then
            -- two-hander <-> one-hander and off hand; until both are known it says how to teach it
            flyoutItems[m.name] = WeaponList(have)
            body, id = SwapBody(have)
            body = body or ("/amac empty " .. m.emptyText)
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
            local made = MADE[m.set]
            local create, carried, createID = MadeCreate(m.set, have)
            -- out of food (water): use Food & Drink instead, unless switched off.
            -- Combo items only ever show on Food / Water this way. A mage who
            -- could conjure eats the combo item; right-click still conjures.
            if #list == 0 and (m.set == "food" or m.set == "water") and not DB().noComboFallback then
                list = Candidates(have, "combo")
                if #list > 0 then carried = true end
            end
            if made then
                -- what you make (healthstone, mana gem, conjured water / food) first,
                -- best rank first, then the rest best first
                table.sort(list, function(x, y)
                    local rx, ry = made.rank[x.id] or 0, made.rank[y.id] or 0
                    if rx ~= ry then return rx > ry end
                    return x.score > y.score
                end)
            end
            -- the button's spells you know, after the items (saved as negative picks)
            for _, s in ipairs(KnownSpells(m)) do
                list[#list + 1] = { id = s.id, spell = true, pick = -s.id }
            end
            -- the spell that makes them (Conjure Water, Create Healthstone, ...)
            -- whenever you know it, your best rank only, last; picked by name,
            -- so learning a new rank keeps it picked
            if create and createID then
                list[#list + 1] = { id = createID, spell = true, pick = create }
            end
            flyoutItems[m.name] = list
            local entry
            id, entry = Chosen(m, list)
            spellUsed = entry ~= nil and entry.spell == true
            -- Water and Food (made.rightClick): a right-click always makes more
            local right = create and made and made.rightClick
            rightCast[m.name] = right and create or nil   -- (for its tooltip, see RightClickHint)
            if create and not carried then
                -- you can make one and carry none: the button makes one, Shift+click
                -- uses the item chosen from what you do carry
                making = true
                body = "#showtooltip " .. create .. "\n/cast " .. (right and "[btn:2][nomod] " or "[nomod] ") .. create
                if id and not spellUsed then
                    body = body .. "\n/use " .. (right and "[mod:shift,nobtn:2] " or "[mod:shift] ") .. "item:" .. id
                end
            elseif right and id and not spellUsed then
                -- left-click uses the chosen item, right-click makes more
                body = "#showtooltip " .. ItemRef(id) .. "\n/cast [btn:2] " .. create .. "\n/use [nobtn:2] item:" .. id
            elseif not id then
                body = EmptyBody(m.label)
            elseif spellUsed then
                body = SpellBody(id)
            elseif entry and entry.unlock then
                body = "#showtooltip " .. ItemRef(id) .. "\n" .. entry.unlock   -- a locked box (OpenableList)
            elseif m.weapon then
                body = WeaponBody(id)
            else
                body = UseBody(id)
            end
        end
        -- spell and scroll buttons show the spell when there is nothing to use, so they are never "empty"
        -- (nor is one that makes a healthstone, mana gem or conjured water / food)
        emptyState[m.name] = (id == nil) and not making and m.kind ~= "spells" and m.special ~= "scroll"
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
    if not ok then Fail("highlight/popout", err) end
end

function Update()
    local ok, err = pcall(UpdateCore)
    if not ok then Fail("update", err) end
    if report.afterUpdate then pcall(report.afterUpdate) end   -- the settings page, if open
    -- items still waiting for their data: look again in a second
    if report.learnWaiting and not report.learnRetry and C_Timer and C_Timer.After then
        report.learnRetry = true
        C_Timer.After(1, function() report.learnRetry = nil; Update() end)
    end
end
