# AutoMacros

WoW addon that scans the player's bags and automatically creates/rewrites draggable macros
for consumables (Healthstone, potions, food, water, etc.) so they can live on any action bar,
replacing AutoBar's clunky dedicated bar. Includes a hover flyout to pick which item a macro uses.

## Target client — important
- **WoW Forever** (Blizzard's Forever client). NOT Turtle WoW, NOT retail, NOT vanilla 1.12.
  All API usage must work on Forever.
- Testing happens in the **uiforever.com browser UI simulator** (flavor=forever) as well as in game.
  The simulator has quirks (e.g. it may not report the mouse position reliably), so prefer
  event-based / self-checking logic over polling the cursor.
- Default Blizzard UI has no "hide macro labels" option, so the addon hides the macro name text
  on buttons holding its own macros itself (`/amac names` toggles this).

## Versioning — always follow
- Every iteration is saved as its own version. Format is three parts: `0.24.0`, `0.25.0`, ...
  (bump the middle number by 1 per iteration: 0.24.0 -> 0.25.0 -> 0.26.0).
- Keep previous versions; older builds go in a `previous/` folder (e.g. `previous/0.24.0/`).
  The top-level `AutoMacros.lua` / `AutoMacros.toc` are always the current version.
- **Current version: 0.25.0.** Bump the version in the .toc and anywhere else it appears.
- When Lewis asks for a zip (for uploading to uiforever.com), build
  `releases/AutoMacros-<version>.zip` containing an `AutoMacros/` folder with only the
  addon files (`AutoMacros.toc`, `AutoMacros.lua`) — no CLAUDE.md, `previous/`, or `.git`.
- Lewis edits the Lua himself. Before building a new version, diff against the last one you
  produced and **merge his edits** — never overwrite them.

## Added in 0.25.0 (built in Claude on the web)
- Item learning: consumables missing from the built-in lists are classified once by item
  class/subclass + tooltip "Use:" line and saved in `AutoMacrosDB.learned` (bumping `CLASSIFIER`
  re-checks automatic results). `/amac assign|unassign|learned|learn on/off`. Only consumable
  subclasses 1-5 and 7 are considered — unverified whether Forever puts potions/food in subclass 0.
- Saved data: `AutoMacrosDB` now has `schema`, `sessions`, `style`, `learned`, `ignored`;
  `/amac status` reports whether data was restored.
- Options window: `/amac options` (tabs Highlight / Tab / Popup / General), all style values in
  `STYLE_DEFAULTS`, `/amac style reset`. Sliders use GetCursorPosition (may misbehave in simulator).
- EllesmereUI: optional skin + settings page via `EllesmereUI.RegisterSkin` / `RegisterPlugin`
  (API names unverified against EllesmereUI's source; all calls are pcall-wrapped).
  `.toc` has `## OptionalDeps: EllesmereUI, LibSharedMedia-3.0`.

## Feature set as of 0.24.0
- Macros are a category catalog: `/amac list`, `/amac add`, `/amac remove`, `/amac custom`
  (user-defined buttons).
- Categories: Healthstone, health potion, mana potion, food, water, bandage, anti-venom,
  stat scrolls, elixirs/buff potions, mage teleports and portals, mage Comprehend Scroll.
- Class-specific macros go in the **character** macro tab; everything else in the **general**
  tab (saves macro slots).
- Per-character flyout picks (the item chosen in the flyout becomes that macro's default).
- Healthstone: modifier switches between creating and using (Create Healthstone is castable in combat).
- Comprehend Scroll (mages): casts spell **1296017** when no untranslated scrolls are in bags;
  otherwise shows the scroll picked up. Untranslated scrolls have all-caps names, e.g. "Scroll: KWYJIBO".
  `/amac next` cycles scrolls.
- Flyout: opens on **hover** over the action button; shows the game's own item tooltip for entries;
  any click selects that item as the default (no left/right distinction). `/amac flyout` toggles,
  `/amac flyout test` opens a test popup.
- Action buttons holding active macros are recognised by **macro name** (their slot reports the
  item ID). Active macros are not rewritten on every refresh.
- `/amac items`: read-only probe of each consumable's item class and tooltip (exploring sorting
  by client data instead of fixed item lists).
- `/amac debug`; errors are reported once, not spammed.

## Empty-state behaviour (when no item of a category is in bags)
- Icon: an in-game item icon — Refreshing Spring Water (water), Empty Vial (health/mana potions),
  Tough Hunk of Bread (food). (Icon 1339440, a red X in a frame, was used before.)
- Macro body is the plain message, e.g. `No water in inventory.` — **no "#" anywhere.**
  Clicking the button prints that message in chat.
- Tooltip is a clean red message via a GameTooltip hook (`/amac tooltip` toggles), guarded
  against the game's tooltip rebuilds overwriting it.
- Button gets a highlight border.
- Titles use readable names: "Health Potion", "Mana Potion"; labels are plural where Lewis set them.

## Roadmap / ideas
- A config page for options and customization.
- Possibly derive categories from client item class data instead of hardcoded lists.
- Disease-removal items category (requested alongside bandages/anti-venom).

## Reference material Lewis has used
- AutoBar 12.1.0.02 (its `camelot` folder is the Forever version)
- FlyoutMacros 1.8.0
- lookino's Flyout 1.1.6 (vanilla 1.12 — reference for flyout UX only, not API)
