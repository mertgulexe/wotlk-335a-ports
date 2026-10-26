-- Integration/AtlasQuest.lua: a "Chain" button on AtlasQuest's quest page.
-- Post-hooks only; AtlasQuest itself is not changed.
local _, ns = ...

local AQ = {}
ns.AtlasQuestButton = AQ

local button
local hooked = false

local function Hide()
    if button then
        button:Hide()
        button.ctx = nil
    end
end

-- after AQButton_SetText: AQINSTANZ, AQSHOWNQUEST and Allianceorhorde name the quest shown
local function OnSetText()
    if not button then return end
    local inst, slot = tonumber(rawget(_G, "AQINSTANZ")), tonumber(rawget(_G, "AQSHOWNQUEST"))
    local side = (rawget(_G, "Allianceorhorde") == 2) and "H" or "A"
    local id
    if inst and slot then
        id = tonumber(rawget(_G, "Inst" .. inst .. "Quest" .. slot .. (side == "H" and "_HORDE" or "") .. "_QuestID"))
    end
    if id and ns.quests[id] then
        button.ctx = { id = id, aq = inst, slot = slot, faction = side }
        button:Show()
    else
        Hide()
    end
end

-- AtlasQuest's next-page button clears the page (AQClearALL); a quest's own extra pages still
-- show that quest, so the button comes back there
local function OnNextPage()
    if rawget(_G, "AQ_NextPageCount") == "Quest" then OnSetText() end
end

function AQ.Setup()
    if hooked then return true end
    if type(rawget(_G, "AQButton_SetText")) ~= "function" then return false end
    local parent = rawget(_G, "AtlasQuestInsideFrame")
    if type(parent) ~= "table" or not parent.GetObjectType then return false end
    hooked = true
    button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    AQ.button = button
    button:SetWidth(50)
    button:SetHeight(20)
    -- top left corner of the quest page (510 x 510): left of the quest name's box (400 wide,
    -- centred, so it starts 55 px in), above the level texts (-50), far from the close button
    -- (top right), the "finished" check box, the page buttons and the reward items
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    button:SetText("Chain")
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnShow", function(self)
        -- AtlasQuest raises its own controls on show (parent level + 1 / + 2)
        self:SetFrameLevel(self:GetParent():GetFrameLevel() + 3)
    end)
    button:SetScript("OnClick", function(self)
        local ctx = self.ctx
        if ctx then ns.OpenQuest(ctx.id, ctx) end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.TITLE)
        GameTooltip:AddLine("Show the whole quest chain of this quest.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:Hide()
    hooksecurefunc("AQButton_SetText", OnSetText)
    if type(rawget(_G, "AQClearALL")) == "function" then hooksecurefunc("AQClearALL", Hide) end
    if type(rawget(_G, "AQButtonSTORY_SetText")) == "function" then hooksecurefunc("AQButtonSTORY_SetText", Hide) end
    if type(rawget(_G, "AQNextPageR_OnClick")) == "function" then hooksecurefunc("AQNextPageR_OnClick", OnNextPage) end
    return true
end

-- AtlasQuest loads before us when it is enabled (OptionalDeps); a late load is handled too
if not AQ.Setup() then
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name == "AtlasQuest" and AQ.Setup() then self:UnregisterEvent("ADDON_LOADED") end
    end)
end
