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
- Every iteration is saved as its own version, **semver MAJOR.MINOR.PATCH** (since 0.85.0):
  - new features or changed behaviour: bump the middle number, patch back to 0 (0.85.0 -> 0.86.0)
  - only fixing a bug/glitch in the previous version: bump the last number (0.85.0 -> 0.85.1)
  - `1.0.0` = first stable release (works on Forever, Lewis happy to recommend it). Stay on 0.x until then.
- **CHANGELOG.md**: every version gets an entry at the top (date, Added / Changed / Fixed /
  Removed), written for players, not code notes (those stay in this file).
- **GitHub Releases** are only for builds worth downloading: tested in game = normal release;
  not yet tested = `--prerelease`. Every iteration is still committed and pushed.
- Keep previous versions; older builds go in a `previous/` folder (e.g. `previous/0.24.0/`).
  The top-level `AutoMacros.lua` / `AutoMacros.toc` are always the current version.
- **Current version: 0.85.0.**
- **Copy the current files into `previous/<version>/` BEFORE the first edit of a new iteration**
  (missed twice; 0.32.0 had to be rebuilt by reversing edits). Bump the version in the .toc and anywhere else it appears.
- When Lewis asks for a zip (for uploading to uiforever.com), build
  `releases/AutoMacros-<version>.zip` containing an `AutoMacros/` folder with only the
  addon files (`AutoMacros.toc`, `AutoMacros.lua`) — no CLAUDE.md, `previous/`, or `.git`.
- **GitHub:** public repo https://github.com/goldenpipes/AutoMacros, branch `master`.
  git = GitHub Desktop's `%LOCALAPPDATA%\GitHubDesktop\app-*\resources\app\git\cmd\git.exe`
  (not on PATH; resolve the wildcard, the folder changes when Desktop updates). Push auth is
  the GitHub CLI `C:\Program Files\GitHub CLI\gh.exe` (logged in as goldenpipes; set up as
  git's credential helper for github.com in the global gitconfig). When a version is
  committed: `git push origin master`; for a release, also build the zip and
  `gh release create v<version> releases/AutoMacros-<version>.zip --title "AutoMacros <version>" --notes-file <that version's CHANGELOG section>`
  (add `--prerelease` if untested).
- Lewis edits the Lua himself. Before building a new version, diff against the last one you
  produced and **merge his edits** — never overwrite them.

## Before handing over any build — always
- Run `python -I tools\luacheck.py AutoMacros.lua`. It checks block/bracket structure and the
  number of **top-level locals**: WoW's Lua 5.1 refuses a file with more than 200, and then
  NOTHING loads (no slash commands, no macros, no EllesmereUI page). 0.30.0 broke this way
  (205). New top-level helpers belong in a table (the options code uses `UI.*`), not new locals.
- There is no Lua interpreter here; the checker is the only pre-flight test.

## Next up (left off 2026-10-25)
- 0.85.0 is built and checked but **not tested in game** (Lewis couldn't run WoW). Waiting on
  him to test it and run `/amac audit` + `/reload` in retail (later Forever). Then read
  `_retail_\WTF\Account\GOLDENPIPES\SavedVariables\AutoMacros.lua` (`audit`), add an
  anti-venom learning rule, and trim DATA to only the items learning misses (0.86.0).

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
