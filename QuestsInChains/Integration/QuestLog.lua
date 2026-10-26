-- Integration/QuestLog.lua: a "Chain" button on Blizzard's quest log.
-- Post-hooks only; FrameXML is not changed.
local _, ns = ...

local QL = {}
ns.QuestLogButton = QL

local buttons = {}

local function SelectedQuest()
    local index = GetQuestLogSelection()
    if not index or index <= 0 then return nil end
    return ns.QuestIDOfLogIndex(index)
end

local function Update()
    local id = SelectedQuest()
    local ok = id and ns.quests[id] and true or false
    for _, b in ipairs(buttons) do
        if ok and b:GetParent():IsShown() then
            b.questID = id
            b:Show()
        else
            b.questID = nil
            b:Hide()
        end
    end
end
QL.Update = Update

local function MakeButton(parent, point, relPoint, x, y)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(56)
    b:SetHeight(22)
    b:SetPoint(point, parent, relPoint, x, y)
    b:SetText("Chain")
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", function(self)
        -- the player's own quest: shown for the player's faction
        if self.questID then ns.OpenQuest(self.questID, { faction = ns.playerFaction }) end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.TITLE)
        GameTooltip:AddLine("Show the whole quest chain of the selected quest.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide()
    buttons[#buttons + 1] = b
    return b
end

function QL.Setup()
    if QL.done then return end
    QL.done = true
    -- the quest log: bottom bar, between the abandon/share/track panel (left) and Close (right)
    if QuestLogFrame and QuestLogFrameCancelButton then
        QL.logButton = MakeButton(QuestLogFrame, "BOTTOMRIGHT", "BOTTOMRIGHT", -91, 14)
    end
    -- the detached details window (shown without the quest log): below its title, left of the map button
    if QuestLogDetailFrame then
        QL.detailButton = MakeButton(QuestLogDetailFrame, "TOPLEFT", "TOPLEFT", 78, -44)
    end
    -- QuestLog_OnShow calls QuestLog_SetSelection, and QuestLog_SetSelection is what shows the
    -- detached details window: this one post-hook sees both windows open
    hooksecurefunc("QuestLog_SetSelection", Update)
    local f = CreateFrame("Frame")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    f:SetScript("OnEvent", Update)
end

QL.Setup()
