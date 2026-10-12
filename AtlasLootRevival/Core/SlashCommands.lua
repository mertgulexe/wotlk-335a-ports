local _, ns = ...

local SlashCommands = ns:RegisterModule("SlashCommands", {})

local FLAVOR_LABELS = {
    era = "FLAVOR_ERA",
    tbc = "FLAVOR_TBC",
    wotlk = "FLAVOR_WOTLK",
}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd6a84bAtlasLoot Revival:|r " .. message)
end

local function CountVisibleItems(record, flavor)
    local count = 0
    for _, item in ipairs(record.items or {}) do
        if ns.Constants.SupportsRecordFlavor(item, flavor) then
            count = count + 1
        end
    end
    return count
end

local function GetCatalogStatus()
    local flavor = ns.Constants.GetClientFlavor()
    local dungeonCount = 0
    local raidCount = 0
    local encounterCount = 0
    local relationCount = 0
    local expansionCounts = { classic = 0, tbc = 0, wotlk = 0 }
    for instanceKey, instance in pairs(ns.Data.instances) do
        if ns.Constants.SupportsInstanceFlavor(instance, flavor) then
            if instance.contentType == "raid" then
                raidCount = raidCount + 1
            else
                dungeonCount = dungeonCount + 1
            end
            local expansion = expansionCounts[instance.contentExpansion]
                and instance.contentExpansion or "classic"
            expansionCounts[expansion] = expansionCounts[expansion] + 1
            local instanceLoot = ns.Data.loot[instanceKey] or {}
            for _, bossKey in ipairs(instance.bosses or {}) do
                local boss = instanceLoot[bossKey]
                if bossKey ~= "trash_drops"
                    and ns.Constants.SupportsRecordFlavor(boss, flavor) then
                    encounterCount = encounterCount + 1
                    relationCount = relationCount + CountVisibleItems(boss, flavor)
                end
            end
            local trashDrops = instanceLoot.trash_drops
            if ns.Constants.SupportsRecordFlavor(trashDrops, flavor) then
                relationCount = relationCount + CountVisibleItems(trashDrops, flavor)
            end
        end
    end
    local flavorLabel = ns.L[FLAVOR_LABELS[flavor] or ""] or flavor
    return string.format(ns.L.STATUS_READY, dungeonCount, raidCount,
        encounterCount, relationCount) .. " " .. string.format(ns.L.STATUS_FLAVOR,
        flavorLabel, expansionCounts.classic, expansionCounts.tbc, expansionCounts.wotlk)
end

function SlashCommands:Handle(input)
    local command = string.lower((input or ""):match("^%s*(.-)%s*$"))

    if command == "" or command == "browse" then
        ns.modules.MainWindow:Toggle()
        return
    end

    if command == "options" or command == "settings" or command == "config" then
        ns.modules.MainWindow:ShowOptions()
        return
    end

    if command == "status" then
        Print(GetCatalogStatus())
        return
    end

    if command == "reset" then
        ns.modules.MainWindow:ResetPosition()
        Print("Window position reset.")
        return
    end

    Print(ns.L.USAGE)
end

function SlashCommands:Initialize()
    SLASH_ATLASLOOTREVIVAL1 = "/atlaslootrevival"
    SLASH_ATLASLOOTREVIVAL2 = "/alr"
    SlashCmdList.ATLASLOOTREVIVAL = function(input)
        self:Handle(input)
    end
end
