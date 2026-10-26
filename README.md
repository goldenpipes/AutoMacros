# AutoMacros

A World of Warcraft addon that keeps a macro for each kind of consumable (Healthstones,
potions, food, water and more) pointed at the best item in your bags. Drag the macros onto
any action bar you like: no extra bar to place, unlike AutoBar.

Made for **WoW Forever**. It also loads in retail, which is used for testing.

> **Beta.** Versions starting with `0.` are still in development, so expect changes. See
> [CHANGELOG.md](CHANGELOG.md) for what changed in each version.

## Features

- **One macro per category**, always using the best item you carry (highest level you can use).
  Macros are only rewritten out of combat.
- **Flyout picker:** hover over a button holding one of these macros to see every item of that
  kind in your bags. Click one to make it that button's choice (remembered per character).
- **Empty buttons stay useful:** when you run out, the button keeps a placeholder icon, gets a
  highlight, and its tooltip tells you what is missing.
- **Learns new items:** consumables that are not on the built-in lists are sorted into the
  right button automatically, from what the game says about them. Each item is checked once
  and re-checked only if Blizzard changes it.
- **Saves macro slots:** class buttons go in the character macro tab, everything else in the
  shared tab.
- **Settings page** in Esc > Options > AddOns > AutoMacros (also inside EllesmereUI when it is
  installed), with a live preview: highlight, flyout and button look.
- Lightweight: no libraries required. Work happens when your bags or bars change, not on a
  timer; the only regular check is a quick look at the cursor, to catch macros dropped on a bar.

### Buttons

| Recovery | Food & drink | Buffs | Utility | Class |
|---|---|---|---|---|
| Healthstone | Food | Stat scrolls (Agi, Int, Sta, Str) | Bandage | Mage portals |
| Health potion | Water | Stat elixirs (Agi, Int, Sta, Str) | Anti-venom | Mage Comprehend scrolls |
| Mana potion | Buff food | Flask | Hearthstone / teleport | |
| Rage potion | | Weapon stones and oils | Explosives | |

You can also make your own buttons from any items or spells (`/amac custom`).

A button turns itself on the first time you carry one of its items, and stays on after that.
Switch buttons on or off in the settings or with `/amac add` / `/amac remove`.

## Installing

1. Download `AutoMacros-<version>.zip` from the [Releases](../../releases) page.
2. Extract it into your AddOns folder, so you end up with
   `World of Warcraft\_forever_\Interface\AddOns\AutoMacros\AutoMacros.toc`.
3. Log in, open your macros (`/macro`) and drag the `AM_...` macros onto your bars.

## Commands

`/amac` and `/automacros` both work.

| Command | What it does |
|---|---|
| `/amac` | Update now and print what each macro is using |
| `/amac options` | Open the settings |
| `/amac list` | List every button and whether it is on |
| `/amac add <name>` / `/amac remove <name>` | Switch a button on or off (off deletes its macro) |
| `/amac custom <name> items <id,id,...>` | Make your own button from items (or `spells`) |
| `/amac custom <name> delete` | Remove your own button |
| `/amac assign <item> <name>` | Put an item on a button by hand (item ID or shift-click link) |
| `/amac unassign <item>` | Take an item off the button it was learned for |
| `/amac learned` | Show the items learned so far |
| `/amac learn on` / `off` | Switch automatic item learning on or off |
| `/amac audit` | Check the built-in item lists against item learning |
| `/amac next` | Mages: switch to the next untranslated scroll |
| `/amac flyout` | Switch the hover flyout on or off |
| `/amac names` | Show or hide the macro names on buttons |
| `/amac glow` | Switch the empty-button highlight on or off |
| `/amac tooltip` | Clean or stock tooltip on empty buttons |
| `/amac style reset` | Put the look back to its defaults |
| `/amac status` | Saved-data and EllesmereUI status |

## Reporting problems

Open an [issue](../../issues) with what you did, what happened, and what `/amac` printed.
Lua errors are printed once in chat with the part of the addon they came from.
