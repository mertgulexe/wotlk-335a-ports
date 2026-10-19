--[[
  AtlasQuest_AutoFinish.lua - 3.3.5a addition (not part of AtlasQuest 4.4.3)

  Ticks AtlasQuest's "finished" box for the quests the server reports as completed:
  at login, and shortly after each quest turn-in. The 3.3.5a client has no QUEST_TURNED_IN
  event, so a post-hook on GetQuestReward (and the "<quest> completed." system message)
  asks the server for the completed list again; any QUEST_QUERY_COMPLETE is used, also
  ones other addons asked for.

  Each completed quest is ticked once: the quest IDs already handled are remembered per
  character (AtlasQuest_Options[name].AQAutoFinished), so a box unticked by hand stays unticked.
]]

local QUERY_DELAY = 1    -- seconds after a turn-in before asking the server
local MAX_INSTANCES = 94 -- AQMAXINSTANCES in AtlasQuest.lua
local MAX_QUESTS = 20    -- AQMAXQUESTS in AtlasQuest.lua

local questKeys -- [questID] = { "AQFinishedQuest_Inst<i>Quest<b>[_HORDE]", ... }
local gotReply = false

-- quest ID -> AtlasQuest's finished keys, from AtlasQuest_QuestIDs.lua (Inst<i>Quest<b>[_HORDE]_QuestID)
local function QuestKeys()
    if questKeys then return questKeys end
    questKeys = {}
    for i = 1, MAX_INSTANCES do
        for b = 1, MAX_QUESTS do
            for _, side in ipairs({ "", "_HORDE" }) do
                local id = tonumber(_G["Inst" .. i .. "Quest" .. b .. side .. "_QuestID"])
                if id then
                    questKeys[id] = questKeys[id] or {}
                    table.insert(questKeys[id], "AQFinishedQuest_Inst" .. i .. "Quest" .. b .. side)
                end
            end
        end
    end
    return questKeys
end

local function Sync()
    local options = AtlasQuest_Options and AtlasQuest_Options[UnitName("player")]
    if type(options) ~= "table" or type(AQ) ~= "table" then return end -- AtlasQuest not initialized yet
    local completed = GetQuestsCompleted()
    if type(completed) ~= "table" then return end

    options.AQAutoFinished = options.AQAutoFinished or {}
    local handled = options.AQAutoFinished
    local changed = false
    for id, keys in pairs(QuestKeys()) do
        if completed[id] and not handled[id] then
            handled[id] = true
            for _, key in ipairs(keys) do
                if AQ[key] ~= 1 then
                    AQ[key] = 1
                    options[key] = 1
                    changed = true
                end
            end
        end
    end

    if changed then
        AQUpdateNOW = true -- AtlasQuest redraws its quest list on its next update
        if AQFinishedQuest and AQFinishedQuest:IsVisible() and AQQuestFinishedSetChecked then
            AQQuestFinishedSetChecked()
        end
    end
end

local frame = CreateFrame("Frame")
local waiting -- seconds left before the next query, or nil

local function ScheduleQuery()
    waiting = QUERY_DELAY
    frame:Show()
end

frame:SetScript("OnUpdate", function(self, elapsed)
    if not waiting then
        self:Hide()
        return
    end
    waiting = waiting - elapsed
    if waiting <= 0 then
        waiting = nil
        self:Hide()
        QueryQuestsCompleted()
    end
end)
frame:Hide()

local QUEST_COMPLETED_MSG = "^" .. string.gsub(ERR_QUEST_COMPLETE_S, "%%s", ".+") .. "$"

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("QUEST_QUERY_COMPLETE")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:SetScript("OnEvent", function(self, event, message)
    if event == "QUEST_QUERY_COMPLETE" then
        gotReply = true
        Sync()
    elseif event == "PLAYER_LOGIN" then
        QueryQuestsCompleted()
    elseif event == "CHAT_MSG_SYSTEM" then
        if type(message) == "string" and message:find(QUEST_COMPLETED_MSG) then
            ScheduleQuery()
        end
    end
end)

-- a turn-in (post-hook: the server records the quest after the reward is taken)
hooksecurefunc("GetQuestReward", ScheduleQuery)

-- AtlasQuest loads its saved ticks when the player enters the world; if the server's
-- answer came first, apply it now
hooksecurefunc("AtlasQuest_Initialize", function()
    if gotReply then Sync() end
end)
