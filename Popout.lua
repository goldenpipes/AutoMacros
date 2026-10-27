-- AutoMacros: The popout: its items, opening it over a button, its indicator,
-- hidden macro names.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---------------------------------------------------------------------------
-- Flyout: hover a button whose category has two or more usable items in your
-- bags and a popup of those items appears beside it, each with the game's own
-- item tooltip. Clicking an item uses it and/or makes it the macro's default
-- (Popout page, "Clicking an item"; picking the best item goes back to
-- automatic). A small tab on the button shows that a popup is available.
-- Choosing rewrites the macro, so in combat the change is applied when combat
-- ends.
--
-- The items are secure buttons, so a click can use an item or cast a spell.
-- The game lets no addon code show, move or size a secure frame in combat, so
-- the popout is opened by a snippet the game runs itself (wrapped round each
-- action button's OnEnter, see WrapButton): everything it needs (which items,
-- where they go, the popout's size and place) is handed to it beforehand, out
-- of combat (PrepareSecure). Our own code only draws on it: icons, counts,
-- the chosen border (OpenFlyout). In combat it shows what it held when combat
-- began; it closes by itself when the mouse leaves (RegisterAutoHide).
-- ---------------------------------------------------------------------------
MAX_ENTRIES = 10
arrows = {}      -- action button -> tab
entries = {}     -- the popout's item buttons (secure; made once, see BuildFlyout)
hooked = {}      -- action buttons we have hooked OnEnter on
wrapped = {}     -- action button -> its number in the secure data (WrapButton)
wrappedList = {} -- that number -> action button
prepared = {}    -- that number -> what its popout holds: { m, list, n, dir, plan }
-- (flyout: the shared popup frame; secureHeader: the secure frame the snippets
-- keep their data on, as attributes; secureStale: data to hand over after combat)

-- What clicking an item in the popout does: "useset" use it and make it the
-- button's item, "set" only make it the button's item, "use" only use it.
POPOUT_CLICKS = { { key = "useset", label = "Use and set" }, { key = "set", label = "Set only" },
    { key = "use", label = "Use only" } }
function PopoutClick()
    local v = DB().popoutClick
    if v == "set" or v == "use" then return v end
    return "useset"
end

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

-- The popout, its secure header and its item buttons, made once (out of
-- combat: secure frames cannot be made in it). The popout is a secure frame
-- too, so the snippets may show and place it; it closes when the mouse leaves
-- (the snippet's RegisterAutoHide), or out of combat on a click elsewhere.
-- (Not in UISpecialFrames: Escape hiding a secure frame in combat is blocked.)
function BuildFlyout()
    if flyout then return flyout end
    local ok, f = pcall(CreateFrame, "Frame", "AutoMacrosFlyout", UIParent, "SecureHandlerBaseTemplate")
    if not ok or not f then f = CreateFrame("Frame", "AutoMacrosFlyout", UIParent) end
    flyout = f
    flyout:SetFrameStrata("DIALOG")
    flyout:SetClampedToScreen(true)
    if flyout.EnableMouse then flyout:EnableMouse(true) end
    flyout:SetSize(1, 1)
    StyleFlyout(flyout)
    flyout:SetScript("OnEvent", function(self)
        if self:IsShown() and not InCombatLockdown() and not self:IsMouseOver()
            and not (self.button and self.button:IsMouseOver()) then
            self:Hide()
        end
    end)
    pcall(flyout.RegisterEvent, flyout, "GLOBAL_MOUSE_DOWN")
    flyout:Hide()
    local okH, h = pcall(CreateFrame, "Frame", "AutoMacrosSecure", UIParent, "SecureHandlerBaseTemplate")
    secureHeader = (okH and h and h.SetFrameRef) and h or nil
    if secureHeader then secureHeader:SetFrameRef("flyout", flyout) end
    for i = 1, MAX_ENTRIES do Entry(i) end
    return flyout
end

-- An item button for a popup (the real one, or the settings demo): icon, the
-- action button art and a stack count. StyleEntry dresses it.
-- Made from Blizzard's own ActionButtonTemplate where the client has it, so it
-- is the game's action button (see BLIZZ_ART.Size); a plain button otherwise.
-- secure: also a SecureActionButton, so clicking it can use an item or cast
-- (the real popout's items).
function ItemButton(parent, secure)
    local tpl = secure and "ActionButtonTemplate, SecureActionButtonTemplate" or "ActionButtonTemplate"
    local ok, e = pcall(CreateFrame, "CheckButton", nil, parent, tpl)
    if ok and e and (e.icon or e.Icon) then
        e.icon = e.icon or e.Icon
        local w = e:GetWidth()
        e.native = (type(w) == "number" and w > 0) and w or 36
        BLIZZ_ART.native = BLIZZ_ART.native or e.native   -- a stock button's size (Item size 100%)
        e.masked = e.IconMask and true or nil   -- the template masks its icon itself
        e.count = e.Count
        -- clicking a checkbutton flips its checked look; only "selected" sets it
        e:SetScript("PostClick", function(self) pcall(self.SetChecked, self, self.amChecked or false) end)
    else
        local okB, b = pcall(CreateFrame, "Button", nil, parent, secure and "SecureActionButtonTemplate" or nil)
        e = (okB and b) or CreateFrame("Button", nil, parent)
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

-- What a click on each kind of item says in its tooltip
POPOUT_CLICK_TIPS = {
    useset = "Click to use it and make it this button's item",
    set = "Click to make it this button's item",
    use = "Click to use it",
}

-- Item i of the popout: a secure button. Its type / item / spell attributes are
-- set by the opening snippet (so in "Set only" a click uses nothing); the game
-- uses it on the click, then the wrapped OnClick's post snippet closes the
-- popout and PostClick (our code) makes it the button's item when asked to.
-- Clicks act on release (useOnKeyDown false), whatever ActionButtonUseKeyDown says.
function Entry(i)
    local e = entries[i]
    if e then return e end
    e = ItemButton(flyout, true)
    e:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pcall(e.SetAttribute, e, "useOnKeyDown", false)
    e:SetScript("PostClick", function(self)
        pcall(self.SetChecked, self, self.amChecked or false)
        local m = flyout.macro
        if not m then return end
        -- gear that is not worn yet is put on (not used), so the button can show its cooldown
        if self.unequipped then
            if InCombatLockdown() then
                Print(ItemRef(self.itemID) .. ": cannot be equipped in combat")
            elseif not EquipByID(self.itemID) then
                Print(ItemRef(self.itemID) .. ": could not be equipped")
            end
        elseif PopoutClick() == "use" then
            return
        end
        -- the best item is what "automatic" already uses, so picking it clears the choice
        local p = flyout.button and prepared[wrapped[flyout.button] or 0]
        local list = p and p.list or flyoutItems[m.name]
        local automatic = list and list[1] and (list[1].pick or list[1].id) == self.pick
        ChooseItem(m, (not automatic) and self.pick or nil)
        if not secureHeader and not InCombatLockdown() then flyout:Hide() end
    end)
    e:SetScript("OnEnter", function(self)
        ShowEntryTooltip(self, self.itemID, self.loc, self.kind == "spell")
        if self.unequipped then
            GameTooltip:AddLine("Not equipped - click to put it on", 1, 0.82, 0)
        else
            GameTooltip:AddLine(POPOUT_CLICK_TIPS[PopoutClick()], 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    e:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if secureHeader then
        secureHeader:SetFrameRef("e" .. i, e)
        -- (the pre snippet passes a message, so the post snippet runs: it closes the popout)
        pcall(SecureHandlerWrapScript, e, "OnClick", secureHeader, [[return nil, true]],
            [[owner:GetFrameRef("flyout"):Hide()]])
    end
    StyleEntry(e)
    e:Hide()
    entries[i] = e
    return e
end

-- Sizes and places the item buttons in popout f (default: the real one) from
-- the saved style, all on whole screen pixels so spacing and borders come out
-- even: item spacing and the popout border are pixels, the first (best) item is
-- nearest the button. dir (up, down, left, right; default the real popout's
-- f.dir, else up) is the way it opens: a column for up and down, a row for
-- left and right. With button, the popout is also put centred on that side of
-- it, just past its indicator (arrow).
-- FlyoutPlan works it out: plan.pos[i] = { x, y } of item i (BOTTOMLEFT, in f's
-- units), plan.w / plan.h the popout's size, plan.pt / rpt / x / y its place
-- against the button (none without one), and the numbers BLIZZ_ART.Dividers
-- needs. LayoutFlyout applies it (the settings demo); the real popout hands it
-- to the secure code (PrepareSecure).
function FlyoutPlan(f, n, button, arrow, dir)
    dir = dir or "up"
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
    local plan = { pos = {}, size = size, gap = gap, pad = pad, art = art, across = across }
    for i = 1, n do
        local at = pad + (reverse and (n - i) or (i - 1)) * (size + gap)
        plan.pos[i] = across and { at, pad } or { pad, at }
    end
    local long, short = 2 * pad + n * (size + gap) - gap, size + 2 * pad
    if across then plan.w, plan.h = long, short else plan.w, plan.h = short, long end
    if not button then return plan end
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
    if across then
        local y = Snap(f, (button:GetHeight() * ratio - plan.h) / 2)
        if dir == "right" then
            plan.pt, plan.rpt, plan.x, plan.y = "BOTTOMLEFT", "BOTTOMRIGHT", away, y
        else
            plan.pt, plan.rpt, plan.x, plan.y = "BOTTOMRIGHT", "BOTTOMLEFT", -away, y
        end
    else
        local x = Snap(f, (button:GetWidth() * ratio - plan.w) / 2)
        if dir == "down" then
            plan.pt, plan.rpt, plan.x, plan.y = "TOPLEFT", "BOTTOMLEFT", x, -away
        else
            plan.pt, plan.rpt, plan.x, plan.y = "BOTTOMLEFT", "TOPLEFT", x, away
        end
    end
    return plan
end

-- Lays out a popout that is not secure (the settings demo) from its plan.
function LayoutFlyout(f, list, n, button, arrow, dir)
    if not f then return end
    local plan = FlyoutPlan(f, n, button, arrow, dir or f.dir or "up")
    for i = 1, n do   -- (StyleEntry has sized them)
        local e = list[i]
        if e then BLIZZ_ART.Point(e, "BOTTOMLEFT", f, "BOTTOMLEFT", plan.pos[i][1], plan.pos[i][2]) end
    end
    f:SetSize(plan.w, plan.h)
    BLIZZ_ART.Dividers(f, plan.art, n, plan.size, plan.gap, plan.pad, plan.across)
    if plan.pt then
        f:ClearAllPoints()
        f:SetPoint(plan.pt, button, plan.rpt, plan.x, plan.y)
    end
end

-- The snippet wrapped round an action button's OnEnter (the game runs it, in
-- combat too; "id" is set in front of it, see WrapButton). Reads what
-- PrepareSecure left on the header: n<id> items, the popout's size w/h and
-- place pt/rpt/x/y, per item ex/ey (its place) and t/v (item or spell to use;
-- "" for none, e.g. gear to put on). "Set only" leaves the items without a type,
-- so a click uses nothing.
OPEN_SNIPPET = [[
    if owner:GetAttribute("off") then return end
    local n = owner:GetAttribute("n" .. id) or 0
    if n < 2 then return end
    local f = owner:GetFrameRef("flyout")
    if not (f:IsShown() and f:GetAttribute("open") == id) then
        f:SetAttribute("open", id)
        f:ClearAllPoints()
        f:SetWidth(owner:GetAttribute("w" .. id))
        f:SetHeight(owner:GetAttribute("h" .. id))
        f:SetPoint(owner:GetAttribute("pt" .. id), self, owner:GetAttribute("rpt" .. id),
            owner:GetAttribute("x" .. id), owner:GetAttribute("y" .. id))
        local setOnly = owner:GetAttribute("mode") == "set"
        for i = 1, owner:GetAttribute("max") do
            local e = owner:GetFrameRef("e" .. i)
            if i <= n then
                local key = id .. "_" .. i
                e:ClearAllPoints()
                e:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", owner:GetAttribute("ex" .. key), owner:GetAttribute("ey" .. key))
                local t = owner:GetAttribute("t" .. key)
                if setOnly or t == "" then t = nil end
                e:SetAttribute("type", t)
                e:SetAttribute("item", t == "item" and owner:GetAttribute("v" .. key) or nil)
                e:SetAttribute("spell", t == "spell" and owner:GetAttribute("v" .. key) or nil)
                e:Show()
            else
                e:Hide()
            end
        end
        f:Show()
    end
    f:RegisterAutoHide(owner:GetAttribute("delay") or 0.5)
    f:AddToAutoHide(self)
]]

-- Gives action button b its number and wraps the snippet round its OnEnter
-- (once, out of combat). nil when it cannot be: no secure header, or b is not
-- a secure button (every bar addon's action buttons are).
function WrapButton(b)
    if wrapped[b] then return wrapped[b] end
    if not (secureHeader and SecureHandlerWrapScript and b.IsProtected and b:IsProtected()) then return nil end
    local id = #wrappedList + 1
    local ok = pcall(SecureHandlerWrapScript, b, "OnEnter", secureHeader, "local id = " .. id .. "\n" .. OPEN_SNIPPET)
    if not ok then return nil end
    wrapped[b], wrappedList[id] = id, b
    return id
end

-- Hands the secure code everything for every action button holding one of our
-- macros: which items its popout shows, and where (see OPEN_SNIPPET). Only out
-- of combat (attributes cannot change in it): after combat it runs again
-- (secureStale). Also sizes the items (StyleEntry), which combat forbids too.
function PrepareSecure()
    if InCombatLockdown() then secureStale = true return end
    secureStale = nil
    BuildFlyout()
    StyleFlyout(flyout)
    for _, e in ipairs(entries) do StyleEntry(e) end
    local hd = secureHeader
    if not hd then return end
    hd:SetAttribute("mode", PopoutClick())
    hd:SetAttribute("delay", Style("closeDelay"))
    hd:SetAttribute("off", DB().noFlyout == true)
    hd:SetAttribute("max", #entries)
    local enabled = DB().noFlyout ~= true
    for _, b in ipairs(buttons) do
        local id = WrapButton(b)
        if id then
            local m = enabled and MacroOnButton(b) or nil
            local list = m and flyoutItems[m.name]
            local n = list and math.min(#list, #entries) or 0
            if n >= 2 then
                local dir = POPOUT.Direction(b, m)
                local plan = FlyoutPlan(flyout, n, b, arrows[b], dir)
                local copy = {}
                for i = 1, n do copy[i] = list[i] end
                prepared[id] = { m = m, list = copy, n = n, dir = dir, plan = plan }
                hd:SetAttribute("n" .. id, n)
                hd:SetAttribute("w" .. id, plan.w)
                hd:SetAttribute("h" .. id, plan.h)
                hd:SetAttribute("pt" .. id, plan.pt)
                hd:SetAttribute("rpt" .. id, plan.rpt)
                hd:SetAttribute("x" .. id, plan.x)
                hd:SetAttribute("y" .. id, plan.y)
                for i = 1, n do
                    local key = id .. "_" .. i
                    local k = entries[i].k or 1   -- (the items are scaled: offsets in their own units)
                    hd:SetAttribute("ex" .. key, plan.pos[i][1] / k)
                    hd:SetAttribute("ey" .. key, plan.pos[i][2] / k)
                    local it = list[i]
                    local t, v = "", nil
                    if m.kind == "spells" or it.spell then
                        local name = SpellName(it.id)
                        if name then t, v = "spell", name end
                    elseif not NeedsEquip(it.id) then   -- (gear to put on first: PostClick equips it)
                        t, v = "item", "item:" .. it.id
                    end
                    hd:SetAttribute("t" .. key, t)
                    hd:SetAttribute("v" .. key, v)
                end
            else
                prepared[id] = nil
                hd:SetAttribute("n" .. id, 0)
            end
        end
    end
end

-- Draws the popout the snippet has just opened over button (our code may do
-- that in combat: icons, counts, the chosen border, the dividers). What it
-- shows is the prepared list, so it matches what the items will use.
function OpenFlyout(button)
    local id = wrapped[button]
    local p = id and prepared[id]
    if not p or not flyout then return end
    flyout.macro, flyout.button, flyout.dir = p.m, button, p.dir
    local list, m = p.list, p.m
    local _, chosenEntry = ChosenFor(m, list)
    local chosen = chosenEntry and (chosenEntry.pick or chosenEntry.id)
    for i = 1, p.n do
        local e = entries[i]
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
        StyleEntry(e)   -- (its size stays as it is in combat: see BLIZZ_ART.Size)
    end
    local pl = p.plan
    BLIZZ_ART.Dividers(flyout, pl.art, p.n, pl.size, pl.gap, pl.pad, pl.across)
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

-- (runs after the button's wrapped OnEnter, so the snippet has opened it)
function OnButtonEnter(b)
    if DB().noFlyout or not (flyout and flyout:IsShown()) then return end
    SafeOpen(b)
end

function HookButton(b)
    if hooked[b] then return end
    hooked[b] = true
    pcall(b.HookScript, b, "OnEnter", OnButtonEnter)
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
    -- only a sign: the mouse goes through it to the button (whose hover opens
    -- the popout; an addon's own frame could not open a secure popout in combat)
    a:EnableMouse(false)
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
    report.barDir = {}   -- which way Automatic opens each button's popout on your bars (the Buttons page shows it)
    for _, b in ipairs(buttons) do
        HookButton(b)
        local mine = MacroOnButton(b)
        ApplyLabel(b, mine)
        local m = enabled and mine or nil
        -- on a bar you can see (popouts on or off): the settings mark buttons that are on none
        if mine and b:IsVisible() then
            report.onBar[mine.name] = (report.onBar[mine.name] or 0) + 1
            if not report.barDir[mine.name] then
                local okDir, auto = pcall(POPOUT.Auto, b)
                report.barDir[mine.name] = okDir and auto or "up"
            end
        end
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
    if flyout and flyout:IsShown() and flyout.button and not InCombatLockdown() then
        local list = flyout.macro and flyoutItems[flyout.macro.name]
        if not list or #list < 2 or not enabled then flyout:Hide() end
    end
    local ok, err = pcall(PrepareSecure)   -- (the popouts open from what this hands over)
    if not ok then Fail("popout", err) end
end

-- ---------------------------------------------------------------------------
-- Look and feel, and the options window. ApplyStyle redraws everything that
-- has been built (highlights, tabs, popup) after a setting changes.
-- ---------------------------------------------------------------------------
-- (StyleOptions: defined below)

ApplyStyle = function()
    for button, g in pairs(glows) do StyleGlow(g, button) end
    for _, a in pairs(arrows) do StyleArrow(a) end
    if flyout then pcall(PrepareSecure) end   -- (restyles and re-lays out the popout, out of combat)
    if StyleOptions then StyleOptions() end
end

function Refresh()
    pcall(SafeCollect)
    Update()
end
