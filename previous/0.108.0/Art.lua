-- AutoMacros: How things look: Blizzard's / EllesmereUI's button art, the highlight,
-- the popout indicator, the popout's bar art.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- ---- action button art, shared by the popup items and the settings demos ----
-- Blizzard's own textures, used when EllesmereUI is not drawing the buttons.
BLIZZ_ART = {
    frame = "Interface\\Buttons\\UI-Quickslot2",
    hover = { kind = "tex", path = "Interface\\Buttons\\ButtonHilight-Square", blend = "ADD", r = 1, g = 1, b = 1 },
    push = { kind = "tex", path = "Interface\\Buttons\\UI-Quickslot-Depress", r = 1, g = 1, b = 1 },
    borderPx = { none = 0, thin = 1, normal = 2, heavy = 3, strong = 4 },
}

-- Popup items and settings previews are made from Blizzard's own
-- ActionButtonTemplate where the client has it (b.native = its size), so with
-- Blizzard's look they are the game's buttons exactly: frame, icon mask, hover,
-- pushed and checked art. They change size the way Edit Mode's Icon Size does,
-- by scale, never by stretching the art. Under EllesmereUI's look (and on a
-- client without the template) they are sized normally and drawn by us.
function BLIZZ_ART.Size(b, size)
    if b.native and not b.euiLook then
        b.k = size / b.native
        b:SetScale(b.k)
        b:SetSize(b.native, b.native)
    else
        b.k = 1
        b:SetScale(1)
        b:SetSize(size, size)
    end
end

-- SetPoint for such a button, with x and y in its parent's units (a scaled
-- frame reads its offsets in its own, scaled units)
function BLIZZ_ART.Point(b, point, rel, relPoint, x, y)
    local k = b.k or 1
    b:ClearAllPoints()
    b:SetPoint(point, rel, relPoint, x / k, y / k)
end

-- How EllesmereUI draws action buttons, or nil for Blizzard's art: nil without
-- EllesmereUI, with its styling turned off here, or when its Action Bars module
-- is set to the Blizzard or classic look. Border, icon zoom and slot background
-- come from Action Bar 1; hover and pushed effects from its Bar Animations page
-- (Highlight/Pushed Type 1-3 its textures, 4 a fill, 5 a border, 6 none). Without
-- the Action Bars module, EllesmereUI's defaults.
function EUIButtonLook()
    if not EllesmereUI or Style("euiSkin") == false then return nil end
    local look = { zoom = 0.055, bg = { 0.15, 0.15, 0.15, 0.5 }, border = { 0, 0, 0, 1 }, size = 1,
        hover = { kind = "fill", r = 1, g = 1, b = 1, a = 0.15 }, push = { kind = "fill", r = 1, g = 1, b = 1, a = 0.25 } }
    local lite = EllesmereUI.Lite
    local ok, eab = false, nil
    if type(lite) == "table" and lite.GetAddon then ok, eab = pcall(lite.GetAddon, "EllesmereUIActionBars", true) end
    local p = ok and type(eab) == "table" and type(eab.db) == "table" and eab.db.profile
    if type(p) ~= "table" then return look end
    if p.useClassicStyle or p.useBlizzardStyle or p.squareIcons == false then return nil end
    local _, class = UnitClass("player")
    local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local s = type(p.bars) == "table" and type(p.bars.MainBar) == "table" and p.bars.MainBar or {}
    local zoom = tonumber(s.iconZoom or p.iconZoom)
    if zoom then look.zoom = zoom / 100 end
    local bg = p.slotBgColor
    if type(bg) == "table" then look.bg = { bg.r or 0.15, bg.g or 0.15, bg.b or 0.15, (tonumber(p.slotBgOpacity) or 50) / 100 } end
    local c = s.borderColor
    if type(c) == "table" then look.border = { c.r or 0, c.g or 0, c.b or 0, c.a or 1 } end
    if s.borderClassColor and cc then look.border = { cc.r, cc.g, cc.b, look.border[4] } end
    look.size = tonumber(s.borderThicknessPx) or BLIZZ_ART.borderPx[s.borderThickness or "thin"] or 1
    -- hover ("highlight") and pushed, as its Bar Animations page sets them
    local function interaction(prefix)
        local t = tonumber(p[prefix .. "TextureType"]) or 2
        local col = type(p[prefix .. "CustomColor"]) == "table" and p[prefix .. "CustomColor"] or {}
        local spec = { r = col.r or 0.973, g = col.g or 0.839, b = col.b or 0.604, a = 1,
            size = tonumber(p[prefix .. "BorderSize"]) or 4 }
        if p[prefix .. "UseClassColor"] and cc then spec.r, spec.g, spec.b = cc.r, cc.g, cc.b end
        if t <= 3 then
            spec.kind = "tex"
            spec.path = "Interface\\AddOns\\EllesmereUIActionBars\\Media\\highlight-" .. (t + 1) .. ".png"
            -- a button's highlight texture is drawn added on (a glow over the
            -- icon); its pushed texture is drawn normally
            if prefix == "highlight" then spec.blend = "ADD" end
        elseif t == 4 then
            spec.kind, spec.a = "fill", 0.35
        elseif t == 5 then
            spec.kind = "edge"
        else
            spec.kind = "none"
        end
        return spec
    end
    look.hover = interaction("highlight")
    look.push = interaction("pushed")
    return look
end

-- Blizzard's action buttons (retail's, with an icon mask) have cut corners:
-- in the art (uiactionbar2x, the frame is 88 px wide) the straight top edge
-- starts 9 px in from each side, and the frame is drawn 46 wide on a 45 wide
-- button, so each corner takes this much of the button's width (about 10.4%).
-- EllesmereUI's and classic's buttons are square.
BLIZZ_ART.CORNER = (9 / 88) * (46 / 45)
function BLIZZ_ART.Rounded()
    local b = _G.ActionButton1
    return not EUIButtonLook() and b ~= nil and b.IconMask ~= nil
end

-- A solid border in the shape of Blizzard's buttons around frame g's edge,
-- size thick (in g's units), color c, its corners cut cut back: straight edges
-- that stop where the corners are cut, and each cut corner drawn as a pixel
-- staircase (as Blizzard's art is), one size x size square per screen pixel
-- along it, so it is crisp at any thickness. All thickens inwards.
function BLIZZ_ART.CutBorder(g, cut, size, c)
    local px = PixelSize(g)
    local n = math.max(1, math.floor(cut / px + 0.5))   -- the cut, in whole pixels
    cut = n * px
    local e = g.edges
    for i = 1, 4 do
        e[i]:ClearAllPoints()
        Paint(e[i], "solid", c)
        e[i]:Show()
    end
    e[1]:SetPoint("TOPLEFT", g, "TOPLEFT", cut, 0); e[1]:SetPoint("TOPRIGHT", g, "TOPRIGHT", -cut, 0); e[1]:SetHeight(size)
    e[2]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", cut, 0); e[2]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", -cut, 0); e[2]:SetHeight(size)
    e[3]:SetPoint("TOPLEFT", g, "TOPLEFT", 0, -cut); e[3]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 0, cut); e[3]:SetWidth(size)
    e[4]:SetPoint("TOPRIGHT", g, "TOPRIGHT", 0, -cut); e[4]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", 0, cut); e[4]:SetWidth(size)
    -- each corner: the pixels just inside the cut, (x, y) with x + y = n - 1
    -- counted from that corner, each grown size x size towards the inside
    local corners = { { "TOPLEFT", 1, -1 }, { "TOPRIGHT", -1, -1 }, { "BOTTOMLEFT", 1, 1 }, { "BOTTOMRIGHT", -1, 1 } }
    g.cells = g.cells or {}
    local used = 0
    for _, cn in ipairs(corners) do
        local point, sx, sy = cn[1], cn[2], cn[3]   -- (sx, sy: towards the inside)
        for x = 0, n - 1 do
            used = used + 1
            local t = g.cells[used]
            if not t then
                t = g:CreateTexture(nil, "OVERLAY")
                g.cells[used] = t
            end
            Paint(t, "solid", c)
            t:ClearAllPoints()
            t:SetSize(size, size)
            t:SetPoint(point, g, point, sx * x * px, sy * (n - 1 - x) * px)
            t:Show()
        end
    end
    for i = used + 1, #g.cells do g.cells[i]:Hide() end
end

-- the popout indicator's thickness in screen pixels: 1 to 5 (more looks clunky)
function BLIZZ_ART.TabHeight()
    return math.max(1, math.min(5, tonumber(Style("tabHeight")) or 3))
end

-- The small tab on a button that has a popout, on the side it opens from
-- (a.dir: up, down, left, right; see POPOUT). Width is UI units (like the
-- button), height screen pixels; never longer than the button's straight edge
-- (between rounded corners), and placed on whole pixels so its edges stay sharp.
function StyleArrow(a)
    local px = PixelSize(a)
    local b = a.button
    local dir = a.dir or "up"
    local across = dir == "left" or dir == "right"   -- on a side edge: standing upright
    local bw = b and (across and b:GetHeight() or b:GetWidth()) or 0
    if type(bw) ~= "number" or bw <= 0 then bw = 36 end
    local bwPx = math.floor(bw / px + 0.5)
    local maxPx = bwPx
    if BLIZZ_ART.Rounded() then maxPx = math.floor(bwPx * (1 - 2 * BLIZZ_ART.CORNER)) end
    local wPx = math.min(math.floor(BarUnits(a, Style("tabWidth")) / px + 0.5), maxPx)
    local long, thick = math.max(wPx, 0.01) * px, BLIZZ_ART.TabHeight() * px   -- 0: nothing to see
    if across then a:SetSize(thick, long) else a:SetSize(long, thick) end
    if b then
        -- centred along the edge, overlapping the button by 3 pixels
        local off, inset = math.floor((bwPx - wPx) / 2) * px, 3 * px
        a:ClearAllPoints()
        if dir == "down" then
            a:SetPoint("TOPLEFT", b, "BOTTOMLEFT", off, inset)
        elseif dir == "right" then
            a:SetPoint("BOTTOMLEFT", b, "BOTTOMRIGHT", -inset, off)
        elseif dir == "left" then
            a:SetPoint("BOTTOMRIGHT", b, "BOTTOMLEFT", inset, off)
        else
            a:SetPoint("BOTTOMLEFT", b, "TOPLEFT", off, -inset)
        end
    end
    Paint(a.tex, Style("tabTexture"), StyleColor("tabColor"))
end

-- The hover color's Default: your action bars' hover
-- color, EllesmereUI's (its Bar Animations page) or Blizzard's pale yellow.
-- Its opacity is only used by fill hovers.
STYLE_DEFAULTS.entryHover = function()
    local look = EUIButtonLook()
    local h = look and look.hover
    if h and h.kind ~= "none" then return { h.r, h.g, h.b, 1 } end
    return { 1, 0.93, 0.6, 1 }
end

-- The Hover setting, for everything we draw like an action button (popup
-- items, settings previews), put into StyleButtonArt's options o. On Default,
-- your action bars' own hover; otherwise their kind of hover (EllesmereUI's
-- glow, fill or border; Blizzard's texture, desaturated) in that color. Its
-- opacity applies in every mode (o.hoverAlpha with Blizzard's look).
function ApplyHover(o)
    local c = StyleColor("entryHover")
    local alpha = c[4] or 1
    local tint = ColorMode("entryHover") ~= "default"
    local h = o.look and o.look.hover
    if h then
        if tint then h.r, h.g, h.b = c[1], c[2], c[3] end
        h.a = (h.a or 1) * alpha
    else
        o.hoverAlpha = alpha
        if tint then o.hover = c end
    end
    return o
end

-- ---------------------------------------------------------------------------
-- Highlight: a pulsing border on any action button holding a macro whose
-- category is empty. It only touches our own frames, so it also works in combat.
-- Colour, thickness, texture and pulse come from the saved style. Two looks:
-- a solid border, or a soft glow inside the button.
-- ---------------------------------------------------------------------------

-- tex as colour c fading to clear: full at the button's edge (side "top",
-- "bottom", "left" or "right"), clear towards the middle
function FadeEdge(tex, side, c)
    local a = c[4] or 1
    local orient = (side == "top" or side == "bottom") and "VERTICAL" or "HORIZONTAL"
    -- VERTICAL runs bottom to top, HORIZONTAL left to right
    local a1, a2 = a, 0
    if side == "top" or side == "right" then a1, a2 = 0, a end
    pcall(tex.SetVertexColor, tex, 1, 1, 1, 1)
    tex:SetColorTexture(1, 1, 1, 1)
    local ok = false
    if CreateColor then
        ok = pcall(tex.SetGradient, tex, orient, CreateColor(c[1], c[2], c[3], a1), CreateColor(c[1], c[2], c[3], a2))
    end
    if not ok and tex.SetGradientAlpha then
        ok = pcall(tex.SetGradientAlpha, tex, orient, c[1], c[2], c[3], a1, c[1], c[2], c[3], a2)
    end
    if not ok then tex:SetColorTexture(c[1], c[2], c[3], a * 0.5) end   -- no gradients: a faint band
end

-- Blizzard's item-border glow, used for the soft glow on Blizzard's buttons
BLIZZ_ART.GLOW = "Interface\\Buttons\\UI-ActionButton-Border"

function StyleGlow(g, button)
    local c = StyleColor("glowColor")
    local t = math.max(1, math.min(5, tonumber(Style("glowThickness")) or 3))   -- 1 to 5
    local px = PixelSize(button)
    local soft = TextureInfo(Style("glowTexture")).glow
    local look = EUIButtonLook()
    local rounded = BLIZZ_ART.Rounded()   -- retail's buttons: cut corners
    -- always inside the button (inside EllesmereUI's border for its soft glow)
    local inset = (soft and look) and look.size * px or 0
    g:ClearAllPoints()
    g:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    g:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
    for i = 1, 4 do g.edges[i]:Hide() end
    for _, s in ipairs(g.softs or {}) do s:Hide() end
    for _, cell in ipairs(g.cells or {}) do cell:Hide() end
    if soft and (look or not rounded) then
        -- square buttons (EllesmereUI's, Classic's): fading in from the edges
        -- over the icon, thickness x3 screen pixels deep
        local w = button:GetWidth()
        if type(w) ~= "number" or w <= 0 then w = 36 end
        local d = math.min(t * 3 * px, w * 0.45)
        local e = g.edges
        for i = 1, 4 do e[i]:ClearAllPoints(); e[i]:Show() end
        e[1]:SetPoint("TOPLEFT", g, "TOPLEFT", 0, 0); e[1]:SetPoint("TOPRIGHT", g, "TOPRIGHT", 0, 0); e[1]:SetHeight(d)
        e[2]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 0, 0); e[2]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", 0, 0); e[2]:SetHeight(d)
        e[3]:SetPoint("TOPLEFT", g, "TOPLEFT", 0, 0); e[3]:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 0, 0); e[3]:SetWidth(d)
        e[4]:SetPoint("TOPRIGHT", g, "TOPRIGHT", 0, 0); e[4]:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", 0, 0); e[4]:SetWidth(d)
        for i, side in ipairs({ "top", "bottom", "left", "right" }) do FadeEdge(e[i], side, c) end
    elseif soft then
        -- Retail's buttons (cut corners): Blizzard's item-border glow, tinted,
        -- its ring on the button's edge (always cropped the same: cropping less
        -- only shrank the ring away from the edge, 0.104.0). Each step of
        -- thickness adds another copy 2 screen pixels further in, so the glow
        -- reaches deeper in the button's own shape. Drawn added on, so opacity
        -- dims the color itself.
        g.softs = g.softs or {}
        local a = c[4] or 1
        for i = 1, t do
            local s = g.softs[i]
            if not s then
                s = g:CreateTexture(nil, "OVERLAY")
                g.softs[i] = s
            end
            s:SetTexture(BLIZZ_ART.GLOW)
            pcall(s.SetBlendMode, s, "ADD")
            s:SetTexCoord(0.21, 0.79, 0.21, 0.79)
            local ins = Snap(g, (i - 1) * 2 * px)
            s:ClearAllPoints()
            s:SetPoint("TOPLEFT", g, "TOPLEFT", ins, -ins)
            s:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", -ins, ins)
            s:SetVertexColor(c[1] * a, c[2] * a, c[3] * a, 1)   -- (its ring is already rounded)
            s:Show()
        end
    elseif rounded then
        -- On the button's frame ring. In the frame art (88 px wide in
        -- uiactionbar2x, drawn 46 wide on a 45 wide button) the grey ring starts
        -- 1 px in from the edge and the corners are cut 9 px back; so: in from
        -- the button by one art pixel, corners cut 8 more, on whole screen pixels.
        local w = button:GetWidth()
        if type(w) ~= "number" or w <= 0 then w = 36 end
        local unit = w * (46 / 45) / 88   -- one pixel of the art, in the button's units
        local ins = math.max(px, Snap(g, unit))
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", button, "TOPLEFT", ins, -ins)
        g:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -ins, ins)
        BLIZZ_ART.CutBorder(g, Snap(g, unit * 8), math.max(px, Snap(g, t * px)), c)
    else
        -- square buttons: a plain border, thickening inwards
        for i = 1, 4 do Paint(g.edges[i], "solid", c) end
        PlaceEdges(g.edges, g, t)
    end
    if g.anim then pcall(g.anim.SetDuration, g.anim, Style("glowSpeed")) end
    if g.pulse and g:IsShown() then
        if Style("glowPulse") then
            local playing = false
            pcall(function() playing = g.pulse:IsPlaying() end)
            if not playing then g.pulse:Play() end
        else
            g.pulse:Stop()
            g:SetAlpha(1)
        end
    end
end

-- Gives button b (with b.icon) the parts StyleButtonArt draws with when the
-- game's own art is not used: slot background, frame, border, selected
-- border, hover and pushed layers.
function ButtonArt(b)
    b.slot = b:CreateTexture(nil, "BACKGROUND", nil, -8)   -- under the icon
    b.slot:SetAllPoints()
    b.normal = b:CreateTexture(nil, "ARTWORK", nil, 1)
    b.normal:SetTexture(BLIZZ_ART.frame)
    b.normal:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.edges = MakeEdges(b, "OVERLAY")
    b.sel = MakeEdges(b, "OVERLAY")
    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
    b.hl:SetAllPoints()
    b.hlEdges = MakeEdges(b, "HIGHLIGHT")
    local pl = CreateFrame("Frame", nil, b)   -- shown while the mouse button is down
    pl:SetAllPoints()
    pl:SetFrameLevel((b:GetFrameLevel() or 1) + 2)
    pl:Hide()
    b.push = pl:CreateTexture(nil, "OVERLAY")
    b.push:SetAllPoints()
    b.pushEdges = MakeEdges(pl, "OVERLAY")
    b.pushLayer = pl
    b:HookScript("OnMouseDown", function(self) self.pushLayer:Show() end)
    b:HookScript("OnMouseUp", function(self) self.pushLayer:Hide() end)
    b:HookScript("OnHide", function(self) self.pushLayer:Hide() end)
end

-- one hover or pushed effect: a texture, a fill, a border or nothing
function PaintInteraction(tex, edges, owner, spec)
    PlaceEdges(edges, owner, 0)
    tex:Hide()
    -- a recolored texture is greyed first, so the color is not mixed with its own
    pcall(tex.SetDesaturated, tex, spec.desat and true or false)
    if spec.kind == "tex" then
        tex:SetTexture(spec.path)
        tex:SetTexCoord(0, 1, 0, 1)
        pcall(tex.SetBlendMode, tex, spec.blend or "BLEND")
        tex:SetVertexColor(spec.r, spec.g, spec.b, spec.a or 1)
        tex:Show()
    elseif spec.kind == "fill" then
        tex:SetVertexColor(1, 1, 1, 1)
        pcall(tex.SetBlendMode, tex, "BLEND")
        tex:SetColorTexture(spec.r, spec.g, spec.b, spec.a or 0.35)
        tex:Show()
    elseif spec.kind == "edge" then
        for i = 1, 4 do edges[i]:SetColorTexture(spec.r, spec.g, spec.b, spec.a or 1) end
        PlaceEdges(edges, owner, spec.size or 2)
    end
end

-- Draws b like an action button. o.look: EllesmereUI's look (EUIButtonLook) or
-- nil for Blizzard's. o.size: its size (see BLIZZ_ART.Size). With Blizzard's
-- look, o.hover recolors the hover. o.sel (+ o.selSize): the selected item's
-- border, in the button's own shape with Blizzard's look (its checked art),
-- square with EllesmereUI's.
BLIZZ_ART.none = { kind = "none" }   -- no hover or pushed effect of ours
function StyleButtonArt(b, o)
    local look = o.look
    b.euiLook = look and true or nil
    if o.size then b.want = o.size end
    if b.want then BLIZZ_ART.Size(b, b.want) end
    local tpl = b.native ~= nil   -- made from Blizzard's template
    if tpl then
        -- the template's own art: shown with Blizzard's look, hidden under EllesmereUI's
        local blizz = not look
        for _, t in ipairs({ b:GetNormalTexture(), b:GetHighlightTexture(), b:GetPushedTexture() }) do
            if t then t:SetAlpha(blizz and 1 or 0) end
        end
        if b.SlotBackground then b.SlotBackground:SetShown(blizz) end
        if b.IconMask and b.masked ~= blizz then
            pcall(blizz and b.icon.AddMaskTexture or b.icon.RemoveMaskTexture, b.icon, b.IconMask)
            b.masked = blizz
        end
        -- selected: the template's checked border, as a pet bar button shows
        -- its active state; o.selTint recolors it with the selected color
        local ct = b:GetCheckedTexture()
        if ct then
            local c = (not look) and o.sel
            b.amChecked = c and true or false
            b:SetChecked(b.amChecked)
            ct:SetAlpha(c and 1 or 0)
            if c then
                local tint = o.selTint and c or nil
                pcall(ct.SetDesaturated, ct, tint and true or false)
                -- (its opacity applies on Default too)
                if tint then ct:SetVertexColor(c[1], c[2], c[3], c[4] or 1) else ct:SetVertexColor(1, 1, 1, c[4] or 1) end
            end
        end
    end
    if look then
        b.normal:Hide()
        b.slot:SetColorTexture(look.bg[1], look.bg[2], look.bg[3], look.bg[4])
        b.slot:Show()
        b.icon:SetTexCoord(look.zoom, 1 - look.zoom, look.zoom, 1 - look.zoom)
        for i = 1, 4 do b.edges[i]:SetColorTexture(look.border[1], look.border[2], look.border[3], look.border[4]) end
        PlaceEdges(b.edges, b, look.size)
        -- hover and pushed fill the icon inside the border, as on EllesmereUI's bars
        local t = look.size * PixelSize(b)
        for _, tex in ipairs({ b.hl, b.push }) do
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", b, "TOPLEFT", t, -t)
            tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -t, t)
        end
        PaintInteraction(b.hl, b.hlEdges, b, look.hover)
        PaintInteraction(b.push, b.pushEdges, b.pushLayer, look.push)
    else
        b.slot:Hide()
        b.icon:SetTexCoord(0, 1, 0, 1)
        PlaceEdges(b.edges, b, 0)
        if tpl then
            b.normal:Hide()
            -- the template's own hover and pushed art; o.hover recolors the hover
            local ht = b:GetHighlightTexture()
            if ht then
                pcall(ht.SetDesaturated, ht, o.hover and true or false)
                local h = o.hover or { 1, 1, 1 }
                ht:SetVertexColor(h[1], h[2], h[3], o.hoverAlpha or 1)
            end
            PaintInteraction(b.hl, b.hlEdges, b, BLIZZ_ART.none)
            PaintInteraction(b.push, b.pushEdges, b.pushLayer, BLIZZ_ART.none)
        else   -- no template on this client: Blizzard's classic frame and hover
            b.normal:SetSize(b:GetWidth() * 66 / 36, b:GetHeight() * 66 / 36)
            b.normal:Show()
            local hover = { kind = "tex", path = BLIZZ_ART.hover.path, blend = BLIZZ_ART.hover.blend,
                r = 1, g = 1, b = 1, a = o.hoverAlpha }
            if o.hover then
                hover.r, hover.g, hover.b, hover.desat = o.hover[1], o.hover[2], o.hover[3], true
            end
            b.hl:ClearAllPoints()
            b.hl:SetAllPoints(b)
            b.push:ClearAllPoints()
            b.push:SetAllPoints(b)
            PaintInteraction(b.hl, b.hlEdges, b, hover)
            PaintInteraction(b.push, b.pushEdges, b.pushLayer, BLIZZ_ART.push)
        end
    end
    -- our own square selected border: EllesmereUI's look, or no template
    if o.sel and not (tpl and not look) then
        for i = 1, 4 do b.sel[i]:SetColorTexture(o.sel[1], o.sel[2], o.sel[3], o.sel[4] or 1) end
        PlaceEdges(b.sel, b, o.selSize or 2)
    else
        PlaceEdges(b.sel, b, 0)
    end
end

-- One item button in the popup: Blizzard's own action button, or with
-- EllesmereUI's look one like your EllesmereUI bars. Hover: see ApplyHover.
function StyleEntry(e)
    -- in the popup's units (the item itself may be scaled), on whole pixels
    local o = ApplyHover({ look = EUIButtonLook(), size = BLIZZ_ART.ItemSize(e:GetParent()) })
    if e.selected then
        o.sel, o.selSize = StyleColor("selectedColor"), Style("selectedSize")
        o.selTint = ColorMode("selectedColor") ~= "default"   -- Default: Blizzard's own color
    end
    StyleButtonArt(e, o)
    if SkinActive() and skin.GetFont then
        local ok, font = pcall(skin.GetFont)
        if ok and type(font) == "string" then pcall(e.count.SetFont, e.count, font, 11, "OUTLINE") end
    end
end

-- The main action bar's frame art (MainActionBar / MainMenuBar .BorderArt,
-- what Edit Mode's Hide Bar Art turns off) on texture t, with its nine-slice
-- margins so it frames any size; false when this client has none.
function BLIZZ_ART.BarArt(t)
    local bar = _G.MainActionBar or _G.MainMenuBar
    local art = bar and bar.BorderArt
    local atlas = art and art.GetAtlas and art:GetAtlas()
    if type(atlas) ~= "string" or atlas == "" then return false end
    local ok, found = pcall(t.SetAtlas, t, atlas)
    if not ok or found == false then return false end
    t:SetVertexColor(1, 1, 1, 1)
    if art.GetTextureSliceMargins and t.SetTextureSliceMargins then
        local okM, l, top, r, bottom = pcall(art.GetTextureSliceMargins, art)
        if okM and l then
            pcall(t.SetTextureSliceMargins, t, l, top, r, bottom)
            if art.GetTextureSliceMode then pcall(t.SetTextureSliceMode, t, art:GetTextureSliceMode()) end
        end
    end
    return true
end

-- true while the popup shows a background (Blizzard's look, switched on)
function BLIZZ_ART.PopupArt()
    return not EUIButtonLook() and Style("flyoutArt") ~= false
end

-- How far the bar art reaches past the main bar's buttons on each side (left,
-- top, right, bottom), in frame f's units, so the popup's art sits around its
-- items the same way. 4 each when the bar cannot be read.
function BLIZZ_ART.BarInsets(f)
    local ok, l, t, r, b = pcall(function()
        local bar = _G.MainActionBar or _G.MainMenuBar
        local art = bar.BorderArt
        local left, top, right, bottom
        for i = 1, 12 do
            local btn = _G["ActionButton" .. i]
            if btn and btn:GetLeft() then
                left = math.min(left or btn:GetLeft(), btn:GetLeft())
                right = math.max(right or btn:GetRight(), btn:GetRight())
                top = math.max(top or btn:GetTop(), btn:GetTop())
                bottom = math.min(bottom or btn:GetBottom(), btn:GetBottom())
            end
        end
        local k = _G.ActionButton1:GetEffectiveScale() / f:GetEffectiveScale()
        return (left - art:GetLeft()) * k, (art:GetTop() - top) * k,
            (art:GetRight() - right) * k, (bottom - art:GetBottom()) * k
    end)
    local function sane(v) return (type(v) == "number" and v >= 0 and v <= 30) and v or 4 end
    if not ok then return 4, 4, 4, 4 end
    return sane(l), sane(t), sane(r), sane(b)
end

-- The space the main bar leaves between its buttons (ActionButton1 to 2, side
-- by side or stacked), in frame f's units; 0 when it cannot be read.
function BLIZZ_ART.BarGap(f)
    local ok, g = pcall(function()
        local a, b = _G.ActionButton1, _G.ActionButton2
        local k = a:GetEffectiveScale() / f:GetEffectiveScale()
        return math.max(b:GetLeft() - a:GetRight(), a:GetBottom() - b:GetTop()) * k
    end)
    if ok and type(g) == "number" and g >= 0 and g <= 20 then return g end
    return 0
end

-- How much smaller (or bigger) the popup's items are than the main bar's
-- buttons. The popup's bar art, dividers and spacing scale by this, as a whole
-- bar does with Edit Mode's Icon Size. 1 when the bar cannot be read.
function BLIZZ_ART.ArtScale(f)
    local ok, s = pcall(function()
        local b = _G.ActionButton1
        return BLIZZ_ART.ItemSize(f) / (b:GetWidth() * b:GetEffectiveScale() / f:GetEffectiveScale())
    end)
    if ok and type(s) == "number" and s > 0.1 and s < 10 then return s end
    return 1
end

-- A divider the main bar uses between buttons stacked one above the other (a
-- vertical bar in Edit Mode): a frame from its VerticalDividersPool, one in use
-- if the bar is vertical now, otherwise a spare one. across: one it uses
-- between buttons side by side instead (HorizontalDividersPool; unverified
-- which pool that is). nil when there is none.
function BLIZZ_ART.DividerSource(across)
    local bar = _G.MainActionBar or _G.MainMenuBar
    local pool = bar and (across and bar.HorizontalDividersPool or bar.VerticalDividersPool)
    if not pool then return nil end
    local function pick(a, b)   -- pools hand out (object, true) or (index, object)
        if type(a) == "table" and a.GetRegions then return a end
        if type(b) == "table" and b.GetRegions then return b end
    end
    local found
    pcall(function() for a, b in pool:EnumerateActive() do found = found or pick(a, b) end end)
    if not found and pool.EnumerateInactive then
        pcall(function() for a, b in pool:EnumerateInactive() do found = found or pick(a, b) end end)
    end
    return found
end

-- Gives our frame dst a copy of Blizzard frame src's textures: the same art,
-- draw layers, colors, sizes and anchors (to the frame and to each other).
function BLIZZ_ART.Clone(src, dst)
    local made, list = {}, {}
    for _, r in ipairs({ src:GetRegions() }) do
        if r:GetObjectType() == "Texture" then
            local layer, sub = r:GetDrawLayer()
            local t = dst:CreateTexture(nil, layer, nil, sub)
            local atlas = r:GetAtlas()
            if type(atlas) == "string" and atlas ~= "" then
                t:SetAtlas(atlas)
            else
                t:SetTexture(r:GetTexture())
                t:SetTexCoord(r:GetTexCoord())
            end
            pcall(t.SetBlendMode, t, r:GetBlendMode())
            t:SetVertexColor(r:GetVertexColor())
            t:SetShown(r:IsShown())
            made[r] = t
            list[#list + 1] = r
        end
    end
    for _, r in ipairs(list) do
        local t = made[r]
        t:SetSize(r:GetWidth(), r:GetHeight())   -- (anchors on both sides win over this)
        local n = r:GetNumPoints()
        for i = 1, n do
            local point, rel, relPoint, x, y = r:GetPoint(i)
            rel = (rel == nil or rel == src) and dst or made[rel]
            if rel then t:SetPoint(point, rel, relPoint, x, y) end
        end
        if n == 0 then t:SetAllPoints(dst) end
    end
    return #list > 0
end

-- Draws the main bar's divider between the n items in popup f (size each, gap
-- apart, the first pad in from the edge): copies of one of its dividers, at its
-- scale. Items stacked, or side by side when across. Hidden when on is false
-- or there is none to copy.
function BLIZZ_ART.Dividers(f, on, n, size, gap, pad, across)
    -- each way has its own copies (different art); the other way's are hidden
    local key = across and "dividersAcross" or "dividers"
    local other = f[across and "dividers" or "dividersAcross"]
    if other then for _, d in ipairs(other) do d:Hide() end end
    f[key] = f[key] or {}
    local list = f[key]
    local src = on and BLIZZ_ART.DividerSource(across)
    if src and not f.dividerLayer then   -- above the items, as on the bar
        f.dividerLayer = CreateFrame("Frame", nil, f)
        f.dividerLayer:SetAllPoints()
        f.dividerLayer:SetFrameLevel(f:GetFrameLevel() + 10)
    end
    local k, w, h = 1, 0, 0
    if src then
        -- the bar's scale, times how much the items differ from its buttons
        k = src:GetEffectiveScale() / f:GetEffectiveScale() * BLIZZ_ART.ArtScale(f)
        w, h = src:GetWidth() or 0, src:GetHeight() or 0
        if w <= 0 or h <= 0 then   -- a spare one is not laid out: as long as an item, as thick as its art
            if across then
                h, w = size / k, 0
                for _, r in ipairs({ src:GetRegions() }) do w = math.max(w, r:GetWidth() or 0) end
            else
                w, h = size / k, 0
                for _, r in ipairs({ src:GetRegions() }) do h = math.max(h, r:GetHeight() or 0) end
            end
        end
    end
    for i = 1, math.max(#list, n - 1) do
        local d = list[i]
        if src and i <= n - 1 then
            if not d then
                d = CreateFrame("Frame", nil, f.dividerLayer)
                if not pcall(BLIZZ_ART.Clone, src, d) then d.broken = true end
                list[i] = d
            end
            d:SetScale(k)
            d:SetSize(w, h)
            d:ClearAllPoints()
            local at = (pad + i * (size + gap) - gap / 2) / k
            if across then
                d:SetPoint("CENTER", f, "LEFT", at, 0)
            else
                d:SetPoint("CENTER", f, "BOTTOM", 0, at)
            end
            d:SetShown(not d.broken)
        elseif d then
            d:Hide()
        end
    end
end

-- The popup frame. With Blizzard's look its background is the action bar's
-- frame art, switched by "Show background" like the bar art in Edit Mode (a
-- client without that art gets a plain dark backing). With EllesmereUI's look
-- it is see-through, so the items stand on their own like buttons on its bars.
-- The art sits on its own frame, scaled with the items (BLIZZ_ART.ArtScale).
function StyleFlyout(f)
    if not BLIZZ_ART.PopupArt() then
        if f.art then f.art:Hide() end
        return
    end
    if not f.art then
        f.art = CreateFrame("Frame", nil, f)
        f.art:SetFrameLevel(f:GetFrameLevel())   -- under the items
        f.art.tex = f.art:CreateTexture(nil, "BACKGROUND")
        f.art.tex:SetAllPoints()
    end
    local t = f.art.tex
    if not BLIZZ_ART.BarArt(t) then
        pcall(t.SetVertexColor, t, 1, 1, 1, 1)
        t:SetColorTexture(0, 0, 0, 0.5)
    end
    -- around the items, reaching out past them as the bar art does (the
    -- offsets are in the art frame's own, scaled units, so they scale too)
    local l, top, r, b = BLIZZ_ART.BarInsets(f)
    f.art:SetScale(BLIZZ_ART.ArtScale(f))
    f.art:ClearAllPoints()
    f.art:SetPoint("TOPLEFT", f, "TOPLEFT", -l, top)
    f.art:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", r, -b)
    f.art:Show()
end

buttons = {}        -- action buttons found on screen

-- The width and height of your action buttons in UI units, the number
-- EllesmereUI's Icon Size shows (its border is inside the button, so it is
-- included), as they are on screen (bars may be scaled).
function BLIZZ_ART.BarButtonSize()
    local b = buttons[1] or _G.ActionButton1
    local w, h = b and b:GetWidth(), b and b:GetHeight()
    if type(w) ~= "number" or w <= 0 then return 45, 45 end
    if type(h) ~= "number" or h <= 0 then h = w end
    local k = b:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return math.max(8, math.floor(w * k + 0.5)), math.max(8, math.floor(h * k + 0.5))
end
