-----------------------
-- BLIZZARD UI HOOKS --
-----------------------

local addonName, addon 	= ...
local L = addon.L -- localization entries
local V = addon.V -- shared variables
local M = addon.M -- shared methods

-- 3.3.5a: GIL's private friend list table (GIL_Compat335.lua); never Blizzard's globals
local C_FriendList = addon.FL or C_FriendList

--------------------
-- LFG TOOL HACKS --
--------------------

function M.GIL_GetPlaystyleString (playstyle, activityInfo)

	if activityInfo and playstyle ~= (0 or nil) and C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown then
		local typeStr
		
		if activityInfo.isMythicPlusActivity then
			typeStr = "GROUP_FINDER_PVE_PLAYSTYLE"
		elseif activityInfo.isRatedPvpActivity then
			typeStr = "GROUP_FINDER_PVP_PLAYSTYLE"
		elseif activityInfo.isCurrentRaidActivity then
			typeStr = "GROUP_FINDER_PVE_RAID_PLAYSTYLE"
		elseif activityInfo.isMythicActivity then
			typeStr = "GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE"
		end
    
		return typeStr and _G[typeStr .. tostring(playstyle)] or nil
	else
		return nil
	end
end

function M.GIL_LFG_Refresh()
	-- 3.3.5a: no LFG list tool (the Wrath check let 3.3.5a in; LFGListFrame is nil there)
	if V.wowIs335 or LFGListFrame == nil then return end
	if V.wowIsERA == true or V.wowIsTBC then return end

	if LFGListFrame.SearchPanel ~= nil and LFGListFrame.SearchPanel:IsShown() then
		LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
	end
end

function M.GIL_LFG_Update (self)
	if not C_LFGList.HasSearchResultInfo(self.resultID) then return end
	
	local info = C_LFGList.GetSearchResultInfo(self.resultID);
	
	if (info ~= nil and M.hasGlobalIgnored(M.Proper(M.addServer(info.leaderName))) > 0) then
		self.Name:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
	end	
end

function M.GIL_LFG_Tooltip (self)
	if not C_LFGList.HasSearchResultInfo(self.resultID) then return end

	local info = C_LFGList.GetSearchResultInfo(self.resultID);
	
	if (info ~= nil and info.leaderName ~= nil) then
		local idx = M.hasGlobalIgnored(M.Proper(M.addServer(info.leaderName)))
		
		if (idx > 0) then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("|c00ff0000" .. L["RCM_8"])
		
			local notes = (GlobalIgnoreDB.notes[idx] or "")
				
			if (notes ~= "") then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("|cffffffff" .. L["RCM_9"])
				GameTooltip:AddLine("|cff69CCF0"..notes)
			end
		
			GameTooltip:Show()
		end
	end
end

function M.GIL_LFG_ApplicantMenu(owner, root, contextData)
	if not owner or not owner.resultID then return end
	
	local info = C_LFGList.GetSearchResultInfo(owner.resultID);
	
	if not info.leaderName or info.leaderName == "" then return end
	
	local target = M.Proper(M.addServer(info.leaderName))
	local text   = ""
	
	if (M.hasGlobalIgnored(target) > 0) then
		text = L["RCM_4"]				
	else
		text = L["RCM_6"]
	end	
	
	local leaderText = format(L["RCM_7"], target)
	
	root:CreateDivider()
	root:CreateTitle(leaderText)
	root:CreateButton(text,
		function(owner, root, contextData)
			C_FriendList.AddOrDelIgnore(M.addServer(info.leaderName))
			M.GILUpdateUI(true)
		end)	
end

----------------------
-- UNIT MENU- HACKS --
----------------------

function M.GIL_UnitMenuPlayer (owner, root, contextData)
	local target, server = UnitName(contextData.unit)

	if server == nil or server == "" then
		target = M.addServer(target)
	else
		target = target .. "-" .. server
	end

	target = M.Proper(target, true)

	local text = ""
	
	if (M.hasGlobalIgnored(M.addServer(target)) > 0) then
		text = L["RCM_4"]				
	else
		text = L["RCM_6"]
	end	

	root:CreateDivider()
	root:CreateButton(text,
		function(owner, root, contextData)
			C_FriendList.AddOrDelIgnore(M.addServer(target))
			M.GILUpdateUI(true)
		end)
end

-------------------------------------
-- 3.3.5a: UNIT RIGHT-CLICK MENUS  --
-------------------------------------

-- 3.3.5a has no Menu.ModifyMenu.  Inserting into UnitPopupMenus/UnitPopupButtons taints every
-- button of the menu ("Set Focus" then fails with "Interface action failed"), and adding a
-- button with UIDropDownMenu_AddButton from a hook leaves tainted values in the open menu
-- (DropDownList1.numButtons, which ToggleDropDownMenu reads right after the hook before it
-- writes the list's onHide; the next click on "Set Focus" runs that OnHide first).  So GIL
-- writes nothing into Blizzard's menu: it shows a small GIL-owned panel attached to the
-- level-1 menu (a child of DropDownList1, so it closes with it).  Clicking it adds or removes
-- the player and leaves Blizzard's menu alone.
--
-- The post-hook of UnitPopup_ShowMenu only remembers the player and the dropdown.  The panel
-- is shown and placed by a post-hook of ToggleDropDownMenu, after Blizzard has shown and
-- positioned the list, and only when the open list belongs to that dropdown: unit frame addons
-- also initialize their dropdowns without opening them, and the panel must not then turn up
-- under the next, unrelated menu with an old player in it.

local GIL_UNIT_MENUS = { PLAYER = true, PARTY = true, RAID_PLAYER = true, RAID = true }
local GIL_NAME_MENUS = { FRIEND = true, FRIEND_OFFLINE = true }
local unitMenu       = nil
local unitPending    = nil	-- { owner = dropdown, key = player } of the last level-1 UnitPopup_ShowMenu
local unitHooked     = false

-- Blizzard's menu hides itself 2 s after the mouse has left its own buttons; the panel stops and
-- restarts that timer as Blizzard's buttons do (UIDropDownMenuTemplates.xml).  This only writes
-- DropDownList1.isCounting/showTimer, which nothing but UIDropDownMenu_OnUpdate reads (and
-- Blizzard's buttons rewrite both on every OnEnter/OnLeave); the Set Focus path never reads them.
local function UnitMenuKeep ()
	UIDropDownMenu_StopCounting(DropDownList1)
end

local function UnitMenuRelease ()
	UIDropDownMenu_StartCounting(DropDownList1)
end

local function UnitMenuUpdate (frame)
	local ignored = M.hasGlobalIgnored(frame.key) > 0
	local height  = 26

	if ignored then
		frame.warning:SetText("|cffff2020" .. L["RCM_8_UNIT"])
		frame.warning:Show()
		frame.button:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -26)
		height = height + 16
	else
		frame.warning:Hide()
		frame.button:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -10)
	end

	frame.button.text:SetText(ignored and L["RCM_4"] or L["RCM_6"])
	frame:SetHeight(height)
end

-- below the menu, or above it when the menu opens too low (ToggleDropDownMenu only keeps its
-- own list on the screen: chat names, party and raid frames at the bottom)
local function UnitMenuPlace (frame)
	local bottom = DropDownList1:GetBottom()

	frame:ClearAllPoints()

	if bottom and bottom < frame:GetHeight() then
		frame:SetPoint("BOTTOMLEFT", DropDownList1, "TOPLEFT", 0, -2)
		frame:SetPoint("BOTTOMRIGHT", DropDownList1, "TOPRIGHT", 0, -2)
	else
		frame:SetPoint("TOPLEFT", DropDownList1, "BOTTOMLEFT", 0, 2)
		frame:SetPoint("TOPRIGHT", DropDownList1, "BOTTOMRIGHT", 0, 2)
	end
end

local function CreateUnitMenu ()
	local f = CreateFrame("Frame", "GILUnitMenu", DropDownList1)

	f:Hide()
	f:SetHeight(26)
	f:EnableMouse(true)
	f:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 4 }
	})
	f:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	f:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
	f:SetScript("OnEnter", UnitMenuKeep)
	f:SetScript("OnLeave", UnitMenuRelease)

	f.warning = f:CreateFontString("GILUnitMenuWarning", "OVERLAY", "GameFontHighlightSmallLeft")
	f.warning:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -10)
	f.warning:SetPoint("RIGHT", f, "RIGHT", -11, 0)
	f.warning:SetJustifyH("LEFT")

	local b = CreateFrame("Button", "GILUnitMenuButton", f)

	b:SetHeight(16)
	b:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -10)
	b:SetPoint("RIGHT", f, "RIGHT", -11, 0)
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	b.text = b:CreateFontString("GILUnitMenuButtonText", "OVERLAY", "GameFontHighlightSmallLeft")
	b.text:SetPoint("LEFT", b, "LEFT", 0, 0)
	b.text:SetJustifyH("LEFT")
	b:SetScript("OnEnter", UnitMenuKeep)
	b:SetScript("OnLeave", UnitMenuRelease)
	b:SetScript("OnClick", function(self)
		local frame = self:GetParent()

		if frame.key then
			C_FriendList.AddOrDelIgnore(frame.key) -- GIL's wrapper: GIL list + server
			M.GILUpdateUI(true)
			UnitMenuUpdate(frame)
			UnitMenuPlace(frame)
		end
	end)

	f.button = b

	-- the panel is a child of DropDownList1, so it hides with every menu; it is also hidden
	-- here so another menu that reuses DropDownList1 never shows it
	DropDownList1:HookScript("OnHide", function() f:Hide() end)

	return f
end

-- post-hook of UnitPopup_ShowMenu (it runs inside UIDropDownMenu_Initialize): remember the player
function M.GIL_UnitPopupHook (dropdownMenu, which, unit, name)
	if UIDROPDOWNMENU_MENU_LEVEL ~= 1 then return end	-- never touch the level-2 menus

	unitPending = nil

	if unitMenu then
		unitMenu:Hide()
	end

	if V.GIL_Loaded ~= true or GlobalIgnoreDB.useUnitHacks ~= true then return end

	local key

	if GIL_UNIT_MENUS[which] and unit and UnitExists(unit) then
		if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end

		key = M.unitKey(unit)
	elseif GIL_NAME_MENUS[which] and dropdownMenu and dropdownMenu.name then
		-- these menus already have Blizzard's "Ignore" (it reaches GIL through the AddIgnore
		-- hooks); the panel only shows for players on GIL's list (cross-realm, list full, ...)
		key = M.key(dropdownMenu.name, dropdownMenu.server)

		if M.hasGlobalIgnored(key) == 0 then return end
	end

	if not key or key == V.playerName then return end

	unitPending = { owner = dropdownMenu, key = key }
end

-- post-hook of ToggleDropDownMenu: show the panel with the level-1 list that was just opened for
-- the remembered dropdown (UIDROPDOWNMENU_OPEN_MENU is set before the dropdown's init runs)
function M.GIL_ToggleDropDownHook (level)
	if (level or 1) ~= 1 then return end	-- a level-2 menu leaves the panel as it is

	local pending = unitPending

	unitPending = nil

	if not pending or not DropDownList1:IsShown() or UIDROPDOWNMENU_OPEN_MENU ~= pending.owner then
		if unitMenu then
			unitMenu:Hide()
		end

		return
	end

	unitMenu = unitMenu or CreateUnitMenu()
	unitMenu.key = pending.key

	UnitMenuUpdate(unitMenu)
	UnitMenuPlace(unitMenu)
	unitMenu:Show()
end

function M.GIL_HookUnitPopup ()
	if unitHooked then return end

	unitHooked = true

	-- the option is checked when a menu opens, so it needs no reload on 3.3.5a
	hooksecurefunc("UnitPopup_ShowMenu", M.GIL_UnitPopupHook)
	hooksecurefunc("ToggleDropDownMenu", M.GIL_ToggleDropDownHook)
end

-----------------------
-- ADDON COMPARTMENT --
-----------------------

if V.wowIsRetail == true then
	AddonCompartmentFrame:RegisterAddon({
		text = "Global Ignore List",
		icon = "Interface\\Icons\\ui_chat.blp",
		notCheckable = true,
		func = function(button, menuInputData, menu)
			M.GIL_GUI()
		end,
	})
end

--------------
-- UI HOOKS --
--------------

function M.GIL_HookFunctions()
	-- /script Menu.PrintOpenMenuTags()
	
	-- 3.3.5a: no LFG list tool and no Menu API; the unit menus get GIL's own panel instead
	if V.wowIs335 then
		M.GIL_HookUnitPopup()
		return
	end
	
	if GlobalIgnoreDB.useLFGHacks == true and (V.wowIsMOP or V.wowIsRetail) then
		hooksecurefunc("LFGListSearchEntry_Update", M.GIL_LFG_Update)
		hooksecurefunc("LFGListSearchEntry_OnEnter", M.GIL_LFG_Tooltip)
		
		Menu.ModifyMenu("MENU_LFG_FRAME_SEARCH_ENTRY", M.GIL_LFG_ApplicantMenu)
	end
	
	if GlobalIgnoreDB.useUnitHacks == true then
		Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", M.GIL_UnitMenuPlayer)
		Menu.ModifyMenu("MENU_UNIT_PLAYER", M.GIL_UnitMenuPlayer)
		Menu.ModifyMenu("MENU_UNIT_PARTY", M.GIL_UnitMenuPlayer)
		Menu.ModifyMenu("MENU_UNIT_RAID_PLAYER", M.GIL_UnitMenuPlayer)
	end
end
