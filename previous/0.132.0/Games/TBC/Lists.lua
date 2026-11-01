-- AutoMacros: spell and item ID lists for TBC Anniversary only (see Game.lua):
-- vanilla's plus The Burning Crusade's. IDs added by TBC are from memory,
-- unverified: a wrong one is never known or found, so it never shows.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)
if GAME ~= "tbc" then return end

-- Hearth/Teleport button's spells: Astral Recall (Shaman), Teleport: Moonglade
-- (Druid), the mage teleports (vanilla cities, then TBC's).
TRAVEL_SPELLS = {
    556, 18960,
    3561, 3562, 3565, 3567, 3563, 3566,
    32271, 32272, 33690, 35715, 49359, 49358,
}
-- Profession windows, every rank (Apprentice, Journeyman, Expert, Artisan,
-- Master): First Aid, Cooking, Alchemy, Blacksmithing, Enchanting,
-- Engineering, Leatherworking, Tailoring, Jewelcrafting, then Smelting
-- (Mining) and Poisons (Rogue).
PROFESSION_SPELLS = {
    3273, 3274, 7924, 10846, 27028,
    2550, 3102, 3413, 18260, 33359,
    2259, 3101, 3464, 11611, 28596,
    2018, 3100, 3538, 9785, 29844,
    7411, 7412, 7413, 13920, 28029,
    4036, 4037, 4038, 12656, 30350,
    2108, 3104, 3811, 10662, 32549,
    3908, 3909, 3910, 12180, 26790,
    25229, 25230, 28894, 28895, 28897,
    2656, 2842,
}
-- Tracking: Find Herbs, Find Minerals, Find Fish, Find Treasure (Dwarf), Sense
-- Undead (Paladin), Sense Demons (Warlock), Track Humanoids (Druid), and the
-- Hunter's.
TRACKING_SPELLS = {
    2383, 2580, 43308, 2481, 5502, 5500, 5225,
    1494, 19883, 19884, 19885, 19880, 19878, 19882, 19879,
}
-- Mage portals (the first one is the button's icon).
PORTAL_SPELLS = {
    10059, 11417, 11416, 11418, 11419, 11420,
    32266, 32267, 33691, 35717, 49360, 49361,
}

-- Healthstone ranks: 1 Minor, 2 Lesser, 3 Healthstone, 4 Greater, 5 Major,
-- 6 Master (the higher ID of each is the talented one); Create Healthstone,
-- best first.
HS_RANK = {
    [5512] = 1, [19004] = 1, [19005] = 1,
    [5511] = 2, [19006] = 2, [19007] = 2,
    [5509] = 3, [19008] = 3, [19009] = 3,
    [5510] = 4, [19010] = 4, [19011] = 4,
    [9421] = 5, [19012] = 5, [19013] = 5,
    [22103] = 6, [22104] = 6, [22105] = 6,
}
CREATE_HS = { 27230, 11730, 11729, 5699, 6202, 6201 }
-- Mana gems: 1 Agate, 2 Jade, 3 Citrine, 4 Ruby, 5 Emerald; Conjure spells,
-- best first.
MANA_GEM_RANK = { [5514] = 1, [5513] = 2, [8007] = 3, [8008] = 4, [22044] = 5 }
CONJURE_GEM = { 27101, 10054, 10053, 3552, 759 }
