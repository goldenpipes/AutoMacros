# Changelog

AutoMacros uses [Semantic Versioning](https://semver.org/): while the version starts with `0.`
the addon is in beta. The middle number goes up for new features or changes, the last number
for bug fixes only.

## 0.108.4 - 2026-10-26 (pre-release, not yet tested in game)

### Fixed
- Goblin Dragon Gun and Steel Weapon Chain no longer land on Weapon Buff.
- Mechanical Repair Kit (heals a mechanical pet) no longer lands on Restore Health.
- Frozen Rune and Engineering's Flame / Ice Deflectors go on Resistance.

## 0.108.3 - 2026-10-26 (pre-release, tested in Classic Era)

### Fixed
- Classic Era: Anti-Venom (filed as a reagent) now goes on Debuff Cure.
- Classic Era: sharpening stones, weightstones and wizard / mana oils (filed as trade goods)
  now go on Weapon Buff.
- Classic Era: Mana Agate and the other mana gems were still skipped; they go on Restore Mana.
- The rules test also lists reagents and trade goods with a "Use:" line that fit no button.

## 0.108.2 - 2026-10-26 (pre-release, not yet tested in game)

### Fixed
- Usable items Classic files as armor (Mana Agate) were skipped.
- Cleansing Water, Moist Towelette and the like now go on Debuff Cure; quest items that
  "cure" something (a sick animal, a brazier) go on Quest Item instead.
- Utility potions go on Other Buffs: invisibility, invulnerability, water breathing, water
  walking, detect undead / demons.
- Rogue poisons that coat "a sword or dagger" go on Weapon Buff, not Explosive.
- Plain reagents in your bags are no longer checked again and again each session.

## 0.108.1 - 2026-10-26 (pre-release, tested in Classic Era)

### Fixed
- Permanent enchants and armor kits ("Permanently enchant ...", "Permanently adds ...") no
  longer land on buff, Restore Mana or Explosive buttons.
- Quest food you sit to eat (Clara's Fresh Apple) goes on Food, not Restore Health.
- Troll's Blood and Mageblood Potions (health or mana regenerated over an hour) go on Other
  Buffs; Greater Dreamless Sleep Potion on Restore Health and Mana.
- `/amac test` now records which AutoMacros version ran it, and splits items without data
  into "never answered" and "no Use: text".

## 0.108.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- **Quest Item** button (Utility): the quest items you use to do a quest ("Use: Place the
  totem at ..."). Quest items that heal or buff you stay on those buttons.

## 0.107.1 - 2026-10-26 (pre-release, not yet tested in game)

### Fixed
- `/amac test` asked the server for items too fast and got almost no answers. It now keeps
  at most 50 questions out at once, asks again after 10 seconds without an answer (3 tries),
  and so goes at the server's own pace.

## 0.107.0 - 2026-10-26 (pre-release, not yet tested in game)

### Changed
- `/amac test` waits for the server's answer for each item instead of retrying in rounds:
  items are sorted as their data arrives, items the server says do not exist are set aside
  at once, and it finishes when everything is answered.
- Gear is only looked at when it could teleport you (rings, trinkets, cloaks, necklaces,
  tabards), in the test and when learning: far fewer items to read.

## 0.106.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- A **Custom** settings page (under AutoMacros) to make your own buttons: drag an item from
  your bags or a spell from your spellbook onto the + to start a new button, named after it.
  Each button lists its items or spells: drag more onto its +, right-click one to take it
  out, type a new name and press Enter to rename it (its macro stays on your bars), or
  Delete it (its macro goes too). Your buttons also appear on the AutoMacros page straight
  away.

## 0.105.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- `/amac test` shows a progress window: a bar, what it is doing (finding items, asking the
  server, sorting) with a count, and a Stop button that turns into Close with a summary when
  it is done. Drag it anywhere.

## 0.104.2 - 2026-10-26 (pre-release, not yet tested in game)

### Fixed
- Choosing the **Class** color mode caused an error ("unable to find mixin or metatable
  (ColorMixin)") since 0.102.0.

## 0.104.1 - 2026-10-26 (pre-release, tested in Classic Era)

### Fixed
- Soft glow highlight: at higher thickness it shrank into a hard-edged box inside the button
  instead of glowing in from the edge. On square buttons (Classic) it now fades in from the
  button's edge, thickness setting how far; on retail's buttons the glow stays on the edge
  and grows inward in the button's shape.

## 0.104.0 - 2026-10-26 (pre-release, not yet tested in game)

### Fixed
- Classic Era: food and drink went on Restore Health, buff food too, and bandages on the
  Explosive button. Classic Era files nearly every consumable simply as "Consumable", so
  food, drink, buff food, bandages, flasks and rage potions are now recognised by their
  tooltip ("Must remain seated while eating", "well fed", "Heals 301 damage over 7 sec.",
  "one flask at a time"). Restore Health and Mana only take things that work at once.
  Everything is sorted again once.

## 0.103.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- `/amac test`: checks the item sorting rules against every item in the game (all of vanilla
  by default, or `/amac test <first ID> <last ID>`), using your client's own item data. It
  changes nothing; the result is saved for checking after a `/reload`. `/amac test stop`
  stops it.

## 0.102.0 - 2026-10-26 (pre-release, not yet tested in game)

### Changed
- The addon's code is split into several files instead of one big one. Nothing changes in
  game. If you install by hand, copy the whole AutoMacros folder (and delete the old
  AutoMacros.lua if it is still there; the new files no longer use it).

## 0.101.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- General > **Chat**: "Show info messages" (what the addon tells you by itself: items learned,
  buttons turned on, macros removed) and "Show the empty-button message" (the "No water in
  inventory." line when you click an empty button). Both on by default. Replies to /amac
  commands and problems you need to fix (macro slots full, ...) always show.

## 0.100.0 - 2026-10-26 (pre-release)

### Changed
- The icon tooltip says where the available ones come from: "1 available in bags",
  "3 available as spells", "4 available: 1 in bags, 3 spells", "3 available: 1 in bags,
  1 to create, 1 to craft".
- Cannibalize counts as available on the Bandage button for Undead characters.

## 0.99.0 - 2026-10-26 (pre-release, tested in retail)

### Changed
- On the settings page, a switched-off button now shows how many are **available**, not just
  carried: "(3 available)" and the green number on its icon. It also counts a healthstone or
  mana gem your class can make, and anything your professions can make right now (you know the
  recipe and carry every reagent), such as First Aid's bandages and healing potions.
- The addon learns your recipes when you open a profession window, so open each profession
  once for its recipes to count.

## 0.98.0 - 2026-10-26 (pre-release, not yet tested in game)

### Changed
- Anti-Venom, Disease Cure and Bleed Cure are one **Debuff Cure** button (Cure on the settings
  page). It takes anything that cures or removes poison, disease, bleeding, curses, magic,
  stuns or snares. It is on if any of the three was, and the Anti-Venom macro stays on your
  bars (renamed).

## 0.97.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- **Disease Cure** and **Bleed Cure** buttons (Recovery), next to Anti-Venom. Anything that
  cures or removes poison, disease or bleeding goes on each button it fits: Jungle Remedy,
  Purification and Restorative Potions on both Anti-Venom and Disease Cure, and on WoW Forever
  First Aid's Simple Poultice (disease) and Woolen Tourniquet (bleeds).
- Quest rewards and miscellaneous items now count for every helpful button they fit: health
  and mana, cures, stat buffs, Armor, Resistance and Other Buffs.

### Changed
- Fishing lures no longer count as Other Buffs.

## 0.96.0 - 2026-10-26 (pre-release, not yet tested in game)

### Added
- Undead: Cannibalize is on the Bandage button, after your bandages (used when you have none).

### Changed
- Shorter names on the settings page, where the section already says what they are: Health,
  Mana and Rage under Recovery; Agility, Intellect, Stamina, Strength, Spirit, Armor, Other
  and Weapon under Buffs. The macros on your bars keep their full names.

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
