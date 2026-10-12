# wotlk-335a-ports

A personal hobby collection of World of Warcraft **3.3.5a** (Wrath of the Lich King, build 12340) addons.
A few were ported or fixed to work on the 3.3.5a client. The rest are unmodified copies, kept here only as a backup.

## Ported, fixed or modified

| Addon | Original author(s) | Status | What changed |
|---|---|---|---|
| AtlasLootRevival | AtlasLoot Revival contributors | **Ported** | Works on 3.3.5a, with all WotLK dungeons and raids added. The WotLK loot data comes from AtlasLoot Enhanced. Details are in [`CHANGES_3.3.5a.md`](AtlasLootRevival/CHANGES_3.3.5a.md). |
| TinyPad | Gello | **Ported** | Works on 3.3.5a and keeps notes from older TinyPad versions. Adds the Roboto Mono font (SIL Open Font License) and fixes typing Turkish letters. |
| GlobalIgnoreList | IceyPop | **Ported** | Works on 3.3.5a. Chat filters you edit stay edited, and there's no chat message at login. |
| WDM (WoW Dungeon Maps) | Trimitor | **Fixed** | Opening the map in combat no longer causes "Interface action failed". Needs the map files listed under [Requirements](#requirements). |
| Auctionator | Zirco | **Modified** | The "Scan AH" button in the profession window is removed. |
| AuctionatorMiniFeatures | ckaotik | **Fixed** | Fixes an error at load. |
| Attune | CixiDelmont, Yvely | **Modified** | No chat message at login. |

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

**WDM** and **AtlasLootRevival** need Trimitor's Classic & TBC dungeon map patch. It isn't included here; get it from the original source, **[Trimitor/WDM-patch](https://github.com/Trimitor/WDM-patch)** (Releases), and put the files in `World of Warcraft\Data\<yourLocale>\` (e.g. `Data\enUS\`):

- `patch-<locale>-M.MPQ`: the main patch with the Classic and TBC dungeon maps.
- `patch-<locale>-N.MPQ`: optional cave and mine maps (beta).

WDM's original source is [Trimitor/WDM-addons](https://github.com/Trimitor/WDM-addons). Without the map patch, AtlasLootRevival still works, but its Classic and TBC instances show no map.

## Disclaimer

- **I don't own any of these addons.** All credit and rights belong to their original authors, listed above, and to the creators of the font and data added to some of them. Thank you to every one of them for their work.
- The changes here are a **hobby project**, made for personal use and shared as-is, without any warranty.
- This repository is not affiliated with or endorsed by the addon authors or Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment.
- Each addon keeps its original license, and added parts keep theirs: AtlasLootRevival's WotLK data comes from GPL-licensed sources (AtlasLoot Enhanced, Questie), and TinyPad's Roboto Mono font is under the SIL Open Font License. Where an addon ships without a license, all rights remain with its author.
- **If you are an author** and want your addon removed or credited differently, please open an issue and it will be taken care of.
