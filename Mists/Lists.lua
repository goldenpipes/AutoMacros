-- AutoMacros: spell and item ID lists for MoP Classic only (see Game.lua):
-- everything up to Mists of Pandaria. IDs after vanilla are from memory,
-- unverified: a wrong one is never known or found, so it never shows.

local ADDON, ns = ...
-- every file shares the addon's own table: names set here are seen by the
-- other files, anything else (the game's API) comes from _G
if not getmetatable(ns) then setmetatable(ns, { __index = _G }) end
setfenv(1, ns)
if GAME ~= "mists" then return end

-- Hearth/Teleport button's spells: Astral Recall (Shaman), Teleport: Moonglade
-- (Druid), Death Gate (Death Knight), Zen Pilgrimage (Monk), then the mage
-- teleports: vanilla cities, TBC, Wrath, Cata, MoP.
TRAVEL_SPELLS = {
    556, 18960, 50977, 126892,
    3561, 3562, 3565, 3567, 3563, 3566,
    32271, 32272, 33690, 35715, 49359, 49358,
    53140, 88342, 88344, 132621, 132627, 120145,
}
-- Profession windows, every rank (Apprentice, Journeyman, Expert, Artisan,
-- Master, Grand Master): First Aid, Cooking, Alchemy, Blacksmithing,
-- Enchanting, Engineering, Leatherworking, Tailoring, Jewelcrafting,
-- Inscription, then Smelting (Mining) and Poisons (Rogue).
PROFESSION_SPELLS = {
    3273, 3274, 7924, 10846, 27028, 45542,
    2550, 3102, 3413, 18260, 33359, 51296,
    2259, 3101, 3464, 11611, 28596, 51304,
    2018, 3100, 3538, 9785, 29844, 51300,
    7411, 7412, 7413, 13920, 28029, 51313,
    4036, 4037, 4038, 12656, 30350, 51306,
    2108, 3104, 3811, 10662, 32549, 51302,
    3908, 3909, 3910, 12180, 26790, 51309,
    25229, 25230, 28894, 28895, 28897, 51311,
    45357, 45358, 45359, 45360, 45361, 45363,
    2656, 2842,
}
-- Tracking: Find Herbs, Find Minerals, Find Fish, Find Treasure (Dwarf), Sense
-- Undead (Paladin), Sense Demons (Warlock), Track Humanoids (Druid), and the
-- Hunter's.
TRACKING_SPELLS = {
    2383, 2580, 43308, 2481, 5502, 5500, 5225,
    1494, 19883, 19884, 19885, 19880, 19878, 19882, 19879,
}
-- Mage portals, in the same order (the first one is the button's icon).
PORTAL_SPELLS = {
    10059, 11417, 11416, 11418, 11419, 11420,
    32266, 32267, 33691, 35717, 49360, 49361,
    53142, 88345, 88346, 132620, 132626, 120146,
}

-- Healthstone ranks: 1 Minor, 2 Lesser, 3 Healthstone, 4 Greater, 5 Major,
-- 6 Master (TBC); since Wrath there is one Healthstone (5512, rank 1).
-- Create Healthstone, best first (6201 is the only one since Wrath).
HS_RANK = {
    [5512] = 1, [19004] = 1, [19005] = 1,
    [5511] = 2, [19006] = 2, [19007] = 2,
    [5509] = 3, [19008] = 3, [19009] = 3,
    [5510] = 4, [19010] = 4, [19011] = 4,
    [9421] = 5, [19012] = 5, [19013] = 5,
    [22103] = 6, [22104] = 6, [22105] = 6,
}
CREATE_HS = { 27230, 11730, 11729, 5699, 6202, 6201 }
-- Mana gems: 1 Agate, 2 Jade, 3 Citrine, 4 Ruby, 5 Emerald, 6 Mana Gem;
-- Conjure spells, best first.
MANA_GEM_RANK = { [5514] = 1, [5513] = 2, [8007] = 3, [8008] = 4, [22044] = 5, [36799] = 6 }
CONJURE_GEM = { 42985, 27101, 10054, 10053, 3552, 759 }
