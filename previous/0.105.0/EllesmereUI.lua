-- AutoMacros: EllesmereUI: a page in its settings and its look for the popout
-- (only while EllesmereUI is installed).

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

function UI.FindPage(name)
    for _, page in ipairs(PAGES) do
        if page.name == name then return page end
    end
end

-- The preview strip builder for an EllesmereUI page (nil: the page has none).
-- One function per page, kept, as EllesmereUI caches the header by builder.
UI.euiHeaders = {}
function UI.EUIHeader(pageName)
    local page = UI.FindPage(pageName)
    if not (page and page.header) then return nil end
    local hb = UI.euiHeaders[pageName]
    if not hb then
        hb = function(host, width)
            return UI.ShowHeader(page.header, host, width, function(h)
                if EllesmereUI.UpdateContentHeaderHeight then
                    pcall(EllesmereUI.UpdateContentHeaderHeight, EllesmereUI, h)
                end
            end)
        end
        UI.euiHeaders[pageName] = hb
    end
    return hb
end

function RegisterEUI()
    if not EllesmereUI then return end
    if not UI.skinRegistered and EllesmereUI.RegisterSkin then
        UI.skinRegistered = true
        local ok, err = pcall(EllesmereUI.RegisterSkin, "AutoMacros", function(S)
            skin = S
            if S.OnLooksChanged then pcall(S.OnLooksChanged, function() ApplyStyle() end) end
            ApplyStyle()
        end)
        if not ok then Fail("EllesmereUI skin", err) end
    end
    if not UI.pluginRegistered and EllesmereUI.RegisterPlugin then
        UI.pluginRegistered = true
        local names = {}
        for _, page in ipairs(PAGES) do names[#names + 1] = page.name end
        local ok, res = pcall(EllesmereUI.RegisterPlugin, "AutoMacros", {
            label = "AutoMacros",
            position = "bottom",
            modules = { {
                key = "options",
                title = "AutoMacros",
                description = "Consumable and teleport macros: buttons, highlight, popout and item learning",
                pages = names,
                buildPage = function(pageName, parent, yOffset)
                    local y = yOffset or 0
                    local page = UI.FindPage(pageName)
                    if not page then return math.abs(y) end
                    -- EllesmereUI's own pages draw their preview strip from inside
                    -- the page build (getHeaderBuilder only brings it back when a
                    -- cached page is shown again), so this page does the same
                    local hb = UI.EUIHeader(pageName)
                    local prebuild = EllesmereUI.IsSearchPrebuild and EllesmereUI.IsSearchPrebuild()
                    if hb and not prebuild and EllesmereUI.SetContentHeader then
                        local okH, errH = pcall(EllesmereUI.SetContentHeader, EllesmereUI, hb)
                        if not okH then Fail("EllesmereUI preview", errH) end
                    end
                    for _, section in ipairs(UI.PageSections(page)) do
                        local ok2, newY = pcall(BuildPage, parent, section, 20, y, true)
                        if not ok2 then
                            Fail("EllesmereUI page", newY)
                            break
                        end
                        y = newY
                    end
                    return math.abs(y)
                end,
                -- the same builder again, when a cached page comes back
                getHeaderBuilder = function(pageName) return UI.EUIHeader(pageName) end,
                onReset = function() ResetStyle(); RefreshOptions() end,
            } },
        })
        -- (a refused spec returns false and EllesmereUI reports why; trying
        -- again would only be refused again, so that is left alone)
        if not ok then
            UI.pluginRegistered = false
            Fail("EllesmereUI page", res)
        end
    end
end
pcall(RegisterEUI)
