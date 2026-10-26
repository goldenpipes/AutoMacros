# Changelog

AutoMacros uses [Semantic Versioning](https://semver.org/): while the version starts with `0.`
the addon is in beta. The middle number goes up for new features or changes, the last number
for bug fixes only.

## 0.95.0 - 2026-10-26 (pre-release, not yet tested in game)

### Changed
- **Restore Health** (was Health Potion) and **Restore Mana** (was Mana Potion) take anything
  that restores health or mana: potions, healthstones, mana gems, Demonic and Dark Runes,
  Whipper Root Tuber, Night Dragon's Breath. Rejuvenation Potions are on both.
- Healthstones and mana gems come first. A Warlock or Mage who can make one but carries none
  makes one with a click (Create Healthstone / Conjure Mana gem); Shift+click then uses the
  best of what you do carry.
- The separate Healthstone button is gone: Restore Health is on for a character if either
  button was. Your Health Potion and Mana Potion macros stay on your bars (renamed); the old
  Healthstone macro is removed.

## 0.94.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- The icons at the top of the AutoMacros settings page glow, like spells in the spellbook that
  are missing from your action bars, when you carry items for that button but it is on none of
  your bars. Its tooltip says so too. The glow goes away as soon as you drag it onto a bar.

## 0.93.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- **Resistance** button: the Fire, Frost, Nature, Shadow, Arcane and Holy Protection Potions
  and anything else that raises a resistance (e.g. Gift of Arthas).

### Changed
- The Protection button is now **Armor Buff**: Scroll of Protection, Elixirs of Defense and
  anything else that raises Armor or Defense. Its settings and macro carry over.

## 0.92.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- One button per buff, whatever gives it: **Agility, Intellect, Stamina, Strength and Spirit
  Buff** take elixirs, scrolls, potions, Juju, E'ko and quest rewards like the Blasted Lands
  R.O.I.D.S., Ground Scorpok Assay, Lung Juice Cocktail, Cerebral Cortex Compound and Gizzard
  Gum. The popout lists them all, best first.
- **Protection**: Scroll of Protection, Elixirs of Defense and the Fire, Frost, Nature, Shadow,
  Arcane and Holy Protection Potions.
- **Other Buffs**: anything else that raises something for a while (attack power, spell damage,
  crit, speed, ...), e.g. Winterfall Firewater, Swiftness Potion, Juju Might.

### Changed
- The separate Scroll and Elixir buttons for each stat are replaced by the buff buttons. Your
  choices carry over: a buff button is on if its scroll or elixir button was. The elixir
  buttons' macros stay on your bars as the new buttons (renamed); the scroll buttons' macros
  are removed.
- Flask, Buff Food and Weapon Buff stay separate buttons.

## 0.91.0 - 2026-10-26 (pre-release, tested in retail)

### Changed
- The Popout page's Direction list shows only the buttons you have switched on. It updates
  when you switch buttons on or off.

## 0.90.0 - 2026-10-26 (pre-release, tested in retail)

### Added
- Popouts open in any direction. On Automatic (the default) each button works it out from
  where it is: to the right on a bar down the left side of the screen, to the left on the right
  side, up from a bar at the bottom and down from one at the top. The indicator moves to the
  side the popout opens from.
- Popout settings page: a Direction for each button (Automatic, Up, Down, Left, Right).

### Changed
- "Flyout" is now called **popout** everywhere: the settings page, its options and
  `/amac popout` (`/amac flyout` still works).

## 0.89.3 - 2026-10-26 (pre-release, tested in retail)

### Fixed
- A button could still open another button's flyout (hovering Bandage showed your water), get
  its highlight or its empty tooltip. Buttons on your bars are now recognised by their macro's
  name.

## 0.89.2 - 2026-10-26 (pre-release)

### Fixed
- Macros are matched by name after one is created, renamed or deleted (the game keeps them in
  name order, so the others move).

## 0.89.1 - 2026-10-26 (pre-release, tested in retail)

### Fixed
- Stat scrolls (Scroll of Stamina, Intellect, ...) were not recognised on retail.
- Fortitude elixirs (which raise maximum health) now go on the Stamina Elixir button.

## 0.89.0 - 2026-10-26 (pre-release, tested in retail)

### Added
- The Buttons settings page shows which switched-off buttons you could use: a green number on
  the icon and "(3 in bags)" next to the checkbox when you carry matching items. It updates as
  your bags change.

### Changed
- Which buttons are on or off is now saved per character. Your current choices are copied to
  each of your characters once, then each can be changed on its own.
- Turning off a button whose macro is shared by all characters (everything except Healthstone,
  Comprehend and Portals) no longer deletes the macro while another character still uses it.
- A new character only gets buttons switched on for what it carries, not for macros your other
  characters made.

## 0.88.2 - 2026-10-26 (pre-release)

### Fixed
- Buff food was sorted again every session instead of being remembered.

## 0.88.1 - 2026-10-26 (pre-release, tested in retail)

### Fixed
- Some items (your Hearthstone, several drinks and breads) were checked before the game had
  loaded their "Use:" text and were wrongly remembered as fitting no button. The addon now
  waits for that text and looks again a second later. Items affected are sorted again.

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
