# Changelog

AutoMacros uses [Semantic Versioning](https://semver.org/): while the version starts with `0.`
the addon is in beta. The middle number goes up for new features or changes, the last number
for bug fixes only.

## 0.88.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- Loads on Classic Era (including Hardcore and Season of Discovery), TBC Anniversary, Mists
  of Pandaria Classic and retail (Midnight), as well as WoW Forever.
- Hearth/Teleport button: Dreamwalk, Death Gate, Zen Pilgrimage and the mage teleports of
  every expansion. Portals button: the mage portals of every expansion. Only spells your
  character knows are shown.
- Healthstone button: Master Healthstones (TBC) and the Demonic Healthstone (retail).

## 0.87.0 - 2026-10-25 (pre-release, not yet tested in game)

### Changed
- No more built-in item lists. Every item you carry is sorted by what the game says about it
  (item type and its "Use:" text) the first time it is in your bags, and the result is saved,
  so it is never looked at again unless Blizzard changes the item. New items, including ones
  added to WoW Forever later, work without an addon update.
- Item learning is always on, as the buttons now depend on it.

### Removed
- `/amac audit` and `/amac learn on/off`, and the "Learn new items automatically" option.
  Use `/amac assign` and `/amac unassign` if an item ends up on the wrong button.

## 0.86.0 - 2026-10-25 (pre-release, not yet tested in game)

### Added
- Anti-venoms are now recognised automatically (any item whose "Use:" line cures poison).
- `/amac audit` also saves what the game says about each item it could not sort (item type
  and "Use:" text), so the automatic sorting can be improved from real data.

### Changed
- The built-in item lists now hold original (vanilla) items only. Items from Burning Crusade
  onward and Season of Discovery were removed, which makes the addon lighter. The
  Hearth/Teleport button no longer lists later-expansion teleport items or spells (Death Gate,
  Zen Pilgrimage, Exodar/Silvermoon/Shattrath teleports).
- Items the automatic sorting had already checked are checked once more with the new rules.

## 0.85.0 - 2026-10-25 (pre-release, not yet tested in game)

First public release.

### Added
- `/amac audit`: checks every item on the built-in item lists against the automatic item
  learning and reports, per list, how many items learning sorts correctly. The details are
  saved after a `/reload`. This shows which built-in lists learning can replace, to make the
  addon lighter in future versions.

### Changed
- Item learning sorts each item only once and remembers it. Once per session, the first time
  an item is in your bags, it checks whether Blizzard has changed the item's tooltip. Only then
  is the item sorted again, and you are only told if its button changed. Items you sorted
  yourself (`/amac assign`, `/amac unassign`) are never touched.
- The action bar check is much lighter. It used to compare every action button once a second;
  now it only runs while something is on your cursor and for 3 seconds after you drop it.

### Features so far
- Draggable macros for Healthstones, health and mana potions, food, water, bandages,
  anti-venom, stat scrolls and elixirs, rage potions, buff food, flasks, weapon stones and
  oils, explosives, Hearthstone/teleports, mage portals and Comprehend scrolls, plus your own
  custom buttons (`/amac custom`).
- Each macro uses the best item in your bags; a flyout on hover lets you pick another.
- Empty buttons show a placeholder icon and highlight, and tell you what is missing.
- New consumables are sorted into buttons automatically.
- Settings page in Esc > Options > AddOns > AutoMacros (and in EllesmereUI, if installed).
