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
| TinyPad | Gello | **Ported** (in progress) | 3.0.19 brought to 3.3.5a. |
| GlobalIgnoreList | IceyPop | **Ported** (in progress) | 11.2.7.1 brought to 3.3.5a. |
| WDM (WoW Dungeon Maps) | Trimitor | **Fixed** | Opening the world map in combat no longer causes "Interface action failed because of an AddOn" (taint fix). Changes are marked `-- 3.3.5a taint fix`. |
| Auctionator | Zirco | **Modified** | The "Scan AH" button on the tradeskill window is removed. |
| AuctionatorMiniFeatures | ckaotik | **Fixed** | Its TOC no longer lists a missing `data.lua`, which caused a load error. |

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
| Attune | CixiDelmont, Yvely |
| GearScoreLite | Mirrikat45 & Leo |
| LibMapData-1.0 | (no author listed) |
| Postal | Xinhuan |
| Questie-335 | Aldori and the original Questie team |

## Installing

Copy the addon folders into `World of Warcraft\Interface\AddOns`.
AtlasLootRevival shows Classic and TBC dungeon maps only if a dungeon-map patch is installed, such as Trimitor's [WDM-patch](https://github.com/Trimitor/WDM-patch). The WotLK maps are part of the 3.3.5a client.
