-- AutoMacros: Running it: scheduling updates, the bar watcher, changes to saved data
-- from older versions, login, events, /amac commands.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- EllesmereUI's page when it is installed, unless blizzard (/amac options blizzard)
function OpenOptions(blizzard)
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

function Schedule()
    if timerSet then return end
    timerSet = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, Update)
    else
        Update()
    end
end

-- Bar events only need the highlight redrawn, not the macros rewritten.
function ScheduleGlow()
    if glowTimerSet then return end
    glowTimerSet = true
    local function run()
        glowTimerSet = false
        RefreshGlow()
        -- a button dragged onto a bar (or off one): the settings page's glow follows
        if report.afterUpdate then pcall(report.afterUpdate) end
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
barSeen, sinceCheck, sinceCollect, watchUntil = {}, 0, 0, 0

-- true when any button holds something else than at the last check (kind, id
-- and text per button, kept in barSeen; no strings are built)
function BarChanged()
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

function WatchBars(elapsed)
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
        if not ok2 then Fail("highlight/popout", err) end
        if report.afterUpdate then pcall(report.afterUpdate) end   -- the settings page's glow
    end
end

-- Runs once per login. The saved data is already loaded by now.
-- 0.92.0 merged the Scroll and Elixir buttons of each stat into one buff
-- button (see CATALOG). Once, at login: a character's new button is on if
-- either old one was (off if one was switched off and neither on), and a popout
-- direction and hand sorted items move over. The elixir buttons' macros are
-- kept (the next update renames them); the scroll buttons' are deleted a
-- moment after login, once the macros are loaded (UI.RemoveScrollMacros).
UI.MERGED = {   -- old scroll key, old elixir key, new key, scroll macro names
    { "agiscroll", "agielixir", "agility", "Agility Scroll", "No Agi Scroll" },
    { "intscroll", "intelixir", "intellect", "Intellect Scroll", "No Int Scroll" },
    { "stascroll", "staelixir", "stamina", "Stamina Scroll", "No Sta Scroll" },
    { "strscroll", "strelixir", "strength", "Strength Scroll", "No Str Scroll" },
}
function UI.MergeBuffButtons()
    local db = DB()
    if db.buffsMerged then return end
    OnOff()   -- (moves a pre-0.89.0 account-wide list into enabledBy first)
    for _, t in pairs(type(db.enabledBy) == "table" and db.enabledBy or {}) do
        if type(t) == "table" then
            for _, m in ipairs(UI.MERGED) do
                local a, b = t[m[1]], t[m[2]]
                if t[m[3]] == nil and (a ~= nil or b ~= nil) then t[m[3]] = (a == true or b == true) end
                t[m[1]], t[m[2]] = nil, nil
            end
        end
    end
    if type(db.popDir) == "table" then
        for _, m in ipairs(UI.MERGED) do
            db.popDir[m[3]] = db.popDir[m[3]] or db.popDir[m[2]] or db.popDir[m[1]]
            db.popDir[m[1]], db.popDir[m[2]] = nil, nil
        end
    end
    -- /amac assign results: scroll_<stat> and elixir_<stat> are now buff_<stat>
    for _, rec in pairs(type(db.learned) == "table" and db.learned or {}) do
        if type(rec) == "table" and type(rec.sets) == "table" then
            local seen, sets = {}, {}
            for _, s in ipairs(rec.sets) do
                s = s:gsub("^scroll_", "buff_"):gsub("^elixir_", "buff_")
                if not seen[s] then seen[s] = true; sets[#sets + 1] = s end
            end
            rec.sets = sets
        end
    end
    db.buffsMerged = true
end

-- The merged scroll buttons' macros (general tab, shared): deleted once, out
-- of combat, when the macros have loaded. Only ours: one that used an item or
-- shows the empty-button message.
function UI.RemoveScrollMacros()
    local db = DB()
    if db.scrollMacrosGone or InCombatLockdown() then return end
    if (GetNumMacros() or 0) == 0 then return end   -- not loaded yet (or none at all): next time
    local deleted = false
    for _, m in ipairs(UI.MERGED) do
        for _, name in ipairs({ m[4], m[5] }) do
            local idx = GetMacroIndexByName(name)
            local body = idx and idx > 0 and GetMacroBody(idx)
            if type(body) == "string" and (body:find("#showtooltip", 1, true) or body:find("/amac empty", 1, true)) then
                if pcall(DeleteMacro, idx) then deleted = true end
            end
        end
    end
    if deleted then
        db.idx = {}   -- the macros after them moved (see DeleteManaged)
        Note("the Scroll and Elixir buttons are now one buff button per stat; the scroll buttons' macros were removed")
    end
    db.scrollMacrosGone = true
end

-- 0.95.0 merged the Healthstone button into Restore Health (was Health
-- Potion): on a character Restore Health is on if either was. Once, at login.
function UI.MergeHealthstone()
    local db = DB()
    if db.healthMerged then return end
    OnOff()
    for _, t in pairs(type(db.enabledBy) == "table" and db.enabledBy or {}) do
        if type(t) == "table" and t.healthstone ~= nil then
            if t.healthstone == true or t.healthpot == nil then t.healthpot = t.healthstone end
            t.healthstone = nil
        end
    end
    if type(db.popDir) == "table" then
        db.popDir.healthpot = db.popDir.healthpot or db.popDir.healthstone
        db.popDir.healthstone = nil
    end
    db.healthMerged = true
end

-- The old Healthstone button's macro (in each character's own macro tab):
-- deleted when found, out of combat, a moment after login. Only ours: it makes
-- or uses a healthstone, or shows the empty-button message.
function UI.RemoveHealthstoneMacro()
    if InCombatLockdown() then return end
    for _, name in ipairs({ "Healthstone", "No Healthstone" }) do
        local idx = GetMacroIndexByName(name)
        local body = idx and idx > 0 and GetMacroBody(idx)
        if type(body) == "string" then
            local id = tonumber(body:match("item:(%d+)"))
            if body:find("Create Healthstone", 1, true) or (id and HS_RANK[id])
                or body:find("/amac empty No Healthstone", 1, true) then
                if pcall(DeleteMacro, idx) then
                    DB().idx = {}   -- the macros after it moved (see DeleteManaged)
                    Note("Healthstone is now part of Restore Health; the old Healthstone macro was removed")
                end
            end
        end
    end
end

function Init()
    local db = DB()
    report.priorSessions = tonumber(db.sessions) or 0
    db.sessions = report.priorSessions + 1
    -- a new character gets the welcome window (looked at before anything is saved for it)
    local okWelcome, due = pcall(UI.WelcomeDue)
    report.welcomeDue = okWelcome and due or nil
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
    local okMerge, errMerge = pcall(UI.MergeBuffButtons)
    if not okMerge then Fail("merging the buff buttons", errMerge) end
    local okHealth, errHealth = pcall(UI.MergeHealthstone)
    if not okHealth then Fail("merging the healthstone button", errHealth) end
    -- 0.93.0: 0.92.0's Protection button is Armor Buff now (resistance items got their own)
    for _, t in pairs(type(db.enabledBy) == "table" and db.enabledBy or {}) do
        if type(t) == "table" and t.protection ~= nil then
            if t.armor == nil then t.armor = t.protection end
            t.protection = nil
        end
    end
    if type(db.popDir) == "table" and db.popDir.protection then
        db.popDir.armor = db.popDir.armor or db.popDir.protection
        db.popDir.protection = nil
    end
    -- 0.98.0: Anti-Venom (and 0.97.0's Disease / Bleed Cure) are one Debuff Cure button:
    -- on if any of them was on
    local oldCures = { "antivenom", "antidisease", "antibleed" }
    for _, t in pairs(type(db.enabledBy) == "table" and db.enabledBy or {}) do
        if type(t) == "table" then
            for _, k in ipairs(oldCures) do
                if t[k] ~= nil then
                    if t.cure == nil or t[k] == true then t.cure = t[k] end
                    t[k] = nil
                end
            end
        end
    end
    if type(db.popDir) == "table" then
        for _, k in ipairs(oldCures) do
            db.popDir.cure = db.popDir.cure or db.popDir[k]
            db.popDir[k] = nil
        end
    end
    for _, rec in pairs(type(db.learned) == "table" and db.learned or {}) do   -- /amac assign
        if type(rec) == "table" and type(rec.sets) == "table" then
            local seen, sets = {}, {}
            for _, s in ipairs(rec.sets) do
                if s == "antivenom" or s == "antidisease" or s == "antibleed" then s = "cure" end
                if not seen[s] then seen[s] = true; sets[#sets + 1] = s end
            end
            rec.sets = sets
        end
    end
    pcall(RegisterEUI)   -- in case EllesmereUI loaded after this addon
    local okPanel, errPanel = pcall(UI.RegisterBlizzPanel)   -- Esc > Options > AddOns
    if not okPanel then Fail("options page", errPanel) end
end

BAR_EVENTS = {
    ACTIONBAR_SLOT_CHANGED = true, ACTIONBAR_PAGE_CHANGED = true,
    UPDATE_BONUS_ACTIONBAR = true, UPDATE_SHAPESHIFT_FORM = true,
}

frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local ok, err = pcall(Init)
        if not ok then Fail("startup", err) end
    end
    if event:find("^TRADE_SKILL") then
        UI.QueueScan()   -- your recipes, while a profession window is open
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if pending then Schedule() end
    elseif BAR_EVENTS[event] then
        ScheduleGlow()
    else
        if event == "PLAYER_ENTERING_WORLD" and C_Timer and C_Timer.After then
            -- bar addons build their buttons a moment after login
            C_Timer.After(3, function()
                local okScrolls, errScrolls = pcall(UI.RemoveScrollMacros)   -- (once, 0.92.0)
                if not okScrolls then Fail("removing the old scroll macros", errScrolls) end
                local okHs, errHs = pcall(UI.RemoveHealthstoneMacro)   -- (0.95.0, per character)
                if not okHs then Fail("removing the old healthstone macro", errHs) end
                SafeCollect()
                local ok, err = pcall(RefreshGlow)
                if not ok then Fail("highlight/popout", err) end
                -- (by now the bags have been read and buttons switched on)
                if report.welcomeDue then
                    report.welcomeDue = nil
                    local okW, errW = pcall(UI.ShowWelcome)
                    if not okW then Fail("welcome window", errW) end
                end
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
    "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE",   -- a profession window (recipes)
}) do
    pcall(frame.RegisterEvent, frame, event)   -- skip events this client lacks
end

_G.SLASH_AUTOMACROS1 = "/automacros"
_G.SLASH_AUTOMACROS2 = "/amac"
SlashCmdList["AUTOMACROS"] = function(msg)
    -- an empty button was clicked (see EmptyBody): its message, for you only
    local message = msg and msg:match("^%s*[Ee][Mm][Pp][Tt][Yy]%s+(.+)$")
    if message then
        if DB().noEmptyMsg then return end   -- General > Chat > "Show the empty-button message" off
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
        Print("/amac options, /amac welcome, /amac assign <item> <name>, /amac unassign <item>, /amac learned,"
            .. " /amac status, /amac test")
        return
    elseif msg:match("^%s*add%s+") or msg:match("^%s*remove%s+") then
        local verb, key = msg:match("^%s*(%a+)%s+(%S+)")
        local e = find(key)
        if not e then
            Print("no category called " .. key .. " - /amac list shows them")
            return
        end
        Print(e.title .. (verb == "add" and ": on for this character" or ": off for this character"))
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
    elseif msg:match("^%s*welcome") then
        local ok, err = pcall(UI.ShowWelcome)
        if not ok then Fail("welcome window", err) end
        return
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
    elseif msg:match("^%s*test") then
        -- /amac test [first] [last] | /amac test stop  (see RulesTest)
        if msg:find("stop", 1, true) then
            if testRun then testRun.stop = true else Print("no rules test is running") end
        else
            local first, last = msg:match("(%d+)%D+(%d+)")
            RulesTest(tonumber(first), tonumber(last))
        end
        return
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
            skin and "styling the popout" or (EllesmereUI and "found, not skinning (turn it on in EllesmereUI)" or "not installed")))
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
    elseif msg:match("^%s*popout") or msg:match("^%s*flyout") then   -- (its name before 0.90.0)
        local db = DB()
        db.noFlyout = not db.noFlyout
        Print("item popouts: " .. (db.noFlyout and "off" or "on"))
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
    Print("action buttons found: " .. #buttons .. ", highlighted: " .. (report.glowing or 0) .. ", popout indicators: " .. (report.tabs or 0))
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
    Print("popouts - " .. table.concat(parts, "; "))
end
