# Atlas 1.17.0: world map taint fix (3.3.5a)

## The problem

After one of Atlas's dropdown menus had been used, opening the world map in combat (key M) showed "Interface action failed because of an AddOn". `Logs\taint.log` said:

`An action was blocked in combat because of taint from Atlas - WorldMapBlobFrame:Hide()`

Atlas's dropdowns used Blizzard's shared dropdown list (`DropDownList1` and the `UIDropDownMenu_*` functions). When Blizzard's `UIDropDownMenu_AddButton` adds a row, it asks the menu that was opened last for its selection. After an Atlas dropdown had been opened, that menu was Atlas's, and Atlas had written its selection. The world map rebuilds its own three dropdowns on every update, so the map update read a value written by Atlas and ran "tainted by Atlas". In combat the client blocks a tainted map update when it shows or hides the quest area frame.

One tainted map update was enough: it left more tainted values in Blizzard's map and dropdown tables, so the map kept failing in combat until the interface was reloaded.

## The fix

- **`AtlasDropDownList.lua` (new).** Atlas's own dropdown list. It copies the look and behaviour of the stock list: backdrop, row height and fonts, check mark, width and height, where it opens (and when it opens upwards or to the left), the scale, the 2-second hide timer and the click sounds. It calls no Blizzard dropdown function and writes to no Blizzard frame, table or global variable. To close together with Blizzard's menus it uses `hooksecurefunc` on `CloseDropDownMenus`, `HideDropDownMenu`, `CloseMenus` and `ToggleDropDownMenu`.
- **`Atlas.lua`, `AtlasOptions.lua`.** The four dropdowns (map category, map, the entrance/instance switch list, "sort by" in the options) keep their frames, names and look, but open Atlas's list. Their `..._Initialize` functions return the rows instead of adding them to Blizzard's list. Their `..._OnClick` functions get the number of the clicked row; called the old way, they still read `this:GetID()`. The text and width of a dropdown are set directly.
- **`Atlas.toc`.** Loads the new file.
- **`AtlasLoot/Core/HooksandAPI.lua` (one call).** AtlasLoot replaces `Atlas_Refresh` with its own copy, and the copy made the same Blizzard dropdown call for the switch list. It now uses Atlas's list when the fixed Atlas is loaded, and the old call otherwise.

Every changed function carries a `--3.3.5a taint fix` comment.

Update Atlas and AtlasLoot together. The fixed Atlas works with an AtlasLoot that lacks the change, but that AtlasLoot still runs Blizzard's dropdown code from addon code each time Atlas shows a map with an entrance/instance button.

## What is different for the player

- With a list open, Escape closes the list and then does what Escape does next: it stops a cast in progress, otherwise it closes the open windows, Atlas included. Before, Escape closed only the list.
- A Blizzard menu or an AtlasLoot menu that is already open stays open when an Atlas list is opened. Before, they shared one list and replaced each other. An AtlasLoot menu also stays for a few seconds after the Atlas window is closed, until its own timer hides it. A Blizzard menu that opens still closes Atlas's list.
- When the game or another addon rebuilds one of its own dropdowns, an open Atlas list stays open. Before, that closed it as a side effect.

The rest was compared with the original in a test harness and is the same: the rows, the checked row, the maps, the positions and sizes of the lists, the sounds and the hide timer.

## Not changed

- The option "Right-Click for World Map" (off by default) still opens the world map from Atlas's code. 3.3.5a has no way to do that without taint, so with this option on, the map can still be blocked in combat after it has been used.
- The game's Interface Options window. When it opens, the client reads the option panels of the addons, and Blizzard's own option dropdowns are then refreshed tainted. This can block the map in combat too, and the log then names the addon whose panel was read first, which can be Atlas. It happens with any addon that has an options panel; an addon cannot fix it.
- AtlasLoot's own two option dropdowns ("Loot Browser Style", "Treat Crafted Items") still use Blizzard's shared list.
- Menus of other addons that use Blizzard's shared list can cause the same message. `Logs\taint.log` names the addon.

## How to check in game

1. Close the game and start it again. A new file was added, and `/reload` does not load new files.
2. Type `/console taintLog 1`.
3. Open Atlas, pick a category and a map with the dropdowns, close Atlas. Do not open the Interface Options or another addon's menu before the next step.
4. Get into combat and press M.
5. No "Interface action failed" appears, and `Logs\taint.log` has no `taint from Atlas` line.
