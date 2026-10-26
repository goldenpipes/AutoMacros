-- AutoMacros: Settings widgets: checkboxes, sliders, dropdowns, colour rows, buttons.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---- small widgets ----
-- Blizzard's own (checkbox, slider, dropdown, button), so the settings look
-- like the game's. A client without one of those templates gets a plain
-- home-made widget instead. Each is placed by its left middle on the row's
-- middle (y - 8, the middle of a label set at y - 2), so it lines up with its text.
ROW = 36

-- CreateFrame with a template, or nil when this client lacks it. named: some
-- older templates find their parts by the frame's global name.
-- (Template)
do
    local count = 0
    Template = function(kind, parent, template, named)
        count = count + 1
        local name = named and ("AutoMacrosWidget" .. count) or nil
        local ok, f = pcall(CreateFrame, kind, name, parent, template)
        if ok and f then return f end
        return nil
    end
end

function MakeLabel(parent, text, x, y, w)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")   -- gold, as Blizzard's option labels
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(w or 180)
    fs:SetJustifyH("LEFT")
    fs:SetText(Loc(text))
    return fs
end

function Box(b)   -- grey outline with a dark inside
    local edge = b:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints()
    edge:SetColorTexture(0.5, 0.5, 0.5, 1)
    local inner = b:CreateTexture(nil, "BORDER")
    inner:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    inner:SetColorTexture(0.05, 0.05, 0.05, 1)
    return inner
end

function MakeToggle(parent, x, y, get, set)
    local cb = Template("CheckButton", parent, "UICheckButtonTemplate")
    if cb then
        cb:SetSize(26, 26)
        cb:SetPoint("LEFT", parent, "TOPLEFT", x - 4, y - 8)
        cb.refresh = function() cb:SetChecked(get() and true or false) end
        cb:SetScript("OnClick", function(self)
            set(self:GetChecked() and true or false)
            if PlaySound and SOUNDKIT then
                pcall(PlaySound, self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
                    or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            end
        end)
        cb.refresh()
        return cb
    end
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(18, 18)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    Box(b)
    local tick = b:CreateTexture(nil, "ARTWORK")
    tick:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
    tick:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
    b.refresh = function()
        local r, g, bl = AccentRGB()
        tick:SetColorTexture(r, g, bl, 1)
        if get() then tick:Show() else tick:Hide() end
    end
    b:SetScript("OnClick", function() set(not get()); b.refresh() end)
    b.refresh()
    return b
end

-- fmt: how the value is shown (default by step: 3, 0.3, 0.25)
function MakeSlider(parent, x, y, width, min, max, step, get, set, fmt)
    fmt = fmt or (step >= 1) and "%d" or (step >= 0.1) and "%.1f" or "%.2f"
    local function snap(v) return tonumber(string.format("%.4f", math.floor(v / step + 0.5) * step)) end
    -- retail's (and newer classic's) slider with - and + steppers
    local M = MinimalSliderWithSteppersMixin
    local ms = M and Template("Frame", parent, "MinimalSliderWithSteppersTemplate")
    if ms then
        local ok = pcall(function()
            ms:SetWidth(width + 30)
            ms:SetPoint("LEFT", parent, "TOPLEFT", x, y - 8)
            local show = function(v) return string.format(fmt, v) end
            local formatters = { [M.Label.Right] = CreateMinimalSliderFormatter
                and CreateMinimalSliderFormatter(M.Label.Right, show) or show }
            ms:Init(tonumber(get()) or min, min, max, math.max(1, math.floor((max - min) / step + 0.5)), formatters)
            ms:RegisterCallback(M.Event.OnValueChanged, function(_, v)
                v = snap(v)
                if ms.quiet or v == ms.last then return end
                ms.last = v
                set(v)
            end, ms)
        end)
        if ok then
            ms.refresh = function()
                local v = tonumber(get()) or min
                ms.last, ms.quiet = v, true
                pcall(ms.SetValue, ms, v)
                ms.quiet = nil
            end
            ms.refresh()
            return ms
        end
        ms:Hide()
    end
    -- older clients' options slider
    local old = Template("Slider", parent, "OptionsSliderTemplate", true)
    if old then
        old:SetWidth(width)
        old:SetPoint("LEFT", parent, "TOPLEFT", x, y - 8)
        old:SetMinMaxValues(min, max)
        old:SetValueStep(step)
        pcall(old.SetObeyStepOnDrag, old, true)
        for _, part in ipairs({ "Low", "High", "Text" }) do
            local r = _G[old:GetName() .. part]
            if r then r:SetText("") end
        end
        local value = old:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetPoint("LEFT", old, "RIGHT", 8, 0)
        old:SetScript("OnValueChanged", function(self, v)
            v = snap(v)
            value:SetText(string.format(fmt, v))
            if self.quiet or v == self.last then return end
            self.last = v
            set(v)
        end)
        old.refresh = function()
            local v = tonumber(get()) or min
            old.last, old.quiet = v, true
            old:SetValue(v)
            old.quiet = nil
            value:SetText(string.format(fmt, v))
        end
        old.refresh()
        return old
    end
    local s = CreateFrame("Frame", nil, parent)
    s:SetSize(width, 18)
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:EnableMouse(true)
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", s, "LEFT", 0, 0)
    track:SetPoint("RIGHT", s, "RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.25, 0.25, 0.25, 1)
    local fill = s:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", s, "LEFT", 0, 0)
    fill:SetHeight(4)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 14)
    local value = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("LEFT", s, "RIGHT", 8, 0)
    local function paint(v)
        local frac = (max > min) and (v - min) / (max - min) or 0
        if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
        local r, g, b = AccentRGB()
        fill:SetColorTexture(r, g, b, 1)
        fill:SetWidth(math.max(1, frac * width))
        thumb:SetColorTexture(1, 1, 1, 1)
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", s, "LEFT", frac * width, 0)
        value:SetText(string.format(fmt, v))
    end
    local function fromCursor()
        local scale = s:GetEffectiveScale() or 1
        local cx = (GetCursorPosition() or 0) / scale
        local frac = (cx - (s:GetLeft() or 0)) / width
        if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
        local v = snap(min + frac * (max - min))
        if v < min then v = min elseif v > max then v = max end
        paint(v)
        if v ~= s.last then
            s.last = v
            set(v)
        end
    end
    s:SetScript("OnMouseDown", function(self) self.drag = true; fromCursor() end)
    s:SetScript("OnMouseUp", function(self) self.drag = nil end)
    s:SetScript("OnHide", function(self) self.drag = nil end)
    s:SetScript("OnUpdate", function(self)
        if not self.drag then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then self.drag = nil return end
        fromCursor()
    end)
    s.refresh = function()
        local v = tonumber(get()) or min
        s.last = v
        paint(v)
    end
    s.refresh()
    return s
end

-- the colour picker differs between client versions, so both forms are handled
function PickColor(r, g, b, onChange, onCancel)
    local function read()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        onChange(nr, ng, nb)
    end
    local function cancel()
        if onCancel then onCancel() else onChange(r, g, b) end
    end
    pcall(function() ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG") end)
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false, swatchFunc = read, cancelFunc = cancel })
    else
        ColorPickerFrame.func = read
        ColorPickerFrame.cancelFunc = cancel
        ColorPickerFrame.opacityFunc = nil
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = { r = r, g = g, b = b }
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

-- (MakeChoice: defined below)

-- Where the parts of a row go, from the control column, so every value lines up:
-- a color's mode dropdown (dropW), then its swatch, then a short slider (at
-- shortX, shortW wide: opacity, Close delay); full sliders run from the column
-- to where the short ones end (fullW). Narrower beside a preview column.
function RowLayout(parent)
    local narrow = parent.amNarrow
    local dropW = narrow and 90 or 100
    local shortX, shortW = dropW + 40, narrow and 60 or 80
    return { dropW = dropW, shortX = shortX, shortW = shortW, fullW = shortX + shortW }
end

-- One colour setting: a box that cycles Default / EllesmereUI accent / Custom,
-- a swatch with the colour in use (clicking it picks a custom colour) and, for
-- colours that can be see-through, an opacity slider.
function MakeColor(parent, x, y, key, hasAlpha)
    local b
    local L = RowLayout(parent)
    local dw = L.dropW
    local mode = MakeChoice(parent, x, y, dw, ColorModeChoices,
        function() return ColorMode(key) end,
        function(v) SetStyle(key .. "Mode", v); if b then b.refresh() end end)
    -- the swatch Blizzard uses for chat colors: a white-edged square in the color
    b = CreateFrame("Button", nil, parent)
    b:SetSize(22, 22)
    b:SetPoint("LEFT", parent, "TOPLEFT", x + dw + 8, y - 8)
    local edge = b:CreateTexture(nil, "BACKGROUND")
    edge:SetSize(18, 18)
    edge:SetPoint("CENTER", b, "CENTER", 0, 0)
    edge:SetColorTexture(1, 1, 1, 1)
    local sw = b:CreateTexture(nil, "ARTWORK")
    sw:SetAllPoints()
    sw:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    local alpha
    b.refresh = function()
        mode.refresh()
        local c = StyleColor(key)
        sw:SetVertexColor(c[1], c[2], c[3], 1)
        if alpha then alpha.refresh() end
    end
    b:SetScript("OnClick", function()
        local c = StyleColor(key)
        local s = DB().style
        local oldValue = type(s) == "table" and s[key] or nil
        local oldMode = type(s) == "table" and s[key .. "Mode"] or nil
        local ok, err = pcall(PickColor, c[1], c[2], c[3], function(r, g, bl)
            SetColor(key, r, g, bl)
            b.refresh()
        end, function()   -- cancelled: put back what was saved before
            SetStyle(key, oldValue)
            SetStyle(key .. "Mode", oldMode)
            b.refresh()
        end)
        if not ok then Fail("color picker", err) end
    end)
    if hasAlpha then
        alpha = MakeSlider(parent, x + L.shortX, y, L.shortW, 0, 1, 0.05,
            function() return Style(key)[4] or 1 end,
            function(v)
                PinMode(key)
                local c = Style(key)
                SetStyle(key, { c[1], c[2], c[3], v })
            end)
    end
    b.refresh()
    return b
end

MakeChoice = function(parent, x, y, width, list, get, set)
    local function labelOf()
        for _, t in ipairs(list()) do
            if t.key == get() then return t.label end
        end
        return "?"
    end
    -- retail's dropdown menu
    local dd = Template("DropdownButton", parent, "WowStyle1DropdownTemplate")
    if dd and dd.SetupMenu then
        dd:SetWidth(width)
        dd:SetPoint("LEFT", parent, "TOPLEFT", x, y - 8)
        dd:SetupMenu(function(_, root)
            for _, t in ipairs(list()) do
                root:CreateRadio(t.label, function() return get() == t.key end, function() set(t.key) end, t.key)
            end
        end)
        dd.refresh = function() pcall(dd.GenerateMenu, dd) end
        return dd
    end
    if dd then dd:Hide() end
    -- older clients' dropdown
    local old = UIDropDownMenu_Initialize and Template("Frame", parent, "UIDropDownMenuTemplate", true)
    if old then
        old:SetPoint("LEFT", parent, "TOPLEFT", x - 16, y - 8)
        pcall(UIDropDownMenu_SetWidth, old, width)
        old.refresh = function() pcall(UIDropDownMenu_SetText, old, labelOf()) end
        UIDropDownMenu_Initialize(old, function()
            for _, t in ipairs(list()) do
                local info = UIDropDownMenu_CreateInfo()
                info.text, info.checked = t.label, get() == t.key
                info.func = function() set(t.key); old.refresh() end
                UIDropDownMenu_AddButton(info)
            end
        end)
        old.refresh()
        return old
    end
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 18)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    Box(b)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local function index(l)
        local cur = get()
        for i, v in ipairs(l) do
            if v.key == cur then return i end
        end
        return 1
    end
    b.refresh = function()
        local l = list()
        local v = l[index(l)]
        fs:SetText(v and v.label or "?")
    end
    b:SetScript("OnClick", function(self, button)
        local l = list()
        local i = index(l)
        if button == "RightButton" then
            i = i - 1
            if i < 1 then i = #l end
        else
            i = i + 1
            if i > #l then i = 1 end
        end
        set(l[i].key)
        self.refresh()
    end)
    b.refresh()
    return b
end

function MakeButton(parent, x, y, width, text, onClick)
    local pb = Template("Button", parent, "UIPanelButtonTemplate")
    if pb then
        pb:SetSize(width, 22)
        pb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        pb:SetText(Loc(text))
        pb:SetScript("OnClick", onClick)
        return pb
    end
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 22)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local inner = Box(b)
    inner:SetColorTexture(0.15, 0.15, 0.15, 1)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    fs:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end
