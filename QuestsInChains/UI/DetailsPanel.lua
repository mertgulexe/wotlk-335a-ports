-- UI/DetailsPanel.lua: the right panel. Details of the selected quest in a scroll frame.
local _, ns = ...

local Details = {}
ns.Details = Details

local box, scroll, content
local W = 250
local texts, quests, items = {}, {}, {}
local used = { texts = 0, quests = 0, items = 0 }
local y = 0
Details.lines = {} -- plain text of what is shown, in order (for the tests)
Details.questRows = {}
Details.itemRows = {}

local BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- ---------------------------------------------------------------- building blocks
local function Reset()
    for i = 1, #texts do texts[i]:Hide() end
    for i = 1, #quests do quests[i]:Hide() quests[i].questID = nil end
    for i = 1, #items do items[i]:Hide() items[i].itemID = nil end
    used.texts, used.quests, used.items = 0, 0, 0
    y = 0
    Details.lines, Details.questRows, Details.itemRows = {}, {}, {}
end

local function Gap(h) y = y + (h or 6) end

local function Text(text, font, r, g, b, indent)
    used.texts = used.texts + 1
    local fs = texts[used.texts]
    if not fs then
        fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        texts[used.texts] = fs
    end
    indent = indent or 0
    fs:SetFontObject(_G[font or "GameFontHighlightSmall"] or GameFontHighlightSmall)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", content, "TOPLEFT", indent, -y)
    fs:SetWidth(W - indent)
    fs:SetText(text)
    fs:SetTextColor(r or 1, g or 1, b or 1)
    fs:Show()
    local h = fs:GetHeight()
    if not h or h < 10 then h = 10 end
    y = y + math.floor(h + 0.5) + 2
    Details.lines[#Details.lines + 1] = text
    return fs
end

local function Header(text)
    Gap(6)
    return Text(text, "GameFontNormal", 1, 0.82, 0)
end

local function StatusIcon(tex, status)
    local icon, desat, alpha = ns.Graph.StatusLook(status, nil)
    tex:SetTexture(icon)
    ns.Graph.SetDesaturated(tex, desat)
    tex:SetAlpha(alpha)
end

local function QuestRow(id)
    used.quests = used.quests + 1
    local b = quests[used.quests]
    if not b then
        b = CreateFrame("Button", nil, content)
        b:SetHeight(14)
        b:RegisterForClicks("LeftButtonUp")
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetWidth(12)
        b.icon:SetHeight(12)
        b.icon:SetPoint("LEFT", b, "LEFT", 0, 0)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", b, "LEFT", 15, 0)
        b.text:SetHeight(14)
        b.text:SetJustifyH("LEFT")
        b:SetScript("OnClick", function(self)
            local qid = self.questID
            if not qid then return end
            if IsShiftKeyDown() and ns.InsertQuestLink(qid) then return end
            ns.UI.SelectQuest(qid)
        end)
        b:SetScript("OnEnter", function(self)
            local q = self.questID and ns.quests[self.questID]
            if not q then return end
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            local st = ns.Status(self.questID)
            local c = ns.STATUS_COLOR[st]
            GameTooltip:AddDoubleLine(q.n, ns.STATUS_TEXT[st], 1, 1, 1, c[1], c[2], c[3])
            if q.zn then GameTooltip:AddLine(q.zn, 0.4, 0.8, 0.4) end
            GameTooltip:AddLine("Quest ID: " .. self.questID, 0.5, 0.5, 0.5)
            GameTooltip:AddLine("Click to select it in the graph", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        quests[used.quests] = b
    end
    local q = ns.quests[id]
    local st = ns.Status(id)
    b.questID = id
    b.rowY = y
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -y)
    b:SetWidth(W - 8)
    b.text:SetWidth(W - 8 - 15)
    StatusIcon(b.icon, st)
    local lv = q.lv and ("[" .. q.lv .. "] ") or ""
    b.text:SetText(lv .. q.n)
    local bright = st == "completed" or st == "active" or st == "available"
    if bright then b.text:SetTextColor(1, 1, 1) else b.text:SetTextColor(0.6, 0.6, 0.6) end
    b:Show()
    y = y + 15
    Details.questRows[#Details.questRows + 1] = b
    Details.lines[#Details.lines + 1] = "- " .. q.n
    return b
end

local function QuestList(title, ids)
    if not ids or #ids == 0 then return end
    Header(title)
    for _, id in ipairs(ids) do
        if ns.quests[id] then QuestRow(id) end
    end
end

-- AtlasQuest's reward item k of a slot: id, name (coloured), description
local function AQItem(aq, slot, side, k)
    local suffix = (side == "H") and "_HORDE" or ""
    local base = "Inst" .. aq .. "Quest" .. slot
    local id = tonumber(rawget(_G, base .. "ID" .. k .. suffix))
    if not id then return nil end
    local name, _, quality = GetItemInfo(id)
    local text
    if name then
        local _, _, _, hex = GetItemQualityColor(quality or 1)
        text = (hex or "") .. name
    else
        local itc, nm = rawget(_G, base .. "ITC" .. k .. suffix), rawget(_G, base .. "name" .. k .. suffix)
        text = (type(itc) == "string" and itc or "") .. (type(nm) == "string" and nm or ("Item " .. id))
    end
    local desc = rawget(_G, base .. "description" .. k .. suffix)
    return id, text, type(desc) == "string" and desc or nil
end

local function ItemRow(id, text, desc)
    used.items = used.items + 1
    local b = items[used.items]
    if not b then
        b = CreateFrame("Button", nil, content)
        b:SetHeight(28)
        b:RegisterForClicks("LeftButtonUp")
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetWidth(24)
        b.icon:SetHeight(24)
        b.icon:SetPoint("LEFT", b, "LEFT", 0, 0)
        b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.name:SetPoint("TOPLEFT", b, "TOPLEFT", 28, -2)
        b.name:SetHeight(12)
        b.name:SetJustifyH("LEFT")
        b.desc = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        b.desc:SetPoint("TOPLEFT", b, "TOPLEFT", 28, -15)
        b.desc:SetHeight(11)
        b.desc:SetJustifyH("LEFT")
        -- the item's tooltip; the only place that asks the server about an uncached item
        b:SetScript("OnEnter", function(self)
            if not self.itemID then return end
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink("item:" .. self.itemID)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b:SetScript("OnClick", function(self)
            if not self.itemID or not IsShiftKeyDown() then return end
            local _, link = GetItemInfo(self.itemID)
            if link and ChatEdit_GetActiveWindow() then ChatEdit_InsertLink(link) end
        end)
        items[used.items] = b
    end
    b.itemID = id
    b.rowY = y
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -y)
    b:SetWidth(W - 8)
    b.name:SetWidth(W - 8 - 28)
    b.desc:SetWidth(W - 8 - 28)
    b.name:SetText(text)
    b.desc:SetText(desc or "")
    b.icon:SetTexture(GetItemIcon(id) or select(10, GetItemInfo(id)) or QUESTION_ICON)
    b:Show()
    y = y + 30
    Details.itemRows[#Details.itemRows + 1] = b
    Details.lines[#Details.lines + 1] = "* " .. text
    return b
end

-- rows outside the visible part of the scroll frame are hidden; a row at the edge takes clicks
-- only on its visible part
local function Cull()
    local top = scroll:GetVerticalScroll() or 0
    local h = scroll:GetHeight() or 0
    if h <= 0 then h = Details.viewH or 0 end
    local function cull(list, n)
        for i = 1, n do
            local b = list[i]
            local y0 = b.rowY - top
            local y1 = y0 + b:GetHeight()
            if y1 <= 0 or y0 >= h then
                if b:IsShown() then
                    if GameTooltip:IsOwned(b) then GameTooltip:Hide() end
                    b:Hide()
                end
            else
                b:SetHitRectInsets(0, 0, y0 < 0 and -y0 or 0, y1 > h and (y1 - h) or 0)
                b:Show()
            end
        end
    end
    cull(quests, used.quests)
    cull(items, used.items)
end
Details.Cull = Cull

local function Finish()
    content:SetHeight(math.max(1, y + 8))
    scroll:SetVerticalScroll(0)
    scroll:UpdateScrollChildRect()
    box:Show()
    Cull()
end

-- ---------------------------------------------------------------- sections
local function PlaceText(p)
    if not p then return nil end
    local kind = p[1] == "obj" and " (object)" or (p[1] == "item" and " (item)" or "")
    local s = (p[2] or "?") .. kind
    if p[3] then s = s .. ", " .. p[3] end
    if p[4] and p[5] then s = s .. string.format(" (%.1f, %.1f)", p[4], p[5]) end
    return s
end

-- the AtlasQuest slot that gives the texts for a quest: the selected row, else the current
-- instance, else the first one of the current side, else any
function Details.SlotFor(id)
    local st = ns.state
    local r = st.row
    if r and r.id == id then return r.inst, r.side, r.slot end
    local slots = ns.SlotsOf(id) or {}
    for _, s in ipairs(slots) do
        if s.inst == st.instance and s.side == st.faction then return s.inst, s.side, s.slot end
    end
    for _, s in ipairs(slots) do
        if s.side == st.faction then return s.inst, s.side, s.slot end
    end
    if slots[1] then return slots[1].inst, slots[1].side, slots[1].slot end
    return nil
end

local function AtlasQuestSection(instIndex, side, slot)
    if not (instIndex and ns.AtlasQuestLoaded()) then return end
    local inst = ns.instances[instIndex]
    if not inst then return end
    local aq = inst.aq
    local function line(label, suffix)
        local v = ns.AQText(aq, slot, side, suffix)
        if v and v ~= "" then
            Text(label, "GameFontNormalSmall", 1, 0.82, 0)
            Text(v, "GameFontHighlightSmall", 1, 1, 1, 6)
        end
    end
    Header("AtlasQuest (" .. inst.name .. ")")
    line("Location:", "_Location")
    line("Aim:", "_Aim")
    line("Note:", "_Note")
    line("Prequest:", "_Prequest")
    line("Follow-up:", "_Folgequest")
    local rt = rawget(_G, "Inst" .. aq .. "Quest" .. slot .. "Rewardtext" .. ((side == "H") and "_HORDE" or ""))
    local first = true
    for k = 1, 6 do
        local id, text, desc = AQItem(aq, slot, side, k)
        if id then
            if first then
                Gap(4)
                Text(type(rt) == "string" and rt or "Rewards:", "GameFontNormalSmall", 1, 0.82, 0)
                first = false
            end
            ItemRow(id, text, desc)
        end
    end
end

local function InstanceNames(id)
    local seen, names = {}, {}
    for _, s in ipairs(ns.SlotsOf(id) or {}) do
        if not seen[s.inst] then
            seen[s.inst] = true
            names[#names + 1] = ns.instances[s.inst].name
        end
    end
    return names
end

-- the children of a quest that are visible under the current filters
local function VisibleChildren(id)
    local opts = ns.ChainOpts()
    local vis = ns.Chain.MakeVisible(opts, ns.state.root)
    local out = {}
    for _, c in ipairs(ns.Chain.ChildrenOf(id) or {}) do
        if vis(c) then out[#out + 1] = c end
    end
    return out
end

-- ---------------------------------------------------------------- public
function Details.Clear()
    if not box then return end
    Reset()
    Text("Select a quest to see its details", "GameFontHighlightSmall", 0.6, 0.6, 0.6)
    Details.shown = nil
    Finish()
end

function Details.Show(id)
    if not box then return end
    local q = ns.quests[id]
    if not q then Details.Clear() return end
    Reset()
    Details.shown = id
    local g = ns.state.graph
    local node = g and g.byId[id]
    Text(q.n, "GameFontNormalLarge", 1, 0.82, 0)
    Text("Quest ID: " .. id, "GameFontHighlightSmall", 0.6, 0.6, 0.6)
    local lv = q.lv and tostring(q.lv) or "scaling"
    Text("Level " .. lv .. (q.rl and (" (requires " .. q.rl .. ")") or ""), "GameFontHighlightSmall", ns.DifficultyColor(q.lv))
    if q.zn then
        local icon = q.zk and ns.ZONE_KIND_ICONS[q.zk]
        Text((icon and ("|T" .. icon .. ":14:14|t ") or "") .. q.zn, "GameFontHighlightSmall", 0.4, 0.8, 0.4)
    end
    local inst = InstanceNames(id)
    if #inst > 0 then Text("Instance: " .. table.concat(inst, ", "), "GameFontHighlightSmall", 0.8, 0.8, 0.8) end
    local st = ns.Status(id)
    local c = ns.STATUS_COLOR[st]
    Text("Status: " .. ns.STATUS_TEXT[st], "GameFontHighlightSmall", c[1], c[2], c[3])
    if node then Text("Step " .. node.step .. " of " .. g.steps, "GameFontHighlightSmall", 0.8, 0.8, 0.8) end
    local cls = ns.ClassText(q.cl)
    if cls then Text("Class: " .. cls, "GameFontHighlightSmall", 1, 0.5, 0.25) end
    local race = ns.RaceText(q.rc)
    if race then Text("Race: " .. race, "GameFontHighlightSmall", 1, 0.5, 0.25) end
    if q.rp then Text("Repeatable", "GameFontHighlightSmall", 0.6, 0.8, 1) end
    local start, finish = PlaceText(q.st), PlaceText(q.en)
    if start then Text("Start: " .. start, "GameFontHighlightSmall", 1, 1, 1) end
    if finish then Text("End: " .. finish, "GameFontHighlightSmall", 1, 1, 1) end

    if node then
        local p = node.parents
        QuestList("Requires all of:", p.req)
        QuestList("Requires one of " .. #p.one .. ":", p.one)
        QuestList(#p.lead >= 2 and "Follows one of:" or "Follows:", p.lead)
        QuestList("Optional lead-in:", p.opt)
    end
    QuestList("Leads to:", VisibleChildren(id))
    if q.ex or q.xo then
        local ex = {}
        for _, x in ipairs(q.ex or {}) do if ns.quests[x] then ex[#ex + 1] = x end end
        if #ex > 0 then QuestList("Not available after:", ex) else Header("Not available after:") end
        -- exclusive quests outside the chain data: name only, not clickable
        for _, x in ipairs(q.xo or {}) do
            local name = ns.xnames and ns.xnames[x] or ("Quest " .. x)
            Text("- " .. name .. " (" .. x .. ")", "GameFontHighlightSmall", 0.6, 0.6, 0.6)
        end
    end
    if q.ob and q.ob ~= "" then
        Header("Objectives")
        Text(q.ob, "GameFontHighlightSmall", 1, 1, 1)
    end
    AtlasQuestSection(Details.SlotFor(id))
    if q.rep and #q.rep > 0 then
        Header("Reputation")
        for _, r in ipairs(q.rep) do
            local sign = r[2] > 0 and "+" or ""
            Text(sign .. r[2] .. " " .. (r[3] or ("Faction " .. r[1])), "GameFontHighlightSmall", r[2] > 0 and 0.4 or 1, r[2] > 0 and 0.8 or 0.3, r[2] > 0 and 0.4 or 0.3)
        end
    end
    Finish()
end

-- a list row without chain data: only AtlasQuest's texts
function Details.ShowSlot(row)
    if not box then return end
    if not row then Details.Clear() return end
    Reset()
    Details.shown = nil
    Text(row.title or row.label or "?", "GameFontNormalLarge", 0.7, 0.7, 0.7)
    Text("No chain data: this quest is not in the quest database", "GameFontHighlightSmall", 1, 0.3, 0.3)
    local inst = ns.instances[row.inst]
    if inst then Text("Instance: " .. inst.name, "GameFontHighlightSmall", 0.8, 0.8, 0.8) end
    if row.id then Text("Quest ID: " .. row.id, "GameFontHighlightSmall", 0.6, 0.6, 0.6) end
    AtlasQuestSection(row.inst, row.side, row.slot)
    Finish()
end

function Details.Frames() return box, scroll, content end

function Details.Create(parent)
    box = CreateFrame("Frame", nil, parent)
    box:SetAllPoints(parent)
    box:SetBackdrop(BACKDROP)
    box:SetBackdropColor(0.02, 0.02, 0.02, 0.6)
    box:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    scroll = CreateFrame("ScrollFrame", "QuestsInChainsDetailsScroll", box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -28, 8)
    local UI = ns.UI
    W = UI.FRAME_W - 4 * 8 - UI.LEFT_W - UI.MID_W - 8 - 28
    Details.viewH = (UI.panelHeight or 524) - 16
    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(W)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    scroll:HookScript("OnVerticalScroll", Cull)
    Details.Clear()
end
