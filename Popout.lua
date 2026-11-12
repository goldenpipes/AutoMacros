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
MAX_ENTRIES = 14   -- (Raid Marker: 8 icons, 4 pings, Clear)
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
-- What clicking an item in a popout does: button m's own choice
-- (db.popClick[key], Shift+right-click on the Buttons page), else the Popout
-- page's (db.popoutClick).
function PopoutClick(m)
    local own = m and type(DB().popClick) == "table" and DB().popClick[m.key]
    if own == "useset" or own == "set" or own == "use" then return own end
    local v = DB().popoutClick
    if v == "set" or v == "use" then return v end
    return "useset"
end

-- button e's own choice (nil: it follows the Popout page)
function OwnPopoutClick(e)
    local t = DB().popClick
    return type(t) == "table" and t[e.key] or nil
end

-- the next one (Default, Use and set, Set only, Use only), saved for e
function NextPopoutClick(e)
    local order = { false, "useset", "set", "use" }
    local cur = OwnPopoutClick(e) or false
    local nxt = false
    for i, v in ipairs(order) do
        if v == cur then nxt = order[i % #order + 1] end
    end
    local db = DB()
    if type(db.popClick) ~= "table" then db.popClick = {} end
    db.popClick[e.key] = nxt or nil
    pcall(PrepareSecure)
    return nxt or nil
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
        if self.amPinned then return end   -- (pinned by a Ctrl+click: stays open)
        if self:IsShown() and not InCombatLockdown() and not self:IsMouseOver()
            and not (self.button and self.button:IsMouseOver())
            and not (pinButton and pinButton:IsMouseOver()) then
            self:Hide()
        end
    end)
    pcall(flyout.RegisterEvent, flyout, "GLOBAL_MOUSE_DOWN")
    flyout:HookScript("OnHide", function() PinChanged(false) end)
    flyout:Hide()
    local okH, h = pcall(CreateFrame, "Frame", "AutoMacrosSecure", UIParent, "SecureHandlerBaseTemplate")
    secureHeader = (okH and h and h.SetFrameRef) and h or nil
    if secureHeader then secureHeader:SetFrameRef("flyout", flyout) end
    for i = 1, MAX_ENTRIES do Entry(i) end
    BuildPinButton()
    BuildPingPlacer()
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
        -- (Ctrl+click: pinned, so a click elsewhere doesn't close it either; see BuildFlyout)
        if IsControlKeyDown() then PinChanged(true) end
        local pinned = flyout.amPinned
        if not m then return end
        -- gear that is not worn yet is put on (not used), so the button can show its cooldown
        if self.noPick then return end   -- (a lure or fishing item: used, the button keeps its pole)
        if self.unequipped and self.macroText then
            -- (a fishing pole: its macro put it on; made the button's pole below)
        elseif self.unequipped then
            if InCombatLockdown() then
                Print(ItemRef(self.itemID) .. ": cannot be equipped in combat")
            elseif not EquipByID(self.itemID) then
                Print(ItemRef(self.itemID) .. ": could not be equipped")
            end
        elseif PopoutClick(m) == "use" then
            return
        end
        -- (Raid Marker: nothing is picked, the bar button stays the skull)
        if m.kind == "icons" then return end
        -- the best item is what "automatic" already uses, so picking it clears the choice
        local p = flyout.button and prepared[wrapped[flyout.button] or 0]
        local list = p and p.list or flyoutItems[m.name]
        local automatic = list and list[1] and (list[1].pick or list[1].id) == self.pick
        ChooseItem(m, (not automatic) and self.pick or nil)
        if pinned then
            -- kept open: redraw it, so the border moves to the new pick
            if flyout:IsShown() and flyout.button and C_Timer and C_Timer.After then
                local b = flyout.button
                C_Timer.After(0, function()
                    if not flyout:IsShown() then return end
                    SafeOpen(b, true)
                end)
            end
        elseif not secureHeader and not InCombatLockdown() then
            flyout:Hide()
        end
    end)
    e:SetScript("OnEnter", function(self)
        if self.label then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.label)
        else
            ShowEntryTooltip(self, self.itemID, self.loc, self.kind == "spell")
        end
        if self.tip then   -- (trinkets, Weapon Swap: what a click does)
            GameTooltip:AddLine(self.tip, 1, 0.82, 0)
        elseif self.lure then
            GameTooltip:AddLine("Click to put it on your fishing pole", 1, 0.82, 0)
        elseif self.noPick then
            GameTooltip:AddLine("Click to use it", 0.7, 0.7, 0.7)
        elseif self.unequipped then
            GameTooltip:AddLine("Not equipped - click to put it on", 1, 0.82, 0)
        elseif self.unlock and PopoutClick(flyout.macro) ~= "set" then
            GameTooltip:AddLine("Click to unlock it", 1, 0.82, 0)
        else
            GameTooltip:AddLine(POPOUT_CLICK_TIPS[PopoutClick(flyout.macro)], 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("Ctrl+click keeps the popout open (or the pin at its end)", 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    e:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if secureHeader then
        secureHeader:SetFrameRef("e" .. i, e)
        -- (the pre snippet passes a message, so the post snippet runs: it closes the popout)
        pcall(SecureHandlerWrapScript, e, "OnClick", secureHeader, [[return nil, true]],
            -- (Ctrl+click pins it open: the hover timer that closes it once the mouse
            -- leaves is switched off, until the button is hovered again)
            -- (a pinned popout stays open on every click: the pin button unpins it)
            [[local f = owner:GetFrameRef("flyout")
            local pb = owner:GetFrameRef("pin")
            if IsControlKeyDown() then
                f:UnregisterAutoHide()
                if pb then pb:SetAttribute("pinned", true) end
            elseif not (pb and pb:GetAttribute("pinned")) then
                f:Hide()
            end]])
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
    local gap = art and Snap(f, BLIZZ_ART.BarGap(f) * BLIZZ_ART.ArtScale(f))
        or (BLIZZ_ART.gapFor or Style("entrySpacing")) * px
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
-- place pt/rpt/x/y, mode<id> (what a click does, per button), k<id> / bw<id> (the
-- items' scale and width: the button's own Item size), per item ex/ey
-- (its place) and t/v (item, spell or macro text to run; "" for none, e.g. gear to put on).
-- "Set only" leaves the items without a type, so a click uses nothing.
OPEN_SNIPPET = [[
    if owner:GetAttribute("off") then return end
    -- a pinned popout stays exactly as it is until its pin button unpins it:
    -- no hover (its own button's or another's) opens, moves or unpins it
    local pinB = owner:GetFrameRef("pin")
    if pinB and pinB:GetAttribute("pinned") and owner:GetFrameRef("flyout"):IsShown() then return end
    -- "Show with": only while that modifier key is held (none = always)
    local mod = owner:GetAttribute("hovermod")
    if (mod == "shift" and not IsShiftKeyDown()) or (mod == "control" and not IsControlKeyDown())
        or (mod == "alt" and not IsAltKeyDown()) then return end
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
        local setOnly = owner:GetAttribute("mode" .. id) == "set"
        local k, bw = owner:GetAttribute("k" .. id) or 1, owner:GetAttribute("bw" .. id)
        for i = 1, owner:GetAttribute("max") do
            local e = owner:GetFrameRef("e" .. i)
            if i <= n then
                local key = id .. "_" .. i
                e:SetScale(k)   -- (this button's own item size)
                if bw then
                    e:SetWidth(bw)
                    e:SetHeight(bw)
                end
                e:ClearAllPoints()
                e:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", owner:GetAttribute("ex" .. key), owner:GetAttribute("ey" .. key))
                local t = owner:GetAttribute("t" .. key)
                -- (u: always used, also on Set only: a lure, which is never the button's item)
                if (setOnly and not owner:GetAttribute("u" .. key)) or t == "" then t = nil end
                e:SetAttribute("type", t)
                e:SetAttribute("item", t == "item" and owner:GetAttribute("v" .. key) or nil)
                e:SetAttribute("spell", t == "spell" and owner:GetAttribute("v" .. key) or nil)
                e:SetAttribute("macrotext", t == "macro" and owner:GetAttribute("v" .. key) or nil)
                e:Show()
            else
                e:Hide()
            end
        end
        f:Show()
    end
    -- the pin button at the popout's far end (its own rect counts as "over" too)
    local pb = owner:GetFrameRef("pin")
    if pb then
        pb:ClearAllPoints()
        pb:SetWidth(owner:GetAttribute("ps" .. id) or 16)
        pb:SetHeight(owner:GetAttribute("ps" .. id) or 16)
        pb:SetPoint(owner:GetAttribute("pa" .. id) or "BOTTOM", f, owner:GetAttribute("pe" .. id) or "TOP",
            owner:GetAttribute("pox" .. id) or 0, owner:GetAttribute("poy" .. id) or 2)
        pb:SetAttribute("pinned", nil)
        pb:Show()
    end
    f:RegisterAutoHide(owner:GetAttribute("delay") or 0.5)
    f:AddToAutoHide(self)
    if pb then f:AddToAutoHide(pb) end
]]

-- The modifier key a popout needs held to open on hover ("Show with", as
-- EllesmereUI's own modifier dropdowns: none / shift / control / alt).
POPOUT_MODIFIERS = {
    { key = "none", label = "None" }, { key = "shift", label = "Shift" },
    { key = "control", label = "Control" }, { key = "alt", label = "Alt" },
}
function PopoutModifier()
    local v = DB().popMod
    return (v == "shift" or v == "control" or v == "alt") and v or "none"
end

-- A button's own Item size (percent) and Item spacing (pixels) on the Popout
-- page's Per-Button Overrides, account-wide like its direction; nil = the global one.
function PopoutSize(m)
    local t = DB().popSize
    return m and type(t) == "table" and tonumber(t[m.key]) or nil
end

function PopoutGap(m)
    local t = DB().popGap
    return m and type(t) == "table" and tonumber(t[m.key]) or nil
end

-- Runs fn(...) with macro m's popout size and spacing in place of the global ones
-- (BLIZZ_ART.ItemSize and FlyoutPlan read them), and returns what it returns.
function PopoutLook(m, fn, ...)
    BLIZZ_ART.scaleFor, BLIZZ_ART.gapFor = PopoutSize(m), PopoutGap(m)
    local ok, a = pcall(fn, ...)
    BLIZZ_ART.scaleFor, BLIZZ_ART.gapFor = nil, nil
    if not ok then error(a, 0) end
    return a
end

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
    hd:SetAttribute("delay", Style("closeDelay"))
    hd:SetAttribute("hovermod", PopoutModifier())
    if pinButton then pinButton:SetAttribute("delay", Style("closeDelay")) end
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
                -- its own size and spacing: the items are scaled by k (Blizzard's
                -- button) or sized bw (EllesmereUI's look) as it opens (OPEN_SNIPPET)
                BLIZZ_ART.barFor = b   -- (its items as big as this bar's buttons at 100%)
                local plan = PopoutLook(m, FlyoutPlan, flyout, n, b, arrows[b], dir)
                local size = PopoutLook(m, BLIZZ_ART.ItemSize, flyout)
                BLIZZ_ART.barFor = nil
                local e1 = entries[1]
                local k, bw = 1, size
                if e1.native and not e1.euiLook then k, bw = size / e1.native, e1.native end
                local copy = {}
                for i = 1, n do copy[i] = list[i] end
                prepared[id] = { m = m, list = copy, n = n, dir = dir, plan = plan }
                hd:SetAttribute("n" .. id, n)
                hd:SetAttribute("mode" .. id, PopoutClick(m))   -- (per button)
                hd:SetAttribute("w" .. id, plan.w)
                hd:SetAttribute("h" .. id, plan.h)
                hd:SetAttribute("pt" .. id, plan.pt)
                hd:SetAttribute("rpt" .. id, plan.rpt)
                hd:SetAttribute("x" .. id, plan.x)
                hd:SetAttribute("y" .. id, plan.y)
                hd:SetAttribute("k" .. id, k)
                hd:SetAttribute("bw" .. id, bw)
                -- the pin button: past the last item, half an item big
                local far = PIN_ENDS[dir] or PIN_ENDS.up
                local ps = Snap(flyout, size * 0.5)
                local gap = Snap(flyout, 2)
                hd:SetAttribute("pe" .. id, far[1])
                hd:SetAttribute("pa" .. id, far[2])
                hd:SetAttribute("pox" .. id, far[3] * gap)
                hd:SetAttribute("poy" .. id, far[4] * gap)
                hd:SetAttribute("ps" .. id, ps)
                for i = 1, n do
                    local key = id .. "_" .. i
                    -- (the items are scaled: offsets in their own units)
                    hd:SetAttribute("ex" .. key, plan.pos[i][1] / k)
                    hd:SetAttribute("ey" .. key, plan.pos[i][2] / k)
                    local it = list[i]
                    local t, v = "", nil
                    if it.unlock then   -- a locked box: Pick Lock or a key on it (OpenableList)
                        t, v = "macro", it.unlock
                    elseif it.macro then   -- Fishing: put a pole on, or a lure on the pole (FishingList)
                        t, v = "macro", it.macro
                    elseif m.kind == "spells" or it.spell then
                        local name = SpellName(it.id)
                        if name then t, v = "spell", name end
                    elseif not NeedsEquip(it.id) then   -- (gear to put on first: PostClick equips it)
                        t, v = "item", "item:" .. it.id
                    end
                    hd:SetAttribute("t" .. key, t)
                    hd:SetAttribute("v" .. key, v)
                    -- (used even on "Set only": lures, Clear; and every Raid Marker
                    -- entry, so picking a marker always puts it on at once)
                    hd:SetAttribute("u" .. key, (it.noPick or m.kind == "icons") and true or nil)
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
function OpenFlyout(button, redraw)
    -- (pinned: a hover leaves it alone, as the snippet does; redraw = our own
    -- redraw of the pinned popout after a click on one of its items)
    if flyout and flyout.amPinned and flyout:IsShown() and not redraw then return end
    local id = wrapped[button]
    local p = id and prepared[id]
    if not p or not flyout then return end
    flyout.macro, flyout.button, flyout.dir = p.m, button, p.dir
    if not redraw then PinChanged(false) end   -- (opened afresh by a hover: the hover timer is back on)
    local list, m = p.list, p.m
    local _, chosenEntry = ChosenFor(m, list)
    -- (Use only never changes the button's item: no item is marked as the one in use)
    local chosen = PopoutClick(m) ~= "use" and chosenEntry and (chosenEntry.pick or chosenEntry.id)
    -- this button's own size and spacing while the items are dressed (StyleEntry
    -- sizes them out of combat only; the snippet already did, in combat too)
    BLIZZ_ART.scaleFor, BLIZZ_ART.gapFor = PopoutSize(m), PopoutGap(m)
    BLIZZ_ART.hoverFor = m and ("entryHover_" .. m.key)
    BLIZZ_ART.barFor = button
    local ok, err = pcall(OpenFlyoutItems, p, list, m, chosen)
    BLIZZ_ART.scaleFor, BLIZZ_ART.gapFor, BLIZZ_ART.hoverFor, BLIZZ_ART.barFor = nil, nil, nil, nil
    if not ok then error(err, 0) end
end

function OpenFlyoutItems(p, list, m, chosen)
    -- the bar art behind the items scales with them (only out of combat: it is
    -- anchored to the secure popout; in combat it keeps the size it last had)
    if not InCombatLockdown() then StyleFlyout(flyout) end
    for i = 1, p.n do
        local e = entries[i]
        local isSpell = m.kind == "spells" or list[i].spell == true   -- the Hearth/Teleport button has both
        e.kind = isSpell and "spell" or "item"
        e.itemID = list[i].id
        e.pick = list[i].pick or list[i].id
        e.loc = (not isSpell) and lastLocs[list[i].id] or nil
        e.unlock = list[i].unlock
        e.macroText = list[i].macro   -- (Fishing: the macro puts the pole on, PostClick doesn't)
        e.noPick = list[i].noPick     -- (a lure: used, never the button's item)
        e.lure = list[i].noPick and list[i].macro ~= nil
        e.tip = list[i].tip
        e.label = list[i].name   -- (icons buttons: no item or spell behind it)
        if list[i].texture or list[i].atlas then
            local okAtlas = list[i].atlas and pcall(e.icon.SetAtlas, e.icon, list[i].atlas)
            if not okAtlas then e.icon:SetTexture(list[i].texture) end
            e.unequipped = false
            pcall(e.icon.SetDesaturated, e.icon, false)
            e.count:SetText("")
        else
            e.icon:SetTexture(isSpell and (list[i].icon or SpellIcon(list[i].id)) or IconFor({ item = list[i].id }))
            e.unequipped = (not isSpell) and NeedsEquip(list[i].id)   -- grey until worn
            pcall(e.icon.SetDesaturated, e.icon, e.unequipped and true or false)
            local count = (not isSpell) and CountOf(list[i].id) or nil
            e.count:SetText((count and count > 1) and tostring(count) or "")
        end
        -- highlighted border: the one in use (trinkets, Weapon Swap: the one worn)
        -- (none on Raid Marker: its popout is a palette, not a choice of item)
        e.selected = (((e.pick == chosen) and not e.noPick) or list[i].worn == true) and m.kind ~= "icons"
        StyleEntry(e)   -- (its size stays as it is in combat: see BLIZZ_ART.Size)
    end
    local pl = p.plan
    BLIZZ_ART.Dividers(flyout, pl.art, p.n, pl.size, pl.gap, pl.pad, pl.across)
end

PIN_TEXTURE = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Pin"

-- Ground pings (Raid Marker's pings, right-click): "/click AutoMacrosPingArm<k>"
-- shows a see-through secure button over the whole screen whose next click runs
-- "/ping [@cursor] <ping>" there ([@cursor] takes the world under the mouse, not
-- the button) and hides it again; a right-click on it only cancels. All of it
-- secure, so it works in combat. (The idea is AbiMark's, VainWoW's Forever addon.)
PING_ARM = "AutoMacrosPingArm"
function BuildPingPlacer()
    if pingPlacer or not C_Ping or not secureHeader then return end
    local ok, o = pcall(CreateFrame, "Button", "AutoMacrosPingPlace", UIParent, "SecureActionButtonTemplate")
    if not ok or not o then return end
    pingPlacer = o
    o:SetAllPoints(UIParent)
    o:SetFrameStrata("FULLSCREEN_DIALOG")
    o:EnableMouse(true)
    o:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pcall(o.SetAttribute, o, "useOnKeyDown", false)
    o:SetAttribute("type", "macro")
    -- what to do, at the top of the screen (plain text, no art: the world stays visible)
    o.hint = o:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    o.hint:SetPoint("TOP", o, "TOP", 0, -120)
    o.hint:SetText(Loc("Click the ground to ping it - right-click to cancel"))
    o:Hide()
    -- after any click: hidden again (a right-click's macro does nothing: [nobtn:2])
    pcall(SecureHandlerWrapScript, o, "OnClick", secureHeader, [[return nil, true]], [[self:Hide()]])
    for k, p in ipairs(PING_TYPES) do
        local okA, a = pcall(CreateFrame, "Button", PING_ARM .. k, UIParent, "SecureHandlerClickTemplate")
        if okA and a then
            a:Hide()
            a:SetFrameRef("place", o)
            a:SetAttribute("ping", "/ping [nobtn:2,@cursor] " .. PingToken(p))
            a:SetAttribute("_onclick", [[
                local o = self:GetFrameRef("place")
                o:SetAttribute("macrotext", self:GetAttribute("ping"))
                o:Show()
            ]])
        end
    end
end
-- where the pin button sits per popout direction: the popout's far edge, the pin
-- button's own point on it, and which way the small gap goes (x, y)
PIN_ENDS = {
    up = { "TOP", "BOTTOM", 0, 1 }, down = { "BOTTOM", "TOP", 0, -1 },
    left = { "LEFT", "RIGHT", -1, 0 }, right = { "RIGHT", "LEFT", 1, 0 },
}

-- A small button at the far end of every popout that pins it open (the hover
-- timer that closes it once the mouse leaves is switched off) and unpins it.
-- Secure (SecureHandlerClickTemplate), so it works in combat too; Ctrl+click on
-- an item does the same. Hovering the bar button again unpins (OPEN_SNIPPET).
function BuildPinButton()
    if pinButton or not secureHeader then return end
    local ok, pb = pcall(CreateFrame, "Button", "AutoMacrosPinButton", flyout, "SecureHandlerClickTemplate")
    if not ok or not pb then return end
    pinButton = pb
    pb:SetSize(16, 16)
    pb:SetFrameLevel(flyout:GetFrameLevel() + 20)
    pb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pb.tex = pb:CreateTexture(nil, "ARTWORK")
    pb.tex:SetAllPoints()
    pb.tex:SetTexture(PIN_TEXTURE)
    pb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    pb:SetFrameRef("flyout", flyout)
    pb:SetAttribute("_onclick", [[
        -- (the release that ends a drag of the pin is no click: MovableBy)
        if self:GetAttribute("dragged") then
            self:SetAttribute("dragged", nil)
            return
        end
        local f = self:GetFrameRef("flyout")
        if self:GetAttribute("pinned") then
            self:SetAttribute("pinned", nil)
            f:RegisterAutoHide(self:GetAttribute("delay") or 0.5)
            f:AddToAutoHide(self)
        else
            self:SetAttribute("pinned", true)
            f:UnregisterAutoHide()
        end
    ]])
    MovableBy(pb)   -- (before the OnDragStart wrap below: SetScript would replace it)
    -- In combat a drag can't follow the mouse (moving the secure popout is our
    -- code's to do out of combat only), and the release that ends a drag never
    -- reaches secure code here (tried: SecureHandlerMouseUpDownTemplate). So a
    -- drag start in combat (this wrap) pins it and shows `mover`, a see-through
    -- secure button over the whole screen: the next click there puts the
    -- popout's centre at the mouse (a right-click only cancels). As the ground
    -- pings (BuildPingPlacer).
    local okM, mv = pcall(CreateFrame, "Button", "AutoMacrosMovePlace", UIParent, "SecureHandlerClickTemplate")
    if okM and mv then
        mv:SetAllPoints(UIParent)
        mv:SetFrameStrata("FULLSCREEN_DIALOG")
        mv:EnableMouse(true)
        mv:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        mv.hint = mv:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        mv.hint:SetPoint("TOP", mv, "TOP", 0, -120)
        mv.hint:SetText(Loc("Click where the popout should go - right-click to cancel"))
        mv:SetFrameRef("flyout", flyout)
        mv:SetFrameRef("header", secureHeader)
        mv:SetAttribute("_onclick", [[
            self:Hide()
            if button ~= "LeftButton" then return end
            local x, y = self:GetMousePosition()
            if not x then return end
            -- the pin lands on the spot (not the popout's centre): the popout's far
            -- edge goes there less the pin's own offset and half its size
            local f = self:GetFrameRef("flyout")
            local hd = self:GetFrameRef("header")
            local id = f:GetAttribute("open")
            local pe = (hd and id and hd:GetAttribute("pe" .. id)) or "TOP"
            local ps = (hd and id and hd:GetAttribute("ps" .. id)) or 16
            local dx = (hd and id and hd:GetAttribute("pox" .. id)) or 0
            local dy = (hd and id and hd:GetAttribute("poy" .. id)) or 2
            if pe == "TOP" then dy = dy + ps / 2 elseif pe == "BOTTOM" then dy = dy - ps / 2
            elseif pe == "RIGHT" then dx = dx + ps / 2 elseif pe == "LEFT" then dx = dx - ps / 2 end
            f:ClearAllPoints()
            f:SetPoint(pe, self, "BOTTOMLEFT", x * self:GetWidth() - dx, y * self:GetHeight() - dy)
        ]])
        mv:Hide()
        pb:SetFrameRef("mover", mv)
    end
    pcall(SecureHandlerWrapScript, pb, "OnDragStart", secureHeader, [[
        if PlayerInCombat() then
            self:SetAttribute("dragged", nil)   -- (no click follows a drag)
            if not self:GetAttribute("pinned") then
                self:SetAttribute("pinned", true)
                self:GetFrameRef("flyout"):UnregisterAutoHide()
            end
            local mv = self:GetFrameRef("mover")
            if mv then mv:Show() end
        end
    ]])
    pb:HookScript("OnClick", function(self)
        PinChanged(self:GetAttribute("pinned") and true or false)
        if GameTooltip:IsOwned(self) then self:GetScript("OnEnter")(self) end
    end)
    pb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if flyout.amPinned then
            GameTooltip:SetText("Unpin the popout")
            GameTooltip:AddLine("It stays open until you unpin it here; then it closes when the mouse leaves it or you click an item.", 0.7, 0.7, 0.7, true)
            GameTooltip:AddLine("Drag the pin to move the popout (in combat: drag it, then click where it should go).", 0.7, 0.7, 0.7, true)
        else
            GameTooltip:SetText("Pin the popout open")
            GameTooltip:AddLine("It stays open while you click its items, move the mouse away or click in the world. Ctrl+click on an item pins it too.", 0.7, 0.7, 0.7, true)
            GameTooltip:AddLine("Drag the pin to move the popout and pin it there (in combat: drag it, then click where it should go).", 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()
    end)
    pb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    secureHeader:SetFrameRef("pin", pb)
    PinChanged(false)
end

-- The popout can be dragged anywhere by frame (the pin button: not the items,
-- so a drag is never taken for a click), pinned or not, and is pinned where it
-- is let go. Out of combat only: the popout is a secure frame, which the game
-- lets addons move only then. Its next opening (once unpinned) puts it back by
-- its bar button (OPEN_SNIPPET anchors it afresh).
function MovableBy(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not (flyout and flyout:IsShown()) then return end
        if InCombatLockdown() then
            -- (the secure wrap pinned it; the next click on the screen moves it)
            PinChanged(true)
            return
        end
        -- (the release ending the drag may also count as a click on the pin: its
        -- _onclick skips that one; cleared below if no click comes)
        self:SetAttribute("dragged", true)
        -- pinned from the start: the hover timer would hide it mid-drag, the mouse
        -- being outside the area it measured (UnregisterAutoHide works from our
        -- code out of combat: Blizzard's SecureHoverDriver.lua)
        if not self:GetAttribute("pinned") then
            self:SetAttribute("pinned", true)
            if UnregisterAutoHide then pcall(UnregisterAutoHide, flyout) end
        end
        PinChanged(true)
        flyout:SetMovable(true)
        flyout:StartMoving()
        flyout.amMoving = true
    end)
    frame:SetScript("OnDragStop", function(self)
        if not (flyout and flyout.amMoving) then return end
        flyout.amMoving = nil
        flyout:StopMovingOrSizing()
        -- (not saved in the game's layout cache: it opens by its button next time)
        pcall(flyout.SetUserPlaced, flyout, false)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.2, function()
                if not InCombatLockdown() then pcall(self.SetAttribute, self, "dragged", nil) end
            end)
        end
    end)
end

-- Pinned or not: the popout's own flag (the click-elsewhere closer skips a
-- pinned one) and the pin button's look.
function PinChanged(on)
    if not flyout then return end
    flyout.amPinned = on or nil
    if pinButton then
        pinButton.tex:SetAlpha(on and 1 or 0.45)
        -- (while pinned: the Selected border color, white otherwise)
        local c = on and StyleColor("selectedColor") or { 1, 1, 1 }
        pinButton.tex:SetVertexColor(c[1] or 1, c[2] or 1, c[3] or 1)
    end
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
    -- (retail's secret values can't be compared: such a button isn't ours to find)
    if not (Readable(kind) and Readable(id)) or kind ~= "macro" then return nil end
    local text = GetActionText and GetActionText(slot)
    if not Readable(text) then return nil end
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

-- Aspects: while an aspect is on, the game shows the bar button with its own
-- "active" icon, so you can't tell which aspect it is. On our Aspects button the
-- aspect's own icon is then drawn over it, with the game's active icon on top at
-- 50% (Lewis). Only pictures on our own frame, anchored to the button: works in
-- combat too. Refreshed on aura, form and bar changes (ActiveIconFrame).
ACTIVE_OVERLAY_ALPHA = 0.5
activeOverlays = {}

function ButtonIconTexture(b)
    local t = b.icon or b.Icon or (b.GetName and b:GetName() and _G[b:GetName() .. "Icon"])
    return t and t.GetTexture and t or nil
end

function RefreshActiveOverlays()
    for _, b in ipairs(buttons or {}) do
        local o = activeOverlays[b]
        local show = false
        local m = MacroOnButton(b)
        if m and m.key == "aspects" and b:IsVisible() then
            local list = flyoutItems[m.name]
            local _, entry = ChosenFor(m, list or {})
            local own = entry and (entry.icon or SpellIcon(entry.id))
            local iconTex = ButtonIconTexture(b)
            local shown = iconTex and iconTex:GetTexture()
            -- (the game shows something else than the aspect: its active icon)
            if own and shown and Readable(shown) and shown ~= own and SpellIcon(entry.id) ~= shown then
                if not o then
                    o = CreateFrame("Frame", nil, UIParent)
                    o.base = o:CreateTexture(nil, "ARTWORK", nil, 1)
                    o.base:SetAllPoints()
                    o.top = o:CreateTexture(nil, "ARTWORK", nil, 2)
                    o.top:SetAllPoints()
                    activeOverlays[b] = o
                end
                o:SetFrameStrata(b:GetFrameStrata())
                o:SetFrameLevel(b:GetFrameLevel() + 3)
                o:ClearAllPoints()
                o:SetAllPoints(iconTex)
                o.base:SetTexture(own)
                o.base:SetTexCoord(iconTex:GetTexCoord())
                o.top:SetTexture(shown)
                o.top:SetTexCoord(iconTex:GetTexCoord())
                o.top:SetAlpha(ACTIVE_OVERLAY_ALPHA)
                show = true
            end
        end
        if o then o:SetShown(show) end
    end
end

ActiveIconFrame = CreateFrame("Frame")
for _, ev in ipairs({ "UNIT_AURA", "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS",
        "ACTIONBAR_UPDATE_STATE", "ACTIONBAR_SLOT_CHANGED", "PLAYER_ENTERING_WORLD" }) do
    pcall(ActiveIconFrame.RegisterEvent, ActiveIconFrame, ev)
end
ActiveIconFrame:SetScript("OnEvent", function(_, ev, unit)
    if ev == "UNIT_AURA" and unit ~= "player" then return end
    -- (a frame later: the bar has redrawn its icon by then)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() pcall(RefreshActiveOverlays) end)
    else
        pcall(RefreshActiveOverlays)
    end
end)

RefreshArrows = function()
    local enabled = DB().noFlyout ~= true
    local tabs = 0
    report.onBar = {}
    report.barLayout = {}   -- vertical / horizontal bar per button (POPOUT.CheckLayout; /amac debug)
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
                POPOUT.CheckLayout(b, mine)   -- (moved between a vertical and a horizontal bar: Automatic again)
                local okDir, auto = pcall(POPOUT.Auto, b, POPOUT.Count(mine))
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
        -- (a pinned one stays until it is unpinned)
        if (not list or #list < 2 or not enabled) and not flyout.amPinned then flyout:Hide() end
    end
    pcall(RefreshActiveOverlays)
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
