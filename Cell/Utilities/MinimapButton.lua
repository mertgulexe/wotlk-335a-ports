local _, Cell = ...
local L = Cell.L
local F = Cell.funcs

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local framesHidden = false

local minimapButton = LDB:NewDataObject("Cell", {
    type = "launcher",
    text = "Cell",
    icon = "Interface\\AddOns\\Cell\\Media\\icon.tga",
    OnClick = function(_, button)
        if button == "RightButton" then
            -- the options window isn't a child of the main frame (OptionsFrame.lua), so the frames stay hidden
            F.ShowOptionsFrame()
        elseif button == "LeftButton" then
            -- CellMainFrame has a "visibility" state driver (MainFrame.lua) that re-shows it,
            -- so swap the driver instead of calling Show/Hide. Secure frame: not in combat.
            if InCombatLockdown() then
                F.Print(L["Cannot toggle Cell frames in combat."])
                return
            end
            framesHidden = not framesHidden
            RegisterStateDriver(Cell.frames.mainFrame, "visibility", framesHidden and "hide" or "show")
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
