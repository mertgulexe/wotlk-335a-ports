-- Core.lua: namespace, saved variables, events, quest status, slash commands, key binding.
local addonName, ns = ...

ns.addonName = addonName
ns.TITLE = "Quests in Chains"
ns.DB_VERSION = 1

local band = bit.band
local floor = math.floor
local pairs, ipairs, type, tonumber, tostring = pairs, ipairs, type, tonumber, tostring

-- ---------------------------------------------------------------- constants
-- Questie's classKeys (Database/QuestieDB.lua), keyed by UnitClass's file name
ns.CLASS_BITS = {
    WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, DEATHKNIGHT = 32,
    SHAMAN = 64, MAGE = 128, WARLOCK = 256, DRUID = 1024,
}
ns.CLASS_LIST = {
    { 1, "Warrior" }, { 2, "Paladin" }, { 4, "Hunter" }, { 8, "Rogue" }, { 16, "Priest" },
    { 32, "Death Knight" }, { 64, "Shaman" }, { 128, "Mage" }, { 256, "Warlock" }, { 1024, "Druid" },
}
-- Questie's raceKeys, keyed by UnitRace's file name
ns.RACE_BITS = {
    Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Scourge = 16, Tauren = 32, Gnome = 64, Troll = 128,
    BloodElf = 512, Draenei = 1024,
}
ns.RACE_LIST = {
    { 1, "Human" }, { 2, "Orc" }, { 4, "Dwarf" }, { 8, "Night Elf" }, { 16, "Undead" },
    { 32, "Tauren" }, { 64, "Gnome" }, { 128, "Troll" }, { 512, "Blood Elf" }, { 1024, "Draenei" },
}
ns.EXPANSIONS = { "Classic", "The Burning Crusade", "Wrath of the Lich King" }
ns.KIND_ICONS = {
    dungeon = "Interface\\LFGFrame\\LFGIcon-Dungeon",
    raid = "Interface\\LFGFrame\\LFGIcon-Raid",
    battleground = "Interface\\LFGFrame\\LFGIcon-Battleground",
}
ns.ZONE_KIND_ICONS = { d = ns.KIND_ICONS.dungeon, r = ns.KIND_ICONS.raid, b = ns.KIND_ICONS.battleground }
ns.STATUS_TEXT = {
    completed = "Completed", active = "In quest log", available = "Available", locked = "Locked",
    unavailable = "Unavailable", otherclass = "Other class", otherrace = "Other race",
}
ns.STATUS_COLOR = {
    completed = { 0.25, 0.75, 0.25 }, active = { 1, 0.82, 0 }, available = { 1, 1, 1 },
    locked = { 0.6, 0.6, 0.6 }, unavailable = { 0.85, 0.3, 0.3 }, otherclass = { 0.85, 0.3, 0.3 },
    otherrace = { 0.85, 0.3, 0.3 },
}
ns.FACTION_NAMES = { A = "Alliance", H = "Horde" }

-- ---------------------------------------------------------------- helpers
local CHAT_PREFIX = "|cffffd100Quests in Chains:|r "
function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. tostring(msg))
end

function ns.ColorCode(r, g, b)
    local function c(v)
        v = floor((v or 1) * 255 + 0.5)
        if v < 0 then v = 0 elseif v > 255 then v = 255 end
        return v
    end
    return string.format("|cff%02x%02x%02x", c(r), c(g), c(b))
end

-- difficulty colour of a quest level (scaling quests, without a level, count as the player's level)
function ns.DifficultyColor(lv)
    lv = tonumber(lv) or UnitLevel("player") or 1
    local c = GetQuestDifficultyColor(lv)
    if type(c) ~= "table" then return 1, 0.82, 0 end
    return c.r, c.g, c.b
end

function ns.QuestLink(id)
    local q = ns.quests[id]
    local name = q and q.n or ("Quest " .. tostring(id))
    local level = (q and (q.lv or q.rl)) or 0
    return string.format("|cffffff00|Hquest:%d:%d|h[%s]|h|r", id, level, name)
end

-- shift-click: put a quest link into the open chat edit box; true when it was inserted
function ns.InsertQuestLink(id)
    if not ChatEdit_GetActiveWindow() then return false end
    return ChatEdit_InsertLink(ns.QuestLink(id)) and true or false
end

function ns.FactionOf(unitFaction)
    return unitFaction == "Horde" and "H" or "A"
end

-- classes and races of a quest, as text (nil when unrestricted)
function ns.ClassText(mask)
    if not mask then return nil end
    local t = {}
    for _, c in ipairs(ns.CLASS_LIST) do
        if band(mask, c[1]) ~= 0 then t[#t + 1] = c[2] end
    end
    return #t > 0 and table.concat(t, ", ") or nil
end
function ns.RaceText(mask)
    if not mask then return nil end
    local t = {}
    for _, r in ipairs(ns.RACE_LIST) do
        if band(mask, r[1]) ~= 0 then t[#t + 1] = r[2] end
    end
    return #t > 0 and table.concat(t, ", ") or nil
end

-- AtlasQuest slots of each quest: ns.SlotsOf(id) -> { { inst = index, side = "A"/"H", slot = b }, ... }
local slotIndex
function ns.SlotsOf(id)
    if not slotIndex then
        slotIndex = {}
        for i, inst in ipairs(ns.instances) do
            for _, side in ipairs({ "A", "H" }) do
                for _, s in ipairs(inst[side == "A" and "a" or "h"] or {}) do
                    local qid = s[2]
                    if qid then
                        local l = slotIndex[qid]
                        if not l then l = {} slotIndex[qid] = l end
                        l[#l + 1] = { inst = i, side = side, slot = s[1] }
                    end
                end
            end
        end
    end
    return slotIndex[id]
end

-- the first instance (display order) whose list for this side holds the quest
function ns.FirstInstanceOf(id, side)
    for _, s in ipairs(ns.SlotsOf(id) or {}) do
        if s.side == side then return s.inst, s.slot end
    end
    return nil
end

function ns.InstanceByAQ(aq)
    for i, inst in ipairs(ns.instances) do
        if inst.aq == aq then return i end
    end
    return nil
end

-- AtlasQuest's localized text Inst<N>Quest<b>[_HORDE]<suffix>, or nil
function ns.AQText(aq, slot, side, suffix)
    local v = rawget(_G, "Inst" .. aq .. "Quest" .. slot .. (side == "H" and "_HORDE" or "") .. (suffix or ""))
    if type(v) == "string" then return v end
    return nil
end
function ns.AtlasQuestLoaded()
    return type(rawget(_G, "AQButton_SetText")) == "function"
end

-- ---------------------------------------------------------------- timers (a private OnUpdate frame)
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
local timers = {}
function ns.After(delay, fn, key)
    if key then
        for i = #timers, 1, -1 do
            if timers[i].key == key then table.remove(timers, i) end
        end
    end
    timers[#timers + 1] = { at = GetTime() + delay, fn = fn, key = key }
    timerFrame:Show()
end
function ns.Cancel(key)
    for i = #timers, 1, -1 do
        if timers[i].key == key then table.remove(timers, i) end
    end
    if #timers == 0 then timerFrame:Hide() end
end
function ns.Pending(key)
    for _, t in ipairs(timers) do
        if t.key == key then return true end
    end
    return false
end
timerFrame:SetScript("OnUpdate", function(self)
    local now = GetTime()
    local due
    for i = #timers, 1, -1 do
        if timers[i].at <= now then
            due = due or {}
            table.insert(due, 1, timers[i])
            table.remove(timers, i)
        end
    end
    if #timers == 0 then self:Hide() end
    if due then
        for _, t in ipairs(due) do t.fn() end
    end
end)

-- ---------------------------------------------------------------- saved variables
local DEFAULT_ANGLE = 200
local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
local function finite(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- every field is checked; anything of a wrong type or out of range gets its default
function ns.ValidateDB(db)
    if type(db) ~= "table" then db = {} end
    local out = { version = ns.DB_VERSION }
    local p = db.pos
    if type(p) == "table" and VALID_POINTS[p.point] and VALID_POINTS[p.relPoint] and finite(p.x) and finite(p.y)
        and p.x > -10000 and p.x < 10000 and p.y > -10000 and p.y < 10000 then
        out.pos = { point = p.point, relPoint = p.relPoint, x = p.x, y = p.y }
    end
    local mm = type(db.minimap) == "table" and db.minimap or {}
    out.minimap = { angle = DEFAULT_ANGLE, hide = false }
    if finite(mm.angle) then out.minimap.angle = mm.angle % 360 end
    if type(mm.hide) == "boolean" then out.minimap.hide = mm.hide end
    if type(db.myClassOnly) == "boolean" then out.myClassOnly = db.myClassOnly else out.myClassOnly = true end
    if type(db.hideCompleted) == "boolean" then out.hideCompleted = db.hideCompleted else out.hideCompleted = false end
    if type(db.lastInstance) == "number" and ns.InstanceByAQ(db.lastInstance) then out.lastInstance = db.lastInstance end
    return out
end

-- ---------------------------------------------------------------- state
ns.completed = {}       -- [questID] = true, from the server
ns.haveCompleted = false
ns.active = {}          -- [questID] = true, from the quest log
ns.statusVersion = 0
ns.state = {
    faction = "A",      -- the faction shown (the player's at login; not saved)
    instance = nil,     -- index into ns.instances
    search = "",
    row = nil,          -- selected list row { inst=, side=, slot=, id=, title= }
    root = nil,         -- quest the graph is built for
    selected = nil,     -- selected card
}
ns.db = ns.ValidateDB(nil)

local listeners = {}
function ns.On(event, fn)
    listeners[event] = listeners[event] or {}
    table.insert(listeners[event], fn)
end
function ns.Fire(event, ...)
    for _, fn in ipairs(listeners[event] or {}) do fn(...) end
end

-- UnitLevel can still report the old level while PLAYER_LEVEL_UP is handled; the event's level
-- counts until UnitLevel catches up (levels only go up)
local levelUp
function ns.PlayerLevel()
    local l = UnitLevel("player") or 1
    if levelUp and levelUp > l then return levelUp end
    return l
end

-- ---------------------------------------------------------------- quest status
local function FactionVisible(id, faction)
    local q = ns.quests[id]
    return q ~= nil and (q.fa == nil or q.fa == faction)
end
ns.FactionVisible = FactionVisible

local function AnyIn(list, a, b)
    if list then
        for _, x in ipairs(list) do
            if a[x] or (b and b[x]) then return true end
        end
    end
    return false
end

-- completed, active, otherclass, otherrace, unavailable, available or locked (checked in this order).
-- The rules follow Questie's IsDoable (Database/QuestieDB.lua):
-- - unavailable: an exclusive quest (ex, xo), the next quest in the chain (nx) or the target of a
--   breadcrumb (bf) is completed or in the quest log;
-- - with a preQuestSingle list (one), one of its quests must be completed and pre is not checked;
-- - otherwise every pre quest must be completed, or (unless the entry was negative, ps) one of the
--   quests it excludes;
-- - lead and bc parents never block, and only faction-visible parents count, so a faction that
--   cannot do a parent is not locked by it.
-- The race is only checked for the player's own faction (rc lists races of one faction).
function ns.Status(id, faction)
    local completed, active = ns.completed, ns.active
    if completed[id] then return "completed" end
    if active[id] then return "active" end
    local q = ns.quests[id]
    if not q then return "locked" end
    faction = faction or ns.state.faction
    local cb, rb = ns.playerClassBit, ns.playerRaceBit
    if q.cl and cb and band(q.cl, cb) == 0 then return "otherclass" end
    if q.rc and rb and faction == ns.playerFaction and band(q.rc, rb) == 0 then return "otherrace" end
    if AnyIn(q.ex, completed, active) or AnyIn(q.xo, completed, active)
        or AnyIn(q.nx, completed, active) or AnyIn(q.bf, completed, active) then
        return "unavailable"
    end
    if q.one then
        local any = false
        for _, p in ipairs(q.one) do
            if FactionVisible(p, faction) then
                if completed[p] then return "available" end
                any = true
            end
        end
        return any and "locked" or "available"
    end
    if q.pre then
        local strict
        if q.ps then
            strict = {}
            for _, p in ipairs(q.ps) do strict[p] = true end
        end
        local Q = ns.quests
        for _, p in ipairs(q.pre) do
            if FactionVisible(p, faction) and not completed[p] then
                local pq = Q[p]
                if (strict and strict[p]) or not (AnyIn(pq.ex, completed) or AnyIn(pq.xo, completed)) then
                    return "locked"
                end
            end
        end
    end
    return "available"
end

function ns.ClassBitFilter()
    if ns.db.myClassOnly then return ns.playerClassBit end
    return nil
end
-- the race filter only applies to the player's own faction
function ns.RaceBitFilter(faction)
    if ns.db.myClassOnly and (faction or ns.state.faction) == ns.playerFaction then return ns.playerRaceBit end
    return nil
end
function ns.ChainOpts(faction)
    faction = faction or ns.state.faction
    return {
        faction = faction,
        classBit = ns.ClassBitFilter(),
        raceBit = ns.RaceBitFilter(faction),
        status = function(id) return ns.Status(id, faction) end,
    }
end

local function StatusChanged()
    ns.statusVersion = ns.statusVersion + 1
    ns.Fire("STATUS")
end
ns.StatusChanged = StatusChanged

-- quest log -> ns.active. GetQuestLogTitle lists no quests under a collapsed header, so the quests
-- last seen under each expanded header are remembered and stay active while that header is
-- collapsed. A quest turned in from a collapsed header leaves the memory once the server's
-- completed list has it (until then it shows as completed anyway: completed is checked first).
local headerQuests = {} -- [header title] = { [questID] = true }
local function QuestIDOf(index)
    local title, _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
    if not title or isHeader then return nil end
    questID = tonumber(questID)
    if not questID then
        local link = GetQuestLink(index)
        questID = link and tonumber(link:match("|Hquest:(%d+):"))
    end
    return questID
end
ns.QuestIDOfLogIndex = QuestIDOf

function ns.ScanQuestLog()
    local numEntries = tonumber((GetNumQuestLogEntries())) or 0
    local found = {}
    local headers, listed = {}, {} -- [title] = isCollapsed; [title] = quests listed under it now
    local header
    for i = 1, numEntries do
        local title, _, _, _, isHeader, isCollapsed = GetQuestLogTitle(i)
        if title then
            if isHeader then
                header = title
                headers[title] = isCollapsed and true or false
                if not isCollapsed then listed[title] = listed[title] or {} end
            else
                local id = QuestIDOf(i)
                if id then
                    found[id] = true
                    if header and listed[header] then listed[header][id] = true end
                end
            end
        end
    end
    for title, set in pairs(listed) do headerQuests[title] = set end
    for title in pairs(headerQuests) do
        if headers[title] == nil then headerQuests[title] = nil end -- the header is gone
    end
    for title, collapsed in pairs(headers) do
        local set = collapsed and headerQuests[title]
        if set then
            for id in pairs(set) do
                if ns.completed[id] then set[id] = nil else found[id] = true end
            end
        end
    end
    local changed = false
    for id in pairs(found) do
        if not ns.active[id] then changed = true break end
    end
    if not changed then
        for id in pairs(ns.active) do
            if not found[id] then changed = true break end
        end
    end
    if changed then
        ns.active = found
        StatusChanged()
    end
    return changed
end

-- the server's completed list
local QUERY_GUARD = 10 -- seconds: one query of ours at a time while no answer came
local lastQuery
local function Query()
    local now = GetTime()
    if lastQuery and now - lastQuery < QUERY_GUARD then return end
    lastQuery = now
    QueryQuestsCompleted()
end
-- (a) the window opens and no list has arrived yet this session
function ns.QueryIfNeeded()
    if not ns.haveCompleted then Query() end
end
-- (b) 2 seconds after a turn-in, unless a list arrived in between
local REWARD_DELAY = 2
hooksecurefunc("GetQuestReward", function()
    ns.After(REWARD_DELAY, function()
        lastQuery = nil
        Query()
    end, "rewardQuery")
end)

local function OnQuestQueryComplete()
    ns.Cancel("rewardQuery")
    lastQuery = nil
    local t = GetQuestsCompleted()
    if type(t) ~= "table" then return end
    local changed = not ns.haveCompleted
    if not changed then
        for id in pairs(t) do
            if not ns.completed[id] then changed = true break end
        end
    end
    if not changed then
        for id in pairs(ns.completed) do
            if not t[id] then changed = true break end
        end
    end
    local copy = {}
    for id, v in pairs(t) do
        if v then copy[id] = true end
    end
    ns.completed = copy
    ns.haveCompleted = true
    if changed then StatusChanged() end
end

-- ---------------------------------------------------------------- events
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("QUEST_QUERY_COMPLETE")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("UNIT_LEVEL")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            QuestsInChainsDB = ns.ValidateDB(QuestsInChainsDB)
            ns.db = QuestsInChainsDB
            ns.Fire("DB")
        end
    elseif event == "PLAYER_LOGIN" then
        ns.playerFaction = ns.FactionOf(UnitFactionGroup("player"))
        ns.state.faction = ns.playerFaction
        local _, classFile = UnitClass("player")
        ns.playerClass = classFile
        ns.playerClassBit = ns.CLASS_BITS[classFile]
        local _, raceFile = UnitRace("player")
        ns.playerRace = raceFile
        ns.playerRaceBit = ns.RACE_BITS[raceFile]
        ns.loggedIn = true
        ns.ScanQuestLog()
        ns.Fire("LOGIN")
    elseif event == "QUEST_QUERY_COMPLETE" then
        OnQuestQueryComplete()
    elseif event == "QUEST_LOG_UPDATE" then
        -- the event comes in bursts: scan once, on the next frame
        if ns.loggedIn and not ns.Pending("scanLog") then ns.After(0, ns.ScanQuestLog, "scanLog") end
    elseif event == "PLAYER_LEVEL_UP" or (event == "UNIT_LEVEL" and arg1 == "player") then
        if event == "PLAYER_LEVEL_UP" then levelUp = tonumber(arg1) end
        ns.After(0, function() ns.Fire("LEVEL") end, "levelUp")
    end
end)

-- ---------------------------------------------------------------- slash command and key binding
local HELP = {
    "/qic - show or hide the window",
    "/qic <quest ID> - show that quest's chain",
    "/qic minimap - show or hide the minimap button",
    "/qic reset - reset the window position and the filters",
    "/qic help - this list",
}

function ns.Toggle()
    if ns.UI and ns.UI.Toggle then ns.UI.Toggle() end
end

function ns.OpenQuest(id, ctx)
    if not ns.quests[id] then
        ns.Print("Quest " .. tostring(id) .. " is not in the chain data.")
        return false
    end
    if ns.UI and ns.UI.OpenQuest then ns.UI.OpenQuest(id, ctx) end
    return true
end

local function Slash(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local cmd = msg:lower()
    if cmd == "" then
        ns.Toggle()
    elseif cmd == "help" or cmd == "?" then
        ns.Print("commands:")
        for _, l in ipairs(HELP) do DEFAULT_CHAT_FRAME:AddMessage("  " .. l) end
    elseif cmd == "minimap" then
        ns.db.minimap.hide = not ns.db.minimap.hide
        ns.Fire("MINIMAP")
        ns.Print(ns.db.minimap.hide and "minimap button hidden (/qic minimap shows it again)." or "minimap button shown.")
    elseif cmd == "reset" then
        ns.db.pos = nil
        ns.db.myClassOnly = true
        ns.db.hideCompleted = false
        ns.Fire("RESET")
        ns.Print("window position and filters reset.")
    else
        local id = tonumber(cmd) or tonumber(msg:match("|Hquest:(%d+)"))
        if id then
            ns.OpenQuest(id)
        else
            ns.Print("unknown command '" .. msg .. "'. /qic help lists the commands.")
        end
    end
end
ns.Slash = Slash

SLASH_QUESTSINCHAINS1 = "/qic"
SLASH_QUESTSINCHAINS2 = "/questchains"
SlashCmdList.QUESTSINCHAINS = Slash

BINDING_HEADER_QUESTSINCHAINS = "Quests in Chains"
BINDING_NAME_QUESTSINCHAINS_TOGGLE = "Toggle Quests in Chains"
function QuestsInChains_Toggle()
    ns.Toggle()
end
