-- UI/ListPanel.lua: the left panel. Search box, instance, faction and sort dropdowns,
-- filters, progress bar and the quest list.
local _, ns = ...

local List = {}
ns.List = List

local ROW_H = 16
local MENU_ROW_H = 16
local MENU_ROWS = 18
local PANEL_W = 230
local LIST_TOP = 144
local SCROLLBAR_W = 24
local ROW_W = PANEL_W - SCROLLBAR_W
local LEVEL_W = 40 -- the level column in front of instance names

local DARK_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local panel
local rows = {}       -- row buttons
local data = {}       -- rows of the current list
local stepCache = {}  -- [filterKey][questID] = { step, steps }

local NODATA_COLOR = { 0.5, 0.5, 0.5 }
local SORT_NAMES = { aq = "AtlasQuest order", name = "Name", level = "Level" }
local SORT_SHORT = { aq = "AtlasQuest", name = "Name", level = "Level" } -- (the button is narrow)

-- ---------------------------------------------------------------- helpers
local function SideKey(side) return side == "H" and "h" or "a" end

local function Label(inst, side, slot, title)
    if ns.AtlasQuestLoaded() then
        local t = ns.AQText(inst.aq, slot, side)
        if t then return t end
    end
    return slot .. ". " .. title
end

-- the level range of an instance, coloured by the player's level against its top
local function LevelText(inst)
    if not inst.lr then return "" end
    local hi = tonumber(inst.lr:match("(%d+)%+?$")) or tonumber(inst.lr:match("^(%d+)"))
    local r, g, b = ns.DifficultyColor(hi)
    return ns.ColorCode(r, g, b) .. inst.lr .. "|r"
end
List.LevelText = LevelText

function List.ClearCache()
    stepCache = {}
end

-- step and number of steps of a quest under the current filters (cached)
function List.Steps(id)
    local key = ns.FilterKey()
    local c = stepCache[key]
    if not c then c = {} stepCache[key] = c end
    local v = c[id]
    if v == nil then
        local step, steps = ns.Chain.Steps(id, ns.ChainOpts())
        v = step and { step, steps } or false
        c[id] = v
    end
    if not v then return nil end
    return v[1], v[2]
end

local function Matches(text, needle)
    return type(text) == "string" and string.find(string.lower(text), needle, 1, true) ~= nil
end

-- is a quest's row shown? ("Hide completed")
local function RowShown(id)
    if not id then return true end
    if ns.db.hideCompleted and ns.completed[id] then return false end
    return true
end

-- the lowest and highest level of an instance's range ("16-22", "80+", "70"); 999 without one
local function LevelBounds(inst)
    local lr = inst.lr or ""
    local lo, hi = lr:match("^(%d+)%-(%d+)$")
    if lo then return tonumber(lo), tonumber(hi) end
    local one = tonumber(lr:match("^(%d+)"))
    if one then return one, one end
    return 999, 999
end
List.LevelBounds = LevelBounds

-- the instances in the order of the sort mode: by expansion and kind (dungeons, raids,
-- battlegrounds), then by name, or by level ("level": the range's lowest level, then its highest)
local KIND_ORDER = { dungeon = 1, raid = 2, battleground = 3 }
function List.InstanceOrder()
    local order = {}
    for i in ipairs(ns.instances) do order[#order + 1] = i end
    if ns.db.sort == "level" then
        table.sort(order, function(a, b)
            local A, B = ns.instances[a], ns.instances[b]
            if A.exp ~= B.exp then return A.exp < B.exp end
            local ka, kb = KIND_ORDER[A.kind] or 9, KIND_ORDER[B.kind] or 9
            if ka ~= kb then return ka < kb end
            local la, ha = LevelBounds(A)
            local lb, hb = LevelBounds(B)
            if la ~= lb then return la < lb end
            if ha ~= hb then return ha < hb end
            return a < b -- (the data's order: by name)
        end)
    end
    return order
end

-- quest rows by name or level; instance rows (a search's instance matches) stay first, in the
-- order of List.InstanceOrder
local function SortRows(out)
    local mode = ns.db.sort
    local insts, quests = {}, {}
    for _, r in ipairs(out) do
        if r.instanceRow then insts[#insts + 1] = r else quests[#quests + 1] = r end
    end
    if #insts > 1 then
        local pos = {}
        for k, i in ipairs(List.InstanceOrder()) do pos[i] = k end
        table.sort(insts, function(a, b) return pos[a.inst] < pos[b.inst] end)
    end
    if mode == "name" or mode == "level" then
        for i, r in ipairs(quests) do r.order = i end
        local function lname(r) return string.lower(r.title or "") end
        table.sort(quests, function(a, b)
            if mode == "level" then
                local qa, qb = a.id and ns.quests[a.id], b.id and ns.quests[b.id]
                local la, lb = qa and (qa.lv or qa.rl) or 999, qb and (qb.lv or qb.rl) or 999
                if la ~= lb then return la < lb end
                local ra, rb = qa and qa.rl or 999, qb and qb.rl or 999
                if ra ~= rb then return ra < rb end
            end
            local na, nb = lname(a), lname(b)
            if na ~= nb then return na < nb end
            return a.order < b.order
        end)
    end
    for _, r in ipairs(quests) do insts[#insts + 1] = r end
    return insts
end

-- the rows of the current list: the selected instance, or the search matches of all the data. A
-- search shows the instances whose name matches (a click opens the instance), then every AtlasQuest
-- row of the shown side whose quest matches, then the other quests of the chains (of the shown side)
-- whose name matches.
local function BuildData()
    local out = {}
    local st = ns.state
    local side = st.faction
    local needle = (st.search or ""):match("^%s*(.-)%s*$"):lower()
    local function Add(i, inst, s, search)
        local id = s[2]
        if not RowShown(id) then return end
        local label = Label(inst, side, s[1], s[3])
        out[#out + 1] = {
            inst = i, side = side, slot = s[1], id = id or false, title = s[3], label = label,
            display = search and (label .. " |cff888888- " .. inst.name .. "|r") or label,
        }
    end
    if needle ~= "" then
        local listed = {}
        for i, inst in ipairs(ns.instances) do
            if Matches(inst.name, needle) then
                local n = 0
                for _, s in ipairs(inst[SideKey(side)] or {}) do n = n + 1 end
                out[#out + 1] = { instanceRow = true, inst = i, side = side, title = inst.name, label = inst.name, count = n }
            end
            for _, s in ipairs(inst[SideKey(side)] or {}) do
                if s[2] then listed[s[2]] = true end
                local label = Label(inst, side, s[1], s[3])
                local plain = label:gsub("^%d+%.%s*", "")
                local q = s[2] and ns.quests[s[2]]
                if Matches(s[3], needle) or Matches(plain, needle) or (q and Matches(q.n, needle)) then
                    Add(i, inst, s, true)
                end
            end
        end
        -- quests of the chains that AtlasQuest does not list on this side
        local extra = {}
        for id, q in pairs(ns.quests) do
            if not listed[id] and (q.fa == nil or q.fa == side) and Matches(q.n, needle) and RowShown(id) then
                extra[#extra + 1] = id
            end
        end
        table.sort(extra, function(a, b)
            local na, nb = ns.quests[a].n:lower(), ns.quests[b].n:lower()
            if na ~= nb then return na < nb end
            return a < b
        end)
        for _, id in ipairs(extra) do
            local q = ns.quests[id]
            out[#out + 1] = {
                side = side, id = id, title = q.n, label = q.n, chainOnly = true,
                display = q.n .. (q.zn and (" |cff888888- " .. q.zn .. "|r") or ""),
            }
        end
    elseif st.instance and ns.instances[st.instance] then
        local inst = ns.instances[st.instance]
        for _, s in ipairs(inst[SideKey(side)] or {}) do Add(st.instance, inst, s, false) end
    end
    return SortRows(out)
end

-- the same row: the same AtlasQuest slot, the same instance (a search's instance rows), or the same
-- quest for rows outside AtlasQuest's lists
local function SameRow(a, b)
    if not (a and b) then return false end
    if a.instanceRow or b.instanceRow then return a.instanceRow and b.instanceRow and a.inst == b.inst end
    if a.chainOnly or b.chainOnly then return a.chainOnly and b.chainOnly and a.id == b.id end
    return a.inst == b.inst and a.side == b.side and a.slot == b.slot
end
List.SameRow = SameRow

-- the row of quest `id` in the current list (the given slot first), or nil
function List.FindRow(id, slot)
    local list = BuildData()
    local first
    for _, r in ipairs(list) do
        if r.id == id then
            if slot == nil or r.slot == slot then return r end
            first = first or r
        end
    end
    return first
end

-- ---------------------------------------------------------------- popup menu (instances, faction, sort)
local menu, catcher, menuScroll
local menuRows = {}
local menuEntries, menuPick, menuSelected, menuBuild = {}, nil, nil, nil
local menuLevels = false -- the entries have a level column

-- offset of a FauxScrollFrame after FauxScrollFrame_Update, clamped to the current item count
-- (FauxScrollFrame_Update may reset the scroll bar, and SetMinMaxValues clamps it silently)
local function ClampedOffset(scroll, count, shown)
    local offset = FauxScrollFrame_GetOffset(scroll) or 0
    local maxOffset = math.max(0, count - shown)
    if offset > maxOffset then offset = maxOffset end
    if offset < 0 then offset = 0 end
    FauxScrollFrame_SetOffset(scroll, offset)
    return offset
end

local function MenuUpdate()
    FauxScrollFrame_Update(menuScroll, #menuEntries, MENU_ROWS, MENU_ROW_H)
    local offset = ClampedOffset(menuScroll, #menuEntries, MENU_ROWS)
    for i = 1, MENU_ROWS do
        local b = menuRows[i]
        local e = menuEntries[offset + i]
        if e and i <= #menuEntries then
            b.entry = e
            b.text:ClearAllPoints()
            b.text:SetPoint("RIGHT", b, "RIGHT", -2, 0)
            if e.header then
                b.text:SetText(e.text)
                b.text:SetTextColor(1, 0.82, 0)
                b.text:SetPoint("LEFT", b, "LEFT", 4, 0)
                b.icon:Hide()
                b.level:Hide()
                b:Disable()
                b.check:Hide()
            else
                local x = 12
                if menuLevels then
                    b.level:SetText(e.level or "")
                    b.level:Show()
                    x = x + LEVEL_W
                else
                    b.level:Hide()
                end
                if e.icon then
                    b.icon:ClearAllPoints()
                    b.icon:SetPoint("LEFT", b, "LEFT", x, 0)
                    b.icon:SetTexture(e.icon)
                    b.icon:Show()
                    x = x + 18
                else
                    b.icon:Hide()
                end
                b.text:SetPoint("LEFT", b, "LEFT", x, 0)
                b.text:SetText(e.text)
                b.text:SetTextColor(1, 1, 1)
                b:Enable()
                local checked
                if e.checked ~= nil then checked = e.checked else checked = (e.value == menuSelected) end
                if checked then b.check:Show() else b.check:Hide() end
            end
            b:Show()
        else
            b.entry = nil
            b:Hide()
        end
    end
end

local function CreateMenu()
    local parent = ns.UI.frame
    catcher = CreateFrame("Button", nil, parent)
    catcher:SetFrameStrata("DIALOG")
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    catcher:SetScript("OnClick", function() List.CloseMenu() end)
    catcher:Hide()

    menu = CreateFrame("Frame", "QuestsInChainsMenu", parent)
    menu:SetFrameStrata("DIALOG")
    menu:SetFrameLevel(catcher:GetFrameLevel() + 5)
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:SetBackdrop(DARK_BACKDROP)
    menu:SetBackdropColor(0.05, 0.05, 0.05, 0.96)
    menu:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    menu:Hide()
    menu:SetScript("OnHide", function() catcher:Hide() end)
    menu:SetScript("OnMouseWheel", function(self, delta)
        local bar = _G[menuScroll:GetName() .. "ScrollBar"]
        bar:SetValue(bar:GetValue() - delta * MENU_ROW_H * 3)
    end)
    -- ESC and the game menu close the menu through a post-hook on CloseMenus (see below): an
    -- entry in Blizzard's UIMenus table would taint every caller of CloseMenus

    menuScroll = CreateFrame("ScrollFrame", "QuestsInChainsMenuScroll", menu, "FauxScrollFrameTemplate")
    menuScroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4)
    menuScroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -26, 4)
    menuScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, MENU_ROW_H, MenuUpdate)
    end)
    for i = 1, MENU_ROWS do
        local b = CreateFrame("Button", nil, menu)
        b:SetHeight(MENU_ROW_H)
        b:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -4 - (i - 1) * MENU_ROW_H)
        b:SetPoint("RIGHT", menu, "RIGHT", -28, 0)
        b:SetFrameLevel(menu:GetFrameLevel() + 3)
        b:RegisterForClicks("LeftButtonUp")
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetWidth(14)
        b.icon:SetHeight(14)
        b.icon:SetPoint("LEFT", b, "LEFT", 12, 0)
        b.check = b:CreateTexture(nil, "OVERLAY")
        b.check:SetWidth(10)
        b.check:SetHeight(10)
        b.check:SetPoint("LEFT", b, "LEFT", 0, 0)
        b.check:SetTexture("Interface\\Buttons\\WHITE8X8")
        b.check:SetVertexColor(1, 0.82, 0, 1)
        b.level = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.level:SetPoint("LEFT", b, "LEFT", 12, 0)
        b.level:SetWidth(LEVEL_W - 4)
        b.level:SetHeight(MENU_ROW_H)
        b.level:SetJustifyH("LEFT")
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", b, "LEFT", 30, 0)
        b.text:SetPoint("RIGHT", b, "RIGHT", -2, 0)
        b.text:SetHeight(MENU_ROW_H)
        b.text:SetJustifyH("LEFT")
        b:SetScript("OnClick", function(self)
            local e = self.entry
            if not e or e.header then return end
            local pick = menuPick
            if menuBuild then
                -- a menu of check boxes: it stays open and shows the new state
                if pick then pick(e.value) end
                if menu:IsShown() and menuBuild then
                    menuEntries = menuBuild()
                    MenuUpdate()
                end
                return
            end
            List.CloseMenu()
            if pick then pick(e.value) end
        end)
        b:SetScript("OnEnter", function(self)
            local e = self.entry
            if not (e and e.tooltip) then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            for i, line in ipairs(e.tooltip) do
                if i == 1 then GameTooltip:AddLine(line) else GameTooltip:AddLine(line, 0.8, 0.8, 0.8, true) end
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        menuRows[i] = b
    end
end

-- entries: a list, or (for a menu of check boxes that stays open) a function that builds it
function List.OpenMenu(anchor, entries, pick, selected)
    if not menu then CreateMenu() end
    if type(entries) == "function" then
        menuBuild = entries
        entries = entries()
    else
        menuBuild = nil
    end
    menuEntries, menuPick, menuSelected = entries, pick, selected
    menuLevels = false
    for _, e in ipairs(entries) do if e.level then menuLevels = true end end
    local n = math.min(#entries, MENU_ROWS)
    menu:SetWidth(anchor:GetWidth())
    menu:SetHeight(n * MENU_ROW_H + 8)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    catcher:Show()
    menu:Show()
    -- the selected entry in view
    local bar = _G[menuScroll:GetName() .. "ScrollBar"]
    local target = 0
    for i, e in ipairs(entries) do
        if not e.header and e.value == selected then target = i break end
    end
    local maxOffset = math.max(0, #entries - MENU_ROWS)
    local offset = math.max(0, math.min(maxOffset, target - math.floor(MENU_ROWS / 2)))
    FauxScrollFrame_Update(menuScroll, #entries, MENU_ROWS, MENU_ROW_H)
    bar:SetValue(offset * MENU_ROW_H)
    FauxScrollFrame_SetOffset(menuScroll, offset)
    MenuUpdate()
end

function List.CloseMenu()
    if menu and menu:IsShown() then menu:Hide() end
    if catcher then catcher:Hide() end
    menuBuild = nil
end
hooksecurefunc("CloseMenus", List.CloseMenu)

function List.MenuFrame() return menu, menuRows, catcher end

local function InstanceTooltip(inst)
    local t = { inst.name }
    if inst.lr then t[#t + 1] = "Levels " .. inst.lr end
    if inst.ml then t[#t + 1] = "Minimum level to enter: " .. inst.ml end
    return t
end

-- the instance menu, in the order of the sort mode (List.InstanceOrder), under expansion headers
local function InstanceEntries()
    local entries, lastExp = {}, nil
    for _, i in ipairs(List.InstanceOrder()) do
        local inst = ns.instances[i]
        if inst.exp ~= lastExp then
            entries[#entries + 1] = { header = true, text = ns.EXPANSIONS[inst.exp] or ("Expansion " .. tostring(inst.exp)) }
            lastExp = inst.exp
        end
        entries[#entries + 1] = {
            text = inst.name, value = i, icon = ns.KIND_ICONS[inst.kind], level = LevelText(inst),
            tooltip = InstanceTooltip(inst),
        }
    end
    return entries
end

-- ---------------------------------------------------------------- dropdown buttons
local function CreateDropdown(parent, y, x0, x1)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(24)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x0 or 0, y)
    if x1 then b:SetPoint("TOPRIGHT", parent, "TOPLEFT", x1, y) else b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y) end
    b:SetBackdrop(DARK_BACKDROP)
    b:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    b:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    b:RegisterForClicks("LeftButtonUp")
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(14)
    b.icon:SetHeight(14)
    b.icon:SetPoint("LEFT", b, "LEFT", 6, 0)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b, "LEFT", 24, 0)
    b.text:SetPoint("RIGHT", b, "RIGHT", -20, 0)
    b.text:SetHeight(14)
    b.text:SetJustifyH("LEFT")
    b.arrow = b:CreateTexture(nil, "OVERLAY")
    b.arrow:SetWidth(16)
    b.arrow:SetHeight(16)
    b.arrow:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    b.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    b.arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    return b
end

local function SimpleTooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title)
        GameTooltip:AddLine(text, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- ---------------------------------------------------------------- list rows
local function RowTooltip(self)
    local r = self.data
    if not r then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local inst = r.inst and ns.instances[r.inst]
    if r.instanceRow then
        for i, line in ipairs(InstanceTooltip(inst)) do
            if i == 1 then GameTooltip:AddLine(line, 1, 0.82, 0) else GameTooltip:AddLine(line, 0.8, 0.8, 0.8) end
        end
        GameTooltip:AddLine(r.count .. " quests listed by AtlasQuest", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Click to show its quests", 0.5, 0.8, 1)
        GameTooltip:Show()
        return
    end
    if not (r.id and ns.quests[r.id]) then
        GameTooltip:AddLine(r.label, 0.7, 0.7, 0.7)
        GameTooltip:AddLine("No chain data: this quest is not in the quest database", 1, 0.3, 0.3, true)
        if inst then GameTooltip:AddLine("Instance: " .. inst.name, 0.8, 0.8, 0.8) end
        GameTooltip:Show()
        return
    end
    local q = ns.quests[r.id]
    local st = ns.Status(r.id)
    GameTooltip:AddLine(q.n, ns.QuestColor(r.id, st))
    local lv = q.lv and tostring(q.lv) or "scaling"
    GameTooltip:AddLine("Level " .. lv .. (q.rl and (" (requires " .. q.rl .. ")") or ""), ns.DifficultyColor(q.lv))
    local c = ns.STATUS_COLOR[st]
    GameTooltip:AddLine("Status: " .. ns.STATUS_TEXT[st], c[1], c[2], c[3])
    if q.dy or q.wk then GameTooltip:AddLine(q.wk and "Weekly" or "Daily", ns.QUEST_COLORS.daily[1], ns.QUEST_COLORS.daily[2], ns.QUEST_COLORS.daily[3]) end
    if q.sk then
        local pc = ns.QUEST_COLORS.profession
        GameTooltip:AddLine("Requires " .. (ns.PROFESSION_NAME[q.sk[1]] or ("skill " .. q.sk[1])) .. (q.sk[2] > 0 and (" (" .. q.sk[2] .. ")") or ""), pc[1], pc[2], pc[3])
    end
    if q.zn then GameTooltip:AddLine("Zone: " .. q.zn, 0.4, 0.8, 0.4) end
    local step, steps = List.Steps(r.id)
    if step and steps > 1 then GameTooltip:AddLine("Step " .. step .. " of " .. steps, 0.8, 0.8, 0.8) end
    if inst then GameTooltip:AddLine("Instance: " .. inst.name, 0.8, 0.8, 0.8) end
    GameTooltip:AddLine("Quest ID: " .. r.id, 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function CreateRow(parent, i)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(ROW_W)
    b:SetHeight(ROW_H)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * ROW_H)
    b:RegisterForClicks("LeftButtonUp")
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    b.sel = b:CreateTexture(nil, "BACKGROUND")
    b.sel:SetAllPoints(b)
    b.sel:SetTexture(1, 0.82, 0, 0.18)
    b.sel:Hide()
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b, "LEFT", 4, 0)
    b.text:SetWidth(ROW_W - 4 - 40)
    b.text:SetHeight(ROW_H)
    b.text:SetJustifyH("LEFT")
    b.steps = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.steps:SetPoint("RIGHT", b, "RIGHT", -2, 0)
    b.steps:SetWidth(38)
    b.steps:SetHeight(ROW_H)
    b.steps:SetJustifyH("RIGHT")
    b:SetScript("OnClick", function(self)
        local r = self.data
        if not r then return end
        if r.instanceRow then ns.UI.OpenInstance(r.inst) return end
        if IsShiftKeyDown() and r.id and ns.quests[r.id] and ns.InsertQuestLink(r.id) then return end
        ns.UI.SelectRow(r)
    end)
    b:SetScript("OnEnter", RowTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function RowColor(r)
    if r.instanceRow then return 1, 0.82, 0 end
    if not (r.id and ns.quests[r.id]) then return NODATA_COLOR[1], NODATA_COLOR[2], NODATA_COLOR[3] end
    local cr, cg, cb = ns.QuestColor(r.id)
    return cr, cg, cb
end
List.RowColor = RowColor

local function UpdateRows()
    FauxScrollFrame_Update(panel.scroll, #data, panel.numRows, ROW_H)
    local offset = ClampedOffset(panel.scroll, #data, panel.numRows)
    local sel = ns.state.row
    for i = 1, #rows do
        local b = rows[i]
        local r = i <= panel.numRows and data[offset + i]
        if r then
            b.data = r
            if r.instanceRow then
                -- an instance of a search: its kind icon, level range and name; on the right, its quest count
                local inst = ns.instances[r.inst]
                local icon = ns.KIND_ICONS[inst.kind]
                b.text:SetText((icon and ("|T" .. icon .. ":14:14|t ") or "") .. (inst.lr and (LevelText(inst) .. " ") or "") .. inst.name)
                b.text:SetTextColor(RowColor(r))
                b.steps:SetText(tostring(r.count))
            else
                b.text:SetText(r.display or r.label)
                b.text:SetTextColor(RowColor(r))
                local step, steps
                if r.id and ns.quests[r.id] then step, steps = List.Steps(r.id) end
                if step and steps > 1 then b.steps:SetText(step .. "/" .. steps) else b.steps:SetText("") end
            end
            b.steps:SetTextColor(0.6, 0.6, 0.6)
            if SameRow(r, sel) then b.sel:Show() else b.sel:Hide() end
            b:Show()
        else
            b.data = nil
            b:Hide()
        end
    end
    if panel.empty then
        if #data == 0 then
            local st = ns.state
            local needle = (st.search or ""):match("^%s*(.-)%s*$")
            if needle ~= "" then panel.empty:SetText("Nothing matches the search")
            elseif not st.instance then panel.empty:SetText("Choose an instance above")
            else panel.empty:SetText("No quests to show") end
            panel.empty:Show()
        else
            panel.empty:Hide()
        end
    end
end

function List.ScrollToRow(r)
    if not (panel and r) then return end
    for i, d in ipairs(data) do
        if SameRow(d, r) then
            local offset = FauxScrollFrame_GetOffset(panel.scroll) or 0
            if i <= offset or i > offset + panel.numRows then
                local maxOffset = math.max(0, #data - panel.numRows)
                local new = math.max(0, math.min(maxOffset, i - math.floor(panel.numRows / 2)))
                local bar = _G[panel.scroll:GetName() .. "ScrollBar"]
                FauxScrollFrame_Update(panel.scroll, #data, panel.numRows, ROW_H)
                bar:SetValue(new * ROW_H)
                FauxScrollFrame_SetOffset(panel.scroll, new)
                UpdateRows()
            end
            return
        end
    end
end

-- ---------------------------------------------------------------- progress
-- the instance's distinct quests on the shown side that count for the character (ns.Counts: its
-- class and race while "My class/race" is on)
local function UpdateProgress()
    local bar = panel.progress
    local st = ns.state
    local inst = st.instance and ns.instances[st.instance]
    if not inst then
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        bar.text:SetText("No instance")
        panel.progressDone, panel.progressTotal = 0, 0
        return
    end
    local seen, total, done = {}, 0, 0
    for _, s in ipairs(inst[SideKey(st.faction)] or {}) do
        local id = s[2]
        if id and not seen[id] and ns.Counts(id, st.faction) then
            seen[id] = true
            total = total + 1
            if ns.completed[id] then done = done + 1 end
        end
    end
    bar:SetMinMaxValues(0, math.max(total, 1))
    bar:SetValue(done)
    bar.text:SetText(done .. " / " .. total .. " completed")
    panel.progressDone, panel.progressTotal = done, total
end

-- ---------------------------------------------------------------- controls
function List.SyncControls()
    if not panel then return end
    local st = ns.state
    local inst = st.instance and ns.instances[st.instance]
    if inst then
        panel.instButton.text:SetText(inst.name)
        panel.instButton.level:SetText(LevelText(inst))
        panel.instButton.icon:SetTexture(ns.KIND_ICONS[inst.kind])
        panel.instButton.icon:Show()
    else
        panel.instButton.text:SetText("Choose an instance")
        panel.instButton.level:SetText("")
        panel.instButton.icon:Hide()
    end
    panel.factionButton.text:SetText(ns.FACTION_NAMES[st.faction] or "")
    panel.factionButton.icon:SetTexture(st.faction == "H" and "Interface\\TargetingFrame\\UI-PVP-Horde" or "Interface\\TargetingFrame\\UI-PVP-Alliance")
    panel.factionButton.icon:SetTexCoord(0.05, 0.6, 0.05, 0.6)
    panel.sortButton.text:SetText("Sort: " .. SORT_SHORT[ns.db.sort])
    panel.classCheck:SetChecked(ns.db.myClassOnly)
    panel.hideCheck:SetChecked(ns.db.hideCompleted)
    local text = panel.search:GetText() or ""
    if text ~= (st.search or "") then
        panel.syncing = true
        panel.search:SetText(st.search or "")
        panel.syncing = false
    end
    if (st.search or "") ~= "" then panel.clear:Show() else panel.clear:Hide() end
end

-- rebuild the list; resetScroll scrolls it back to the top
function List.Refresh(resetScroll)
    if not panel then return end
    data = BuildData()
    if resetScroll then
        local bar = _G[panel.scroll:GetName() .. "ScrollBar"]
        bar:SetValue(0)
        FauxScrollFrame_SetOffset(panel.scroll, 0)
    end
    List.SyncControls()
    UpdateRows()
    UpdateProgress()
end

-- the panel's height changed (the window was resized): as many rows as fit
function List.SetHeight(panelHeight)
    if not panel then return end
    local n = math.max(1, math.floor((panelHeight - LIST_TOP) / ROW_H))
    panel.numRows = n
    for i = #rows + 1, n do
        rows[i] = CreateRow(panel.listFrame, i)
        rows[i]:SetFrameLevel(panel.scroll:GetFrameLevel() + 2)
    end
    panel.scroll:ClearAllPoints()
    panel.scroll:SetPoint("TOPLEFT", panel.listFrame, "TOPLEFT", 0, 0)
    panel.scroll:SetPoint("BOTTOMRIGHT", panel.listFrame, "TOPLEFT", ROW_W, -n * ROW_H)
    UpdateRows()
end

function List.Data() return data end
function List.Rows() return rows end
function List.Panel() return panel end

-- the colour legend, in the tooltip of the "?" button
local function LegendTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Quest colours")
    for _, l in ipairs(ns.LEGEND) do
        local c = ns.QUEST_COLORS[l[1]]
        GameTooltip:AddLine(l[2], c[1], c[2], c[3])
    end
    GameTooltip:AddLine("A daily, profession, class or race quest whose prerequisites are missing is shown darker.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

function List.Create(parent)
    panel = parent
    -- default instance: the last used one, or the first
    if not ns.state.instance then
        ns.state.instance = (ns.db.lastInstance and ns.InstanceByAQ(ns.db.lastInstance)) or (ns.instances[1] and 1) or nil
    end

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, 0)
    label:SetText("Search")
    panel.searchLabel = label

    local legend = CreateFrame("Button", nil, parent)
    panel.legend = legend
    legend:SetWidth(14)
    legend:SetHeight(14)
    legend:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, 2)
    legend:SetNormalTexture("Interface\\FriendsFrame\\InformationIcon")
    legend:SetScript("OnEnter", LegendTooltip)
    legend:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local search = CreateFrame("EditBox", "QuestsInChainsSearchBox", parent, "InputBoxTemplate")
    panel.search = search
    search:SetAutoFocus(false)
    search:SetHeight(20)
    search:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -13)
    search:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -13)
    search:SetTextInsets(16, 18, 0, 0)
    search:SetMaxLetters(60)
    local icon = search:CreateTexture(nil, "OVERLAY")
    icon:SetWidth(14)
    icon:SetHeight(14)
    icon:SetPoint("LEFT", search, "LEFT", 0, -1)
    icon:SetTexture("Interface\\Common\\UI-SearchBox-Icon")
    icon:SetVertexColor(0.7, 0.7, 0.7)
    search:SetScript("OnTextChanged", function(self)
        if panel.syncing then return end
        local text = self:GetText() or ""
        if text == (ns.state.search or "") then return end
        ns.state.search = text
        List.Refresh(true)
    end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    local clear = CreateFrame("Button", nil, search)
    panel.clear = clear
    clear:SetWidth(16)
    clear:SetHeight(16)
    clear:SetPoint("RIGHT", search, "RIGHT", -2, 0)
    clear:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clear:GetNormalTexture():SetAlpha(0.6)
    clear:SetHighlightTexture("Interface\\FriendsFrame\\ClearBroadcastIcon", "ADD")
    clear:RegisterForClicks("LeftButtonUp")
    clear:SetScript("OnClick", function()
        ns.state.search = ""
        panel.syncing = true
        search:SetText("")
        panel.syncing = false
        search:ClearFocus()
        List.Refresh(true)
    end)
    clear:Hide()

    -- the instance: its level range in front of its name
    local instButton = CreateDropdown(parent, -38)
    panel.instButton = instButton
    instButton.level = instButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instButton.level:SetPoint("LEFT", instButton, "LEFT", 24, 0)
    instButton.level:SetWidth(LEVEL_W - 4)
    instButton.level:SetHeight(14)
    instButton.level:SetJustifyH("LEFT")
    instButton.text:ClearAllPoints()
    instButton.text:SetPoint("LEFT", instButton, "LEFT", 24 + LEVEL_W, 0)
    instButton.text:SetPoint("RIGHT", instButton, "RIGHT", -20, 0)
    instButton:SetScript("OnClick", function(self)
        List.OpenMenu(self, InstanceEntries(), function(i)
            if (ns.state.search or "") ~= "" then ns.state.search = "" end
            ns.UI.SetInstance(i)
        end, ns.state.instance)
    end)
    instButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local inst = ns.state.instance and ns.instances[ns.state.instance]
        GameTooltip:AddLine(inst and inst.name or "Instance")
        if inst and inst.lr then GameTooltip:AddLine("Levels " .. inst.lr, 0.8, 0.8, 0.8) end
        if inst and inst.ml then GameTooltip:AddLine("Minimum level to enter: " .. inst.ml, 0.8, 0.8, 0.8) end
        GameTooltip:AddLine("The quests AtlasQuest lists for this instance.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    instButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- the faction (left) and the sort order (right, wider for its text)
    local split = 95
    local factionButton = CreateDropdown(parent, -66, 0, split)
    panel.factionButton = factionButton
    factionButton:SetScript("OnClick", function(self)
        List.OpenMenu(self, {
            { text = "Alliance", value = "A", icon = "Interface\\TargetingFrame\\UI-PVP-Alliance" },
            { text = "Horde", value = "H", icon = "Interface\\TargetingFrame\\UI-PVP-Horde" },
        }, function(f) ns.UI.SetFaction(f) end, ns.state.faction)
    end)
    local sortButton = CreateDropdown(parent, -66, split + 4)
    panel.sortButton = sortButton
    sortButton.icon:Hide()
    sortButton.text:ClearAllPoints()
    sortButton.text:SetPoint("LEFT", sortButton, "LEFT", 8, 0)
    sortButton.text:SetPoint("RIGHT", sortButton, "RIGHT", -20, 0)
    sortButton:SetScript("OnClick", function(self)
        List.OpenMenu(self, {
            { text = SORT_NAMES.aq, value = "aq" }, { text = SORT_NAMES.name, value = "name" }, { text = SORT_NAMES.level, value = "level" },
        }, function(v) ns.UI.SetSort(v) end, ns.db.sort)
    end)
    SimpleTooltip(sortButton, "Sort", "The order of the quests (AtlasQuest's, by name or by level) and of the instance menu (by level: each expansion's dungeons, raids and battlegrounds from the lowest level up).")

    local classCheck = CreateFrame("CheckButton", "QuestsInChainsMyClassCheck", parent, "UICheckButtonTemplate")
    panel.classCheck = classCheck
    classCheck:SetWidth(24)
    classCheck:SetHeight(24)
    classCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", -2, -93)
    _G[classCheck:GetName() .. "Text"]:SetText("My class/race")
    classCheck:SetHitRectInsets(0, -80, 0, 0)
    classCheck:SetScript("OnClick", function(self) ns.UI.SetMyClassOnly(self:GetChecked() and true or false) end)
    SimpleTooltip(classCheck, "My class/race", "Hide the quests of other classes in the chain, and on your own faction's side the quests of other races. The progress bar then counts only your character's quests.")

    local hideCheck = CreateFrame("CheckButton", "QuestsInChainsHideCompletedCheck", parent, "UICheckButtonTemplate")
    panel.hideCheck = hideCheck
    hideCheck:SetWidth(24)
    hideCheck:SetHeight(24)
    hideCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 112, -93)
    _G[hideCheck:GetName() .. "Text"]:SetText("Hide completed")
    hideCheck:SetHitRectInsets(0, -90, 0, 0)
    hideCheck:SetScript("OnClick", function(self) ns.UI.SetHideCompleted(self:GetChecked() and true or false) end)
    SimpleTooltip(hideCheck, "Hide completed", "Leave the completed quests out of the list.")

    local progress = CreateFrame("StatusBar", nil, parent)
    panel.progress = progress
    progress:SetHeight(14)
    progress:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -122)
    progress:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -122)
    progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progress:SetStatusBarColor(0.25, 0.6, 0.25)
    progress:SetMinMaxValues(0, 1)
    progress:SetValue(0)
    local pbg = progress:CreateTexture(nil, "BACKGROUND")
    pbg:SetAllPoints(progress)
    pbg:SetTexture(0, 0, 0, 0.5)
    progress.text = progress:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progress.text:SetPoint("CENTER", progress, "CENTER", 0, 0)

    -- the list: rows over a FauxScrollFrame (the rows are not its children: it hides itself
    -- when everything fits)
    local listFrame = CreateFrame("Frame", nil, parent)
    panel.listFrame = listFrame
    listFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -LIST_TOP)
    listFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    listFrame:EnableMouseWheel(true)
    local scroll = CreateFrame("ScrollFrame", "QuestsInChainsListScroll", listFrame, "FauxScrollFrameTemplate")
    panel.scroll = scroll
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, UpdateRows)
    end)
    listFrame:SetScript("OnMouseWheel", function(self, delta)
        if not scroll:IsShown() then return end
        local bar = _G[scroll:GetName() .. "ScrollBar"]
        bar:SetValue(bar:GetValue() - delta * ROW_H * 3)
    end)
    panel.empty = listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.empty:SetPoint("TOP", listFrame, "TOP", -SCROLLBAR_W / 2, -20)
    panel.empty:Hide()
    List.SetHeight(ns.UI.panelHeight or 524)

    List.SyncControls()
end
