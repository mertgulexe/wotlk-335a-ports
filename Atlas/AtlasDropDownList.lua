--[[

	AtlasDropDownList.lua - Atlas's own dropdown list (3.3.5a taint fix)

	Atlas's dropdowns used Blizzard's shared dropdown list (DropDownList1 and the
	UIDropDownMenu_* functions). Once a dropdown of Atlas had been opened, Blizzard's own
	dropdown code went on reading values that Atlas had written (UIDropDownMenu_AddButton
	reads the selection of the menu that was opened last). The next world map update then
	ran "tainted by Atlas", and in combat the client blocked it: "Interface action failed
	because of an AddOn" (WorldMapBlobFrame:Hide() / :Show()).

	The dropdowns keep their frames, names and look (UIDropDownMenuTemplate), but they open
	the private list below. Nothing in this file calls a Blizzard dropdown function, and
	nothing writes to a Blizzard frame, table or global variable. The list copies the look
	and the behaviour of the stock single-level list (UIDropDownMenu.lua and
	UIDropDownMenuTemplates.xml of 3.3.5a).

	This file is part of Atlas.

	Atlas is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	Atlas is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

--]]

--the numbers of the stock list
local BUTTON_HEIGHT = 16;	--UIDROPDOWNMENU_BUTTON_HEIGHT
local BORDER_HEIGHT = 15;	--UIDROPDOWNMENU_BORDER_HEIGHT
local SHOW_TIME = 2;		--UIDROPDOWNMENU_SHOW_TIME: seconds until the list hides after the mouse left it

local LIST_NAME = "AtlasDropDownList";

local list;				--the list frame, created when a dropdown is opened for the first time
local buttons = {};		--the rows of the list
local owner;			--the dropdown that the open list belongs to
local dropdowns = {};	--[dropdown frame] = its settings (see AtlasDropDown_Register)

local function StartCounting()
	list.showTimer = SHOW_TIME;
	list.isCounting = 1;
end

local function StopCounting()
	list.isCounting = nil;
end

--Hides the list, whichever dropdown it belongs to
function AtlasDropDown_Close()
	if ( list and list:IsShown() ) then
		list:Hide();
	end
end

--The hide timer works as in the stock list: it starts when the mouse leaves the list or a row,
--stops when the mouse comes back, and is cleared only when it runs out. A row that is hidden
--under the mouse (after a click) gets its OnLeave too, so, as with the stock list, a list that
--is opened again hides after 2 seconds unless the mouse goes onto it.
local function List_OnUpdate(self, elapsed)
	if ( not self.showTimer or not self.isCounting ) then
		return;
	elseif ( self.showTimer < 0 ) then
		self:Hide();
		self.showTimer = nil;
		self.isCounting = nil;
	else
		self.showTimer = self.showTimer - elapsed;
	end
end

local function List_OnHide(self)
	owner = nil;
end

local function Button_OnEnter(self)
	self.highlight:Show();
	StopCounting();
end

local function Button_OnLeave(self)
	self.highlight:Hide();
	StartCounting();
end

--A row was clicked: hide the list, then tell the dropdown which row it was
local function Button_OnClick(self)
	local settings = owner and dropdowns[owner];
	list:Hide();
	if ( settings and settings.click ) then
		settings.click(self:GetID());
		PlaySound("UChatScrollButton");
	end
end

local function CreateList()
	--no parent, like DropDownList1
	list = CreateFrame("Button", LIST_NAME);
	list:SetFrameStrata("FULLSCREEN_DIALOG");
	list:SetToplevel(true);
	list:EnableMouse(true);
	list:Hide();
	list:SetWidth(180);
	list:SetHeight(10);
	list:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 9 },
	});
	list:SetScript("OnClick", AtlasDropDown_Close);
	list:SetScript("OnEnter", StopCounting);
	list:SetScript("OnLeave", StartCounting);
	list:SetScript("OnUpdate", List_OnUpdate);
	list:SetScript("OnHide", List_OnHide);
end

local function CreateButton(index)
	local button = CreateFrame("Button", LIST_NAME.."Button"..index, list);
	button:SetID(index);
	button:SetWidth(100);
	button:SetHeight(BUTTON_HEIGHT);
	button:SetPoint("TOPLEFT", list, "TOPLEFT", 17, -((index - 1) * BUTTON_HEIGHT) - BORDER_HEIGHT);

	local highlight = button:CreateTexture(nil, "BACKGROUND");
	highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
	highlight:SetBlendMode("ADD");
	highlight:SetAllPoints(button);
	highlight:Hide();
	button.highlight = highlight;

	local check = button:CreateTexture(nil, "ARTWORK");
	check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
	check:SetWidth(18);
	check:SetHeight(18);
	check:SetPoint("LEFT", button, "LEFT", 0, 0);
	button.check = check;

	local text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallLeft");
	text:SetPoint("LEFT", button, "LEFT", 20, 0);
	button:SetFontString(text);
	button:SetNormalFontObject(GameFontHighlightSmallLeft);
	button:SetHighlightFontObject(GameFontHighlightSmallLeft);
	button.text = text;

	button:SetScript("OnClick", Button_OnClick);
	button:SetScript("OnEnter", Button_OnEnter);
	button:SetScript("OnLeave", Button_OnLeave);

	buttons[index] = button;
	return button;
end

--Fills the list with the entries, checks the selected one and sizes the list
local function FillList(entries, selected)
	local count = getn(entries);
	local maxWidth = 0;
	local button, width;
	for index = 1, count do
		button = buttons[index] or CreateButton(index);
		button:SetText(entries[index]);
		--the stock list anchors the text again after every SetText
		button.text:ClearAllPoints();
		button.text:SetPoint("LEFT", button, "LEFT", 20, 0);
		width = button.text:GetStringWidth() + 40;
		if ( width > maxWidth ) then
			maxWidth = width;
		end
		if ( index == selected ) then
			button.check:Show();
		else
			button.check:Hide();
		end
		button.highlight:Hide();
		button:Show();
	end
	for index = count + 1, getn(buttons) do
		buttons[index]:Hide();
	end
	for index = 1, count do
		buttons[index]:SetWidth(maxWidth);
	end
	list:SetWidth(maxWidth + 25);
	list:SetHeight((count * BUTTON_HEIGHT) + (BORDER_HEIGHT * 2));
	return count;
end

--The scale of the stock list: it has no parent and follows the UI scale
local function GetListScale()
	local uiParentScale = UIParent:GetScale();
	local uiScale = uiParentScale;
	if ( GetCVar("useUIScale") == "1" ) then
		uiScale = tonumber(GetCVar("uiscale")) or uiParentScale;
		if ( uiParentScale < uiScale ) then
			uiScale = uiParentScale;
		end
	end
	return uiScale;
end

--Opens the list of a dropdown, or closes it when it is open (as ToggleDropDownMenu does)
function AtlasDropDown_Toggle(dropdown)
	local settings = dropdowns[dropdown];
	if ( not settings ) then
		return;
	end
	if ( list and list:IsShown() and owner == dropdown ) then
		list:Hide();
		return;
	end
	if ( not list ) then
		CreateList();
	end

	list:SetScale(GetListScale());
	list:Hide();
	owner = dropdown;

	--below the left end of the dropdown, or below the frame the dropdown names as its anchor
	local relativeTo, xOffset, yOffset;
	if ( settings.anchor ) then
		relativeTo = getglobal(settings.anchor);
		xOffset = settings.xOffset or 0;
		yOffset = settings.yOffset or 0;
	else
		relativeTo = getglobal(dropdown:GetName().."Left");
		xOffset = 8;
		yOffset = 22;
	end
	local point = "TOPLEFT";
	list:ClearAllPoints();
	list:SetPoint(point, relativeTo, "BOTTOMLEFT", xOffset, yOffset);

	local selected;
	if ( settings.selected ) then
		selected = settings.selected();
	end
	if ( FillList(settings.entries(), selected) == 0 ) then
		owner = nil;
		return;
	end

	list:Show();
	local x, y = list:GetCenter();
	if ( not x or not y ) then
		list:Hide();
		return;
	end

	--off the screen: open upwards and/or to the left (the rules of the stock list)
	local offscreenY, offscreenX;
	if ( (y - list:GetHeight()/2) < 0 ) then
		offscreenY = 1;
	end
	if ( list:GetRight() > GetScreenWidth() ) then
		offscreenX = 1;
	end
	if ( offscreenY and offscreenX ) then
		point = "BOTTOMRIGHT";
	elseif ( offscreenY ) then
		point = "BOTTOMLEFT";
	elseif ( offscreenX ) then
		point = "TOPRIGHT";
	end
	list:ClearAllPoints();
	list:SetPoint(point, relativeTo, "BOTTOMLEFT", xOffset, yOffset);
end

--The arrow button of a dropdown was clicked
local function Arrow_OnClick(self)
	AtlasDropDown_Toggle(self:GetParent());
	PlaySound("igMainMenuOptionCheckBoxOn");
end

--A dropdown of Atlas was hidden (its window was closed): the list goes with it, whichever
--dropdown it belongs to. The template's script closed every dropdown list here.
local function DropDown_OnHide(self)
	AtlasDropDown_Close();
end

--Makes a frame that inherits UIDropDownMenuTemplate open Atlas's list.
--settings.entries():      returns the texts of the rows, in order
--settings.selected():     returns the number of the row to check (optional)
--settings.click(index):   called when a row is clicked
--settings.anchor, .xOffset, .yOffset: name of the frame the list opens under (optional;
--                         without it the list opens under the dropdown itself)
function AtlasDropDown_Register(dropdown, settings)
	if ( not dropdowns[dropdown] ) then
		--replace the two scripts of the template; both call Blizzard's dropdown code
		dropdown:SetScript("OnHide", DropDown_OnHide);
		getglobal(dropdown:GetName().."Button"):SetScript("OnClick", Arrow_OnClick);
	end
	dropdowns[dropdown] = settings;
end

--Shows the text of the selected row on the dropdown and sets the dropdown's width
--(what UIDropDownMenu_Initialize, _SetSelectedID and _SetWidth did). Closes the list.
function AtlasDropDown_Update(dropdown, width)
	local settings = dropdowns[dropdown];
	if ( not settings ) then
		return;
	end
	AtlasDropDown_Close();

	local name = dropdown:GetName();
	local text;
	if ( settings.selected ) then
		text = settings.entries()[settings.selected()];
	end
	if ( text ) then
		getglobal(name.."Text"):SetText(text);
	end
	if ( width ) then
		getglobal(name.."Middle"):SetWidth(width);
		dropdown:SetWidth(width + 25 + 25);
		getglobal(name.."Text"):SetWidth(width - 25);
	end
end

--The stock list is closed by CloseDropDownMenus and HideDropDownMenu, by CloseMenus (Escape)
--and when another dropdown opens. Atlas's list follows them. hooksecurefunc does not change
--these functions for anyone else.
hooksecurefunc("CloseDropDownMenus", function(level)
	if ( not level or level <= 1 ) then
		AtlasDropDown_Close();
	end
end);
hooksecurefunc("HideDropDownMenu", function(level)
	if ( not level or level <= 1 ) then
		AtlasDropDown_Close();
	end
end);
hooksecurefunc("ToggleDropDownMenu", function(level)
	if ( not level or level <= 1 ) then
		AtlasDropDown_Close();
	end
end);
hooksecurefunc("CloseMenus", AtlasDropDown_Close);
