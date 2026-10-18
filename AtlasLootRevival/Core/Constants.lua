local _, ns = ...

ns.Constants = {
    DISPLAY_NAME = "AtlasLoot Revival",
    VERSION = "0.2.4",
    DATABASE_VERSION = 5,
    CLIENT_ERA = "era",
    CLIENT_TBC = "tbc",
    CLIENT_WOTLK = "wotlk",
    -- Display order of the difficulty selector; also the set of valid difficulty keys.
    DIFFICULTY_ORDER = { "normal", "heroic", "raid10", "raid25", "raid10h", "raid25h" },
}

-- Value lookups (dropChances, *ByFlavor) fall back along this chain.
local FLAVOR_FALLBACK = {
    wotlk = "tbc",
    tbc = "era",
}

-- clientFlavors membership: only wotlk inherits from tbc, so era-only records stay
-- hidden in wotlk exactly as they are in tbc.
local MEMBERSHIP_FALLBACK = {
    wotlk = "tbc",
}

local VALID_DIFFICULTIES = {}
for _, difficulty in ipairs(ns.Constants.DIFFICULTY_ORDER) do
    VALID_DIFFICULTIES[difficulty] = true
end

local clientFlavor

function ns.Constants.GetClientFlavor()
    if clientFlavor then
        return clientFlavor
    end

    local interfaceVersion = tonumber((select(4, GetBuildInfo()))) or 0
    if interfaceVersion >= 30000
        and (interfaceVersion < 30400 or WOW_PROJECT_ID == nil) then
        -- 3.3.5a port: the interface version identifies 3.3.5a (30300). WOW_PROJECT_ID is
        -- ignored on 3.3.x: compat libraries such as !!!ClassicAPI define it (= 11).
        clientFlavor = ns.Constants.CLIENT_WOTLK
    elseif WOW_PROJECT_BURNING_CRUSADE_CLASSIC
        and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        clientFlavor = ns.Constants.CLIENT_TBC
    else
        clientFlavor = ns.Constants.CLIENT_ERA
    end
    return clientFlavor
end

function ns.Constants.IsValidDifficulty(difficulty)
    return VALID_DIFFICULTIES[difficulty] == true
end

-- First non-nil value of byFlavor[flavor] along the flavor fallback chain.
function ns.Constants.GetFlavorValue(byFlavor, flavor)
    if type(byFlavor) ~= "table" then
        return nil
    end
    flavor = flavor or ns.Constants.GetClientFlavor()
    while flavor do
        local value = byFlavor[flavor]
        if value ~= nil then
            return value
        end
        flavor = FLAVOR_FALLBACK[flavor]
    end
    return nil
end

local function IsExcluded(record, flavor)
    return type(record.excludedFlavors) == "table"
        and record.excludedFlavors[flavor] == true
end

-- Bosses, events and items: clientFlavors lists the flavors where the record exists.
function ns.Constants.SupportsRecordFlavor(record, flavor)
    if type(record) ~= "table" then
        return false
    end
    flavor = flavor or ns.Constants.GetClientFlavor()
    if IsExcluded(record, flavor) then
        return false
    end
    local flavors = record.clientFlavors
    if type(flavors) ~= "table" then
        return true
    end
    while flavor do
        if flavors[flavor] ~= nil then
            return flavors[flavor] == true
        end
        flavor = MEMBERSHIP_FALLBACK[flavor]
    end
    return false
end

local function InstanceInFlavor(instance, flavor)
    if instance.clientFlavors and instance.clientFlavors[flavor] then
        return true
    end

    if flavor == ns.Constants.CLIENT_WOTLK then
        return InstanceInFlavor(instance, ns.Constants.CLIENT_TBC)
    end

    return flavor == ns.Constants.CLIENT_TBC
        and instance.contentExpansion ~= "tbc"
        and instance.contentExpansion ~= "wotlk"
end

function ns.Constants.SupportsInstanceFlavor(instance, flavor)
    if type(instance) ~= "table" then
        return false
    end
    flavor = flavor or ns.Constants.GetClientFlavor()
    if IsExcluded(instance, flavor) then
        return false
    end
    return InstanceInFlavor(instance, flavor)
end
