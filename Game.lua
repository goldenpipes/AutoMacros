-- AutoMacros: which game this is. Loads first, so the game folders in Games\
-- (Forever, ClassicEra, TBC, Mists, Mainline) can check it: each holds only
-- what is different on that game (its spell and item ID lists), and its files
-- skip themselves on every other game.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)

-- GAME: "forever", "classicera", "tbc", "mists" or "mainline" (retail), from
-- the client's interface number (the .toc's Interface line): Forever 16001,
-- Classic Era (also Hardcore and Season of Discovery) 11509, TBC Anniversary
-- 20506, MoP Classic 50504, retail (Mainline) 120105. A client between those
-- (a future Wrath or Cata Classic, say) gets the nearest older game's lists:
-- they only miss later spells, which that client would not have anyway.
do
    local iface = select(4, GetBuildInfo())
    iface = tonumber(iface) or 0
    if iface >= 100000 then
        GAME = "mainline"
    elseif iface >= 50000 then
        GAME = "mists"
    elseif iface >= 20000 then
        GAME = "tbc"
    elseif iface >= 16000 and iface < 17000 then
        GAME = "forever"
    else
        GAME = "classicera"
    end
end
