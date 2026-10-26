# wotlk-335a-ports

A personal hobby collection of World of Warcraft **3.3.5a** (Wrath of the Lich King, build 12340) addons.
A few were ported or fixed to work on the 3.3.5a client. The rest are unmodified copies, kept here only as a backup.

## Ported, fixed or modified

| Addon | Original author(s) | Status | What changed |
|---|---|---|---|
| AtlasLootRevival | AtlasLoot Revival contributors | **Ported** | Works on 3.3.5a, with all WotLK dungeons and raids added. The WotLK loot data comes from AtlasLoot Enhanced. Inside an instance, the map opens on the floor you're on. Details are in [`CHANGES_3.3.5a.md`](AtlasLootRevival/CHANGES_3.3.5a.md). |
| TinyPad | Gello | **Ported** | Works on 3.3.5a and keeps notes from older TinyPad versions. Adds the Roboto Mono font (SIL Open Font License) and fixes typing Turkish letters. |
| GlobalIgnoreList | IceyPop | **Ported** | Works on 3.3.5a. Chat filters you edit stay edited, and there's no chat message at login. Also fixes a game freeze caused by a filter ending in "not", and errors in the ignore list. |
| MBB (MinimapButtonBag-Reborn) | GrazyMonster; based on MinimapButtonBag by karlsnyder, vallantv and SkunFly | **Ported** | Works on 3.3.5a: collects the minimap icons into one button. Icons are gathered before the loading screen ends, and the button circles the minimap edge when dragged. Adds an option to hide its tooltip. Details are in [`CHANGES_3.3.5a.md`](MBB/CHANGES_3.3.5a.md). |
| WDM (WoW Dungeon Maps) | Trimitor | **Fixed** | Opening the map in combat no longer causes "Interface action failed". Clicking a dungeon or raid entrance on the world map shows that instance's map, with its floors. Needs the map files listed under [Requirements](#requirements). |
| Auctionator | Zirco | **Modified** | The "Scan AH" button in the profession window is removed. |
| AuctionatorMiniFeatures | ckaotik | **Fixed** | Fixes an error at load. |
| Attune | CixiDelmont, Yvely | **Modified** | No chat message at login. The minimap icon appears right at login instead of after the server sends quest data. |
| AtlasQuest | Thandrenn | **Modified** | Quests you complete are ticked as finished automatically, at login and after each turn-in. Boxes you untick by hand stay unticked. |
| Cell (r279, WotLK build): raid-style party and raid frames | enderneko; WotLK build by NoM0Re | **Modified** | Minimap button: right-click opens the options window, left-click hides or shows the party/raid frames (not in combat; they come back after `/reload`). |
| TinyDPS (0.84, the last 3.3.x version) | Sideshow | **Modified** | Middle-click on the window switches between damage and healing. Resetting the data is now Ctrl + middle-click. The window shows Overall (all fights) by default and stays on it after a reset, including the automatic reset when you join a group; upstream switched back to the current fight each time. When you hide the window (minimap button or `/tdps`), it stays hidden, even in combat or after `/reload`, until you show it again the same way. |
| Questie-335 | Aldori and the original Questie team | **Modified** | Minimap and world-map buttons: left-click hides or shows Questie, and Ctrl + left-click opens or closes the My Journey window. Shift + left-click (options), right-click (menu) and Ctrl + right-click (hide the minimap button) are unchanged. |

## Made here

| Addon | Status | What it does |
|---|---|---|
| QuestsInChains | **New**, awaiting in-game test | Shows the whole quest chain of every quest AtlasQuest lists for dungeons, raids and battlegrounds: what comes before it, what it leads to, and the quests those need. Finished, active, available and locked quests are marked from your completed quests and quest log. Open it with `/qic`, the minimap button, or the **Chain** button on AtlasQuest's quest page and in the quest log. The look follows QuestWeaver (a TBC Classic addon). The chain data is generated from Questie-335's quest database and AtlasQuest's quest lists. |

## Unmodified (backups)

These are stock copies, untouched:

| Addon | Original author(s) |
|---|---|
| !Astrolabe | Esamynn, Trimitor |
| ACP (Addon Control Panel) | sylvanaar, Rophy, Saien |
| AllStats | Ganoran |
| Atlas, Atlas_Battlegrounds, Atlas_DungeonLocs, Atlas_OutdoorRaids, Atlas_Transportation | Dan Gilbert and the Atlas team |
| AtlasLoot, AtlasLootFu, AtlasLoot_BurningCrusade, AtlasLoot_Crafting, AtlasLoot_OriginalWoW, AtlasLoot_WorldEvents, AtlasLoot_WrathoftheLichKing | Hegarol and the AtlasLoot team |
| GearScoreLite | Mirrikat45 & Leo |
| LibMapData-1.0 (library file only: no .toc, so the game doesn't load it, and no addon here uses it) | (no author listed) |
| Postal | Xinhuan |

## Installing

This repository is the whole `World of Warcraft\Interface\AddOns` folder: clone it, copy the map patch once, and play.

**1. Get the addons.** If you don't have an `AddOns` folder yet, run this in `World of Warcraft\Interface`:

```
git clone https://github.com/mertgulexe/wotlk-335a-ports.git AddOns
cd AddOns
```

If you already have one, run this inside `World of Warcraft\Interface\AddOns`. Files from the repo overwrite addons with the same name. Old files they no longer use stay behind but aren't loaded; for a clean copy, delete those addon folders first. Other folders, including the game's `Blizzard_*` folders, are left alone:

```
git init
git remote add origin https://github.com/mertgulexe/wotlk-335a-ports.git
git fetch origin main
git checkout -f -B main origin/main
```

If you run these again, ignore "remote origin already exists".

**2. Copy the dungeon map patch** (enUS client), from inside the `AddOns` folder. In Command Prompt or PowerShell:

```
copy "_WDM-patch\enUS\*.MPQ" "..\..\Data\enUS\"
```

In Git Bash:

```
cp _WDM-patch/enUS/*.MPQ ../../Data/enUS/
```

Or copy the two files from `_WDM-patch\enUS` into `World of Warcraft\Data\enUS` in File Explorer.

**3. Start the game.** To update later, close the game and run `git pull` in the `AddOns` folder. If the pull changes files in `_WDM-patch`, do step 2 again. If it says untracked files would be overwritten, delete the files it lists and run it again.

## Requirements

**WDM** and **AtlasLootRevival** use Trimitor's Classic & TBC dungeon map patch. The enUS files are included in [`_WDM-patch/enUS`](_WDM-patch/enUS) and go into `World of Warcraft\Data\enUS\` (step 2 above):

- `patch-enUS-M.MPQ`: the main patch with the Classic and TBC dungeon maps.
- `patch-enUS-N.MPQ`: optional cave and mine maps (beta).

For other client languages, get `patch-<locale>-M.MPQ` and `patch-<locale>-N.MPQ` from **[Trimitor/WDM-patch](https://github.com/Trimitor/WDM-patch)** (Releases) and put them in `Data\<locale>\`. WDM's original source is [Trimitor/WDM-addons](https://github.com/Trimitor/WDM-addons). Without the map patch, AtlasLootRevival still works, but its Classic and TBC instances show no map.

## Disclaimer

- **I don't own any of these addons** (except QuestsInChains, made here). All credit and rights belong to their original authors, listed above, and to the creators of the font and data added to some of them. Thank you to every one of them for their work.
- QuestsInChains uses quest data from Questie-335 (GPL) and AtlasQuest (GPL), and takes its look from QuestWeaver by the QuestWeaver Team; none of QuestWeaver's code or files are included.
- The changes here are a **hobby project**, made for personal use and shared as-is, without any warranty.
- This repository is not affiliated with or endorsed by the addon authors or Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment.
- Each addon keeps its original license, and added parts keep theirs: AtlasLootRevival's WotLK data comes from GPL-licensed sources (AtlasLoot Enhanced, Questie), and TinyPad's Roboto Mono font is under the SIL Open Font License. MinimapButtonBag-Reborn itself is public domain (Unlicense). Where an addon ships without a license, all rights remain with its author.
- **If you are an author** and want your addon removed or credited differently, please open an issue and it will be taken care of.
