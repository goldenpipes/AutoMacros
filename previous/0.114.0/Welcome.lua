-- AutoMacros: the welcome window, shown once on a character's first login
-- (/amac welcome shows it again): what the addon does, the buttons it turned
-- on for you (drag them onto your bars), every button to switch on or off,
-- and the way to the settings.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

UI.WELCOME_W = 560
UI.WELCOME_ICON, UI.WELCOME_GAP = 36, 6

-- Characters seen are saved in db.welcomed[char] = true. A character that
-- already had AutoMacros settings before this window existed counts as
-- welcomed (looked at once, at login, before anything is saved for it).
function UI.WelcomeDue()
    local db, char = DB(), CharKey()
    if type(db.welcomed) ~= "table" then db.welcomed = {} end
    if db.welcomed[char] then return false end
    for _, t in ipairs({ db.enabledBy, db.picks, db.idx }) do
        if type(t) == "table" and type(t[char]) == "table" and next(t[char]) then
            db.welcomed[char] = true
            return false
        end
    end
    return true
end

-- the buttons on for this character that have something to use now
function UI.WelcomeReady()
    local list = {}
    for _, e in ipairs(UI.AvailableButtons()) do
        if Enabled(e) and report.have then
            local ok, n = pcall(UI.Available, e, report.have)
            if ok and n > 0 then list[#list + 1] = e end
        end
    end
    return list
end

-- every button but your own (those are made on the Buttons page), grouped and
-- ordered as on the Buttons page
function UI.WelcomeButtons()
    local list = {}
    for _, section in ipairs(UI.ButtonSections()) do
        for _, item in ipairs(section.items) do
            for _, e in ipairs(item.entries or {}) do list[#list + 1] = e end
        end
    end
    return list
end

-- The window: Blizzard's framed window where the client has it, else a plain
-- dark one. Escape closes it; closing it in any way counts as seen.
function UI.WelcomeFrame()
    if UI.welcome then return UI.welcome end
    -- (named, so Escape can close it: UISpecialFrames holds names)
    local ok, f = pcall(CreateFrame, "Frame", "AutoMacrosWelcome", UIParent, "BasicFrameTemplateWithInset")
    if not ok or not f then
        f = CreateFrame("Frame", "AutoMacrosWelcome", UIParent)
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.05, 0.92)
        local close = Template("Button", f, "UIPanelCloseButton")
        if close then close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0) end
    end
    f:SetSize(UI.WELCOME_W, 400)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnHide", function()
        local db = DB()
        if type(db.welcomed) ~= "table" then db.welcomed = {} end
        db.welcomed[CharKey()] = true
    end)
    if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "AutoMacrosWelcome") end
    local title = f.TitleText or (f.TitleContainer and f.TitleContainer.TitleText)
    if not title then
        title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", f, "TOP", 0, -8)
    end
    title:SetText(Loc("Welcome to AutoMacros"))

    local x, w = 20, UI.WELCOME_W - 40
    local intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", f, "TOPLEFT", x, -36)
    intro:SetWidth(w)
    intro:SetJustifyH("LEFT")
    intro:SetText(Loc("AutoMacros makes a macro for each kind of consumable (health potions, food, water, bandages,"
        .. " buffs and more) and keeps it on the best one in your bags. Put the buttons on your action bars once;"
        .. " they fill themselves as you loot and use things. Hover one on your bar to pick another item from its popout."))
    f.intro = intro

    f.readyHead = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.readyHead:SetText(Loc("Ready for you"))
    f.readyNote = UI.SmallText(f, "")
    f.readyNote:SetWidth(w)
    f.readyNote:SetJustifyH("LEFT")
    f.icons = {}

    f.pickHead = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.pickHead:SetText(Loc("Your buttons"))
    f.pickNote = UI.SmallText(f, "Tick the ones you want. Buttons also switch on by themselves the first time you carry"
        .. " something for them.")
    f.pickNote:SetWidth(w)
    f.pickNote:SetJustifyH("LEFT")
    f.toggles = {}

    f.settings = MakeButton(f, x, 0, 140, "Open settings", function()
        f:Hide()
        local ok, err = pcall(OpenOptions)
        if not ok then Fail("options window", err) end
    end)
    f.done = MakeButton(f, UI.WELCOME_W - 20 - 100, 0, 100, "Got it", function() f:Hide() end)
    f:Hide()
    UI.welcome = f
    return f
end

-- Lays the window out again: the icons of the buttons ready to use, the
-- checkboxes (built once, refreshed after), the buttons at the bottom.
function UI.RefreshWelcome()
    local f = UI.welcome
    if not (f and f:IsShown()) then return end
    local x, w = 20, UI.WELCOME_W - 40
    local size, gap = UI.WELCOME_ICON, UI.WELCOME_GAP
    local y = -36 - math.max(40, (f.intro:GetStringHeight() or 40)) - 16

    f.readyHead:ClearAllPoints()
    f.readyHead:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    y = y - 26
    local ready = UI.WelcomeReady()
    if #ready > 0 then
        f.readyNote:SetText(Loc("Drag these onto your action bars."))
    else
        f.readyNote:SetText(Loc("Nothing in your bags fits a button yet. Tick the ones you want below, or pick some"
            .. " consumables up: their buttons appear on their own."))
    end
    f.readyNote:ClearAllPoints()
    f.readyNote:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    y = y - math.max(14, (f.readyNote:GetStringHeight() or 12)) - 8
    local perRow = math.max(1, math.floor((w + gap) / (size + gap)))
    for i, e in ipairs(ready) do
        local b = f.icons[i]
        if not b then
            b = UI.SampleButton(f, size)
            b:RegisterForDrag("LeftButton")
            b:SetScript("OnDragStart", function(self) UI.PickUp(self.entry) end)
            b:SetScript("OnClick", function(self) UI.PickUp(self.entry) end)
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(self.entry.title)
                local ok, n, parts = pcall(UI.Available, self.entry, report.have)
                if ok then GameTooltip:AddLine(UI.AvailableText(n, parts), 0.25, 1, 0.25) end
                GameTooltip:AddLine(Loc("Drag onto an action bar to place it"), 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            f.icons[i] = b
        end
        b.entry = e
        b.icon:SetTexture(UI.CategoryIcon(e))
        UI.StyleSample(b)
        local row, col = math.floor((i - 1) / perRow), (i - 1) % perRow
        BLIZZ_ART.Point(b, "TOPLEFT", f, "TOPLEFT", x + col * (size + gap), y - row * (size + gap))
        b:Show()
    end
    for i = #ready + 1, #f.icons do f.icons[i]:Hide() end
    if #ready > 0 then y = y - math.ceil(#ready / perRow) * (size + gap) - 6 end
    y = y - 10

    f.pickHead:ClearAllPoints()
    f.pickHead:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    y = y - 26
    f.pickNote:ClearAllPoints()
    f.pickNote:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    y = y - math.max(14, (f.pickNote:GetStringHeight() or 12)) - 10
    -- three to a row; built the first time (the list only changes with your class)
    if not f.toggled then
        f.toggled = true
        local colW = math.floor(w / 3)
        for i, e in ipairs(UI.WelcomeButtons()) do
            local row, col = math.floor((i - 1) / 3), (i - 1) % 3
            local tx, ty = x + col * colW, y - row * 28
            local cb = MakeToggle(f, tx + 4, ty, function() return Enabled(e) end, function(v) UI.SetEnabled(e, v) end)
            local fs = MakeLabel(f, "", tx + 30, ty - 2, colW - 34)
            f.toggles[#f.toggles + 1] = { e = e, cb = cb, fs = fs, tx = tx, row = row }
        end
    end
    -- placed again each time: the icons above take more or less room
    for _, t in ipairs(f.toggles) do
        local ty = y - t.row * 28
        t.cb:ClearAllPoints()
        t.cb:SetPoint("LEFT", f, "TOPLEFT", t.tx, ty - 8)
        t.fs:ClearAllPoints()
        t.fs:SetPoint("TOPLEFT", f, "TOPLEFT", t.tx + 30, ty - 2)
        if t.cb.refresh then t.cb.refresh() end
        local n = UI.CouldUse(t.e)
        t.fs:SetText(Loc(UI.Name(t.e)) .. (n > 0 and (" " .. UI.HAVE_COLOR .. "(" .. n .. ")|r") or ""))
    end
    local rows = math.ceil(#f.toggles / 3)
    y = y - rows * 28 - 16

    f.settings:ClearAllPoints()
    f.settings:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    f.done:ClearAllPoints()
    f.done:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, y)
    f:SetHeight(-y + 22 + 14)
end

function UI.ShowWelcome()
    local f = UI.WelcomeFrame()
    f:Show()
    UI.RefreshWelcome()
    -- (string heights are only right once shown: lay it out again a frame later)
    if C_Timer and C_Timer.After then C_Timer.After(0, function() pcall(UI.RefreshWelcome) end) end
end
