-- UI/ListPanel.lua: the left panel. Search box, instance and faction dropdowns, filters,
-- progress bar and the quest list.
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

local COMPLETED_COLOR = { 0.25, 0.45, 0.25 }
local ACTIVE_COLOR = { 1, 0.82, 0 }
local NODATA_COLOR = { 0.5, 0.5, 0.5 }

-- ---------------------------------------------------------------- helpers
local function SideKey(side) return side == "H" and "h" or "a" end

local function Label(inst, side, slot, title)
    if ns.AtlasQuestLoaded() then
        local t = ns.AQText(inst.aq, slot, side)
        if t then return t end
    end
    return slot .. ". " .. title
end

local function FilterKey()
    return ns.state.faction .. ":" .. tostring(ns.ClassBitFilter() or 0) .. ":" .. tostring(ns.RaceBitFilter() or 0)
end

function List.ClearCache()
    stepCache = {}
end

-- step and number of steps of a quest under the current filters (cached)
function List.Steps(id)
    local key = FilterKey()
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
    return text and string.find(string.lower(text), needle, 1, true) ~= nil
end

-- the rows of the current list: the selected instance, or the search matches of every instance
local function BuildData()
    local out = {}
    local st = ns.state
    local side = st.faction
    local hide = ns.db.hideCompleted
    local needle = (st.search or ""):match("^%s*(.-)%s*$"):lower()
    local function Add(i, inst, s)
        local id = s[2]
        if hide and id and ns.completed[id] then return end
        out[#out + 1] = { inst = i, side = side, slot = s[1], id = id or false, title = s[3], label = Label(inst, side, s[1], s[3]) }
    end
    if needle ~= "" then
        for i, inst in ipairs(ns.instances) do
            for _, s in ipairs(inst[SideKey(side)] or {}) do
                local label = Label(inst, side, s[1], s[3])
                local plain = label:gsub("^%d+%.%s*", "")
                if Matches(s[3], needle) or Matches(plain, needle) then Add(i, inst, s) end
            end
        end
    elseif st.instance and ns.instances[st.instance] then
        local inst = ns.instances[st.instance]
        for _, s in ipairs(inst[SideKey(side)] or {}) do Add(st.instance, inst, s) end
    end
    return out
end

local function SameRow(a, b)
    return a and b and a.inst == b.inst and a.side == b.side and a.slot == b.slot
end

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

-- ---------------------------------------------------------------- popup menu (instances, faction)
local menu, catcher, menuScroll
local menuRows = {}
local menuEntries, menuPick, menuSelected = {}, nil, nil

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
            if e.header then
                b.text:SetText(e.text)
                b.text:SetTextColor(1, 0.82, 0)
                b.text:SetPoint("LEFT", b, "LEFT", 4, 0)
                b.icon:Hide()
                b:Disable()
                b.check:Hide()
            else
                b.text:SetText(e.text)
                b.text:SetTextColor(1, 1, 1)
                if e.icon then
                    b.icon:SetTexture(e.icon)
                    b.icon:Show()
                    b.text:SetPoint("LEFT", b, "LEFT", 30, 0)
                else
                    b.icon:Hide()
                    b.text:SetPoint("LEFT", b, "LEFT", 12, 0)
                end
                b:Enable()
                if e.value == menuSelected then b.check:Show() else b.check:Hide() end
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
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", b, "LEFT", 30, 0)
        b.text:SetPoint("RIGHT", b, "RIGHT", -2, 0)
        b.text:SetHeight(MENU_ROW_H)
        b.text:SetJustifyH("LEFT")
        b:SetScript("OnClick", function(self)
            local e = self.entry
            if not e or e.header then return end
            local pick = menuPick
            List.CloseMenu()
            if pick then pick(e.value) end
        end)
        menuRows[i] = b
    end
end

function List.OpenMenu(anchor, entries, pick, selected)
    if not menu then CreateMenu() end
    menuEntries, menuPick, menuSelected = entries, pick, selected
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
end
hooksecurefunc("CloseMenus", List.CloseMenu)

function List.MenuFrame() return menu, menuRows, catcher end

local function InstanceEntries()
    local entries, lastExp = {}, nil
    for i, inst in ipairs(ns.instances) do
        if inst.exp ~= lastExp then
            entries[#entries + 1] = { header = true, text = ns.EXPANSIONS[inst.exp] or ("Expansion " .. tostring(inst.exp)) }
            lastExp = inst.exp
        end
        entries[#entries + 1] = { text = inst.name, value = i, icon = ns.KIND_ICONS[inst.kind] }
    end
    return entries
end

-- ---------------------------------------------------------------- dropdown buttons
local function CreateDropdown(parent, y)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(24)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
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
    b.text:SetPoint("RIGHT", b, "RIGHT", -24, 0)
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

-- ---------------------------------------------------------------- list rows
local function RowTooltip(self)
    local r = self.data
    if not r then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local inst = ns.instances[r.inst]
    if not (r.id and ns.quests[r.id]) then
        GameTooltip:AddLine(r.label, 0.7, 0.7, 0.7)
        GameTooltip:AddLine("No chain data: this quest is not in the quest database", 1, 0.3, 0.3, true)
        if inst then GameTooltip:AddLine("Instance: " .. inst.name, 0.8, 0.8, 0.8) end
        GameTooltip:Show()
        return
    end
    local q = ns.quests[r.id]
    local st = ns.Status(r.id)
    GameTooltip:AddLine(q.n, 1, 1, 1)
    local lv = q.lv and tostring(q.lv) or "scaling"
    GameTooltip:AddLine("Level " .. lv .. (q.rl and (" (requires " .. q.rl .. ")") or ""), ns.DifficultyColor(q.lv))
    local c = ns.STATUS_COLOR[st]
    GameTooltip:AddLine("Status: " .. ns.STATUS_TEXT[st], c[1], c[2], c[3])
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
        if IsShiftKeyDown() and r.id and ns.quests[r.id] and ns.InsertQuestLink(r.id) then return end
        ns.UI.SelectRow(r)
    end)
    b:SetScript("OnEnter", RowTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function RowColor(r)
    if not (r.id and ns.quests[r.id]) then return NODATA_COLOR[1], NODATA_COLOR[2], NODATA_COLOR[3] end
    if ns.completed[r.id] then return COMPLETED_COLOR[1], COMPLETED_COLOR[2], COMPLETED_COLOR[3] end
    if ns.active[r.id] then return ACTIVE_COLOR[1], ACTIVE_COLOR[2], ACTIVE_COLOR[3] end
    return ns.DifficultyColor(ns.quests[r.id].lv)
end

local function UpdateRows()
    FauxScrollFrame_Update(panel.scroll, #data, panel.numRows, ROW_H)
    local offset = ClampedOffset(panel.scroll, #data, panel.numRows)
    local sel = ns.state.row
    for i = 1, panel.numRows do
        local b = rows[i]
        local r = data[offset + i]
        if r then
            b.data = r
            b.text:SetText(r.label)
            b.text:SetTextColor(RowColor(r))
            local step, steps
            if r.id and ns.quests[r.id] then step, steps = List.Steps(r.id) end
            if step and steps > 1 then b.steps:SetText(step .. "/" .. steps) else b.steps:SetText("") end
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
            if needle ~= "" then panel.empty:SetText("No quest matches the search")
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
local function UpdateProgress()
    local bar = panel.progress
    local st = ns.state
    local inst = st.instance and ns.instances[st.instance]
    if not inst then
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        bar.text:SetText("No instance")
        return
    end
    local seen, total, done = {}, 0, 0
    for _, s in ipairs(inst[SideKey(st.faction)] or {}) do
        local id = s[2]
        if id and not seen[id] then
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
        panel.instButton.icon:SetTexture(ns.KIND_ICONS[inst.kind])
        panel.instButton.icon:Show()
    else
        panel.instButton.text:SetText("Choose an instance")
        panel.instButton.icon:Hide()
    end
    panel.factionButton.text:SetText(ns.FACTION_NAMES[st.faction] or "")
    panel.factionButton.icon:SetTexture(st.faction == "H" and "Interface\\TargetingFrame\\UI-PVP-Horde" or "Interface\\TargetingFrame\\UI-PVP-Alliance")
    panel.factionButton.icon:SetTexCoord(0.05, 0.6, 0.05, 0.6)
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

function List.Data() return data end
function List.Rows() return rows end
function List.Panel() return panel end

function List.Create(parent)
    panel = parent
    -- default instance: the last used one, or the first
    if not ns.state.instance then
        ns.state.instance = (ns.db.lastInstance and ns.InstanceByAQ(ns.db.lastInstance)) or (ns.instances[1] and 1) or nil
    end

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, 0)
    label:SetText("Search quests")
    panel.searchLabel = label

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

    local instButton = CreateDropdown(parent, -38)
    panel.instButton = instButton
    instButton:SetScript("OnClick", function(self)
        List.OpenMenu(self, InstanceEntries(), function(i)
            if (ns.state.search or "") ~= "" then ns.state.search = "" end
            ns.UI.SetInstance(i)
        end, ns.state.instance)
    end)
    instButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Instance")
        GameTooltip:AddLine("The quests AtlasQuest lists for this instance.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    instButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local factionButton = CreateDropdown(parent, -66)
    panel.factionButton = factionButton
    factionButton:SetScript("OnClick", function(self)
        List.OpenMenu(self, {
            { text = "Alliance", value = "A", icon = "Interface\\TargetingFrame\\UI-PVP-Alliance" },
            { text = "Horde", value = "H", icon = "Interface\\TargetingFrame\\UI-PVP-Horde" },
        }, function(f) ns.UI.SetFaction(f) end, ns.state.faction)
    end)

    local classCheck = CreateFrame("CheckButton", "QuestsInChainsMyClassCheck", parent, "UICheckButtonTemplate")
    panel.classCheck = classCheck
    classCheck:SetWidth(24)
    classCheck:SetHeight(24)
    classCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", -2, -93)
    _G[classCheck:GetName() .. "Text"]:SetText("My class/race")
    classCheck:SetHitRectInsets(0, -80, 0, 0)
    classCheck:SetScript("OnClick", function(self) ns.UI.SetMyClassOnly(self:GetChecked() and true or false) end)
    classCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("My class/race")
        GameTooltip:AddLine("Hide the quests of other classes in the chain, and on your own faction's side the quests of other races.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    classCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local hideCheck = CreateFrame("CheckButton", "QuestsInChainsHideCompletedCheck", parent, "UICheckButtonTemplate")
    panel.hideCheck = hideCheck
    hideCheck:SetWidth(24)
    hideCheck:SetHeight(24)
    hideCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 112, -93)
    _G[hideCheck:GetName() .. "Text"]:SetText("Hide completed")
    hideCheck:SetHitRectInsets(0, -90, 0, 0)
    hideCheck:SetScript("OnClick", function(self) ns.UI.SetHideCompleted(self:GetChecked() and true or false) end)
    hideCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Hide completed")
        GameTooltip:AddLine("Leave the completed quests out of the list.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    hideCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
    local height = (ns.UI.panelHeight or 524) - LIST_TOP
    panel.numRows = math.floor(height / ROW_H)
    local scroll = CreateFrame("ScrollFrame", "QuestsInChainsListScroll", listFrame, "FauxScrollFrameTemplate")
    panel.scroll = scroll
    scroll:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", listFrame, "TOPLEFT", ROW_W, -panel.numRows * ROW_H)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, UpdateRows)
    end)
    listFrame:SetScript("OnMouseWheel", function(self, delta)
        if not scroll:IsShown() then return end
        local bar = _G[scroll:GetName() .. "ScrollBar"]
        bar:SetValue(bar:GetValue() - delta * ROW_H * 3)
    end)
    for i = 1, panel.numRows do
        rows[i] = CreateRow(listFrame, i)
        rows[i]:SetFrameLevel(scroll:GetFrameLevel() + 2)
    end
    panel.empty = listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.empty:SetPoint("TOP", listFrame, "TOP", -SCROLLBAR_W / 2, -20)
    panel.empty:Hide()

    List.SyncControls()
end
