-- Default / enUS localization

MBB_TOOLTIP1 = "Ctrl + Right click on a button to reattach it to the minimap.";
MBB_OPTIONS_HEADER = "Options";
MBB_OPTIONS_OKBUTTON = "Ok";
MBB_OPTIONS_CANCELBUTTON = "Cancel";
MBB_OPTIONS_SLIDEROFF = "Off";
MBB_OPTIONS_SLIDERSEK = "sec";
MBB_OPTIONS_SLIDERLABEL = "Collapse Timeout:";
MBB_OPTIONS_EXPANSIONLABEL = "Expand to:";
MBB_OPTIONS_EXPANSIONLEFT = "Left";
MBB_OPTIONS_EXPANSIONTOP = "Top";
MBB_OPTIONS_EXPANSIONRIGHT = "Right";
MBB_OPTIONS_EXPANSIONBOTTOM = "Bottom";
MBB_OPTIONS_MAXBUTTONSLABEL = "Max. Buttons/Line:";
MBB_OPTIONS_MAXBUTTONSINFO = "(0=infinity)";
MBB_OPTIONS_ALTEXPANSIONLABEL = "Next row:";
MBB_OPTIONS_BUTTONSCALE = "Button size:";
MBB_HELP1 = "Type \"/mmbb <cmd>\" where <cmd> is one of the following:";
MBB_HELP2 = "  |c00ffffffbuttons|r: Shows a list of all frames in the MBB bar";
MBB_HELP3 = "  |c00ffffffreset position|r: Resets the position of the MBB minimap button";
MBB_HELP4 = "  |c00ffffffreset all|r: Resets all options";
MBB_NOERRORS = "No errors found!";
MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn loaded."
MBB_FIRST_RUN_COUNT = "Collected %d minimap buttons."
MBB_FIRST_RUN_HELP = "Type /mbb to see available commands."
MBB_FIRST_RUN_RESCAN = "Use /mbb rescan if buttons are missing."


-- NEW: About / Credits
MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
MBB_ABOUT_VERSION = "Version:";
MBB_ABOUT_BASED_ON = "(based on 4.0.26)";
MBB_ABOUT_CREDITS_TITLE = "Credits:";

-- NEW: Patch status (/mbb patch)
MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – Patch Status";
MBB_PATCH_ADDON_INTERFACE = "Addon Interface Version:";
MBB_PATCH_WOW_INTERFACE = "Current WoW Interface Version:";
MBB_PATCH_OK = "Status: Addon is up to date for this WoW patch.";
MBB_PATCH_OLD = "Status: This addon was built for an older WoW patch. Please check for updates.";

-- NEW: Help lines
MBB_HELP_ABOUT = "  |c00ffffffabout|r: Shows addon info (version & credits)";
MBB_HELP_PATCH = "  |c00ffffffpatch|r: Shows patch compatibility status";
MBB_HELP_RESCAN = "  |c00ffffffrescan|r: Rescans the minimap for missing buttons";
MBB_RESCAN_DONE = "MBB: Rescan complete. Found %d new minimap button(s).";

-- Detach / Free move option
MBB_OPTIONS_DETACH = "Detach from Minimap";
MBB_OPTIONS_DETACH_DESC = "Allows the MBB button to be freely moved on the screen.";
MBB_OPTIONS_DETACH_COMBAT = "Cannot be changed during combat.";

-- Version update notification
MBB_UPDATE_AVAILABLE = "MBB: A newer version is available: %s (you are using %s). Please update via CurseForge.";

-- MBB Reborn 2.0 - Button Manager
MBB_MANAGER_BUTTON = "Button Manager...";
MBB_MANAGER_TITLE = "Button Manager";
MBB_MANAGER_DESC = "Manage known minimap buttons. Checked buttons are collected by MBB.";
MBB_MANAGER_ENABLED = "In MBB";
MBB_MANAGER_DISABLED = "On Minimap";
MBB_MANAGER_MISSING = "Not loaded";
MBB_MANAGER_RESCAN = "Rescan";
MBB_MANAGER_CLOSE = "Close";
MBB_MANAGER_COUNT = "%d known buttons";
MBB_MANAGER_EMPTY = "No buttons detected yet. Use Rescan.";
MBB_MANAGER_COMBAT = "Button management is disabled during combat.";
MBB_MANAGER_COLUMN_BUTTON = "Button";
MBB_MANAGER_COLUMN_STATUS = "Status";
MBB_MANAGER_TOOLTIP_INCLUDED = "Checked: this button is collected inside MBB.";
MBB_MANAGER_TOOLTIP_EXCLUDED = "Unchecked: this button stays on the minimap.";
MBB_HELP_MANAGER = "  |c00ffffffmanager|r: Opens the minimap button manager";

-- MBB Reborn 2.0 - Button ordering
MBB_MANAGER_ORDER_HELP = "Drag a row or use the arrows to change the button order.";
MBB_MANAGER_MOVE_UP = "Move up";
MBB_MANAGER_MOVE_DOWN = "Move down";
MBB_MANAGER_RESET_ORDER = "Reset order";
MBB_MANAGER_RESET_ORDER_DONE = "MBB: Button order reset.";
MBB_MANAGER_DRAG_HINT = "Drag this row to change its position.";

-- MBB Reborn 2.0 - Positioning
MBB_OPTIONS_LOCK_POSITION = "Lock position";
MBB_OPTIONS_LOCK_POSITION_DESC = "Prevents accidentally moving the detached MBB button.";
MBB_OPTIONS_SNAP_EDGES = "Snap to WoW window edges";
MBB_OPTIONS_SNAP_EDGES_DESC = "Snaps the detached MBB button to nearby WoW window edges. Note: WoW addons cannot detect the physical boundary between multiple monitors.";

-- 3.3.5a port
MBB_OPTIONS_SHOW_TOOLTIP = "Show tooltip";
MBB_OPTIONS_SHOW_TOOLTIP_DESC = "Shows the MBB tooltip when the mouse is over the MBB button.";

-- MBB Reborn 2.0 - Profiles
MBB_PROFILE_BUTTON = "Profiles";
MBB_PROFILE_TITLE = "Profiles";
MBB_PROFILE_DESC = "Profiles save layout, scale, position and button order. Excluded buttons remain character-specific.";
MBB_PROFILE_CURRENT = "Current profile:";
MBB_PROFILE_ACTIVE = "Active";
MBB_PROFILE_DEFAULT_DISPLAY = "Default";
MBB_PROFILE_ACTIVATE = "Activate";
MBB_PROFILE_NEW = "New";
MBB_PROFILE_DELETE = "Delete";
MBB_PROFILE_CLOSE = "Close";
MBB_PROFILE_HINT = "New profiles start as a copy of the current profile.";
MBB_PROFILE_NEW_PROMPT = "Enter a name for the new profile:";
MBB_PROFILE_DELETE_PROMPT = "Delete profile '%s'?";
MBB_PROFILE_APPLIED = "MBB: Profile '%s' activated.";
MBB_PROFILE_CREATED = "MBB: Profile '%s' created.";
MBB_PROFILE_DELETED = "MBB: Profile '%s' deleted.";
MBB_PROFILE_EXISTS = "MBB: A profile named '%s' already exists.";
MBB_PROFILE_INVALID = "MBB: Please enter a profile name between 1 and 32 characters.";
MBB_PROFILE_DELETE_DEFAULT = "MBB: The Default profile cannot be deleted.";
MBB_PROFILE_COMBAT = "MBB: Profiles cannot be changed during combat.";
MBB_PROFILE_RENAME = "Rename";
MBB_PROFILE_DUPLICATE = "Duplicate";
MBB_PROFILE_RENAME_PROMPT = "Enter a new name for profile '%s':";
MBB_PROFILE_DUPLICATE_PROMPT = "Enter a name for the copy of profile '%s':";
MBB_PROFILE_COPY_SUFFIX = "Copy";
MBB_PROFILE_RENAMED = "MBB: Profile '%s' renamed to '%s'.";
MBB_PROFILE_DUPLICATED = "MBB: Profile '%s' duplicated as '%s'.";
MBB_PROFILE_RENAME_DEFAULT = "MBB: The Default profile cannot be renamed.";
MBB_HELP_PROFILE = "  |c00ffffffprofiles|r: Opens the profile manager";
