-- Dungeon map viewer (3.3.5a port addition): clicking a dungeon or raid entrance icon on the world map
-- shows that instance's own map over the zone map, with its floors. Everything here is WDM's own frames
-- and textures laid over Blizzard's map: the world map itself is never switched, because SetMapByID
-- from addon code would taint Blizzard's map update (the world map could then fail in combat).
-- Map data: dungeonmapdata.lua (generated from the client's map DBCs and AtlasLootRevival's instance data).

local WDM = LibStub("AceAddon-3.0"):GetAddon("WDM")
local DungeonMap = WDM:NewModule("DungeonMap", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("WDM")

local LBZ = LibStub("LibBabble-Zone-3.0", true)
local BZ = LBZ and LBZ:GetLookupTable() or setmetatable({}, {__index = function(t, k) return k end})

-- Blizzard's map detail area is 1002x668 units, drawn with 4x3 tiles of 256 (the tiles overhang it)
local MAP_WIDTH, MAP_HEIGHT, TILE = 1002, 668, 256
local COLUMNS, ROWS = 4, 3

-- the data's floor names are English; other clients use Blizzard's/WDM's names or "Area N"
local ENGLISH_CLIENT = (GetLocale() == "enUS" or GetLocale() == "enGB")

-- Maps are looked up by kind ("dungeon"/"raid", as on the entrance icons) and name: in some languages
-- two entrances share a name (esES: Trial of the Champion and Trial of the Crusader).
local function MapKey(kind, name)
    return tostring(kind) .. ":" .. tostring(name)
end

function DungeonMap:OnInitialize()
    self.maps = {}
    for name, map in pairs(WDM_DUNGEON_MAP_DATA or {}) do
        local kind = map.kind or "dungeon"
        self.maps[MapKey(kind, name)] = map
        -- the entrance icons carry the localized name (BZ), as in _data.lua
        local ok, localized = pcall(function() return BZ[name] end)
        if ok and type(localized) == "string" then
            self.maps[MapKey(kind, localized)] = map
        end
    end
end

function DungeonMap:OnEnable()
    self:SecureHook("WorldMapFrame_Update", "OnWorldMapUpdate")
    self:SecureHook("WorldMapFrame_SetOpacity", "ApplyOpacity")
    -- Blizzard's quest-area (blob) tooltip only tests the map's rectangle, not the mouse focus, so it would
    -- pop up over the viewer. Post-hook: right after Blizzard's handler, in the same frame.
    if WorldMapBlobFrame then
        self:SecureHookScript(WorldMapBlobFrame, "OnUpdate", "MuteBlobTooltip")
    end
end

function DungeonMap:OnDisable()
    self:Close()
    self:UnhookAll()
end

function DungeonMap:HasMap(kind, name)
    return name ~= nil and self.maps[MapKey(kind, name)] ~= nil
end

function DungeonMap:IsShown()
    return self.frame ~= nil and self.frame:IsShown()
end

-- Identifies the map Blizzard shows; the viewer closes when it changes (zoom out, other zone, ...).
local function CurrentWorldMapKey()
    return string.format("%s:%d:%d:%d", GetMapInfo() or "", GetCurrentMapContinent() or 0,
        GetCurrentMapZone() or 0, GetCurrentMapDungeonLevel() or 0)
end

local function CreateArrowButton(parent, direction)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(26, 26)
    local base = "Interface\\Buttons\\UI-SpellbookIcon-" .. direction .. "Page-"
    button:SetNormalTexture(base .. "Up")
    button:SetPushedTexture(base .. "Down")
    button:SetDisabledTexture(base .. "Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return button
end

-- Above the map's icons and the player arrow (Blizzard: POIs at WORLDMAP_POI_FRAMELEVEL, the arrow at
-- +100). Set on the viewer and on its child frames, which are not raised along with their parent.
function DungeonMap:SetLevels()
    local f = self.frame
    local base = (WORLDMAP_POI_FRAMELEVEL or 100) + 110
    f:SetFrameLevel(base)
    f.nav:SetFrameLevel(base + 1)
    f.prev:SetFrameLevel(base + 2)
    f.next:SetFrameLevel(base + 2)
    f.close:SetFrameLevel(base + 2)
end

function DungeonMap:CreateFrame()
    local f = CreateFrame("Frame", "WDM_DungeonMapFrame", WorldMapButton)
    f:SetAllPoints(WorldMapDetailFrame)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:Hide()

    local background = f:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(f)
    background:SetTexture(0, 0, 0, 1)
    f.background = background

    f.tiles = {}
    for i = 1, COLUMNS * ROWS do
        f.tiles[i] = f:CreateTexture("WDM_DungeonMapTile" .. i, "BORDER")
    end

    f.missing = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.missing:SetPoint("CENTER")
    f.missing:SetWidth(600)
    f.missing:SetText(L["dungeonmap_no_art_text"])

    -- 3.3.5a port: the floor name is shown in WDM's own tooltip, a child of WorldMapFrame. GameTooltip is a
    -- child of UIParent, which the full-screen map hides, and Blizzard's quest-area code hides WorldMapTooltip
    -- whenever the mouse is over the map and not over a quest (WorldMapBlobFrame_OnUpdate).
    local tip = CreateFrame("GameTooltip", "WDM_DungeonMapTooltip", WorldMapFrame, "GameTooltipTemplate")
    tip:SetFrameStrata("TOOLTIP")
    f.tooltip = tip

    -- floor switcher, only on maps with several floors: two arrows and "1/3"; the floor's name is
    -- shown when the mouse is over the counter
    local nav = CreateFrame("Frame", nil, f)
    nav:SetPoint("TOP", f, "TOP", 0, -8)
    nav:SetSize(110, 28)
    nav:EnableMouse(true)
    nav:SetScript("OnEnter", function(self)
        local name = DungeonMap:CurrentFloorName()
        if name then
            -- 3.3.5a port: strata set again on every show, as Blizzard does for WorldMapTooltip after the
            -- map size toggle re-parents WorldMapFrame (WorldMap_ToggleSizeUp/Down)
            tip:SetFrameStrata("TOOLTIP")
            tip:SetOwner(self, "ANCHOR_BOTTOM")
            tip:SetText(name, 1, 1, 1)
            tip:Show()
        end
    end)
    nav:SetScript("OnLeave", function() tip:Hide() end) -- 3.3.5a port: WDM's own tooltip
    f.nav = nav

    f.counter = nav:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.counter:SetPoint("CENTER")

    f.prev = CreateArrowButton(nav, "Prev")
    f.prev:SetPoint("LEFT", nav, "LEFT", 0, 0)
    f.prev:SetScript("OnClick", function() DungeonMap:ShowFloor(DungeonMap.floor - 1) end)
    f.next = CreateArrowButton(nav, "Next")
    f.next:SetPoint("RIGHT", nav, "RIGHT", 0, 0)
    f.next:SetScript("OnClick", function() DungeonMap:ShowFloor(DungeonMap.floor + 1) end)

    -- top-right corner, left of WDM's tracking button (which sits in the corner, TOOLTIP strata)
    local close = CreateFrame("Button", "WDM_DungeonMapCloseButton", f, "UIPanelCloseButton")
    if WDM_WorldMapButton then
        close:SetPoint("RIGHT", WDM_WorldMapButton, "LEFT", -2, 0)
    else
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    end
    close:SetScript("OnClick", function() DungeonMap:Close() end)
    f.close = close

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
    f.hint:SetJustifyH("LEFT")

    -- right-click goes back to the zone map, like Blizzard's right-click zooms out. A mouse button bound
    -- to the world map toggle (handled by Blizzard's WorldMapButton click, which the viewer covers)
    -- closes the viewer, so the next press closes the map as usual.
    f:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" or GetBindingFromClick(button) == "TOGGLEWORLDMAP" then
            DungeonMap:Close()
        end
    end)
    f:SetScript("OnMouseWheel", function(_, delta)
        DungeonMap:ShowFloor(DungeonMap.floor - delta)
    end)
    f:SetScript("OnSizeChanged", function() DungeonMap:LayoutTiles() end)
    -- closing the world map closes the viewer too, so the map opens on the zone next time
    f:SetScript("OnHide", function(self)
        if not WorldMapFrame:IsShown() then self:Hide() end
        tip:Hide() -- 3.3.5a port: the floor-name tooltip goes with the viewer
        DungeonMap:MuteBlobTooltip() -- restores the quest tooltip once the viewer is closed
    end)

    self.frame = f
end

-- The windowed map's opacity setting fades the zone map (WorldMapDetailFrame); fade the dungeon map alike.
function DungeonMap:ApplyOpacity()
    local f = self.frame
    if not f then return end
    local alpha = WorldMapDetailFrame:GetAlpha()
    f.background:SetAlpha(alpha)
    for _, tile in ipairs(f.tiles) do tile:SetAlpha(alpha) end
end

-- While the viewer is open, make the quest-area tooltip Blizzard shows for the zone map underneath
-- invisible. Alpha only: no Lua field of Blizzard's is written and no tooltip handler runs (Hide() would
-- run GameTooltip_OnHide insecurely). Only Blizzard's quest tooltips are owned by WorldMapFrame.
function DungeonMap:MuteBlobTooltip()
    local mute = self:IsShown() and WorldMapTooltip:GetOwner() == WorldMapFrame
    if mute then
        WorldMapTooltip:SetAlpha(0)
        self.tooltipMuted = true
    elseif self.tooltipMuted then
        WorldMapTooltip:SetAlpha(1)
        self.tooltipMuted = nil
    end
end

-- Same tile grid as Blizzard's WorldMapDetailTile1-12, cut to the 1002x668 map area so the
-- overhanging parts of the right column and the bottom row don't cover the frame around the map.
function DungeonMap:LayoutTiles()
    local f = self.frame
    local scale = f:GetWidth() / MAP_WIDTH
    if not scale or scale <= 0 then return end
    for row = 1, ROWS do
        for col = 1, COLUMNS do
            local tile = f.tiles[(row - 1) * COLUMNS + col]
            local w = math.min(TILE, MAP_WIDTH - (col - 1) * TILE)
            local h = math.min(TILE, MAP_HEIGHT - (row - 1) * TILE)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", f, "TOPLEFT", (col - 1) * TILE * scale, -(row - 1) * TILE * scale)
            tile:SetSize(w * scale, h * scale)
            tile:SetTexCoord(0, w / TILE, 0, h / TILE)
        end
    end
end

-- Blizzard's/WDM's localized name for this floor level, else the English name on English clients
function DungeonMap:FloorName(level, english)
    local name = WDM:GetFloorName(self.map[1]:upper(), level)
    if not name and ENGLISH_CLIENT and english ~= "" then name = english end
    return name
end

-- shown when the mouse is over the floor counter
function DungeonMap:CurrentFloorName()
    local floor = self.map and self.map[(self.floor or 1) + 1]
    if not floor then return nil end
    return self:FloorName(floor[2], floor[3]) or string.format(FLOOR_NUMBER, self.floor)
end

function DungeonMap:ShowFloor(index)
    local map = self.map
    if not map then return end
    local count = #map - 1
    index = math.max(1, math.min(index or 1, count))
    self.floor = index

    local f = self.frame
    local folder = map[1]
    local prefix = map[index + 1][1]
    local loaded = false
    for i, tile in ipairs(f.tiles) do
        if tile:SetTexture("Interface\\WorldMap\\" .. folder .. "\\" .. prefix .. i) then
            loaded = true
        end
    end
    for _, tile in ipairs(f.tiles) do
        if loaded then tile:Show() else tile:Hide() end
    end
    if loaded then f.missing:Hide() else f.missing:Show() end

    if count > 1 then
        f.counter:SetText(string.format("%d/%d", index, count))
        if index > 1 then f.prev:Enable() else f.prev:Disable() end
        if index < count then f.next:Enable() else f.next:Disable() end
        f.nav:Show()
        f.hint:SetText(L["dungeonmap_hint_floors_text"])
    else
        f.nav:Hide()
        f.hint:SetText(L["dungeonmap_hint_text"])
    end
    -- refresh the floor name if the mouse is on the counter (switched with the arrows or the wheel)
    -- 3.3.5a port: in WDM's own tooltip; hidden when the new map has no counter
    if f.tooltip:IsShown() and f.tooltip:IsOwned(f.nav) then
        if f.nav:IsShown() then f.nav:GetScript("OnEnter")(f.nav) else f.tooltip:Hide() end
    end
end

function DungeonMap:Open(kind, name)
    local map = self.maps[MapKey(kind, name)]
    if not map then return false end
    if not self.frame then self:CreateFrame() end
    local f = self.frame
    self.map = map
    self.name = name
    self.mapKey = CurrentWorldMapKey()
    self:SetLevels()
    f:Show()
    self:LayoutTiles()
    self:ApplyOpacity()
    self:ShowFloor(1)
    PlaySound("igMainMenuOptionCheckBoxOn")
    return true
end

function DungeonMap:Close()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    end
end

function DungeonMap:OnWorldMapUpdate()
    if self:IsShown() and CurrentWorldMapKey() ~= self.mapKey then
        self:Close()
    end
end
