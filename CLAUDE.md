# AutoMacros

WoW addon that scans the player's bags and automatically creates/rewrites draggable macros
for consumables (Healthstone, potions, food, water, etc.) so they can live on any action bar,
replacing AutoBar's clunky dedicated bar. Includes a hover flyout to pick which item a macro uses.

## Folders (Lewis, 2026-11-01: "you can always access these files and folders")
- Project / git repo: `C:\Users\lewis\OneDrive\Documents\Coding Projects\Claude\WOW ADDONS\AutoMacros`
- Test client: `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\AutoMacros`
  (Forever is tested here); also `_forever_\Interface\AddOns\AutoMacros`.
- **Run on Lewis's PC** (Lewis, 2026-11-01: "always run on the PC unless i specify
  otherwise"): work in a local Claude Code session with a Windows shell, not a cloud
  session (a cloud session can only read/write files; it can't run mklink, git.exe, gh).
- **`_forever_` gets a plain copy, not a junction** (Lewis, 2026-11-02, after the
  CurseForge app replaced the junction and deleted project files through it three times;
  Lewis runs off `_forever_` and lets the app update the addon there). After every build
  (before handing it over) run `& .\tools\sync_forever.ps1`: it checks every file the .toc
  lists + the Media icon exists, removes a junction as a link only
  ([IO.Directory]::Delete(path, $false)), replaces a plain folder, copies the files and
  prints the version. **Never make a junction to this folder again**, and never use
  Remove-Item -Recurse on a junction (it can delete the target's files).
  `tools\link_clients.bat` is out of date for `_forever_`.
- Lewis has given standing OK to read and write these. From a cloud session, ask for
  access to these exact folders at the start without asking him first (the access prompt
  still shows once per session).

## Target client — important
- **WoW Forever** (Blizzard's Forever client). NOT Turtle WoW, NOT retail, NOT vanilla 1.12.
  All API usage must work on Forever.
- Testing happens in the **uiforever.com browser UI simulator** (flavor=forever) as well as in game.
  The simulator has quirks (e.g. it may not report the mouse position reliably), so prefer
  event-based / self-checking logic over polling the cursor.
- Default Blizzard UI has no "hide macro labels" option, so the addon hides the macro name text
  on buttons holding its own macros itself (`/amac names` toggles this).

## Versioning — always follow
- **One version per session** (Lewis, 2026-11-01: "this session should be a bump, and
  have bugfixes to this session be 0.XXX.1"), **semver MAJOR.MINOR.PATCH**:
  - a session with new features or changed behaviour bumps the middle number once, patch
    0 (0.138.0 -> 0.139.0). Every change in that session goes into that same version;
    don't bump again per iteration;
  - a later session that only fixes bugs in it bumps the last number (0.139.0 -> 0.139.1);
  - once a version is committed and released, the next session starts a new one.
  - (Up to 0.138.0 every iteration got its own version.)
  - `1.0.0` = first stable release (Lewis, 2026-11-06). From here: 1.1.0 for a session with
    new features or changes, 1.0.1 for bug fixes only.
- **CHANGELOG.md**: every version gets an entry at the top (date, Added / Changed / Fixed /
  Removed), written for players, not code notes (those stay in this file).
- **GitHub Releases** are only for builds worth downloading. Every iteration is still
  committed and pushed.
- Keep previous versions; older builds go in a `previous/` folder (e.g. `previous/0.24.0/`).
  The top-level `AutoMacros.toc` and the `.lua` files it lists are always the current version
  (up to 0.101.0 it was one `AutoMacros.lua`).
- **Current version: 1.1.0.**
- **Copy the current files (`AutoMacros.toc` + every `.lua` the .toc lists, keeping the
  `Games\<game>\` subfolders) into `previous/<version>/` BEFORE the first edit of a new
  version** (once per session, not per iteration) (missed twice; 0.32.0 had to be rebuilt by reversing edits). Bump the version
  in the .toc and in Core.lua's first line.
- When Lewis asks for a zip (for uploading to uiforever.com), build
  `releases/AutoMacros-<version>.zip` containing an `AutoMacros/` folder with only the
  addon files (`AutoMacros.toc`, the `.lua` files it lists **with their `Games/<game>/`
  subfolders**, and the `Media\AutoMacros.tga` icon since 0.129.0) — no CLAUDE.md,
  `tools/`, `previous/`, or `.git`. Entry names use forward slashes.
- **GitHub:** public repo https://github.com/goldenpipes/AutoMacros, branch `master`.
  git = GitHub Desktop's `%LOCALAPPDATA%\GitHubDesktop\app-*\resources\app\git\cmd\git.exe`
  (not on PATH; resolve the wildcard, the folder changes when Desktop updates). Push auth is
  the GitHub CLI `C:\Program Files\GitHub CLI\gh.exe` (logged in as goldenpipes; set up as
  git's credential helper for github.com in the global gitconfig). When a version is
  committed: `git push origin master`; for a release, also build the zip and
  `gh release create v<version> releases/AutoMacros-<version>.zip --title "AutoMacros <version>" --notes-file <that version's CHANGELOG section>`
  `--prerelease`.
- **Every release is `--prerelease` (beta on CurseForge) unless Lewis says otherwise for
  that release** (Lewis, 2026-11-01: "always prerelease unless i specify otherwise"),
  tested in game or not. Don't ask which type; just use pre-release. (v1.0.0 was a full
  release because Lewis said so; that doesn't change the default for later ones.)
- Lewis edits the Lua himself. Before building a new version, diff against the last one you
  produced and **merge his edits** — never overwrite them.
- **Every commit message ends with** a blank line and `Co-Authored-By: Claude
  <noreply@anthropic.com>` (Lewis, 2026-11-01: credit Claude on the repo; GitHub builds
  contributors from commits, there is no list to add someone to). Write the message with
  the Write tool and `git commit -F <file>` (no BOM). The README has a "Built with Claude"
  shields.io badge (logo=claude, D97757) linking to anthropic.com/claude-code.

## Before handing over any build — always
- Run `python -I tools\luacheck.py AutoMacros.toc`. For every file the .toc lists it checks
  block/bracket structure, the shared-table header, and the number of **top-level locals**:
  WoW's Lua 5.1 refuses a file with more than 200, and then NOTHING loads (0.30.0 broke this
  way). Since the split each file has only its header's 2.
- There is no Lua interpreter here; the checker is the only pre-flight test.
- Then copy the build into the game: `& .\tools\sync_forever.ps1` (see Folders). Lewis's
  own Lua edits only reach the game after the next copy.

## Code layout (since 0.102.0)
- **Per-game files (since 0.121.0, Lewis: keep each game's things separate; only files a
  game needs go in its subfolder).** `Game.lua` loads first and sets `GAME` from the
  interface number: "forever" (16xxx), "classicera" (other < 20000), "tbc" (20000-49999,
  so a Wrath/Cata client would get TBC's lists), "mists" (50000-99999), "mainline"
  (>= 100000). Then `Games\Forever|ClassicEra|TBC|Mists|Mainline\
  Lists.lua`, each starting `if GAME ~= "<game>" then return end` after the header: every
  game file loads on every client but only the running game's sets anything. They hold
  TRAVEL_SPELLS, PROFESSION_SPELLS, TRACKING_SPELLS, PORTAL_SPELLS, HS_RANK, CREATE_HS,
  MANA_GEM_RANK, CONJURE_GEM, each with only that game's IDs (its expansion and earlier).
  Core keeps HEARTHSTONE and builds MADE from them. Something new that differs by game goes
  in those folders, not behind `if` checks in the shared files. (Not per-game .toc files:
  Forever's .toc suffix is unknown.)
- Files, in .toc (load) order: Game, Games\*\Lists, Core (lists, saved data, style, colours, CATALOG, on/off,
  Print/Note/Fail), Macros (bag scan, choosing, macro text, Find/Apply/DeleteManaged), Art
  (BLIZZ_ART, button art, StyleGlow, StyleArrow, popout bar art), Bars (POPOUT direction,
  finding action buttons, highlight, empty tooltip), Learning (Classify, LearnNew), Update
  (AutoEnable, UpdateCore, Update), Popout (the popout, indicators, labels), Widgets, Options
  (UI: Buttons page, availability, recipes, previews), OptionsPages (PAGES, BuildPage, the
  AddOns panel), Custom (your own buttons + their rows on the Buttons page; since 0.106.0),
  Welcome (first-login window, since 0.113.0), EllesmereUI,
  Events (Schedule, bar watcher, migrations, Init, events, /amac).
- When searching code, keep to the top-level `*.lua`: `previous/` holds every old build.
- **Every file starts with** `local ADDON, ns = ...` / `setmetatable(ns, { __index = _G })` /
  `setfenv(1, ns)`: the addon's table is each file's environment. A name assigned at a
  file's top level (`function Update()`, `MACROS = {}`) is shared with all files; anything
  not ours falls through to _G. Use `local` only for what one file/function needs.
  **Real globals must be written as `_G.X`** (AutoMacrosDB, SLASH_AUTOMACROS1/2); a plain
  `X = ...` lands in the addon's table.
- Names resolve when code runs, so a function may use names another file defines later;
  only code that runs while the files load needs things from earlier files (order matters
  for e.g. CATALOG using TRAVEL_SPELLS).
- **Game functions that return an object look its mixin up in the caller's environment
  without the _G fallback** (C_ClassColor.GetClassColor -> "unable to find mixin or metatable
  (ColorMixin)", 0.104.2). Core.lua copies every `*Mixin` table from _G into ns at load
  (rawset). A mixin from a load-on-demand Blizzard addon loaded later would not be copied:
  if a new error names one, copy it too.

## Next up (left off 2026-10-26)
- 0.88.0 built and checked, not tested in game. Lewis decided to **wait for Forever's release**
  before checking the learning rules there. Meanwhile the addon also targets the other
  clients (see 0.88.0). Lewis only has retail and Forever installed; the Classic clients need
  installing before they can be tested. Per client still to check in game: learning rules
  (carry items, see what lands where), Healthstone, settings page templates, bar art.
- Once Forever is out: buttons depend entirely on the learning rules, so check them there.
  Offline option (Lewis declined for now): Wowhead's per-item
  XML for Forever (`https://www.wowhead.com/forever/item=<id>&xml`, works from PowerShell;
  gives class, subclass, htmlTooltip with the "Use:" text) for the vanilla consumables in
  `previous/0.86.0/AutoMacros.lua` DATA, run through a Python copy of Classify. Wowhead's
  listing pages (e.g. /forever/items/consumables/potions) return 403 to scripts: don't
  scrape those. ForeverDB (foreverdb.net) is datamined from the Forever client but has no
  API or download.

## CurseForge (2026-10-27)
- Lewis is releasing on CurseForge as **Forever only** for now, as a pre-release (CurseForge
  release type Beta). **WoW Forever's beta is over** (the game is out): don't call the
  game or the addon a Forever beta in shown text.
- Forever-only build: `releases\AutoMacros-<v>-forever.zip` = the normal files with the
  .toc's Interface line cut to `16001` and only `Games\Forever\` listed/included (built
  by a one-off PowerShell step; the repo .toc stays all-clients). CurseForge text (summary,
  description, file changelog) in `releases\curseforge-<v>.md`; logo
  `releases\AutoMacros-logo.png` from `tools\make_logo.ps1` (System.Drawing: button with a
  red potion, popout above with mana potion and green elixir, the selected one ringed in
  gold). releases/ is gitignored; Lewis creates the project and uploads himself.
- Unknown: whether CurseForge lists a WoW Forever game version yet.
- **README.md is also the CurseForge description** (Lewis, 2026-10-28). CurseForge has no
  API for the description (only file uploads), so Lewis pastes README.md into CurseForge's
  editor (Markdown mode) by hand. Keep the README **plain Markdown, no HTML, every link
  and image a full https:// address** (images from
  `https://raw.githubusercontent.com/goldenpipes/AutoMacros/master/docs/...`; no relative
  paths like `../../releases` or `CHANGELOG.md`). Whenever a version changes the README,
  tell Lewis to paste it into CurseForge again. Lewis pasted it in on 2026-10-28.
- The CurseForge project **is approved and public** (checked 2026-11-01 in the browser
  pane: https://www.curseforge.com/wow/addons/automacros, by SchwansCS, 27 downloads).
  Scripts get 403 from curseforge.com (bot check); use the browser pane to look. The
  README links it in the Installing step and has a badge first in the badge row:
  shields.io `curseforge/dt/1769719` (logo=curseforge, color F16436, live download count).
- **Automatic upload** (`.github/workflows/curseforge.yml`): on every published GitHub
  release (or by hand for a tag) it runs luacheck, builds the Forever zip with
  `tools/build_zip.py --game forever` and POSTs it to
  `https://wow.curseforge.com/api/projects/<id>/upload-file` (header X-Api-Token; metadata:
  release notes as markdown changelog, displayName = zip name, releaseType beta for a
  pre-release else release, gameVersions = IDs looked up by name from /api/game/versions).
  Needs repo secret `CF_API_TOKEN` and variables `CF_PROJECT_ID`, `CF_GAME_VERSIONS`
  (names, comma-separated; an unknown name makes the run print the names CurseForge has).
  Lewis set them: project **1769719**, game version **1.60.1** (CurseForge id 17053).
  **Works:** first run (by hand for v0.128.0, run 40596286177) uploaded
  AutoMacros-0.128.0-forever as beta, file id 9347729. It checks out the release tag into
  `src/` and the default branch into `ci/`, and builds src with ci's tools
  (`build_zip.py --root src`), so older tags build too. Releasing = `gh release create`
  as before; the upload follows by itself (watch the Actions tab / `gh run list`).
  Pushing workflow files needed the CLI's `workflow` scope (added 2026-10-27).
- `tools/build_zip.py [--game <game>]` builds release zips (all games, or one game's
  Interface number + Games folder); use it instead of hand-made PowerShell zips. It and
  luacheck.py read the .toc's `\` paths on Linux too.

## Releases (2026-10-27)
- Lewis wants **only the latest release shown on GitHub**: v0.128.1 published as a
  pre-release (notes: changelog since 0.120.0), then every older release deleted with its
  tag (`gh release delete <tag> --cleanup-tag --yes`). `git fetch --prune --prune-tags` also
  dropped the local-only tags v0.24.0/v0.25.0 (commits e2d8a82, 3b7af1a still there).
  When publishing a new version, ask whether to delete the previous release again.
- v0.128.1's CurseForge upload ran by itself off the release (run 40597397284, file id
  9347782): the automatic path works.

## Where things stand (2026-10-27, end of session)
- **0.128.0 released as a pre-release** (v0.128.0, zip in releases/, notes = every changelog
  section since 0.120.0). Lewis: "looks great, done for now" after checking the learned
  list and the EllesmereUI Popout page. This session: Games\ folders, retail test fixes,
  the retail soft glow (settled in 0.127.2), learned list, EUI demo column.
- Retail UI still to look at: solid border highlight on rounded buttons, popout items'
  hover / pressed / selected look, "Show background" art and dividers.

## Where things stood (2026-10-26, end of session)
- **0.120.0 released as a pre-release** (v0.120.0, zip in releases/); Lewis is handing it
  out to Classic Era testers. Other clients (retail, TBC Anniversary, MoP, Forever) come
  later. He'll come back with more ideas and tester feedback.
- **Possible rename** (Lewis is asking testers first; nothing renamed yet): favourites
  **AutoPop**, AutoPopouts, Popouts. Macros stay (they work on any bar addon; own buttons
  would mean rebuilding a bar system). A rename touches: folder + .toc, SavedVariables
  (copy AutoMacrosDB once), slash commands (keep /amac as an alias), GitHub repo (rename
  redirects old links; ask before doing it) and release names.
- Still unchecked in game: Weapon Buff with sharpening stones, an unworn teleport ring,
  EllesmereUI bars, the Professions / Tracking spell IDs, ActiveTracking on Classic Era,
  0.117.1's settings-after-combat, the welcome window's look.

## TBC Anniversary test setup (2026-10-29)
- Lewis is installing/testing **TBC Anniversary** (folder `_anniversary_`, product
  wow_anniversary, build 2.5.6.70577). `_anniversary_\Interface\AddOns\AutoMacros` is a
  **junction to this project folder** (made 2026-10-29), like retail's and Classic Era's.
  The .toc already lists 20506 (unconfirmed: check `/dump select(4, GetBuildInfo())`);
  Game.lua maps 20000-49999 to GAME "tbc" (Games\TBC\Lists.lua). Release on hold until
  this test (Lewis, after pushing 0.132.0).
- **TBC Anniversary: works** (Lewis, 2026-10-29: "tbc works perfectly", 0.132.0). Not
  itemised what he checked; the .toc's 20506 evidently loads.
- **MoP Classic** too: folder `_classic_` (product wow_classic, build 5.5.4.70631, .toc
  50504, GAME "mists"). It had never been started (no Interface folder): made
  `_classic_\Interface\AddOns` and the junction there, 2026-10-29. **Works, no errors**
  (Lewis, 2026-10-29, 0.132.0).
- Lewis also asked for **Wrath**: no Wrath client exists here, and Blizzard has no live
  Wrath Classic (it progressed to Cata, then MoP). Not set up; a Wrath client would get
  TBC's lists (Game.lua maps 20000-49999 to "tbc").
- **CurseForge now every client** (Lewis, 2026-10-29, after TBC + MoP worked): the workflow
  builds the all-clients zip (`build_zip.py --root src --out out`, no `--game`; file name
  AutoMacros-<v>, no -forever) and `CF_GAME_VERSIONS` = "1.60.1, 1.15.9, 2.5.6, 5.5.4,
  12.1.5" (set with gh variable set). **Works:** CurseForge knew all five names; v0.132.0's
  upload (run 40978632998) put up AutoMacros-0.132.0 as beta, file id 9367363. (An unknown
  name would stop the upload and print CurseForge's names.) README line 6 now says it works in
  all five; Lewis must paste the README into CurseForge again. The "Forever only for now"
  notes in the CurseForge section are out of date.
- .build.info now (2026-10-29): Forever 1.60.1.70685, retail 12.1.5.70575, Era
  1.15.9.70576, Anniversary 2.5.6.70577, MoP 5.5.4.70631.

## 1.1.0 — Openable Items button (2026-11-06)
- Lewis: a button for openables, called 'Openable Items'; Rogues pick locked boxes, and
  blacksmiths' keys open them too.
- Wowhead Forever XML: Small Barnacled Clam 5523 is 7.11 `<Right Click to Open>`, Dented
  Crate 6351 is 15.4 the same, Ornate Bronze Lockbox 4632 / Iron 4634 are 15.4 `Locked`
  (no lock skill in the tooltip). Skeleton keys 15869 Silver .. 15872 Arcanite are 0.8,
  "Use: Allows opening of simple / hard locks."
- Learning (CLASSIFIER 22): tooltip line equal to ITEM_OPENABLE or LOCKED -> `openable`;
  Use line with "opening of" + "locks" -> `skeleton_key` (no button). Both right after
  `permanent`, so before the class 5/7 branch (clams are 7.11).
- By item ID the tooltip always says Locked, so `OpenableSlots()` (Macros.lua) reads each
  slot's own tooltip (`BagTooltipLines`, SetBagItem): id -> { bag, slot, locked }, an
  unlocked one first. `OpenableList(have)` is what Candidates returns for set `openable`:
  unlocked first; locked only with `entry.unlock` = "/cast Pick Lock\n/use bag slot"
  (1804, `PickLockName`), else "/use item:<key>\n/use bag slot".
- Lewis: cheapest key first, always, and Rogues only when they can. The client's tooltip
  gives no lock skill, so `LOCK_SKILL` (Macros.lua, by item ID, all games: vanilla boxes,
  numbers from warcraft.wiki.gg's box pages and Lockpicking page, IDs checked on Wowhead
  Forever) and `KEY_SKILL` (15869 Silver 25, 15870 Golden 125, 15871 Truesilver 200,
  15872 Arcanite 300; the wiki's Silver page says 15, its Lockpicking page 25).
  `LockSkill()`: GetSkillLineInfo "Lockpicking", else 5 x level (retail; enUS name only).
  `CheapestKey(keys, need)`: lowest cap >= need; a box not listed takes the cheapest, a
  key not listed comes last. Pick Lock needs skill >= need; a box neither can open is left
  out. Numbers are vanilla's: Forever could differ.
- UpdateCore: `entry.unlock` body = #showtooltip + those lines. BodyMatches accepts
  "/use N N" for set openable. Popout: t "macro", v = entry.unlock, OPEN_SNIPPET sets
  `macrotext`; entry tooltip "Click to unlock it".
- CATALOG `openable` (AM_Openable, "Openable Items", empty "No Openables": macro names
  stop at 16 letters; placeholder 5523), Utility group. README row added: **paste README
  into CurseForge again.** Untested in game: macrotext on the popout's secure items,
  /use bag slot on Pick Lock's cursor, the box updating after it is unlocked.

### Scrapped (Lewis, 2026-11-07: "scrap the offhand items thing altogether")
Everything below in this section was **removed before 1.1.0 was released**: none of those
functions or rules exist in the code (gear with a Use line on buttons, /equip in UseBody,
OffHandSwap, AMDropSlot, CLASSIFIER 23; it stays 22). The notes stay for what they found
out about the game. The code: `releases\gear-offhand-scrapped-2026-11-07.patch` (a diff
against 62b0919).

- Lewis: Ley Orb and other such items on the buttons they fit. Ley Orb 7508 is 4.0 held
  off-hand, "Use: Restores 80 to 240 mana", skipped because gear only counted for
  teleports. Class 2 is now in LOOKED_AT; `IsGear(class, slot)` (weapons, worn armour):
  CLASSIFIER 23, no Use line -> {}, else sub = -1 like quest / misc items (restoring,
  buffs, utility, enemy; no food, weapon_buff, explosives by sub). Checked on Forever:
  Insignia of the Alliance 18854 "Dispels all Immobilizing, Slowing and Stun" -> cure,
  Gnomish Cloaking Device 4397 -> utility, Cold Basilisk Eye 5079 -> enemy.
- `WorthALook(id, noGear)`: the rules test passes true, so `/amac test` does not ask the
  server about all gear, and shows no gear (it stays out of the test's results).
- Candidates (not Hearth/Teleport): equippable items score -1e9 worn, -2e9 not, so
  consumables, then worn gear, then bag gear. The popout shows bag gear gray. Every piece
  of gear carried now gets an `ignored` entry in saved data. Untested in game.
- Lewis: not worn -> a click on the bar equips it, taking off a staff for an off-hand if
  needed; these items work like trinkets, with a cooldown after equipping. `UseBody(id)`
  adds `/equip item:<id>` before the /use while NeedsEquip(id) (every UseBody button, so
  unworn Hearth/Teleport gear too). The /use stays so a later click works in combat, where
  the macro can't be rewritten; PLAYER_EQUIPMENT_CHANGED drops the /equip after combat.
  The first click's /use may give a red error while the swap is under way. The popout's
  gray items still don't equip in combat (PostClick).
- Lewis, in game (Forever, staff 248008, 2026-11-06): /equip of Ley Orb works with no
  staff, but **the game does not put an off-hand on over a two-hander**. A failed attempt
  **locks the weapon until logout** (IsInventoryItemLocked(16); /reload doesn't reliably
  clear it, so test from a fresh login). Failed: PickupInventoryItem(16) +
  PutItemInBackpack/PutItemInBag; macro `/click CharacterMainHandSlot` + `/click
  CharacterBag0Slot` in one click.
- **Works (Lewis, 2026-11-06: "It works"; bar button, out of combat, Forever):**
  `OffHandSwap(id)` = `/click CharacterMainHandSlot` (only with a free slot) + `/amac equip
  <id>`; `DropStaffFor(id)` waits one frame (C_Timer.After(0); Lewis tried a test command:
  0 works, so 0.3 s was not needed), then PickupContainerItem on one exact empty slot
  (`FreeSlot`), keeps `offHandWanted`, and on PLAYER_EQUIPMENT_CHANGED or a 0.5 s timer
  (within 5 s) `FinishOffHand` calls EquipByID (not in combat: the rebuilt macro's next
  click does it). Exact slot in the same frame as the lift was never tried. No /equip
  or /use in that body: they may lock the weapon too. `TwoHanderInTheWay(id)` =
  `IsOffHand` (`OFF_HAND_SLOTS`) + main hand in `TWO_HAND_SLOTS`; TwoHanderMessage when
  there's no bag room. The weapon stays in bags. Not re-tested after removing the trace.
  Popout: PrepareSecure gives such an item t "macro" = OffHandSwap, PostClick skips
  EquipByID for it (Set only: message). Untested: popout, other clients.
- **In combat the game blocks an addon's PickupContainerItem** (Lewis's BugGrabber:
  ADDON_ACTION_BLOCKED, from the timer in DropStaffFor). So the swap is out of combat only:
  `/click [nocombat] ...` (from memory that /click takes conditions; not found in
  Forever's source), and DropStaffFor checks InCombatLockdown (ClearCursor + a message)
  in case. Untested in game.
- Lewis: in combat he can drag the staff to a bag by hand, then equip the orb. A macro
  can't. His macro tests: `/click CharacterMainHandSlot` lifts it (in combat too), but
  **`/click CharacterBag0Slot` locks the weapon even on its own key press**, so the bag
  button (PutItemInBag) is what fails; only an exact-slot PickupContainerItem works, and
  an addon can't call that in combat. `/use <bag> <slot>` on an empty slot with it on the
  cursor does nothing. `/equipslot 17 item:7508` over a staff does nothing. AutoBar
  (MuffinManKen/AutoBar) never takes a weapon off; it equips with `/equipslot <slot> <bag>
  <slot>`.
- **Works in combat (Lewis, 2026-11-06, two macros on keys):** lift, then on a second
  press `/click` on our hidden copy of Blizzard's bag slot button (`UpdateDropSlot`:
  frame `AMDropSlot`, ContainerFrameItemButtonTemplate, parent `AMDropBag`; parent's
  SetID = bag, own SetID = slot, kept on FreeSlot on PLAYER_ENTERING_WORLD and
  BAG_UPDATE_DELAYED, in combat too; not protected). Lift + that drop in one macro press
  fails (no /wait in macros).
- OffHandSwap: `/equip` + `/use [combat,nocursor,noequipped:<main hand's subtype>]
  item:<id>`, then one line `/click [cursor] AMDropSlot; CharacterMainHandSlot`, then
  `/amac equip <id>`. First try had separate /click lines and [noequipped] without
  [combat,nocursor]: Lewis: "doesn't work at all", no details (suspect: a lifted weapon
  doesn't count as equipped, so /equip fired and locked it; unconfirmed). **255-letter
  macro limit**: about 215 letters + 2 x subtype + 3 x ID length, so #showtooltip uses
  item:<id>, not the name. Out of combat one press (DropStaffFor's timer). In combat:
  press lifts, press drops, press equips. Untested in game, incl. `;` in /click, [cursor]
  there, `[noequipped:Staves]`, and a **mouse click with the weapon on the cursor** (may
  land on the button).

## 1.0.0 — first stable release (2026-11-06)
- Lewis: "push the current version as 1.0 and make it public on curseforge". Same code as
  0.140.0, only the version changed. Full GitHub release (no --prerelease), which the
  workflow uploads as CurseForge release type "release", not beta.
- **Committed** (332173a) and **released** 2026-11-06 as v1.0.0, Latest on GitHub (notes:
  its changelog section); CurseForge upload run 42236840950, file id 9474793, type
  release. README unchanged, so no paste needed. v0.140.0's release and tag deleted:
  v1.0.0 is the only GitHub release.

## 0.140.0 — session of 2026-11-02
- **Committed** (caef378), **released** 2026-11-03 as pre-release v0.140.0 (notes: its
  changelog section); CurseForge upload run 41558106367, success. v0.139.0's release
  and tag deleted: v0.140.0 is the only GitHub release. (A push alone uploads nothing:
  CurseForge only gets a file from a published release.)
- Lewis (EUI screenshot of Per-Button Overrides): Item size and Item spacing should be
  sliders. `UI.OwnPopoutNumber(label, dbKey, styleKey, lo, hi, step, fmt, disabled)` is now
  a `range` item: get = the button's own value, else Style(styleKey) (the global); set
  saves the override and only runs PrepareSecure (no page refresh while dragging). Moving
  a slider always makes an override; the `button` item "Use global size and spacing"
  clears both (UI.PopoutChanged). Spacing is greyed out with the bar background on
  (Blizzard's page; EUI sliders ignore `disabled`). Untested in game.
- Lewis: the Popout page demo should show the button picked in Per-Button Overrides,
  with the current demo as the default. The Button choice now starts with "Example"
  (`_example`; `UI.popoutKey` nil). `UI.PopoutEntry()` returns nil then (no more
  fallback to the first button), and UI.EachButtonItems shows only the choice + a note;
  the override rows are `UI.OwnPopoutItems()`. `UI.EnabledStamp` includes the picked key,
  and `UI.RefreshPanels` now rebuilds a visible page whose stamp changed (UI.ShowPanel);
  EUI gets RefreshEUIPage(true) from the Button setter.
- `UI.DemoPopout()` -> { icon, count, selected } list + button icon: the picked button's
  `flyoutItems[e.name]` (max 10, ChosenFor, none selected on Use only), else
  `UI.DEMO_ITEMS` 929/1710/3928. HEADERS.flyout sets BLIZZ_ART.scaleFor / gapFor to the
  button's own and calls `UI.LayoutDemo` (item pool grows, extras hidden). The demo
  still opens upward whatever the button's direction. Slider drags call RefreshHeaders.
  Untested in game.
- 2026-11-02: **`Games\` and `Media\` deleted from the project a third time**, and
  `_forever_\Interface\AddOns\AutoMacros` was a plain folder holding CurseForge's 0.139.0
  (written 15:53, the day after the v0.139.0 upload): the CurseForge app updates the addon
  there and deletes through the junction. Restored the six files from HEAD (`cmd /c git
  show HEAD:<path> > file`). The other client folders don't exist on this PC any more
  (only `_forever_` has an AddOns\AutoMacros). **Every release now triggers this while the
  CurseForge app manages AutoMacros in `_forever_`.** Lewis runs off `_forever_`; its
  copy moved to `releases\forever-copy-0.139.0`, junction remade (New-Item -ItemType
  Junction), checked: loads 0.140.0.

## 0.139.0 — session of 2026-11-01 (one version; built in steps then
numbered 0.139.0-0.149.0, renumbered at Lewis's request. Snapshots of the steps:
`releases\in-session-builds-2026-11-01\`; the step numbers below are those.)

- **Committed** (896b4b1) and **released** 2026-11-02 as pre-release v0.139.0 (notes: its
  changelog section); CurseForge upload run 41372513969, success. `gh release create`
  needs git on PATH: prepend GitHub Desktop's git cmd folder to $env:PATH first.
  README changed: Lewis to paste it into CurseForge (pane + Waterfox opened).
  v0.138.0's release and tag deleted: v0.139.0 is the only GitHub release.

### after the renumbering (still 0.139.0): raw fish kept for Cooking
- Lewis (Cooking 10, Raw Slitherskin Mackerel): don't require knowing the recipe; know
  Cooking and it's something you'll cook (now or later) -> don't eat it.
- Forever's test data: nearly every raw fish is **Trade Goods 7.8** (Cooking) with a
  seated Use line (Raw Slitherskin Mackerel 6303, Brilliant Smallfish 6291, Sagefish
  21071, ...). Exceptions 0.5: Raw Winter Squid 13755 (cookable: caught only via a known
  recipe), Raw Black Truffle 4608 (not cookable). Classic Era files most things 0.0, so
  there only known recipes count.
- `CookingReagent(id)` now: in cookSkillUp -> true (if Cooking known); in `db.cookGray
  [char]` (reagents only of gray recipes you know: retail relativeDifficulty 3, older kind
  "trivial"; written by UI.ScanRecipes with cookSkillUp) -> false; else class 7 sub 8 and
  Cooking known -> true. A fish whose recipe you never learn stays off food while you know
  Cooking. Untested in game.
- `COOKING_FISH` (Macros.lua, by item ID, all games): cookable raw fish filed as 0.5,
  counted like 7.8. Only Raw Winter Squid 13755 (Grilled Squid; Wowhead Forever XML:
  class 0 sub 5, name "Raw Winter Squid" on Forever, "Winter Squid" in vanilla). Checked
  every "Raw" item in the Forever test data: all 7.8 except it and Raw Black Truffle
  (not cookable, stays food).

### after the renumbering (still 0.139.0): per-button size / spacing, Use only
- Lewis: no selected border when a button is set to Use only; add size and spacing to
  Per-Button Overrides. (The 0.139.0 note "per-button popout size not done" is now done.)
- OpenFlyout: `chosen` is nil when PopoutClick(m) == "use", so no entry is `selected`.
- `db.popSize[key]` (Item size %) / `db.popGap[key]` (Item spacing px), account-wide,
  nil = global; `PopoutSize(m)`, `PopoutGap(m)`, `PopoutLook(m, fn, ...)` (Popout.lua)
  set `BLIZZ_ART.scaleFor` / `BLIZZ_ART.gapFor`, which BLIZZ_ART.ItemSize (Bars.lua) and
  FlyoutPlan's gap read in place of Style. With the bar background on, spacing is the
  bar's own as before.
- The item buttons are one shared pool, so the size is applied **as the popout opens**:
  PrepareSecure works out per button `k<id>` (scale = size / native, Blizzard's
  template) and `bw<id>` (width: native, or size with the EUI look, k = 1) and ex/ey in
  those units; OPEN_SNIPPET does `e:SetScale(k)`, SetWidth/SetHeight(bw) (restricted
  HANDLE:SetScale exists, checked in Gethe/wow-ui-source RestrictedFrames.lua).
  OpenFlyout dresses the items under the same overrides (OpenFlyoutItems), and out of
  combat re-runs StyleFlyout so the bar art scales; in combat the art keeps its last
  scale (it is anchored to the secure popout).
- Settings: `UI.OwnPopoutNumber(label, dbKey, lo, hi, step, fmt)` = a `choice`
  ("Global", then each value) for the picked button; Item size 50-200% step 10, Item
  spacing 0-10. The settings demo still shows the global look. Untested in game.

### step 0.149.0 — "Buffs and Debuffs"
- Lewis kept the name Enemy Debuff, then: call the Buffs section "Buffs and Debuffs".
  UI.BUTTON_GROUPS' buffs group is renamed, flagged `buffs = true` (ButtonSections finds
  it by that, not by name, to put the combine toggle / Buff types first and the Other
  note last), and `enemydebuff` moved into it from Utility. README table updated.

### step 0.148.0 — Enemy Debuff button
- Lewis: Glowing Wax Stick (on Utility Buff in 0.146.0 via "invisible") and Bag of
  Marbles are used on enemies; wants their own button, name open. Chose **"Enemy
  Debuff"** (matches "Debuff Cure"); renaming = title/empty/label in CATALOG.
- **Lewis's Forever SavedVariables has a /amac test result** (`db.test.items`, lines
  "sets | class.sub | name | Use text"): `_forever_\WTF\Account\1791#1\SavedVariables\
  AutoMacros.lua`. Mined it with a scratchpad script for the rule; a Python copy of the
  rule matched exactly 14 items there, no false hits: 835, 20084 (15.0), 4941, 1191,
  18209, 13514, 2091, 3434, 1434, 11565 (quest 12.0), 4388, 5457, 3441, 1704.
- Learning (CLASSIFIER 21): flag `enemy` = Use line (digit) with target / enemy /
  enemies / opponent + decreas / reduc / unable to move / to sleep / cripple / cannot
  stealth / chance to hit / transforms the target / time between / immobiliz / snare /
  daze / silence / disarm, not friendly / party / increases the target / perman, not
  `hurts` (bombs stay Explosives). Branch right after onWeapon (poisons), before stats,
  so before questUse too. CATALOG `enemydebuff` (AM_EnemyDebuff, set `enemy_debuff`,
  placeholder 835 Large Rope Net), Utility group. README row added. Untested in game.

### step 0.147.0 — what Other means
- Lewis confirmed Swiftness belongs on Utility Buff (0.146.0). He asked for a one-line
  note at the bottom of the Buttons page's Buffs section explaining Other: a `text` item
  (height 30) appended in UI.ButtonSections after the Buffs grid: "Other: buffs that fit
  none of the above, such as attack power, regeneration or crit." Untested in game.

### step 0.146.0 — Utility Buff button
- Lewis: movement, immunity and escapes belong under Utility, not Other Buffs. New
  CATALOG `utility` (AM_Utility, "Utility Buff", set `buff_utility`, placeholder 5634
  Free Action Potion, ID from memory), Buttons page Utility group. **Not a buffPart**:
  never folded into the one Buffs button, not in BUFF_PARTS.
- Learning (CLASSIFIER 20): flag `utility` = Use line (with a digit) naming run /
  movement / swim / mounted speed, immune, invisib, breathe, walk on/across water,
  allows you to walk, slow fall, levitat, escape, shows the location (not perman /
  fishing); branch after resist/armor, before spellpower/haste -> buff_utility. Quest
  and misc items count too. Swiftness ("Increases run speed") went to Other before.
- Living Action Potion ("removes existing stun and movement impairing effects") still
  goes to Debuff Cure (the cure branch returns first). README table row added: **paste
  README into CurseForge again.** Untested in game.

### step 0.145.0 — cooking ingredients off the food buttons
- Lewis: raw fish / cooking ingredients that a known recipe still gives skill-ups for
  should not show as food when the player knows Cooking. Read as: hide them then; show
  them as before otherwise (without Cooking, or once the recipe is gray).
- UI.ScanRecipes: when `UI.OpenProfession()` (C_TradeSkillUI.GetBaseProfessionInfo
  .professionName, else GetTradeSkillLine()) equals `CookingName()` (SpellName(2550), else
  "Cooking"), every reagent of a recipe giving skill (retail relativeDifficulty ~= 3;
  older kind optimal / medium / easy) goes in `db.cookSkillUp[char]`, replaced whole on
  each Cooking scan. `CookingReagent(id)` (Macros.lua) = in that list and
  KnowsSpellName(CookingName()). Candidates skips those for `COOK_SETS` (food, water,
  combo, food_buff): buttons, popouts, Stocked/AutoEnable, the settings counts.
- Nothing is hidden until the Cooking window has been opened once with 0.145.0.
  Untested in game (incl. GetTradeSkillLine's name on Forever, retail's
  GetBaseProfessionInfo).

- Buff types on EUI: Lewis showed EllesmereUI's own checkbox dropdown (General >
  "EUI Buttons", EUI__General_Options.lua ~2005). It is
  `EllesmereUI.BuildVisOptsCBDropdown(parent, w, level, items {key,label,tooltip},
  getFn(k), setFn(k, v), ...)` -> ddBtn, refreshFn (EllesmereUI_Widgets_CheckboxDropdowns.lua;
  not in PLUGINS_API.md). EUI builds a DualRow with a placeholder dropdown, hides
  `rgn._control`, PP.Point(dd, "RIGHT", rgn, "RIGHT", -20, 0), sets `rgn._control = dd`,
  `_lastInline = nil`, RegisterWidgetRefresh(refresh). Ours: `UI.MultiDropdown(region,
  item)` after each DualRow; NativeCfg(multi) = that placeholder; UI.Pairable(multi) =
  BuildVisOptsCBDropdown exists (else BuildItem's togglegrid). The combine toggle is
  `half = not OneBuff()` again, so it pairs with the dropdown. Untested in game.

### step 0.144.0 — Popout page sections; Buff types switches on EUI
- Lewis (EUI page, 0.143.0): the Buff types dropdown used Blizzard check icons, not EUI's
  look, and picks seemed to do nothing. **EllesmereUI's dropdown builds its menu once and
  caches it** (BuildDropdownMenu / WireLazyDropdown), and each item click calls
  setValue then sets the label to that entry's text and closes. The ticks never redrew,
  so it can't act as a multi-select. On W the `multi` item now builds a `togglegrid`
  (EUI TripleRow switches), and `multi` is no longer in UI.PAIRABLE. Blizzard's page keeps
  MakeMulti. The multi item takes `set(key, on)` (was `toggle`). UI.SetBuffPart also calls
  RefreshEUIPage. UI.CHECK / NOCHECK removed. The combine toggle is always `half`.
- Lewis: the Popout page's top section is "Global Behavior" (global settings above), and
  "Each button" is renamed "Per-Button Overrides" and moved to the bottom; its "As above"
  choice is now "Global".

### step 0.143.0 — dropdowns where they fit
- Lewis: use dropdowns where it makes sense; he picked all four proposals.
- General: Chat = one `choice` "Chat messages" (UI.CHAT_CHOICES all / info / empty / none,
  mapped onto db.quiet + db.noEmptyMsg); "Food and water" = `choice` "Out of food or
  water" (UI.FALLBACK_CHOICES combo / empty -> db.noComboFallback).
- New settings item type **`multi`** (`list` {key,label}, `isOn(key)`, `toggle(key)`,
  `summary()`; pairable): Blizzard page = `MakeMulti` (Widgets.lua: WowStyle1Dropdown
  `CreateCheckbox` returning MenuResponse.Refresh so the menu stays open, text via
  OverrideText / SetDefaultText; else UIDropDownMenu isNotRadio + keepShownOnClick; nil
  -> BuildPage falls back to a togglegrid under the label). EUI = its single-choice
  dropdown (EllesmereUI has no multi-select): UI.NativeCfg fills values with UI.CHECK /
  UI.NOCHECK icons + label, getValue always "_summary" (not in order, labels the closed
  dropdown), setValue toggles and refills the same tables in place, RefreshEUIPage().
  **Unverified** that EUI's dropdown shows values["_summary"] for a key not in order.
- Buffs: UI.BuffChoiceItems = the combine toggle (half only while off, so while on it
  pairs with the dropdown) + `multi` "Buff types" (BUFF_PARTS, UI.BuffSummary
  "A, B, C +N"). The togglegrid type stays (fallback).
- Popout page: section "Each button" (`items` function UI.EachButtonItems: `choice`
  Button (UI.EnabledButtons, UI.popoutKey; UI.PopoutEntry), Opens (UI.DIR_CHOICES ->
  db.popDir), Clicking an item ("As above" + POPOUT_CLICKS -> db.popClick); changes go
  through UI.PopoutChanged (PrepareSecure, Refresh, headers, RefreshPanels,
  RefreshEUIPage)). Page `stamp` = UI.EnabledStamp so Blizzard's page rebuilds when the
  buttons that are on change. Untested in game.

### step 0.142.0 — combining is the Buffs button's switch
- Lewis, right after 0.141.1: with combine on, the Buffs button should simply be what is
  enabled; the types are filters. `Enabled(e)` returns `OneBuff()` for the `oneBuff`
  entry (OnOff ignored); `UI.SetEnabled` on it calls `UI.SetOneBuff(on)` (icon row,
  welcome window, `/amac add|remove buffs` all go through SetEnabled); SetOneBuff no
  longer sets OnOff().buffs. 0.141.1's separate Buffs toggle is removed again; the Buffs
  grid still leaves the `oneBuff` entry out. Untested in game.

### step 0.141.1
- 0.141.0 in game (Lewis's EUI screenshot): the checkbox grid works, 3 to a row, Spell
  Power ticked on his caster. The Buffs button's own switch sat in the button grid with
  Flask / Weapon; he wants it first, left of the combine toggle. UI.BuffChoiceItems now
  starts (while OneBuff) with a plain toggle for the `oneBuff` entry (label UI.Name,
  Enabled / UI.SetEnabled), so on EUI it pairs into one DualRow with the combine toggle
  (`half` only applies to an item that would be alone). UI.ButtonSections leaves
  `oneBuff` entries out of the Buffs grid (still `placed`, so not under Other).

### step 0.141.0 — Haste / Spell Power buttons; a checkbox per buff kind in 3 columns
- Lewis (EUI screenshot of 0.140.1's stat toggles: 2 per row, Strength alone): keep 3
  columns for these checkboxes; Resistance, Haste and Spell Power each their own category.
  He chose: Haste and Spell Power as **buttons and checkboxes**; Spell Power ticked by
  default for casters only.
- Learning (CLASSIFIER 19): flags `spellPower` (buff, not resist, and "spell power" /
  "magical spells" / "healing done", or "spell" + damage/healing) and `haste` (buff +
  "haste" / "attack speed" / "casting speed"); new branch after resist/armor ->
  `buff_spellpower`, `buff_haste` (was buff_other). Stat buffs still win (stats branch is
  first).
- CATALOG: `spellpower` (AM_SpellPower "Spell Power", placeholder 13454) and `haste`
  (AM_Haste "Haste Buff", placeholder 2459 Swiftness Potion), both buffPart. Field
  `stat` -> `part` on every buffPart entry (armor, resistance, haste, spellpower, other
  too). UI.SHORT haste = "Haste"; BUTTON_GROUPS Buffs has both.
- `BUFF_PARTS` (10, checkbox order), `SPELL_CLASSES` (Mage, Warlock, Priest, Paladin,
  Shaman, Druid, Evoker); `BuffStats()` -> **`BuffParts()`**: class stats + armor,
  resistance, haste, other (+ spellpower for SPELL_CLASSES), then db.buffStats[char]
  overlaid (now saved **true / false** per part, `UI.SetBuffPart`; parts not touched keep
  following the defaults). InSet("buff_class") = any part's buff_<part>.
- New settings item type **`togglegrid`** (`toggles = { { label, get, set } }`): EUI =
  TripleRow (missing slots `{ type = "spacer" }`), Blizzard = UI.GRID_COLS columns of
  MakeToggle + label (like buttongrid). UI.BuffChoiceItems: the half toggle + one
  togglegrid of BUFF_PARTS (UI.PART_NAMES); the "also takes armor..." note is gone.
- Untested in game, incl. the haste/spell power wording on Forever's items.

### step 0.140.1
- Lewis (EUI page screenshot): rename the one-Buffs toggle -> **"Combine class-related
  buffs into one button"** (README + 0.139.0 changelog text too); its switch was far right
  (EllesmereUI gives a lone toggle a full-width row). Settings items may set `half =
  true`: on EUI, BuildPage puts such a pairable item alone in a `DualRow` with
  `{ type = "spacer" }` as the right half (EllesmereUI_Widgets_Rows.lua: "Empty half-space
  placeholder"), so its switch sits mid-row like paired ones. Only that toggle has it so
  far ("Use EllesmereUI styling" is also a lone full-width toggle). Blizzard's page
  unchanged. The icon in his shot was his mouse cursor. Untested in game.

### step 0.140.0 — version on the General page
- Lewis: show the current version in the General settings. `AddonVersion()` (Core.lua:
  C_AddOns.GetAddOnMetadata / GetAddOnMetadata(ADDON, "Version"), pcall'd) and a last
  General section "About" with one text item "AutoMacros <version>" (both settings pages
  draw text items). Built on top of untested 0.139.0. Untested in game.
- 2026-11-01: **Lewis now tests in `_forever_`, not `_classic_beta_`.** `_forever_`'s
  AutoMacros was a plain copy of released 0.138.0 (CurseForge app, 17:07): moved to
  `releases\forever-copy-0.138.0`, junction in its place (New-Item -ItemType Junction).
  **If the CurseForge app keeps AutoMacros installed there, its next update will replace
  the junction again and may delete project files through it** (as with Games\/Media\).

### step 0.139.0 — one Buffs button; Clicking an item per button
- Lewis: the buff buttons don't suit casters (Str/Agi useless); option for one button with
  the class's buff items. He chose: stats per character with class defaults, plus Other,
  Armor and Resistance; the separate buttons **hidden** while it's on; per-button "Clicking
  an item" set by **Shift+right-click** on the Buttons page icon row.
- Core: CATALOG flags `buffPart` (agility, intellect, stamina, strength, spirit, armor,
  resistance, otherbuff) and `stat` (the five stats); new entry `buffs` (AM_Buffs,
  "Buffs", set `buff_class`, `oneBuff`, scope character, placeholder 2458).
  `BUFF_STATS`, `CLASS_BUFF_STATS` (casters Int/Spi/Sta, Warrior/Rogue Str/Agi/Sta, Hunter
  Agi/Int/Sta, Paladin/Shaman/Druid all, DK Str/Sta, DH/Monk Agi/Sta, Evoker Int/Sta),
  `OneBuff()` (db.oneBuff[char]), `BuffStats()` (db.buffStats[char] or the class's),
  `HiddenButton(e)`. InSet("buff_class") = any chosen buff_<stat>, buff_armor,
  buff_resistance, buff_other. RebuildMacros leaves hidden entries out of ALL (so also
  MACROS, the Buttons page, AutoEnable). UpdateCore's toDelete counts hidden as off.
- Options: `UI.SetOneBuff(on)` (saves, queues the other kind's macros in toDelete, turns
  `buffs` on, UI.CustomChanged); `UI.SetBuffStat(stat, on)`; `UI.BuffChoiceItems()` =
  the toggle "One Buffs button for this character" + (while on) five "Buffs: <Stat>"
  toggles and a note, inserted at the top of the Buttons page's Buffs section
  (UI.ButtonSections). BUTTON_GROUPS Buffs has `buffs`.
- Popout: `PopoutClick(m)` = db.popClick[key] (account-wide, like popDir) else the global;
  `OwnPopoutClick(e)`, `NextPopoutClick(e)` (Default -> Use and set -> Set only -> Use
  only). Secure: attribute `mode<id>` per wrapped button (OPEN_SNIPPET reads it; the old
  shared "mode" is gone). PostClick / entry tooltip use flyout.macro's. Buttons page icon:
  Shift+right-click = NextPopoutClick; tooltip line `UI.ClickText(e)`.
- **Not done: per-button popout size** (Lewis asked mid-turn). The popout's item buttons
  are one shared pool, sized out of combat by scale; a size per button would need a pool
  per size (SetScale on protected frames is blocked in combat). Asked Lewis first.
- 2026-11-01: `Games\` and `Media\` were **deleted from the project again**, and
  `_forever_\Interface\AddOns\AutoMacros` was a plain folder, not a junction:
  most likely the CurseForge app updating AutoMacros there deleted through the junction.
  Restored the six files from HEAD (`git show HEAD:<path>` into the missing files; a
  `git checkout --` was refused by the permission check). Told Lewis.
- README Features/Buttons updated: **paste README into CurseForge again**. Untested in game.

## 0.138.0 — "Right-click: Conjure Water" in the tooltip
- Lewis: the Water and Food buttons' tooltips should say right-click conjures.
  `rightCast` (Update.lua, top-level: macro name -> spell name) is set in UpdateCore's set
  branch whenever `right` (MADE rightClick + create known), i.e. whenever the body has
  the `[btn:2]` cast. `RightClickHint(tip)` (Bars.lua): MacroOnButton(owner) -> rightCast
  -> AddLine("Right-click: <spell>", green 0.25/1/0.25) + Show, skipped if that exact
  line is already there (Readable-guarded). Called with CleanTooltip on each **build**
  (TooltipDataProcessor post-call, SetAction hook: `built`), not from the OnUpdate
  backstop. **Confirmed in game** (Lewis, 2026-11-01: "it works").
- **Released** 2026-11-01 as pre-release v0.138.0 (notes: its changelog section);
  CurseForge upload run 41357082883, file id 9400258, beta. v0.137.1's release and tag
  deleted.

## 0.137.1 — /amac opens Buttons on EllesmereUI too
- Lewis: 0.137.0's /amac opened EllesmereUI's settings, but not at Buttons. EllesmereUI's
  PLUGINS_API documents `EllesmereUI.OpenPlugin(id [, moduleKey [, pageName]])` -> false
  for an unknown plugin/module/page (EllesmereUI_Panel.lua 5889: sets the module's last
  page, ShowModule, SelectPage if already on it). OpenOptions now calls
  `OpenPlugin("AutoMacros", "options", page)` when a page is given (our module key from
  RegisterEUI, page = the PAGES name), and plain `OpenPlugin("AutoMacros")` if that says
  false. The note below ("OpenPlugin takes no page") was wrong.
- **Confirmed in game** (Lewis, 2026-11-01): /amac opens Buttons on EllesmereUI and on
  Blizzard's window (EllesmereUI off).
- **Released** 2026-11-01 as pre-release v0.137.1 (notes: changelog 0.136.0-0.137.1);
  CurseForge upload run 41333586878, file id 9397372, beta. v0.135.1's release and tag
  deleted.
- Lewis asked whether the README can reach CurseForge automatically: **no**, CurseForge's
  author API only uploads files (no description endpoint). Offered: keep pasting, or a
  short stable CurseForge description that links to the GitHub README. **Lewis chose to
  keep pasting the full README** (2026-11-01): keep telling him when it changes.
- **Whenever the README needs pasting into CurseForge** (Lewis, 2026-11-01): open
  `README.md` in the app's file pane (show_pane file, line 1) **and** open the description
  editor in Waterfox: `Start-Process "C:\Program Files\Waterfox\waterfox.exe" -ArgumentList
  "https://authors.curseforge.com/#/projects/1769719/description"`. He copies from the
  pane and pastes there himself (Markdown mode).

## 0.137.0 — /amac opens the Buttons page
- Lewis (2026-11-01): `/amac` with nothing after it = `OpenOptions(nil, "Buttons")`
  (Blizzard's window at the Buttons page; EllesmereUI's page still opens where it opens,
  OpenPlugin takes no page). The old update + report is `/amac update`: any word the
  handler doesn't know still falls through to it, so `update` needs no branch of its own.
  `/amac list` help line and README command table updated (**paste README into
  CurseForge again**). Untested in game.

## 0.136.0 — Food & Drink (combo) button, fallback
- Lewis (2026-11-01): combo food (health + mana, seated) gets its own button **AM_Combo,
  titled "Food & Drink"** (key/set `combo`, empty "No Food & Drink", placeholder item
  13724 Enriched Manna Biscuit, ID from memory). Food and Water keep only food-only /
  water-only items. Combo items show on Food / Water **only as the fallback**: when that
  button's list is empty (UpdateCore's set branch: `#list == 0` for food/water ->
  `Candidates(have, "combo")`, and `carried = true` so a mage's button eats the combo
  item with right-click still conjuring instead of the conjure-when-out body).
- Setting `db.noComboFallback` (nil = fallback on): General > "Food and water" toggle,
  `/amac fallback`. README command table updated: **paste the README into CurseForge again.**
- Learning: seated + health + mana -> `{ "combo" }` (both branches). CLASSIFIER 17 -> 18
  so automatic results are re-sorted. RebuildLearned indexes any record with both food and
  water (manual, or older) as combo instead.
- Not handled: MoP/retail Conjure Refreshment items are in MADE water and food (shared rank
  table), so InSet still puts them on Food and Water as before, as well as Food & Drink.
- 2026-11-01 housekeeping: `_forever_\Interface\AddOns\AutoMacros` was **no longer a
  junction** but a plain copy of 0.135.1 (no CLAUDE.md, files dated 2026-11-01 04:44 UTC;
  likely an addon manager install), and this folder's `Games\` and `Media\` were missing
  from disk (git showed them deleted). Restored both from HEAD. The junction must be
  remade from Windows (`mklink /J`); the cloud VM can't.
- **Tested in game 2026-11-01 (Lewis, `_classic_beta_`): all works**, incl. conjuring
  water clears the combo fallback item off Water.
- **Lewis tests Forever in `_classic_beta_`** (2026-11-01), not `_forever_`. Its
  `Interface\\AddOns\\AutoMacros` was also a plain 0.135.1 copy; 0.136.0 copied into both.

## 0.135.1 — retail secret values
- CurseForge bug comment (retail 12.x, 0.135.0): `Bars.lua:262: attempted to index a table
  that cannot be indexed with secret keys` in CleanTooltip, from TooltipDataProcessor's
  post-call on an action button tooltip (ActionButton SetTooltip -> SetAction). Locals:
  `text=<secret string>` (GameTooltipTextLeft1). **Retail's secret values**: an addon may
  not compare them, index with them, or use them as table keys; `type()` still says
  "string". Check with `issecretvalue(v)` (absent before 12.0).
- `Readable(v)` (Core.lua) = not issecretvalue(v). Guarded: CleanTooltip's line lookup
  and its first-line compare; MacroOnButton (GetActionInfo kind/id, GetActionText ->
  not ours); BarChanged (secret kind/id/text stored as "?"); the scan tooltip's lines
  (Learning); `/amac debug` prints "(secret)". The three tooltip hooks now call
  `pcall(CleanTooltip, tip)`, so the tidy-up can never error into Blizzard's tooltip code.
- **Rule: any game value an addon compares or uses as a key on retail may be secret
  (tooltip text, action info, unit/aura/cooldown data in combat): pass it through
  Readable first.** Untested in game (no retail test of combat tooltips yet).
- **Released** 2026-11-01 as pre-release v0.135.1 for the reporter (notes: only its own
  changelog section this time); CurseForge upload run 41270991059, file id 9391475, beta.
  v0.135.0's release and tag deleted. Lewis never saw the error in Midnight: secrets show
  up mostly in combat / instances, and retail hides Lua errors unless scriptErrors is on
  or an error catcher (BugSack) is installed.

## 0.135.0 — right-click conjures (Water, Food)
- Lewis: right-clicking the Water or Food macro should always conjure. MADE entries get
  `rightClick = true` (water, food only). UpdateCore's set branch, when the spell is known:
  carrying some -> `#showtooltip <item>` / `/cast [btn:2] <spell>` / `/use [nobtn:2]
  item:<id>`; carrying none -> `/cast [btn:2][nomod] <spell>` / `/use [mod:shift,nobtn:2]
  item:<id>`. A picked spell (spellUsed) already casts it. Healthstone / mana gem buttons
  unchanged.
- **0.133.0-0.135.0 confirmed working on Forever** (Lewis, 2026-10-31: "its all working"):
  conjuring when out, the spell in the popout, right-click conjures.
- **Released** 2026-11-01 as pre-release v0.135.0 (Lewis chose pre-release again; notes:
  changelog since 0.120.0); CurseForge upload ran by itself (run 41270380806, file id
  9391445, AutoMacros-0.135.0, beta). v0.132.0's release and tag deleted: v0.135.0 is
  the only GitHub release.

## 0.134.0 — the making spell in the popout
- Lewis: Conjure Water should always show in the Water popout for a mage, highest rank only.
  `MadeCreate` now returns `name, carried, spellID` (best known rank: the lists are best
  first; name fallback takes the ID `KnowsSpellName` gets back, GetSpellInfo's 7th return
  or C_Spell info.spellID). UpdateCore's set branch appends `{ id = createID, spell =
  true, pick = create }` after KnownSpells: last in the popout, pick keyed by **name** so a
  new rank keeps it chosen. Applies to every MADE button (water, food, hpot, mpot).
  Casting is by name (SpellBody / the secure popout's spell attribute), i.e. best rank.
- "Highest rank" read as the spell; carried conjured water of several ranks still all
  show (asked Lewis). Untested in game.

## 0.133.0 — conjured water and food (2026-10-31)
- Lewis got **WoW Forever running**; a mage who knows Conjure Water had the Water button
  out and it didn't offer Conjure Water. It never had: only hpot/mpot were in MADE.
- **Forever is now a junction too** (2026-10-31, Lewis asked): `_forever_\Interface\AddOns\
  AutoMacros` was a real copy of 0.132.0 (same as previous/0.132.0 apart from CRLF);
  moved to `releases\forever-copy-0.132.0` (gitignored, kept), junction in its place.
  All five clients now load this project folder directly.
- MADE gains `water` / `food` (only when the game's Lists set WATER_RANK / FOOD_RANK):
  same path as healthstones (UpdateCore's set branch, MadeCreate, AutoEnable, UI.Available):
  none carried + spell known -> `#showtooltip Conjure Water` / `/cast [nomod]` / `/use
  [mod:shift] item:<chosen>`; conjured items sort first by rank.
- Lists (**IDs from memory, unverified**): vanilla (Forever, Era) water 5350, 2288, 2136,
  3772, 8077, 8078, 8079, spells 10140..5504; food 5349, 1113, 1114, 1487, 8075, 8076,
  22895, spells 28612, 10145..587. TBC adds Glacier Water 22018 / 27090 and Croissant
  22019 / 33717. MoP: Conjure Refreshment 42955 makes mana foods (65517, 65516, 65515,
  65500, 43518, 43523, 65499, 80610, 80618), water and food share the table; retail adds
  Mana Bun 113509 and spell 190336.
- `MadeCreate` falls back to **spell name**: if no listed ID is known, a listed spell's
  name that `KnowsSpellName` (C_Spell.GetSpellInfo / GetSpellInfo by name, which only
  answers for spells in your spellbook) finds; /cast by name uses the best rank. Covers
  Forever spell IDs differing from vanilla, for healthstones and gems too.

## 0.132.0 — learned list like EllesmereUI's Patch Notes
- Lewis (retail, EUI): EUI's scroll bars are thin page bars; asked for the learned list to
  look like EUI's Patch Notes page (white title + gray description rows). 0.131.4's
  AttachSmoothScrollbar list was never seen in game (superseded).
- EUI page: `UI.BuildLearnedNotes(parent, x, y, w, refreshers)` (BuildPage's `learned`
  branch when W): heading (skin font) + "Copy list" MakeButton (skinned) on the right, then
  per `UI.LearnedGroups()` group (button title A-Z, items A-Z, "(by hand)" marked, "No
  button" last) a white GameFontHighlight title "Water  (8)" and a gray (0.6)
  GameFontHighlightSmall line of item names joined ", ", wrapped to w; no box, no inner
  scroll. Built once; its refresher calls `RefreshEUIPage(true)` when UI.LearnedText's body
  differs from the one it was built with (and the page is visible).
- `UI.ShowCopy(title, text)`: frame `AutoMacrosCopy` (BasicFrameTemplateWithInset or plain,
  FULLSCREEN_DIALOG, movable, Escape), template scroll frame + read-only multi-line
  EditBox focused and selected, hint, Close; skinned at creation when SkinActive().
- Blizzard's page: `UI.BuildLearnedList` back to the template list only (eui path,
  AttachSmoothScrollbar and skin.Panel removed; insets/spacing kept).
- **Confirmed** (Lewis, 2026-10-29: "looks good like this"); committed and pushed.
- **Released** 2026-10-30 as pre-release v0.132.0 (notes: every changelog section since
  0.120.0), after TBC Anniversary and MoP Classic tests; first all-clients CurseForge
  upload (file id 9367363). v0.129.0's release and tag deleted: v0.132.0 is the only one.
  Commit messages: write them with the Write tool (Set-Content -Encoding utf8 put a BOM
  at the start of 50b82aa's message).

## 0.131.4
- 0.131.3 in game (Forever, EUI page): panel and font fine, scroll bar still Blizzard's:
  **`skin.ScrollBar` does nothing to the classic UIPanelScrollFrameTemplate bar.** On EUI's
  page the list is now a plain ScrollFrame with `EllesmereUI.AttachSmoothScrollbar(sf,
  { passWheel = true })` (EllesmereUI.lua; public on the EllesmereUI table but not in
  PLUGINS_API.md; pcall'd, returns UpdateThumb, called after each SetText and a frame
  later). The bar sits inside the list (sf w - 8, EditBox listW - 12). If the call fails:
  plain frame + our mouse wheel. Blizzard's page keeps the template.
- Process slip: the first edit came before saving previous/0.131.3; restored it from
  releases/AutoMacros-0.131.3.zip (the build Lewis had).

## 0.131.3
- Lewis (EUI General page): the Item learning list looked wonky (cramped small font, lines
  cut at the box's top edge, Blizzard scroll bar). `UI.BuildLearnedList(..., eui)`
  (BuildPage passes `W ~= nil`): backing is now its own frame `box` (level below sf):
  EUI = `skin.Panel(box, { inset = true })`, else the old 0.35 black; EditBox gets
  SetTextInsets(6, 6, 4, 4) and SetSpacing(2) on every page; EUI also skins sf.ScrollBar,
  the heading font, and the list font (skin.GetFont, 11). Untested in game.

## 0.131.2
- 0.131.1's EUI styling of the Custom rows confirmed (Lewis's screenshot: themed checkbox,
  name box, Delete). The row started at x0 (20), left of everything, and Delete ended near
  the page edge. BuildPage's customrows branch on EUI now passes x = `tx` (labels, pad + 20)
  and width `w - tx + 10`, so Delete's right edge (width - 10) is `w - tx`, mirroring the
  left. Blizzard's page unchanged. **Confirmed in game** (Lewis, EUI page: lines up).

## 0.131.1 — custom buttons on EllesmereUI's page
- 0.131.0 confirmed working (Lewis, Forever, Blizzard and EUI pages). His EUI screenshot:
  Delete left the row (and a new button's row was missing), Delete was a red Blizzard-skin
  button, picker unthemed.
- `RefreshEUIPage(rebuild)` passes it to `E:RefreshPage`; UI.CustomChanged uses
  `RefreshEUIPage(true)` (rows change). Before, only values were re-read.
- `UI.Skin(kind, frame, ...)` = pcall'd `skin[kind]` (EllesmereUI's SKINNING_API: Shell,
  Inset, CloseButton, Button, WhiteButtonLabel, Checkbox, EditBox, ScrollBar, Font).
  BuildCustomRows got `eui` (BuildPage passes `W ~= nil`): Checkbox, EditBox {padInput},
  Button on its widgets. Picker: skinned once at creation when `SkinActive()` (f.skinned;
  turning EUI styling off later needs a /reload for it); `UI.MarkPickTabs` colors the active
  tab's label AccentRGB when skinned, else LockHighlight.
- Picker closing: `UI.dropHost` = the visible SettingsPanel / InterfaceOptionsFrame /
  EllesmereUIFrame when opened; OnUpdate (every 0.25 s) hides the picker once it isn't
  visible. Replaces the OnHide hooks (EUI's PLUGINS_API forbids hooking its things).
- **Confirmed in game** (Lewis, EUI page): Delete clears the row straight away. Still
  unknown whether the EUI page keeps its scroll position on rebuild.

## 0.131.0 — picker instead of closing the settings
- Lewis tried 0.130.0 on Classic Era (Forever-style spellbook): the drop window worked for
  bags, but its Spellbook button made the window disappear (cause not found), and the
  spellbook takes half the screen. He asked to keep the settings open.
- The drop window (`AutoMacrosDrop`, same name) is now a picker at FULLSCREEN_DIALOG over the
  settings; nothing is closed or opened. Rows: the button's things + DropSlot (drops still
  work), tabs Bags / Spells (`UI.pickTab`, MakeButtons, active one LockHighlight), a
  UIPanelScrollFrameTemplate list (`f.list`, pooled `UI.PickIcon`s, 32 px, 5 rows visible),
  Done. `UI.BagThings()` = ScanBags A-Z (worn gear included); `UI.BookSpells()` = retail
  C_SpellBook skill lines (no passive / off-spec), else GetSpellTabInfo + GetSpellBookItemInfo
  "SPELL" minus IsPassiveSpell; one entry per spell name, the last (highest) rank. Already
  added = desaturated, alpha 0.5. Hooks SettingsPanel / InterfaceOptionsFrame OnHide to close.
- Removed: UI.CloseSettings, UI.OpenBags, UI.OpenSpellbook, Back to settings.
  `OpenOptions(blizzard, page)` stays (nothing passes a page now).
- **Untested in game**, incl. the strata over SettingsPanel and the spell lists per client.

## 0.130.0 — drop window for custom buttons
- Lewis: can't open bags or spellbook while the settings page is open, so nothing can be
  dragged onto the custom +s (0.118.0 already saw this for the spellbook on Classic Era).
- `UI.DropSlot(parent, size, drop, tip, empty)`: `empty` runs on a click with nothing on the
  cursor (GetCursorInfo nil). The Buttons strip's + and each Custom row's add slot pass
  `UI.ShowDrop(key)` (nil = new button). ShowDrop (Custom.lua, refused in combat):
  `UI.CloseSettings()` (SettingsPanel:Close(true) / HideUIPanel, InterfaceOptionsFrame,
  GameMenuFrame), frame `AutoMacrosDrop` (BasicFrameTemplateWithInset like Welcome, DIALOG,
  movable, Escape), `UI.OpenBags()` (OpenAllBags). Window: title "New button" / "Add to X",
  the button's things (right-click removes), a DropSlot -> `UI.DropTake` (first drop on a new
  one: `UI.CustomCreate` now returns the key, kept in `UI.dropKey`), buttons Bags,
  Spellbook (`UI.OpenSpellbook`: PlayerSpellsUtil.OpenToSpellBookTab, else
  ToggleSpellBook), Back to settings = `OpenOptions(nil, "Buttons")`.
- `OpenOptions(blizzard, page)`: opens that page; RegisterBlizzPanel keeps each page's
  category in `UI.panels[i].category`. EllesmereUI's page can't be opened at a page (opens
  as before), and its window is not closed by CloseSettings (unknown whether it blocks bags).
- **Untested in game.**

## 0.129.0 — AddOn List icon
- Lewis: the AddOn List showed a red "?" for AutoMacros; use the logo (he liked
  NauticusClassic's gold "N" there). `.toc`: `## IconTexture: Interface\AddOns\AutoMacros\
  Media\AutoMacros` (no extension). `Media\AutoMacros.tga` = 64x64 uncompressed 32-bit TGA
  with alpha, drawn natively at 64 by `& .\tools\make_logo.ps1 Media\AutoMacros.tga 64`
  (the script now writes a TGA when the name ends in .tga; WoW's Classic clients don't
  take PNG icons). Run it with `&`, not `powershell -ExecutionPolicy Bypass` (the
  permission check refuses that).
- `tools/build_zip.py` adds the IconTexture file (.tga/.blp found next to the path) to
  every zip, so the zip is no longer only the .toc + .lua files. Checked: both the
  all-games and the Forever zip contain `AutoMacros/Media/AutoMacros.tga`.
- The AddOn List reads .toc files at game start: needs a full restart, not /reload.
- **Confirmed in game** (Lewis, 2026-10-28): the icon shows in the AddOn List.
- **Released** 2026-10-28 as pre-release v0.129.0 (notes: every changelog section since
  0.120.0, like v0.128.1's); the CurseForge upload ran by itself (run 40619992966, file id
  9348878, AutoMacros-0.129.0-forever, beta). v0.128.1's release and tag deleted, so
  v0.129.0 is the only GitHub release.

## 0.128.1
- Lewis's Popout screenshot (Blizzard page, EllesmereUI off): the Color / Selected border
  mode dropdowns were blank: their saved mode was "accent", which ColorModeChoices leaves
  out without EllesmereUI. `ColorMode` now returns "default" for a saved "accent" while
  `EUIAccent()` is nil (StyleColor already drew Default); the saved value stays, so it is
  accent again with EllesmereUI back. PinMode only saves when no mode is saved, so it
  doesn't overwrite it.
- README rewritten (logo, badge, screenshots in `docs/screenshots/`, 850 px wide copies of
  Lewis's settings shots; current buttons and commands). Originals moved to
  `releases\screenshots-original\` (a delete was refused by the permission check).
## 0.128.0 — learned list; EllesmereUI Popout page with the demo on the right
- Lewis (EllesmereUI page, retail): the Item learning text wasn't indented like the rest, and
  should be a scrollable list he can copy out of the game. New settings item type
  `learned` (General > Item learning, was a `text` item with UI.LearnedSummary, now gone):
  `UI.LearnedText()` = heading + every learned item "Name - Button, Button" (A-Z, "(by
  hand)" marked); `UI.BuildLearnedList(parent, x, y, w, refreshers)` = heading, a
  UIPanelScrollFrameTemplate scroll frame (plain one + mouse wheel as fallback) holding a
  multi-line EditBox, read-only (OnTextChanged by the user puts the text back), focus
  selects all for Ctrl+C, a hint line; 176 high.
- Notes and the list line up with the labels: BuildPage's `tx`/`tw`. On EllesmereUI's page
  rows sit `EllesmereUI.CONTENT_PAD` (45) in and labels 20 further, so tx = 65 there (text
  was at x0 = 20, left of everything); Blizzard's page unchanged (lx).
- EllesmereUI Popout page: preview in a right-hand column like Blizzard's page. For pages
  with previewSide = "right" (not in search prebuild) buildPage makes `parent.amCol`
  (settings column, page width - UI.EUI_SIDE_W 220) and `parent.amSide` (preview host at
  the top right, UI.ShowHeader into it, onResize sets its height); old ones are hidden on a
  rebuild; no SetContentHeader for that page. Returns max(settings height, preview height).
  **Untested**: EUI widgets built into a child frame instead of the page itself.
## 0.127.2 — back to 0.123.0's soft glow, frame drawn again on top
- **Confirmed in retail** (Lewis: "looks perfect"): red fade, rounded corners, the grey
  frame shows over it all round. This settles the retail soft glow after 0.123.x-0.127.1.
- 0.127.1 still white. Lewis: go back to the original glow (before Blizzard's texture) and
  put it behind the border. The on-button BORDER-layer fill (GlowFill, amFollow) is gone;
  **textures created on the action button itself drew white whatever we did** (cause not
  found: not the mask, not hidden-when-faded).
- Now: 0.123.0's g.edges fade (FadeEdge, 20..100%), masked by the button's IconMask on
  retail rounded buttons (MaskSoft again: that did clip, and the fade worked), plus
  BLIZZ_ART.GlowBorder(g, button): a copy of the button's NormalTexture (its atlas,
  size, TOPLEFT point, vertex color) on g at OVERLAY 7, above the fade, so the grey ring
  shows over the glow like over the icon. It pulses with g (the real ring is underneath).

## 0.127.1
- 0.127.0 in retail: fill still **flat white, opacity ignored**, so 0.126.1's mask theory
  was wrong. Remaining difference from g.edges (which fade fine): those are Show()n before
  FadeEdge; the fill pieces were still hidden when FadeEdge ran. Now StyleGlow only stores
  g.amFillColor; amFollow applies FadeEdge to each piece right after showing it (every
  time it shows). **Theory, unverified.** Plan B if still white: draw the fade as stacked
  solid bands of falling alpha (no SetGradient at all).

## 0.127.0 — retail soft glow = our fill only, behind the frame
- Lewis: drop Blizzard's glow texture, use our own, behind the border like Blizzard's icon so
  the border always shows. BLIZZ_ART.GlowRing / amRings gone; retail rounded buttons (no
  EUI look) draw only the BORDER-layer fill (GlowFill), depth (bw - 2k) x t/5 = 20..100%,
  same steps as the other games.

## 0.126.1
- 0.126.0 in retail: border fine (the BORDER-layer fill does sit under the frame art), but
  the fill was **flat white bands** (no gradient, no color): the FadeEdge gradient did not
  draw on textures masked with the button's IconMask (inferred: the only difference from
  g.edges, which fade fine). Fill now unmasked, inset k = 2.4 button units (x bw/45,
  snapped) on all sides: from the frame art measurements (ring 3/88 wide from 1/88 in,
  corners cut 9/88, art 46 wide), the square corner (k,k) lies under the ring's cut
  corner and the straight edges meet the ring's inner edge. Depth = (bw - 2k) x (t-1)/4.
  (The mask theory was wrong, see 0.127.1.)

## 0.126.0 — retail soft glow: Blizzard's glow + a fill under the frame
- Lewis: users should still be able to fill the whole button, "just fill inward". The fill
  covered the border because the glow frame g sits above the whole button (frame art too).
  Now the fill is **four FadeEdge textures on the button itself, layer BORDER sublevel 7**
  (above the icon in BACKGROUND, below the NormalTexture frame art in ARTWORK), masked by
  the button's own IconMask (same frame), anchored to the button: the frame ring is always
  on top. BLIZZ_ART.GlowFill(g, button) makes them once (g.amFill) with their own Alpha
  pulse groups (g's alpha doesn't reach the button's textures) and hooks g OnShow/OnHide
  (g.amFollow, g.amFillOn) so they show, hide and pulse with the glow.
- Thickness on retail: 1 = Blizzard's Mouseover glow alone (one copy), 2..5 = + fill
  25/50/75/100% of the button. Unverified in game, incl. that the NormalTexture is ARTWORK.

## 0.125.0 — retail soft glow = Blizzard's glow only
- Lewis's side-by-side (Blizzard's yellow hover glow vs our red at 0.124.0): ours still
  covered the grey border (the fill). He wants it **exactly** like Blizzard's. Retail rounded
  buttons (no EUI look) now draw only Blizzard's Mouseover glow, `t` copies added on
  (BLIZZ_ART.GlowRing(g, i), g.amRings): thickness = strength, 1 = Blizzard's own. The
  fill, its mask (BLIZZ_ART.GlowMask, MASK_ATLAS) and MaskSoft are gone. Classic/EUI keep
  the gradient fill (20..100%).

## 0.124.0 — retail soft glow = Blizzard's own glow (+ fill)
- Lewis: match Blizzard's effect (his retail screenshot: the yellow hover/spell-highlight
  glow inside the grey frame ring) and **never cover the frame's border** on Blizzard's
  buttons. 0.123.2's 46 x 45 fill covered the ring.
- Retail rounded soft glow now: BLIZZ_ART.GlowRing(g) = atlas
  UI-HUD-ActionBar-IconFrame-Mouseover on the glow frame (OVERLAY 2), desaturated, ADD,
  vertex color x opacity, at Blizzard's place (TOPLEFT, button x 46/45 by button height).
  Plus the gradient fill back on the button's bounds, masked by the glow frame's own mask
  sized and centred exactly like the IconMask (no 46/45: 0.123.0's look, which left the
  ring alone). Thickness on retail: 1 = Blizzard's glow alone, 2..5 = + fill 25/50/75/100%.
  Classic/EUI unchanged (20..100%). Unverified in game.

## 0.123.2
- 0.123.1 in retail: the glow shrank to a small square up and left of centre. The mask atlas
  has **see-through padding** (known since 0.80.0, forgotten): stretched to the 46 x 45 area
  its shape came out far smaller. Now the glow's mask is sized like the button's own IconMask
  (its GetWidth/GetHeight; else the atlas's size x button/45), x 46/45 wide, centred on the
  46 x 45 glow frame. **Never size a mask from the area it should clip; size it like the
  IconMask.** Lewis guessed UI scale; it wasn't.

## 0.123.1 — retail soft glow where Blizzard's highlights are
- Lewis's zoomed retail screenshot (soft glow, thickness 5): the IconMask clip worked
  (rounded corners), but the fill stopped a pixel short of the frame on the right and
  bottom. Blizzard's retail template (gh api, Blizzard_ActionBar/Mainline/
  ActionButtonTemplate.xml): NormalTexture, PushedTexture, HighlightTexture and
  CheckedTexture are **46 x 45 anchored TOPLEFT** on the 45 x 45 button; Flash
  (UI-HUD-ActionBar-IconFrame-Flash), NewActionTexture and SpellHighlightTexture (Mouseover
  atlas, ADD, alpha 0.4, pulsing 0.35 s in / 0.35 s out) use their atlas size at TOPLEFT.
  The icon is 45 wide with IconMask (UI-HUD-ActionBar-IconFrame-Mask) centred on it.
- So on retail's rounded buttons (no EUI look) the soft glow frame now sits like those:
  TOPLEFT, button width x 46/45 by button height, snapped; clipped by its own MaskTexture
  (BLIZZ_ART.GlowMask(g): CreateMaskTexture on the glow frame, atlas
  UI-HUD-ActionBar-IconFrame-Mask, all points; atlas checked with C_Texture.GetAtlasInfo)
  instead of the button's IconMask. (The claim that a mask only clips its own frame's textures
  was wrong: 0.123.0's IconMask on the glow frame's edges did clip.)

## 0.123.0 — soft glow fills the button at 5, every game alike
- Lewis (retail screenshot of the Highlight demo, soft glow): can it fill the whole button at
  max thickness? Unsure about the steps; same for every game.
- StyleGlow's soft glow is now the FadeEdge gradients on every look (retail's rounded
  buttons included; the UI-ActionButton-Border ring copies, g.softs and BLIZZ_ART.GLOW are
  gone). Depth = (button width - 2 x inset) x thickness / 5: 20/40/60/80/100%, so at 5 each
  edge's fade spans the whole button and the four overlap to fill it. Retail (rounded, no
  EUI look): the four edges get the button's own IconMask via MaskSoft(g, mask)
  (pcall'd AddMaskTexture; removed again for other looks). **Unverified that a mask on the
  button applies to textures in the glow's child frame**: if not, the glow shows square
  corners on retail.

## 0.122.0 — fixes from the first retail (Midnight) test
- Lewis ran `/amac test 1 25000` on retail (addon 0.120.0, build 12.1.5 70575, interface
  **120105 confirmed**): 965 sorted, 775 missing, 123 noanswer, 14 notext, 532 unsorted.
  Compared item by item with the Classic Era test (0.108.4, same range): 773 sorted on both,
  729 the same. Reading tools (scratchpad, one-off): svread.py (SavedVariables -> JSON),
  cmptest.py (summary / diff / eraonly / retailonly / unsorted).
- Retail differences: raw fish are **7.8** (Trade Goods) with "must remain seated" (were
  hpot); retail's wizard oils "Applies ... oil to your weapon, increasing Intellect" (were
  buff_intellect); explosives are **0.8** (Other) with "Inflicts N Fire damage" (were
  unsorted); "increases X ... decreases Y" counted Y (Stormstout, Trogg Ale, Kreeg's);
  utility elixirs say "Allows you to breathe/walk". Spirit is gone on retail (Versatility
  items -> buff_other, fine).
- Fixed (CLASSIFIER 17): class 5/7 seated + health/mana -> food/water first; onWeapon
  ("to your weapon", "target weapon", "applied to", "coats a") -> weapon_buff before stat
  buffs; stats only counted before "decreas"; sub 8 + hurts (damage with inflict / does /
  causes / burning / deals, or "blasts open") -> explosives; buff words + "allows you to
  breathe" / "allows you to walk". **Not re-tested**: run the test again on retail and Era.
- Left alone: retail Gift of Arthas / Potion of Petrification wording, Arcane Bomb (0.0,
  "drains mana"), fun items, fishing lures, alcohol ("A typical alcoholic beverage").
- Lewis doesn't play retail and doesn't know what buttons retail players want.

## 0.121.2
- Lewis changed his mind: the game folders go back under Games\, and retail's folder is
  called **Mainline** (Blizzard's own name for the retail client); GAME = "mainline".

## 0.121.1
- Lewis: the game folders live in the project root (Forever\, ClassicEra\, TBC\, Mists\,
  Retail\), not under Games\. Moved with git mv; .toc paths and comments updated.

## 0.121.0 — per-game subfolders (then under Games\)
- Lewis asked for a subfolder per game holding only that game's files (separate code per
  game). See Code layout. The lists were split by expansion from 0.120.0's combined ones:
  checked with a script that retail's equal 0.120.0's exactly and every other game's are a
  subset (nothing added). No behaviour change intended: IDs dropped from a game are spells it
  doesn't have / items it can't carry. Forever = Classic Era's lists for now.
- tools/luacheck.py names files by their .toc path (four files are called Lists.lua).
- **Not run in game yet.** First thing to check after /reload: buttons still fill
  (Hearth/Teleport, Restore Health/Mana, Professions, Tracking), no Lua error on load.

## 0.120.0 — active tracking is the chosen one
- Lewis: the active tracking should always be the Tracking button's chosen one. CATALOG
  flag `tracking = true`; `ActiveTracking(list)` (Macros.lua): C_Minimap.GetNumTrackingTypes
  / GetTrackingInfo (table form, or the older name, texture, active, category, nested,
  spellID returns) matched by spellID or name, else GetTrackingTexture() vs SpellIcon.
  `ChosenFor(m, list)` = ActiveTracking for tracking buttons, else Chosen; used by
  UpdateCore's spells branch and OpenFlyout (the selected border). Event
  MINIMAP_UPDATE_TRACKING -> Schedule. **Unverified which API Classic Era answers**, and
  whether GetTrackingTexture's value equals the spell's texture (both should be file IDs).
- Not known: whether pressing the bar button (which /casts the active tracking) does
  nothing or turns tracking off on Classic.

## 0.119.0 — Tracking button
- Lewis: one button for all tracking spells, showing the ones a class/race can do. CATALOG
  `tracking` (AM_Tracking), same shape as Professions (kind spells, byName, autoSpells,
  scope character), Utility. `TRACKING_SPELLS`: Find Herbs 2383, Find Minerals 2580, Find
  Fish 43308 (TBC), Find Treasure 2481, Sense Undead 5502, Sense Demons 5500, Druid Track
  Humanoids 5225, Hunter Track Beasts 1494 / Humanoids 19883 / Undead 19884 / Hidden 19885 /
  Elementals 19880 / Demons 19878 / Giants 19882 / Dragonkin 19879. **From memory,
  unverified.** Hunter and Druid Track Humanoids share a name: byName keeps one (a
  character only has one). The Druid one needs Cat Form (the game says so if not).
  Retail tracks from the minimap menu: the button may be empty there.

## 0.118.0 — Professions button
- Lewis: a button for the tradeskill windows; first tried as a custom button, but **Classic
  Era's settings window blocks opening the spellbook** (no dragging spells from it while
  settings are open; dragging from an action bar onto the + works). Built-in instead, in
  Utility (A-Z puts it between Hearth/Teleport and Quest Item; Lewis said "on the bottom in
  utility").
- `PROFESSION_SPELLS` (Core.lua): every rank of First Aid, Cooking, Alchemy, Blacksmithing,
  Enchanting, Engineering, Leatherworking, Tailoring, Jewelcrafting, Inscription, plus
  Smelting 2656 and Poisons 2842. **IDs from memory, unverified** (3464 Expert Alchemy
  matched Lewis's bar in /amac debug). Retail professions likely use other spells: the
  button may stay empty there.
- CATALOG `professions` (AM_Profession, kind "spells", scope character, `byName`,
  `autoSpells`). KnownSpells with byName: one entry per spell name, highest known rank,
  `pick = name` (so a popout choice survives a rank-up). autoSpells: Stocked = #KnownSpells,
  AutoEnable takes it ("turned on (you know some)"). UI.Available counts known spells for
  any kind "spells" button (Portals too).

## 0.117.2
- Lewis (Classic Era): Agility on, Scroll of Agility in bags, not on a bar, but no glow on
  the Buttons page. `/amac debug`: "Agility Buff: 1 item(s), on a bar 0x" (Other Buffs the
  same), so UI.NotOnBars was right; the glow texture was empty. UnplacedGlow trusted
  `SetAtlas` returning false for a missing atlas; Classic Era returns nothing, so the
  CheckButtonHilight fallback never ran. Now: C_Texture.GetAtlasInfo first, and the
  fallback also when GetAtlas() is empty afterwards. **Rule: don't trust SetAtlas's return
  value on Classic; check the atlas exists first** (other SetAtlas uses: BarArt checks
  GetAtlas from a live texture, fine).
- **Confirmed fixed in Classic Era** (Lewis).
- `/amac debug` was the right tool again: per category "N item(s), on a bar Nx".

## 0.117.1
- Lewis's BugGrabber (Classic Era, in combat): ADDON_ACTION_BLOCKED, AutoMacros called
  protected `OpenSettingsPanel()` from Settings.OpenToCategory in OpenOptions, reached from
  the slash handler via a **bar macro** (UseAction -> MacroExecutionManager -> /amac
  opt...). None of our macros run that (only `/amac empty`), so likely a macro of his own.
  Fix: OpenOptions' Blizzard path in combat prints once and sets `optionsAfterCombat`;
  PLAYER_REGEN_ENABLED opens it then. EllesmereUI's OpenPlugin path is tried first as
  before (not protected).

## 0.117.0 — secure popout: click uses the item, in combat too
- Lewis wanted popout clicks to use the item (option: use and set / set only / use without
  setting), in combat as well; macro still only changes after combat. He'd never resize in
  combat (so sizing out of combat only is fine). **Entirely untested in game.**
- Design (Popout.lua): `flyout` = SecureHandlerBaseTemplate frame (protected);
  `secureHeader` (AutoMacrosSecure) holds frame refs "flyout", "e1".."e10" and attributes;
  entries = `ItemButton(flyout, true)` ("ActionButtonTemplate, SecureActionButtonTemplate"),
  made once in BuildFlyout, RegisterForClicks Left/RightButtonUp + attribute
  `useOnKeyDown` false (unverified that this makes them fire on release on every client).
- Every bar button in `buttons` that IsProtected gets `WrapButton(b)`: id, and
  SecureHandlerWrapScript(b, "OnEnter", header, "local id = N\n" .. OPEN_SNIPPET). The
  snippet (restricted env) reads header attributes n<id>, w/h, pt/rpt/x/y, per item
  ex/ey (offset / item scale k) and t/v ("item","item:ID" | "spell", name | "" = none),
  "mode" (set -> no type), "off", "max", "delay"; places/shows entries and flyout, sets
  type/item/spell, `f:RegisterAutoHide(delay)` + `f:AddToAutoHide(self)` (unverified that
  these handle methods exist on every client). Entries' OnClick wrapped: pre `return nil,
  true`, post hides the flyout.
- `PrepareSecure()` (end of RefreshArrows, ApplyStyle, the setting, PLAYER_REGEN_ENABLED
  when `secureStale`): out of combat only; StyleFlyout + StyleEntry all, writes the
  attributes from `FlyoutPlan(flyout, n, b, arrows[b], dir)` (LayoutFlyout split into
  plan + apply; LayoutFlyout now only for the settings demo) and keeps `prepared[id] = { m,
  list (copy), n, dir, plan }`. Insecure `OpenFlyout(button)` (HookScript OnEnter, after
  the snippet) only draws from prepared: icons, counts, desaturate, selected, dividers.
- PostClick (our code): equip unworn gear (out of combat), else unless mode "use"
  ChooseItem (automatic = prepared list[1]). Tooltip line per mode (POPOUT_CLICK_TIPS).
  Setting: `db.popoutClick` (nil = useset), `POPOUT_CLICKS`, `PopoutClick()`; Popout page
  Behaviour "Clicking an item".
- Combat guards: BLIZZ_ART.Size / Point return for protected frames in combat;
  StyleButtonArt's SetChecked pcall'd; RefreshArrows only hides the flyout out of combat.
- Dropped: hover tracking (SetOver/AnyOver/idle OnUpdate), opening from the tab (arrow
  EnableMouse false), Escape closing (UISpecialFrames with a protected frame taints).
- **Lewis, Classic Era: works** out of combat (Bandage popout, Cannibalize cast at once and
  became the button's spell) and in combat (item used, popout closed, button changed after
  combat). Classic Era target dummies are Engineering items: test combat on a mob.
- Then also confirmed: Set only and Use only, closing on leave, a button moved to another
  slot then hovered, Hearth/Teleport (spells). Not checked: unworn teleport ring,
  EllesmereUI bars, retail.

## 0.116.1
- Lewis: the "A" isn't needed (Automatic is the default, the tooltip says the direction).
  UI.DirMark draws only the tab (still alpha 0.6 on Automatic).
- Lewis also asked for a popout click behaviour option (use and set / set only / use
  without setting): picking Cannibalize from Bandage's popout only set it. Popout entries
  are insecure (ActionButtonTemplate CheckButtons), so they cannot use an item or cast;
  see the next entry for what was decided.

## 0.116.0 — four columns (a test)
- Lewis liked 0.115.0 ("beautiful!"); asked for the Buttons page checkboxes in 4 columns
  as a test. `UI.GRID_COLS` (OptionsPages.lua, 4) for Blizzard's page: column =
  (width - lx - 10) / cols (~130 on the 560 page), label width column - 30; the off-button
  count is now "(3)" in green, not "(3 available)" (too long for the column). EllesmereUI's
  page keeps its 3-wide TripleRow. Back to 3 = set UI.GRID_COLS = 3.

## 0.115.0 — popout direction by right-click on the Buttons page
- Lewis (right after 0.114.0): no labels and dropdowns; click the button to cycle its
  direction, on the Buttons page: right-click, Automatic default, cycle; an indicator for
  automatic vs manual; buttons on the bars should show (on the page) how they open there.
- `POPOUT.CYCLE` auto/up/right/down/left, `POPOUT.Chosen(e)`, `POPOUT.Next(e)` (saves
  db.popDir, auto = nil). RefreshArrows fills `report.barDir[name]` = **POPOUT.Auto** of
  the first visible bar button holding it (the automatic direction, not Direction(), so
  going back to Automatic doesn't show the old manual one).
- Icon strip: RegisterForClicks left+right; right-click = POPOUT.Next + Refresh +
  RefreshHeaders (+ tooltip redrawn). `UI.DirShown(e)` = chosen dir, or on auto barDir
  while on (nil = not on a bar); `UI.DirMark(b, e, size)`: solid tab (tabColor, alpha 0.6
  on auto) 3 px x half the edge on that edge inside the icon, "A" top-left on auto, both
  ignore parent alpha. Tooltip line `UI.DirText(e)`. Hint text extended; previewH 160.
- Removed: the Popout page's Direction section, UI.DirectionItems / DirectionStamp, and
  0.114.0's `choicepairs` item type (nothing else used it).

## 0.114.0 — Direction in two columns
- Lewis (Classic Era screenshot of the Popout page): note that only buttons that are on are
  listed; more compact, 2 columns. DirectionItems: note text (height 36) + one item of new
  type **`choicepairs`** (`items` = the choices, full titles kept: there is no group
  heading). BuildPage: on EUI it is flattened (adjacent dropdowns pair into DualRows by
  themselves); on Blizzard's page two per row: column = (width - lx - 10) / 2, label 48% of
  it, MakeChoice width = column - label - 44 (room for UIDropDownMenu's side art).

## 0.113.0 — welcome window
- New file **Welcome.lua** (after Custom in the .toc). Lewis chose: what the addon does,
  buttons found for you (draggable), pick buttons to turn on, Open settings + Got it; once
  per character.
- `UI.WelcomeDue()` runs at the start of Init (before anything is saved for the char):
  `db.welcomed[char]` set -> no; the char has a non-empty table in enabledBy / picks / idx
  (used AutoMacros before) -> marked welcomed, no; else `report.welcomeDue`. Shown from the
  3 s step after PLAYER_ENTERING_WORLD (bags read, AutoEnable done) via `UI.ShowWelcome`.
  Any close (Got it, X, Escape via UISpecialFrames, Open settings) marks it seen (OnHide).
  `/amac welcome` shows it again.
- Frame `AutoMacrosWelcome`: BasicFrameTemplateWithInset (TitleText) or a plain dark frame
  + UIPanelCloseButton; DIALOG strata, movable. `UI.RefreshWelcome` (also from
  report.afterUpdate) lays it out: intro, "Ready for you" = `UI.WelcomeReady()` (on and
  `UI.Available` > 0; icons drag/click -> UI.PickUp), "Your buttons" = `UI.WelcomeButtons()`
  (ButtonSections' grids flattened, so no custom buttons), MakeToggle 3 per row with
  "(n)" counts, then the two buttons; height fits the content. Untested in game; the
  template's look on Classic Era / Forever unchecked.

## 0.112.0 — custom buttons mix items and spells
- Lewis: why can't a custom button hold both? (No reason: built-in set buttons already
  append spells.) He chose: in the order added, rearrangeable in the custom settings.
- Saved form `db.custom[key] = { title, list = { {kind="item"|"spell", id}, ... }, scope,
  oldNames }`. `CustomThings(c)` (Core.lua) converts the old `kind`/`ids` on first read
  (spells -> scope "character"; `/amac custom` still writes the old form, converted too).
  New buttons: scope "character" if the first thing is a spell, else general (never changes
  afterwards, so the macro never moves tab).
- CustomEntries: `e.order` = the list, `e.set` (items via DATA) and `e.spells` (nil when
  none, so BodyMatches only accepts /cast then) for counting/recognising; placeholder =
  first thing ({ icon = SpellIcon } for a spell). UpdateCore has an `m.order` branch: carried
  items / known spells in list order (spell entries pick = -id), Chosen, Use/SpellBody,
  EmptyBody when none. No item level filter there (you chose them).
- Custom.lua: `UI.ThingKind` ("items"/"spells" -> "item"/"spell"), CustomAdd appends any
  kind (dedup kind+id), `CustomRemove(key, i)`, `CustomMove(key, i, j)`. Rows: click an icon
  = pick (`UI.customMoving = {key, i}`, shown with SetChecked + LockHighlight via
  `UI.MarkMoving(parent)` over `parent.amCustomIcons`), click another of the same button =
  move there, same one again = cancel; right-click removes. Click-to-move instead of drag:
  dragging would need the thing on the cursor (could land on a bar) and the simulator's
  cursor position is unreliable.
- Next: the welcome screen (Lewis chose all four parts: what the addon does, buttons found
  (draggable), pick buttons to turn on, Open settings + Got it; once per character,
  `/amac welcome` to show it again).

## 0.111.0 — General first
- Lewis: General should be the page settings open on; Buttons its own page. PAGES order is
  now General, Buttons, Highlight, Popout. **PAGES[1] is the AutoMacros category itself**
  (MakePanel names it "AutoMacros", RegisterBlizzPanel registers it, older clients open it);
  the rest are subcategories. Nothing may assume Buttons is panel 1: RefreshButtonsPage
  finds it by name.

## 0.110.0 — custom buttons on the Buttons page
- Lewis: the Custom page can go; put a + "at the end of the row" (the Buttons page's icon
  strip) with a tooltip explaining what to do. PAGES has no Custom entry any more (EUI's page
  list follows PAGES); Buttons' stamp = ButtonsStamp .. "|" .. CustomStamp.
- HEADERS.buttons: `slots = #list + 1`, `place(b, i)` centres rows incl. the +; `f.newSlot` =
  `UI.DropSlot(f, size, CustomCreate, UI.NEW_BUTTON_TIP)` (DropSlot takes tooltip lines now).
  Custom icons in the strip take drops (OnReceiveDrag, or OnClick with something on the
  cursor) -> `UI.AddToIcon` -> CustomAdd.
- ButtonSections: custom buttons are no longer in a checkbox grid; last section "Custom" =
  item type `customrows` (BuildPage) -> `UI.BuildCustomRows(parent, width, x, y,
  refreshers)` (was BuildCustomPage, minus title/note/New button): per row MakeToggle
  (via `UI.CustomEntry(key)`), name box (tooltip "Type a new name and press Enter"), icons,
  add slot, Delete. UI.RefreshCustomPage removed. Untested in game.

## 0.109.2
- Lewis: rework the Buttons page's icon-strip hint (HEADERS.buttons `f.hint`). Now plain
  sentences: click / drag, "The green number is how many you have or can make", "A glowing
  icon has items but isn't on any of your bars yet." Lewis prefers short, plain help text.

## 0.109.1 (Lewis: "perfect")
- Lewis found the Direction note confusing (it spelt out every edge). Now one line:
  "Automatic opens each popout toward the middle of the screen." (text item height 30).

## 0.109.0 — Buttons page A-Z
- Lewis: sort each group on the Buttons page alphabetically. `UI.ButtonSections`' `add`
  sorts every list (groups, Custom, Other) by `Loc(UI.Name(e))`, case-blind; BUTTON_GROUPS
  now only decides which group a button is in. Grid fills row by row (A B C / D E F).
  The icon strip (HEADERS.buttons) keeps AvailableButtons' order.
- 0.108.4 released as a pre-release (v0.108.4, first release since 0.85.0); Lewis checked
  every button in game on Classic Era except Weapon Buff (no sharpening stones yet).

## 0.108.4 — fourth Classic Era test (addon 0.108.3)
- 912 sorted, 623 Use-but-none, 142 missing, 0 noanswer, 44 notext. All 0.108.3 targets
  right (Anti-Venoms 5.0 -> cure; 20+ stones/oils 7.0 -> weapon_buff; mana gems -> mpot).
  Class 5 caused no false positives.
- Fixed (CLASSIFIER 16): weapon not on "attach" (Steel Weapon Chain 6041); class 5/7 weapon
  not sub 3 (Goblin Dragon Gun 10727); restore not on "mechanical" (Mechanical Repair Kit
  11590); class 5/7 `resist` -> buff_resistance (Frozen Rune 22682, Flame/Ice Deflector
  4376/4386).
- Left as is: Recombobulators 4381/18637 (7.3, dispel polymorph + restore health and mana)
  -> hpot+mpot; Seaforium charges and Flash Bomb (7.2) -> explosives via the sub-2 rule.
  Unsorted 7.3 = engineering gadgets (dragonlings, pets, scopes "permanent", target dummies,
  jumper cables, reflectors), 7.0 essences / skeleton keys / shield spikes: no button, fine.
- The scratchpad testread.py from 0.107.1 was lost; rewritten (summary / unsorted / ids / <set>).

## 0.108.3 — what Classic Era's client says about the missing items
- Lewis's `/dump GetItemInfoInstant` on Classic Era: Anti-Venom 6452 = **class 5 (Reagent)
  sub 0**; Rough Sharpening Stone 2862 = **7.0**; Mana Agate 5514 = **4.0**. All three have
  slot **`INVTYPE_NON_EQUIP_IGNORE`** (so NotWorn missed Mana Agate).
- Fixed (CLASSIFIER 15): LOOKED_AT + class 5; NotWorn accepts INVTYPE_NON_EQUIP_IGNORE;
  classes 5 and 7 share one branch: restoring -> hpot/mpot, quest use -> quest, weapon + Use
  -> weapon_buff, else nothing (cures are caught earlier for every class). The test's
  `unsorted` now also covers classes 5 and 7, so class-7 misses no longer vanish.
- Next: another `/amac test` on Classic Era; check that reagents with a Use line don't
  flood buttons.

## 0.108.2 — fixes from the third Classic Era test
- Third test (addon 0.108.1): 871 sorted, 568 Use-but-none, 139 missing, **0 noanswer**,
  1033 notext. Flow control works. All common potions, mana gems, flasks, elixirs, Juju,
  protection potions, bandages, conjured water, rage potions, poisons/oils, 302 quest items
  (sample right), travel incl. Stormwind Medallion / Scepter of Celebras portals.
- **The Classic Era client reports nearly everything as class 0 sub 0** (833 of the listed),
  not Wowhead's classes (Wowhead: Anti-Venom 15.1, sharpening stones / wizard oils 0.-3,
  Mana Agate 4.0). Anti-Venom 6452/19440, Rough/Dense Sharpening Stone 2862/12404, Brilliant
  Wizard Oil 20749, Mana Agate 5514 were in **no** list (not found by WorthALook?): asked
  Lewis for `/dump GetItemInfoInstant(6452 / 2862 / 5514)`. Healthstones say "life", come
  via MADE (InSet), so the test lists them unsorted: expected.
- Fixed (CLASSIFIER 14): `NotWorn(slot)` ("" / INVTYPE_NON_EQUIP / nil): class 4 not worn
  counts like a consumable (WorthALook, Classify); cure words "remov"/"neutraliz" +
  "negative"/"affliction", or "cures the user"/"cure for the"; cure only when not a quest item
  (quest items that "cure a sickly animal" -> quest); weapon also on "coats a"; permanent on
  "perman" (test item "Permantly"); buff also "gives the imbiber", "gives you", "allows the
  imbiber", "lets you", "is immune", "shows the location" (utility potions -> other).
- **Classify needed 2 tooltip lines**, so plain reagents (tooltip = name only) returned nil:
  1033 "notext" in the test (IDs 537, 555, 723, 729: Dull Heart, vulture feathers, Goretusk
  Liver, vulture meat), and in play every reagent in bags was retried for ~20 s each session.
  Now 1 line is enough (the GetItemSpell guard still waits for missing Use text).
- Not handled (ideas): combat tools (nets, Sticky Glue, Marbles, Wail of the Banshee),
  fishing lures, Thistle Tea (energy; could share Rage), soulstones / resurrection items.

## 0.108.1 — fixes from the second Classic Era test
- Second test (probably 0.107.0: event-driven, no flow control): 374 sorted, 219 Use-but-none,
  139 missing, **1983 no data, incl. nearly every common consumable** (Lesser..Major Healing,
  mana potions, Flask of the Titans, Mongoose, Juju Power, Linen Bandage, sharpening stones,
  conjured water) -> asked too fast. Sorted ones were right: bandages, scrolls/elixirs,
  Blasted Lands, Juju, armor, resistance, explosives (incl. thrown items), 150 food, 50 buff
  food, 39 water (Arathi rations on both), hpot/mpot, travel (AV insignias), rogue poisons ->
  weapon buff (fine).
- Fixed (CLASSIFIER 13): `permanent` ("permanently" / "permanent enchant" in a Use line) ->
  no button (QAEnchant test items, ZG head/leg enchants, Fortitude of the Scourge, armor
  kits); restore also on "heals" (Greater Dreamless Sleep; bandages checked earlier); buff
  also on "regenerate" (Troll's Blood, Mageblood -> other); seated food/drink for any class
  incl. quest/misc, before buff food is excluded (`not wellFed`); the own-only food branch
  removed.
- Test: `res.addon` (C_AddOns.GetAddOnMetadata / GetAddOnMetadata), nodata split into
  `noanswer` / `notext`.
- Left for later: class-0 quest-use items with no "Quest Item" line on Classic (Nimboya's
  Laden Pike "Place at a Witherbark village", Dark Keeper Key "Use on the Dark Coffer"):
  check after the next test whether the quest rule catches them. Ideas seen: mounts, pets,
  fireworks, combat tools (Bag of Marbles, Sticky Glue, Hunting Net) could get buttons.

## 0.108.0 — Quest Item button
- Lewis: a button for usable quest items. CATALOG `questitem` ("Quest Item", AM_QuestItem,
  set `quest`, placeholder Gold Pickup Schedule 1307 = class 12 on classic/retail/forever),
  Utility group. Classify (CLASSIFIER 12): `quest` = class 12 or a tooltip line equal to
  ITEM_BIND_QUEST ("Quest Item"); `questUse` = quest + Use line -> "quest", after restoring /
  stats / armor / resistance (so Juju, E'ko, healing quest rewards keep their buttons) and
  before weapon / explosives / other buffs; class 7 (non-restoring) and 12/15 too.

## 0.107.1 — test flow control
- **First Classic Era test (0.105.0)**: 11,476 items looked at, only 31 sorted (28 explosives,
  which need no server), **11,445 no data**, 0 unsorted. Asking ~80/s for 6 rounds: the server
  drops most requests. Fix: at most TEST_INFLIGHT (50) questions out; `run.pending[id]` =
  time asked, `run.inflight`; no answer in TEST_RETRY (10 s) -> cached? sort : ask again, up
  to TEST_TRIES (3), then `res.nodata`; items in but no Use text -> `run.spell[id]` = since,
  given up after TEST_QUIET (30 s); `TestDone` takes an item off every list. Finish when
  nothing waits, or after 60 s without progress.
- Reading the results: scratchpad script `testread.py <SavedVariables file> [set|unsorted|all]`
  (one-off, not in the repo).
- previous/0.107.0 was again saved from git after the first edit.

## 0.107.0 — event-driven test; gear slot filter
- Lewis: why so many "no data" (first test was on retry round 4 of 6); wait for each item's
  data and drop items of no use. Likely causes: IDs in the client files the server never
  serves (unused items), spell text never arriving, server pace.
- `ItemInstant` also returns the equip slot (6th). `WorthALook(id)` (Learning.lua): class in
  LOOKED_AT, and class 4 only in TELEPORT_SLOTS (finger, trinket, cloak, neck, tabard); nil =
  unknown item. Used by Classify, LearnNew and the test (Atiesh, a weapon, is not covered).
- RulesTest: asks TEST_STEP per tick, `run.waiting[id]`; answers via its own frame on
  GET_ITEM_INFO_RECEIVED / ITEM_DATA_LOAD_RESULT (id, success) -> `TestAnswer`: success ==
  false -> res.missing; else `TestSort` (Classify; nil = Use text pending -> run.spell, retried
  each tick). Cached items (C_Item.IsItemDataCachedByID / GetItemInfo) sorted at once. Done
  when nothing waits, or TEST_QUIET (30 s) without progress -> leftovers res.nodata. Progress
  bar: answered / found.

## 0.106.0 — Custom page (drag and drop)
- Lewis: make custom buttons in the settings by dragging items from bags / spells from the
  spellbook onto a blank button. New file **Custom.lua** (after OptionsPages in the .toc):
  db.custom[key] = { title, kind = items|spells, ids, oldNames }; `UI.CustomCreate(kind, id)`
  (key from the name via `UI.CustomKey`, title = item/spell name, 16 chars), `CustomAdd`
  (one kind per button), `CustomRemove` (last one out deletes the button), `CustomRename`
  (old title + "No <old>" into oldNames; CustomEntries passes `oldNames`, so FindMacro finds
  and Apply renames the macro), `CustomDelete` (as /amac custom delete: toDelete). After a
  change `UI.CustomChanged` (RebuildMacros, Refresh, headers, Custom + Buttons pages, EUI).
  `UI.CursorThing()`: GetCursorInfo "item", id / "spell", slot, book, spellID (fallback
  GetSpellBookItemInfo(slot, book)); `UI.DropSlot` takes it on OnReceiveDrag or OnClick.
- Pages may have `build = fn(parent, width) -> y` (UI.ShowPanel, EUI buildPage) besides
  sections. PAGES: Custom is 2nd (tree: right under AutoMacros), stamp UI.CustomStamp; the
  Buttons page now has stamp `UI.ButtonsStamp` (keys + titles) so new buttons appear.
  `/amac custom` still works as before. Untested in game.

## 0.105.0
- Lewis: a progress bar for the test. Learning.lua: `TestBar()` (frame AutoMacrosTestBar,
  draggable, StatusBar UI-StatusBar, Stop/Close button via UIPanelButtonTemplate or plain),
  `TestBarUpdate(run)` after each tick (find 0-10%, ask 10-40%, sort 40-100%, retry rounds
  at 99%), `TestBarDone(text)` from finish / on error. run now keeps first/last.
- 0.104.0's Classic food fix confirmed in Carkke's saved data: 4539/6303/6361 -> food,
  5479 -> food_buff, 3531 -> bandage.

## 0.104.2
- Lewis (Classic Era, BugSack-style error): Class color mode -> "unable to find mixin or
  metatable (ColorMixin)" in StyleColor. Regression from 0.102.0's setfenv (see Code layout).
  Fix: copy `*Mixin` into ns (Core.lua); StyleColor pcalls C_ClassColor.GetClassColor and
  falls back to RAID_CLASS_COLORS. 0.104.1's soft glow confirmed fixed on Classic Era.

## 0.104.1 — soft glow
- Lewis (Classic Era screenshot, Highlight page, Soft glow, thickness 5): a hard red box inset
  in the button. The Blizzard-look soft glow cropped UI-ActionButton-Border less for more
  thickness (0.80.0), which only shrinks its ring towards the middle. Now (StyleGlow, Art.lua):
  square buttons (`not BLIZZ_ART.Rounded()`, i.e. Classic and EUI) use the FadeEdge gradients
  from the button edge (depth t x 3 px; inset only with the EUI look); rounded (retail) draw
  `t` copies of the ring at a fixed crop 0.21 (`g.softs`), copy i inset (i-1) x 2 px. The
  retail look is **unverified**.

## 0.104.0 — Classic Era: rules by text, not subclass
- Lewis (character Carkke-Mankrik, Classic Era): food on Restore Health. Its saved data:
  Goldenbark Apple 4539, Raw Rainbow Fin Albacore 6361, Raw Slitherskin Mackerel 6303 ->
  hpot; Crispy Lizard Tail 5479 (buff food) -> hpot; Heavy Linen Bandage 3531 -> explosives.
  **Classic Era's client reports nearly all consumables as subclass 0 "Consumable"**
  (Wowhead's classic pages show 0.5 / 0.7 etc., the client does not), so sub 5 / 7 / 3 / 1
  rules missed and food fell through to "restoring", the bandage ("Heals 301 damage over
  7 sec.") to sub 0 + damage = explosives.
- Classify (CLASSIFIER 11): new text flags `bandaged` (heals + damage), `flask` ("one flask" /
  "persists through death"); for consumables (`own`, i.e. not quest/misc): bandage -> flask
  -> well fed = food_buff -> seated + health/mana = food/water -> rage -> restoring =
  hpot/mpot -> stats ... The sub 5 / sub 1 conditions are gone (early returns for sub 7 / 3
  kept). Quest/misc items still only restoring + buffs.
- Process slip: previous/0.103.0 was saved from git (HEAD) after the first edit had started.

## 0.103.0 — in-game rules test; Classic Era set up
- Lewis installed **Classic Era** (1.15.9, interface 11509) and will mostly play Forever, so
  rules are checked on Classic first. `_classic_era_\Interface\AddOns\AutoMacros` is now a
  **junction to this project folder** (created 2026-10-26; the game hadn't made AddOns yet),
  like retail's. Its saved data: `_classic_era_\WTF\Account\<acct>\SavedVariables\AutoMacros.lua`.
  `.build.info`: Forever 1.60.1.70532 (16001), retail 12.1.5.70575, Classic Era 1.15.9.70576.
- Instead of scraping Wowhead (category pages 403 to scripts; lists not needed at runtime):
  `/amac test [first] [last]` (Learning.lua, `RulesTest`, state `testRun`): finds IDs in the
  range whose class is in LOOKED_AT (ItemInstant, no server), requests their data
  (C_Item.RequestLoadItemDataByID or GetItemInfo, TEST_STEP 20 per TEST_TICK 0.25 s), runs
  Classify, no-data items retried up to 6 rounds (3 s apart). Saves `db.test`: build,
  interface, first, last, counts[set], items[id] = "sets | class.sub | name | Use/well fed
  lines" (`TestLine`), unsorted[id] (class 0/15 with a Use: line, no button), nodata. Learns
  nothing. Next: Lewis runs it on Classic Era, /reload, then read the file and fix rules.

## 0.102.0 — split into files (no behaviour change)
- Lewis asked whether to split the Lua (efficiency: none; reasons: the 200-local limit at
  191, and readability). Done mechanically with a one-off script: top-level `local`s
  dropped (190 names), forward declarations removed, AutoMacrosDB/SLASH_ written via _G,
  cut at section boundaries in the original order. Checked: the code lines of the 12 files
  equal the old file's line for line (4171), apart from those changes; the old file's only
  real global writes were exactly those three. `tools/luacheck.py` now takes the .toc.
  **Not run in game yet** (setfenv on the chunk is standard Lua 5.1, used by other addons).

## 0.101.0 — chat toggles
- Lewis: option in General to show/hide chat messages; he chose two separate toggles.
  `Note(msg)` (top-level, after Print, 191/200) = Print unless `db.quiet`; used for what the
  addon says by itself (learned/relearned/no longer fits, turned on, macro deleted / left
  alone, will change / be deleted when combat ends, off on this character, merge notes).
  **New automatic messages should use Note; replies to /amac and actionable problems Print.**
  `db.noEmptyMsg` makes the slash handler's `empty <text>` branch return silently. Settings:
  General section "Chat".

## 0.100.0
- 0.99.0 works in retail (Lewis). The tooltip's "(carried, or you can make them)" was vague:
  teleports are cast, not made. `UI.Available` now returns `n, parts` (bags / spells / create
  / craft; travel splits TravelOptions by `spell`, set buttons count KnownSpells, e.g.
  Cannibalize); `UI.AvailableText(n, parts)`: one source -> "N available in bags / as spells
  / to create / to craft", several -> "N available: 1 in bags, 3 spells". Wording: create =
  conjured (healthstone, mana gem), craft = professions, spells = cast.

## 0.99.0 — "N available" (carried, made, craftable)
- Lewis: disabled buttons should count what the character can make: healthstone / mana gem if
  the spell is known; crafted items only when the recipe is known **and** every reagent is in
  the bags (e.g. First Aid health potions). Wording "N available", not "in bags".
- `UI.CouldUse` -> `UI.Available(e, have)` = Stocked + 1 if MadeCreate known and none carried
  + each recipe product in the button's set (InSet) not carried with `UI.CanCraft(need)`
  (CountOf per reagent, any of a slot's ids). Only the settings indicator; buttons/macros
  still use bags only. Tooltip "N available (carried, or you can make them)", grid
  "(N available)", strip hint updated.
- Recipes can only be read with a profession window open: events TRADE_SKILL_SHOW / _UPDATE /
  _LIST_UPDATE -> `UI.QueueScan` (one read 1 s after, then Update) -> `UI.ScanRecipes`: retail
  C_TradeSkillUI.GetAllRecipeIDs + GetRecipeInfo(.learned) + GetRecipeSchematic(outputItemID,
  reagentSlotSchematics: required ~= false, reagents[].itemID, quantityRequired); older
  clients GetNumTradeSkills / GetTradeSkillInfo (skip header/subheader) / ItemLink /
  NumReagents / ReagentInfo (count) / ReagentItemLink. Saved `db.recipes[char][itemID] =
  { { ids = {...}, n = k }, ... }`, merged per scan. **Untested on every client**; Enchanting's
  Craft API (classic) not read. Products are learned quietly: UpdateCore passes have +
  recipe products to LearnNew(look, loud = have), which only prints for loud items.

## 0.98.0 — one Debuff Cure button
- Lewis: anti-venom, disease and bleed removal in **one** button; more debuff removers will
  turn up. 0.97.0's three buttons -> `cure` ("Debuff Cure", saved name AM_AntiVenom, alias
  antivenom, oldNames = Anti-Venom / Disease Cure / Bleed Cure names, UI.SHORT "Cure",
  placeholder Restorative Potion). Rule: cure/remove/neutralize/dispel + poison, disease,
  bleed, curse, magic, stun, impair, snare, root or harmful -> `cure`. CLASSIFIER 10. Init
  moves enabledBy/popDir/manual learned antivenom|antidisease|antibleed -> cure (on if any).

## 0.97.0 — cures; quest and misc items count
- Lewis: get **every item that benefits the player** into the right category, incl. quest
  rewards that remove diseases/poisons; on Forever First Aid crafts disease removal.
- Forever (Wowhead XML): Simple Poultice **255716** "Target is cured of diseases up to level
  25. Not usable in combat." and Woolen Tourniquet **255720** "cured of bleeds", both class
  **7.11 (Trade Goods)**. Jungle Remedy 2633 "Cures diseases and neutralizes poisons";
  Purification 13462 "remove one Curse or Bane, one Disease and one Poison"; Restorative 9030
  "Removes 1 magic, curse, poison or disease"; Potion of Poison Cleansing 3386 "cured of up to
  four poisons"; Anti-Venom 6452 / Powerful 19440 "Target is cured of poisons"; Immature Venom
  Sac 12586 "Cures 1 poison effect". Forever First Aid also makes healing potions and
  Anti-Venom (sources: Warcraft Tavern / Icy Veins / Blizzard Watch, beta-era).
- New buttons `antidisease` ("Disease Cure", AM_Disease) and `antibleed` ("Bleed Cure",
  AM_Bleed), Recovery group. Classify (CLASSIFIER 9): `cures` table from Use lines with
  cure/remove/neutralize + poison/disease/bleed; checked right after travel for every class
  but 4 (gear), returns every cure set that fits. Class 7 then still only for restoring;
  classes 12 **and 15** get sub = -1 (restoring + buffs; not food, weapon, explosives).
  Buff word excludes "fishing" (lures).

## 0.96.0
- Lewis (screenshot of the Buttons page): drop "Buff" under Buffs and "Restore" under
  Recovery. `UI.SHORT` (key -> settings name) + `UI.Name(e)`, used only by the Buttons page's
  checkbox grid (both paths). Macro names (`title`) stay full on purpose (a bare "Health" could
  clash with a user's macro); icon tooltips and the Direction list keep full titles (no
  section heading there).
- Lewis: Undead racial on the Bandage button. CATALOG entries with `set` may have `spells`:
  UpdateCore's set branch appends KnownSpells after the items (`spell = true`, pick = -id,
  as on Hearth/Teleport) and casts via SpellBody when one is chosen; BodyMatches accepts /cast
  for them. Bandage: spells = { 20577 } (Cannibalize). Stocked still counts items only.

## 0.95.0 — Restore Health / Restore Mana
- Lewis: combine health potions + healthstones and mana potions + mana stones; if the
  character can make one and carries none, make it; otherwise use what's carried; include any
  restorative item; Rejuvenation on both.
- `MADE` (top-level) = { hpot = { rank = HS_RANK, spells = CREATE_HS }, mpot = { rank = mana
  gems 5514/5513/8007/8008/22044/36799, spells = 42985/27101/10054/10053/3552/759 } } (post-
  vanilla IDs unverified). InSet also accepts MADE ranks (Major Healthstone says "restores
  1440 **life**", which the rules don't read as health). `MadeCreate(set, have)` = known
  create spell name + whether one is carried. UpdateCore's set branch: MADE items sorted
  first by rank; create known and none carried -> `#showtooltip <create>` / `/cast [nomod]` /
  `/use [mod:shift] item:<chosen>`, not "empty" (`making`). BodyMatches: MADE set + /cast.
  AutoEnable switches these on when a create spell is known.
- Removed: the healthstone CATALOG entry (special "healthstone", character scope),
  HealthstoneBody, BestHealthstone, CreateSpellName. healthpot/manapot keep their saved names
  (AM_HealthPot/AM_ManaPot), titles "Restore Health"/"Restore Mana", empties "No Health
  Items"/"No Mana Items", oldNames = the potion names; healthpot alias "healthstone".
  `UI.MergeHealthstone` (Init, once, db.healthMerged): healthpot on if healthstone was;
  popDir moved. `UI.RemoveHealthstoneMacro` (3 s step, every login, per character): deletes
  "Healthstone"/"No Healthstone" macros that make/use a healthstone or have the empty text.
- Rules (CLASSIFIER 8): `restoring` = restore + health/mana, not weapon (mana oils). Any
  consumable (not sub 6, not quest) -> hpot/mpot; Food & Drink that restores without
  "seated"/"while eating/drinking" (Whipper Root Tuber) too; class 7 trade goods are now read
  and count only when restoring (Demonic Rune is 7.11). Checked on Forever (Wowhead XML):
  9421, 8008, 18253 (both), 12662, 11951, 11952 (both), 20748 (excluded), food 4540/159/8932,
  buff food 2682.

## 0.94.0 — "not on your bars" glow
- Lewis: on the settings page, mark buttons that have items but are not on an action bar, as
  the spellbook does (glow + tooltip). From Blizzard's source (gh api on Gethe/wow-ui-source,
  Blizzard_PlayerSpells/SpellBook/Blizzard_SpellBookItem.xml/.lua): `Button.ActionBarHighlight`
  = atlas `spellbook-item-unassigned-glow`, ADD, TOPLEFT -4,3 / BOTTOMRIGHT 3,-3, looping Alpha
  0.5->1 (0.5 s, OUT) then 1->0.5 (IN); shown when status MissingFromAllBars; tooltip line
  `SPELLBOOK_SPELL_NOT_ON_ACTION_BAR` in LIGHTBLUE_FONT_COLOR (spell wording, so ours is
  "Not on your action bars - drag it onto one" in that color).
- `UI.NotOnBars(e)` = Stocked > 0 and `report.onBar[name]` == 0; `UI.UnplacedGlow(b)` copies
  the glow (fallback texture CheckButtonHilight, ignores parent alpha); icon strip only.
  `report.onBar` now counts every visible bar button holding the macro (it used to count
  nothing while popouts were off). After bar changes (ScheduleGlow's run, the bar watcher)
  `report.afterUpdate` refreshes the open settings page.
- `gh api repos/Gethe/wow-ui-source/contents/<path> -H "Accept: application/vnd.github.raw"`
  works for reading Blizzard's UI code (raw.githubusercontent 404'd on that path guess;
  `gh search code ... --repo Gethe/wow-ui-source` finds files).

## 0.93.0 — Armor Buff and Resistance
- Lewis likes Other Buffs; attack power items stay there (vanilla has ~3: Winterfall
  Firewater, Juju Might, Elixir of Demonslaying - from memory). Resistance gets its own
  button; armor/defense separate from it.
- 0.92.0's `protection` button -> `armor` ("Armor Buff", set `buff_armor`, saved name still
  AM_Protection, oldNames Protection/No Protection, alias protection): `armor` flag = buff
  word + armor/ARMOR/defense. New `resistance` ("Resistance", AM_Resist, `buff_resistance`):
  `resist` flag = buff word + "resist", or "absorb" + damage (protection potions). Both
  checked after the stat buffs; an item can get both. CLASSIFIER 7. Init moves
  enabledBy/popDir `protection` -> `armor` (for anyone who ran 0.92.0).
- Forever tooltips checked: Gift of Arthas 9088 -> resistance, Elixir of Defense 8951 ->
  armor, Fire Protection Potion 6049 -> resistance, Elixir of Lesser Fortitude 3825 -> stamina.

## 0.92.0 — buff buttons by buff, not by item type
- Lewis: scrolls and buff potions etc. should share a button per buff type; Flask, Buff Food,
  Weapon Buff stay separate; then also a button for armor (protection potions and scrolls).
  He didn't pick the buff list; I used Agility, Intellect, Stamina, Strength, Spirit,
  Protection, Other Buffs (sets `buff_<stat>`, `buff_protection`, `buff_other`).
- CATALOG: keys agility/intellect/stamina/strength keep the old elixir buttons' saved names
  (AM_ElxAgi, ...) with `oldNames` = the old elixir macro names, so FindMacro finds and Apply
  renames the existing macro; `alias` = old elixir key. New: spirit (AM_Spirit), protection
  (AM_Protection), otherbuff (AM_OtherBuff). BUTTON_GROUPS Buffs updated.
- Classify (CLASSIFIER 6): STAT_KEYS + spirit (SPELL_STAT5_NAME). hpot/mpot need "restore"
  (so "maximum health" elixirs aren't potions). `buff` = increase/improve/grant/raise, not
  "permanent" (armor kits); `protect` = buff + Armor, or "absorb" + damage. Order after
  food/rage/potions: stats (not sub 6) -> protection -> weapon -> explosives (sub 0, damage,
  not buff) -> other buffs. **Class 12 (Quest) is now looked at**: Juju Power/Might are 12.0
  on Forever (Wowhead); quest items count only as stat/protection/other buffs (sub set to -1).
  Checked 17 Forever tooltips (Wowhead XML) against the rules by hand: all as intended.
- Migration: `UI.MergeBuffButtons` (Init, once, `db.buffsMerged`): per character in enabledBy
  new key = old scroll or elixir key on (false if one was off and neither on), old keys
  removed; popDir moved; manual learned sets scroll_/elixir_ -> buff_. `UI.RemoveScrollMacros`
  (the 3 s after PLAYER_ENTERING_WORLD step, once, `db.scrollMacrosGone`, not in combat, not
  while GetNumMacros() is 0): deletes the macros named "<Stat> Scroll" / "No <Abbr> Scroll"
  whose body has #showtooltip or /amac empty.

## 0.91.0
- 0.90.0 **confirmed in retail**: bars at the top, bottom, left and right all open the right way.
- Lewis: Direction list only for buttons that are on. `UI.EnabledButtons()`;
  `UI.DirectionItems` lists those (a note when none). Pages are built once, so PAGES entries
  may have `stamp = fn`: UI.ShowPanel rebuilds the page on a fresh scroll child (old content
  hidden) when the stamp differs from the one it was built with. Popout's stamp =
  `UI.DirectionStamp` (enabled keys joined).

## 0.90.0 — popout directions; "flyout" is now "popout"
- Lewis: **call it "popout", not "flyout"** in everything players see (page "Popout",
  "Popout on hover", "Popout indicator", `/amac popout` + old `/amac flyout`, messages). Code
  names (flyout, LayoutFlyout, StyleFlyout, noFlyout, flyoutArt, HEADERS.flyout,
  AutoMacrosFlyout) and saved keys are unchanged.
- Lewis: each button configurable, and smart by default. `POPOUT` table (top-level, 191/200),
  after `buttons`: `DIRS` (auto/up/down/left/right), `Rect(b)` (centre/size in screen px),
  `Auto(b)`: visible action buttons straight above/below within 1.8 heights and none beside =
  column -> right on the left half, left on the right half; row (beside, none above/below) ->
  up in the lower half, down in the upper; otherwise (grid, lone) away from the nearest screen
  edge (`AWAY`). `Direction(b, m)` = `db.popDir[m.key]` (account-wide; nil = auto) or Auto.
- OpenFlyout sets `flyout.dir`; LayoutFlyout(f, list, n, button, arrow, dir): column for
  up/down, row for left/right; reversed (down/left) so item 1 is nearest the button; anchored
  on that side, centred, `away` = tab overhang + the art inset on the facing side.
- StyleArrow uses `a.dir` (RefreshArrows sets it, restyles on change): tab on that edge,
  upright for left/right, length capped by the button's height there.
- Dividers(…, across): row popouts copy from `HorizontalDividersPool` (**unverified** that this
  pool holds the side-by-side dividers; none = no dividers), kept in `f.dividersAcross`; the
  other orientation's copies are hidden.
- Settings: Popout page section "Direction" (`UI.DirectionItems`: note + a choice per
  available button). Section `items` may now be a function (BuildPage; LocItems skips it);
  choice items may bring their own get/set (UI.NativeCfg). The settings demo stays "up".
- Roadmap item "Flyout direction" done (untested).

## 0.89.3 — GetActionInfo's macro number is not the macro index
- 0.89.2 did not fix Lewis's bug. `/amac debug` in retail showed the real cause: action slot 7
  "holds macro 6 named Bandage", but Bandage is macro index 2 and Water is index 6. Retail's
  GetActionInfo(slot) for a macro returns a number that is **not** the GetMacroInfo index
  (his six: 6..11 in another order vs indexes 1..6 alphabetical). MacroOnButton looked it up
  in macroAt (index -> category) first, so 6 hit Water.
- Fix: MacroOnButton matches GetActionText(slot) (macro name; works with our label hiding)
  against GetMacroInfo(idx) of our macros; macroAt[id] only when the client gives no name.
  Everything (flyout, tabs, highlight, empty tooltip, label hiding) goes through it.
- `/amac debug` is the tool for this: per action button kind/id/name/"ours", per category its
  remembered slot and "on a bar Nx".
- **Confirmed in retail** (Lewis's /amac debug after the fix): every bar button matches its
  own category, each "on a bar 1x".

## 0.89.2 — macro slots move
- 0.89.1 confirmed in retail: 1711 -> scroll_stamina, 27499 -> scroll_intellect,
  2458 -> elixir_stamina. Hearth/drinks/food on Steinstien right.
- Bug (Lewis's screenshot): hovering Bandage opened Water's flyout, Bandage had Water's tab.
  **Retail keeps macros sorted by name**, so CreateMacro / EditMacro renames ("Water" <->
  "No Water") / DeleteMacro move *other* macros' indexes. Apply only re-remembered the macro it
  touched; SetEmpty built `macroAt` (index -> category, used by MacroOnButton) from the stale
  saved slots, so a stale Water index pointed at the Bandage macro.
- Fix: FindMacro's remembered slot also needs the macro's name to be one of the category's
  (title/empty/name/oldNames), not just BodyMatches; SetEmpty uses FindMacro + Remember for
  every macro at the end of each update. Never trust a saved macro index without the name.

## 0.89.1
- 0.89.0 per-character on/off works in retail (enabledBy has both characters). Steinstien got
  all buttons on: the old account-wide list was all-on when 0.89.0 migrated it.
- Rule misses found in retail: Scroll of Stamina II (1711), Scroll of Intellect V (27499) are
  class 0 **sub 8** (Other) on retail, sub 4 on Forever (Wowhead forever XML) -> scroll rule
  also takes sub 8 when a stat matched. Elixir of Minor Fortitude (2458, sub 2): "maximum
  health" on both clients -> counts as Stamina (elixir_stamina). CLASSIFIER 5.

## 0.89.0 — on/off per character, "in bags" indicator
- Lewis: on/off per character. `OnOff()` (top-level, like Picks/MacroSlots) =
  `db.enabledBy[CharKey()]`. Migration: old account-wide `db.enabled` copied to every char
  known from `idx`/`picks` (+ current), then `db.enabled = nil`. Enabled, AutoEnable,
  UI.SetEnabled use OnOff.
- General-tab (shared) macros: the toDelete loop skips DeleteManaged while another character's
  enabledBy has the key on (prints that). Character-tab macros and removed custom categories
  delete as before. AutoEnable's "macro already made" switch-on now only for character-scope
  macros (a new char no longer inherits every shared button).
- Lewis: show on the options page which off buttons you carry items for. `Stocked(e, have)`
  (count; AutoEnable uses it too) + `UI.CouldUse(e)` (0 when on) using `report.have` (last
  scan, set in UpdateCore). Icon strip: green NumberFontNormal count bottom-right
  (SetIgnoreParentAlpha, the icon is at 0.5 when off) + tooltip line; checkbox labels (Blizzard
  path) "(n in bags)" in `UI.HAVE_COLOR`, refreshed. EUI's TripleRow labels are static: no
  count there. `report.afterUpdate` (set next to StyleOptions) refreshes visible pages after
  every Update. Top-level locals 190/200.

## 0.88.2
- 0.88.1 confirmed in retail (Lewis, new character, bought food/water): Hearthstone -> travel,
  vanilla drinks -> water, breads/cheese/kimchi -> food, flyouts updated by themselves; no
  consumable left in `ignored` with a bare sig. Gumweed 82392 (novelty, "random effect")
  correctly fits nothing.
- Fix: Classify's well-fed branch returned no sig, so buff food was re-sorted every session.
- Wowhead's retail XML (`https://www.wowhead.com/item=<id>&xml`) is handy for identifying an
  item ID from SavedVariables (name, class/subclass, tooltip).

## 0.88.1 — half-loaded tooltips
- First Midnight run of 0.88.0: Hearthstone (6948), Ice Cold Milk, Melon Juice, Sweet Nectar,
  Mulgore Spice Bread, Homemade Cherry Pie were saved in `ignored` with the bare sig
  (class*1000+sub, e.g. 5 / 15000) = **no "Use:" line seen**. Every item that showed a Use line
  was sorted right. Cause (inferred): retail delivers the item before its spell text, so the
  scan tooltip had no Use line. Likely also behind many 0.85.0 retail audit misses.
- Classify: no Use line but `GetItemSpell` (C_Item or global) gives a spellID -> return nil
  (no data yet) after `C_Spell.RequestLoadSpellData`. LearnNew returns `waiting` (nil
  results under 20 tries, or budget used up) -> `report.learnWaiting`; Update re-runs itself
  1 s later while waiting (`report.learnRetry` guard). CLASSIFIER 4 redoes saved results.
- Reading the bare-sig pattern in SavedVariables (`ignored[id].sig == class*1000+sub`) is a
  quick way to spot items sorted without their Use text.

## 0.88.0 — every current client
- Lewis wants Midnight (retail), MoP Classic, Classic Era/Hardcore/SoD and TBC Anniversary
  besides Forever. Wrath/Cata Classic are no longer separate live clients (progressed to MoP).
- .toc `## Interface: 16001, 11509, 20506, 50504, 120105` (Era 1.15.9, TBC Anniv 2.5.6,
  MoP 5.5.4, retail 12.1.5; numbers from the Warcraft Wiki TOC table / addon PRs, **confirm
  with `/dump select(4, GetBuildInfo())` on each client**).
- TRAVEL_SPELLS / new PORTAL_SPELLS hold every expansion's teleports/portals; KnownSpells
  filters to known ones, so listing extras is harmless. **Spell IDs after vanilla are from
  memory, unverified** (a wrong one just never shows). PORTAL_SPELLS[1] (Stormwind) is the
  button's icon.
- HS_RANK: Master Healthstone 22103-22105 = rank 6 (TBC), Demonic Healthstone 224464 = rank 1
  (retail); CREATE_HS starts with 27230 (Master, TBC). IDs from memory, unverified.

## 0.87.0 — no built-in lists
- Lewis: the lists aren't needed; learn items dynamically and keep the result in
  SavedVariables (already how `learned`/`ignored` work). All DATA lists, LEARNABLE,
  InBuiltInList, `/amac audit` (UI.Audit, UI.AuditWhy), `learnOff` (toggle + `/amac learn`)
  removed; Init clears `db.audit` and `db.learnOff`. `DATA` remains only for custom
  categories (`/amac custom`). HEARTHSTONE, TRAVEL_SPELLS, HS_RANK, CREATE_HS unchanged.
  The vanilla lists (338 items) are kept in `previous/0.86.0/` for testing the rules.

## 0.86.0 — vanilla only
- Lewis: **only Classic/Forever (vanilla) items matter, not retail.** DATA and TRAVEL_SPELLS
  cut to vanilla (picked per item, not a plain ID cutoff: TBC starts ~22800 among late-vanilla
  Naxx/holiday items; SoD 2xxxxx gone too). 671 -> 338 listed items.
- Retail audit (0.85.0, build 12.1.5): only bandage fully learned; misses were mostly the
  vanilla items, likely because retail files old consumables differently (unverified).
- Anti-venom rule: "Use:" line with poison + cure/remove -> antivenom (class 0 only, before
  the subclass rules). CLASSIFIER 3.
- Audit saves `audit.why[id]` = "class.sub | name | Use:/well fed lines" for every miss
  (`UI.AuditWhy`).

## 0.85.0 — lighter: learning first, bar watcher only when needed
- Lewis wants the addon very lightweight and asked whether the built-in item lists are needed
  at all. Plan: trim the lists to what learning gets wrong, **from audit data, not guesses**.
- `/amac audit` (`UI.Audit`): runs `Classify` on every built-in list item (20 per 0.1 s,
  no-data items retried up to 6 rounds), prints per list "right / not / no data", saves
  `AutoMacrosDB.audit` (build, per set: right, miss, extra, nodata ids). After Lewis runs it
  (retail, later Forever) + /reload, read the SavedVariables file and trim DATA accordingly.
  Known gap: **anti-venom has no learning rule**, so it will show all misses.
- Learn once, re-check on change: `Classify` returns `sets, sig` (sig = hash of class, sub
  and the "Use:"/"well fed" lines with digits dropped). `learned[id].sig`, auto ignores are
  `ignored[id] = { sig }`, manual unassign is `ignored[id] = "manual"`. Once per session, the
  first time an item is in bags, its sig is recomputed; only a different sig re-sorts it
  (prints only if the result changed). Pre-0.85 numeric ignores count as automatic.
  A CLASSIFIER bump now keeps manual ignores.
- Bar watcher: no longer compares all buttons every second. Polls `GetCursorInfo` every
  0.25 s; while something is on the cursor and 3 s after, `BarChanged()` compares kind/id/text
  per button (flat `barSeen` array, no strings built) twice a second.
- SavedVariables are account-wide (all characters and realms): `WTF\Account\<acct>\SavedVariables\AutoMacros.lua`.

## 0.84.0
- Lewis zoomed in on 0.83.0: the bottom-right cut corner was a pixel off (antialiased
  CreateLine diagonals land between pixels). CutBorder now draws each cut corner as a pixel
  staircase like Blizzard's art: the cut rounded to n whole pixels, one `size x size` solid
  square per pixel along the diagonal (`g.cells`, cells (x, n-1-x) from each corner, grown
  inward). No more Lines. (Overlapping squares look a bit stronger at opacity < 1.)

## 0.83.0
- 0.82.0's border (anchored to the NormalTexture) came out far too big (Lewis's GIF): the
  template's NormalTexture is larger than the visible frame. **Don't size from texture regions.**
  The retail solid border anchors to the button again, inset by one art pixel
  (`width * 46/45 / 88`, at least 1 screen px), corners cut 8 art pixels more, snapped.
  Corners were crisp in 0.82.0, so CutBorder itself is fine.

## 0.82.0
- 1px solid border looked wonky: it sat just outside Blizzard's grey frame ring. Measured the
  frame piece (`tools/blp_row.py`): the grey ring is 3 px wide starting 1 px in from the
  piece's edge (of 88), corners cut 9 px back. The retail solid border now anchors to the
  button's **NormalTexture** (frame image, 46 wide on a 45 button) inset by 1/88 of its width,
  corners cut 8/88 from there, all `Snap`ped to whole pixels; `CutBorder(g, cut, size, c)`.
- Highlight thickness max 5 (clamped in StyleGlow too); soft glow crop step 0.035 per step.

## 0.81.0
- Lewis's video of 0.80.0 (frames pulled with ShareX's ffmpeg, `C:\Program Files\ShareX\ffmpeg.exe`):
  the stacked IconFrame-Border outline is itself soft, so "solid" was blurry and filled the icon;
  the soft glow's shape mask was sized before layout and showed a stray box. Both removed.
- Solid border on retail's buttons: `BLIZZ_ART.CutBorder(g, b, size, c)` = 4 edges stopping
  `CORNER * width` short of each corner + 4 `CreateLine` lines across the cut corners, shifted
  half their thickness inward, so it is crisp, in the button's shape, and thickens inward.
  Clients without CreateLine (or square buttons) get the plain 4-edge border.
- Soft glow on Blizzard's buttons: the item-border glow unmasked (its ring is already rounded).

## 0.80.0 — highlight in Blizzard's shapes
- Soft glow on Blizzard's buttons is Blizzard's item-border glow again (`BLIZZ_ART.GLOW` =
  UI-ActionButton-Border, ADD), inside the button: thickness = texcoord crop
  `0.21 - (t-1)*0.015` (estimate, art not measured); opacity scales the RGB (ADD ignores alpha
  in practice); retail: clipped by `BLIZZ_ART.ShapeMask(g, tex, on)` = a MaskTexture with atlas
  UI-HUD-ActionBar-IconFrame-Mask sized like ActionButton1.IconMask vs its button (the mask art
  has padding, cf. 0.52's shrunk icons). EUI square look keeps the gradient fade-in.
- Solid border on retail's buttons: the outline atlas UI-HUD-ActionBar-IconFrame-Border
  (equipped-item border), desaturated + tinted, drawn `thickness` times each 1 px further in
  (`g.rings`) so it has the button's cut corners. Square buttons keep the 4-edge border.

## 0.79.0
- General: "Empty tooltip color" renamed **Tooltip text color**.
- Lewis reminder: **treat EllesmereUI as not installed** when designing/answering; the
  Blizzard look is what matters.

## 0.78.0 — Highlight page
- "Pulse [x]  Pulse time <slider>" is one row (row type).
- Soft glow is the gradient fade-in from the edges (FadeEdge) on **both looks**, so thickness
  (depth = thickness x3 px) and opacity work with Blizzard's look too; the old
  UI-ActionButton-Border glow texture (`g.soft`, TEXTURES path) is gone.
- The solid border stays **inside** the button and thickens inward (no outward offset; the
  0.37.0 "1px tighter" rule is obsolete). Thickness max 12 (was 8).

## 0.77.0
- Our options pages show their scroll bar only when the settings don't fit: `UI.MakeScroll`
  sets `scrollBarHideIfUnscrollable` (retail) and `scrollBarHideable` (older) on the scroll
  frame; `UI.FitScroll(pn)` also hides/shows `scroll.ScrollBar` after a page is shown (and a
  frame later, once sizes are known).

## 0.76.0
- Flyout page: the preview's hint is a note across the bottom of the page under both columns
  (MakePanel side layout; text `UI.FLYOUT_NOTE`), the preview column ends above it, and the
  flyout header hides its own hint when its host has `noteBelow`. Columns now
  `UI.SIDE_W` 120 / `UI.LEFT_W` 480.

## 0.75.0
- Settings values line up in one column: `RowLayout(parent)` (top-level local, 188/200) gives
  dropW (color mode dropdown), shortX/shortW (opacity sliders and the row type's Close delay
  slider, same place and width) and fullW = shortX + shortW (Width, Height, Item size, Item
  spacing run from the control column to where the short sliders end). Used by MakeColor,
  BuildPage's range and row branches.
- Item spacing is now below Show background.

## 0.74.0
- Selected border has an opacity slider; with Blizzard's look it is the checked texture's
  vertex alpha, on Default too.
- Items section order: Hover, Selected border, (Selected border size, EUI), Item size, Item
  spacing, Show background (last). Item spacing is always shown and **greyed out** while the
  bar background is on: range items may have `disabled = fn`; BuildPage adds a refresher that
  calls `UI.SetWidgetEnabled(widget, label, on)` (SetEnabled / Enable+Disable, mouse off, alpha
  0.5, label GameFontDisable). The toggle no longer rebuilds pages; `UI.RebuildPages` removed.

## 0.73.0
- Dropdown "Class color" -> "Class"; Items "Hover color" -> "Hover" (the word color was
  redundant, Lewis).
- Hover has an **opacity slider** again, applied in every mode: `ApplyHover` multiplies the
  EUI hover's alpha by it (tint only off Default), Blizzard look passes `o.hoverAlpha` to the
  template HighlightTexture's vertex alpha (and the no-template fallback). Default opacity of
  `entryHover` is now 1 (was 0.35).
- "Show background" moved into Items (`when = UI.BlizzLook`); the Popup section is gone (the
  whole page is the popup).

## 0.72.0
- New color mode **Class color** (`class` in COLOR_MODES, after Custom) for every color
  setting: the logged-in character's class color (`C_ClassColor.GetClassColor`, else
  `RAID_CLASS_COLORS`), opacity from the setting as for the other modes. Anything that
  checks `ColorMode(key) ~= "default"` (hover tint, selected tint) treats it like Custom.

## 0.71.0
- Measured Blizzard's button corners from the art Lewis exported (`uiactionbar2x.blp`, retail,
  512x2048 raw BGRA BLP2): the icon frame pieces are 88x88 with **45° cut corners**; the
  straight top edge starts 9 px in from each side. Frame drawn 46 wide on a 45 button, so
  `BLIZZ_ART.CORNER = (9/88) * (46/45)` (~10.4%; the 0.70.0 guess was 5/45).
- `tools/blp_to_png.py` (raw BGRA BLP2 -> PNG, optional crop/zoom, `--alpha`) and
  `tools/blp_edges.py` (bounding box + per-row opaque run of a piece) for checking Blizzard art.
  Run downloaded files from their own folder with `python -I`.
- Reference for Blizzard's button layout: Blizzard UI source mirror github.com/Gethe/wow-ui-source
  (ActionButtonTemplate, Blizzard_ActionBar/Mainline/MainActionBar.xml); in game
  `C_Texture.GetAtlasInfo(atlas)` and `/tinspect`.

## 0.70.0
- Flyout indicator height: 1..5 screen px (Lewis: more looks clunky); default 3 (was 7); a saved
  higher value draws at 5 (`BLIZZ_ART.TabHeight()`, used by StyleArrow, LayoutFlyout, demo).
- Width on Blizzard's rounded buttons (retail: ActionButton1 has IconMask, no EUI look —
  `BLIZZ_ART.Rounded()`): capped at the straight top edge, button width x (1 - 2 x
  `BLIZZ_ART.CORNER`), CORNER = 5/45 (**a guess** at the corner size, tune if needed). Both the
  slider max (`UI.TabMaxWidth`) and StyleArrow's clamp use it, so it follows button size/scale.
- `StyleArrow` moved below EUIButtonLook/BLIZZ_ART (it needs them).

## 0.69.0
- Settings widgets line up with their labels: the Blizzard-template ones (checkbox, both
  sliders, both dropdowns, color swatch) anchor `"LEFT", parent, "TOPLEFT", x, y - 8` (middle
  of a label set at y - 2). Color mode dropdowns narrower (100, 90 on a narrow page).
- **Item size is a percentage** (`itemScale`, default 100, 50..200 step 10, shown "100%"),
  like Edit Mode's Icon Size: `BLIZZ_ART.ItemSize(f)` = stock button size (the template's own
  size, `BLIZZ_ART.native`, set by the first ItemButton; 36 before) x percent; with the EUI
  look, of the EUI bar's button size. The old `itemSize` key, its function default and
  `UI.MaxItemSize` are gone. `UI.ButtonSize` is now `BLIZZ_ART.BarButtonSize` (defined after
  `buttons`). MakeSlider takes an optional `fmt`; range items may set `fmt`.

## 0.68.0
- Flyout page: preview in a **right-hand column**, settings in the wider left column (Lewis).
  PAGES entry `previewSide = "right"`; `UI.SIDE_W` 180 / `UI.LEFT_W` 420. The column host runs
  the page's full height (`fixedH` = its height, set in ShowPanel). The settings content gets
  `amNarrow`: BuildPage puts controls at x0+170 (not 240), the row type and MakeColor go more
  compact (dropdown 110, opacity 60). The flyout preview's hint wraps to the strip width and
  the sample button sits above it (`base` = hint height). Text items size to the content width.

## 0.67.0 — tabs in the options tree
- Lewis: the tab row under the title wastes space; put the tabs in the options tree under
  AutoMacros. Now one canvas page per PAGES entry (`UI.MakePanel(i)`, `UI.panels[i]` =
  { frame, host, scroll, content, built }): AutoMacros itself = the Buttons page, Highlight /
  Flyout / General are `Settings.RegisterCanvasLayoutSubcategory` children (old clients:
  `panel.parent = "AutoMacros"` + InterfaceOptions_AddCategory). Tabs, `optionsPanel`,
  `UI.BuildOptions`, `UI.ShowTab` are gone; `UI.ShowPanel(i)` builds a page on its OnShow,
  `UI.RefreshPanels()` refreshes visible ones.
- Lewis: changing a setting resized the preview and threw the whole window around. The preview
  host on these pages has a fixed height (`previewH` in PAGES: buttons 140, glow 120, flyout
  260); `UI.FitHeader(f)` shrinks a taller preview (SetScale) to fit, centred at the top.
  EllesmereUI's page is unchanged (its host has no fixedH).

## 0.66.0 — settings page tidy-up (Blizzard look)
- Lewis confirmed in retail: popup dividers scale with Item size (0.64.0), empty-button
  message prints as red text only (0.65.0).
- Styled after Blizzard's own options pages (his reference: Options > Controls): section
  headings are large white text with **no divider art** (the Options_HorizontalDivider was too
  thick); labels gold (`MakeLabel` = GameFontNormal), indented 30 (`lx`), controls in one column
  at x0+240 (`ctlX`); ROW 36. Color rows narrower (dropdown 130, swatch, opacity 80).
- New settings item type **`row`** = a toggle and a slider side by side
  ("Label [x]   Label <slider>"); the EUI page flattens it into its usual pair. Behaviour is now
  one row: "Flyout on hover [x]  Close delay <slider>".

## 0.65.0
- Empty buttons no longer /say their message (Lewis: only the player should see it). The macro
  body is now `/amac empty No <label> in inventory.`; the slash handler catches `empty <text>`
  before lower-casing and prints the text alone in "Empty tooltip color". Not `/run`, which
  retail gates behind its script permission. BodyMatches still finds "No <label>", and existing
  macros are rewritten on the next update (body differs).

## 0.64.0
- 0.63.0 dividers work in retail. With a smaller Item size the bar art stayed full size.
  `BLIZZ_ART.ArtScale(f)` = item size / main bar button size (in f's units). The popup art now
  sits on its own frame `f.art` (+ `f.art.tex`; `f.bg`/`f.edges` are gone), `SetScale(ArtScale)`
  with the inset offsets in its own units; dividers scale by it too, as do the gap between
  items, the popup's lift above the button and the settings demo's height — like Edit Mode's
  Icon Size scaling a whole bar.

## 0.63.0
- `/amac art` in retail (main bar vertical, art on) showed: `MainActionBar.VerticalDividersPool`
  active=11 (one per gap between 12 stacked buttons), `HorizontalDividersPool` active=0, pools
  have **no template name** (`frameTemplate` nil). A divider is a three-slice frame:
  `.Center` atlas `UI-HUD-ActionBar-Frame-Divider-ThreeSlice-Center` (12x16) plus edge pieces.
  Bar art: `MainActionBar.BorderArt` atlas `UI-HUD-ActionBar-Frame` (57x573 on a vertical bar),
  `EndCaps` = Gryphon-Left/Right. ActionButton1 parts: NormalTexture `UI-HUD-ActionBar-IconFrame`
  46x45, SlotBackground `UI-HUD-ActionBar-IconFrame-Background`, Checked/Highlight
  `...-IconFrame-Mouseover`, PushedTexture `...-IconFrame-Down`.
- Popup dividers: `BLIZZ_ART.DividerSource()` takes a frame from VerticalDividersPool (active,
  else a spare via EnumerateInactive); `BLIZZ_ART.Clone(src, dst)` copies its textures (atlas,
  layer, color, size, anchors incl. to each other); `BLIZZ_ART.Dividers` puts a copy in each gap
  at the source's scale (`SetScale(k)`, offsets / k). A spare (not laid out) is sized item-wide
  by its tallest piece. Old BottomDivider code removed.

## 0.62.0
- Lewis's /fstack (retail, bar art on): the main bar's divider is an **unnamed child frame of
  MainActionBar** (`MainActionBar.<hex>`, with a `.RightEdge` piece), i.e. pooled from a
  template, not a texture on the buttons. Also seen: `MainActionBar.BorderArt`,
  `MainActionBar.EndCaps` (LeftEndCap/RightEndCap), source
  `Interface/AddOns/Blizzard_ActionBar/Mainline/MainActionBar.xml`.
- `/amac art` now also lists frame pools on the main bar (key, `frameTemplate`, type, active
  count) and up to 4 unnamed non-button child frames with their texture pieces. Plan: create
  the popup's dividers from that same template once its name is known.

## 0.61.0
- Popup dividers still missing in retail (vertical main bar shows them), so ActionButton1
  `BottomDivider` is the wrong name/atlas. Blizzard's interface code is not on this machine and no
  installed addon names these parts. Added read-only `/amac art`: prints every texture on
  ActionButton1, ActionButton2 and the main bar whose key or atlas mentions divider/art/frame
  (key, atlas, file, size, shown). Waiting on Lewis's output to pick the right divider.

## 0.60.0
- With the bar background on, Item spacing is not used (Lewis: it only messes up the art):
  the gap between items is the main bar's own (`BLIZZ_ART.BarGap(f)`, ActionButton1 to 2,
  0 if unreadable) and the slider is hidden (`when`). "Show background" calls
  `UI.RebuildPages()`: built Blizzard pages get a fresh scroll child and the visible one is
  rebuilt (EUI page: RefreshPage(true)).

## 0.59.0
- Lewis: Blizzard's main bar can itself be vertical in Edit Mode (stacked buttons with their
  own dividers). So the divider is only ActionButton1's **BottomDivider** (the stacked-button
  one); the turned-RightDivider fallback from 0.58.0 is gone. No BottomDivider = no dividers.

## 0.58.0
- 0.57.0 popup art "much closer"; Lewis: missing the art between buttons that the main bar has.
  `BLIZZ_ART.Divider(f)` reads ActionButton1's BottomDivider (or RightDivider, turned 90°:
  sized thickness x length before SetRotation, **unverified**) atlas and size;
  `BLIZZ_ART.Dividers(f, on, n, size, gap, pad)` (called from LayoutFlyout) draws one centred
  in each gap between stacked items, on `f.dividerLayer` (frame level +10, above the items).
  Hidden when the background is off or with the EUI look.

## 0.57.0
- Popup bar art (0.56.0, BorderArt works in retail) had too much room around the items.
  Now the items touch the popup's edges (pad 0 with the art on, spacing only between items)
  and the art is anchored *outside* the popup by `BLIZZ_ART.BarInsets(f)`: how far the main
  bar's BorderArt reaches past ActionButton1-12 on each side, read from the live bar (4 each
  if unreadable, clamped 0..30). The popup moves up by the bottom inset; the settings demo's
  height allows for it.

## 0.56.0
- Mode dropdowns just say **Default** again (the `defaultLabel` mechanism is gone).
- Hover color and Selected border have no opacity slider (it did nothing).
- **Item border removed for good** (Lewis: never changed with the Blizzard UI): settings,
  `entryBorderColor/Size`, `o.border` path.
- **Popup:** Background / Border / Border size removed (border did nothing). New `flyoutArt`
  toggle "Show background" (section shown only with the Blizzard look; sections can now have
  `when`, filtered in `UI.PageSections`). On = the main action bar's frame art
  (`BLIZZ_ART.BarArt`: MainActionBar/MainMenuBar .BorderArt atlas + its texture slice margins),
  plain dark backing on a client without it; items get 6 units extra padding for it. EUI look:
  popup see-through as before. **Unverified in game** whether BorderArt is the right art or is
  sliced (may stretch).

## 0.55.0
- Selected item, Blizzard look: Lewis wants it the same as the **pet bar's active glow** (same
  idea). That glow is the checked texture, so Selected border on Default ("Pet bar selected"
  in the dropdown) now shows the CheckedTexture untouched; only Accent/Custom desaturate and
  tint it (`o.selTint`). Lewis's saved mode is custom (green): he must pick Default to match.
  Selected border size is hidden under the Blizzard look (the checked art has a fixed width).

## 0.54.0 — Blizzard first
- Lewis: **develop for the Blizzard UI first, as if EllesmereUI did not exist; EUI changes only
  when EUI is installed. No resizing shenanigans.** The 0.51-0.53 copy-and-measure code
  (BLIZZ_ART.Live/LiveFrame/Copy/Put/Fit/Place, our own icon mask) is gone.
- `ItemButton(parent)` (popup items, settings demo items) and `UI.SampleButton` (previews) are
  made from Blizzard's **ActionButtonTemplate** (CheckButton; `b.native` = its size), falling
  back to a plain Button. With Blizzard's look the template's own art shows untouched: frame,
  IconMask, SlotBackground, hover, pushed. Size changes by **scale** (`BLIZZ_ART.Size`, like
  Edit Mode's Icon Size); positions go through `BLIZZ_ART.Point` (offsets / scale). Under the
  EUI look the template art is hidden (alpha 0, mask removed), scale 1, and our ButtonArt parts
  draw as before.
- Sizes are given via `o.size` / `b.want` to StyleButtonArt (StyleEntry uses
  `BarUnits(e:GetParent(), itemSize)`); item border thickness is now `o.borderSize`.
- Custom hover color with Blizzard's look: the template's HighlightTexture desaturated + tinted.
- **Selected item** (Lewis: square border looked messy): with Blizzard's look it is the
  template's **CheckedTexture**, desaturated and tinted with Selected border color, so it has
  the button's own shape (PostClick keeps checked = `amChecked`). EUI look keeps the square
  border; Selected border size only applies there.

## 0.53.0
- Lewis: the Blizzard options page appears properly in AddOns (0.52.0 panel confirmed in retail).
- Popup items had a dark inner padding: the retail IconMask was stretched over our whole icon,
  but on Blizzard's button it has its own size/place. `BLIZZ_ART.Copy(t, b)` now also records
  each region's size and centre offset as fractions of ActionButton1 (`rw, rh, ox, oy`);
  `BLIZZ_ART.Fit` / `Place` put frame, mask, slot background, hover and pushed textures the
  same way on our buttons (whole button when nothing could be measured).

## 0.52.0 — works and looks stock without EllesmereUI
- Lewis: everything must work standalone and match the stock Blizzard UI when EllesmereUI is
  not installed. He chose **Blizzard's AddOns panel** for the settings.
- The home-made stand-alone window is gone. `UI.BuildOptions()` builds a canvas page (title,
  `PanelTopTabButtonTemplate` tabs, preview strip, a `ScrollFrameTemplate` /
  `UIPanelScrollFrameTemplate` per tab); `UI.RegisterBlizzPanel()` (at PLAYER_LOGIN) adds it via
  `Settings.RegisterCanvasLayoutCategory` + `RegisterAddOnCategory`, or `InterfaceOptions_AddCategory`
  on old clients. `/amac options` opens EUI's page when installed, else Esc > Options > AddOns >
  AutoMacros (`Settings.OpenToCategory(cat:GetID())`); `/amac options blizzard` forces the
  Blizzard page.
- Widgets try Blizzard templates first, then fall back to the old home-made ones (`Template()`
  = pcall'd CreateFrame): UICheckButtonTemplate; MinimalSliderWithSteppersTemplate (Init +
  RegisterCallback OnValueChanged, `quiet` guard so refresh does not save) then
  OptionsSliderTemplate; WowStyle1DropdownTemplate (`SetupMenu`/`CreateRadio`) then
  UIDropDownMenuTemplate; UIPanelButtonTemplate; color swatch = ChatFrameColorSwatch. Section
  headings: GameFontHighlightLarge + `Options_HorizontalDivider` atlas. ROW is 32.
  **None of these templates has been checked on the Forever client** — fallbacks cover misses.
- Blizzard look for popup items and previews copies ActionButton1's NormalTexture (frame,
  size ratio), IconMask (rounded corners, via a MaskTexture on our icon) and SlotBackground:
  `BLIZZ_ART.LiveFrame()`, `BLIZZ_ART.Copy`, `BLIZZ_ART.Put`; classic falls back to UI-Quickslot2.

## 0.51.0
- Lewis tests the **Blizzard look with EllesmereUI disabled**, so check which look is active
  before blaming EUI code. His 0.50.0 screenshot was the Blizzard path: Custom hover was a flat
  fill, and the hover file was classic's ButtonHilight-Square, not retail's.
- `BLIZZ_ART.Live("Highlight"|"Pushed")` copies the texture (atlas on retail, file on classic)
  and blend mode from `ActionButton1`'s own Highlight/Pushed texture, falling back to the
  BLIZZ_ART files. A Custom/Accent hover color recolors that texture (desaturated first, spec
  field `desat`), no longer a flat fill. `PaintInteraction` handles `spec.atlas` and `desat`.

## 0.50.0
- Item hover looked like a flat wash instead of the bars' glow: EUI's highlight PNGs
  (Media\highlight-2..4.png) were drawn with BLEND. A button's HighlightTexture is ADD
  (ActionButtonTemplate), so `EUIButtonLook` now sets `blend = "ADD"` on the hover spec for
  types 1-3; the pushed texture stays BLEND (as EUI's PushedTexture).
- Checked in retail: EUI's profile is read fine (`Lite.GetAddon` works). Lewis's EUI profile:
  `highlightTextureType = 1`, `highlightUseClassColor = true`. His AutoMacros `entryHoverMode` is
  "custom", so items use his custom color until he picks "Action bar hover".

## 0.49.0
- Lewis: **the flyout indicator has nothing to do with hover**, it only shows that a button has
  a flyout. 0.48.0's indicator hover (tabHoverColor, LightArrow) is gone; `StyleArrow(a)`
  draws only `tabColor`.
- One **Hover color** setting (`entryHover`, Items section) for the hover on everything we draw
  like an action button: popup items (real + demo) and the settings preview buttons
  (`UI.StyleSample`). `ApplyHover(o)` puts it into StyleButtonArt's options. Mode Default is
  shown as "Action bar hover" = the bars' own hover as it is (EUI Bar Animations, or Blizzard's
  ButtonHilight-Square); Accent/Custom = the same kind of hover in that color (Blizzard look:
  a flat fill). `STYLE_DEFAULTS.entryHover` is a function (EUI hover color, else pale yellow
  {1, 0.93, 0.6}, alpha 0.35) so the swatch shows the real default.
- The real action bar buttons' own hover is not touched (that is EllesmereUI's / Blizzard's).

## 0.48.0
- Flyout indicator **Hover color**: Lewis could never see it change. It only applied while the
  mouse was on the 3px indicator itself. Now `LightArrow(button, on)` lights it while the mouse
  is on the action button or the indicator, or that button's popup is open (flyout OnHide
  and OpenFlyout switching buttons turn it off). The settings demo button lights its indicator too.
- Its Default is the action bars' hover color: EllesmereUI's Bar Animations hover color
  (`EUIButtonLook().hover`), else Blizzard's pale yellow {1, 0.93, 0.6}.
  `STYLE_DEFAULTS.tabHoverColor` is a function (set after EUIButtonLook); `StyleColor` calls
  function defaults. Mode dropdown shows "Action bar hover" for Default under the EUI look.

## 0.47.0
- **Spelling:** shown text is US English ("Color"); `Loc(s)` turns color -> colour only when
  `GetLocale() == "enGB"`. Applied in Print, UI.SmallText, MakeLabel, text items, TEXTURES
  labels, the colorpicker text, and PAGES labels (`UI.LocItems`, once at load). Write new
  shown strings in US spelling; comments in the code are still British.
- **Item hover color** under the EUI look: Default = EllesmereUI's Bar Animations hover exactly
  (kind and color), shown in the mode dropdown as "Action bar hover" (`defaultLabel` on the
  settings item, passed to `ColorModeChoices(defaultLabel)` / `MakeColor`). Accent/Custom keep
  EUI's kind of hover in our color. Without EUI: unchanged (Blizzard art, Custom = flat fill).
  Selected border unchanged.

## 0.46.0
- Lewis: the hover colour "did nothing" and items showed EllesmereUI's Bar Interactions colour.
  Cause: under the EUI look, item hover copied EUI's colour and the item hover setting was
  hidden, so the only visible "Hover colour" was the flyout indicator's.
- Now `StyleEntry` keeps EUI's hover *kind* (tex/fill/edge/none) but paints it in
  `StyleColor("entryHover")` (Default white); opacity applies to fills only. The setting is
  shown under both looks and renamed **Item hover colour**.

## 0.45.0
- Highlight texture choices are only **Solid colour** and **Soft glow** (`TextureChoices(true)`);
  any other saved glowTexture draws as solid. The indicator keeps the full list.
- Soft glow never goes outside the button. Square (EllesmereUI) look: four gradient edges
  (`FadeEdge`, SetGradient+CreateColor, falling back to SetGradientAlpha) inside the button's
  border, colour at the edge fading to clear, depth = thickness x3 screen px (max 45% of the
  button). Blizzard look: the old rounded UI-ActionButton-Border glow, now sized to the button
  with texcoords 0.2-0.8 (untested guess at cropping its padding).
- `StyleGlow` moved below `EUIButtonLook` (it needs it).

## 0.44.0 — cleanup, no intended behaviour change (except as noted)
- Shared helpers instead of copies: `MacroSlots()` (per-character macro slots, like `Picks()`),
  `ItemInstant(id)` (class, sub, icon, type names), `ItemInfo` also returns the link,
  `SpellName` + `KnowsSpell` (used by Healthstone, Comprehend and spell lists),
  `ShowEntryTooltip(owner, id, loc, isSpell)` (was item + spell versions), `ItemButton(parent)`
  (popup items and the settings demo items), `UI.Choices(list)`; BuildPage reuses
  `UI.NativeCfg` get/set. `FindMacro(m, checked)`: checked = name matches must pass BodyMatches
  (AutoEnable uses it). `/amac add|remove` calls `UI.SetEnabled`.
- Placeholder icons all live in CATALOG (`placeholder`); the PLACEHOLDER table is gone.
- Removed: unused `emptyMacro`; `/amac items` probe (ItemClassInfo, TooltipSummary);
  migrations for `db.pick`/`db.scrollPick` and the 0.25.0 `euiAccent` switch (those colours
  now read Default unless a mode was saved); `EMPTY_CLICK` (always the plain message, sent as
  /say) and the empty-body handling (SameBody, " " retries).
- Top-level locals 184/200.

## 0.43.0
- **Units:** EllesmereUI's Icon Size (45) is UI units (UIParent units, snapped with PP.mult),
  not screen pixels; at Lewis's scale 45 units = 54px, which is why 0.41/0.42 showed 54.
  Sizes that go with the button (item size `itemSize`, indicator width `tabWidth`) are now
  UI units via `BarUnits(frame, v)` (UIParent units -> frame units, snapped). Thicknesses
  (borders, spacing, indicator height, padding) stay screen pixels, as in EllesmereUI.
- `UI.ButtonSize()` (was ButtonWidthPx) returns the action button's w, h in UI units,
  allowing for a scaled button. The settings demo button/items/indicator use BarUnits too, so
  they show at true on-screen size whatever EUI's Window Scale is.
- Top-level locals 190/200.

## 0.42.0
- Flyout settings demo button is the size of your action buttons (`UI.ButtonWidthPx()` now
  returns width, height in pixels), not a fixed 40.
- Item size is now **pixels**, new key `itemSize` (old `entrySize` in UI units is gone/ignored).
  Default = action button width: `STYLE_DEFAULTS.itemSize` is a function (set after
  `UI.ButtonWidthPx`), and `Style()` calls function defaults. Slider 16..button width+16
  (`UI.MaxItemPx`), 1px steps.

## 0.41.0
- **Pixel-exact sizes.** `PixelSize(frame)` = one physical pixel in frame units
  (768 / physical height / effective scale); `Snap(frame, v)` rounds to whole pixels.
  `PlaceEdges` thickness is now **screen pixels** (all borders: glow, popup, items, selected,
  EUI look), as are glow offsets, item spacing, popup padding and the flyout indicator's
  width/height. Item size stays in UI units but is snapped. Fixes 1 showing as 1-2px and
  uneven spacing at UI scales below 1.
- `LayoutFlyout(f, list, n, button, arrow)` lays out the real popup and the settings demo
  alike: BOTTOMLEFT anchors on whole pixels, centred over the button above its indicator
  (no "BOTTOM"/centre anchors, which land on half pixels).
- "Tab" settings section renamed **Flyout indicator**; width 0..action button width in pixels
  (`UI.ButtonWidthPx`, measured from the first found action button; EUI's border is inside
  the button). `StyleArrow` clamps to it and places the indicator itself. Slider `max` may be
  a function (`UI.Num`). Only EllesmereUI bars checked so far; Blizzard/other bar addons later.
- Top-level locals 189/200: next big change should be the file split.

## 0.40.0
- EllesmereUI look: hover/pushed textures are inset by the border size (fill the icon, leave
  the border alone, as on EUI's bars). Popup Background and Border on Default are see-through
  under that look (StyleFlyout, now defined after the button-art block), so each item shows its
  own border like a bar button; Custom/Accent still draw.

## 0.39.0
- Popup items are drawn like action buttons, by the same code as the settings demos:
  `ButtonArt(b)` (parts) + `StyleButtonArt(b, o)` (look), top-level locals near StyleEntry.
  - EllesmereUI look (`EUIButtonLook()`, nil = Blizzard): border/zoom/slot bg from
    EllesmereUIActionBars' MainBar, hover + pushed from its Bar Animations settings
    (`highlight|pushed` + `TextureType` 1-3 = its Media\highlight-2..4.png, 4 fill 0.35,
    5 border edges `BorderSize`, 6 none; `CustomColor`, `UseClassColor`).
  - Blizzard look: UI-Quickslot2 frame, ButtonHilight-Square (ADD) hover,
    UI-Quickslot-Depress pushed. Item border / hover colour set away from Default replace the
    frame / hover with flat ones (as before).
  - Selected border is always ours: `selectedColor` + new `selectedSize`.
- Settings items can have `when = fn` (BuildPage skips them while false). Items section hides
  item border / border size / hover colour under the EllesmereUI look and shows a note.
  The "Use EllesmereUI styling" toggle rebuilds the EUI page (`RefreshPage(true)`).
- Top-level locals now 187/200.

## 0.38.0
- Buttons-tab icon strip is draggable: `UI.PickUp(e)` (OnDragStart) switches the button on if
  needed, runs Update so the macro exists, then `PickupMacro(idx)`. Refused in combat.
  Should drop on any bar that takes the cursor (Blizzard, EllesmereUI); untested in the simulator.
- Item buttons are no longer on by default. `Enabled(e)` with no saved choice: custom
  categories and the mage scroll button use `e.default`; everything else is off until
  `AutoEnable(have)` (each UpdateCore, after learning) finds items for it (healthstone: also
  any warlock; travel: any TravelOptions) and saves `enabled[key] = true` for good, so running
  out never removes a button. Migration: a button whose macro already exists (remembered slot
  or name, checked with BodyMatches) is switched on silently. `e.default` on CATALOG entries
  now only matters for comprehend.

## 0.37.0
- Empty-button highlight sits 1px tighter (`StyleGlow`: offset `max(1, t-1) - 1`) so it covers
  the action button's own 1px border (EllesmereUI bars) instead of drawing just outside it.

## 0.36.0
- Item border thickness: `entryBorderSize` (default 2, was a fixed 2px inset); `StyleEntry`
  places the icon inset by it.
- Test popup removed entirely (Lewis: the settings demo replaces it): the "Open a test popup"
  button, `/amac flyout test`, `PREVIEW`/`PreviewFlyout`, `flyout.sticky`. `OpenFlyout` now
  needs a button.
- Items section: Item border | Border size, Selected border | Hover colour, Item size | Item
  spacing (spacing moved from Popup).

## 0.35.0
- Popup background / border / item border colours did nothing with EllesmereUI styling on:
  `skin.Panel` fades the frame's own textures and adds its own outline, and
  `skin.SquareIcon(icon, parent)` draws a black border over the item border. Now the popup
  always draws its own bg + edges (Default background = `skin.GetPanelColor()` when skinned)
  and icons are squared with `skin.SquareIcon(icon)` only (no parent = no border).
- "Chosen item border" renamed "Selected border". Flyout tab split into Behaviour / Tab /
  Popup / Items sections.
- EUI page: colour rows pair up like EllesmereUI's Action Bars page: mode dropdown with an
  inline swatch (`EllesmereUI.BuildColorSwatch` placed left of `region._control`,
  `UI.InlineSwatch`). The swatch shows the colour drawn now; picking sets Custom. Without
  BuildColorSwatch, colours fall back to the old full-width DualRow.

## 0.34.0
- Preview buttons (Buttons strip, Highlight samples, Flyout sample) are drawn like action
  buttons: `UI.SampleButton` + `UI.StyleSample`, re-styled on every header refresh.
  EllesmereUI look when EllesmereUI is loaded and our `euiSkin` style is on: slot background,
  icon zoom, border colour/thickness read from EllesmereUIActionBars' profile
  (`EllesmereUI.Lite.GetAddon("EllesmereUIActionBars", true).db.profile`, bar `MainBar`;
  defaults when that module is missing). Blizzard art (UI-Quickslot2, ButtonHilight-Square)
  without EllesmereUI, or when its action bars use the Blizzard/classic style.

## 0.33.0
- EllesmereUI preview strips actually show now: EUI never calls `getHeaderBuilder` on a first
  build, its own pages call `EllesmereUI:SetContentHeader(builder)` from inside `buildPage`
  (see EUI_CooldownManager_Options.lua). `buildPage` now does that (skipped in search prebuild);
  `getHeaderBuilder` returns the same kept function (`UI.EUIHeader`) for cache restores.
  PLUGINS_API.md does not mention this.

## 0.32.0
- Turning a button off (settings checkbox, icon strip, `/amac remove`) or deleting a custom
  category **deletes its macro** (`toDelete` queue, handled at the start of `UpdateCore` out of
  combat, so in combat it waits). `DeleteManaged` only deletes when `BodyMatches` says the text
  is ours. After a delete, `db.idx` is wiped because macro indexes shift; slots are found again
  by name.

## 0.31.0
- Fix for 0.30.0 not loading at all (205 top-level locals). The options code's private helpers
  moved into the `UI` table (now 181 locals).

## Added in 0.30.0 — options as tabs (modelled on EllesmereUI's Cooldown Manager page)
- `PAGES` = tabs: Buttons, Highlight, Flyout, General. Each page has `sections` (a list, or a
  function for Buttons) and optionally `header` = a preview strip key in `HEADERS`
  (buttons: clickable icon strip, grey = off; glow: empty vs stocked sample; flyout: sample
  button + tab + a static popup drawn with the current style). Header builders are idempotent
  (re-run to refresh, `RefreshHeaders`); EUI gets them via `getHeaderBuilder`, height changes
  via `EllesmereUI:UpdateContentHeaderHeight`.
- EUI page: adjacent toggle/slider/dropdown items are paired into `DualRow`s; colour rows are a
  DualRow (mode dropdown + custom swatch); the Buttons grid uses `TripleRow` toggles.
  Order items in PAGES so pairable ones sit next to each other.
- Buttons tab groups: `BUTTON_GROUPS` (Recovery, Food & Drink, Buffs, Utility, Class), then
  Custom and Other. `SetEnabled(e, on)` = /amac add/remove.
- Stand-alone window (`/amac options standalone`, and the simulator): same tabs, preview strip
  above a scrolling page, single column except the 3-column checkbox grid.

## Added in 0.29.0
- New item categories (off by default, `/amac add <key>`): `explosives`, `ragepot`, `bufffood`,
  `flask`, `weaponbuff` (macro adds `/use [mod:shift] 17; 16` to apply to a weapon). Item lists
  from AutoBar (Muffin.* and LibPeriodicTable Misc/Consumable sets).
- `travel` (Hearth/Teleport, on by default, all classes, general tab) replaced the mage-only
  `teleports` button (keeps its saved name AM_Teleport; `alias = "teleports"`). Lists hearth items
  carried **or worn** (ScanBags adds equipped slots 1-19) with Hearthstone first, then known
  TRAVEL_SPELLS (Astral Recall, Teleport: Moonglade, mage teleports, ...). List entries can be
  spells (`spell = true`, `pick = -spellID`); `Chosen` returns id + entry and matches on `pick`.
- Learning extended (CLASSIFIER 2, so earlier automatic results are redone): looks at classes
  0/4/7/15; "Use:" teleport/"returns you to" -> travel; "well fed" -> buff food (not plain food);
  rage potions; flasks (sub 3); weapon buffs; explosives (classic: Trade Goods sub 2; retail:
  consumable sub 0 with damage).
- Lewis wants automatic learning for every category.
- Options got a checkbox per category (now the Buttons tab, see 0.30.0).
- Equippable items (teleport rings/cloaks/trinkets) show **grey** in the flyout until worn;
  clicking equips them (`EquipByID`, not in combat) and picks them, so the button shows their
  cooldown. On Hearth/Teleport, gear that needs equipping sorts last so the automatic choice
  always works. PLAYER_EQUIPMENT_CHANGED triggers an update.
- (These two were added on top of 0.29.0 before it was tested, so 0.29.0 has no separate
  earlier copy in previous/.)

## Retail test setup (0.28.0)
- WoW Forever isn't released yet, so Lewis also tests in **retail**. The .toc lists
  `## Interface: 16001, 120100, 120105` so it loads in both.
- `_retail_\Interface\AddOns\AutoMacros` is a **junction to this project folder**: edits here
  are live in retail after `/reload`. Retail item lists don't match (built-in lists are classic
  items). EllesmereUI is installed in retail too (9.6.8, plugin API 3, same as Forever's 9.6.7),
  so the EUI settings page and accent colour can be tested there.

## Added in 0.27.0
- Bar watcher: once a second the contents of the known action buttons are compared
  (`BarSignature`), and the highlight/tabs redrawn on any change, because the simulator can miss
  ACTIONBAR_SLOT_CHANGED when a macro is dropped on a bar (highlight only appeared after a bag event).
- `/automacros` prints macro counts and which macros had to be created this session
  (diagnosing macros/bars not surviving /reload in the simulator).

## Added in 0.26.0
- Every colour setting has a mode: Default (STYLE_DEFAULTS) / EllesmereUI accent / Custom,
  saved as `style[<key>Mode]`. `StyleColor(key)` resolves it; draw code must use StyleColor,
  not Style, for colours. The 0.25.0 global `euiAccent` switch is gone (still read once as a
  migration hint in `ColorMode`).
- (0.26.0-0.29.0 had all options on one page; 0.30.0 went back to tabs, see above.)
- EllesmereUI is installed at `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\EllesmereUI*`;
  its developer docs are `EllesmereUI\PLUGINS_API.md` and `SKINNING_API.md`. Accent colour:
  skin `S.GetAccentColor()` or `EllesmereUI.ELLESMERE_GREEN` {r,g,b} (live).

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
  (verified against EllesmereUI's source in 0.26.0; all calls are pcall-wrapped).
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
  any click selects that item as the default (no left/right distinction). `/amac flyout` toggles.
  (`/amac flyout test` was removed in 0.36.0.)
- Action buttons holding active macros are recognised by **macro name** (their slot reports the
  item ID). Active macros are not rewritten on every refresh.
- `/amac items` (removed in 0.44.0; item learning replaced it).
- `/amac debug`; errors are reported once, not spammed.

## Empty-state behaviour (when no item of a category is in bags)
- Icon: an in-game item icon — Refreshing Spring Water (water), Empty Vial (health/mana potions),
  Tough Hunk of Bread (food). (Icon 1339440, a red X in a frame, was used before.)
- Macro body is `/amac empty No water in inventory.` (since 0.65.0; was the plain message,
  which the game sent as /say) — **no "#" anywhere.** Clicking prints the message in your own
  chat only.
- Tooltip is a clean red message via a GameTooltip hook (`/amac tooltip` toggles), guarded
  against the game's tooltip rebuilds overwriting it.
- Button gets a highlight border.
- Titles use readable names: "Health Potion", "Mana Potion"; labels are plural where Lewis set them.

## Roadmap / ideas
- ~~Popout direction~~: done in 0.90.0 (see there). The settings demo always shows "up".
- A config page for options and customization.
- Possibly derive categories from client item class data instead of hardcoded lists.
- Disease-removal items category (requested alongside bandages/anti-venom).
- More AutoBar categories offered but not yet chosen: rejuvenation potions, mana stones,
  battle/guardian elixirs, utility potions (free action, water breathing, speed, resistance),
  rogue poisons, pet food, lockboxes/openables, fishing, mount items, fireworks/fun items,
  quest-usable items, unlock items, class spells (forms, stances, aspects, totems, traps...).

## Reference material Lewis has used
- AutoBar 12.1.0.02 (its `camelot` folder is the Forever version)
- FlyoutMacros 1.8.0
- lookino's Flyout 1.1.6 (vanilla 1.12 — reference for flyout UX only, not API)
