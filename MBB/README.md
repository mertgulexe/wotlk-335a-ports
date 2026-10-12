# Minimap Button Bag Reborn (MBB Reborn)

## Summary
MBB Reborn keeps your minimap clean by collecting addon buttons into a single expandable menu.

With the new **Button Manager**, custom button sorting, profiles and flexible positioning options, MBB Reborn gives you full control over how your minimap buttons are organized.

---

## Features

- Collects minimap buttons into one expandable menu
- Keeps the minimap clean and uncluttered
- Button Manager for managing detected minimap buttons
- Drag & Drop button sorting
- Move buttons up or down manually
- Persistent custom button order
- Profile system with create, rename, duplicate and delete options
- Quick profile switching from the settings
- Adjustable MBB button scale
- Configurable expansion direction
- Configurable secondary row direction
- Adjustable maximum buttons per row
- Auto-hide support
- Detachable and freely movable MBB button
- Position locking
- Snapping to WoW window edges
- Movable settings window
- Manual recovery of missing buttons
- Built-in patch compatibility check
- Account-wide general settings
- Multi-language localization
- Support for multiple World of Warcraft clients

---

## Supported World of Warcraft Versions

MBB Reborn uses a shared codebase and currently supports:

- **World of Warcraft Retail / Midnight**
- **World of Warcraft Forever**
- **WoW Classic Era**
- **WoW Classic: The Burning Crusade**
- **WoW Classic: Mists of Pandaria**

MBB Reborn 2.0 has been tested on all of the clients listed above.

> **WoW Forever:** MBB Reborn was tested successfully with the WoW Forever Beta client using Interface 16001.

---

## Button Manager

MBB Reborn 2.0 introduces a new **Button Manager**.

The Button Manager displays detected minimap buttons and allows you to manage them directly.

Buttons are visually marked depending on their current state:

- **In MBB** – the button is currently stored inside MBB
- **On Minimap** – the button is currently attached to the minimap
- **Unavailable** – the button is known to MBB but is currently not loaded

You can also reorder buttons using **Drag & Drop** or the **Up / Down** controls.

Open the Button Manager from the MBB settings or with:

`/mbb manager`

---

## Profiles

MBB Reborn 2.0 includes a complete profile system.

Profiles can store settings such as:

- Button scale
- Expansion direction
- Secondary row direction
- Maximum buttons per row
- Auto-hide settings
- Detached MBB button position
- Position lock
- WoW window edge snapping
- Custom button order

Profiles can be created, renamed, duplicated, deleted and switched directly from the MBB settings.

Character-specific excluded buttons remain independent from profiles.

Use:

`/mbb profiles`

or:

`/mbb profile`

---

## Detaching Buttons

Each button stored inside MBB can be returned to the minimap using:

**Ctrl + Right Click**

The MBB button itself can also be detached from the minimap and positioned freely.

When detached, its position can optionally be locked or snapped to the edges of the WoW window.

> **Multi-monitor note:** WoW addons can detect the boundaries of the WoW UI viewport, but not the physical boundary between individual monitors.

---

## Slash Commands

- `/mbb` – shows the available MBB commands
- `/mbb buttons` – shows a list of buttons currently known to MBB
- `/mbb manager` – opens the Button Manager
- `/mbb profiles` – opens the profile management
- `/mbb profile` – opens the profile management
- `/mbb rescan` – rescans the minimap for missing buttons
- `/mbb reset position` – resets the position of the MBB button
- `/mbb reset all` – resets MBB settings and custom button order
- `/mbb patch` – shows patch compatibility status
- `/mbb about` – shows addon version and credits

---

## Patch Compatibility

MBB Reborn includes a built-in patch compatibility check.

If World of Warcraft receives a new patch and its interface version changes, MBB can notify you that an addon update may be required.

You can manually check the current compatibility status using:

`/mbb patch`

---

## Versioning

MBB Reborn uses independent semantic versioning.

Current version:

[![GitHub Release](https://img.shields.io/github/v/release/DGMonster/MBB)](https://github.com/DGMonster/MBB/releases/latest)

The original `4.x` versioning is no longer used by MBB Reborn.

---

## Localization

MBB Reborn currently includes localization for:

- English
- German
- French
- Italian
- Korean
- Russian
- Simplified Chinese
- Traditional Chinese

English is used as the fallback language.

Translations are community-driven. Contributions and corrections are welcome through GitHub.

---

## Credits

MBB Reborn is based on **MinimapButtonBag 4.0.26**.

Original authors and maintainers:

- **karlsnyder**
- **vallantv**
- **SkunFly**

Many thanks to the original authors for creating and maintaining the project.

---

## Maintainer

**GrazyMonster**

---

## Source Code

GitHub repository:

https://github.com/DGMonster/MBB
