local _, Cell = ...
local L = Cell.L
local F = Cell.funcs

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local minimapButton = LDB:NewDataObject("Cell", {
    type = "launcher",
    text = "Cell",
    icon = "Interface\\AddOns\\Cell\\Media\\icon.tga",
    OnClick = function(_, button)
        local mainFrame = Cell.frames.mainFrame
        if button == "RightButton" then
            -- the options window is a child of the main frame, bring the frames back to show it
            if not mainFrame:IsShown() then
                if InCombatLockdown() then
                    F.Print(L["Cannot show Cell frames in combat."])
                    return
                end
                mainFrame:Show()
            end
            F.ShowOptionsFrame()
        elseif button == "LeftButton" then
            -- CellMainFrame is a secure frame, it can't be shown/hidden in combat
            if InCombatLockdown() then
                F.Print(L["Cannot toggle Cell frames in combat."])
                return
            end
            if mainFrame:IsShown() then
                mainFrame:Hide()
            else
                mainFrame:Show()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:ClearLines()
        tooltip:AddDoubleLine("Cell", Cell.version or "", 1, 0.82, 0, 1, 0.82, 0)
        tooltip:AddLine(" ")
        tooltip:AddLine(L["|cffeda55fLeft-Click|r to toggle showing the party/raid frames."], 0.2, 1, 0.2)
        tooltip:AddLine(L["|cffeda55fRight-Click|r to toggle showing the options window."], 0.2, 1, 0.2)
    end,
})

function F.UpdateMinimapButton()
    if CellDB["minimap"]["hide"] then
        LDBIcon:Hide("Cell")
    else
        LDBIcon:Show("Cell")
    end
end

Cell.RegisterCallback("AddonLoaded", "MinimapButton_AddonLoaded", function()
    LDBIcon:Register("Cell", minimapButton, CellDB["minimap"])
end)
