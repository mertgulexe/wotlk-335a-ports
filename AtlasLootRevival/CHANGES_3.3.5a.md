# AtlasLoot Revival: unofficial WoW 3.3.5a (WotLK) port

Based on AtlasLoot Revival 0.2.4. TOC version `0.2.4-wotlk335`, `## Interface: 30300`.
Built and tested for the 3.3.5a client (build 12340) with WotLK content.

## 3.3.5a compatibility
- **TOC:** Interface 30300. 3.3.5a only reads `AtlasLootRevival.toc`, so it now also lists the TBC and WotLK data files. Directives the client ignores were removed. `Bindings.xml` no longer uses the `category` attribute.
- **`Core/Compat.lua` (new):** local helpers, with no new globals and no changes to Blizzard's widget methods:
  - `SetColorTexture` → `SetTexture(r, g, b, a)`;
  - `SetShown` → `Show`/`Hide`;
  - a check that each map tile actually loaded;
  - an item-info request queue: a hidden GameTooltip calls `SetHyperlink` about 8 times per second and the cache is polled every 0.5 s. It replaces `C_Item.RequestLoadItemDataByID` and the `GET_ITEM_INFO_RECEIVED` / `ITEM_DATA_LOAD_RESULT` events, none of which exist on 3.3.5a.
- **Other fixes:**
  - `SetClipsChildren` is guarded.
  - The settings button uses a texture that exists in the 3.3.5a client.
  - Item icons fall back to `GetItemIcon`.
  - A tooltip that was waiting on an item refreshes when the item arrives.
- **Current-instance detection** matches the `GetInstanceInfo()` name against new `mapNames` fields. 3.3.5a has no instanceID return and no `UnitPosition`. It also picks the current difficulty.
- **Robust window build:** if anything fails while the main window or settings panel is being built, it fails cleanly instead of leaving a half-built, stuck window.
- **Images:** the TGA assets were re-saved as uncompressed with bottom-left origin. The pixels are identical.
- **Modern clients:** the original code paths are kept. Flavor detection still uses `WOW_PROJECT_ID` when it exists, and `AtlasLootRevival_TBC.toc` also loads `Core\Compat.lua`.

## WotLK support
- **New `wotlk` flavor** (3.3.5a):
  - shows Classic + TBC + WotLK content;
  - `*ByFlavor` values fall back wotlk → tbc → era;
  - a new `excludedFlavors` field hides content a 3.3.5a realm no longer has.
- **Difficulty keys:** `raid10`, `raid25`, `raid10h`, `raid25h`, alongside `normal`/`heroic`. The buttons are built for whatever each instance offers.
- **`Data/WotLK/` (generated):**
  - 16 dungeons and 9 raids. Naxxramas 80 and Onyxia 80 replace the level-60 records.
  - Holiday bosses inside existing dungeons: Coren Direbrew, Headless Horseman, Ahune and the Apothecary Trio.
  - Exclusions for removed content, such as the Scourge Invasion bosses.
  - Map.dbc instance names for auto-select.
- **Item tags:**
  - hard mode (Ulduar, Sartharion drakes);
  - Tribute Chest tiers (new item field `tributeAttempts`);
  - a player-faction filter for WotLK tables, with a "Show other faction's items" setting.
- **SavedVariables:** schema 5. Its migration drops remembered difficulties that are no longer valid.
- **Feedback link:** hidden, because upstream does not support this build.

## Data sources and licensing (please check before merging)
- **WotLK loot lists and drop rates:** converted from AtlasLoot Enhanced 5.11.04 for 3.3.5 (`X-License: GPL v2`).
- **Boss positions:** Questie-335 spawn data (upstream Questie is GPL-3.0) and Wowhead WotLK Classic, calibrated against Revival's existing coordinates.
- **Instance and floor data:** the 3.3.5a client DBCs.
- **License status:** the generated WotLK data is therefore not MIT-clean as it stands. The code changes are new work under the project's MIT license.
- **Classic/TBC maps:** on 3.3.5a these maps require a dungeon-map MPQ patch, such as Trimitor's WDM patch. The stock 3.3.5a client only ships maps for WotLK instances.

## Testing
- **Headless tests:** run against a strict 3.3.5a API simulation built from the client's own Wow.exe and FrameXML. The suite covers every instance, difficulty, encounter and floor, plus tooltips, clicks, settings, reload, five old SavedVariables schemas and a client without the map patch. Result: 0 Lua errors.
- **Not yet confirmed in-game:** the final visual layout and exact boss-pin alignment.
