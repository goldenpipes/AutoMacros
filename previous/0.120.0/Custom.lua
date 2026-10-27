-- AutoMacros: your own buttons (db.custom), made on the Buttons settings page
-- by dragging items from your bags or spells from your spellbook onto the +
-- at the end of its icon row; edited in its Custom section.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- Saved as db.custom[key] = { title = "...", list = { { kind = "item" | "spell",
-- id = n }, ... }, scope = "character" | nil, oldNames = { ... } }: key is made
-- from the first name (letters and digits), title is the macro's name (16
-- characters at most), list what it holds in your order (CustomThings turns
-- the old kind/ids form into it), oldNames the names it had before a rename,
-- so its macro is found and renamed rather than made again (see CustomEntries).

function UI.CustomTable()
    local db = DB()
    if type(db.custom) ~= "table" then db.custom = {} end
    return db.custom
end

-- a free key for a new button called title
function UI.CustomKey(title)
    local custom = UI.CustomTable()
    local base = tostring(title):lower():gsub("[^%w]", ""):sub(1, 12)
    if base == "" then base = "custom" end
    local taken = {}
    for _, e in ipairs(CATALOG) do taken[e.key] = true; if e.alias then taken[e.alias] = true end end
    local key, n = base, 1
    while custom[key] or taken[key] do
        n = n + 1
        key = base .. n
    end
    return key
end

-- What is on the cursor: "items", itemID or "spells", spellID (nil for anything
-- else). GetCursorInfo gives "item", id or "spell", slot, book, spellID.
function UI.CursorThing()
    local kind, a, book, spellID = GetCursorInfo()
    if kind == "item" and tonumber(a) then return "items", tonumber(a) end
    if kind == "spell" then
        spellID = tonumber(spellID)
        if not spellID and GetSpellBookItemInfo then   -- (a client that gives only the spellbook slot)
            local ok, _, id = pcall(GetSpellBookItemInfo, a, book)
            if ok then spellID = tonumber(id) end
        end
        if spellID then return "spells", spellID end
    end
    return nil
end

function UI.ThingName(kind, id)
    if UI.ThingKind(kind) == "spell" then return SpellName(id) or ("Spell " .. id) end
    return ItemRef(id)
end

function UI.ThingIcon(kind, id)
    if UI.ThingKind(kind) == "spell" then return SpellIcon(id) end
    return IconFor({ item = id })
end

-- after any change: the buttons, the macros, and the pages
function UI.CustomChanged()
    pcall(RebuildMacros)
    Refresh()
    RefreshHeaders()
    UI.RefreshButtonsPage()
    RefreshEUIPage()
end

-- "item" or "spell", from UI.CursorThing's "items" / "spells"
function UI.ThingKind(kind)
    return (kind == "spells" or kind == "spell") and "spell" or "item"
end

-- a new button with one item or spell in it, named after it. One that starts
-- with a spell goes in the character macro tab (spells differ per character),
-- one that starts with an item in the shared tab.
function UI.CustomCreate(kind, id)
    kind = UI.ThingKind(kind)
    local title = UI.ThingName(kind, id):sub(1, 16)
    local key = UI.CustomKey(title)
    UI.CustomTable()[key] = { title = title, list = { { kind = kind, id = id } },
        scope = kind == "spell" and "character" or nil }
    OnOff()[key] = true
    Note("new button " .. title .. " - drag more onto its icon in the AutoMacros settings")
    UI.CustomChanged()
end

-- adds an item or spell at the end (items and spells can share a button)
function UI.CustomAdd(key, kind, id)
    local c = UI.CustomTable()[key]
    if not c then return end
    kind = UI.ThingKind(kind)
    local list = CustomThings(c)
    for _, t in ipairs(list) do
        if t.kind == kind and t.id == id then return end
    end
    list[#list + 1] = { kind = kind, id = id }
    UI.CustomChanged()
end

-- takes the i-th one out; taking the last one out deletes the button
function UI.CustomRemove(key, i)
    local c = UI.CustomTable()[key]
    if not c then return end
    local list = CustomThings(c)
    if list[i] then table.remove(list, i) end
    if #list == 0 then return UI.CustomDelete(key) end
    UI.CustomChanged()
end

-- moves the i-th one to place j (the button's order is the popout's, and the
-- first one you have is what the button uses unless you pick another)
function UI.CustomMove(key, i, j)
    local c = UI.CustomTable()[key]
    if not c then return end
    local list = CustomThings(c)
    if i == j or not list[i] or j < 1 or j > #list then return end
    local t = table.remove(list, i)
    table.insert(list, j, t)
    UI.CustomChanged()
end

function UI.CustomRename(key, title)
    local c = UI.CustomTable()[key]
    title = tostring(title or ""):gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 16)
    if not c or title == "" or title == c.title then return end
    -- the macro is still under the old names until the next update renames it
    c.oldNames = c.oldNames or {}
    c.oldNames[#c.oldNames + 1] = c.title
    c.oldNames[#c.oldNames + 1] = ("No " .. c.title):sub(1, 16)
    c.title = title
    UI.CustomChanged()
end

-- the button and its macro (the macro waits for the end of combat)
function UI.CustomDelete(key)
    for _, e in ipairs(ALL) do
        if e.custom and e.key == key then
            e.removed = true
            toDelete[e.key] = e
        end
    end
    local c = UI.CustomTable()[key]
    UI.CustomTable()[key] = nil
    if c then Note((c.title or key) .. ": button deleted, and its macro with it") end
    UI.CustomChanged()
end

-- what the Custom section shows; the Buttons page is built again when this changes
function UI.CustomStamp()
    local custom, keys, parts = UI.CustomTable(), {}, {}
    for k in pairs(custom) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local c, ids = custom[k], {}
        for _, t in ipairs(CustomThings(c)) do ids[#ids + 1] = t.kind:sub(1, 1) .. t.id end
        parts[#parts + 1] = k .. "=" .. tostring(c.title) .. ":" .. table.concat(ids, ",")
    end
    return table.concat(parts, ";")
end

-- the Buttons page (whose Custom section lists them), if shown
function UI.RefreshButtonsPage()
    for i, page in ipairs(PAGES) do
        local pn = UI.panels and UI.panels[i]
        if page.name == "Buttons" and pn and pn.frame:IsVisible() then UI.ShowPanel(i) end
    end
end

-- A slot to drag an item or spell onto (or click while carrying one): drop(kind,
-- id) gets it. size: the slot's size; tip: its tooltip lines (a default if nil).
function UI.DropSlot(parent, size, drop, tip)
    local b = UI.SampleButton(parent, size, "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    local plus = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    plus:SetPoint("CENTER")
    plus:SetText("+")
    local function take()
        local kind, id = UI.CursorThing()
        if not kind then return end
        ClearCursor()
        drop(kind, id)
    end
    b:SetScript("OnReceiveDrag", take)
    b:SetScript("OnClick", take)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local lines = tip or { "Drag an item from your bags or a spell from your spellbook here" }
        for i, line in ipairs(lines) do
            if i == 1 then GameTooltip:AddLine(Loc(line)) else GameTooltip:AddLine(Loc(line), 1, 0.82, 0, true) end
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

UI.CUSTOM_ICON, UI.CUSTOM_GAP = 36, 6

-- the + at the end of the Buttons page's icon row: its tooltip says how it all works
UI.NEW_BUTTON_TIP = {
    "New button",
    "Drag an item from your bags or a spell from your spellbook here to make your own button.",
    "Drag more items or spells onto its icon to add them.",
    "Rename it, reorder or take things out, or delete it under Custom at the bottom of this page.",
}

-- an item or spell dropped on your own button's icon in the icon row: add it
function UI.AddToIcon(b)
    local e = b and b.entry
    if not (e and e.custom) then return end
    local kind, id = UI.CursorThing()
    if not kind then return end
    ClearCursor()
    UI.CustomAdd(e.key, kind, id)
end

function UI.CustomEntry(key)
    for _, e in ipairs(ALL) do
        if e.custom and e.key == key and not e.removed then return e end
    end
end

-- Moving one: clicking an icon picks it (UI.customMoving = { key, i }), it is
-- shown checked; clicking another icon of the same button moves it there.
UI.customMoving = nil
function UI.MarkMoving(parent)
    local mv = UI.customMoving
    for _, ic in ipairs(parent.amCustomIcons or {}) do
        local on = mv ~= nil and mv.key == ic.key and mv.i == ic.i
        if ic.b.SetChecked then pcall(ic.b.SetChecked, ic.b, on) end
        if on and ic.b.LockHighlight then ic.b:LockHighlight() elseif ic.b.UnlockHighlight then ic.b:UnlockHighlight() end
    end
end

-- The Buttons page's Custom section: one row per button of your own: on/off,
-- its name (type to rename), its items and spells in order (hover for the
-- tooltip, click to move one, right-click to take it out), a slot to add more,
-- and Delete. x, y: where it starts; returns the y below it. refreshers: the
-- page's list (the on/off boxes).
function UI.BuildCustomRows(parent, width, x, y, refreshers)
    width = width or UI.CONTENT_W
    parent.amCustomIcons = {}
    UI.customMoving = nil   -- (a fresh page: nothing picked)
    local size, gap = UI.CUSTOM_ICON, UI.CUSTOM_GAP
    local custom = UI.CustomTable()
    local keys = {}
    for k in pairs(custom) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(custom[a].title):lower() < tostring(custom[b].title):lower() end)
    local iconsX = x + 186
    local perRow = math.max(1, math.floor((width - iconsX - 100 + gap) / (size + gap)))
    for _, key in ipairs(keys) do
        local c = custom[key]
        local cb = MakeToggle(parent, x, y - 6,
            function() local e = UI.CustomEntry(key); return e and Enabled(e) or false end,
            function(v) local e = UI.CustomEntry(key); if e then UI.SetEnabled(e, v) end end)
        if refreshers and cb.refresh then refreshers[#refreshers + 1] = cb.refresh end
        local box
        local okBox, made = pcall(CreateFrame, "EditBox", nil, parent, "InputBoxTemplate")
        if okBox and made then box = made else box = CreateFrame("EditBox", nil, parent) end
        box:SetSize(140, 22)
        box:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 36, y - 6)
        box:SetAutoFocus(false)
        box:SetMaxLetters(16)
        box:SetFontObject("GameFontHighlight")
        box:SetText(c.title or key)
        box:SetCursorPosition(0)
        box:SetScript("OnEnterPressed", function(self) self:ClearFocus(); UI.CustomRename(key, self:GetText()) end)
        box:SetScript("OnEscapePressed", function(self) self:SetText(c.title or key); self:ClearFocus() end)
        local slots = {}
        for _, t in ipairs(CustomThings(c)) do slots[#slots + 1] = t end
        slots[#slots + 1] = false   -- the slot to add more
        for i, t in ipairs(slots) do
            local b
            if t then
                local spell = t.kind == "spell"
                b = UI.SampleButton(parent, size, UI.ThingIcon(t.kind, t.id))
                b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                parent.amCustomIcons[#parent.amCustomIcons + 1] = { key = key, i = i, b = b }
                b:SetScript("OnClick", function(_, button)
                    local mv = UI.customMoving
                    if button == "RightButton" then
                        UI.customMoving = nil
                        UI.CustomRemove(key, i)
                    elseif mv and mv.key == key and mv.i ~= i then
                        UI.customMoving = nil
                        UI.CustomMove(key, mv.i, i)
                    elseif mv and mv.key == key then   -- (clicked again: put it back)
                        UI.customMoving = nil
                    else
                        UI.customMoving = { key = key, i = i }
                    end
                    UI.MarkMoving(parent)
                end)
                b:SetScript("OnEnter", function(self)
                    ShowEntryTooltip(self, t.id, nil, spell)
                    local mv = UI.customMoving
                    if mv and mv.key == key and mv.i ~= i then
                        GameTooltip:AddLine(Loc("Click to move the picked one here"), 0.25, 1, 0.25)
                    else
                        GameTooltip:AddLine(Loc("Click to move it, then click where it should go"), 0.7, 0.7, 0.7)
                    end
                    GameTooltip:AddLine(Loc("Right-click to take it out of this button"), 0.7, 0.7, 0.7)
                    GameTooltip:Show()
                end)
                b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else
                b = UI.DropSlot(parent, size, function(k, newID) UI.CustomAdd(key, k, newID) end,
                    { "Add to " .. tostring(c.title), "Drag an item from your bags or a spell from your spellbook here." })
            end
            local row, col = math.floor((i - 1) / perRow), (i - 1) % perRow
            BLIZZ_ART.Point(b, "TOPLEFT", parent, "TOPLEFT", iconsX + col * (size + gap), y - row * (size + gap))
        end
        box:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(Loc("Type a new name and press Enter"))
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function() GameTooltip:Hide() end)
        MakeButton(parent, width - 90, y - 6, 80, "Delete", function() UI.CustomDelete(key) end)
        local rows = math.ceil(#slots / perRow)
        y = y - rows * (size + gap) - 14
    end
    return y
end
