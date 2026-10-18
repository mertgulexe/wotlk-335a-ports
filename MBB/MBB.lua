--[[

	Addon to reduces minimap buttons and makes them accessible through a menu!
	
	Author: karlsnyder
	
	Previous Authors: Tunhadil, Fixed by Pericles for patch 2.23 til 4.0, fixed by yossa for patch 4.0.1, updated for 4.2+ by karlsnyder
	
]]

local function MBB_GetMetadata(field)
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata("MBB", field);
	elseif GetAddOnMetadata then
		return GetAddOnMetadata("MBB", field);
	end
	return nil;
end

-- 3.3.5a port: there is no "BackdropTemplate" on this client (frames have
-- SetBackdrop natively), and widgets have no SetEnabled().
local MBB_BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil;

function MBB_SetEnabled(widget, enabled)
	if widget.SetEnabled then
		widget:SetEnabled(enabled);
	elseif enabled then
		widget:Enable();
	else
		widget:Disable();
	end
end

-- 3.3.5a port: InCombatLockdown() only turns true after PLAYER_REGEN_DISABLED has
-- been handled, so windows refreshed by that event kept their controls enabled.
-- Track the events too; this frame is created before every other MBB frame, so
-- it sees them first.
local MBB_CombatStarted = false;
do
	local combatWatch = CreateFrame("Frame");
	combatWatch:RegisterEvent("PLAYER_REGEN_DISABLED");
	combatWatch:RegisterEvent("PLAYER_REGEN_ENABLED");
	combatWatch:SetScript("OnEvent", function(self, event)
		MBB_CombatStarted = (event == "PLAYER_REGEN_DISABLED");
	end);
end

function MBB_IsInCombat()
	if MBB_CombatStarted then return true; end
	return (InCombatLockdown and InCombatLockdown()) and true or false;
end

local rawVersion = MBB_GetMetadata("Version")
local sourceVersion = "v2.0.0"

-- @project-version@ is replaced only in packaged releases. When the addon is
-- installed directly from the source tree, do not accidentally read the
-- historical "based on 4.0.26" number as the current MBB version.
if type(rawVersion) == "string" and not rawVersion:find("@project%-version@") then
	MBB_Version = rawVersion:match("([vV]?%d+%.%d+%.%d+[%w%.%-]*)") or sourceVersion
else
	MBB_Version = sourceVersion
end

MBB_CREDITS = {
    "Original authors:",
    "  karlsnyder",
    "  vallantv",
    "  SkunFly",
    "",
    "Maintained by:",
    "  GrazyMonster",
}

-- Setup some variable for debugging.
MBB_DebugFlag = 0;
MBB_DebugInfo = {};

MBB_DragFlag = 0;
MBB_ShowTimeout = -1;
MBB_CheckTime = 0;
MBB_IsShown = 0;
MBB_FuBar_MinimapContainer = "FuBarPlugin-MinimapContainer-2.0";

MBB_Buttons = {};
MBB_Exclude = {};

MBB_DefaultOptions = {
	["ButtonPos"] = {-18, -100},
	["AttachToMinimap"] = 1,
	["DetachedButtonPos"] = "CENTER",
	["CollapseTimeout"] = 1,
	["ExpandDirection"] = 1,
	["MaxButtonsPerLine"] = 0,
	["AltExpandDirection"] = 4,
	["ButtonScale"] = 1.0,
	["DetachedButtonLocked"] = 0,
	["SnapToScreenEdges"] = 0,
	["ShowTooltip"] = 1, -- 3.3.5a port: tooltip of the MBB button on/off
	["OptionsFramePos"] = {"CENTER", "CENTER", 0, 0}
};


BACKDROP_MAXBUTTONS_OPTIONS = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	--tileEdge = true,
	tileSize = 8,
	edgeSize = 8
};

BACKDROP_TOOLTIP_OPTIONS = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
};

-- Buttons to force include
MBB_Include = {
	[1] = "BagSync_MinimapButton" -- doesn't have de OnClick script
};

-- Button names to always ignore.
MBB_Ignore = {
	[1] = "MiniMapTrackingFrame",
	[2] = "MiniMapMeetingStoneFrame",
	[3] = "MiniMapMailFrame",
	[4] = "MiniMapBattlefieldFrame",
	[5] = "MiniMapWorldMapButton",
	[6] = "MiniMapPing",
	[7] = "MinimapBackdrop",
	[8] = "MinimapZoomIn",
	[9] = "MinimapZoomOut",
	[10] = "BookOfTracksFrame",
	[11] = "GatherNote",
	[12] = "FishingExtravaganzaMini",
	[13] = "MiniNotePOI",
	[14] = "RecipeRadarMinimapIcon",
	[15] = "FWGMinimapPOI",
	[16] = "CartographerNotesPOI",
	[17] = "MBB_MinimapButtonFrame",
	[18] = "EnhancedFrameMinimapButton",
	[19] = "GFW_TrackMenuFrame",
	[20] = "GFW_TrackMenuButton",
	[21] = "TDial_TrackingIcon",
	[22] = "TDial_TrackButton",
	[23] = "MiniMapTracking",
	[24] = "GatherMatePin",
	[25] = "HandyNotesPin",
	[26] = "TimeManagerClockButton",
	[27] = "GameTimeFrame",
	[28] = "DA_Minimap",
	[29] = "ElvConfigToggle",
	[30] = "MiniMapInstanceDifficulty",
	[31] = "MinimapZoneTextButton",
	[32] = "GuildInstanceDifficulty",
	[33] = "MiniMapVoiceChatFrame",
	[34] = "MiniMapRecordingButton",
	[35] = "QueueStatusMinimapButton",
	[36] = "GatherArchNote",
	[37] = "ZGVMarker",
	[38] = "QuestPointerPOI",	-- QuestPointer
	[39] = "poiMinimap",	-- QuestPointer
	[40] = "MiniMapLFGFrame",    -- LFG
	[41] = "PremadeFilter_MinimapButton",    -- PreMadeFilter
	[42] = "GarrisonMinimapButton",
	[43] = "TukuiMinimapZone",
	[44] = "GPSArrow",
	[45] = "HandyNotes_.*Pin", -- Handy Notes plugins support,
	[46] = "DugisArrowMinimapPoint1",  --Dugi Guides arrow
	[47] = "DugisArrowMinimapPoint2",  --Dugi Guides arrow
	[48] = "DugisArrowMinimapPoint3",  --Dugi Guides arrow
	[49] = "TTMinimapButton", -- Tom tom / Wow-pro guides
	[50] = "QueueStatusButton", -- ElvUI Queue Button
	[51] = "MinimapPing", -- 3.3.5a name of the ping frame
	[52] = "QuestieFrame" -- Questie map pins (QuestieFrameGroup, QuestieFrameN)
};

MBB_IgnoreSize = {
	[1] = "AM_MinimapButton",
	[2] = "STC_HealthstoneButton",
	[3] = "STC_ShardButton",
	[4] = "STC_SoulstoneButton",
	[5] = "STC_SpellstoneButton",
	[6] = "STC_FirestoneButton"
};

MBB_ExtraSize = {
	["GathererMinimapButton"] = function()
		GathererMinimapButton.mask:SetHeight(31);
		GathererMinimapButton.mask:SetWidth(31);
	end
};

function MBB_OnLoad()
--	hooksecurefunc("SecureHandlerClickTemplate_onclick", MBB_SecureOnClick);
--	hooksecurefunc("SecureHandlerClickTemplate_OnEnter", MBB_SecureOnEnter);
--	hooksecurefunc("SecureHandlerClickTemplate_OnLeave", MBB_SecureOnLeave);
	
	if( AceLibrary ) then
		if( AceLibrary:HasInstance(MBB_FuBar_MinimapContainer) ) then
			AceLibrary(MBB_FuBar_MinimapContainer).oldAddPlugin = AceLibrary(MBB_FuBar_MinimapContainer).AddPlugin;
			AceLibrary(MBB_FuBar_MinimapContainer).AddPlugin = function(...)
				local plugin = select(2, ...);
				local self = select(1, ...);
				local value = AceLibrary(MBB_FuBar_MinimapContainer):oldAddPlugin(plugin);
				local button = plugin.minimapFrame:GetName();
				local frame = _G[button]
				
				if( not frame.oshow ) then
					MBB_PrepareButton(button);
					--if( not MBB_IsExcluded(button) ) then
					if( not MBB_IsInArray(MBB_Exclude, button) ) then
						MBB_AddButton(button);
						MBB_SetPositions();
					end
				end
				
				return value;
			end
			
			AceLibrary(MBB_FuBar_MinimapContainer).oldRemovePlugin = AceLibrary(MBB_FuBar_MinimapContainer).RemovePlugin;
			AceLibrary(MBB_FuBar_MinimapContainer).RemovePlugin = function(...)
				local self = select(1, ...);
				local plugin = select(2, ...);
				local button = plugin.minimapFrame:GetName();
				local frame = _G[button]
				
				if( not frame.oshow ) then
					MBB_PrepareButton(button);
				end
				
				local value = AceLibrary(MBB_FuBar_MinimapContainer):oldRemovePlugin(plugin);
				return value;
			end
		end
	end
	
	MBBFrame:RegisterEvent("ADDON_LOADED");
	SLASH_MBB1 = "/mbb";
	SLASH_MBB2 = "/minimapbuttonbag";
	SLASH_MBB3 = "/mmbb";
	SlashCmdList["MBB"] = MBB_SlashHandler;
end

function MBB_SlashHandler(cmd)
	if( cmd == "buttons" ) then
		MBB_Print("MBB Buttons:")

		if( #MBB_Buttons > 0 ) then
			for i, name in ipairs(MBB_Buttons) do
				MBB_Print("  " .. name)
			end
		else
			MBB_Print("No Minimap buttons are currently stored.")
		end

	elseif( cmd == "about" ) then
		-- Localized About
		MBB_Print(MBB_ABOUT_TITLE or "MinimapButtonBag Reborn")
		MBB_Print((MBB_ABOUT_VERSION or "Version:") .. " " .. MBB_Version .. " " .. (MBB_ABOUT_BASED_ON or "(based on 4.0.26)"))
		MBB_Print("")

		for _, line in ipairs(MBB_CREDITS) do
			MBB_Print(line)
		end

	elseif( cmd == "patch" ) then
		MBB_ShowPatchStatus()
		
	elseif( cmd == "manager" ) then
		MBB_ButtonManager_Toggle()

	elseif( cmd == "profile" or cmd == "profiles" ) then
		MBB_ProfileManager_Toggle()

	elseif( cmd == "rescan" ) then
		MBB_Rescan()
	
	elseif( string.sub(cmd, 1, 6) == "debug " ) then
		local _, _, sFrame = string.find(cmd, "debug (.+)")
		local hasClick, hasMouseUp, hasMouseDown, hasEnter, hasLeave = MBB_TestFrame(sFrame)

		MBB_Debug("Frame: " .. sFrame)
		if( hasClick ) then MBB_Debug("  has OnClick script") else MBB_Debug("  has no OnClick script") end
		if( hasMouseUp ) then MBB_Debug("  has OnMouseUp script") else MBB_Debug("  has no OnMouseUp script") end
		if( hasMouseDown ) then MBB_Debug("  has OnMouseDown script") else MBB_Debug("  has no OnMouseDown script") end
		if( hasEnter ) then MBB_Debug("  has OnEnter script") else MBB_Debug("  has no OnEnter script") end
		if( hasLeave ) then MBB_Debug("  has OnLeave script") else MBB_Debug("  has no OnLeave script") end

	elseif( cmd == "reset position" ) then
		MBB_ResetButtonPosition()

	elseif( cmd == "reset all" ) then
		MBB_GlobalOptions = MBB_CopyOptions(MBB_DefaultOptions);
		MBB_Options = MBB_GlobalOptions;
		if type(MBB_DB) ~= "table" then MBB_DB = {}; end
		MBB_DB.ButtonOrder = {};
		MBB_DB.Profiles = nil;
		MBB_DB.ActiveProfile = nil;
		MBB_Profile_EnsureStore();
		-- 3.3.5a fix: EnsureStore puts a copy of the options in the new Default
		-- profile. Use that table as the live one, or the next ADDON_LOADED (any
		-- load-on-demand Blizzard window) brings the copy back and undoes changes.
		MBB_Options = MBB_DB.Profiles[MBB_DB.ActiveProfile].options;
		MBB_GlobalOptions = MBB_Options;
		MBB_ResetButtonPosition()
		if MBB_OptionsFrame then
			MBB_RestoreOptionsFramePosition()
		end

		-- 3.3.5a fix: MBB_AddButton removes the name from MBB_Exclude, so walk a
		-- copy (the old loop skipped every other name and then passed nil). Names
		-- MBB never prepared (addon disabled, button moved off the minimap) are
		-- only taken off the list; the next scan bags them if they come back.
		local pending = {};
		for _, name in ipairs(MBB_Exclude) do table.insert(pending, name); end
		for _, name in ipairs(pending) do
			local f = (type(name) == "string") and _G[name];
			if( type(f) == "table" and f.oshow and f.GetPoint and not MBB_IsInArray(MBB_Buttons, name) ) then
				MBB_AddButton(name); -- also takes it off MBB_Exclude
			else
				local idx = MBB_IsInArray(MBB_Exclude, name);
				if( idx ) then table.remove(MBB_Exclude, idx); end
			end
		end

		MBB_SetPositions()

	elseif( cmd == "errors" ) then
		if( table.maxn(MBB_DebugInfo) > 0 ) then
			for name, arr in pairs(MBB_DebugInfo) do
				MBB_Print(name)
				for _, error in pairs(arr) do
					MBB_Print("  " .. error)
				end
			end
		else
			MBB_Print(MBB_NOERRORS)
		end

	else
		MBB_Print("MBB " .. MBB_Version .. ":")
		MBB_Print(MBB_HELP1)
		MBB_Print(MBB_HELP2)
		MBB_Print(MBB_HELP3)
		MBB_Print(MBB_HELP4)

		-- Localized help additions (fallback to English if not present)
		MBB_Print(MBB_HELP_ABOUT or "  |c00ffffffabout|r: Shows addon info (version & credits)")
		MBB_Print(MBB_HELP_PATCH or "  |c00ffffffpatch|r: Shows patch compatibility status")
		MBB_Print(MBB_HELP_RESCAN or "  |c00ffffffrescan|r: Rescans the minimap for missing buttons")
		MBB_Print(MBB_HELP_MANAGER or "  |c00ffffffmanager|r: Opens the minimap button manager")
		MBB_Print(MBB_HELP_PROFILE or "  |c00ffffffprofiles|r: Opens the profile manager")
	end
end



-- ---------------------------------------------------------------------------
-- MBB Reborn 2.0 - Button Manager
-- ---------------------------------------------------------------------------
-- The manager deliberately uses only long-established WoW UI templates so it
-- can be shared by Retail and the supported Classic clients.

-- ---------------------------------------------------------------------------
-- MBB Reborn 2.0 - Profiles
-- ---------------------------------------------------------------------------
-- Profiles are account-wide. They store general layout/options and the
-- collected-button order. The exclude list intentionally remains per character.

local MBB_ButtonOrder_GetStore;
local MBB_ButtonOrder_ApplyToCollected;

local MBB_PROFILE_DEFAULT_NAME = "Default";

local function MBB_Profile_CopyTable(source)
    local copy = {};
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = MBB_Profile_CopyTable(value);
        else
            copy[key] = value;
        end
    end
    return copy;
end

local function MBB_Profile_CopyArray(source)
    local copy = {};
    for index, value in ipairs(source or {}) do
        copy[index] = value;
    end
    return copy;
end

function MBB_Profile_EnsureStore()
    if type(MBB_DB) ~= "table" then
        MBB_DB = {};
    end

    if type(MBB_DB.Profiles) ~= "table" then
        local initialOptions;
        if type(MBB_GlobalOptions) == "table" then
            initialOptions = MBB_Profile_CopyTable(MBB_GlobalOptions);
        elseif type(MBB_Options) == "table" then
            initialOptions = MBB_Profile_CopyTable(MBB_Options);
        else
            initialOptions = MBB_Profile_CopyTable(MBB_DefaultOptions);
        end

        MBB_DB.Profiles = {
            [MBB_PROFILE_DEFAULT_NAME] = {
                options = initialOptions,
                buttonOrder = MBB_Profile_CopyArray(MBB_DB.ButtonOrder or {}),
            },
        };
        MBB_DB.ActiveProfile = MBB_PROFILE_DEFAULT_NAME;
    end

    if type(MBB_DB.Profiles[MBB_PROFILE_DEFAULT_NAME]) ~= "table" then
        MBB_DB.Profiles[MBB_PROFILE_DEFAULT_NAME] = {
            options = MBB_Profile_CopyTable(MBB_DefaultOptions),
            buttonOrder = {},
        };
    end

    for _, profile in pairs(MBB_DB.Profiles) do
        if type(profile.options) ~= "table" then
            profile.options = MBB_Profile_CopyTable(MBB_DefaultOptions);
        end
        if type(profile.buttonOrder) ~= "table" then
            profile.buttonOrder = {};
        end
    end

    if type(MBB_DB.ActiveProfile) ~= "string" or not MBB_DB.Profiles[MBB_DB.ActiveProfile] then
        MBB_DB.ActiveProfile = MBB_PROFILE_DEFAULT_NAME;
    end
end

local function MBB_Profile_GetActiveData()
    MBB_Profile_EnsureStore();
    return MBB_DB.Profiles[MBB_DB.ActiveProfile], MBB_DB.ActiveProfile;
end

local function MBB_Profile_GetDisplayName(name)
    if name == MBB_PROFILE_DEFAULT_NAME then
        return MBB_PROFILE_DEFAULT_DISPLAY or "Default";
    end
    return tostring(name or "");
end

function MBB_Profile_GetActiveDisplayName()
    MBB_Profile_EnsureStore();
    return MBB_Profile_GetDisplayName(MBB_DB.ActiveProfile);
end

-- 3.3.5a fix: set once MBB_OnEvent has run, i.e. after the SavedVariables are
-- loaded. Building the profile store before that hid a classic MBB's settings.
local MBB_VarsReady = false;

-- Quick profile selector used directly in the main settings window.
-- The legacy UIDropDownMenu API is available across all WoW clients supported
-- by MBB and keeps the selector consistent with Blizzard UI controls.
function MBB_ProfileDropdown_Refresh()
    if not MBB_OptionsFrame_ProfileDropDown then return; end
    if not MBB_VarsReady then return; end -- 3.3.5a fix: see MBB_VarsReady
    MBB_Profile_EnsureStore();

    local displayName = MBB_Profile_GetDisplayName(MBB_DB.ActiveProfile);
    if UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(MBB_OptionsFrame_ProfileDropDown, displayName);
    end
    -- 3.3.5a fix: UIDropDownMenu_SetSelectedValue also refreshes DropDownList1,
    -- whichever menu has it open (tracking, unit menus), and this runs at every
    -- combat start and end. MBB's own menu sets info.checked, so only the
    -- dropdown's fields are needed (what SetSelectedValue sets).
    local dd = MBB_OptionsFrame_ProfileDropDown;
    dd.selectedName = nil;
    dd.selectedID = nil;
    dd.selectedValue = MBB_DB.ActiveProfile;

    local locked = MBB_IsInCombat();
    if locked then
        if UIDropDownMenu_DisableDropDown then UIDropDownMenu_DisableDropDown(MBB_OptionsFrame_ProfileDropDown); end
    else
        if UIDropDownMenu_EnableDropDown then UIDropDownMenu_EnableDropDown(MBB_OptionsFrame_ProfileDropDown); end
    end
end

function MBB_ProfileDropdown_Initialize(self, level)
    if level and level ~= 1 then return; end
    if not MBB_VarsReady then return; end -- 3.3.5a fix: see MBB_VarsReady
    MBB_Profile_EnsureStore();
    if not UIDropDownMenu_CreateInfo or not UIDropDownMenu_AddButton then return; end

    for _, name in ipairs(MBB_Profile_GetNames()) do
        local info = UIDropDownMenu_CreateInfo();
        info.text = MBB_Profile_GetDisplayName(name);
        info.value = name;
        info.checked = (name == MBB_DB.ActiveProfile);
        info.func = function(_, selectedName)
            if MBB_Profile_Activate(selectedName) then
                MBB_ProfileDropdown_Refresh();
            end
            if CloseDropDownMenus then CloseDropDownMenus(); end
        end;
        info.arg1 = name;
        UIDropDownMenu_AddButton(info, level or 1);
    end
end

function MBB_Profile_GetNames()
    MBB_Profile_EnsureStore();
    local names = {};
    for name in pairs(MBB_DB.Profiles) do
        if name ~= MBB_PROFILE_DEFAULT_NAME then
            table.insert(names, name);
        end
    end
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b);
    end);
    table.insert(names, 1, MBB_PROFILE_DEFAULT_NAME);
    return names;
end

local function MBB_Profile_FindNameCaseInsensitive(name)
    if type(name) ~= "string" then return nil; end
    local wanted = string.lower(name);
    for existing in pairs(MBB_DB.Profiles or {}) do
        if string.lower(existing) == wanted then
            return existing;
        end
    end
    return nil;
end

local function MBB_Profile_RefreshOptionsWindow()
    if MBB_OptionsFrame and MBB_OptionsFrame:IsShown() then
        -- Existing controls populate themselves in OnShow. Re-showing is the
        -- safest shared-client way to refresh every radio/slider/edit box.
        MBB_OptionsFrame:Hide();
        MBB_OptionsFrame:Show();
    elseif MBB_ProfileDropdown_Refresh then
        MBB_ProfileDropdown_Refresh();
    end
end

function MBB_Profile_Activate(name, quiet)
    MBB_Profile_EnsureStore();
    if type(name) ~= "string" or not MBB_DB.Profiles[name] then return false; end

    if MBB_IsInCombat() then
        MBB_Print(MBB_PROFILE_COMBAT or "MBB: Profiles cannot be changed during combat.");
        return false;
    end

    local oldProfile = MBB_DB.Profiles[MBB_DB.ActiveProfile];
    local currentWindowPos = MBB_Options and MBB_Options.OptionsFramePos;
    if oldProfile and type(MBB_Options) == "table" then
        oldProfile.options = MBB_Profile_CopyTable(MBB_Options);
    end

    MBB_DB.ActiveProfile = name;
    local profile = MBB_DB.Profiles[name];
    MBB_GlobalOptions = MBB_Profile_CopyTable(profile.options);

    -- The settings-window location is UI chrome, not a gameplay profile
    -- preference. Keep the current window location while changing profiles.
    if type(currentWindowPos) == "table" then
        MBB_GlobalOptions.OptionsFramePos = MBB_Profile_CopyTable(currentWindowPos);
    end

    for opt, val in pairs(MBB_DefaultOptions) do
        if MBB_GlobalOptions[opt] == nil then
            if type(val) == "table" then
                MBB_GlobalOptions[opt] = MBB_Profile_CopyTable(val);
            else
                MBB_GlobalOptions[opt] = val;
            end
        end
    end

    MBB_Options = MBB_GlobalOptions;
    profile.options = MBB_Options;
    MBB_DB.ButtonOrder = MBB_Profile_CopyArray(profile.buttonOrder or {});

    if MBB_SetButtonPosition then MBB_SetButtonPosition(); end
    if MBB_ButtonOrder_ApplyToCollected then MBB_ButtonOrder_ApplyToCollected(); end
    if MBB_SetPositions then MBB_SetPositions(); end
    if MBB_ButtonManager_Refresh then MBB_ButtonManager_Refresh(); end
    if MBB_ProfileManager_Refresh then MBB_ProfileManager_Refresh(); end
    MBB_Profile_RefreshOptionsWindow();

    if not quiet then
        MBB_Print(string.format(MBB_PROFILE_APPLIED or "MBB: Profile '%s' activated.", MBB_Profile_GetDisplayName(name)));
    end
    return true;
end

function MBB_Profile_Create(name)
    MBB_Profile_EnsureStore();
    name = tostring(name or "");
    name = name:gsub("^%s+", ""):gsub("%s+$", "");

    if name == "" or #name > 32 then
        MBB_Print(MBB_PROFILE_INVALID or "MBB: Please enter a profile name between 1 and 32 characters.");
        return false;
    end
    if MBB_Profile_FindNameCaseInsensitive(name) then
        MBB_Print(string.format(MBB_PROFILE_EXISTS or "MBB: A profile named '%s' already exists.", name));
        return false;
    end

    local currentOrder = {};
    if MBB_ButtonOrder_GetStore then
        currentOrder = MBB_Profile_CopyArray(MBB_ButtonOrder_GetStore());
    elseif type(MBB_DB.ButtonOrder) == "table" then
        currentOrder = MBB_Profile_CopyArray(MBB_DB.ButtonOrder);
    end

    MBB_DB.Profiles[name] = {
        options = MBB_Profile_CopyTable(MBB_Options or MBB_DefaultOptions),
        buttonOrder = currentOrder,
    };

    MBB_Profile_Activate(name, true);
    MBB_ProfileManager_SelectedName = name;
    MBB_Print(string.format(MBB_PROFILE_CREATED or "MBB: Profile '%s' created.", name));
    if MBB_ProfileManager_Refresh then MBB_ProfileManager_Refresh(); end
    return true;
end

function MBB_Profile_Delete(name)
    MBB_Profile_EnsureStore();
    if name == MBB_PROFILE_DEFAULT_NAME then
        MBB_Print(MBB_PROFILE_DELETE_DEFAULT or "MBB: The Default profile cannot be deleted.");
        return false;
    end
    if not MBB_DB.Profiles[name] then return false; end

    if MBB_DB.ActiveProfile == name then
        if not MBB_Profile_Activate(MBB_PROFILE_DEFAULT_NAME, true) then
            return false;
        end
    end

    MBB_DB.Profiles[name] = nil;
    MBB_ProfileManager_SelectedName = MBB_DB.ActiveProfile;
    MBB_Print(string.format(MBB_PROFILE_DELETED or "MBB: Profile '%s' deleted.", name));
    if MBB_ProfileManager_Refresh then MBB_ProfileManager_Refresh(); end
    return true;
end

function MBB_Profile_Rename(oldName, newName)
    MBB_Profile_EnsureStore();
    if oldName == MBB_PROFILE_DEFAULT_NAME then
        MBB_Print(MBB_PROFILE_RENAME_DEFAULT or "MBB: The Default profile cannot be renamed.");
        return false;
    end
    if type(oldName) ~= "string" or not MBB_DB.Profiles[oldName] then return false; end

    newName = tostring(newName or "");
    newName = newName:gsub("^%s+", ""):gsub("%s+$", "");
    if newName == "" or #newName > 32 then
        MBB_Print(MBB_PROFILE_INVALID or "MBB: Please enter a profile name between 1 and 32 characters.");
        return false;
    end

    local existing = MBB_Profile_FindNameCaseInsensitive(newName);
    if existing and existing ~= oldName then
        MBB_Print(string.format(MBB_PROFILE_EXISTS or "MBB: A profile named '%s' already exists.", newName));
        return false;
    end

    if newName == oldName then return true; end

    local profile = MBB_DB.Profiles[oldName];
    MBB_DB.Profiles[oldName] = nil;
    MBB_DB.Profiles[newName] = profile;

    if MBB_DB.ActiveProfile == oldName then
        MBB_DB.ActiveProfile = newName;
    end
    MBB_ProfileManager_SelectedName = newName;

    MBB_Print(string.format(MBB_PROFILE_RENAMED or "MBB: Profile '%s' renamed to '%s'.", oldName, newName));
    if MBB_ProfileManager_Refresh then MBB_ProfileManager_Refresh(); end
    return true;
end

function MBB_Profile_Duplicate(sourceName, newName)
    MBB_Profile_EnsureStore();
    if type(sourceName) ~= "string" or not MBB_DB.Profiles[sourceName] then return false; end

    newName = tostring(newName or "");
    newName = newName:gsub("^%s+", ""):gsub("%s+$", "");
    if newName == "" or #newName > 32 then
        MBB_Print(MBB_PROFILE_INVALID or "MBB: Please enter a profile name between 1 and 32 characters.");
        return false;
    end
    if MBB_Profile_FindNameCaseInsensitive(newName) then
        MBB_Print(string.format(MBB_PROFILE_EXISTS or "MBB: A profile named '%s' already exists.", newName));
        return false;
    end

    -- Keep the active profile fully in sync before copying it.
    if sourceName == MBB_DB.ActiveProfile then
        local source = MBB_DB.Profiles[sourceName];
        -- 3.3.5a fix: keep the live table bound to the active profile. A copy
        -- here left MBB_Options cut off from it, so later changes were lost.
        if type(MBB_Options) == "table" then
            source.options = MBB_Options;
        end
        if MBB_ButtonOrder_GetStore then
            source.buttonOrder = MBB_Profile_CopyArray(MBB_ButtonOrder_GetStore());
        end
    end

    local source = MBB_DB.Profiles[sourceName];
    MBB_DB.Profiles[newName] = {
        options = MBB_Profile_CopyTable(source.options or MBB_DefaultOptions),
        buttonOrder = MBB_Profile_CopyArray(source.buttonOrder or {}),
    };

    MBB_ProfileManager_SelectedName = newName;
    MBB_Print(string.format(MBB_PROFILE_DUPLICATED or "MBB: Profile '%s' duplicated as '%s'.", MBB_Profile_GetDisplayName(sourceName), newName));
    if MBB_ProfileManager_Refresh then MBB_ProfileManager_Refresh(); end
    return true;
end

MBB_ButtonManagerRows = MBB_ButtonManagerRows or {};
MBB_ButtonManagerDragName = nil;
MBB_ButtonManagerDropIndex = nil;

MBB_ButtonOrder_GetStore = function()
    local profile = MBB_Profile_GetActiveData();
    if profile then
        if type(profile.buttonOrder) ~= "table" then
            profile.buttonOrder = {};
        end
        return profile.buttonOrder;
    end

    if type(MBB_DB) ~= "table" then MBB_DB = {}; end
    if type(MBB_DB.ButtonOrder) ~= "table" then MBB_DB.ButtonOrder = {}; end
    return MBB_DB.ButtonOrder;
end

local function MBB_ButtonOrder_EnsureName(name)
    if type(name) ~= "string" or name == "" then return end
    local order = MBB_ButtonOrder_GetStore();
    for _, storedName in ipairs(order) do
        if storedName == name then return end
    end
    table.insert(order, name);
end

local function MBB_ButtonOrder_EnsureCurrentButtons()
    for _, name in ipairs(MBB_Buttons or {}) do
        MBB_ButtonOrder_EnsureName(name);
    end
    for _, name in ipairs(MBB_Exclude or {}) do
        MBB_ButtonOrder_EnsureName(name);
    end
end

MBB_ButtonOrder_ApplyToCollected = function()
    MBB_ButtonOrder_EnsureCurrentButtons();
    local order = MBB_ButtonOrder_GetStore();
    local rank = {};
    for index, name in ipairs(order) do
        rank[name] = index;
    end
    table.sort(MBB_Buttons, function(a, b)
        local ar = rank[a] or 999999;
        local br = rank[b] or 999999;
        if ar == br then
            return string.lower(a) < string.lower(b);
        end
        return ar < br;
    end);
end

local function MBB_ButtonManager_GetKnownButtons()
    MBB_ButtonOrder_EnsureCurrentButtons();

    local present = {};
    for _, name in ipairs(MBB_Buttons or {}) do
        if type(name) == "string" and name ~= "" then present[name] = true; end
    end
    for _, name in ipairs(MBB_Exclude or {}) do
        if type(name) == "string" and name ~= "" then present[name] = true; end
    end

    local names = {};
    local seen = {};
    for _, name in ipairs(MBB_ButtonOrder_GetStore()) do
        if present[name] and not seen[name] then
            seen[name] = true;
            table.insert(names, name);
        end
    end

    local missingFromOrder = {};
    for name in pairs(present) do
        if not seen[name] then
            table.insert(missingFromOrder, name);
        end
    end
    table.sort(missingFromOrder, function(a, b)
        return string.lower(a) < string.lower(b);
    end);
    for _, name in ipairs(missingFromOrder) do
        MBB_ButtonOrder_EnsureName(name);
        table.insert(names, name);
    end

    return names;
end

local function MBB_ButtonOrder_SaveKnownOrder(names)
    local oldOrder = MBB_ButtonOrder_GetStore();
    local newOrder = {};
    local seen = {};

    for _, name in ipairs(names or {}) do
        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true;
            table.insert(newOrder, name);
        end
    end

    -- Keep entries which are currently not visible in this character's manager
    -- so another character can retain its established account-wide ordering.
    for _, name in ipairs(oldOrder) do
        if not seen[name] then
            seen[name] = true;
            table.insert(newOrder, name);
        end
    end

    local profile = MBB_Profile_GetActiveData();
    if profile then
        profile.buttonOrder = newOrder;
    end
    -- Compatibility mirror for 1.x/early-2.0 SavedVariables.
    MBB_DB.ButtonOrder = MBB_Profile_CopyArray(newOrder);
    MBB_ButtonOrder_ApplyToCollected();
    MBB_SetPositions();
end

local function MBB_ButtonOrder_Move(name, targetIndex)
    local names = MBB_ButtonManager_GetKnownButtons();
    local sourceIndex = nil;
    for index, buttonName in ipairs(names) do
        if buttonName == name then
            sourceIndex = index;
            break;
        end
    end
    if not sourceIndex then return end

    targetIndex = math.max(1, math.min(tonumber(targetIndex) or sourceIndex, #names));
    if targetIndex == sourceIndex then return end

    table.remove(names, sourceIndex);
    -- targetIndex refers to the row the user pointed at before the removal.
    -- Moving downward therefore needs the original index, while moving upward
    -- can be inserted directly at the requested row.
    if sourceIndex < targetIndex then
        targetIndex = math.min(targetIndex, #names + 1);
    end
    table.insert(names, targetIndex, name);
    MBB_ButtonOrder_SaveKnownOrder(names);
end

local function MBB_ButtonOrder_Reset()
    local names = MBB_ButtonManager_GetKnownButtons();
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b);
    end);
    MBB_ButtonOrder_SaveKnownOrder(names);
end

local function MBB_ButtonManager_IsInCombat()
    return MBB_IsInCombat();
end

local function MBB_ButtonManager_SetManaged(name, managed)
    if MBB_ButtonManager_IsInCombat() then
        MBB_Print(MBB_MANAGER_COMBAT or "MBB: Button management is disabled during combat.");
        return;
    end

    local button = _G[name];
    if not button then
        return;
    end
    -- 3.3.5a fix: only frames MBB has prepared (an excluded button can have left
    -- the minimap since); a bagged unprepared frame broke closing the bag.
    if not button.oshow then return end

    MBB_ButtonOrder_EnsureName(name);

    if managed then
        if not MBB_IsInArray(MBB_Buttons, name) then
            MBB_AddButton(name);
        end
    else
        if MBB_IsInArray(MBB_Buttons, name) then
            MBB_RestoreButton(name);
        end
    end

    MBB_ButtonOrder_ApplyToCollected();
    MBB_SetPositions();
end

local function MBB_ButtonManager_FinishDrag()
    local name = MBB_ButtonManagerDragName;
    local targetIndex = MBB_ButtonManagerDropIndex;
    MBB_ButtonManagerDragName = nil;
    MBB_ButtonManagerDropIndex = nil;

    if name and targetIndex and not MBB_ButtonManager_IsInCombat() then
        MBB_ButtonOrder_Move(name, targetIndex);
    end

    if MBB_ButtonManager_Refresh then
        MBB_ButtonManager_Refresh();
    end
end

local function MBB_ButtonManager_ShortenName(name)
    name = tostring(name or "")
    -- Frame names are normally ASCII. Keep the list compact and show the full
    -- value in the tooltip when a name is longer than the visual panel.
    local maxChars = 27
    if #name > maxChars then
        return name:sub(1, maxChars - 3) .. "..."
    end
    return name
end

local function MBB_ButtonManager_SetNameBoxState(row, state)
    if not row or not row.nameBox or not row.nameBox.SetBackdropColor then return end

    if state == "managed" then
        -- Soft green: collected by MBB.
        row.nameBox:SetBackdropColor(0.06, 0.20, 0.09, 0.92)
        row.nameBox:SetBackdropBorderColor(0.28, 0.68, 0.34, 0.95)
    elseif state == "minimap" then
        -- Soft blue: currently left on the minimap.
        row.nameBox:SetBackdropColor(0.07, 0.12, 0.22, 0.92)
        row.nameBox:SetBackdropBorderColor(0.30, 0.48, 0.78, 0.95)
    elseif state == "missing" then
        -- Muted red: known, but the frame is not currently loaded.
        row.nameBox:SetBackdropColor(0.22, 0.06, 0.06, 0.88)
        row.nameBox:SetBackdropBorderColor(0.60, 0.24, 0.24, 0.95)
    elseif state == "combat" then
        row.nameBox:SetBackdropColor(0.14, 0.14, 0.14, 0.88)
        row.nameBox:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.90)
    else
        row.nameBox:SetBackdropColor(0.10, 0.10, 0.10, 0.90)
        row.nameBox:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.90)
    end
end

local function MBB_ButtonManager_CreateRow(index)
    local content = MBB_ButtonManagerScrollChild;
    if not content then return nil end

    local row = CreateFrame("Frame", nil, content);
    row:SetHeight(28);
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((index - 1) * 28));
    row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((index - 1) * 28));
    row:EnableMouse(true);
    row:RegisterForDrag("LeftButton");

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate");
    row.check:SetPoint("LEFT", row, "LEFT", 2, 0);

    row.dragText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    row.dragText:SetPoint("LEFT", row.check, "RIGHT", 0, 0);
    row.dragText:SetWidth(18);
    row.dragText:SetText("::");

    -- Button name panel: gives every entry a clearer, button-like visual target
    -- while keeping the whole row available for drag-and-drop.
    row.nameBox = CreateFrame("Frame", nil, row, MBB_BACKDROP_TEMPLATE);
    row.nameBox:SetSize(184, 22);
    row.nameBox:SetPoint("LEFT", row.dragText, "RIGHT", 2, 0);
    if row.nameBox.SetBackdrop then
        row.nameBox:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        });
    end

    row.nameText = row.nameBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    row.nameText:SetPoint("LEFT", row.nameBox, "LEFT", 7, 0);
    row.nameText:SetPoint("RIGHT", row.nameBox, "RIGHT", -7, 0);
    row.nameText:SetJustifyH("LEFT");
    row.nameText:SetWordWrap(false);

    row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    row.statusText:SetPoint("RIGHT", row, "RIGHT", -4, 0);
    row.statusText:SetWidth(80);
    row.statusText:SetJustifyH("RIGHT");

    row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate");
    row.down:SetSize(24, 20);
    row.down:SetPoint("RIGHT", row.statusText, "LEFT", -4, 0);
    row.down:SetText("v");

    row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate");
    row.up:SetSize(24, 20);
    row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 0);
    row.up:SetText("^");

    row.check:SetScript("OnClick", function(self)
        local currentName = row.buttonName;
        if not currentName then return end

        if MBB_ButtonManager_IsInCombat() or not _G[currentName] then
            self:SetChecked(MBB_IsInArray(MBB_Buttons, currentName) ~= nil);
            return;
        end

        MBB_ButtonManager_SetManaged(currentName, self:GetChecked() and true or false);
        MBB_ButtonManager_Refresh();
    end);

    row.up:SetScript("OnClick", function()
        if MBB_ButtonManager_IsInCombat() or not row.buttonName or row.managerIndex <= 1 then return end
        MBB_ButtonOrder_Move(row.buttonName, row.managerIndex - 1);
        MBB_ButtonManager_Refresh();
    end);

    row.down:SetScript("OnClick", function()
        local names = MBB_ButtonManager_GetKnownButtons();
        if MBB_ButtonManager_IsInCombat() or not row.buttonName or row.managerIndex >= #names then return end
        MBB_ButtonOrder_Move(row.buttonName, row.managerIndex + 1);
        MBB_ButtonManager_Refresh();
    end);

    row.up:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(MBB_MANAGER_MOVE_UP or "Move up", 1, 1, 1);
        GameTooltip:Show();
    end);
    row.up:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    row.down:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(MBB_MANAGER_MOVE_DOWN or "Move down", 1, 1, 1);
        GameTooltip:Show();
    end);
    row.down:SetScript("OnLeave", function() GameTooltip:Hide(); end);

    row:SetScript("OnDragStart", function(self)
        if MBB_ButtonManager_IsInCombat() or not self.buttonName then return end
        MBB_ButtonManagerDragName = self.buttonName;
        MBB_ButtonManagerDropIndex = self.managerIndex;
        GameTooltip:Hide();
        self.nameText:SetTextColor(1, 0.82, 0);
    end);
    row:SetScript("OnDragStop", function()
        MBB_ButtonManager_FinishDrag();
    end);

    row:SetScript("OnEnter", function(self)
        if MBB_ButtonManagerDragName then
            MBB_ButtonManagerDropIndex = self.managerIndex;
            self.nameText:SetTextColor(1, 0.82, 0);
            return;
        end
        if not self.buttonName then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.buttonName, 1, 1, 1);
        GameTooltip:AddLine(MBB_MANAGER_DRAG_HINT or "Drag this row to change its position.", nil, nil, nil, true);
        if MBB_IsInArray(MBB_Buttons, self.buttonName) then
            GameTooltip:AddLine(MBB_MANAGER_TOOLTIP_INCLUDED or "Checked: this button is collected inside MBB.", nil, nil, nil, true);
        else
            GameTooltip:AddLine(MBB_MANAGER_TOOLTIP_EXCLUDED or "Unchecked: this button stays on the minimap.", nil, nil, nil, true);
        end
        GameTooltip:Show();
    end);
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide();
        if not MBB_ButtonManagerDragName then
            self.nameText:SetTextColor(1, 1, 1);
        end
    end);

    MBB_ButtonManagerRows[index] = row;
    return row;
end

function MBB_ButtonManager_Refresh()
    if not MBB_ButtonManagerFrame or not MBB_ButtonManagerScrollChild then return end

    local names = MBB_ButtonManager_GetKnownButtons();
    local inCombat = MBB_ButtonManager_IsInCombat();

    if MBB_ButtonManagerCountText then
        MBB_ButtonManagerCountText:SetText(string.format(MBB_MANAGER_COUNT or "%d known buttons", #names));
    end

    if MBB_ButtonManagerCombatText then
        if inCombat then
            MBB_ButtonManagerCombatText:SetText(MBB_MANAGER_COMBAT or "Button management is disabled during combat.");
            MBB_ButtonManagerCombatText:Show();
        else
            MBB_ButtonManagerCombatText:Hide();
        end
    end

    if MBB_ButtonManagerEmptyText then
        if #names == 0 then
            MBB_ButtonManagerEmptyText:SetText(MBB_MANAGER_EMPTY or "No buttons detected yet. Use Rescan.");
            MBB_ButtonManagerEmptyText:Show();
        else
            MBB_ButtonManagerEmptyText:Hide();
        end
    end

    for index, name in ipairs(names) do
        local row = MBB_ButtonManagerRows[index] or MBB_ButtonManager_CreateRow(index);
        if row then
            local button = _G[name];
            local managed = MBB_IsInArray(MBB_Buttons, name) ~= nil;

            row.buttonName = name;
            row.managerIndex = index;
            row.nameText:SetText(MBB_ButtonManager_ShortenName(name));
            row.check:SetChecked(managed);
            row.nameText:SetTextColor(1, 1, 1);
            MBB_ButtonManager_SetNameBoxState(row, managed and "managed" or "minimap");

            if not button or not button.oshow then -- 3.3.5a fix: unprepared frames count as missing
                row.statusText:SetText(MBB_MANAGER_MISSING or "Not loaded");
                row.check:Disable();
                row.up:Disable();
                row.down:Disable();
                row.nameText:SetTextColor(0.70, 0.70, 0.70);
                MBB_ButtonManager_SetNameBoxState(row, "missing");
            elseif inCombat then
                row.statusText:SetText(managed and (MBB_MANAGER_ENABLED or "In MBB") or (MBB_MANAGER_DISABLED or "On Minimap"));
                row.check:Disable();
                row.up:Disable();
                row.down:Disable();
                row.nameText:SetTextColor(0.78, 0.78, 0.78);
                MBB_ButtonManager_SetNameBoxState(row, "combat");
            else
                row.statusText:SetText(managed and (MBB_MANAGER_ENABLED or "In MBB") or (MBB_MANAGER_DISABLED or "On Minimap"));
                row.check:Enable();
                if index > 1 then row.up:Enable(); else row.up:Disable(); end
                if index < #names then row.down:Enable(); else row.down:Disable(); end
            end

            row:Show();
        end
    end

    for index = #names + 1, #MBB_ButtonManagerRows do
        MBB_ButtonManagerRows[index]:Hide();
    end

    MBB_ButtonManagerScrollChild:SetHeight(math.max(#names * 28, 1));
end

function MBB_ButtonManager_Create()
    if MBB_ButtonManagerFrame then return end

    local frame = CreateFrame("Frame", "MBB_ButtonManagerFrame", UIParent, MBB_BACKDROP_TEMPLATE);
    frame:SetSize(460, 485);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    -- Keep the Button Manager above the movable settings window.
    -- FULLSCREEN_DIALOG is intentionally used here because the settings frame is DIALOG/toplevel.
    frame:SetFrameStrata("FULLSCREEN_DIALOG");
    frame:SetToplevel(true);
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); end);
    if frame.SetBackdrop then
        frame:SetBackdrop(BACKDROP_TOOLTIP_OPTIONS);
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOP", frame, "TOP", 0, -18);
    title:SetText(MBB_MANAGER_TITLE or "Button Manager");

    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    desc:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -48);
    desc:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -48);
    desc:SetJustifyH("LEFT");
    desc:SetText(MBB_MANAGER_DESC or "Manage known minimap buttons. Checked buttons are collected by MBB.");

    local orderHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    orderHelp:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -68);
    orderHelp:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -68);
    orderHelp:SetJustifyH("LEFT");
    orderHelp:SetText(MBB_MANAGER_ORDER_HELP or "Drag a row or use the arrows to change the button order.");

    local countText = frame:CreateFontString("MBB_ButtonManagerCountText", "OVERLAY", "GameFontNormalSmall");
    countText:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -94);

    local combatText = frame:CreateFontString("MBB_ButtonManagerCombatText", "OVERLAY", "GameFontNormalSmall");
    combatText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -94);
    combatText:SetTextColor(1, 0.35, 0.35);
    combatText:Hide();

    local headerName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    headerName:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -118);
    headerName:SetText(MBB_MANAGER_COLUMN_BUTTON or "Button");

    local headerStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    headerStatus:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -118);
    headerStatus:SetText(MBB_MANAGER_COLUMN_STATUS or "Status");

    local scroll = CreateFrame("ScrollFrame", "MBB_ButtonManagerScrollFrame", frame, "UIPanelScrollFrameTemplate");
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -136);
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -42, 60);

    local content = CreateFrame("Frame", "MBB_ButtonManagerScrollChild", scroll);
    content:SetWidth(390);
    content:SetHeight(1);
    scroll:SetScrollChild(content);

    local emptyText = content:CreateFontString("MBB_ButtonManagerEmptyText", "OVERLAY", "GameFontHighlight");
    emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 12, -12);
    emptyText:SetWidth(350);
    emptyText:SetJustifyH("LEFT");
    emptyText:Hide();

    local rescan = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    rescan:SetSize(118, 22);
    rescan:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 22);
    rescan:SetText(MBB_MANAGER_RESCAN or "Rescan");
    rescan:SetScript("OnClick", function()
        MBB_Rescan();
        MBB_ButtonManager_Refresh();
    end);

    local resetOrder = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    resetOrder:SetSize(170, 22);
    resetOrder:SetPoint("BOTTOM", frame, "BOTTOM", 0, 22);
    resetOrder:SetText(MBB_MANAGER_RESET_ORDER or "Reset order");
    resetOrder:SetScript("OnClick", function()
        if MBB_ButtonManager_IsInCombat() then return end
        MBB_ButtonOrder_Reset();
        MBB_Print(MBB_MANAGER_RESET_ORDER_DONE or "MBB: Button order reset.");
        MBB_ButtonManager_Refresh();
    end);

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    close:SetSize(118, 22);
    close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 22);
    close:SetText(MBB_MANAGER_CLOSE or "Close");
    close:SetScript("OnClick", function() frame:Hide(); end);

    frame:RegisterEvent("PLAYER_REGEN_DISABLED");
    frame:RegisterEvent("PLAYER_REGEN_ENABLED");
    frame:SetScript("OnEvent", function() MBB_ButtonManager_Refresh(); end);
    frame:SetScript("OnShow", function(self)
        -- A toplevel settings frame may raise itself when clicked/moved.
        -- Explicitly raise the manager whenever it is shown so it always stays in front.
        if MBB_OptionsFrame then
            local optionsLevel = MBB_OptionsFrame:GetFrameLevel() or 1;
            if self:GetFrameLevel() <= optionsLevel then
                self:SetFrameLevel(optionsLevel + 20);
            end
        end
        if self.Raise then
            self:Raise();
        end

        MBB_ButtonOrder_ApplyToCollected();
        MBB_SetPositions();
        MBB_ButtonManager_Refresh();
    end);

    if UISpecialFrames then
        local found = false;
        for _, name in ipairs(UISpecialFrames) do
            if name == "MBB_ButtonManagerFrame" then
                found = true;
                break;
            end
        end
        if not found then
            table.insert(UISpecialFrames, "MBB_ButtonManagerFrame");
        end
    end

    frame:Hide();
end

function MBB_ButtonManager_Open()
    MBB_ButtonManager_Create();
    if MBB_ProfileManagerFrame then MBB_ProfileManagerFrame:Hide(); end
    MBB_ButtonOrder_ApplyToCollected();
    MBB_SetPositions();
    MBB_ButtonManager_Refresh();
    MBB_ButtonManagerFrame:Show();
    if MBB_ButtonManagerFrame.Raise then
        MBB_ButtonManagerFrame:Raise();
    end
end

function MBB_ButtonManager_Toggle()
    MBB_ButtonManager_Create();
    if MBB_ButtonManagerFrame:IsShown() then
        MBB_ButtonManagerFrame:Hide();
    else
        MBB_ButtonManager_Open();
    end
end


-- ---------------------------------------------------------------------------
-- MBB Reborn 2.0 - Profile Manager
-- ---------------------------------------------------------------------------

MBB_ProfileManagerRows = MBB_ProfileManagerRows or {};
MBB_ProfileManager_SelectedName = MBB_ProfileManager_SelectedName or nil;

-- 3.3.5a port: StaticPopups use the DIALOG strata, below this FULLSCREEN_DIALOG
-- window, so their buttons sat behind it. The window steps aside while a popup
-- is open and comes back when it closes.
local MBB_ProfileManager_ReturnAfterPopup = false;

local function MBB_ProfileManager_PopupOnHide()
    if MBB_ProfileManager_ReturnAfterPopup then
        MBB_ProfileManager_ReturnAfterPopup = false;
        MBB_ProfileManager_Open();
    end
end

local function MBB_ProfileManager_EnsurePopups()
    if not StaticPopupDialogs then return end

    if not StaticPopupDialogs["MBB_CREATE_PROFILE"] then
        StaticPopupDialogs["MBB_CREATE_PROFILE"] = {
            text = MBB_PROFILE_NEW_PROMPT or "Enter a name for the new profile:",
            button1 = ACCEPT,
            button2 = CANCEL,
            hasEditBox = true,
            maxLetters = 32,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnHide = MBB_ProfileManager_PopupOnHide,
            -- 3.3.5a fix: the focused edit box takes Esc; without this the pop-up stayed open
            EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
            OnShow = function(self)
                local editBox = self.editBox or _G[self:GetName() .. "EditBox"];
                if editBox then
                    editBox:SetText("");
                    editBox:SetFocus();
                end
            end,
            OnAccept = function(self)
                local editBox = self.editBox or _G[self:GetName() .. "EditBox"];
                if editBox then
                    MBB_Profile_Create(editBox:GetText());
                end
            end,
            EditBoxOnEnterPressed = function(self)
                local parent = self:GetParent();
                MBB_Profile_Create(self:GetText());
                if parent then parent:Hide(); end
            end,
        };
    end

    if not StaticPopupDialogs["MBB_DELETE_PROFILE"] then
        StaticPopupDialogs["MBB_DELETE_PROFILE"] = {
            text = MBB_PROFILE_DELETE_PROMPT or "Delete profile '%s'?",
            button1 = YES,
            button2 = NO,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnHide = MBB_ProfileManager_PopupOnHide,
            OnAccept = function(self, data)
                data = data or self.data;
                if type(data) == "string" then
                    MBB_Profile_Delete(data);
                end
            end,
        };
    end

    if not StaticPopupDialogs["MBB_RENAME_PROFILE"] then
        StaticPopupDialogs["MBB_RENAME_PROFILE"] = {
            text = MBB_PROFILE_RENAME_PROMPT or "Enter a new name for profile '%s':",
            button1 = ACCEPT,
            button2 = CANCEL,
            hasEditBox = true,
            maxLetters = 32,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnHide = MBB_ProfileManager_PopupOnHide,
            EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end, -- 3.3.5a fix: Esc closes it
            OnShow = function(self)
                local editBox = self.editBox or _G[self:GetName() .. "EditBox"];
                if editBox then
                    editBox:SetText(MBB_Profile_GetDisplayName(self.data or ""));
                    editBox:HighlightText();
                    editBox:SetFocus();
                end
            end,
            OnAccept = function(self, data)
                local oldName = data or self.data;
                local editBox = self.editBox or _G[self:GetName() .. "EditBox"];
                if oldName and editBox then MBB_Profile_Rename(oldName, editBox:GetText()); end
            end,
            EditBoxOnEnterPressed = function(self)
                local parent = self:GetParent();
                if parent and parent.data then MBB_Profile_Rename(parent.data, self:GetText()); end
                if parent then parent:Hide(); end
            end,
        };
    end

    if not StaticPopupDialogs["MBB_DUPLICATE_PROFILE"] then
        StaticPopupDialogs["MBB_DUPLICATE_PROFILE"] = {
            text = MBB_PROFILE_DUPLICATE_PROMPT or "Enter a name for the copy of profile '%s':",
            button1 = ACCEPT,
            button2 = CANCEL,
            hasEditBox = true,
            maxLetters = 32,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnHide = MBB_ProfileManager_PopupOnHide,
            EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end, -- 3.3.5a fix: Esc closes it
            OnShow = function(self)
                local editBox = self.editBox or _G[self:GetName() .. "EditBox"];
                if editBox then
                    local sourceName = self.data or "";
                    editBox:SetText(MBB_Profile_GetDisplayName(sourceName) .. " " .. (MBB_PROFILE_COPY_SUFFIX or "Copy"));
                    editBox:HighlightText();
                    editBox:SetFocus();
                end
            end,
            OnAccept = function(self, data)
                local sourceName = data or self.data;
                local editBox = self.editBox or _G[self:GetName() .. "EditBox"];
                if sourceName and editBox then MBB_Profile_Duplicate(sourceName, editBox:GetText()); end
            end,
            EditBoxOnEnterPressed = function(self)
                local parent = self:GetParent();
                if parent and parent.data then MBB_Profile_Duplicate(parent.data, self:GetText()); end
                if parent then parent:Hide(); end
            end,
        };
    end
end

local function MBB_ProfileManager_ShowPopup(which, text, data)
    MBB_ProfileManager_EnsurePopups();
    if not StaticPopup_Show then return; end
    if StaticPopup_Show(which, text, nil, data) and MBB_ProfileManagerFrame and MBB_ProfileManagerFrame:IsShown() then
        MBB_ProfileManager_ReturnAfterPopup = true;
        MBB_ProfileManagerFrame:Hide();
    end
end

local function MBB_ProfileManager_CreateRow(index)
    local child = MBB_ProfileManagerScrollChild;
    if not child then return nil; end

    local row = CreateFrame("Button", nil, child, "UIPanelButtonTemplate");
    row:SetHeight(26);
    row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -((index - 1) * 28));
    row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -((index - 1) * 28));
    row:SetScript("OnClick", function(self)
        MBB_ProfileManager_SelectedName = self.profileName;
        MBB_ProfileManager_Refresh();
    end);
    MBB_ProfileManagerRows[index] = row;
    return row;
end

function MBB_ProfileManager_Refresh()
    if not MBB_ProfileManagerFrame then return; end
    MBB_Profile_EnsureStore();

    local names = MBB_Profile_GetNames();
    if not MBB_ProfileManager_SelectedName or not MBB_DB.Profiles[MBB_ProfileManager_SelectedName] then
        MBB_ProfileManager_SelectedName = MBB_DB.ActiveProfile;
    end

    for index, name in ipairs(names) do
        local row = MBB_ProfileManagerRows[index] or MBB_ProfileManager_CreateRow(index);
        row.profileName = name;
        local label = MBB_Profile_GetDisplayName(name);
        if name == MBB_DB.ActiveProfile then
            label = label .. "  [" .. (MBB_PROFILE_ACTIVE or "Active") .. "]";
        end
        row:SetText(label);
        row:Show();
        if name == MBB_ProfileManager_SelectedName then
            row:LockHighlight();
        else
            row:UnlockHighlight();
        end
    end

    for index = #names + 1, #MBB_ProfileManagerRows do
        MBB_ProfileManagerRows[index]:Hide();
    end

    if MBB_ProfileManagerScrollChild then
        MBB_ProfileManagerScrollChild:SetHeight(math.max(1, #names * 28));
    end

    if MBB_ProfileManagerCurrent then
        MBB_ProfileManagerCurrent:SetText((MBB_PROFILE_CURRENT or "Current profile:") .. " " .. MBB_Profile_GetDisplayName(MBB_DB.ActiveProfile));
    end

    if MBB_ProfileManagerActivateButton then
        local selected = MBB_ProfileManager_SelectedName;
        MBB_SetEnabled(MBB_ProfileManagerActivateButton, selected ~= nil and selected ~= MBB_DB.ActiveProfile and not (MBB_IsInCombat()));
    end
    if MBB_ProfileManagerDeleteButton then
        local selected = MBB_ProfileManager_SelectedName;
        MBB_SetEnabled(MBB_ProfileManagerDeleteButton, selected ~= nil and selected ~= MBB_PROFILE_DEFAULT_NAME and not (MBB_IsInCombat()));
    end
    if MBB_ProfileManagerRenameButton then
        local selected = MBB_ProfileManager_SelectedName;
        MBB_SetEnabled(MBB_ProfileManagerRenameButton, selected ~= nil and selected ~= MBB_PROFILE_DEFAULT_NAME and not (MBB_IsInCombat()));
    end
    if MBB_ProfileManagerDuplicateButton then
        local selected = MBB_ProfileManager_SelectedName;
        MBB_SetEnabled(MBB_ProfileManagerDuplicateButton, selected ~= nil and not (MBB_IsInCombat()));
    end
end

function MBB_ProfileManager_Create()
    if MBB_ProfileManagerFrame then return; end
    MBB_ProfileManager_EnsurePopups();

    local frame = CreateFrame("Frame", "MBB_ProfileManagerFrame", UIParent, MBB_BACKDROP_TEMPLATE);
    frame:SetSize(410, 430);
    frame:SetPoint("CENTER");
    frame:SetFrameStrata("FULLSCREEN_DIALOG");
    frame:SetFrameLevel(50);
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); end);
    if frame.SetBackdrop then
        frame:SetBackdrop(BACKDROP_TOOLTIP_OPTIONS);
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOP", frame, "TOP", 0, -18);
    title:SetText(MBB_PROFILE_TITLE or "Profiles");

    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    desc:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -48);
    desc:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -48);
    desc:SetJustifyH("LEFT");
    desc:SetWordWrap(true);
    desc:SetText(MBB_PROFILE_DESC or "Profiles save layout, scale, position and button order. Excluded buttons remain character-specific.");

    MBB_ProfileManagerCurrent = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    MBB_ProfileManagerCurrent:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -92);

    local scroll = CreateFrame("ScrollFrame", "MBB_ProfileManagerScrollFrame", frame, "UIPanelScrollFrameTemplate");
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -118);
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -46, 126);

    local child = CreateFrame("Frame", "MBB_ProfileManagerScrollChild", scroll);
    child:SetWidth(330);
    child:SetHeight(1);
    scroll:SetScrollChild(child);

    -- Two compact action rows keep profile management clear without squeezing translations.
    MBB_ProfileManagerActivateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    MBB_ProfileManagerActivateButton:SetSize(112, 23);
    MBB_ProfileManagerActivateButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 69);
    MBB_ProfileManagerActivateButton:SetText(MBB_PROFILE_ACTIVATE or "Activate");
    MBB_ProfileManagerActivateButton:SetScript("OnClick", function()
        if MBB_ProfileManager_SelectedName then
            MBB_Profile_Activate(MBB_ProfileManager_SelectedName);
        end
    end);

    MBB_ProfileManagerNewButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    MBB_ProfileManagerNewButton:SetSize(112, 23);
    MBB_ProfileManagerNewButton:SetPoint("LEFT", MBB_ProfileManagerActivateButton, "RIGHT", 4, 0);
    MBB_ProfileManagerNewButton:SetText(MBB_PROFILE_NEW or "New");
    MBB_ProfileManagerNewButton:SetScript("OnClick", function()
        if MBB_IsInCombat() then
            MBB_Print(MBB_PROFILE_COMBAT or "MBB: Profiles cannot be changed during combat.");
            return;
        end
        MBB_ProfileManager_ShowPopup("MBB_CREATE_PROFILE");
    end);

    MBB_ProfileManagerDuplicateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    MBB_ProfileManagerDuplicateButton:SetSize(112, 23);
    MBB_ProfileManagerDuplicateButton:SetPoint("LEFT", MBB_ProfileManagerNewButton, "RIGHT", 4, 0);
    MBB_ProfileManagerDuplicateButton:SetText(MBB_PROFILE_DUPLICATE or "Duplicate");
    MBB_ProfileManagerDuplicateButton:SetScript("OnClick", function()
        local name = MBB_ProfileManager_SelectedName;
        if not name then return; end
        if MBB_IsInCombat() then
            MBB_Print(MBB_PROFILE_COMBAT or "MBB: Profiles cannot be changed during combat.");
            return;
        end
        MBB_ProfileManager_ShowPopup("MBB_DUPLICATE_PROFILE", MBB_Profile_GetDisplayName(name), name);
    end);

    MBB_ProfileManagerRenameButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    MBB_ProfileManagerRenameButton:SetSize(112, 23);
    MBB_ProfileManagerRenameButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 40);
    MBB_ProfileManagerRenameButton:SetText(MBB_PROFILE_RENAME or "Rename");
    MBB_ProfileManagerRenameButton:SetScript("OnClick", function()
        local name = MBB_ProfileManager_SelectedName;
        if not name or name == MBB_PROFILE_DEFAULT_NAME then return; end
        if MBB_IsInCombat() then
            MBB_Print(MBB_PROFILE_COMBAT or "MBB: Profiles cannot be changed during combat.");
            return;
        end
        MBB_ProfileManager_ShowPopup("MBB_RENAME_PROFILE", MBB_Profile_GetDisplayName(name), name);
    end);

    MBB_ProfileManagerDeleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    MBB_ProfileManagerDeleteButton:SetSize(112, 23);
    MBB_ProfileManagerDeleteButton:SetPoint("LEFT", MBB_ProfileManagerRenameButton, "RIGHT", 4, 0);
    MBB_ProfileManagerDeleteButton:SetText(MBB_PROFILE_DELETE or "Delete");
    MBB_ProfileManagerDeleteButton:SetScript("OnClick", function()
        local name = MBB_ProfileManager_SelectedName;
        if not name or name == MBB_PROFILE_DEFAULT_NAME then return; end
        if MBB_IsInCombat() then
            MBB_Print(MBB_PROFILE_COMBAT or "MBB: Profiles cannot be changed during combat.");
            return;
        end
        MBB_ProfileManager_ShowPopup("MBB_DELETE_PROFILE", MBB_Profile_GetDisplayName(name), name);
    end);

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    close:SetSize(112, 23);
    close:SetPoint("LEFT", MBB_ProfileManagerDeleteButton, "RIGHT", 4, 0);
    close:SetText(MBB_PROFILE_CLOSE or "Close");
    close:SetScript("OnClick", function() frame:Hide(); end);

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 14);
    hint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 14);
    hint:SetJustifyH("CENTER");
    hint:SetText(MBB_PROFILE_HINT or "New profiles start as a copy of the current profile.");

    frame:SetScript("OnShow", function(self)
        if MBB_OptionsFrame then
            local optionsLevel = MBB_OptionsFrame:GetFrameLevel() or 1;
            if self:GetFrameLevel() <= optionsLevel then
                self:SetFrameLevel(optionsLevel + 30);
            end
        end
        MBB_ProfileManager_SelectedName = MBB_ProfileManager_SelectedName or MBB_DB.ActiveProfile;
        MBB_ProfileManager_Refresh();
        if self.Raise then self:Raise(); end
    end);

    frame:RegisterEvent("PLAYER_REGEN_DISABLED");
    frame:RegisterEvent("PLAYER_REGEN_ENABLED");
    frame:SetScript("OnEvent", function()
        MBB_ProfileManager_Refresh();
    end);

    if UISpecialFrames then
        local found = false;
        for _, name in ipairs(UISpecialFrames) do
            if name == "MBB_ProfileManagerFrame" then found = true; break; end
        end
        if not found then table.insert(UISpecialFrames, "MBB_ProfileManagerFrame"); end
    end

    frame:Hide();
end

function MBB_ProfileManager_Open()
    MBB_ProfileManager_Create();
    if MBB_ButtonManagerFrame then MBB_ButtonManagerFrame:Hide(); end
    MBB_ProfileManagerFrame:Show();
    if MBB_ProfileManagerFrame.Raise then MBB_ProfileManagerFrame:Raise(); end
end

function MBB_ProfileManager_Toggle()
    MBB_ProfileManager_Create();
    if MBB_ProfileManagerFrame:IsShown() then
        MBB_ProfileManagerFrame:Hide();
    else
        MBB_ProfileManager_Open();
    end
end


function MBB_TestFrame(name)
	local hasClick = false;
	local hasMouseUp = false;
	local hasMouseDown = false;
	local hasEnter = false;
	local hasLeave = false;
	local testframe = _G[name]
	
	if( testframe ) then
		if( not testframe.HasScript ) then
			if( testframe:GetName() ) then
				if( not MBB_DebugInfo[testframe:GetName()] ) then
					MBB_DebugInfo[testframe:GetName()] = {};
				end
				if( not MBB_IsInArray(MBB_DebugInfo[testframe:GetName()], "No HasScript") ) then
					table.insert(MBB_DebugInfo[testframe:GetName()], "No HasScript");
				end
			end
		else
			if( testframe:HasScript("OnClick") ) then
				local test = testframe:GetScript("OnClick");
				if( test ) then
					hasClick = true;
				end
			end
			if( testframe:HasScript("OnMouseUp") ) then
				local test = testframe:GetScript("OnMouseUp");
				if( test ) then
					hasMouseUp = true;
				end
			end
			if( testframe:HasScript("OnMouseDown") ) then
				local test = testframe:GetScript("OnMouseDown");
				if( test ) then
					hasMouseDown = true;
				end
			end
			if( testframe:HasScript("OnEnter") ) then
				local test = testframe:GetScript("OnEnter");
				if( test ) then
					hasEnter = true;
				end
			end
			if( testframe:HasScript("OnLeave") ) then
				local test = testframe:GetScript("OnLeave");
				if( test ) then
					hasLeave = true;
				end
			end
		end
	end
	
	return hasClick, hasMouseUp, hasMouseDown, hasEnter, hasLeave;
end

function MBB_CopyOptions(source)
	local copy = {};
	for key, value in pairs(source or {}) do
		if( type(value) == "table" ) then
			copy[key] = {};
			for subkey, subvalue in pairs(value) do
				copy[key][subkey] = subvalue;
			end
		else
			copy[key] = value;
		end
	end
	return copy;
end

function MBB_OnEvent(self, event, ...)
	-- v1.0.6: migrate the current character's existing settings once, then
	-- use one account-wide option table for every character.
	if( not MBB_GlobalOptions ) then
		if( MBB_Options ) then
			MBB_GlobalOptions = MBB_CopyOptions(MBB_Options);
		else
			MBB_GlobalOptions = MBB_CopyOptions(MBB_DefaultOptions);
		end
	end

	-- Migrate the current 1.x/early-2.0 account-wide settings into the default
	-- profile once, then bind the active profile as the live options table.
	MBB_Profile_EnsureStore();
	local activeProfile = MBB_Profile_GetActiveData();
	if activeProfile and type(activeProfile.options) == "table" then
		MBB_GlobalOptions = activeProfile.options;
	end
	MBB_Options = MBB_GlobalOptions;

	for opt,val in pairs(MBB_DefaultOptions) do
		if( MBB_Options[opt] == nil ) then
			MBB_Debug(opt .. " option set to default: " .. tostring(val));
			if( type(val) == "table" ) then
				MBB_Options[opt] = MBB_CopyOptions(val);
			else
				MBB_Options[opt] = val;
			end
		else
			MBB_Debug(opt .. " option exists: " .. tostring(MBB_Options[opt]));
		end
	end
	if activeProfile then
		activeProfile.options = MBB_Options;
		MBB_DB.ButtonOrder = MBB_Profile_CopyArray(activeProfile.buttonOrder or {});
	end
	MBB_VarsReady = true; -- 3.3.5a fix: the profile dropdown may build the store now
	MBB_SetButtonPosition();
end

function MBB_PrepareButton(name)
	local buttonframe = _G[name]
	local hasHeader;
	if( buttonframe.GetAttribute ) then
		hasHeader = buttonframe:GetAttribute("anchorchild");
		if( hasHeader and hasHeader == "$parent" and not buttonframe.hasParentFrame ) then
			MBB_Debug("buttonframe has header parent");
			buttonframe.hasParentFrame = true;
		end
	else
		if( buttonframe:GetName() ) then
			if( not MBB_DebugInfo[buttonframe:GetName()] ) then
				MBB_DebugInfo[buttonframe:GetName()] = {};
			end
			if( not MBB_IsInArray(MBB_DebugInfo[buttonframe:GetName()], "No GetAttribute") ) then
				table.insert(MBB_DebugInfo[buttonframe:GetName()], "No GetAttribute");
			end
		end
	end
	
	if( buttonframe ) then
		if( buttonframe.RegisterForClicks ) then
			buttonframe:RegisterForClicks("LeftButtonDown", "RightButtonDown", "MiddleButtonDown");
		end
		
		-- 3.3.5a fix: IsShown, not IsVisible: these store what the addon set. A
		-- button whose container was already hidden (Atlas with its minimap
		-- button off) never came back to the bag when the container was shown.
		buttonframe.isvisible = buttonframe:IsShown();

		if( buttonframe.hasParentFrame ) then
			local parent = buttonframe:GetParent();
			parent.MBBChild = buttonframe:GetName();
			buttonframe.parentisvisible = parent:IsShown();
			parent.oshow = parent.Show;
			parent.Show = function(...)
				local self = select(1, ...);
				local parent = select(1, ...);
				MBB_Debug("Parent Frame: " .. parent:GetName());
				local child = _G[parent.MBBChild]
				MBB_Debug("Child Frame: " .. child:GetName());
				child.parentisvisible = true;
				MBB_Debug("Showing frame: " .. parent:GetName());
				if( not MBB_IsInArray(MBB_Exclude, child:GetName()) ) then
					MBB_SetPositions();
				end
				if( MBB_IsInArray(MBB_Exclude, child:GetName()) or MBB_IsShown == 1 ) then
					parent.oshow(select(1, ...));
					--child.oshow(child);
				end
			end
			parent.ohide = parent.Hide;
			parent.Hide = function(...)
				local parent = select(1, ...);
				MBB_Debug("Parent Frame: " .. parent:GetName());
				local child = _G[parent.MBBChild]
				MBB_Debug("Child Frame: " .. child:GetName());
				child.parentisvisible = false;
				MBB_Debug("Hiding frame: " .. parent:GetName());
				parent.ohide(select(1, ...));
				if( not MBB_IsInArray(MBB_Exclude, child:GetName()) ) then
					MBB_SetPositions();
				end
			end
			-- 3.3.5a fix: while the child is in the bag, the container is really
			-- hidden whenever the bag is closed. Report the state its addon set:
			-- Atlas's "Show Button on Minimap" uses IsVisible() to pick Show or
			-- Hide, so the option could not be turned off. (Same addon frame whose
			-- Show/Hide MBB replaces above; Blizzard frames are in MBB_Ignore.)
			parent.oisvisible = parent.IsVisible;
			parent.IsVisible = function(self)
				local c = _G[self.MBBChild];
				if( c and MBB_IsInArray(MBB_Buttons, c:GetName()) ) then
					return c.parentisvisible and 1 or nil;
				end
				return self.oisvisible(self);
			end
		end
		
		buttonframe.oshow = buttonframe.Show;
		buttonframe.Show = function(...)
			local innerframe = select(1, ...);
			innerframe.isvisible = true;
			MBB_Debug("Showing innerframe: " .. innerframe:GetName());
			if( not MBB_IsInArray(MBB_Exclude, innerframe:GetName()) ) then
				MBB_SetPositions();
			end
			if( MBB_IsInArray(MBB_Exclude, innerframe:GetName()) or MBB_IsShown == 1 ) then
				--[[if( innerframe.hasParentFrame ) then
					local parent = innerframe:GetParent();
					parent.oshow(parent);
				else]]
					innerframe.oshow(select(1, ...));
				--end
			end
		end
		buttonframe.ohide = buttonframe.Hide;
		buttonframe.Hide = function(...)
			local innerframe = select(1, ...);
			MBB_Debug("Hiding innerframe: " .. innerframe:GetName());
			-- Respect Hide() calls from the original addon (for example MDT's
			-- middle-click action) and remove the button from MBB's visible list.
			innerframe.isvisible = false;
			if( innerframe.ohide ) then
				innerframe.ohide(innerframe);
			end
			if( not MBB_IsInArray(MBB_Exclude, innerframe:GetName()) ) then
				MBB_SetPositions();
			end
		end
		
		if( buttonframe:HasScript("OnClick") and not hasHeader ) then
			buttonframe.oclick = buttonframe:GetScript("OnClick");
			buttonframe:SetScript("OnClick", function(...)
				local self = select(1, ...);
				local arg1 = select(2, ...);
				if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
					local name = self:GetName();
					if( MBB_IsInArray(MBB_Exclude, name) ) then
						MBB_AddButton(name);
					else
						MBB_RestoreButton(name);
					end
					MBB_SetPositions();
				elseif( self.oclick ) then
					self.oclick(select(1, ...));
				end
			end);
		elseif( buttonframe:HasScript("OnMouseUp") and not hasHeader ) then
			buttonframe.omouseup = buttonframe:GetScript("OnMouseUp");
			buttonframe:SetScript("OnMouseUp", function(...)
				local self = select(1, ...);
				local arg1 = select(2, ...);
				if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
					local name = self:GetName();
					if( MBB_IsInArray(MBB_Exclude, name) ) then
						MBB_AddButton(name);
					else
						MBB_RestoreButton(name);
					end
					MBB_SetPositions();
				elseif( self.omouseup ) then
					self.omouseup(select(1, ...));
				end
			end);
		elseif( buttonframe:HasScript("OnMouseDown") and not hasHeader ) then
			buttonframe.omousedown = buttonframe:GetScript("OnMouseDown");
			buttonframe:SetScript("OnMouseDown", function(...)
				local self = select(1, ...);
				local arg1 = select(2, ...);
				if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
					local name = self:GetName();
					if( MBB_IsInArray(MBB_Exclude, name) ) then
						MBB_AddButton(name);
					else
						MBB_RestoreButton(name);
					end
					MBB_SetPositions();
				elseif( self.omousedown ) then
					self.omousedown(select(1, ...));
				end
			end);
		end
		if( buttonframe:HasScript("OnEnter") and not hasHeader ) then
			buttonframe.oenter = buttonframe:GetScript("OnEnter");
			buttonframe:SetScript("OnEnter", function(...)
				local self = select(1, ...);
				if( IsControlKeyDown() ) then
					local button;
					if( MBB_IsInArray(MBB_Exclude, self:GetName()) ) then
						button = _G["MBB_ButtonAdd"]
					else
						button = _G["MBB_ButtonRemove"]
					end
					button.MBBButtonName = self:GetName();
					button:ClearAllPoints();
					button:SetPoint("BOTTOM", self, "TOP", 0, 0);
					button:Show();
				end
				if( not MBB_IsInArray(MBB_Exclude, self:GetName()) ) then
					MBB_ShowTimeout = -1;
				end
				if( self.oenter ) then
					self.oenter(select(1, ...));
				end
			end);
		end
		if( buttonframe:HasScript("OnLeave") and not hasHeader ) then
			buttonframe.oleave = buttonframe:GetScript("OnLeave");
			buttonframe:SetScript("OnLeave", function(...)
				local self = select(1, ...);
				if( not MBB_IsInArray(MBB_Exclude, self:GetName()) ) then
					MBB_ShowTimeout = 0;
				end
				if( self.oleave ) then
					self.oleave(select(1, ...));
				end
			end);
		end
	end
end

function MBB_AddButton(name)
	local child = _G[name]
	if not child then return end -- 3.3.5a fix: stale exclude entries have no frame

	child.opoint = {child:GetPoint()};
	if( not child.opoint[1] ) then
		child.opoint = {"TOP", Minimap, "BOTTOM", 0, 0};
	end
	child.osize = {child:GetHeight(),child:GetWidth()};
	child.oscale = child:GetScale();
	child.oclearallpoints = child.ClearAllPoints;
	child.ClearAllPoints = function() end;
	child.osetpoint = child.SetPoint;
	child.SetPoint = function() end;
	if( MBB_IsShown == 0 ) then
		if( child.hasParentFrame ) then
			local parent = child:GetParent();
			child.oshow(child);
			parent.ohide(parent);
		else
			-- TODO: Not sure why ohide would be nil but it is.  We'll fix this later.
			if(child.ohide) then
				child.ohide(child);
			end
		end
	end
	MBB_ButtonOrder_EnsureName(name);
	table.insert(MBB_Buttons, name);
	MBB_ButtonOrder_ApplyToCollected();
	local i = MBB_IsInArray(MBB_Exclude, name);
	if( i ) then
		table.remove(MBB_Exclude, i);
	end
	if MBB_ButtonManagerFrame and MBB_ButtonManagerFrame:IsShown() and MBB_ButtonManager_Refresh then
		MBB_ButtonManager_Refresh();
	end
end

function MBB_RestoreButton(name)
	local button = _G[name]
	
	button.oclearallpoints(button);
	button.osetpoint(button, button.opoint[1], button.opoint[2], button.opoint[3], button.opoint[4], button.opoint[5]);
	button:SetHeight(button.osize[1]);
	button:SetWidth(button.osize[2]);
	if button.oscale then button:SetScale(button.oscale); end
	button.ClearAllPoints = button.oclearallpoints;
	button.SetPoint = button.osetpoint;
	MBB_Debug("EVENT Restoring Button");
	-- 3.3.5a fix: show it only if its addon has it shown (TinyPad's button is
	-- off by default and appeared on the minimap when taken out of the bag).
	if( button.hasParentFrame ) then
		local parent = button:GetParent();
		if( button.parentisvisible and parent.oshow ) then parent.oshow(parent); end
	else
		if( button.isvisible and button.oshow ) then button.oshow(button); end
	end
	
	table.insert(MBB_Exclude, name);
	local i = MBB_IsInArray(MBB_Buttons, button:GetName());
	if( i ) then
		table.remove(MBB_Buttons, i);
	end
	MBB_ButtonOrder_EnsureName(name);
	MBB_ButtonOrder_ApplyToCollected();
	if MBB_ButtonManagerFrame and MBB_ButtonManagerFrame:IsShown() and MBB_ButtonManager_Refresh then
		MBB_ButtonManager_Refresh();
	end
end

function MBB_SetPositions()
	MBB_ButtonOrder_ApplyToCollected();
	MBB_MinimapButtonFrame:SetScale(MBB_Options.ButtonScale or 1.0);
	local directions = {
		[1] = {"RIGHT", "LEFT"},
		[2] = {"BOTTOM", "TOP"},
		[3] = {"LEFT", "RIGHT"},
		[4] = {"TOP", "BOTTOM"}
	};
	local offsets = {
		[1] = {-5, 0},
		[2] = {0, 5},
		[3] = {5, 0},
		[4] = {0, -5}
	};
	
	local pos = {0, 0};
	local parentid = 0;
	local firstid = 1;
	local count = 1;
	for i,name in ipairs(MBB_Buttons) do
		local positionframe = _G[name]
		if( not positionframe.hasParentFrame ) then
			positionframe.parentisvisible = true;
		end
		if( positionframe.isvisible and positionframe.parentisvisible ) then
			-- Apply user-selected button scale while preserving each addon button's original scale.
			local baseScale = positionframe.oscale or 1
			positionframe:SetScale(baseScale * (MBB_Options.ButtonScale or 1.0));

			local parent;
			if( parentid==0 ) then
				parent = MBB_MinimapButtonFrame;
			else
				parent = _G[MBB_Buttons[parentid]]
			end
			
			if( not MBB_IsInArray(MBB_IgnoreSize, name) ) then
				if( MBB_ExtraSize[name] ) then
					local func = MBB_ExtraSize[name];
					func();
				else
					positionframe:SetHeight(31); -- 33
					positionframe:SetWidth(31);
				end
			end
			
			local direction;
			
			if( MBB_Options.MaxButtonsPerLine > 0 and count > MBB_Options.MaxButtonsPerLine ) then
				parent = _G[MBB_Buttons[firstid]]
				direction = {directions[MBB_Options.AltExpandDirection][1], directions[MBB_Options.AltExpandDirection][2]};
				if( MBB_ExtraSize[name] or MBB_IsInArray(MBB_IgnoreSize, name) or MBB_ExtraSize[parent:GetName()] or MBB_IsInArray(MBB_IgnoreSize, parent:GetName()) ) then
					pos = offsets[MBB_Options.AltExpandDirection];
				else
					pos = {0, 0};
				end
				count = 2;
				firstid = i;
			else
				direction = {directions[MBB_Options.ExpandDirection][1], directions[MBB_Options.ExpandDirection][2]};
				if( MBB_ExtraSize[name] or MBB_IsInArray(MBB_IgnoreSize, name) or MBB_ExtraSize[parent:GetName()] or MBB_IsInArray(MBB_IgnoreSize, parent:GetName()) ) then
					pos = offsets[MBB_Options.ExpandDirection];
				else
					pos = {0, 0};
				end
				count = count + 1;
			end
			
			positionframe.oclearallpoints(positionframe);
			positionframe.osetpoint(positionframe, direction[1], parent, direction[2], pos[1], pos[2]);
			
			parentid = i;
		end
	end
end

function MBB_OnClick(arg1)
	if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
		if( MBB_Options.AttachToMinimap == 1 ) then
			--[[local xpos,ypos = GetCursorPosition();
			local scale = GetCVar("uiScale");]]
			MBB_Options.AttachToMinimap = 0;
			MBB_Options.ButtonPos = {0, 0};	--{(xpos/scale)-10, (ypos/scale)-10};
			MBB_Options.DetachedButtonPos = MBB_DefaultOptions.DetachedButtonPos;
		else
			MBB_Options.AttachToMinimap = 1;
			MBB_Options.ButtonPos = MBB_DefaultOptions.ButtonPos;
		end
		MBB_SetButtonPosition();
	elseif( arg1 and arg1 == "RightButton" ) then
		MBB_OptionsFrame:Show();
	else
		if( MBB_IsShown == 1 ) then
			MBB_HideButtons();
		else
			MBB_Debug("EVENT OnClick");
			for i,name in ipairs(MBB_Buttons) do
				local clickframe = _G[name]
				if( not clickframe.hasParentFrame ) then
					clickframe.parentisvisible = true;
				end
				if( clickframe.isvisible and clickframe.parentisvisible ) then
					if( clickframe.hasParentFrame and clickframe.hasParentFrame ) then
						local parent = clickframe:GetParent();
						if( parent.oshow ) then
							parent.oshow(parent);
						else
							if( parent:GetName() ) then
								if( not MBB_DebugInfo[parent:GetName()] ) then
									MBB_DebugInfo[parent:GetName()] = {};
								end
								if( not MBB_IsInArray(MBB_DebugInfo[parent:GetName()], "No oshow") ) then
									table.insert(MBB_DebugInfo[parent:GetName()], "No oshow");
								end
							end
						end
					else
						clickframe.oshow(clickframe);
					end
				end
			end
			MBB_IsShown = 1;
			--MBB_ShowTimeout = 0;
		end
	end
end

function MBB_HideButtons()
	MBB_ShowTimeout = -1;
	for i,name in ipairs(MBB_Buttons) do
		local buttonhideframe = _G[name]
		if( buttonhideframe.hasParentFrame ) then
			local parent = buttonhideframe:GetParent();
			if( parent.ohide ) then
				parent.ohide(parent);
			else
				if( parent:GetName() ) then
					if( not MBB_DebugInfo[parent:GetName()] ) then
						MBB_DebugInfo[parent:GetName()] = {};
					end
					if( not MBB_IsInArray(MBB_DebugInfo[parent:GetName()], "No ohide") ) then
						table.insert(MBB_DebugInfo[parent:GetName()], "No ohide");
					end
				end
				-- 3.3.5a fix: an unprepared frame has no ohide; the error stopped the bag from closing
				if( buttonhideframe.ohide ) then buttonhideframe.ohide(buttonhideframe); end
			end
		else
			if( buttonhideframe.ohide ) then buttonhideframe.ohide(buttonhideframe); end -- 3.3.5a fix: as above
		end
	end
	MBB_IsShown = 0;
end

function MBB_IsKnownButton(name, opt)
	if( not opt ) then
		opt = 1;
	end
	
	if( opt <= 1 ) then
		for _, button in ipairs(MBB_Buttons) do
			if( button == name ) then
				return true;
			end
		end
	end
	if( opt <= 2 ) then
		for _, button in ipairs(MBB_Exclude) do
			if( button == name ) then
				return true;
			end
		end
	end
	if( opt <= 3 ) then
		for _, button in ipairs(MBB_Ignore) do
			if( string.find(name, button) ) then
				return true;
			end
		end
	end
	
	return false;
end

function MBB_isButtonToBeIncluded(name)
	for _, button in ipairs(MBB_Include) do
		if( string.find(name, button) ) then
			return true;
		end
	end
end

-- 3.3.5a port: like the 3.3.5a MBB, also scan MinimapBackdrop and accept a
-- button wrapped in a container frame (e.g. Atlas: AtlasButtonFrame > AtlasButton).
function MBB_GetScanCandidates()
	local candidates = {};
	local children = {Minimap:GetChildren()};
	if( MinimapBackdrop ) then
		for _, child in ipairs({MinimapBackdrop:GetChildren()}) do
			table.insert(children, child);
		end
	end

	for _, child in ipairs(children) do
		local name = child:GetName();
		if( name ) then
			if( MBB_isButtonToBeIncluded(name) or (child:HasScript("OnClick") and not MBB_IsKnownButton(name, 3)) ) then
				table.insert(candidates, child);
			elseif( not child:HasScript("OnClick") and not MBB_IsKnownButton(name, 3) ) then
				local subchildren = {child:GetChildren()};
				local sub = subchildren[1];
				if( #subchildren == 1 and sub:GetName() and sub:HasScript("OnClick") and not MBB_IsKnownButton(sub:GetName(), 3) ) then
					sub.hasParentFrame = true;
					table.insert(candidates, sub);
				end
			end
		end
	end

	return candidates;
end

-- Prepares the minimap buttons not seen before and puts them in the bag
-- (unless excluded). Returns how many went into the bag.
function MBB_ScanMinimap()
	local added = 0;
	for _, child in ipairs(MBB_GetScanCandidates()) do
		if( not child.oshow ) then
			MBB_PrepareButton(child:GetName());
			if( not MBB_IsInArray(MBB_Exclude, child:GetName()) ) then
				MBB_AddButton(child:GetName());
				added = added + 1;
			end
		end
	end
	if( added > 0 ) then
		MBB_SetPositions();
	end
	return added;
end

-- 3.3.5a port: the regular scan runs every 3 s, so buttons stayed on the
-- minimap for a moment after the loading screen. Scan while the loading screen
-- is still up (PLAYER_ENTERING_WORLD comes after every addon's PLAYER_LOGIN
-- setup), then every 0.1 s for 10 s for buttons that come a little later.
MBB_FastScanUntil = 0;

do
	local loadingScan = CreateFrame("Frame");
	loadingScan:RegisterEvent("PLAYER_ENTERING_WORLD");
	loadingScan:SetScript("OnEvent", function()
		if( not MBB_Options ) then return; end
		MBB_ScanMinimap();
		MBB_FastScanUntil = GetTime() + 10;
	end);
end

function MBB_OnUpdate(elapsed)
	local interval = (GetTime() < MBB_FastScanUntil) and 0.1 or 3;
	if( MBB_CheckTime >= interval ) then
		MBB_CheckTime = 0;
		MBB_ScanMinimap();
	else
		MBB_CheckTime = MBB_CheckTime + elapsed;
	end
	
	if( MBB_DragFlag == 1 and MBB_Options.AttachToMinimap == 1 ) then
		-- 3.3.5a port: the upstream numbers circle a 198 wide minimap; this one is
		-- 140 wide, so the button went round a bigger, off-centre circle. Keep the
		-- button's centre 80 from the minimap's centre (like LibDBIcon buttons),
		-- in the button's own scale (Button size option).
		local scale = Minimap:GetEffectiveScale();
		local xpos, ypos = GetCursorPosition();
		local mx, my = Minimap:GetCenter();
		local angle = math.atan2(ypos / scale - my, xpos / scale - mx);
		local ratio = MBB_MinimapButtonFrame:GetEffectiveScale() / scale;
		local half = MBB_MinimapButtonFrame:GetWidth() / 2;

		MBB_MinimapButtonFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT",
			(Minimap:GetWidth() / 2 + math.cos(angle) * 80) / ratio - half,
			(-Minimap:GetHeight() / 2 + math.sin(angle) * 80) / ratio + half);
	end
	
	if( MBB_Options.CollapseTimeout and MBB_Options.CollapseTimeout ~= 0 ) then
		if( MBB_ShowTimeout >= MBB_Options.CollapseTimeout and MBB_IsShown == 1 ) then
			MBB_HideButtons();
		end
		if( MBB_ShowTimeout ~= -1 ) then
			MBB_ShowTimeout = MBB_ShowTimeout + elapsed;
		end
	end
end

function MBB_Rescan()
	-- Avoid protected actions / taint issues during combat
	if( MBB_IsInCombat() ) then
		MBB_Print("MBB: Can't rescan during combat.")
		return
	end

	local added = 0

	-- Same detection logic as the periodic scan
	for _, child in ipairs(MBB_GetScanCandidates()) do
		local name = child:GetName()
		if( not child.oshow ) then
			MBB_PrepareButton(name)

			-- Add only if not excluded and not already in bar
			if( not MBB_IsInArray(MBB_Exclude, name) and not MBB_IsInArray(MBB_Buttons, name) ) then
				MBB_AddButton(name)
				added = added + 1
			end
		end
	end

	MBB_SetPositions()

	-- Chat feedback (localized if available)
	if( MBB_RESCAN_DONE ) then
		MBB_Print(string.format(MBB_RESCAN_DONE, added))
	else
		MBB_Print("MBB: Rescan complete. Found " .. added .. " new minimap button(s).")
	end
end


function MBB_SaveOptionsFramePosition()
    if not MBB_OptionsFrame or not MBB_Options then return end

    local point, _, relativePoint, x, y = MBB_OptionsFrame:GetPoint(1)
    MBB_Options.OptionsFramePos = {
        point or "CENTER",
        relativePoint or point or "CENTER",
        tonumber(x) or 0,
        tonumber(y) or 0
    }
end

function MBB_RestoreOptionsFramePosition()
    if not MBB_OptionsFrame then return end

    MBB_OptionsFrame:SetClampedToScreen(true)

    local pos = MBB_Options and MBB_Options.OptionsFramePos
    if type(pos) ~= "table" then
        pos = {"CENTER", "CENTER", 0, 0}
    end

    local point = type(pos[1]) == "string" and pos[1] or "CENTER"
    local relativePoint = type(pos[2]) == "string" and pos[2] or point
    local x = tonumber(pos[3]) or 0
    local y = tonumber(pos[4]) or 0

    -- Protect against stale coordinates after resolution/UI-scale changes.
    if x > 5000 or x < -5000 or y > 5000 or y < -5000 then
        point, relativePoint, x, y = "CENTER", "CENTER", 0, 0
        if MBB_Options then
            MBB_Options.OptionsFramePos = {point, relativePoint, x, y}
        end
    end

    MBB_OptionsFrame:ClearAllPoints()
    MBB_OptionsFrame:SetPoint(point, UIParent, relativePoint, x, y)
end

local function MBB_SaveDetachedButtonPosition()
    if not MBB_MinimapButtonFrame or MBB_Options.AttachToMinimap == 1 then return end

    local point, _, _, xpos, ypos = MBB_MinimapButtonFrame:GetPoint()
    MBB_Options.DetachedButtonPos = point or "CENTER"
    MBB_Options.ButtonPos = { tonumber(xpos) or 0, tonumber(ypos) or 0 }
end

function MBB_SnapDetachedButtonToScreen()
    if not MBB_MinimapButtonFrame or MBB_Options.AttachToMinimap == 1 then return end
    if MBB_Options.SnapToScreenEdges ~= 1 then
        MBB_SaveDetachedButtonPosition()
        return
    end

    local frame = MBB_MinimapButtonFrame
    local parent = UIParent

    -- Use the actual WoW viewport (UIParent), not desktop/monitor dimensions.
    -- This keeps snapping stable when WoW is running on a secondary monitor
    -- or when the two monitors use different resolutions/scales.
    local parentLeft = parent:GetLeft()
    local parentRight = parent:GetRight()
    local parentBottom = parent:GetBottom()
    local parentTop = parent:GetTop()

    local frameLeft = frame:GetLeft()
    local frameRight = frame:GetRight()
    local frameBottom = frame:GetBottom()
    local frameTop = frame:GetTop()
    local centerX, centerY = frame:GetCenter()

    -- Fallback for rare cases where edge coordinates are not available yet.
    if not parentLeft or not parentRight or not parentBottom or not parentTop then
        local parentCenterX, parentCenterY = parent:GetCenter()
        local parentWidth, parentHeight = parent:GetWidth(), parent:GetHeight()
        if parentCenterX and parentCenterY and parentWidth and parentHeight
           and parentWidth > 0 and parentHeight > 0 then
            parentLeft = parentCenterX - parentWidth * 0.5
            parentRight = parentCenterX + parentWidth * 0.5
            parentBottom = parentCenterY - parentHeight * 0.5
            parentTop = parentCenterY + parentHeight * 0.5
        end
    end

    if not frameLeft or not frameRight or not frameBottom or not frameTop
       or not centerX or not centerY
       or not parentLeft or not parentRight or not parentBottom or not parentTop then
        MBB_SaveDetachedButtonPosition()
        return
    end

    local parentCenterX = (parentLeft + parentRight) * 0.5
    local parentCenterY = (parentBottom + parentTop) * 0.5

    -- UIParent and the detached button now share the same coordinate space,
    -- so no Windows monitor coordinates or cursor scale conversion is needed.
    local threshold = 120

    local distLeft = math.abs(frameLeft - parentLeft)
    local distRight = math.abs(parentRight - frameRight)
    local distBottom = math.abs(frameBottom - parentBottom)
    local distTop = math.abs(parentTop - frameTop)

    local nearLeft = distLeft <= threshold
    local nearRight = distRight <= threshold
    local nearBottom = distBottom <= threshold
    local nearTop = distTop <= threshold

    local point, x, y

    -- Corners first, then the nearest single viewport edge.
    if nearTop and nearLeft then
        point, x, y = "TOPLEFT", 0, 0
    elseif nearTop and nearRight then
        point, x, y = "TOPRIGHT", 0, 0
    elseif nearBottom and nearLeft then
        point, x, y = "BOTTOMLEFT", 0, 0
    elseif nearBottom and nearRight then
        point, x, y = "BOTTOMRIGHT", 0, 0
    else
        local bestDistance = math.huge
        if nearLeft and distLeft < bestDistance then
            bestDistance = distLeft
            point, x, y = "LEFT", 0, centerY - parentCenterY
        end
        if nearRight and distRight < bestDistance then
            bestDistance = distRight
            point, x, y = "RIGHT", 0, centerY - parentCenterY
        end
        if nearTop and distTop < bestDistance then
            bestDistance = distTop
            point, x, y = "TOP", centerX - parentCenterX, 0
        end
        if nearBottom and distBottom < bestDistance then
            bestDistance = distBottom
            point, x, y = "BOTTOM", centerX - parentCenterX, 0
        end
    end

    if not point then
        MBB_SaveDetachedButtonPosition()
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(point, parent, point, x, y)

    MBB_Options.DetachedButtonPos = point
    MBB_Options.ButtonPos = { x, y }
end

function MBB_UpdatePositionOptionControls()
    local detached = MBB_Options and MBB_Options.AttachToMinimap == 0
    local detachCheck = _G["MBB_OptionsFrame_DetachFromMinimapCheck"]
    local lockCheck = _G["MBB_OptionsFrame_LockDetachedCheck"]
    local snapCheck = _G["MBB_OptionsFrame_SnapEdgesCheck"]

    -- 3.3.5a port: Ctrl+Right-click on the MBB button and /mbb reset also change
    -- the attach mode; keep the Detach box in step with it.
    if detachCheck and MBB_Options then
        detachCheck:SetChecked(detached)
        MBB_SetCheckEnabled(detachCheck, not MBB_IsInCombat())
    end

    if lockCheck then
        lockCheck:SetChecked(MBB_Options and MBB_Options.DetachedButtonLocked == 1)
        MBB_SetCheckEnabled(lockCheck, detached and not (MBB_IsInCombat()))
    end
    if snapCheck then
        snapCheck:SetChecked(MBB_Options and MBB_Options.SnapToScreenEdges == 1)
        MBB_SetCheckEnabled(snapCheck, detached and not (MBB_IsInCombat()))
    end
end

-- 3.3.5a port: a disabled check box keeps its white label on this client, so it
-- still looked clickable. Grey the label too, as Blizzard's option panels do.
function MBB_SetCheckEnabled(check, enabled)
    MBB_SetEnabled(check, enabled)
    local label = _G[check:GetName() .. "Text"]
    if label then
        if enabled then
            label:SetTextColor(1, 1, 1)
        else
            local gray = GRAY_FONT_COLOR or { r = 0.5, g = 0.5, b = 0.5 }
            label:SetTextColor(gray.r, gray.g, gray.b)
        end
    end
end

function MBB_ResetButtonPosition()
	MBB_Options.AttachToMinimap = MBB_DefaultOptions.AttachToMinimap;
	MBB_Options.ButtonPos = MBB_DefaultOptions.ButtonPos;
	MBB_Options.DetachedButtonPos = MBB_DefaultOptions.DetachedButtonPos;
	
	MBB_SetButtonPosition();
end

function MBB_SetButtonPosition()
    if (MBB_Options.AttachToMinimap == 1) then
        MBB_MinimapButtonFrame:ClearAllPoints();
        MBB_MinimapButtonFrame:SetParent(Minimap);
        MBB_MinimapButtonFrame:SetMovable(false);
        -- 3.3.5a fix: ButtonPos is kept at 100% size (the default and older saved
        -- positions are); anchor offsets are in the button's own scale, so convert
        -- them around the button's centre. Otherwise a Button size other than 100%
        -- put the button off the minimap ring.
        local s = MBB_Options.ButtonScale or 1.0;
        local half = MBB_MinimapButtonFrame:GetWidth() / 2;
        MBB_MinimapButtonFrame:SetScale(s);
        MBB_MinimapButtonFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", (MBB_Options.ButtonPos[1] + half) / s - half, (MBB_Options.ButtonPos[2] - half) / s + half);
    else
        -- Detached: always keep it on-screen and default to center if anything looks wrong
        MBB_MinimapButtonFrame:ClearAllPoints();
        MBB_MinimapButtonFrame:SetParent(UIParent);
        MBB_MinimapButtonFrame:SetClampedToScreen(true);
        MBB_MinimapButtonFrame:SetMovable(MBB_Options.DetachedButtonLocked ~= 1);

        if (not MBB_Options.DetachedButtonPos) then
            MBB_Options.DetachedButtonPos = "CENTER";
        end
        if (not MBB_Options.ButtonPos) then
            MBB_Options.ButtonPos = { 0, 0 };
        end

        local x = tonumber(MBB_Options.ButtonPos[1]) or 0;
        local y = tonumber(MBB_Options.ButtonPos[2]) or 0;

        -- If values are insane (can happen across resolutions/UI scale), reset to center
        if (x > 5000 or x < -5000 or y > 5000 or y < -5000) then
            x, y = 0, 0;
            MBB_Options.ButtonPos[1], MBB_Options.ButtonPos[2] = 0, 0;
            MBB_Options.DetachedButtonPos = "CENTER";
        end

        MBB_MinimapButtonFrame:SetPoint(MBB_Options.DetachedButtonPos, UIParent, MBB_Options.DetachedButtonPos, x, y);
    end
    MBB_UpdatePositionOptionControls();
end


function MBB_RadioButton_OnClick(id, alt)
	local substring;
	if( alt ) then
		substring = "Alt";
	else
		substring = "";
	end
	local buttons = {
		[1] = "Left",
		[2] = "Top",
		[3] = "Right",
		[4] = "Bottom"
	};
	
	for i,name in ipairs(buttons) do
		if( i == id ) then
			_G["MBB_OptionsFrame_" .. name .. substring .. "Radio"]:SetChecked(true)
		else
			_G["MBB_OptionsFrame_" .. name .. substring .. "Radio"]:SetChecked(nil);
		end
	end
end

function MBB_UpdateAltRadioButtons()
	local buttons = {
		[1] = "Left",
		[2] = "Top",
		[3] = "Right",
		[4] = "Bottom"
	};
	
	local exchecked = 1;
	
	for i,name in pairs(buttons) do
		if( _G["MBB_OptionsFrame_" .. name .. "Radio"]:GetChecked() ) then
			exchecked = i;
			break;
		end
	end
	
	local checked = false;
	local textbox = _G["MBB_OptionsFrame_MaxButtonsTextBox"]
	
	for i,name in pairs(buttons) do
		local radio = _G["MBB_OptionsFrame_" .. name .. "AltRadio"]
		local label = _G["MBB_OptionsFrame_" .. name .. "AltRadioLabel"]
		if( textbox:GetText() == "" or tonumber(textbox:GetText()) == 0 ) then
			radio:Disable();
			radio:SetChecked(nil);
			label:SetTextColor(0.5, 0.5, 0.5);
		else
			if( exchecked % 2 == i % 2 ) then
				if( radio:GetChecked() ) then
					checked = true;
					if( i == 4 ) then
						_G["MBB_OptionsFrame_LeftAltRadio"]:SetChecked(true);
					else
						_G["MBB_OptionsFrame_" .. buttons[i+1] .. "AltRadio"]:SetChecked(true);
					end
				end
				radio:Disable();
				radio:SetChecked(nil);
				label:SetTextColor(0.5, 0.5, 0.5);
			else
				if( radio:GetChecked() ) then
					checked = true;
				end
				radio:Enable();
				label:SetTextColor(1, 1, 1);
			end
		end
	end
	
	if( not checked and tonumber(textbox:GetText()) ~= 0 and textbox:GetText() ~= "" ) then
		if( exchecked % 2 == 1 ) then
			_G["MBB_OptionsFrame_TopAltRadio"]:SetChecked(true);
		else
			_G["MBB_OptionsFrame_LeftAltRadio"]:SetChecked(true);
		end
	end
end

function MBB_Debug(msg)
	if (MBB_DebugFlag == 1) then
		MBB_Print("MBB Debug : " .. tostring(msg));
	end
end

function MBB_Test()
	local children = {Minimap:GetChildren()};
	for _, child in ipairs(children) do
		if( child:GetName() and not MBB_IsKnownButton(child:GetName()) ) then
			ChatFrame1:AddMessage(child:GetName());
		end
	end
end

function MBB_IsInArray(array, needle)
	if(type(array) == "table") then
		--MBB_Debug("Looking for " .. tostring(needle) .. " in " .. tostring(array));
		for i, element in pairs(array) do
			if(type(element) ==  type(needle) and element == needle) then
				return i;
			end
		end
	end
	return nil;
end

function MBB_SecureOnClick(self, button, down)
	local name = self:GetName();
	if(name) then -- trap to check for nils
		MBB_Debug("Name: " .. name);
		MBB_Debug("Button: " .. button);
		if( MBB_IsInArray(MBB_Buttons, name) ) then
			if( button == "RightButton" and IsControlKeyDown() ) then
				MBB_Debug("Restoring button: " .. name);
				MBB_RestoreButton(name);
				MBB_SetPositions();
			end
		elseif( MBB_IsInArray(MBB_Exclude, name) ) then
			if( button == "RightButton" and IsControlKeyDown() ) then
				MBB_Debug("Adding button: " .. name);
				MBB_AddButton(name);
				MBB_SetPositions();
			end
		end
	end
end

function MBB_SecureOnEnter(self)
	local name = self:GetName();
	if(name) then -- trap to check for nils
		MBB_Debug("Name: " .. name);
		if( MBB_IsInArray(MBB_Buttons, name) ) then
			if( IsControlKeyDown() ) then
				local button = _G["MBB_ButtonRemove"]
				button.MBBButtonName = name;
				button:ClearAllPoints();
				button:SetPoint("BOTTOM", self, "TOP", 0, 0);
				button:Show();
			end
			MBB_ShowTimeout = -1;
		elseif( MBB_IsInArray(MBB_Exclude, name) ) then
			if( IsControlKeyDown() ) then
				local button = _G["MBB_ButtonAdd"]
				button.MBBButtonName = name;
				button:ClearAllPoints();
				button:SetPoint("BOTTOM", self, "TOP", 0, 0);
				button:Show();
			end
		end
	end
end

function MBB_SecureOnLeave(self)
	local name = self:GetName();
	if(name) then -- trap to check for nils
		MBB_Debug("Name: " .. name);
		if( MBB_IsInArray(MBB_Buttons, name) ) then
			MBB_ShowTimeout = 0;
		elseif( MBB_IsInArray(MBB_Exclude, name) ) then
		
		end
	end
end

function MBB_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg, 0.2, 0.8, 0.8);
end

-- This looks to be used for testing only.
function MBB_NotSureIfThisIsNeeded()
	local children = {Minimap:GetChildren()};
	local additional = {MinimapBackdrop:GetChildren()};
	for _,child in ipairs(additional) do
		table.insert(children, child);
	end
	for _,child in ipairs(MBB_Include) do
		local childframe = _G[child]
		if( childframe ) then
			table.insert(children, childframe);
		end
	end
	
	for _,child in ipairs(children) do
		if( child:GetName() ) then
			local ignore = false;
			local exclude = false;
			for i,needle in ipairs(MBB_Ignore) do
				if( string.find(child:GetName(), needle) ) then
					ignore = true;
				end
			end
			if( not ignore ) then
				if( not child:HasScript("OnClick") ) then
					for _,subchild in ipairs({child:GetChildren()}) do
						if( subchild:HasScript("OnClick") ) then
							child = subchild;
							child.hasParentFrame = true;
							break;
						end
					end
				end
				
				local hasClick, hasMouseUp, hasMouseDown, hasEnter, hasLeave = MBB_TestFrame(child:GetName());
				
				if( hasClick or hasMouseUp or hasMouseDown ) then
					local name = child:GetName();
					
					MBB_PrepareButton(name);
					if( not MBB_IsInArray(MBB_Exclude, name) ) then
						if( child:IsVisible() ) then
							MBB_Debug("Button is visible: " .. name);
						else
							MBB_Debug("Button is not visible: " .. name);
						end
						MBB_Debug("Button added: " .. name);
						MBB_AddButton(name);
					else
						MBB_Debug("Button excluded: " .. name);
					end
				else
					MBB_Debug("Frame is no button: " .. child:GetName());
				end
			else
				MBB_Debug("Frame ignored: " .. child:GetName());
			end
		end
	end
	
	MBB_SetPositions()
end

-- Patch compatibility warning

function MBB_ShowPatchStatus()
	local _, _, _, toc = GetBuildInfo()
	toc = tonumber(toc)

	MBB_Print(MBB_PATCH_STATUS_TITLE or "MinimapButtonBag Reborn – Patch Status")
	MBB_Print((MBB_PATCH_ADDON_INTERFACE or "Addon Interface Version:") .. " " .. tostring(MBB_InterfaceVersion))

	if toc then
		MBB_Print((MBB_PATCH_WOW_INTERFACE or "Current WoW Interface Version:") .. " " .. tostring(toc))

		if toc > MBB_InterfaceVersion then
			MBB_Print("|cffff5555" .. (MBB_PATCH_OLD or "Status: This addon was built for an older WoW patch. Please check for updates.") .. "|r")
		else
			MBB_Print("|cff55ff55" .. (MBB_PATCH_OK or "Status: Addon is up to date for this WoW patch.") .. "|r")
		end
	else
		MBB_Print("Status: Unable to determine WoW build information.")
	end
end


-- Read the supported Interface versions from the active TOC file and select
-- the newest entry for the currently running WoW client family.
local function MBB_GetInterfaceFamily(interface)
	interface = tonumber(interface) or 0;
	if interface >= 100000 then
		return "retail";
	elseif interface >= 50000 and interface < 60000 then
		return "mists";
	elseif interface >= 20000 and interface < 30000 then
		return "tbc";
	elseif interface >= 10000 and interface < 20000 then
		return "classic";
	end
	return "other";
end

local function MBB_GetAddonInterfaceVersion()
	local value = MBB_GetMetadata("Interface");
	-- 3.3.5a port: this client cannot read a TOC's Interface field (it returned
	-- nil, and every login warned about an outdated addon). The TOC says 30300.
	if value == nil then
		value = "30300";
	end
	local _, _, _, current = GetBuildInfo();
	current = tonumber(current) or 0;

	-- If the current WoW client accepts this addon without marking it outdated,
	-- use the running client's Interface version directly.
	-- This also handles WoW Forever, which uses Mainline APIs but its own
	-- Interface version range (160xx).
	if current > 0 then
		if C_AddOns and C_AddOns.IsAddOnLoadable then
			local loadable, reason = C_AddOns.IsAddOnLoadable("MBB");
			if loadable then
				return current;
			end
		end
	end

	local currentFamily = MBB_GetInterfaceFamily(current);
	local best = 0;
	local fallback = 0;

	if type(value) == "number" then
		value = tostring(value);
	end

	if type(value) == "string" then
		for token in value:gmatch("%d+") do
			local interface = tonumber(token) or 0;

			if fallback == 0 then
				fallback = interface;
			end

			if interface == current then
				return interface;
			end

			if MBB_GetInterfaceFamily(interface) == currentFamily and interface > best then
				best = interface;
			end
		end
	end

	return best > 0 and best or fallback;
end

MBB_InterfaceVersion = MBB_GetAddonInterfaceVersion();

local patchWarningFrame = CreateFrame("Frame")
patchWarningFrame:RegisterEvent("PLAYER_LOGIN")
patchWarningFrame:SetScript("OnEvent", function()
    local _, _, _, toc = GetBuildInfo()
    toc = tonumber(toc)

    if toc and toc > MBB_InterfaceVersion then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff5555MBB: This addon was built for an older WoW patch (" ..
            MBB_InterfaceVersion ..
            "). If you experience issues after this patch, please check for an update on CurseForge.|r"
        )
    end
end)

-- In-game version exchange. WoW addons cannot query CurseForge directly, so MBB
-- shares its version through the hidden addon-message channel. If another player
-- is running a newer MBB release, show one update notice for the session.
local MBB_VERSION_PREFIX = "MBB_VERSION";
local MBB_UpdateNotifiedVersion = nil;
local MBB_LastVersionBroadcast = 0;
local MBB_RepliedToVersionSender = {};

local function MBB_ParseVersion(version)
	if type(version) ~= "string" or #version > 64 then return nil; end
	local major, minor, patch, suffix = version:match("^[vV]?(%d+)%.(%d+)%.(%d+)([%w%.%-]*)");
	if not major then return nil; end

	local rank = 3; -- stable release
	local prerelease = 0;
	if suffix and suffix ~= "" then
		local lower = string.lower(suffix);
		if string.find(lower, "alpha", 1, true) then
			rank = 0;
		elseif string.find(lower, "beta", 1, true) then
			rank = 1;
		elseif string.find(lower, "rc", 1, true) then
			rank = 2;
		else
			rank = 0;
		end
		prerelease = tonumber(lower:match("(%d+)")) or 0;
	end

	return tonumber(major), tonumber(minor), tonumber(patch), rank, prerelease;
end

local function MBB_CompareVersions(left, right)
	local l1, l2, l3, lrank, lpre = MBB_ParseVersion(left);
	local r1, r2, r3, rrank, rpre = MBB_ParseVersion(right);
	if not l1 or not r1 then return 0; end
	if l1 ~= r1 then return l1 > r1 and 1 or -1; end
	if l2 ~= r2 then return l2 > r2 and 1 or -1; end
	if l3 ~= r3 then return l3 > r3 and 1 or -1; end
	if lrank ~= rrank then return lrank > rrank and 1 or -1; end
	if lpre ~= rpre then return lpre > rpre and 1 or -1; end
	return 0;
end

local function MBB_IsPrereleaseVersion(version)
	local _, _, _, rank = MBB_ParseVersion(version);
	return rank ~= nil and rank < 3;
end

local function MBB_RegisterVersionPrefix()
	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		return C_ChatInfo.RegisterAddonMessagePrefix(MBB_VERSION_PREFIX);
	elseif RegisterAddonMessagePrefix then
		return RegisterAddonMessagePrefix(MBB_VERSION_PREFIX);
	end
	return false;
end

local function MBB_SendVersion(channel, target)
	if not channel or not MBB_ParseVersion(MBB_Version) then return; end
	if C_ChatInfo and C_ChatInfo.SendAddonMessage then
		C_ChatInfo.SendAddonMessage(MBB_VERSION_PREFIX, MBB_Version, channel, target);
	elseif SendAddonMessage then
		SendAddonMessage(MBB_VERSION_PREFIX, MBB_Version, channel, target);
	end
end

local function MBB_BroadcastVersion(force)
	-- Alpha/Beta/RC builds must not advertise themselves to stable users.
	-- Otherwise a stable 1.x client could be told to update to a test build
	-- that is intentionally hidden from the normal CurseForge client.
	if MBB_IsPrereleaseVersion(MBB_Version) then return; end

	local now = GetTime and GetTime() or 0;
	if not force and MBB_LastVersionBroadcast > 0 and (now - MBB_LastVersionBroadcast) < 10 then
		return;
	end
	MBB_LastVersionBroadcast = now;

	if IsInGuild and IsInGuild() then
		MBB_SendVersion("GUILD");
	end

	local inInstanceGroup = LE_PARTY_CATEGORY_INSTANCE and IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE);
	if inInstanceGroup then
		MBB_SendVersion("INSTANCE_CHAT");
	elseif IsInRaid and IsInRaid() then
		MBB_SendVersion("RAID");
	elseif IsInGroup and IsInGroup() then
		MBB_SendVersion("PARTY");
	end
end

local function MBB_ShowUpdateNotice(newVersion)
	if MBB_UpdateNotifiedVersion and MBB_CompareVersions(newVersion, MBB_UpdateNotifiedVersion) <= 0 then
		return;
	end
	MBB_UpdateNotifiedVersion = newVersion;
	MBB_Print(string.format(
		MBB_UPDATE_AVAILABLE or "MBB: A newer version is available: %s (you are using %s). Please update via CurseForge.",
		newVersion, MBB_Version
	));
end

-- 3.3.5a port: version exchange is off. The newer upstream releases don't run
-- on this client, so their update notices would only be noise.
local MBB_VERSION_EXCHANGE = false;

if MBB_VERSION_EXCHANGE then
MBB_RegisterVersionPrefix();

local versionFrame = CreateFrame("Frame");
versionFrame:RegisterEvent("PLAYER_LOGIN");
versionFrame:RegisterEvent("CHAT_MSG_ADDON");
versionFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
versionFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		if C_Timer and C_Timer.After then
			C_Timer.After(5, function() MBB_BroadcastVersion(true); end);
		else
			MBB_BroadcastVersion(true);
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		if C_Timer and C_Timer.After then
			C_Timer.After(2, function() MBB_BroadcastVersion(false); end);
		else
			MBB_BroadcastVersion(false);
		end
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, message, channel, sender = ...;
		local _, _, _, senderRank = MBB_ParseVersion(message);
		if prefix ~= MBB_VERSION_PREFIX or senderRank == nil then return; end

		local comparison = MBB_CompareVersions(message, MBB_Version);
		if comparison > 0 then
			MBB_ShowUpdateNotice(message);
		elseif comparison < 0 and sender and not MBB_RepliedToVersionSender[sender] then
			-- Stable releases may advertise themselves normally. Pre-release builds
			-- only reply to other pre-release clients, so stable users are never
			-- prompted to install an Alpha/Beta/RC build.
			if not MBB_IsPrereleaseVersion(MBB_Version) or senderRank < 3 then
				MBB_RepliedToVersionSender[sender] = true;
				MBB_SendVersion("WHISPER", sender);
			end
		end
	end
end);
end

local firstRunFrame = CreateFrame("Frame")
firstRunFrame:RegisterEvent("PLAYER_LOGIN")
firstRunFrame:SetScript("OnEvent", function()
	-- First run only
	if not MBB_FirstRun then
		MBB_FirstRun = true

		-- 3.3.5a port: wait for a minimap scan (every 3 s); at login the count was always 0.
		local waited = 0
		firstRunFrame:SetScript("OnUpdate", function(self, elapsed)
			waited = waited + elapsed
			if waited < 4 then return end
			self:SetScript("OnUpdate", nil)

			-- Count collected buttons
			local count = #MBB_Buttons

			MBB_Print(MBB_FIRST_RUN_TITLE or "MinimapButtonBag Reborn loaded.")
			MBB_Print(string.format(MBB_FIRST_RUN_COUNT or "Collected %d minimap buttons.", count))
			MBB_Print(MBB_FIRST_RUN_HELP or "Type /mbb to see available commands.")
			MBB_Print(MBB_FIRST_RUN_RESCAN or "Use /mbb rescan if buttons are missing.")
		end)
    end
end)
-- TBC-only delayed rescan to catch late-registered minimap buttons
local function MBB_IsTBC()
    local _, _, _, interface = GetBuildInfo()
    interface = tonumber(interface) or 0
    return interface >= 20501 and interface < 30000
end

local function MBB_SafeScan()
    -- In this addon the scan function is MBB_Rescan()
    if type(MBB_Rescan) == "function" then
        MBB_Rescan()
    end
end

local function MBB_ScheduleTBCRescans()
    if not MBB_IsTBC() then return end
    if not C_Timer or not C_Timer.After then return end

    -- 1) normaler Scan (falls du den schon woanders machst, kannst du diese Zeile entfernen)
    MBB_SafeScan()

    -- 2) delayed Scan (fängt die meisten Fälle ab)
    C_Timer.After(1.5, MBB_SafeScan)

    -- 3) optionaler "Spätzünder"-Scan für sehr viele Addons / langsame Logins
    C_Timer.After(4.0, MBB_SafeScan)
end

-- Hook an Login (einmalig)
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function()
        MBB_ScheduleTBCRescans()
    end)
end
