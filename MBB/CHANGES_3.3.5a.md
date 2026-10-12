# MinimapButtonBag-Reborn 2.0.1: WoW 3.3.5a port

An unofficial port of [MinimapButtonBag-Reborn](https://github.com/DGMonster/MBB) 2.0.1 by GrazyMonster to WoW 3.3.5a (Interface 30300). MinimapButtonBag-Reborn is based on MinimapButtonBag by karlsnyder, vallantv and SkunFly. All credit goes to them.

Changes in the code are marked `3.3.5a port`.

## Compatibility

- **TOC:** Interface 30300, version `2.0.1-wotlk335`.
- **Backdrops:** this client has no `BackdropTemplate`, `KeyValues`, script `inherit` or `obeyStepOnDrag`. The windows use the client's own backdrops.
- **SetEnabled:** this client doesn't have it, so a small helper (`MBB_SetEnabled`) is used instead.

## Added

- **Show tooltip:** a new checkbox in the options turns off the tooltip of the MBB button. It's on by default and saved per profile.

## Fixes

- **Faster gathering:** the icons are collected while the loading screen is still up, then checked every 0.1 s for 10 s for late ones. Upstream checks every 3 s, so the icons stayed on the minimap for a moment after loading.
- **Greyed-out options:** "Lock position" and "Snap to WoW window edges" only work while "Detach from Minimap" is ticked. Their labels now turn grey when they can't be used, and so does "Detach" during combat. On this client, a disabled check box keeps its white label.
- **Combat:** on this client, `InCombatLockdown()` only turns true after the combat-start event has been handled. Windows refreshed by that event (options, Button Manager, Profiles) kept their controls enabled through the fight. MBB now tracks the combat events itself.
- **Detach box:** Ctrl+right-click on the MBB button and `/mbb reset position` also detach or attach it. The open options window now follows those changes.
- **Button detection:** MinimapBackdrop is scanned too, and so are buttons inside a one-button frame, as the old 3.3.5a MBB did. Atlas puts its button inside a frame like this.
- **Dragging:** the button now circles the minimap's edge, like other minimap buttons. The upstream math was made for the 198-wide minimap of today's clients; the 3.3.5a minimap is 140 wide, so the button circled a bigger, off-center ring.
- **Ignored frames:** MBB no longer collects the minimap ping or Questie's map pins.
- **Login warning:** this client can't read a TOC's Interface field, so MBB warned at every login that it was built for an older patch. It now reads as 30300.
- **Profile pop-ups:** the New, Rename, Duplicate and Delete pop-ups opened behind the profile window, and their buttons couldn't be clicked. The window now steps aside while a pop-up is open.
- **First-run message:** it waits for the first minimap scan. Before this it always said "Collected 0 minimap buttons".
- **Button size:** the slider doesn't snap while you drag it on this client, so the saved size is rounded to 5% steps.
- **Version check:** turned off. Newer upstream releases don't run on this client, so their update notices would only be noise.
