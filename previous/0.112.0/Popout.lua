-- AutoMacros: The popout: its items, opening it over a button, its indicator,
-- hidden macro names.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---------------------------------------------------------------------------
-- Flyout: hover a button whose category has two or more usable items in your
-- bags and a popup of those items appears above it, each with the game's own
-- item tooltip. Click an item to make it the macro's default (picking the best
-- item goes back to automatic). A small gold tab on the button shows that a popup
-- is available. Choosing rewrites the macro, so in combat the change is applied
-- when combat ends.
-- ---------------------------------------------------------------------------
MAX_ENTRIES = 10
arrows = {}      -- action button -> tab
entries = {}     -- pooled item buttons in the popup
hooked = {}      -- action buttons we have hooked OnEnter/OnLeave on
-- (flyout: the shared popup frame)

function CountOf(id)
    local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not fn then return nil end
    local ok, n = pcall(fn, id)
    return ok and tonumber(n) or nil
end

function ChooseItem(m, id)
    Picks()[m.name] = id          -- nil goes back to automatic
    if InCombatLockdown() then
        Note(m.title .. ": will change when combat ends")
    end
    Update()                      -- in combat this only queues the macro rewrite
end

-- The popup stays open while the mouse is over the button, its tab or the popup.
-- This is tracked from enter/leave events rather than by asking where the mouse
-- is, so it does not depend on the client being able to answer that.
function AnyOver()
    if not flyout or not flyout.over then return false end
    for _, on in pairs(flyout.over) do
        if on then return true end
    end
    return false
end

function SetOver(frame, on)
    if frame and flyout and flyout.over then flyout.over[frame] = on or nil end
end
-- The game's own tooltip for an entry in the popup. A spell: by its ID, then
-- its link. An item, tried in order: its real bag slot (exactly what the bag
-- shows), then by item ID, then by link.
function ShowEntryTooltip(owner, id, loc, isSpell)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local function filled()
        return GameTooltip.NumLines and GameTooltip:NumLines() > 0
    end
    if isSpell then
        if GameTooltip.SetSpellByID then pcall(GameTooltip.SetSpellByID, GameTooltip, id) end
        if not filled() then pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. id) end
        if not filled() then GameTooltip:AddLine(SpellName(id) or ("spell " .. id)) end
        GameTooltip:Show()
        return
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
    local _, _, link = ItemInfo(id)
    if type(link) == "string" then pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
    if not filled() then pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. id) end
    if not filled() then GameTooltip:AddLine(ItemRef(id)) end
    GameTooltip:Show()
end

function BuildFlyout()
    if flyout then return flyout end
    flyout = CreateFrame("Frame", "AutoMacrosFlyout", UIParent)
    flyout.over = {}
    flyout:SetFrameStrata("DIALOG")
    flyout:SetClampedToScreen(true)
    if flyout.EnableMouse then flyout:EnableMouse(true) end
    StyleFlyout(flyout)
    flyout:SetScript("OnEnter", function(self) SetOver(self, true) end)
    flyout:SetScript("OnLeave", function(self) SetOver(self, false) end)    flyout:SetScript("OnUpdate", function(self, elapsed)
        if AnyOver() then
            self.idle = 0
        else
            self.idle = (self.idle or 0) + elapsed
            if self.idle > Style("closeDelay") then self:Hide() end
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

-- An item button for a popup (the real one, or the settings demo): icon, the
-- action button art and a stack count. StyleEntry dresses it.
-- Made from Blizzard's own ActionButtonTemplate where the client has it, so it
-- is the game's action button (see BLIZZ_ART.Size); a plain button otherwise.
function ItemButton(parent)
    local ok, e = pcall(CreateFrame, "CheckButton", nil, parent, "ActionButtonTemplate")
    if ok and e and (e.icon or e.Icon) then
        e.icon = e.icon or e.Icon
        local w = e:GetWidth()
        e.native = (type(w) == "number" and w > 0) and w or 36
        BLIZZ_ART.native = BLIZZ_ART.native or e.native   -- a stock button's size (Item size 100%)
        e.masked = e.IconMask and true or nil   -- the template masks its icon itself
        e.count = e.Count
        -- clicking a checkbutton flips its checked look; only "selected" sets it
        e:SetScript("PostClick", function(self) self:SetChecked(self.amChecked or false) end)
    else
        e = CreateFrame("Button", nil, parent)
        e.icon = e:CreateTexture(nil, "ARTWORK")
        e.icon:SetAllPoints()
    end
    ButtonArt(e)
    if not e.count then
        local okFs, fs = pcall(e.CreateFontString, e, nil, "OVERLAY", "NumberFontNormal")
        if not okFs or not fs then fs = e:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") end
        fs:SetPoint("BOTTOMRIGHT", -3, 3)
        e.count = fs
    end
    return e
end

function Entry(i)
    local e = entries[i]
    if e then return e end
    e = ItemButton(flyout)
    e:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    e:SetScript("OnClick", function(self)
        local m = flyout.macro
        if not m then return end
        -- the best item is what "automatic" already uses, so picking it clears the choice
        -- gear that is not worn yet is put on, so the button can show its cooldown
        if self.unequipped then
            if InCombatLockdown() then
                Print(ItemRef(self.itemID) .. ": cannot be equipped in combat")
            elseif not EquipByID(self.itemID) then
                Print(ItemRef(self.itemID) .. ": could not be equipped")
            end
        end
        local list = flyoutItems[m.name]
        local automatic = list and list[1] and (list[1].pick or list[1].id) == self.pick
        ChooseItem(m, (not automatic) and self.pick or nil)
        flyout:Hide()
    end)
    e:SetScript("OnEnter", function(self)
        SetOver(self, true)
        ShowEntryTooltip(self, self.itemID, self.loc, self.kind == "spell")
        if self.unequipped then
            GameTooltip:AddLine("Not equipped - click to put it on", 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    e:SetScript("OnLeave", function(self)
        SetOver(self, false)
        GameTooltip:Hide()
    end)
    StyleEntry(e)
    entries[i] = e
    return e
end

-- Sizes and places the item buttons in popout f (default: the real one) from
-- the saved style, all on whole screen pixels so spacing and borders come out
-- even: item spacing and the popout border are pixels, the first (best) item is
-- nearest the button. dir (up, down, left, right; default the real popout's
-- f.dir, else up) is the way it opens: a column for up and down, a row for
-- left and right. With button, the popout is also put centred on that side of
-- it, just past its indicator (arrow). The settings demo uses this too.
function LayoutFlyout(f, list, n, button, arrow, dir)
    f = f or flyout
    if not f then return end
    list = list or entries
    n = n or f.count or 0
    dir = dir or f.dir or "up"
    local across = dir == "left" or dir == "right"
    local reverse = dir == "down" or dir == "left"   -- counted from the far end, so item 1 is nearest
    local px = PixelSize(f)
    local size = BLIZZ_ART.ItemSize(f)
    -- With the background on, the items sit as on the main bar: its gap between
    -- buttons, touching the popout's edge with the art reaching out past them
    -- (StyleFlyout). Without, Item spacing between and around them.
    local art = BLIZZ_ART.PopupArt()
    local gap = art and Snap(f, BLIZZ_ART.BarGap(f) * BLIZZ_ART.ArtScale(f)) or Style("entrySpacing") * px
    local pad = art and 0 or gap
    for i = 1, n do   -- (StyleEntry has sized them)
        local e = list[i]
        if e then
            local at = pad + (reverse and (n - i) or (i - 1)) * (size + gap)
            if across then
                BLIZZ_ART.Point(e, "BOTTOMLEFT", f, "BOTTOMLEFT", at, pad)
            else
                BLIZZ_ART.Point(e, "BOTTOMLEFT", f, "BOTTOMLEFT", pad, at)
            end
        end
    end
    local long, short = 2 * pad + n * (size + gap) - gap, size + 2 * pad
    if across then f:SetSize(long, short) else f:SetSize(short, long) end
    BLIZZ_ART.Dividers(f, art, n, size, gap, pad, across)
    button = button or (f == flyout and f.button)
    if not button then return end
    arrow = arrow or arrows[button]
    local ratio = button:GetEffectiveScale() / f:GetEffectiveScale()
    local away = 0   -- how far from the button
    if arrow and arrow:IsShown() then   -- the indicator overlaps the button by 3px (StyleArrow)
        away = math.max(0, BLIZZ_ART.TabHeight() - 3) * px
    end
    if art then   -- clear of the art on the side facing the button too
        local l, t, r, b = BLIZZ_ART.BarInsets(f)
        local facing = ({ up = b, down = t, right = l, left = r })[dir]
        away = away + Snap(f, facing * BLIZZ_ART.ArtScale(f))
    end
    f:ClearAllPoints()
    if across then
        local y = Snap(f, (button:GetHeight() * ratio - f:GetHeight()) / 2)
        if dir == "right" then
            f:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", away, y)
        else
            f:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", -away, y)
        end
    else
        local x = Snap(f, (button:GetWidth() * ratio - f:GetWidth()) / 2)
        if dir == "down" then
            f:SetPoint("TOPLEFT", button, "BOTTOMLEFT", x, -away)
        else
            f:SetPoint("BOTTOMLEFT", button, "TOPLEFT", x, away)
        end
    end
end

-- button is the action button to open over. source is the frame the mouse is
-- on. toggle closes the popup if it is already open for this button (clicking the tab).
function OpenFlyout(button, m, source, toggle)
    local list = flyoutItems[m.name]
    if not button or not list or #list < 2 then return end
    BuildFlyout()
    if flyout:IsShown() and flyout.button == button and flyout.macro == m then
        if toggle then flyout:Hide() else SetOver(source, true) end
        return
    end
    flyout.macro, flyout.button = m, button
    flyout.dir = POPOUT.Direction(button, m)
    flyout.over = {}
    SetOver(source, true)
    local _, chosenEntry = Chosen(m, list)
    local chosen = chosenEntry and (chosenEntry.pick or chosenEntry.id)
    local n = math.min(#list, MAX_ENTRIES)
    for i = 1, n do
        local e = Entry(i)
        local isSpell = m.kind == "spells" or list[i].spell == true   -- the Hearth/Teleport button has both
        e.kind = isSpell and "spell" or "item"
        e.itemID = list[i].id
        e.pick = list[i].pick or list[i].id
        e.loc = (not isSpell) and lastLocs[list[i].id] or nil
        e.icon:SetTexture(isSpell and SpellIcon(list[i].id) or IconFor({ item = list[i].id }))
        e.unequipped = (not isSpell) and NeedsEquip(list[i].id)   -- grey until worn
        pcall(e.icon.SetDesaturated, e.icon, e.unequipped and true or false)
        local count = (not isSpell) and CountOf(list[i].id) or nil
        e.count:SetText((count and count > 1) and tostring(count) or "")
        e.selected = (e.pick == chosen)                   -- highlighted border: the one in use
        StyleEntry(e)
        e:Show()
    end
    for i = n + 1, #entries do entries[i]:Hide() end
    flyout.count = n
    LayoutFlyout()   -- also places it over the button
    flyout.idle = 0
    flyout:Show()
end

function SafeOpen(...)
    local ok, err = pcall(OpenFlyout, ...)
    if not ok then Print("popout error: " .. tostring(err)) end
end

-- The macro on an action button, if it is one of ours: found by the macro's
-- name, checked against the macros we keep. The number GetActionInfo gives for
-- a macro is not always its place in the macro list (retail gives another
-- number, an item's when #showtooltip shows one), so that is only used when the
-- client gives no name.
MacroOnButton = function(b)
    local ok, slot = pcall(ButtonSlot, b)
    if not (ok and slot) then return nil end
    local kind, id = GetActionInfo(slot)
    if kind ~= "macro" then return nil end
    local text = GetActionText and GetActionText(slot)
    if type(text) == "string" and text ~= "" then
        for idx, mm in pairs(macroAt) do
            if GetMacroInfo(idx) == text then return mm end
        end
        return nil
    end
    return macroAt[id]
end

function OnButtonEnter(b)
    if DB().noFlyout then return end
    local m = MacroOnButton(b)
    if not m then return end
    local list = flyoutItems[m.name]
    if list and #list >= 2 then SafeOpen(b, m, b) end
end

function OnButtonLeave(b)
    SetOver(b, false)
end

function HookButton(b)
    if hooked[b] then return end
    hooked[b] = true
    pcall(b.HookScript, b, "OnEnter", OnButtonEnter)
    pcall(b.HookScript, b, "OnLeave", OnButtonLeave)
end

function ArrowFor(button)
    local a = arrows[button]
    if a then return a end
    local ok, frame = pcall(CreateFrame, "Button", nil, button)
    if not ok or not frame then return nil end
    a = frame
    a.button = button
    a:SetFrameLevel((button:GetFrameLevel() or 1) + 12)
    a.tex = a:CreateTexture(nil, "OVERLAY")
    a.tex:SetAllPoints()
    StyleArrow(a)
    a:RegisterForClicks("LeftButtonUp")
    a:SetScript("OnClick", function(self)
        if self.macro then SafeOpen(self.button, self.macro, self, true) end
    end)
    a:SetScript("OnEnter", function(self)
        if self.macro and not DB().noFlyout then SafeOpen(self.button, self.macro, self) end
    end)
    a:SetScript("OnLeave", function(self) SetOver(self, false) end)
    a:Hide()
    arrows[button] = a
    return a
end

-- The macro name drawn on a button is a text on the button, so it can be hidden
-- there without touching the macro. Only buttons holding one of our macros are
-- touched, and their label is restored if the macro is moved off them.
hiddenLabel = {}   -- action button -> its label, while we are hiding it

function LabelOf(b)
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

function ApplyLabel(b, mine)
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
        -- on a bar you can see (popouts on or off): the settings mark buttons that are on none
        if mine and b:IsVisible() then report.onBar[mine.name] = (report.onBar[mine.name] or 0) + 1 end
        local list = m and flyoutItems[m.name]
        if list and #list >= 2 then
            local a = ArrowFor(b)
            if a then
                a.macro = m
                local dir = POPOUT.Direction(b, m)
                if dir ~= a.dir then
                    a.dir = dir
                    StyleArrow(a)   -- onto the side it opens from
                end
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

-- ---------------------------------------------------------------------------
-- Look and feel, and the options window. ApplyStyle redraws everything that
-- has been built (highlights, tabs, popup) after a setting changes.
-- ---------------------------------------------------------------------------
-- (StyleOptions: defined below)

ApplyStyle = function()
    for button, g in pairs(glows) do StyleGlow(g, button) end
    for _, a in pairs(arrows) do StyleArrow(a) end
    if flyout then
        StyleFlyout(flyout)
        for _, e in ipairs(entries) do StyleEntry(e) end
        LayoutFlyout()
    end
    if StyleOptions then StyleOptions() end
end

function Refresh()
    pcall(SafeCollect)
    Update()
end
