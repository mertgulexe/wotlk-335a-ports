-- UI/ChainGraph.lua: the middle panel. A scrollable graph of quest cards and connectors.
-- Chain.lua computes every position; this file only places frames and textures.
--
-- The ScrollFrame clips; its scroll child has the size of the view, and the canvas inside it
-- (sized to the content) is moved by its anchor offset. Cards outside the view are hidden and a
-- card at the edge only takes clicks on its visible part.
local _, ns = ...

local Graph = {}
ns.Graph = Graph

local NODE_W, NODE_H = 200, 44
local WHEEL_STEP = 40
local ICON = 28

local CARD_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local SMALL_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local GREY = { 0.45, 0.45, 0.45, 0.9 }
local GREEN = { 0.37, 0.73, 0.28, 0.8 }
local BLUE = { 0.35, 0.6, 1, 0.9 }
local OPT = { 0.5, 0.5, 0.5, 0.45 }
local GOLD = { 1, 0.82, 0, 1 }
Graph.COLORS = { grey = GREY, green = GREEN, blue = BLUE, opt = OPT }

local ICONS = {
    completed = "Interface\\RaidFrame\\ReadyCheck-Ready",
    active = "Interface\\GossipFrame\\ActiveQuestIcon",
    available = "Interface\\GossipFrame\\AvailableQuestIcon",
    locked = "Interface\\GossipFrame\\AvailableQuestIcon",
    unavailable = "Interface\\RaidFrame\\ReadyCheck-NotReady",
    otherclass = "Interface\\GossipFrame\\AvailableQuestIcon",
    otherrace = "Interface\\GossipFrame\\AvailableQuestIcon",
}
Graph.ICONS = ICONS
local ARROW_TEXTURE = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"

local view, child, canvas, placeholder, summary, levelCard
local viewW, viewH = 1, 1
local cards, lines, arrows = {}, {}, {}
local used = { cards = 0, lines = 0, arrows = 0 }
local graph, selectedId
local scrollX, scrollY, originX = 0, 0, 0

-- ---------------------------------------------------------------- status look
-- icon texture, desaturated, alpha; background and border colours of a card
function Graph.StatusLook(status, lv)
    local dr, dg, db = ns.DifficultyColor(lv)
    if status == "completed" then
        return ICONS.completed, false, 1, { 0.25, 0.45, 0.25, 0.25 }, { 0.25, 0.45, 0.25, 0.8 }
    elseif status == "active" then
        return ICONS.active, false, 1, { 0.055, 0.306, 0.576, 0.7 }, GOLD
    elseif status == "available" then
        return ICONS.available, false, 1, { dr, dg, db, 0.15 }, { dr, dg, db, 0.6 }
    elseif status == "unavailable" then
        return ICONS.unavailable, false, 1, { 0.1, 0.1, 0.1, 0.5 }, { 0.5, 0.2, 0.2, 1 }
    elseif status == "otherclass" or status == "otherrace" then
        return ICONS[status], true, 1, { 0.1, 0.1, 0.1, 0.5 }, { 0.5, 0.2, 0.2, 1 }
    end
    return ICONS.locked, true, 0.6, { 0.1, 0.1, 0.1, 0.5 }, { 0.35, 0.35, 0.35, 1 }
end

function Graph.SetDesaturated(tex, on)
    -- without shader support SetDesaturated does nothing; grey the texture then
    if tex:SetDesaturated(on) then
        tex:SetVertexColor(1, 1, 1)
    elseif on then
        tex:SetVertexColor(0.5, 0.5, 0.5)
    else
        tex:SetVertexColor(1, 1, 1)
    end
end

-- colour of a connector rect or arrow from Chain.lua
function Graph.ConnectorColor(part, kind, fromCompleted)
    if part == "drop" or part == "arrow" then
        if kind == "one" then return BLUE end
        if kind == "opt" then return OPT end
    end
    return fromCompleted and GREEN or GREY
end

-- ---------------------------------------------------------------- tooltip
local function NameOf(id)
    local q = ns.quests[id]
    return q and q.n or tostring(id)
end

function Graph.CardTooltip(self)
    local n = self.node
    if not n then return end
    local q = ns.quests[n.id]
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local c = ns.STATUS_COLOR[n.status] or ns.STATUS_COLOR.locked
    local nr, ng, nb = ns.QuestColor(n.id, n.status)
    GameTooltip:AddDoubleLine(q.n, ns.STATUS_TEXT[n.status] or "", nr, ng, nb, c[1], c[2], c[3])
    local dc, pc = ns.QUEST_COLORS.daily, ns.QUEST_COLORS.profession
    if q.dy or q.wk then GameTooltip:AddLine(q.wk and "Weekly" or "Daily", dc[1], dc[2], dc[3]) end
    if q.sk then
        GameTooltip:AddLine("Requires " .. (ns.PROFESSION_NAME[q.sk[1]] or ("skill " .. q.sk[1])) .. (q.sk[2] > 0 and (" (" .. q.sk[2] .. ")") or ""), pc[1], pc[2], pc[3])
    end
    if graph then GameTooltip:AddLine("Step " .. n.step .. " of " .. graph.steps, 0.8, 0.8, 0.8) end
    if n.oneCount then GameTooltip:AddLine("Requires one of " .. n.oneCount, 0.35, 0.6, 1) end
    if n.leadCount then
        local names = {}
        for _, p in ipairs(n.parents.lead) do names[#names + 1] = NameOf(p) end
        GameTooltip:AddLine("Follows one of: " .. table.concat(names, ", "), 0.8, 0.8, 0.8, true)
    end
    if n.leadIn then GameTooltip:AddLine("Optional lead-in", 0.6, 0.6, 0.6) end
    local cls = ns.ClassText(q.cl)
    if cls then GameTooltip:AddLine("Class: " .. cls, 1, 0.5, 0.25, true) end
    local race = ns.RaceText(q.rc)
    if race then GameTooltip:AddLine("Race: " .. race, 1, 0.5, 0.25, true) end
    GameTooltip:AddLine("Quest ID: " .. n.id, 0.5, 0.5, 0.5)
    GameTooltip:AddLine("Shift-click to link in chat", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-- ---------------------------------------------------------------- pools
local function NewCard()
    local b = CreateFrame("Button", nil, canvas)
    b:SetWidth(NODE_W)
    b:SetHeight(NODE_H)
    b:SetBackdrop(CARD_BACKDROP)
    b:RegisterForClicks("LeftButtonUp")
    b.hover = b:CreateTexture(nil, "HIGHLIGHT")
    b.hover:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
    b.hover:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
    b.hover:SetTexture(1, 1, 1, 0.1)
    b.selected = b:CreateTexture(nil, "ARTWORK")
    b.selected:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
    b.selected:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
    b.selected:SetTexture(1, 1, 1, 0.12)
    b.selected:Hide()
    b.icon = b:CreateTexture(nil, "OVERLAY")
    b.icon:SetWidth(ICON)
    b.icon:SetHeight(ICON)
    b.icon:SetPoint("LEFT", b, "LEFT", 6, 0)
    b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.name:SetPoint("TOPLEFT", b, "TOPLEFT", 6 + ICON + 5, -7)
    b.name:SetWidth(NODE_W - (6 + ICON + 5) - 30)
    b.name:SetHeight(14)
    b.name:SetJustifyH("LEFT")
    b.zoneIcon = b:CreateTexture(nil, "OVERLAY")
    b.zoneIcon:SetWidth(12)
    b.zoneIcon:SetHeight(12)
    b.zoneIcon:SetPoint("TOPLEFT", b, "TOPLEFT", 6 + ICON + 5, -24)
    b.zone = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.zone:SetHeight(12)
    b.zone:SetJustifyH("LEFT")
    b.zone:SetTextColor(0.4, 0.8, 0.4)
    b.req = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.req:SetPoint("TOPRIGHT", b, "TOPRIGHT", -6, -7)
    b.req:SetWidth(26)
    b.req:SetHeight(12)
    b.req:SetJustifyH("RIGHT")
    b.req:SetTextColor(1, 0.3, 0.3)
    b.lvl = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.lvl:SetPoint("TOPRIGHT", b, "TOPRIGHT", -6, -22)
    b.lvl:SetWidth(26)
    b.lvl:SetHeight(12)
    b.lvl:SetJustifyH("RIGHT")
    b:SetScript("OnClick", function(self)
        local n = self.node
        if not n then return end
        if IsShiftKeyDown() and ns.InsertQuestLink(n.id) then return end
        ns.UI.SelectQuest(n.id)
    end)
    b:SetScript("OnEnter", Graph.CardTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function Acquire(pool, kind, make)
    used[kind] = used[kind] + 1
    local o = pool[used[kind]]
    if not o then
        o = make()
        pool[used[kind]] = o
    end
    return o
end

local function ReleaseAll()
    for i = 1, #cards do cards[i]:Hide() cards[i].node = nil end
    for i = 1, #lines do lines[i]:Hide() end
    for i = 1, #arrows do arrows[i]:Hide() end
    used.cards, used.lines, used.arrows = 0, 0, 0
end

-- ---------------------------------------------------------------- scrolling
-- the summary and level cards sit over the bottom corners of the view: the content gets that much
-- room below it, so the bottom cards (often the selected quest) can be scrolled above them
local OVERLAY_GAP = 8 -- the cards are 8 px from the bottom
local function OverlayRoom()
    local h = 0
    if summary and summary:IsShown() then h = summary:GetHeight() end
    if levelCard and levelCard:IsShown() and levelCard:GetHeight() > h then h = levelCard:GetHeight() end
    if h <= 0 then return 0 end
    return math.ceil(h) + OVERLAY_GAP
end
Graph.OverlayRoom = OverlayRoom

local function ContentSize()
    if not graph then return 0, 0 end
    return graph.width, graph.height + OverlayRoom()
end

local function Clamp()
    local w, h = ContentSize()
    local maxX, maxY = math.max(0, w - viewW), math.max(0, h - viewH)
    if scrollX > maxX then scrollX = maxX end
    if scrollY > maxY then scrollY = maxY end
    if scrollX < 0 then scrollX = 0 end
    if scrollY < 0 then scrollY = 0 end
    scrollX, scrollY = math.floor(scrollX + 0.5), math.floor(scrollY + 0.5)
end

-- cards outside the view are hidden; a card at the edge takes clicks only on its visible part
local function Cull()
    for i = 1, used.cards do
        local b = cards[i]
        local n = b.node
        local x0, y0 = originX + n.x - scrollX, n.y - scrollY
        local x1, y1 = x0 + NODE_W, y0 + NODE_H
        if x1 <= 0 or y1 <= 0 or x0 >= viewW or y0 >= viewH then
            if b:IsShown() then
                if GameTooltip:IsOwned(b) then GameTooltip:Hide() end
                b:Hide()
            end
        else
            local l = x0 < 0 and -x0 or 0
            local r = x1 > viewW and (x1 - viewW) or 0
            local t = y0 < 0 and -y0 or 0
            local bt = y1 > viewH and (y1 - viewH) or 0
            b:SetHitRectInsets(l, r, t, bt)
            b:Show()
        end
    end
end

local function Apply()
    Clamp()
    canvas:ClearAllPoints()
    canvas:SetPoint("TOPLEFT", child, "TOPLEFT", originX - scrollX, scrollY)
    Cull()
end

function Graph.ScrollTo(x, y)
    scrollX, scrollY = x, y
    Apply()
end
function Graph.ScrollBy(dx, dy)
    scrollX, scrollY = scrollX + dx, scrollY + dy
    Apply()
end
function Graph.GetScroll() return scrollX, scrollY end
function Graph.ViewSize() return viewW, viewH end

-- the window was resized: the view (the middle panel) has a new size
function Graph.SetViewSize(w, h)
    w, h = math.max(1, math.floor(w)), math.max(1, math.floor(h))
    if w == viewW and h == viewH then return end
    viewW, viewH = w, h
    if child then
        child:SetWidth(viewW)
        child:SetHeight(viewH)
    end
    if graph then
        originX = graph.width < viewW and math.floor((viewW - graph.width) / 2) or 0
        Apply()
    end
end

local function CenterOn(id)
    local n = graph and graph.byId[id]
    if not n then return end
    scrollX = n.x + NODE_W / 2 - viewW / 2
    scrollY = n.y + NODE_H / 2 - (viewH - OverlayRoom()) / 2
    Apply()
end

-- left-drag on empty space pans (the cards keep their clicks)
local pan
function Graph.PanMouseDown(button)
    if button ~= "LeftButton" then return end
    local x, y = GetCursorPosition()
    pan = { x = x, y = y, sx = scrollX, sy = scrollY, active = false }
end
function Graph.StartPan()
    if not pan then Graph.PanMouseDown("LeftButton") end
    pan.active = true
    view:SetScript("OnUpdate", function()
        if not (pan and pan.active) then return end
        local x, y = GetCursorPosition()
        local scale = view:GetEffectiveScale()
        scrollX = pan.sx - (x - pan.x) / scale
        scrollY = pan.sy + (y - pan.y) / scale
        Apply()
    end)
end
function Graph.StopPan()
    pan = nil
    if view then view:SetScript("OnUpdate", nil) end
end

-- ---------------------------------------------------------------- summary and level warning
-- quests the player cannot (or no longer) do are left out of the totals; quests that exclude each
-- other (ex) count as one, done when one of them is done, and an open choice between them adds no
-- reputation (it isn't known which one the player will take)
local LEFT_OUT = ns.CANNOT
function Graph.Totals(g)
    local nodes, root = {}, {}
    for _, n in ipairs(g.nodes) do
        if not LEFT_OUT[n.status] then nodes[#nodes + 1] = n root[n.id] = n.id end
    end
    local function find(x)
        while root[x] ~= x do x = root[x] end
        return x
    end
    for _, n in ipairs(nodes) do
        for _, x in ipairs(ns.quests[n.id].ex or {}) do
            if root[x] then
                local a, b = find(n.id), find(x)
                if a ~= b then if a < b then root[b] = a else root[a] = b end end
            end
        end
    end
    local groups, order = {}, {}
    for _, n in ipairs(nodes) do
        local r = find(n.id)
        local grp = groups[r]
        if not grp then grp = { members = {} } groups[r] = grp order[#order + 1] = r end
        grp.members[#grp.members + 1] = n
        if n.status == "completed" then grp.done = n end
        if n.status == "active" and not grp.chosen then grp.chosen = n end
    end
    local done, total = 0, #order
    local rep, repOrder = {}, {}
    for _, r in ipairs(order) do
        local grp = groups[r]
        if grp.done then done = done + 1 end
        local take
        if #grp.members == 1 then take = grp.members[1] else take = grp.done or grp.chosen end
        local q = take and ns.quests[take.id]
        for _, x in ipairs(q and q.rep or {}) do
            local key = x[1]
            if not rep[key] then
                rep[key] = { name = x[3] or ("Faction " .. tostring(x[1])), amount = 0 }
                repOrder[#repOrder + 1] = key
            end
            rep[key].amount = rep[key].amount + x[2]
        end
    end
    return done, total, rep, repOrder
end

local summaryLines = {}
local function UpdateSummary()
    if not graph then summary:Hide() return end
    local done, total, rep, repOrder = Graph.Totals(graph)
    table.sort(repOrder, function(a, b)
        if rep[a].name ~= rep[b].name then return rep[a].name < rep[b].name end
        return a < b
    end)
    local texts = {
        { "Completed: " .. done .. " / " .. total, 1, 1, 1 },
        { "Steps: " .. graph.steps, 1, 1, 1 },
    }
    for _, key in ipairs(repOrder) do
        local r = rep[key]
        if r.amount ~= 0 then
            local sign = r.amount > 0 and "+" or ""
            local col = r.amount > 0 and { 0.4, 0.8, 0.4 } or { 1, 0.3, 0.3 }
            texts[#texts + 1] = { sign .. r.amount .. " " .. r.name, col[1], col[2], col[3] }
        end
    end
    for i, t in ipairs(texts) do
        local fs = summaryLines[i]
        if not fs then
            fs = summary:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("TOPLEFT", summary, "TOPLEFT", 8, -6 - (i - 1) * 12)
            fs:SetWidth(144)
            fs:SetHeight(12)
            fs:SetJustifyH("LEFT")
            summaryLines[i] = fs
        end
        fs:SetText(t[1])
        fs:SetTextColor(t[2], t[3], t[4])
        fs:Show()
    end
    for i = #texts + 1, #summaryLines do summaryLines[i]:Hide() end
    summary:SetHeight(12 + #texts * 12)
    summary:Show()
    Graph.summaryTexts = texts
end

local function UpdateLevelWarning()
    local q = selectedId and ns.quests[selectedId]
    local rl = q and q.rl
    local level = ns.PlayerLevel()
    if not rl or level > rl then levelCard:Hide() levelCard.state = nil return end
    if level < rl then
        levelCard:SetBackdropColor(0.15, 0.02, 0.02, 0.85)
        levelCard:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        levelCard.line1:SetText("Requires level " .. rl)
        levelCard.line1:SetTextColor(1, 0.3, 0.3)
        levelCard.line2:SetText("You are level " .. level)
        levelCard.line2:SetTextColor(1, 0.5, 0.5)
        levelCard.line2:Show()
        levelCard:SetHeight(40)
        levelCard.state = "below"
    else
        levelCard:SetBackdropColor(0.15, 0.13, 0.02, 0.85)
        levelCard:SetBackdropBorderColor(0.9, 0.75, 0.1, 1)
        levelCard.line1:SetText("Minimum level reached")
        levelCard.line1:SetTextColor(1, 0.85, 0.2)
        levelCard.line2:SetText("")
        levelCard.line2:Hide()
        levelCard:SetHeight(28)
        levelCard.state = "reached"
    end
    levelCard:Show()
end

-- ---------------------------------------------------------------- cards
local function PaintCard(b, n)
    local q = ns.quests[n.id]
    local icon, desat, alpha, bg, border = Graph.StatusLook(n.status, q.lv)
    b.icon:SetTexture(icon)
    Graph.SetDesaturated(b.icon, desat)
    b.icon:SetAlpha(alpha)
    b:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    if n.id == selectedId then
        b:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
        b.selected:Show()
    else
        b:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        b.selected:Hide()
    end
    b.name:SetText(q.n)
    b.name:SetTextColor(ns.QuestColor(n.id, n.status))
    b.zone:ClearAllPoints()
    local zoneIcon = q.zk and ns.ZONE_KIND_ICONS[q.zk]
    if zoneIcon then
        b.zoneIcon:SetTexture(zoneIcon)
        b.zoneIcon:Show()
        b.zone:SetPoint("TOPLEFT", b, "TOPLEFT", 6 + ICON + 5 + 14, -24)
        b.zone:SetWidth(NODE_W - (6 + ICON + 5 + 14) - 30)
    else
        b.zoneIcon:Hide()
        b.zone:SetPoint("TOPLEFT", b, "TOPLEFT", 6 + ICON + 5, -24)
        b.zone:SetWidth(NODE_W - (6 + ICON + 5) - 30)
    end
    b.zone:SetText(q.zn or "")
    b.req:SetText(q.rl and tostring(q.rl) or "")
    b.lvl:SetText(q.lv and tostring(q.lv) or "")
    b.lvl:SetTextColor(ns.DifficultyColor(q.lv))
end

-- ---------------------------------------------------------------- public
function Graph.Show(g, selected, keepScroll)
    graph = g
    selectedId = selected
    placeholder:Hide()
    ReleaseAll()
    canvas:SetWidth(math.max(1, g.width))
    canvas:SetHeight(math.max(1, g.height))
    originX = g.width < viewW and math.floor((viewW - g.width) / 2) or 0
    for _, r in ipairs(g.rects) do
        local t = Acquire(lines, "lines", function() return canvas:CreateTexture(nil, "ARTWORK") end)
        local c = Graph.ConnectorColor(r.part, r.kind, r.fromCompleted)
        t:SetTexture(c[1], c[2], c[3], c[4])
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", canvas, "TOPLEFT", r.x, -r.y)
        t:SetWidth(r.w)
        t:SetHeight(r.h)
        t.rect = r
        t:Show()
    end
    for _, a in ipairs(g.arrows) do
        local t = Acquire(arrows, "arrows", function()
            local tex = canvas:CreateTexture(nil, "OVERLAY")
            tex:SetTexture(ARROW_TEXTURE)
            tex:SetTexCoord(0.25, 0.75, 0.25, 0.75)
            return tex
        end)
        local c = Graph.ConnectorColor("arrow", a.kind, a.fromCompleted)
        t:SetVertexColor(c[1], c[2], c[3], c[4])
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", canvas, "TOPLEFT", a.x, -a.y)
        t:SetWidth(a.w)
        t:SetHeight(a.h)
        t.arrow = a
        t:Show()
    end
    for _, n in ipairs(g.nodes) do
        local b = Acquire(cards, "cards", NewCard)
        b.node = n
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", canvas, "TOPLEFT", n.x, -n.y)
        b:SetFrameLevel(canvas:GetFrameLevel() + 1)
        PaintCard(b, n)
        b:Show()
    end
    -- the overlay cards first: their height is room below the content (OverlayRoom)
    UpdateSummary()
    UpdateLevelWarning()
    if keepScroll then Apply() else CenterOn(selected) end
end

-- a different card is selected; the graph stays
function Graph.SetSelected(id)
    selectedId = id
    for i = 1, used.cards do
        local b = cards[i]
        PaintCard(b, b.node)
    end
    UpdateLevelWarning()
    Apply() -- the level card may have changed the room below the content
end

function Graph.ShowPlaceholder(text)
    graph, selectedId = nil, nil
    ReleaseAll()
    scrollX, scrollY = 0, 0
    canvas:SetWidth(1)
    canvas:SetHeight(1)
    Apply()
    placeholder:SetText(text)
    placeholder:Show()
    summary:Hide()
    levelCard:Hide()
end

function Graph.CardOf(id)
    for i = 1, used.cards do
        if cards[i].node and cards[i].node.id == id then return cards[i] end
    end
    return nil
end
function Graph.Cards()
    local t = {}
    for i = 1, used.cards do t[i] = cards[i] end
    return t
end
function Graph.Lines()
    local t = {}
    for i = 1, used.lines do t[i] = lines[i] end
    return t
end
function Graph.Arrows()
    local t = {}
    for i = 1, used.arrows do t[i] = arrows[i] end
    return t
end
function Graph.Current() return graph, selectedId end
function Graph.Frames() return view, child, canvas, placeholder, summary, levelCard end

function Graph.Create(parent)
    view = CreateFrame("ScrollFrame", nil, parent)
    view:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
    view:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -2, 2)
    viewW = ns.UI.MID_W - 4
    viewH = (ns.UI.panelHeight or 524) - 4
    child = CreateFrame("Frame", nil, view)
    child:SetWidth(viewW)
    child:SetHeight(viewH)
    view:SetScrollChild(child)
    canvas = CreateFrame("Frame", nil, child)
    canvas:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    canvas:SetWidth(1)
    canvas:SetHeight(1)

    view:EnableMouse(true)
    view:EnableMouseWheel(true)
    view:RegisterForDrag("LeftButton")
    view:SetScript("OnMouseWheel", function(_, delta)
        if not graph then return end
        if IsShiftKeyDown() then Graph.ScrollBy(-delta * WHEEL_STEP, 0) else Graph.ScrollBy(0, -delta * WHEEL_STEP) end
    end)
    view:SetScript("OnMouseDown", function(_, button) Graph.PanMouseDown(button) end)
    view:SetScript("OnDragStart", function() Graph.StartPan() end)
    view:SetScript("OnDragStop", function() Graph.StopPan() end)
    view:SetScript("OnMouseUp", function() if pan and not pan.active then pan = nil end end)
    view:SetScript("OnHide", function() Graph.StopPan() end)

    placeholder = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholder:SetPoint("CENTER", parent, "CENTER", 0, 0)
    placeholder:SetTextColor(0.6, 0.6, 0.6)
    placeholder:SetText("Select a quest to view its chain")

    summary = CreateFrame("Frame", nil, parent)
    summary:SetBackdrop(SMALL_BACKDROP)
    summary:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    summary:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    summary:SetWidth(160)
    summary:SetHeight(36)
    summary:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
    summary:SetFrameLevel(view:GetFrameLevel() + 20)
    summary:Hide()

    levelCard = CreateFrame("Frame", nil, parent)
    levelCard:SetBackdrop(SMALL_BACKDROP)
    levelCard:SetWidth(150)
    levelCard:SetHeight(40)
    levelCard:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 8)
    levelCard:SetFrameLevel(view:GetFrameLevel() + 20)
    levelCard.icon = levelCard:CreateTexture(nil, "OVERLAY")
    levelCard.icon:SetWidth(16)
    levelCard.icon:SetHeight(16)
    levelCard.icon:SetPoint("TOPLEFT", levelCard, "TOPLEFT", 6, -6)
    levelCard.icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    levelCard.line1 = levelCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelCard.line1:SetPoint("TOPLEFT", levelCard, "TOPLEFT", 26, -8)
    levelCard.line1:SetWidth(118)
    levelCard.line1:SetHeight(12)
    levelCard.line1:SetJustifyH("LEFT")
    levelCard.line2 = levelCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelCard.line2:SetPoint("TOPLEFT", levelCard.line1, "BOTTOMLEFT", 0, -2)
    levelCard.line2:SetWidth(118)
    levelCard.line2:SetHeight(12)
    levelCard.line2:SetJustifyH("LEFT")
    levelCard:Hide()
end
