# wotlk-335a-ports

A personal hobby collection of World of Warcraft **3.3.5a** (Wrath of the Lich King, build 12340) addons.
A few were ported or fixed to work on the 3.3.5a client. The rest are unmodified copies, kept here only as a backup.

## Disclaimer

- **I don't own any of these addons.** All credit and rights belong to their original authors, listed below. Thank you to every one of them for their work.
- The changes here are a **hobby project**, made for personal use and shared as-is, without any warranty.
- This repository is not affiliated with or endorsed by the addon authors or Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment.
- Each addon keeps its original license. Where an addon ships without a license, all rights remain with its author.
- **If you are an author** and want your addon removed or credited differently, please open an issue and it will be taken care of.

## Ported, fixed or modified

| Addon | Original author(s) | Status | What changed |
|---|---|---|---|
| AtlasLootRevival | AtlasLoot Revival contributors | **Ported** | From Classic Era / TBC Anniversary (0.2.4) to 3.3.5a, with WotLK dungeons and raids added. Details in [`AtlasLootRevival/CHANGES_3.3.5a.md`](AtlasLootRevival/CHANGES_3.3.5a.md). The WotLK loot lists are derived from AtlasLoot Enhanced (GPL v2). |
| TinyPad | Gello | **Ported** (awaiting in-game test) | 3.0.19 brought to 3.3.5a. A small compatibility layer (`misc/compat.lua`) replaces the modern APIs, including timers and show/hide/enable helpers. Fixes: 3.3.5a scroll frames and fonts, clickable links in the editor, ESC handling, the window fade, and quest/achievement link insertion. Existing notes from older TinyPad versions load unchanged. Adds a **Roboto Mono** font option, which has the Turkish letters (Ğ ğ İ ı Ş ş) and other Latin Extended letters that the game's default font lacks. Adds a **Turkish Letters** setting (on by default): the 3.3.5a client turns typed or pasted ğ ı ş Ğ İ Ş into ð ý þ Ð Ý Þ, and this converts them back in the editor, search and bookmark-title boxes. Roboto Mono is by The Roboto Mono Project Authors, under the SIL Open Font License 1.1 (`media/RobotoMono-OFL.txt`). |
| GlobalIgnoreList | IceyPop | **Ported** (awaiting in-game test) | 11.2.7.1 brought to 3.3.5a: a plain `GlobalIgnoreList.toc` (3.3.5a doesn't read the flavor TOCs) and a private compatibility layer (`GIL_Compat335.lua`) for the 3.3.5a ignore API, group functions and timers. The modern windows and menus are rebuilt with 3.3.5a templates. The right-click menu entry is a taint-safe panel beside the menu. Server sync uses plain names, checkboxes work with 3.3.5a's 1/nil values, and the group warning uses 3.3.5a events. The login chat message is removed; `/gi` still shows help. Built-in chat filters you edit or remove now stay that way; before, the auto-update put them back at every login. Reset Defaults restores them. |
| WDM (WoW Dungeon Maps) | Trimitor | **Fixed** | Opening the world map in combat no longer causes "Interface action failed because of an AddOn" (taint fix). Changes are marked `-- 3.3.5a taint fix`. Needs the WDM-patch MPQ files (see [Requirements](#requirements)). Original source: [Trimitor/WDM-addons](https://github.com/Trimitor/WDM-addons). |
| Auctionator | Zirco | **Modified** | The "Scan AH" button on the tradeskill window is removed. |
| AuctionatorMiniFeatures | ckaotik | **Fixed** | Its TOC no longer lists a missing `data.lua`, which caused a load error. |
| Attune | CixiDelmont, Yvely | **Modified** | The login chat message is removed; `/attune info` still shows it. |

## Unmodified (backups)

These are stock copies, untouched:

| Addon | Original author(s) |
|---|---|
| !Astrolabe | Esamynn, Trimitor |
| ACP (Addon Control Panel) | sylvanaar, Rophy, Saien |
| AllStats | Ganoran |
| Atlas, Atlas_Battlegrounds, Atlas_DungeonLocs, Atlas_OutdoorRaids, Atlas_Transportation | Dan Gilbert and the Atlas team |
| AtlasLoot, AtlasLootFu, AtlasLoot_BurningCrusade, AtlasLoot_Crafting, AtlasLoot_OriginalWoW, AtlasLoot_WorldEvents, AtlasLoot_WrathoftheLichKing | Hegarol and the AtlasLoot team |
| AtlasQuest | Thandrenn |
| GearScoreLite | Mirrikat45 & Leo |
| LibMapData-1.0 | (no author listed) |
| Postal | Xinhuan |
| Questie-335 | Aldori and the original Questie team |

## Installing

Copy the addon folders into `World of Warcraft\Interface\AddOns`.

## Requirements

**WDM** and **AtlasLootRevival** need the Classic & TBC dungeon map patch by Trimitor. The MPQ files are not included here; get them from the original source, **[Trimitor/WDM-patch](https://github.com/Trimitor/WDM-patch)** (Releases), and place them in `World of Warcraft\Data\<yourLocale>\` (e.g. `Data\enUS\`):

- `patch-<locale>-M.MPQ`: the main patch, which adds the Classic and TBC dungeon maps. Required for WDM, and for the Classic and TBC maps in AtlasLootRevival.
- `patch-<locale>-N.MPQ`: optional "Caverns and Mines" maps, a beta release. It needs the M patch, WDM and !Astrolabe.

Without the M patch, AtlasLootRevival still works, with WotLK maps (part of the 3.3.5a client) and all loot. Its Classic and TBC instances then show "Map image not found".
