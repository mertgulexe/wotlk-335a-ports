if( GetLocale() == "deDE" ) then
	MBB_TOOLTIP1 = "Strg + Rechtsklick auf einen Button, um ihn aus der Leiste zu lösen.";
	MBB_OPTIONS_HEADER = "Einstellungen";
	MBB_OPTIONS_OKBUTTON = "Ok";
	MBB_OPTIONS_CANCELBUTTON = "Abbrechen";
	MBB_OPTIONS_SLIDEROFF = "Aus";
	MBB_OPTIONS_SLIDERSEK = "Sek.";
	MBB_OPTIONS_SLIDERLABEL = "Autom. ausblenden:";
	MBB_OPTIONS_EXPANSIONLABEL = "Ausklappen nach:";
	MBB_OPTIONS_EXPANSIONLEFT = "Links";
	MBB_OPTIONS_EXPANSIONTOP = "Oben";
	MBB_OPTIONS_EXPANSIONRIGHT = "Rechts";
	MBB_OPTIONS_EXPANSIONBOTTOM = "Unten";
	MBB_OPTIONS_MAXBUTTONSLABEL = "Max. Knöpfe/Zeile:";
	MBB_OPTIONS_MAXBUTTONSINFO = "(0=unendlich)";
	MBB_OPTIONS_ALTEXPANSIONLABEL = "Neue Reihe nach:";
	MBB_OPTIONS_BUTTONSCALE = "Button-Größe:";
	MBB_HELP1 = "Gib \"/mmbb <cmd>\" ein, wobei <cmd> folgendes sein kann:";
	MBB_HELP2 = "  |c00ffffffbuttons|r: Zeigt eine Liste aller Frames in der MBB Leiste";
	MBB_HELP3 = "  |c00ffffffreset position|r: Setzt den MBB Minimap Button an seine ursprüngliche Position";
	MBB_HELP4 = "  |c00ffffffreset all|r: Setzt alle Einstellungen auf ihre ursprünglichen Werte";
	MBB_NOERRORS = "Keine Fehler gefunden!";
	MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn geladen."
    MBB_FIRST_RUN_COUNT = "%d Minimap-Buttons gesammelt."
    MBB_FIRST_RUN_HELP = "Gib /mbb ein, um alle Befehle zu sehen."
    MBB_FIRST_RUN_RESCAN = "Nutze /mbb rescan, falls Buttons fehlen."


	-- NEW: About / Credits
	MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
	MBB_ABOUT_VERSION = "Version:";
	MBB_ABOUT_BASED_ON = "(basierend auf 4.0.26)";
	MBB_ABOUT_CREDITS_TITLE = "Credits:";

	-- NEW: Patch status (/mbb patch)
	MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – Patch-Status";
	MBB_PATCH_ADDON_INTERFACE = "Addon Interface-Version:";
	MBB_PATCH_WOW_INTERFACE = "Aktuelle WoW Interface-Version:";
	MBB_PATCH_OK = "Status: Addon ist für diesen WoW-Patch aktuell.";
	MBB_PATCH_OLD = "Status: Dieses Addon wurde für einen älteren WoW-Patch erstellt. Bitte prüfe auf Updates.";

	-- NEW: Help lines (optional, if you print them)
	MBB_HELP_ABOUT = "  |c00ffffffabout|r: Zeigt Addon-Infos (Version & Credits)";
	MBB_HELP_PATCH = "  |c00ffffffpatch|r: Zeigt Patch-Kompatibilitätsstatus";
	MBB_HELP_RESCAN = "  |c00ffffffrescan|r: Scannt die Minimap erneut nach fehlenden Buttons";
    MBB_RESCAN_DONE = "MBB: Rescan abgeschlossen. %d neue Minimap-Buttons gefunden.";
	
	-- Detach / Free move option
	MBB_OPTIONS_DETACH = "Von der Minimap lösen";
	MBB_OPTIONS_DETACH_DESC = "Erlaubt es, den MBB-Button frei auf dem Bildschirm zu platzieren.";
	MBB_OPTIONS_DETACH_COMBAT = "Kann im Kampf nicht geändert werden.";

	-- Version update notification
	MBB_UPDATE_AVAILABLE = "MBB: Eine neuere Version ist verfügbar: %s (du verwendest %s). Bitte aktualisiere über CurseForge.";

	-- MBB Reborn 2.0 - Button Manager
	MBB_MANAGER_BUTTON = "Button-Verwaltung...";
	MBB_MANAGER_TITLE = "Button-Verwaltung";
	MBB_MANAGER_DESC = "Verwalte bekannte Minimap-Buttons. Aktivierte Buttons werden in MBB gesammelt.";
	MBB_MANAGER_ENABLED = "In MBB";
	MBB_MANAGER_DISABLED = "Auf Minimap";
	MBB_MANAGER_MISSING = "Nicht geladen";
	MBB_MANAGER_RESCAN = "Neu scannen";
	MBB_MANAGER_CLOSE = "Schließen";
	MBB_MANAGER_COUNT = "%d bekannte Buttons";
	MBB_MANAGER_EMPTY = "Noch keine Buttons erkannt. Nutze „Neu scannen“.";
	MBB_MANAGER_COMBAT = "Die Button-Verwaltung ist im Kampf deaktiviert.";
	MBB_MANAGER_COLUMN_BUTTON = "Button";
	MBB_MANAGER_COLUMN_STATUS = "Status";
	MBB_MANAGER_TOOLTIP_INCLUDED = "Aktiviert: Dieser Button wird in MBB gesammelt.";
	MBB_MANAGER_TOOLTIP_EXCLUDED = "Deaktiviert: Dieser Button bleibt auf der Minimap.";
	MBB_HELP_MANAGER = "  |c00ffffffmanager|r: Öffnet die Minimap-Button-Verwaltung";

	-- MBB Reborn 2.0 - Button ordering
	MBB_MANAGER_ORDER_HELP = "Ziehe eine Zeile oder nutze die Pfeile, um die Button-Reihenfolge zu ändern.";
	MBB_MANAGER_MOVE_UP = "Nach oben";
	MBB_MANAGER_MOVE_DOWN = "Nach unten";
	MBB_MANAGER_RESET_ORDER = "Reihenfolge zurücksetzen";
	MBB_MANAGER_RESET_ORDER_DONE = "MBB: Button-Reihenfolge zurückgesetzt.";
	MBB_MANAGER_DRAG_HINT = "Ziehe diese Zeile, um ihre Position zu ändern.";


-- MBB Reborn 2.0 - Positioning
	MBB_OPTIONS_LOCK_POSITION = "Position sperren";
	MBB_OPTIONS_LOCK_POSITION_DESC = "Verhindert, dass der gelöste MBB-Button versehentlich verschoben wird.";
	MBB_OPTIONS_SNAP_EDGES = "An WoW-Fensterrändern einrasten";
	MBB_OPTIONS_SNAP_EDGES_DESC = "Lässt den gelösten MBB-Button an nahen Rändern des WoW-Fensters einrasten. Hinweis: WoW-Addons können die physische Grenze zwischen mehreren Monitoren nicht erkennen.";


-- MBB Reborn 2.0 - Profiles
	MBB_PROFILE_BUTTON = "Profile";
	MBB_PROFILE_TITLE = "Profile";
	MBB_PROFILE_DESC = "Profile speichern Layout, Skalierung, Position und Button-Reihenfolge. Ausgeschlossene Buttons bleiben charakterspezifisch.";
	MBB_PROFILE_CURRENT = "Aktuelles Profil:";
	MBB_PROFILE_ACTIVE = "Aktiv";
	MBB_PROFILE_DEFAULT_DISPLAY = "Standard";
	MBB_PROFILE_ACTIVATE = "Aktivieren";
	MBB_PROFILE_NEW = "Neu";
	MBB_PROFILE_DELETE = "Löschen";
	MBB_PROFILE_CLOSE = "Schließen";
	MBB_PROFILE_HINT = "Neue Profile starten als Kopie des aktuellen Profils.";
	MBB_PROFILE_NEW_PROMPT = "Name für das neue Profil eingeben:";
	MBB_PROFILE_DELETE_PROMPT = "Profil '%s' löschen?";
	MBB_PROFILE_APPLIED = "MBB: Profil '%s' aktiviert.";
	MBB_PROFILE_CREATED = "MBB: Profil '%s' erstellt.";
	MBB_PROFILE_DELETED = "MBB: Profil '%s' gelöscht.";
	MBB_PROFILE_EXISTS = "MBB: Ein Profil mit dem Namen '%s' existiert bereits.";
	MBB_PROFILE_INVALID = "MBB: Bitte einen Profilnamen mit 1 bis 32 Zeichen eingeben.";
	MBB_PROFILE_DELETE_DEFAULT = "MBB: Das Standardprofil kann nicht gelöscht werden.";
	MBB_PROFILE_COMBAT = "MBB: Profile können im Kampf nicht gewechselt werden.";
	MBB_PROFILE_RENAME = "Umbenennen";
	MBB_PROFILE_DUPLICATE = "Duplizieren";
	MBB_PROFILE_RENAME_PROMPT = "Neuen Namen für Profil '%s' eingeben:";
	MBB_PROFILE_DUPLICATE_PROMPT = "Namen für die Kopie von Profil '%s' eingeben:";
	MBB_PROFILE_COPY_SUFFIX = "Kopie";
	MBB_PROFILE_RENAMED = "MBB: Profil '%s' wurde in '%s' umbenannt.";
	MBB_PROFILE_DUPLICATED = "MBB: Profil '%s' wurde als '%s' dupliziert.";
	MBB_PROFILE_RENAME_DEFAULT = "MBB: Das Standardprofil kann nicht umbenannt werden.";
	MBB_HELP_PROFILE = "  |c00ffffffprofiles|r: Öffnet die Profilverwaltung";

end
