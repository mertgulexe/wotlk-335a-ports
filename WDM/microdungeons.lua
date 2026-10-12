local WDM = LibStub("AceAddon-3.0"):GetAddon("WDM")
local MD = WDM:NewModule("MicroDungeons", "AceHook-3.0")

local LBZ = LibStub("LibBabble-Zone-3.0", true)
local BZ = LBZ and LBZ:GetLookupTable() or
               setmetatable({}, {__index = function(t, k) return k end})

local LBSZ = LibStub("LibBabble-SubZone-3.0", true)
local BSZ = LBSZ and LBSZ:GetLookupTable() or
                setmetatable({}, {__index = function(t, k) return k end})

local defaults = {
    profile = {
        ["show_minimap"] = false,
        ["show_zonelevel"] = false,
        ["show_taxinode"] = true,
        ["show_taxinode_opposite"] = false,
        ["show_taxinode_continent"] = true,
        ["show_taxinode_continent_opposite"] = false,
        ["show_instance"] = true,
        ["microdungeons"] = false,
        ["debugmode"] = false
    }
}

local data = {
    { -- Kalimdor
        ["Ashenvale"] = 43,
        ["Azshara"] = 181,
        ["Azuremyst Isle"] = 464,
        ["Bloodmyst Isle"] = 476,
        ["Darkshore"] = 42,
        ["Darnassus"] = 381,
        ["Desolace"] = 101,
        ["Durotar"] = 4,
        ["Dustwallow Marsh"] = 141,
        ["Felwood"] = 182,
        ["Feralas"] = 121,
        ["Moonglade"] = 241,
        ["Mulgore"] = 9,
        ["Orgrimmar"] = 321,
        ["Silithus"] = 261,
        ["Stonetalon Mountains"] = 81,
        ["Tanaris"] = 161,
        ["Teldrassil"] = 41,
        ["The Barrens"] = 11,
        ["The Exodar"] = 471,
        ["Thousand Needles"] = 61,
        ["Thunder Bluff"] = 362,
        ["Un'Goro Crater"] = 201,
        ["Winterspring"] = 281
    }, { -- Eastern Kingdoms
        ["Alterac Mountains"] = 15,
        ["Arathi Highlands"] = 16,
        ["Badlands"] = 17,
        ["Blasted Lands"] = 19,
        ["Burning Steppes"] = 29,
        ["Deadwind Pass"] = 32,
        ["Dun Morogh"] = 27,
        ["Duskwood"] = 34,
        ["Eastern Plaguelands"] = 23,
        ["Elwynn Forest"] = 30,
        ["Eversong Woods"] = 462,
        ["Ghostlands"] = 463,
        ["Hillsbrad Foothills"] = 24,
        ["Ironforge"] = 341,
        ["Isle of Quel'Danas"] = 499,
        ["Loch Modan"] = 35,
        ["Redridge Mountains"] = 36,
        ["Searing Gorge"] = 28,
        ["Silvermoon City"] = 480,
        ["Silverpine Forest"] = 21,
        ["Stormwind City"] = 301,
        ["Stranglethorn Vale"] = 37,
        ["Swamp of Sorrows"] = 38,
        ["The Hinterlands"] = 26,
        ["Tirisfal Glades"] = 20,
        ["Undercity"] = 382,
        ["Western Plaguelands"] = 22,
        ["Westfall"] = 39,
        ["Wetlands"] = 40
    }
}

local subzones = {
    ["Elwynn Forest"] = {
        ["Fargodeep Mine"] = 1001,
        ["Jasperlode Mine"] = 1019,
        ["Echo Ridge Mine"] = 1003
    },
    ["Dun Morogh"] = {
        ["Coldridge Pass"] = 1006,
        ["Frostmane Hold"] = 1008,
        ["Gol'Bolar Quarry"] = 1011,
        -- ["Frostmane Hovel"] = 1009,
        ["Gnomeregan"] = 1010
    }
}

local mdlevels = {
    ["Fargodeepmine1_"] = {"Elwynn", 1, 1001},
    ["Fargodeepmine2_"] = {"Elwynn", 2, 1002},
    ["EchoRidgeMine3_"] = {"Northshire", 3, 1003},
    ["GoldCoastQuarry4_"] = {"Westfall", 4, 1004},
    ["JangolodeMine5_"] = {"Westfall", 5, 1005},
    ["ColdridgePass6_"] = {"DunMorogh", 6, 1006},
    ["TheGrizzledDen7_"] = {"DunMorogh", 7, 1007},
    ["FrostmaneHold8_"] = {"NewTinkertown", 8, 1008},
    ["FrostmaneHovel9_"] = {"ColdridgeValley", 9, 1009},
    ["GnomereganEntrance10_"] = {"DunMorogh", 10, 1010},
    ["GolBolarQuarry11_"] = {"DunMorogh", 11, 1011},
    ["NightWebsHollow12_"] = {"Tirisfal", 12, 1012},
    ["ScarletMonasteryEntrance13_"] = {"Tirisfal", 13, 1013},
    ["BlackrockMountain14_"] = {"BurningSteppes", 14, 1014},
    ["BlackrockMountain15_"] = {"BurningSteppes", 15, 1015},
    ["BlackrockMountain16_"] = {"BurningSteppes", 16, 1016},
    ["DeadminesWestfall17_"] = {"Westfall", 17, 1017},
    ["Uldaman18_"] = {"Badlands", 18, 1018},
    ["JasperlodeMine19_"] = {"Elwynn", 19, 1019},
    ["Ogrimmar"] = {"Orgrimmar", 0, 321},
    ["Ogrimmar1_"] = {"Orgrimmar", 1, 1020},
    ["ShadowthreadCave2_"] = {"Teldrassil", 2, 1021},
    ["FelRock3_"] = {"Teldrassil", 3, 1022},
    ["BanethilBarrowden4_"] = {"Teldrassil", 4, 1023},
    ["BanethilBarrowden5_"] = {"Teldrassil", 5, 1024},
    ["PalemaneRock6_"] = {"Mulgore", 6, 1025},
    ["TheVentureCoMine7_"] = {"Mulgore", 7, 1026},
    ["BurningBladeCoven8_"] = {"Durotar", 8, 1027},
    ["TiragardeKeep10_"] = {"Durotar", 10, 1028},
    ["TiragardeKeep11_"] = {"Durotar", 11, 1029},
    ["SkullRock12_"] = {"Durotar", 12, 1030},
    ["TwilightsRun13_"] = {"Silithus", 13, 1031},
    ["TheSlitheringScar14_"] = {"UngoroCrater", 14, 1032},
    ["TheNoxiousLair15_"] = {"Tanaris", 15, 1033},
    ["TheGapingChasm16_"] = {"Tanaris", 16, 1034},
    ["CavernsofTime17_"] = {"Tanaris", 17, 1035},
    ["CavernsofTime18_"] = {"Tanaris", 18, 1036},
    ["DustwindCave19_"] = {"Durotar", 19, 1037},
    ["WailingCavernsBarrens20_"] = {"Barrens", 20, 1038},
    ["MaraudonOutside21_"] = {"Desolace", 21, 1039},
    ["MaraudonOutside22_"] = {"Desolace", 22, 1040},
    ["AmaniCatacombs1_"] = {"Ghostlands", 1, 1041},
    ["TidesHollow2_"] = {"AzermystIsle", 2, 1042},
    ["StillpineHold3_"] = {"AzermystIsle", 3, 1043}
}

function MD:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WDMdb", defaults, true)
    
    self.zone_names = {}
    self.zone_data = {}
    self.zone_set = {} -- 3.3.5a taint fix: localized zone name -> id, used by the zone-list filter
    self.zone_row_file = {} -- 3.3.5a taint fix: zone-list row -> map file seen on it (tells duplicates apart)

    for key, idata in pairs(data) do
        local names = {}
        local name_data = {}
        for name, zdata in pairs(idata) do
            tinsert(names, BZ[name])
            name_data[BZ[name]] = zdata
        end
        table.sort(names)
        self.zone_names[key] = names

        local zone_data = {}
        for k, v in pairs(names) do zone_data[k] = name_data[v] end
        self.zone_data[key] = zone_data
        self.zone_set[key] = name_data -- 3.3.5a taint fix
        self.zone_row_file[key] = {} -- 3.3.5a taint fix
    end
    data = nil

    self.mdlevels = {}

    for key, value in pairs(mdlevels) do
        if self.mdlevels[key] == nil then self.mdlevels[key] = {} end

        for k, v in pairs(mdlevels) do
            local k_match = string.match(k, "(.-)%d*_$") or k -- изменено здесь
            local key_match = string.match(key, "(.-)%d*_$") or key -- изменено здесь

            if k_match == key_match then
                table.insert(self.mdlevels[key], v)
            end
        end
    end

    for key, value in pairs(self.mdlevels) do
        table.sort(value, function(a, b) return a[2] < b[2] end)
    end

    mdlevels = nil

    self.sub_zones = {}

    for key, value in pairs(subzones) do
        local names = {}
        local lkey = BZ[key]
        for name, zdata in pairs(value) do tinsert(names, BSZ[name]) end
        table.sort(names)

        self.sub_zones[lkey] = names
    end

    subzones = nil

end

function MD:OnEnable()
    self:CreateLevelDropDown() -- 3.3.5a taint fix
    self:SecureHook("WorldMapLevelDropDown_Update")
    -- 3.3.5a taint fix: filter Blizzard's zone list instead of re-initializing WorldMapZoneDropDown (see below)
    self:SecureHook("WorldMapFrame_LoadZones")
    WorldMapLevelUpButton:HookScript("OnClick", DungeonMapLevelUp_OnClick)
    WorldMapLevelDownButton:HookScript("OnClick", DungeonMapLevelDown_OnClick)
end

-- 3.3.5a taint fix: the cave levels are listed in WDM's own dropdown, placed over Blizzard's floor dropdown (which
-- Blizzard hides on cave maps). WDM used to re-initialize WorldMapLevelDropDown from addon code
-- (UIDropDownMenu_Initialize/SetSelectedID), which tainted fields Blizzard reads on the next map update.
function MD:CreateLevelDropDown()
    if self.levelDropDown then return end
    local dd = CreateFrame("Frame", "WDM_MicroDungeonLevelDropDown", WorldMapLevelDropDown:GetParent(),
                           "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", WorldMapLevelDropDown, "TOPLEFT")
    dd:SetFrameLevel(WorldMapLevelDropDown:GetFrameLevel())
    local header = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", 20, 10)
    header:SetText(FLOOR)
    UIDropDownMenu_SetWidth(dd, 130)
    dd.initialize = MicroDungeonLevelDropDown_Initialize
    dd:Hide()
    self.levelDropDown = dd
end

local function MicroDungeonLevelName(entry)
    return WDM:GetFloorName(entry[1]:upper(), entry[2]) or string.format(FLOOR_NUMBER, entry[2])
end

-- 3.3.5a taint fix: switching caves needs SetMapByID from addon code, which runs Blizzard's map update
-- insecurely; 3.3.5a has no secure way to do it. In combat that blocks WorldMapBlobFrame, so WDM refuses there.
local switchNoticeShown
local function MicroDungeonSwitchAllowed()
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.1, 0.1, 1.0)
        return false
    end
    if not switchNoticeShown then
        switchNoticeShown = true
        print("[WDM] Switching cave levels changes the map from addon code: the world map may fail to open in combat until you /reload.")
    end
    return true
end

function MD:WorldMapLevelDropDown_Update()
    local mapName, _, _ = GetMapInfo()
    local dd = self.levelDropDown
    if not self.mdlevels[mapName] or not self.db.profile.microdungeons then
        if dd and dd:IsShown() then dd:Hide() end -- 3.3.5a taint fix
        return
    end

    -- 3.3.5a taint fix: show WDM's own dropdown; Blizzard's WorldMapLevelDropDown is left alone
    UIDropDownMenu_SetText(dd, MicroDungeonLevelName(self.mdlevels[mapName][GetCurrentMicroDungeonLevel()]))
    dd:Show()
    if (WORLDMAP_SETTINGS.size ~= WORLDMAP_WINDOWED_SIZE) then
        WorldMapLevelUpButton:Show();
        WorldMapLevelDownButton:Show();
    end
    if self.mdlevels[mapName][GetCurrentMicroDungeonLevel()][2] ~= 0 then
        for i = 1, NUM_WORLDMAP_ATLAS_POI do
            _G["WorldMapFrameAtlasPOI" .. i]:Hide()
        end
    end
end

function DungeonMapLevelUp_OnClick(self)
    local mapName, _, _ = GetMapInfo()
    if not MD.mdlevels[mapName] then return end

    if GetCurrentMicroDungeonLevel() > 1 and MicroDungeonSwitchAllowed() then -- 3.3.5a taint fix: combat check
        -- 3.3.5a taint fix: no UIDropDownMenu_SetSelectedID on Blizzard's WorldMapLevelDropDown; the map
        -- update that SetMapByID fires refreshes WDM's dropdown
        SetMapByID(MD.mdlevels[mapName][GetCurrentMicroDungeonLevel() - 1][3]);
        PlaySound("UChatScrollButton");
    end
end

function DungeonMapLevelDown_OnClick(self)
    local mapName, _, _ = GetMapInfo()
    if not MD.mdlevels[mapName] then return end

    if GetCurrentMicroDungeonLevel() < #MD.mdlevels[mapName] and MicroDungeonSwitchAllowed() then -- 3.3.5a taint fix
        -- 3.3.5a taint fix: no UIDropDownMenu_SetSelectedID on Blizzard's WorldMapLevelDropDown
        SetMapByID(MD.mdlevels[mapName][GetCurrentMicroDungeonLevel() + 1][3]);
        PlaySound("UChatScrollButton");
    end
end

function GetCurrentMicroDungeonLevel()
    local mapName, _, _ = GetMapInfo()
    local curmdlist = MD.mdlevels[mapName]
    if not curmdlist then return 1 end

    local match = tonumber(string.match(mapName, "%d+"))
    if match == nil then match = 0 end

    for i = 1, #curmdlist do if curmdlist[i][2] == match then return i end end
    
    return 1
end

function MicroDungeonLevelDropDown_Initialize()
    local info = UIDropDownMenu_CreateInfo()
    local level = GetCurrentMicroDungeonLevel()
    local curmd = MD.mdlevels[GetMapInfo()]
    if not curmd then return end -- 3.3.5a taint fix: WDM's own dropdown can be opened on any map

    for i = 1, #curmd do
        info.text = MicroDungeonLevelName(curmd[i]); -- 3.3.5a taint fix: names from WDM_DUNGEON_FLOORS
        info.func = MicroDungeonLevelButton_OnClick;
        info.checked = (i == level);
        UIDropDownMenu_AddButton(info);
    end
end

function MicroDungeonLevelButton_OnClick(self)
    if not MicroDungeonSwitchAllowed() then return end -- 3.3.5a taint fix: combat check
    -- 3.3.5a taint fix: no UIDropDownMenu_SetSelectedID on Blizzard's WorldMapLevelDropDown
    SetMapByID(MD.mdlevels[GetMapInfo()][self:GetID()][3]);
end

-- 3.3.5a taint fix: WDM no longer replaces Blizzard's zone dropdown. Its UIDropDownMenu_Initialize/SetSelectedID
-- calls on WorldMapZoneDropDown tainted fields that Blizzard reads on every map update, and its own zone buttons
-- changed the map with SetMapByID from addon code. Blizzard now builds the zone list itself; afterwards WDM hides
-- the rows that are not in its zone list (the extra patch-N entries) and closes the gaps, with widget calls only.
-- A click still runs Blizzard's own WorldMapZoneButton_OnClick.
function MD:WorldMapFrame_LoadZones(...)
    local cont = GetCurrentMapContinent()
    local zones = self.zone_set[cont]
    if not zones then return end
    local count = select("#", ...)
    -- 3.3.5a taint fix: patch-N also lists a cave under a zone's own name (Kalimdor has a second "Orgrimmar" row,
    -- the Cleft of Shadow map "Ogrimmar1_"). Names cannot tell the two apart, so remember the map file of the row
    -- that is shown (read-only API calls); cave map files end in "_".
    local rowFile = self.zone_row_file[cont]
    local cur = GetCurrentMapZone()
    if cur and cur > 0 and cur <= count then rowFile[cur] = GetMapInfo() end
    if not self.db.profile.microdungeons then return end
    local first = (DropDownList1.numButtons or 0) - count -- Blizzard added one row per zone to DropDownList1
    if count == 0 or first < 0 then return end

    local rows, real = {}, {} -- zone name -> number of rows with it / the row known to be the zone itself
    for i = 1, count do
        local name = select(i, ...)
        if zones[name] then
            rows[name] = (rows[name] or 0) + 1
            if rowFile[i] and not rowFile[i]:find("_$") then real[name] = i end
        end
    end
    local keepRow, keep, found = {}, 0, 0
    for _ in pairs(rows) do found = found + 1 end
    for i = 1, count do
        local name = select(i, ...)
        local k = zones[name] ~= nil
        if k and rows[name] > 1 then -- a duplicate name: drop the row known to be a cave (both stay while unknown)
            if real[name] then k = (real[name] == i) else k = not (rowFile[i] and rowFile[i]:find("_$")) end
        end
        keepRow[i] = k
        if k then keep = keep + 1 end
    end
    -- nothing to hide, or some of WDM's zone names were not found (e.g. a translation differs): leave the list as is
    if keep == count or found < #self.zone_names[cont] then return end

    local row = first
    for i = 1, count do
        local button = _G["DropDownList1Button" .. (first + i)]
        if keepRow[i] then
            row = row + 1
            for p = 1, button:GetNumPoints() do
                local point, relativeTo, relativePoint, x = button:GetPoint(p)
                if point == "TOPLEFT" then
                    button:SetPoint("TOPLEFT", relativeTo, relativePoint, x,
                                    -((row - 1) * UIDROPDOWNMENU_BUTTON_HEIGHT) - UIDROPDOWNMENU_BORDER_HEIGHT)
                    break
                end
            end
        else
            button:Hide()
        end
    end
    DropDownList1:SetHeight((row * UIDROPDOWNMENU_BUTTON_HEIGHT) + (UIDROPDOWNMENU_BORDER_HEIGHT * 2))
end

function MD:OnDisable()
    self:UnhookAll()
    -- 3.3.5a taint fix: Blizzard's dropdowns rebuild themselves on the next map update; only hide WDM's own
    -- dropdown (was WorldMapLevelDropDown_Update() and WorldMapZoneDropDown_Update() from addon code)
    if self.levelDropDown then self.levelDropDown:Hide() end
end
