-- AutoMacros: DaylightUI: our settings as a plugin section in DaylightUI's options
-- window (only while DaylightUI is installed), like the page in EllesmereUI's.
-- Through DaylightUI's public API: RegisterPlugin + RegisterModule with option
-- pages of plain rows (toggle, slider, dropdown, color, button, text) that read
-- and write our own settings by get / set, and "custom" rows we draw ourselves
-- (the preview strips, the learned list, your own buttons). DaylightUI builds a
-- page once and keeps it, so every row that can come and go is there from the
-- start and hidden while it doesn't apply (our "when" -> its "hidden").

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

UI.DUI_MODULE = "AutoMacros"   -- its module's name: page ids are "AutoMacros.<id>"

-- DaylightUI's options window, while it is on screen: shows the values again
-- (and our custom rows rebuild what changed). Not in DaylightUI's promised API,
-- so pcall'd: a later version without it only means a page that catches up when
-- next opened.
function RefreshDUIPage()
    local P = DaylightUI and DaylightUI.OptionsPanel
    if type(P) ~= "table" or not (P.IsShown and P.Refresh) then return end
    pcall(function() if P.IsShown() then P.Refresh() end end)
end

-- the page id for one of our PAGES names
function UI.DUIPageId(name)
    return UI.DUI_MODULE .. "." .. string.lower(name or "general")
end

-- one of the buttons as it is now (ALL, without the stat buttons while one
-- Buffs button is used), or nil; class buttons only on that class
local function LiveButton(key)
    local _, class = UnitClass("player")
    for _, e in ipairs(ALL) do
        if e.key == key and (not e.class or e.class == class) then return e end
    end
end

-- an item's when (shown while it returns true) as DaylightUI's hidden
local function Hidden(when, extra)
    if not when and not extra then return nil end
    return function()
        if extra and extra() then return true end
        if when and not when() then return true end
        return false
    end
end

-- a set function as DaylightUI wants it: only an explicit false means refused
local function Setter(fn)
    return function(v) fn(v); return true end
end

-- A custom row holding something we draw ourselves: make(holder, width) fills
-- a fresh holder and returns its height; it is made again when stamp() (if
-- given) changes or the row's width does. refresh(holder) runs on every
-- refresh of the page.
local function CustomRow(make, stamp, refresh, hidden)
    local item = { type = "custom", label = "", noSearch = true, hidden = hidden }
    local function fill(row)
        local w = math.floor(row:GetWidth() or 0)
        if w <= 0 then return row.amH or 1 end
        local s = stamp and stamp() or ""
        if row.amHolder and row.amW == w and row.amStamp == s then return row.amH end
        if row.amHolder then row.amHolder:Hide() end
        local holder = CreateFrame("Frame", nil, row)
        holder:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        holder:SetSize(w, 10)
        holder.amRefreshers = {}
        local ok, h = pcall(make, holder, w)
        if not ok then
            Fail("DaylightUI page", h)
            h = 1
        end
        h = math.max(1, tonumber(h) or 1)
        holder:SetHeight(h)
        row.amHolder, row.amW, row.amStamp, row.amH = holder, w, s, h
        return h
    end
    item.build = function(row) row.amH = 1 end
    item.height = fill
    item.update = function(row)
        -- (a changed stamp: the next layout measures it again and rebuilds it)
        if stamp and row.amHolder and row.amStamp ~= stamp() then row.amW = nil end
        local holder = row.amHolder
        if holder then
            for _, r in ipairs(holder.amRefreshers or {}) do pcall(r) end
            if refresh then pcall(refresh, holder) end
        end
    end
    return item
end

-- A color setting (our mode + color + opacity) as two rows: the mode
-- dropdown, and DaylightUI's swatch showing the color drawn now. Picking a new
-- color makes it Custom; changing only the opacity keeps the mode.
-- keyOf: the style key (a function for the Per-Button Overrides' hover).
local function ColorRows(out, label, keyOf, alpha, hidden)
    out[#out + 1] = { type = "dropdown", label = label, hidden = hidden,
        choices = function() return UI.Choices(ColorModeChoices(keyOf())) end,
        get = function() return ColorMode(keyOf()) end,
        set = Setter(function(v) SetColorMode(keyOf(), v); RefreshHeaders() end) }
    out[#out + 1] = { type = "color", label = alpha and "Color and opacity" or "Color", alpha = alpha and true or nil,
        hidden = hidden,
        get = function()
            local key = keyOf()
            local c = StyleColor(key)
            local s = Style(key)
            local a = type(s) == "table" and s[4] or c[4] or 1
            return { c[1], c[2], c[3], a }
        end,
        set = Setter(function(v)
            if type(v) ~= "table" then return end
            -- (SetColor: a new color becomes Custom, the opacity alone keeps the mode)
            SetColor(keyOf(), v[1], v[2], v[3], alpha and tonumber(v[4]) or nil)
            RefreshHeaders()
        end) }
end

-- Our settings items as DaylightUI rows, appended to out. hide: an extra
-- "hidden" for all of them (Per-Button Overrides while no button is picked).
local function Rows(items, out, hide)
    for _, item in ipairs(items) do
        local hidden = Hidden(item.when, hide)
        local t = item.type
        if t == "row" then
            Rows(item.items, out, hidden)
        elseif t == "eui" then
            if EllesmereUI then Rows(item.items, out, hidden) end
        elseif t == "toggle" then
            out[#out + 1] = { type = "toggle", label = item.label, hidden = hidden,
                get = function() return item.get() and true or false end, set = Setter(item.set) }
        elseif t == "range" then
            local get = item.get or function() return tonumber(Style(item.key)) end
            local set = item.set or function(v) SetStyle(item.key, v) end
            local floor = item.floor
            local unit = item.fmt and item.fmt:find("%%%%") and "%" or nil
            out[#out + 1] = { type = "slider", label = item.label, hidden = hidden,
                min = item.min, max = UI.Num(item.max), step = item.step, unit = unit,
                disabled = item.disabled and function() return item.disabled() end or nil,
                get = function() return tonumber(get()) or item.min end,
                set = Setter(function(v)
                    v = tonumber(v) or item.min
                    if floor then v = math.max(floor, v) end
                    set(v)
                    RefreshHeaders()
                end) }
        elseif t == "choice" then
            local get = item.get or function() return Style(item.key) end
            local set = item.set or function(v) SetStyle(item.key, v) end
            out[#out + 1] = { type = "dropdown", label = item.label, hidden = hidden,
                choices = function() return UI.Choices(item.list()) end,
                get = get, set = Setter(function(v) set(v); RefreshHeaders() end) }
        elseif t == "color" then
            local key = item.key
            ColorRows(out, item.label, function() return key end, item.alpha, hidden)
        elseif t == "text" then
            out[#out + 1] = { type = "text", hidden = hidden,
                label = function() return Loc(type(item.text) == "function" and item.text() or tostring(item.text or "")) end }
        elseif t == "button" then
            out[#out + 1] = { type = "button", label = item.label, hidden = hidden,
                func = function()
                    pcall(item.action)
                    RefreshOptions()
                end }
        elseif t == "multi" then
            -- each choice its own switch
            for _, c in ipairs(item.list()) do
                local key = c.key
                out[#out + 1] = { type = "toggle", label = c.label, hidden = hidden,
                    get = function() return item.isOn(key) and true or false end,
                    set = Setter(function(v) item.set(key, v) end) }
            end
        elseif t == "togglegrid" then
            for _, tg in ipairs(item.toggles or {}) do
                out[#out + 1] = { type = "toggle", label = tg.label, hidden = hidden,
                    get = function() return tg.get() and true or false end, set = Setter(tg.set) }
            end
        elseif t == "learned" then
            out[#out + 1] = CustomRow(function(holder, w)
                return UI.BuildLearnedList(holder, 16, 0, w - 32, holder.amRefreshers) + 8
            end, nil, nil, hidden)
        elseif t == "customrows" then
            out[#out + 1] = CustomRow(function(holder, w)
                return -UI.BuildCustomRows(holder, w, 16, 0, holder.amRefreshers) + 8
            end, UI.CustomStamp, nil, hidden)
        end
        -- (spacer and anything else: nothing)
    end
    return out
end

-- a page's preview strip (UI.HEADERS) as a row of its own at the top
local function PreviewGroup(key)
    return { label = "Preview", items = {
        CustomRow(function(holder, w)
            return UI.ShowHeader(key, holder, w, function() RefreshDUIPage() end) + 6
        end, nil, function() RefreshHeaders() end),
    } }
end

-- The Buttons page: a switch for every button this character could have, in
-- the Buttons page's groups (A-Z), each hidden while that button isn't there
-- (the stat buttons while one Buffs button is used, say).
local function ButtonGroups()
    local _, class = UnitClass("player")
    local all = {}
    for _, e in ipairs(CATALOG) do
        if not e.class or e.class == class then all[#all + 1] = e end
    end
    local byKey, placed = {}, {}
    for _, e in ipairs(all) do byKey[e.key] = e end
    local groups = { PreviewGroup("buttons") }
    local function add(name, list, before, after)
        table.sort(list, function(a, b)
            return tostring(Loc(UI.Name(a))):lower() < tostring(Loc(UI.Name(b))):lower()
        end)
        local items = {}
        if before then Rows(before, items) end
        for _, e in ipairs(list) do
            local key = e.key
            items[#items + 1] = { type = "toggle", label = UI.Name(e),
                hidden = function()
                    local live = LiveButton(key)
                    return live == nil or live.oneBuff == true
                end,
                get = function() local live = LiveButton(key); return live ~= nil and Enabled(live) end,
                set = Setter(function(v)
                    local live = LiveButton(key)
                    if live then UI.SetEnabled(live, v) end
                end) }
        end
        if after then Rows(after, items) end
        if #items > 0 then groups[#groups + 1] = { label = name, items = items } end
    end
    for _, g in ipairs(UI.BUTTON_GROUPS) do
        local list = {}
        for _, key in ipairs(g.keys) do
            local e = byKey[key]
            if e then
                if not e.oneBuff then list[#list + 1] = e end
                placed[key] = true
            end
        end
        if g.buffs then
            -- combining, then (while combined) a switch per buff type, then the note on Other
            local before = {
                { type = "toggle", label = "Combine class-related buffs into one button",
                  get = function() return OneBuff() end, set = function(v) UI.SetOneBuff(v) end },
            }
            for _, part in ipairs(BUFF_PARTS) do
                before[#before + 1] = { type = "toggle", label = "Buffs: " .. (UI.PART_NAMES[part] or part),
                    when = function() return OneBuff() end,
                    get = function() return BuffParts()[part] == true end,
                    set = function(v) UI.SetBuffPart(part, v) end }
            end
            local after = { { type = "text", text = function()
                return "Other: buffs that fit none of the above, such as attack power, regeneration or crit." end } }
            add(g.name, list, before, after)
        else
            add(g.name, list)
        end
    end
    local other = {}
    for _, e in ipairs(all) do
        if not placed[e.key] then other[#other + 1] = e end
    end
    add("Other", other)
    -- your own buttons, one editable row each (Custom.lua)
    groups[#groups + 1] = { label = "Custom", items = {
        { type = "text", label = function()
            return Loc("Drag an item or spell onto the + in the preview above to make a button of your own.") end,
          hidden = function() return next(UI.CustomTable()) ~= nil end },
        CustomRow(function(holder, w)
            return -UI.BuildCustomRows(holder, w, 16, 0, holder.amRefreshers) + 8
        end, UI.CustomStamp, nil, function() return next(UI.CustomTable()) == nil end),
    } }
    return groups
end

-- Per-Button Overrides: pick a button, then its own settings (all of them
-- there from the start, hidden until a button is picked)
local function OverrideItems()
    local none = function() return #UI.EnabledButtons() == 0 end
    local items = {
        { type = "text", when = none, text = function() return "Turn a button on to set its popout here." end },
        { type = "choice", label = "Button", when = function() return not none() end,
            list = function()
                local list = { { key = "_example", label = "Example" } }
                for _, e in ipairs(UI.EnabledButtons()) do list[#list + 1] = { key = e.key, label = e.title } end
                return list
            end,
            get = function() local e = UI.PopoutEntry(); return e and e.key or "_example" end,
            set = function(v)
                UI.popoutKey = (v ~= "_example") and v or nil
                UI.PopoutChanged()
            end },
        { type = "text", when = function() return not none() and UI.PopoutEntry() == nil end,
            text = function() return "Pick one of your buttons to give its popout its own settings." end },
    }
    local out = Rows(items, {})
    -- the picked button's own rows (UI.OwnPopoutItems reads the picked button
    -- each time; only its Hover color's key is fixed when made, so that one is
    -- done here with the key worked out each time)
    local real = UI.PopoutEntry
    UI.PopoutEntry = function() return { key = "_" } end
    local ok, own = pcall(UI.OwnPopoutItems)
    UI.PopoutEntry = real
    if not ok then
        Fail("DaylightUI page", own)
        return out
    end
    local unpicked = function() return UI.PopoutEntry() == nil end
    for _, item in ipairs(own) do
        if item.type == "color" then
            ColorRows(out, item.label, function()
                local e = UI.PopoutEntry()
                return e and ("entryHover_" .. e.key) or "entryHover"
            end, item.alpha, Hidden(item.when, unpicked))
        else
            Rows({ item }, out, unpicked)
        end
    end
    return out
end

-- our PAGES as DaylightUI pages: { id, label, desc, groups }
local function Pages()
    local pages = {}
    for _, page in ipairs(PAGES) do
        local groups
        if page.name == "Buttons" then
            groups = ButtonGroups()
        else
            groups = {}
            if page.header then groups[1] = PreviewGroup(page.header) end
            local sections = type(page.sections) == "function" and page.sections() or page.sections
            for _, section in ipairs(sections) do
                local items
                if section.name == "Per-Button Overrides" then
                    items = OverrideItems()
                elseif type(section.items) == "table" then
                    items = Rows(section.items, {})
                end
                if items and #items > 0 then groups[#groups + 1] = { label = section.name, items = items } end
            end
        end
        pages[#pages + 1] = { id = string.lower(page.name), label = page.name, groups = groups }
    end
    return pages
end

-- Our section in DaylightUI's options window (once; from Init, after login,
-- so the class and the saved settings are known).
function RegisterDUI()
    if UI.duiRegistered then return end
    local API = DaylightUI and DaylightUI.API
    if type(API) ~= "table" or API.major ~= 1 then return end
    if not (DaylightUI.RegisterPlugin and DaylightUI.RegisterModule) then return end
    UI.duiRegistered = true
    local ok, err = pcall(function()
        DaylightUI:RegisterPlugin("AutoMacros", {
            needs = { 1, 3 },
            color = { 0.4, 0.8, 1 },
            short = "AutoMacros",
            blurb = "Consumable and teleport macros: buttons, highlight, popout and item learning.",
        })
        DaylightUI:RegisterModule(UI.DUI_MODULE, {
            plugin = "AutoMacros", label = "AutoMacros", defaults = {},
            options = { pages = Pages() },
        })
    end)
    if not ok then Fail("DaylightUI page", err) end
end

-- Opens our section in DaylightUI's window at page (a PAGES name); false when
-- it can't.
function OpenDUIPage(page)
    if not UI.duiRegistered then return false end
    local P = DaylightUI and DaylightUI.OptionsPanel
    if type(P) ~= "table" or not P.Show then return false end
    local ok = pcall(P.Show, UI.DUIPageId(page or PAGES[1].name))
    return ok and P.IsShown and P.IsShown() or false
end
