-- 3.3.5a port: which floor of the current instance the player is on, so the map opens on it.
--   * Live: the sub-zone name (GetSubZoneText/GetMinimapZoneText) looked up in Data/WotLK/SubzoneFloors.lua,
--     made from the client's own map DBCs. Remembered when the player walks into an unnamed area.
--   * Otherwise: the floor the game itself last placed the player on. A post-hook on SetMapToCurrentZone
--     reads it after Blizzard's code calls it (on entering the instance, and when the world map opens).
-- Read-only API calls only. The world map is never changed from here: SetMapToCurrentZone from addon code
-- would run Blizzard's world map and quest tracker updates insecurely ("Interface action failed" in combat).
local _, ns = ...

local FloorTracker = ns:RegisterModule("FloorTracker", {})

local lookups = {}     -- [instance map ID] = { [lower-case sub-zone] = level } or false
local subzoneSeen = {} -- [instance map ID] = { level, time }: last floor known from a sub-zone name
local mapPlaced = {}   -- [lower-case map folder] = { level, time }: last floor the game placed the player on

local function Normalize(text)
    if type(text) ~= "string" then
        return nil
    end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return nil
    end
    return text:lower()
end

local function Lookup(mapID)
    if not mapID then
        return nil
    end
    local lookup = lookups[mapID]
    if lookup == nil then
        lookup = false
        local data = ns.Data.subzoneFloors and ns.Data.subzoneFloors[mapID]
        if data then
            lookup = {}
            for name, level in pairs(data) do
                local key = Normalize(name)
                if key then
                    lookup[key] = level
                end
            end
        end
        lookups[mapID] = lookup
    end
    return lookup or nil
end

local function SubzoneLevel(mapID)
    local lookup = Lookup(mapID)
    if not lookup then
        return nil
    end
    for _, text in ipairs({ GetSubZoneText(), GetMinimapZoneText() }) do
        local key = Normalize(text)
        if key and lookup[key] then
            return lookup[key]
        end
    end
    return nil
end

local function CurrentInstance()
    local window = ns.modules.MainWindow
    local instanceKey = window and window.GetCurrentInstanceKey and window:GetCurrentInstanceKey()
    return instanceKey and ns.Data.instances[instanceKey]
end

-- Dungeon level of the floor the player is on in this instance (0 = the terrain map), or nil.
function FloorTracker:GetFloorLevel(instance)
    if type(instance) ~= "table" then
        return nil
    end
    local level = SubzoneLevel(instance.instanceID)
    if level then
        return level
    end
    local best, bestTime
    local seen = instance.instanceID and subzoneSeen[instance.instanceID]
    if seen then
        best, bestTime = seen.level, seen.time
    end
    local folder = instance.map and Normalize(instance.map.textureFolder)
    local placed = folder and mapPlaced[folder]
    if placed and (not bestTime or placed.time > bestTime) then
        best = placed.level
    end
    return best
end

local function OnZoneChanged()
    local instance = CurrentInstance()
    local level = instance and SubzoneLevel(instance.instanceID)
    if level then
        subzoneSeen[instance.instanceID] = { level = level, time = GetTime() }
    end
end

hooksecurefunc("SetMapToCurrentZone", function()
    local folder = Normalize(GetMapInfo())
    local level = GetCurrentMapDungeonLevel()
    if not folder or not level or level <= 0 then
        return
    end
    if DungeonUsesTerrainMap and DungeonUsesTerrainMap() then
        level = level - 1
    end
    mapPlaced[folder] = { level = level, time = GetTime() }
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", OnZoneChanged)
