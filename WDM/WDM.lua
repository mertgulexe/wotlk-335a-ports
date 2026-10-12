local WDM = LibStub("AceAddon-3.0"):NewAddon("WDM", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("WDM")

local options = {
    name = "WoW Dungeon Maps",
    handler = WDM,
    type = "group",
    args = {
        show_minimap = {
            type = "toggle",
            name = L["show_minimap_text"],
            desc = L["show_minimap_warn_text"],
            get = "GetMinimap",
            set = "ToggleMinimap",
            descStyle = "inline",
            width = "double",
        },
        microdungeons = {
            type = "toggle",
            name = L["microdungeons_text"],
            desc = L["microdungeons_warn_text"],
            get = "GetMicrodungeons",
            set = "ToggleMicrodungeons",
            descStyle = "inline",
            width = "double",
        },
    },
}

local defaults = { profile = {
    ["show_minimap"] = false,
    ["show_zonelevel"] = false,
    ["show_taxinode"] = true,
    ["show_taxinode_opposite"] = false,
    ["show_taxinode_continent"] = true,
    ["show_taxinode_continent_opposite"] = false,
    ["show_instance"] = true,
    ["microdungeons"] = false,
    ["debugmode"] = false,
},}


function WDM:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WDMdb", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("WDM", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WDM", "WoW Dungeon Maps")
    self:RegisterChatCommand("wdm", "ChatCommand")
end

-- 3.3.5a taint fix: the floor names from locales\global live in WDM_DUNGEON_FLOORS instead of DUNGEON_FLOOR_*
-- globals (Blizzard's WorldMapLevelDropDown_Initialize read the WDM-written globals, which tainted the world map
-- update). Blizzard now builds its floor list with "Area N" for those floors, and WDM relabels the rows after it.
-- Only widget calls (SetText/SetWidth) on Blizzard's list buttons; no Blizzard variable is written.
function WDM:GetFloorName(mapName, floorNum)
    local key = "DUNGEON_FLOOR_" .. mapName .. floorNum
    return _G[key] or (WDM_DUNGEON_FLOORS and WDM_DUNGEON_FLOORS[key])
end

function WDM:WorldMapLevelDropDown_Initialize()
    local numLevels = GetNumDungeonMapLevels() or 0
    -- Blizzard added one row per floor to DropDownList1
    local first = (DropDownList1.numButtons or 0) - numLevels
    if numLevels == 0 or first < 0 then return end
    local mapName = strupper(GetMapInfo() or "")
    local usesTerrainMap = DungeonUsesTerrainMap()
    for i = 1, numLevels do
        local name = self:GetFloorName(mapName, usesTerrainMap and (i - 1) or i)
        local button = _G["DropDownList1Button" .. (first + i)]
        if name and button then
            button:SetText(name)
        end
    end
end

-- 3.3.5a taint fix: widen the open floor list for the relabelled rows (its OnShow sized it for "Area N")
function WDM:ToggleDropDownMenu(level)
    if (level or 1) ~= 1 or UIDROPDOWNMENU_OPEN_MENU ~= WorldMapLevelDropDown or not DropDownList1:IsShown() then
        return
    end
    local width = 0
    for i = 1, DropDownList1.numButtons or 0 do
        local w = _G["DropDownList1Button" .. i .. "NormalText"]:GetWidth() + 40
        if w > width then width = w end
    end
    if width + 25 > DropDownList1:GetWidth() then
        for i = 1, DropDownList1.numButtons do
            _G["DropDownList1Button" .. i]:SetWidth(width)
        end
        DropDownList1:SetWidth(width + 25)
    end
end

function WDM:OnEnable()
    self:SecureHook("WorldMapLevelDropDown_Initialize") -- 3.3.5a taint fix: floor names (see above)
    self:SecureHook("ToggleDropDownMenu") -- 3.3.5a taint fix: floor list width (see above)
end

function WDM:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    elseif input == "debug" then
        -- Toggle the debug option
        self:SetDebug(nil, not self:GetDebug())
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("wdm", "WDM", input)
    end
end

function WDM:GetDebug(info)
    return self.db.profile.debugmode
end

function WDM:SetDebug(info, value)
    self.db.profile.debugmode = value
    if self.db.profile.debugmode then
        print("[WDM] Debugging |c00569C08enabled|r")
    else
        print("[WDM] Debugging |c00FD1A36disabled|r")
    end
end

function WDM:GetMicrodungeons(info)
    return self.db.profile.microdungeons
end

function WDM:GetMinimap(info)
    return self.db.profile.show_minimap
end

function WDM:ToggleMicrodungeons(info, value)
    self.db.profile.microdungeons = value
end

function WDM:ToggleMinimap(info, value)
    self.db.profile.show_minimap = value
end