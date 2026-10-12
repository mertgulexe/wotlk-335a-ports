local addonName, ns = ...

local Events = ns:RegisterModule("Events", {})
Events.frame = CreateFrame("Frame")

function Events:OnAddonLoaded(loadedAddon)
    if loadedAddon ~= addonName then
        return
    end

    ns.modules.Database:Initialize()
    ns.modules.MinimapButton:Initialize()
    ns.modules.SlashCommands:Initialize()
    -- 3.3.5a has no GET_ITEM_INFO_RECEIVED / ITEM_DATA_LOAD_RESULT; Compat polls instead.
    ns.Compat.RegisterItemInfoCallback(function(resolvedItems)
        ns.modules.MainWindow:OnItemDataLoaded(resolvedItems)
    end)
    self.frame:UnregisterEvent("ADDON_LOADED")
end

Events.frame:RegisterEvent("ADDON_LOADED")
Events.frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        Events:OnAddonLoaded(...)
    end
end)
