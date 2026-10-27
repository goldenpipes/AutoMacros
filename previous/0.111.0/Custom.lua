-- AutoMacros: your own buttons (db.custom), made on the Buttons settings page
-- by dragging items from your bags or spells from your spellbook onto the +
-- at the end of its icon row; edited in its Custom section.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- Saved as db.custom[key] = { title = "...", kind = "items" | "spells",
-- ids = { ... }, oldNames = { ... } }: key is made from the first name (letters
-- and digits), title is the macro's name (16 characters at most), oldNames the
-- names it had before a rename, so its macro is found and renamed rather than
-- made again (see CustomEntries).

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
    if kind == "spells" then return SpellName(id) or ("Spell " .. id) end
    return ItemRef(id)
end

function UI.ThingIcon(kind, id)
    if kind == "spells" then return SpellIcon(id) end
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

-- a new button with one item or spell in it, named after it
function UI.CustomCreate(kind, id)
    local title = UI.ThingName(kind, id):sub(1, 16)
    local key = UI.CustomKey(title)
    UI.CustomTable()[key] = { title = title, kind = kind, ids = { id } }
    OnOff()[key] = true
    Note("new button " .. title .. " - drag more onto its icon in the AutoMacros settings")
    UI.CustomChanged()
end

function UI.CustomAdd(key, kind, id)
    local c = UI.CustomTable()[key]
    if not c then return end
    if c.kind ~= kind then
        Print(c.title .. " holds " .. (c.kind == "spells" and "spells" or "items") .. " only - make a new button for "
            .. (kind == "spells" and "spells" or "items"))
        return
    end
    for _, have in ipairs(c.ids) do
        if have == id then return end
    end
    c.ids[#c.ids + 1] = id
    UI.CustomChanged()
end

-- takes one out; taking the last one out deletes the button
function UI.CustomRemove(key, id)
    local c = UI.CustomTable()[key]
    if not c then return end
    for i, have in ipairs(c.ids) do
        if have == id then table.remove(c.ids, i) break end
    end
    if #c.ids == 0 then return UI.CustomDelete(key) end
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
        local c = custom[k]
        parts[#parts + 1] = k .. "=" .. tostring(c.title) .. ":" .. table.concat(c.ids or {}, ",")
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
    "Drag more onto its icon to add them. A button holds items or spells, not both.",
    "Rename it, take things out or delete it under Custom at the bottom of this page.",
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

-- The Buttons page's Custom section: one row per button of your own: on/off,
-- its name (type to rename), its items or spells (hover for the tooltip,
-- right-click to take one out), a slot to add more, and Delete. x, y: where it
-- starts; returns the y below it. refreshers: the page's list (the on/off boxes).
function UI.BuildCustomRows(parent, width, x, y, refreshers)
    width = width or UI.CONTENT_W
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
        local kind = c.kind == "spells" and "spells" or "items"
        local slots = {}
        for _, id in ipairs(c.ids or {}) do slots[#slots + 1] = id end
        slots[#slots + 1] = false   -- the slot to add more
        for i, id in ipairs(slots) do
            local b
            if id then
                b = UI.SampleButton(parent, size, UI.ThingIcon(kind, id))
                b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                b:SetScript("OnClick", function(_, button)
                    if button == "RightButton" then UI.CustomRemove(key, id) end
                end)
                b:SetScript("OnEnter", function(self)
                    ShowEntryTooltip(self, id, nil, kind == "spells")
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
