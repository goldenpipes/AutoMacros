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
    RefreshEUIPage(true)   -- (rows added or gone: built again)
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
    return key
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
-- id) gets it. size: the slot's size; tip: its tooltip lines (a default if nil);
-- empty: run when it is clicked with nothing on the cursor.
function UI.DropSlot(parent, size, drop, tip, empty)
    local b = UI.SampleButton(parent, size, "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    local plus = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    plus:SetPoint("CENTER")
    plus:SetText("+")
    local function take(_, button)
        local kind, id = UI.CursorThing()
        if not kind then
            -- (a click with an empty hand, not a drop of something we can't take)
            if empty and button and not GetCursorInfo() then empty() end
            return
        end
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
    "Click to pick items from your bags and spells you know to make your own button (or drag one here).",
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

-- EllesmereUI's look for one of our widgets (kind: a skin function, "Button",
-- "Checkbox", "EditBox", ...), when its skin is there; else nothing.
function UI.Skin(kind, frame, ...)
    if frame and skin and type(skin[kind]) == "function" then pcall(skin[kind], frame, ...) end
end

-- The Buttons page's Custom section: one row per button of your own: on/off,
-- its name (type to rename), its items and spells in order (hover for the
-- tooltip, click to move one, right-click to take it out), a slot to add more,
-- and Delete. x, y: where it starts; returns the y below it. refreshers: the
-- page's list (the on/off boxes). eui: on EllesmereUI's page (its look).
function UI.BuildCustomRows(parent, width, x, y, refreshers, eui)
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
        if eui then
            UI.Skin("Checkbox", cb)
            UI.Skin("EditBox", box, { padInput = true })
        end
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
                    { "Add to " .. tostring(c.title), "Click to pick from your bags and spells, or drag one here." },
                    function() UI.ShowDrop(key) end)
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
        local del = MakeButton(parent, width - 90, y - 6, 80, "Delete", function() UI.CustomDelete(key) end)
        if eui then UI.Skin("Button", del); UI.Skin("WhiteButtonLabel", del) end
        local rows = math.ceil(#slots / perRow)
        y = y - rows * (size + gap) - 14
    end
    return y
end

-- ---- the picker ----
-- The game's settings window keeps the bags and spellbook from opening while it
-- is up, so there is nothing to drag onto a +. Clicking a + with nothing on the
-- cursor opens this window over the settings instead: what the button holds so
-- far, a + that still takes drops, and (in two tabs) every item in your bags and
-- every spell you can cast, to click. UI.dropKey is the button they go to (nil =
-- a new one: the first pick makes it, later ones add to it).

UI.DROP_W, UI.PICK_ICON, UI.PICK_ROWS = 380, 32, 5
UI.dropKey, UI.pickTab = nil, "items"

-- every item in your bags (and worn), A-Z
function UI.BagThings()
    local list = {}
    for id in pairs(ScanBags()) do list[#list + 1] = { kind = "item", id = id, name = ItemRef(id) } end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

-- every spell in your spellbook you can cast (no passives), in the book's order;
-- of a spell with ranks only the highest (it comes last in the book)
function UI.BookSpells()
    local list, at = {}, {}
    local function add(id)
        id = tonumber(id)
        if not id then return end
        local name = SpellName(id) or ("Spell " .. id)
        if at[name] then list[at[name]].id = id; return end
        list[#list + 1] = { kind = "spell", id = id }
        at[name] = #list
    end
    local SB = C_SpellBook
    if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemInfo then
        -- retail
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
        for i = 1, SB.GetNumSpellBookSkillLines() or 0 do
            local okLine, line = pcall(SB.GetSpellBookSkillLineInfo, i)
            if okLine and line and not line.shouldHide then
                local first = line.itemIndexOffset or 0
                for slot = first + 1, first + (line.numSpellBookItems or 0) do
                    local ok, info = pcall(SB.GetSpellBookItemInfo, slot, bank)
                    if ok and info and info.spellID and not info.isPassive and not info.isOffSpec
                        and (spellType == nil or info.itemType == spellType) then
                        add(info.spellID)
                    end
                end
            end
        end
        return list
    end
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
        local book = BOOKTYPE_SPELL or "spell"
        for t = 1, GetNumSpellTabs() or 0 do
            local _, _, offset, n = GetSpellTabInfo(t)
            offset = offset or 0
            for slot = offset + 1, offset + (n or 0) do
                local ok, kind, id = pcall(GetSpellBookItemInfo, slot, book)
                local passive = false
                if IsPassiveSpell then
                    local okP, p = pcall(IsPassiveSpell, slot, book)
                    passive = okP and p
                end
                if ok and kind == "SPELL" and not passive then add(id) end
            end
        end
    end
    return list
end

-- something picked or dropped
function UI.DropTake(kind, id)
    if UI.dropKey and UI.CustomTable()[UI.dropKey] then
        UI.CustomAdd(UI.dropKey, kind, id)
    else
        UI.dropKey = UI.CustomCreate(kind, id)
    end
    UI.RefreshDrop()
end

function UI.DropFrame()
    if UI.dropFrame then return UI.dropFrame end
    -- (named, so Escape can close it: UISpecialFrames holds names)
    local ok, f = pcall(CreateFrame, "Frame", "AutoMacrosDrop", UIParent, "BasicFrameTemplateWithInset")
    if not ok or not f then
        f = CreateFrame("Frame", "AutoMacrosDrop", UIParent)
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.05, 0.92)
        local close = Template("Button", f, "UIPanelCloseButton")
        if close then close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0) end
    end
    f:SetSize(UI.DROP_W, 300)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    -- above the game's settings window
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "AutoMacrosDrop") end
    -- closes with the settings window it was opened from (UI.dropHost, see
    -- UI.ShowDrop); checked now and then rather than hooking that window
    local since = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        since = since + (elapsed or 0)
        if since < 0.25 then return end
        since = 0
        local host = UI.dropHost
        if host and not host:IsVisible() then self:Hide() end
    end)
    f.title = f.TitleText or (f.TitleContainer and f.TitleContainer.TitleText)
    if not f.title then
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", f, "TOP", 0, -8)
    end
    f.note = UI.SmallText(f, "Click an item or spell below to add it, or drag one onto the +."
        .. " Right-click one at the top to take it out again.")
    f.note:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -34)
    f.note:SetWidth(UI.DROP_W - 32)
    f.note:SetJustifyH("LEFT")
    f.icons = {}
    f.slot = UI.DropSlot(f, UI.CUSTOM_ICON, UI.DropTake,
        { "Drop here", "Drag an item or a spell here." })
    f.tabItems = MakeButton(f, 16, 0, 90, "Bags", function() UI.pickTab = "items"; UI.RefreshDrop() end)
    f.tabSpells = MakeButton(f, 112, 0, 90, "Spells", function() UI.pickTab = "spells"; UI.RefreshDrop() end)
    -- the list to pick from, scrolling
    local okS, sf = pcall(CreateFrame, "ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    local templated = okS and sf
    if not templated then
        sf = CreateFrame("ScrollFrame", nil, f)
        sf:EnableMouseWheel(true)
        sf:SetScript("OnMouseWheel", function(self, delta)
            local v = self:GetVerticalScroll() - delta * 36
            self:SetVerticalScroll(math.max(0, math.min(v, self:GetVerticalScrollRange())))
        end)
    end
    sf:SetSize(UI.DROP_W - 32 - 22, UI.PICK_ROWS * (UI.PICK_ICON + 4) - 4)   -- (room for the scroll bar)
    local bg = sf:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", sf, "TOPLEFT", -4, 4)
    bg:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 4, -4)
    bg:SetColorTexture(0, 0, 0, 0.35)
    f.list = CreateFrame("Frame", nil, sf)
    f.list:SetSize(sf:GetWidth(), sf:GetHeight())
    sf:SetScrollChild(f.list)
    f.scroll = sf
    f.picks = {}
    f.empty = f.list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.empty:SetPoint("TOPLEFT", f.list, "TOPLEFT", 4, -4)
    f.done = MakeButton(f, UI.DROP_W - 16 - 90, 0, 90, "Done", function() f:Hide() end)
    -- with EllesmereUI's styling on: its window, buttons and scroll bar
    if SkinActive() then
        f.skinned = true
        UI.Skin("Shell", f)
        UI.Skin("Inset", f.Inset)
        UI.Skin("CloseButton", f.CloseButton)
        UI.Skin("ScrollBar", sf.ScrollBar)
        for _, b in ipairs({ f.tabItems, f.tabSpells, f.done }) do UI.Skin("Button", b) end
        UI.Skin("WhiteButtonLabel", f.done)
        UI.Skin("Font", f.title)
        UI.Skin("Font", f.note)
    end
    UI.dropFrame = f
    return f
end

-- the tab shown: highlighted, or in EllesmereUI's accent color when skinned
function UI.MarkPickTabs(f)
    local on = UI.pickTab == "spells" and f.tabSpells or f.tabItems
    local off = on == f.tabSpells and f.tabItems or f.tabSpells
    if f.skinned then
        local r, g, b = AccentRGB()
        local fs = on:GetFontString()
        if fs then fs:SetTextColor(r, g, b) end
        fs = off:GetFontString()
        if fs then fs:SetTextColor(1, 1, 1) end
    else
        on:LockHighlight()
        off:UnlockHighlight()
    end
end

-- one icon in the list: click adds it
function UI.PickIcon(f, i)
    local b = f.picks[i]
    if b then return b end
    b = UI.SampleButton(f.list, UI.PICK_ICON)
    b:SetScript("OnClick", function(self) UI.DropTake(self.t.kind, self.t.id) end)
    b:SetScript("OnEnter", function(self)
        ShowEntryTooltip(self, self.t.id, nil, self.t.kind == "spell")
        if self.added then
            GameTooltip:AddLine(Loc("Already on this button"), 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(Loc("Click to add it"), 0.25, 1, 0.25)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.picks[i] = b
    return b
end

-- moves a button made with MakeButton down to y
function UI.DropRow(b, y)
    local p, rel, rp, x = b:GetPoint(1)
    b:SetPoint(p, rel, rp, x, -y)
end

-- the title, the button's things so far and the +, the tabs, the list, Done
function UI.RefreshDrop()
    local f = UI.dropFrame
    if not (f and f:IsShown()) then return end
    local c = UI.dropKey and UI.CustomTable()[UI.dropKey]
    if not c then UI.dropKey = nil end
    f.title:SetText(c and Loc("Add to") .. " " .. tostring(c.title) or Loc("New button"))

    -- what it holds, then the +
    local size, gap = UI.CUSTOM_ICON, UI.CUSTOM_GAP
    local perRow = math.max(1, math.floor((UI.DROP_W - 32 + gap) / (size + gap)))
    local y = 34 + math.ceil(f.note:GetStringHeight() or 24) + 10
    local list = c and CustomThings(c) or {}
    local added = {}
    local function place(b, i)
        local row, col = math.floor((i - 1) / perRow), (i - 1) % perRow
        BLIZZ_ART.Point(b, "TOPLEFT", f, "TOPLEFT", 16 + col * (size + gap), -y - row * (size + gap))
    end
    for i, t in ipairs(list) do
        added[t.kind .. t.id] = true
        local b = f.icons[i]
        if not b then
            b = UI.SampleButton(f, size)
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:SetScript("OnClick", function(self, button)
                if button == "RightButton" and UI.dropKey then UI.CustomRemove(UI.dropKey, self.i); UI.RefreshDrop() end
            end)
            b:SetScript("OnEnter", function(self)
                ShowEntryTooltip(self, self.t.id, nil, self.t.kind == "spell")
                GameTooltip:AddLine(Loc("Right-click to take it out of this button"), 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            f.icons[i] = b
        end
        b.i, b.t = i, t
        b.icon:SetTexture(UI.ThingIcon(t.kind, t.id) or QUESTION_MARK)
        place(b, i)
        b:Show()
    end
    for i = #list + 1, #f.icons do f.icons[i]:Hide() end
    place(f.slot, #list + 1)
    y = y + math.ceil((#list + 1) / perRow) * (size + gap) + 4

    -- the tabs
    UI.DropRow(f.tabItems, y)
    UI.DropRow(f.tabSpells, y)
    local spells = UI.pickTab == "spells"
    UI.MarkPickTabs(f)
    y = y + 22 + 10

    -- the list
    f.scroll:ClearAllPoints()
    f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -y)
    local things = spells and UI.BookSpells() or UI.BagThings()
    local ps, pg = UI.PICK_ICON, 4
    local cols = math.max(1, math.floor((f.scroll:GetWidth() + pg) / (ps + pg)))
    for i, t in ipairs(things) do
        local b = UI.PickIcon(f, i)
        b.t = t
        b.added = added[t.kind .. t.id] or false
        b.icon:SetTexture(UI.ThingIcon(t.kind, t.id) or QUESTION_MARK)
        pcall(b.icon.SetDesaturated, b.icon, b.added)
        b:SetAlpha(b.added and 0.5 or 1)
        local row, col = math.floor((i - 1) / cols), (i - 1) % cols
        BLIZZ_ART.Point(b, "TOPLEFT", f.list, "TOPLEFT", col * (ps + pg), -row * (ps + pg))
        b:Show()
    end
    for i = #things + 1, #f.picks do f.picks[i]:Hide() end
    f.empty:SetText(#things == 0 and Loc(spells and "No spells to show." or "Nothing in your bags.") or "")
    f.list:SetHeight(math.max(f.scroll:GetHeight(), math.ceil(#things / cols) * (ps + pg)))
    y = y + f.scroll:GetHeight() + 12

    UI.DropRow(f.done, y)
    f:SetHeight(y + 22 + 14)
end

-- key: the button to add to (nil = a new one)
function UI.ShowDrop(key)
    UI.dropKey = key
    -- the settings window it opens from: Blizzard's, or EllesmereUI's
    UI.dropHost = nil
    for _, win in ipairs({ SettingsPanel, InterfaceOptionsFrame, EllesmereUIFrame }) do
        if win and win.IsVisible and win:IsVisible() then UI.dropHost = win end
    end
    local f = UI.DropFrame()
    f:Show()
    f:Raise()
    UI.RefreshDrop()
end
