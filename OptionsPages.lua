-- AutoMacros: Settings, part 2: the pages (PAGES), the page builder, Blizzard's
-- AddOns panel.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---- the settings ----
function UI.SToggle(label, key)
    return { type = "toggle", label = label,
        get = function() return Style(key) and true or false end,
        set = function(v) SetStyle(key, v) end }
end

function UI.LearnedSummary()
    local learned = DB().learned
    local n, auto, lines = 0, 0, {}
    if type(learned) == "table" then
        local ids = {}
        for id in pairs(learned) do ids[#ids + 1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local rec = learned[id]
            n = n + 1
            if type(rec) ~= "table" or rec.how ~= "manual" then auto = auto + 1 end
            if #lines < 4 and type(rec) == "table" then
                local t = {}
                for _, s in ipairs(rec.sets or {}) do t[#t + 1] = (SetTitle(s)) end
                lines[#lines + 1] = ItemRef(id) .. " - " .. table.concat(t, ", ")
            end
        end
    end
    local head = string.format("Learned items: %d (%d automatic, %d by hand). /amac learned lists them all.", n, auto, n - auto)
    return head .. (#lines > 0 and ("\n" .. table.concat(lines, "\n")) or "")
end

-- true while buttons use Blizzard's art (no EllesmereUI look): for settings
-- that only apply then (an item's "when")
function UI.BlizzLook() return EUIButtonLook() == nil end

UI.ButtonSize = BLIZZ_ART.BarButtonSize   -- (the demo button's size)

-- the widest the flyout indicator goes: your buttons' width, or on Blizzard's
-- rounded buttons the straight part of their top edge
function UI.TabMaxWidth()
    local w = UI.ButtonSize()
    if BLIZZ_ART.Rounded() then w = math.floor(w * (1 - 2 * BLIZZ_ART.CORNER)) end
    return w
end

-- a setting's number, or what its function returns (a slider's max, say)
function UI.Num(v)
    if type(v) == "function" then return v() end
    return v
end

-- Items listed in pairs where they can share a row: on the EllesmereUI page
-- two toggles, sliders or dropdowns next to each other go side by side.
-- An item with when = function shows only while it returns true.
PAGES = {
    -- the first page is the one AutoMacros opens on (named AutoMacros in the
    -- options tree, the others under it)
    { name = "General", sections = {
        { name = "Tooltips and labels", items = {
            { type = "toggle", label = "Clean \"No X in inventory\" tooltip",
                get = function() return not DB().stockTooltip end, set = function(v) DB().stockTooltip = not v end },
            { type = "toggle", label = "Hide macro names on buttons",
                get = function() return not DB().showNames end,
                set = function(v) DB().showNames = not v; Refresh() end },
            { type = "color", label = "Tooltip text color", key = "tooltipColor" },
        } },
        { name = "Chat", items = {
            -- what the addon says by itself: items learned, buttons turned on, macros removed
            { type = "toggle", label = "Show info messages",
                get = function() return not DB().quiet end,
                set = function(v) DB().quiet = (not v) or nil end },
            -- the "No water in inventory." line when you click an empty button
            { type = "toggle", label = "Show the empty-button message",
                get = function() return not DB().noEmptyMsg end,
                set = function(v) DB().noEmptyMsg = (not v) or nil end },
        } },
        { name = "Item learning", items = {
            { type = "text", text = UI.LearnedSummary },
        } },
        { name = "Appearance", items = {
            { type = "eui", items = {
                { type = "toggle", label = "Use EllesmereUI styling",
                    get = function() return Style("euiSkin") and true or false end,
                    set = function(v)
                        SetStyle("euiSkin", v)
                        -- the Flyout tab shows different item options for each look
                        if EllesmereUI and EllesmereUI.RefreshPage then pcall(EllesmereUI.RefreshPage, EllesmereUI, true) end
                        RefreshOptions()
                    end },
            } },
            { type = "button", label = "Reset appearance", action = function() ResetStyle() end, refreshAll = true },
        } },
    } },
    -- previewH: the preview strip's fixed height on Blizzard's pages (see UI.FitHeader);
    -- previewSide = "right": the preview in a column right of the settings instead
    -- (stamp: built again when the buttons change, e.g. a new one of your own,
    -- or what one of yours holds)
    -- (a page may also have build = fn(parent, width) -> y: one that lays itself out)
    { name = "Buttons", header = "buttons", previewH = 140, sections = UI.ButtonSections,
        stamp = function() return UI.ButtonsStamp() .. "|" .. UI.CustomStamp() end },
    { name = "Highlight", header = "glow", previewH = 120, sections = {
        { name = "Highlight", items = {
            { type = "toggle", label = "Highlight empty buttons",
                get = function() return DB().glow ~= false end,
                set = function(v) DB().glow = v; RefreshGlow() end },
            -- one row: "Pulse [x]   Pulse time <slider>"
            { type = "row", items = {
                UI.SToggle("Pulse", "glowPulse"),
                { type = "range", label = "Pulse time", key = "glowSpeed", min = 0.2, max = 2, step = 0.1 },
            } },
            { type = "color", label = "Color", key = "glowColor", alpha = true },
            -- solid: the border's width, inside the button; soft glow: how far it reaches in
            { type = "range", label = "Thickness", key = "glowThickness", min = 1, max = 5, step = 1 },
            { type = "choice", label = "Texture", key = "glowTexture", list = function() return TextureChoices(true) end },
        } },
    } },
    -- stamp: built again when shown if this has changed (the Direction list)
    { name = "Popout", header = "flyout", previewSide = "right", stamp = UI.DirectionStamp, sections = {
        { name = "Behaviour", items = {
            -- one row: "Popout on hover [x]   Close delay <slider>"
            { type = "row", items = {
                { type = "toggle", label = "Popout on hover",
                    get = function() return not DB().noFlyout end,
                    set = function(v) DB().noFlyout = not v; Refresh() end },
                { type = "range", label = "Close delay", key = "closeDelay", min = 0.1, max = 1.5, step = 0.1 },
            } },
        } },
        -- which way each button's popout opens (POPOUT.Direction)
        { name = "Direction", items = function() return UI.DirectionItems() end },
        { name = "Popout indicator", items = {
            { type = "color", label = "Color", key = "tabColor", alpha = true },
            { type = "range", label = "Width", key = "tabWidth", min = 0, max = UI.TabMaxWidth, step = 1 },
            { type = "range", label = "Height (pixels)", key = "tabHeight", min = 1, max = 5, step = 1 },
            { type = "choice", label = "Texture", key = "tabTexture", list = function() return TextureChoices(false) end },
        } },
        { name = "Items", items = {
            -- with EllesmereUI's look the items copy its Action Bars settings
            { type = "text", height = 34, when = function() return EUIButtonLook() ~= nil end,
                text = function() return "Items look like your EllesmereUI action bars: border, icon zoom, and the hover"
                    .. " and pushed effects from its Bar Animations page." end },
            -- the hover on everything drawn like an action button (items, previews);
            -- Default is your action bars' own hover; its opacity applies to every mode
            { type = "color", label = "Hover", key = "entryHover", alpha = true },
            -- with Blizzard's look the selected item shows the button's checked
            -- border (as the pet bar marks its active button), Default its own color
            { type = "color", label = "Selected border", key = "selectedColor", alpha = true },
            { type = "range", label = "Selected border size", key = "selectedSize", min = 1, max = 6, step = 1,
                when = function() return EUIButtonLook() ~= nil end },
            { type = "range", label = "Item size", key = "itemScale", min = 50, max = 200, step = 10, fmt = "%d%%" },
            -- the popup's background: Blizzard's action bar art, on or off as the
            -- bar art can be in Edit Mode (EllesmereUI's look has none)
            { type = "toggle", label = "Show background", when = UI.BlizzLook,
                get = function() return Style("flyoutArt") ~= false end,
                set = function(v) SetStyle("flyoutArt", v) end },
            -- greyed out with the bar background on: the items then use the main bar's spacing
            { type = "range", label = "Item spacing", key = "entrySpacing", min = 0, max = 10, step = 1,
                disabled = function() return BLIZZ_ART.PopupArt() end },
        } },
    } },
}

-- a tab's sections; one with when = function shows only while it returns true
function UI.PageSections(page)
    local all = page.sections
    if type(all) == "function" then all = all() end
    local list = {}
    for _, section in ipairs(all) do
        if not section.when or section.when() then list[#list + 1] = section end
    end
    return list
end

-- the settings' labels in the reader's spelling (see Loc), done once
function UI.LocItems(items)
    for _, item in ipairs(items) do
        item.label = Loc(item.label)
        if item.items then UI.LocItems(item.items) end
    end
end
for _, page in ipairs(PAGES) do
    if type(page.sections) == "table" then
        for _, section in ipairs(page.sections) do
            if type(section.items) == "table" then UI.LocItems(section.items) end
        end
    end
end

UI.PAIRABLE = { toggle = true, range = true, choice = true }

-- Colours share a row too when EllesmereUI can put a swatch next to a dropdown,
-- as its Action Bars page does: mode dropdown with the colour swatch beside it.
function UI.Pairable(item)
    if UI.PAIRABLE[item.type] then return true end
    return item.type == "color" and EllesmereUI and EllesmereUI.BuildColorSwatch ~= nil
end

-- The colour swatch inside one half of a DualRow, left of its dropdown. It
-- shows the colour drawn now; picking one switches the mode to Custom.
function UI.InlineSwatch(region, item)
    if item.type ~= "color" or type(region) ~= "table" or not region._control then return end
    local key = item.key
    local ok, sw, refresh = pcall(EllesmereUI.BuildColorSwatch, region, region:GetFrameLevel() + 5,
        function() local c = StyleColor(key); return c[1], c[2], c[3], c[4] or 1 end,
        function(r, g, b, a)
            SetColor(key, r, g, b, item.alpha and a or nil)
            RefreshEUIPage()
        end, item.alpha and true or false, 20)
    if not ok or type(sw) ~= "table" then return end
    pcall(function()
        sw:ClearAllPoints()
        sw:SetPoint("RIGHT", region._control, "LEFT", -12, 0)
        region._lastInline = sw
    end)
    if type(refresh) == "function" and EllesmereUI.RegisterWidgetRefresh then
        pcall(EllesmereUI.RegisterWidgetRefresh, function() pcall(refresh) end)
    end
end

-- Greys out (or brings back) a setting on our pages, as Blizzard's do for
-- options that do not apply: its label grey, its control faded and not usable.
function UI.SetWidgetEnabled(w, label, on)
    if w.SetEnabled then
        pcall(w.SetEnabled, w, on)
    elseif w.Enable and w.Disable then
        if on then w:Enable() else w:Disable() end
    end
    if w.EnableMouse then pcall(w.EnableMouse, w, on) end   -- (home-made slider)
    w:SetAlpha(on and 1 or 0.5)
    if label then label:SetFontObject(on and "GameFontNormal" or "GameFontDisable") end
end

-- a dropdown's values (key -> label) and their order, from a { key, label } list
function UI.Choices(list)
    local values, order = {}, {}
    for _, t in ipairs(list) do
        values[t.key] = t.label
        order[#order + 1] = t.key
    end
    return values, order
end

-- The EllesmereUI widget config for a toggle, slider, dropdown or colour mode
-- (a DualRow half); the widgets on Blizzard's options page use its get/set too.
function UI.NativeCfg(item)
    if item.type == "color" then
        local key = item.key
        local values, order = UI.Choices(ColorModeChoices())
        return { type = "dropdown", text = item.label, values = values, order = order,
            getValue = function() return ColorMode(key) end,
            setValue = function(v) SetStyle(key .. "Mode", v); RefreshEUIPage() end }
    end
    if item.type == "toggle" then
        return { type = "toggle", text = item.label, getValue = item.get, setValue = item.set }
    end
    -- a style value, unless the item brings its own get / set
    local get = item.get or function() return Style(item.key) end
    local set = item.set or function(v) SetStyle(item.key, v) end
    if item.type == "range" then
        return { type = "slider", text = item.label, min = item.min, max = UI.Num(item.max), step = item.step,
            getValue = get, setValue = set }
    end
    local values, order = UI.Choices(item.list())
    return { type = "dropdown", text = item.label, values = values, order = order, getValue = get, setValue = set }
end

-- Builds one section into parent, starting at y0 (negative = down), and returns
-- the y below its last row. native: parent is an EllesmereUI page, so its own
-- widgets are used (any that fail fall back to ours).
function BuildPage(parent, group, x0, y0, native)
    local y = y0
    parent.amRefreshers = parent.amRefreshers or {}
    local refreshers = parent.amRefreshers
    local W = native and EllesmereUI and EllesmereUI.Widgets or nil
    -- one EllesmereUI widget: returns its height and frame, or nil when it could not be made
    local function Native(name, ...)
        if not (W and W[name]) then return nil end
        local ok, f, h = pcall(W[name], W, parent, ...)
        if ok and f then return (type(h) == "number") and h or 50, f end
        return nil
    end
    local headerH = Native("SectionHeader", group.name:upper(), y)
    if headerH then
        y = y - headerH
    else
        -- as a subsection heading on Blizzard's options pages: large white text
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", x0, y - 10)
        title:SetText(Loc(group.name))
        y = y - 40
    end
    local items = {}
    -- (items may be a function: a list made when the page is built)
    local groupItems = type(group.items) == "function" and group.items() or group.items
    for _, item in ipairs(groupItems) do
        if item.when and not item.when() then
            -- not shown with the current look
        elseif item.type == "eui" or ((item.type == "row" or item.type == "choicepairs") and W) then
            -- (EllesmereUI's page pairs a row's items, and dropdowns, by itself)
            if item.type ~= "eui" or EllesmereUI then
                for _, sub in ipairs(item.items) do items[#items + 1] = sub end
            end
        else
            items[#items + 1] = item
        end
    end
    -- as on Blizzard's options pages: gold labels indented under the heading,
    -- every control in one column further right
    -- (a narrow page, beside a preview column, sets parent.amNarrow: controls
    -- start sooner and the wide rows are more compact)
    local lx = native and x0 or x0 + 30
    local ctlX = native and x0 + 190 or x0 + (parent.amNarrow and 170 or 240)

    -- one item on a row of its own; returns the row's height
    local function BuildItem(item)
        local rowH
        if item.type == "toggle" then
            rowH = Native("Toggle", item.label, y, item.get, item.set)
            if not rowH then
                MakeLabel(parent, item.label, lx, y - 2)
                refreshers[#refreshers + 1] = MakeToggle(parent, ctlX, y, item.get, item.set).refresh
            end
        elseif item.type == "color" then
            local key = item.key
            -- mode on the left, the custom colour on the right; picking a
            -- colour there switches the mode to Custom
            rowH = Native("DualRow", y, UI.NativeCfg(item),
                { type = "colorpicker", text = Loc("Custom color"), hasAlpha = item.alpha,
                  getValue = function() local c = Style(key); return c[1], c[2], c[3], c[4] or 1 end,
                  setValue = function(r, g, b, a)
                      SetColor(key, r, g, b, item.alpha and a or nil)
                      RefreshEUIPage()
                  end })
            if not rowH then
                MakeLabel(parent, item.label, lx, y - 2)
                refreshers[#refreshers + 1] = MakeColor(parent, ctlX, y, key, item.alpha).refresh
            end
        elseif item.type == "range" then
            local c = UI.NativeCfg(item)
            rowH = Native("Slider", item.label, y, c.min, c.max, c.step, c.getValue, c.setValue)
            if not rowH then
                local fs = MakeLabel(parent, item.label, lx, y - 2)
                -- as wide as a color row, so its value lines up with the opacity values
                local s = MakeSlider(parent, ctlX, y, RowLayout(parent).fullW, c.min, c.max, c.step,
                    c.getValue, c.setValue, item.fmt)
                refreshers[#refreshers + 1] = s.refresh
                if item.disabled then   -- greyed out while it does not apply
                    local function update() UI.SetWidgetEnabled(s, fs, not item.disabled()) end
                    update()
                    refreshers[#refreshers + 1] = update
                end
            end
        elseif item.type == "choice" then
            local c = UI.NativeCfg(item)
            rowH = Native("Dropdown", item.label, y, c.values, c.getValue, c.setValue, c.order)
            if not rowH then
                MakeLabel(parent, item.label, lx, y - 2)
                refreshers[#refreshers + 1] = MakeChoice(parent, ctlX, y, 150, item.list, c.getValue, c.setValue).refresh
            end
        elseif item.type == "button" then
            local function after()
                if item.refreshAll then RefreshOptions() end
            end
            rowH = Native("Button", item.label, y, function() item.action(nil); after() end)
            if not rowH then
                local b
                b = MakeButton(parent, lx, y, 170, item.label, function() item.action(b); after() end)
                rowH = 30
            end
        elseif item.type == "row" then
            -- a checkbox and a slider side by side: "Label [x]   Label <slider>"
            local a, s = item.items[1], item.items[2]
            MakeLabel(parent, a.label, lx, y - 2)
            refreshers[#refreshers + 1] = MakeToggle(parent, ctlX, y, a.get, a.set).refresh
            -- its slider where a color row's opacity slider is, the same width
            local L = RowLayout(parent)
            MakeLabel(parent, s.label, ctlX + 40, y - 2, L.shortX - 40)
            local c = UI.NativeCfg(s)
            refreshers[#refreshers + 1] = MakeSlider(parent, ctlX + L.shortX, y, L.shortW,
                c.min, c.max, c.step, c.getValue, c.setValue).refresh
        elseif item.type == "text" then
            local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", lx, y - 4)
            fs:SetWidth((parent:GetWidth() or UI.CONTENT_W) - lx - 20)
            fs:SetJustifyH("LEFT")
            refreshers[#refreshers + 1] = function() fs:SetText(Loc(item.text())) end
            fs:SetText(Loc(item.text()))
            rowH = item.height or 70
        elseif item.type == "choicepairs" then
            -- dropdowns two to a row: "Label <dropdown>   Label <dropdown>"
            local pw = (parent:GetWidth() or 0) > 0 and parent:GetWidth() or UI.CONTENT_W
            local colW = math.floor((pw - lx - 10) / 2)
            local labelW = math.floor(colW * 0.48)
            local h = 0
            for i, sub in ipairs(item.items) do
                local col = (i - 1) % 2
                local cx = lx + col * colW
                MakeLabel(parent, sub.label, cx, y - h - 2, labelW)
                local c = UI.NativeCfg(sub)
                refreshers[#refreshers + 1] = MakeChoice(parent, cx + labelW + 4, y - h,
                    colW - labelW - 44, sub.list, c.getValue, c.setValue).refresh
                if col == 1 or i == #item.items then h = h + ROW end
            end
            rowH = h
        elseif item.type == "customrows" then
            -- your own buttons, one row each (Custom.lua)
            local w = (parent:GetWidth() or 0) > 0 and parent:GetWidth() or UI.CONTENT_W
            rowH = y - UI.BuildCustomRows(parent, w, lx, y, refreshers)
        elseif item.type == "buttongrid" then
            -- three checkboxes to a row
            local h = 0
            for i = 1, #item.entries, 3 do
                local cfgs = {}
                for j = 0, 2 do
                    local e = item.entries[i + j]
                    if e then
                        cfgs[j + 1] = { type = "toggle", text = UI.Name(e) .. (e.custom and " (custom)" or ""),
                            getValue = function() return Enabled(e) end,
                            setValue = function(v) UI.SetEnabled(e, v) end }
                    end
                end
                local th = Native("TripleRow", y - h, cfgs[1], cfgs[2], cfgs[3], { 0.34, 0.33 })
                if not th then
                    for j = 0, 2 do
                        local e = item.entries[i + j]
                        if e then
                            local x = lx + j * 170
                            refreshers[#refreshers + 1] = MakeToggle(parent, x, y - h,
                                function() return Enabled(e) end, function(v) UI.SetEnabled(e, v) end).refresh
                            local fs = MakeLabel(parent, "", x + 26, y - h - 2, 138)
                            -- "(3 available)" while it is off and you carry or can make some
                            local function label()
                                local n = UI.CouldUse(e)
                                fs:SetText(Loc(UI.Name(e) .. (e.custom and " (custom)" or ""))
                                    .. (n > 0 and (" " .. UI.HAVE_COLOR .. "(" .. n .. " available)|r") or ""))
                            end
                            label()
                            refreshers[#refreshers + 1] = label
                        end
                    end
                    th = ROW
                end
                h = h + th
            end
            rowH = h
        end
        return rowH or ROW
    end

    local i = 1
    while i <= #items do
        local item, nxt = items[i], items[i + 1]
        local rowH
        if W and UI.Pairable(item) and nxt and UI.Pairable(nxt) then
            local row
            rowH, row = Native("DualRow", y, UI.NativeCfg(item), UI.NativeCfg(nxt))
            if rowH then
                UI.InlineSwatch(row and row._leftRegion, item)
                UI.InlineSwatch(row and row._rightRegion, nxt)
                i = i + 1
            end
        end
        rowH = rowH or BuildItem(item)
        y = y - rowH
        i = i + 1
    end
    parent.amRefresh = function()
        for _, f in ipairs(refreshers) do f() end
    end
    return y
end

-- ---- Blizzard's settings: Esc > Options > AddOns > AutoMacros ----
-- One canvas page per tab in the game's own options window, nested in its tree
-- under AutoMacros (which opens the first tab): a fixed-height preview strip,
-- then the settings, built from Blizzard's widgets. /amac options opens it (or
-- EllesmereUI's page while that is installed).
UI.CONTENT_W = 560
UI.SIDE_W, UI.LEFT_W = 120, 480   -- a page with its preview in a right-hand column
UI.panels = {}   -- per tab: { frame, host (preview strip), scroll, content, built }

function UI.ShowPanel(i)
    local pn, page = UI.panels[i], PAGES[i]
    if pn.content.amNarrow then   -- a side column: as tall as the page
        pn.host.fixedH = math.max(100, pn.host:GetHeight() or 0)
    end
    if page.header then UI.ShowHeader(page.header, pn.host, pn.host:GetWidth()) end
    local stamp = page.stamp and page.stamp() or nil
    if pn.built and stamp ~= pn.stamp then
        -- what the page lists has changed: build it again on a fresh sheet
        pn.content:Hide()
        local content = CreateFrame("Frame", nil, pn.scroll)
        content:SetSize(pn.width, 10)
        content.amNarrow = pn.content.amNarrow
        pn.scroll:SetScrollChild(content)
        pn.content, pn.built = content, false
    end
    if not pn.built then
        pn.built, pn.stamp = true, stamp
        local y = 0
        if page.build then
            local ok, h = pcall(page.build, pn.content, pn.width)
            if ok then y = h else Fail(page.name .. " page", h) end
        end
        for _, section in ipairs(UI.PageSections(page)) do
            y = BuildPage(pn.content, section, 0, y, false) - 10
        end
        pn.content:SetHeight(math.max(1, -y))
    end
    pn.scroll:SetVerticalScroll(0)
    if pn.content.amRefresh then pn.content.amRefresh() end
    -- the scroll bar only if needed, once the page has its size
    UI.FitScroll(pn)
    if C_Timer and C_Timer.After then C_Timer.After(0, function() UI.FitScroll(pn) end) end
end

-- a scrolling area under host, or left of it with side: Blizzard's scroll
-- frame with its scroll bar, content width wide
function UI.MakeScroll(p, host, side, width)
    local scroll = Template("ScrollFrame", p, "ScrollFrameTemplate")
        or Template("ScrollFrame", p, "UIPanelScrollFrameTemplate", true)
    if not scroll then
        scroll = CreateFrame("ScrollFrame", nil, p)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            local v = math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 40))
            self:SetVerticalScroll(v)
        end)
    end
    if side then
        scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -50)
        scroll:SetPoint("BOTTOMRIGHT", host, "BOTTOMLEFT", -30, 0)
    else
        scroll:SetPoint("TOPLEFT", host, "BOTTOMLEFT", 0, -8)
        scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -30, 10)
    end
    -- no scroll bar while everything fits (Blizzard's scroll frames read these
    -- whenever the scroll range changes; retail's and the older one's names)
    scroll.scrollBarHideIfUnscrollable, scroll.scrollBarHideable = true, true
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(width, 10)
    content.amNarrow = side or nil   -- (BuildPage lays a narrow page out more compactly)
    scroll:SetScrollChild(content)
    return scroll, content
end

-- Shows the page's scroll bar only when its settings do not fit (also done
-- here, in case a client ignores the flags above).
function UI.FitScroll(pn)
    local bar = pn.scroll.ScrollBar or (pn.scroll:GetName() and _G[pn.scroll:GetName() .. "ScrollBar"])
    if not bar then return end
    local fits = (pn.content:GetHeight() or 0) <= (pn.scroll:GetHeight() or 0) + 1
    bar:SetShown(not fits)
end

-- the canvas page for tab i (the first is AutoMacros itself)
function UI.MakePanel(i)
    local page = PAGES[i]
    local p = CreateFrame("Frame", "AutoMacrosOptions" .. i)   -- the options window sizes and shows it
    p.name = (i == 1) and "AutoMacros" or Loc(page.name)        -- (the older options window reads
    if i > 1 then p.parent = "AutoMacros" end                   -- name and parent)
    local ok, title = pcall(p.CreateFontString, p, nil, "ARTWORK", "GameFontHighlightHuge")
    if not ok or not title then title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge") end
    title:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -15)
    title:SetText(p.name)
    -- The preview keeps its size whatever the settings do (see UI.FitHeader):
    -- a strip on top, or with previewSide a column on the right, settings left.
    local side = page.header and page.previewSide == "right"
    local host = CreateFrame("Frame", nil, p)
    if side then
        -- the preview's note across the bottom of the page, under both columns
        local note = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        note:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 14, 12)
        note:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -14, 12)
        note:SetJustifyH("CENTER")
        note:SetText(Loc(UI.FLYOUT_NOTE))
        host.noteBelow = true
        host:SetPoint("TOPRIGHT", p, "TOPRIGHT", -14, -50)
        host:SetPoint("BOTTOMRIGHT", note, "TOPRIGHT", 0, 10)
        host:SetWidth(UI.SIDE_W)
    else
        host:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -50)
        host:SetSize(UI.CONTENT_W, page.header and page.previewH or 1)
    end
    host.fixedH = page.header and page.previewH or nil
    local width = side and UI.LEFT_W or UI.CONTENT_W
    local scroll, content = UI.MakeScroll(p, host, side, width)
    UI.panels[i] = { frame = p, host = host, scroll = scroll, content = content, width = width }
    p:SetScript("OnShow", function() UI.ShowPanel(i) end)
    p:Hide()
    return p
end

-- Adds the pages to the game's options window, once.
function UI.RegisterBlizzPanel()
    if UI.blizzRegistered then return end
    UI.blizzRegistered = true
    for i in ipairs(PAGES) do UI.MakePanel(i) end
    local main = UI.panels[1].frame
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, main, "AutoMacros")
        if ok and cat then
            for i = 2, #PAGES do
                pcall(Settings.RegisterCanvasLayoutSubcategory, cat, UI.panels[i].frame, UI.panels[i].frame.name)
            end
            pcall(Settings.RegisterAddOnCategory, cat)
            UI.blizzCategory = cat
            return
        end
    end
    if InterfaceOptions_AddCategory then
        for _, pn in ipairs(UI.panels) do pcall(InterfaceOptions_AddCategory, pn.frame) end
    end
end

-- the settings on whichever of our pages is on screen
function UI.RefreshPanels()
    for _, pn in ipairs(UI.panels) do
        if pn.frame:IsVisible() and pn.content.amRefresh then pn.content.amRefresh() end
    end
end

-- Brings everything on screen up to date after a change made elsewhere.
RefreshOptions = function()
    UI.RefreshPanels()
    RefreshHeaders()
    RefreshEUIPage()
end

-- after a style change: our pages and the previews (EllesmereUI refreshes its own)
StyleOptions = function()
    RefreshHeaders()
    UI.RefreshPanels()
end

-- after every update (bags changed, items sorted): the "in bags" counts on
-- whichever of our pages is open (both only touch what is on screen)
report.afterUpdate = function()
    UI.RefreshPanels()
    RefreshHeaders()
    if UI.RefreshWelcome then pcall(UI.RefreshWelcome) end   -- (the welcome window, if open)
end

-- ---- EllesmereUI: a page in its settings, and its look for the popup ----
-- Only the published EllesmereUI interfaces are used (RegisterSkin and
-- RegisterPlugin); everything is wrapped so a change on their side cannot
-- break this addon.
UI.skinRegistered, UI.pluginRegistered = false, false
