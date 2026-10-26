-- UI/MainFrame.lua: the window with its three panels, and the selection logic shared by them.
local _, ns = ...

local UI = {}
ns.UI = UI

local FRAME_W, FRAME_H = 1020, 560
local TITLE_H = 24
local PAD = 8
local LEFT_W, MID_W = 230, 470
local TOP = TITLE_H + 8 -- panels start below the title bar

UI.FRAME_W, UI.FRAME_H, UI.LEFT_W, UI.MID_W = FRAME_W, FRAME_H, LEFT_W, MID_W

local WINDOW_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local frame

-- ---------------------------------------------------------------- position
function UI.SavePosition()
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint(1)
    if point and relPoint and x and y then
        ns.db.pos = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

function UI.RestorePosition()
    if not frame then return end
    frame:ClearAllPoints()
    local p = ns.db.pos
    if p then
        frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- ---------------------------------------------------------------- size
-- The window grows to the right and down: the left and middle panels keep their widths, the right
-- panel (the details) takes the extra width, and every panel takes the extra height.
local function PanelHeight() return math.floor((frame:GetHeight() or FRAME_H) - TOP - PAD + 0.5) end
local function RightWidth()
    return math.floor((frame:GetWidth() or FRAME_W) - PAD - LEFT_W - PAD - MID_W - PAD - PAD + 0.5)
end
UI.RightWidth = RightWidth

-- lay the panels out for the window's size; full: also lay the details text out again (on
-- release of the size grip, not on every frame of the drag)
function UI.Layout(full)
    if not frame or UI.laying then return end
    UI.laying = true
    local ph = PanelHeight()
    UI.panelHeight = ph
    ns.List.SetHeight(ph)
    ns.Graph.SetViewSize(MID_W - 4, ph - 4)
    ns.Details.SetSize(RightWidth(), ph, full)
    UI.laying = false
end

function UI.SaveSize()
    if not frame then return end
    local w, h = math.floor(frame:GetWidth() + 0.5), math.floor(frame:GetHeight() + 0.5)
    if w <= FRAME_W and h <= FRAME_H then ns.db.size = nil else ns.db.size = { w = w, h = h } end
end

function UI.RestoreSize()
    if not frame then return end
    local s = ns.db.size
    frame:SetWidth(s and s.w or FRAME_W)
    frame:SetHeight(s and s.h or FRAME_H)
    UI.Layout(true)
end

-- ---------------------------------------------------------------- window
function UI.Create()
    if frame then return frame end
    frame = CreateFrame("Frame", "QuestsInChainsFrame", UIParent)
    UI.frame = frame
    frame:SetWidth(FRAME_W)
    frame:SetHeight(FRAME_H)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetBackdrop(WINDOW_BACKDROP)
    frame:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
    frame:SetResizable(true)
    frame:SetMinResize(FRAME_W, FRAME_H)
    frame:Hide()
    tinsert(UISpecialFrames, "QuestsInChainsFrame")

    -- title bar: drag to move
    local bar = CreateFrame("Frame", nil, frame)
    UI.titleBar = bar
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    bar:SetHeight(TITLE_H)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() frame:StartMoving() end)
    bar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        -- our own saved position is the only one: keep the client's layout cache out of it
        frame:SetUserPlaced(false)
        UI.SavePosition()
    end)
    local strip = bar:CreateTexture(nil, "BACKGROUND")
    strip:SetAllPoints(bar)
    strip:SetTexture(0.2, 0.2, 0.2, 0.6)
    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", bar, "LEFT", 8, 0)
    title:SetText(ns.TITLE)
    UI.titleText = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    UI.closeButton = close
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    close:SetFrameLevel(bar:GetFrameLevel() + 2)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- panels
    local left = CreateFrame("Frame", nil, frame)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -TOP)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
    left:SetWidth(LEFT_W)
    local mid = CreateFrame("Frame", nil, frame)
    mid:SetPoint("TOPLEFT", left, "TOPRIGHT", PAD, 0)
    mid:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", PAD, 0)
    mid:SetWidth(MID_W)
    local right = CreateFrame("Frame", nil, frame)
    right:SetPoint("TOPLEFT", mid, "TOPRIGHT", PAD, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    for _, p in ipairs({ mid, right }) do
        local bg = p:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(p)
        bg:SetTexture(0.1, 0.1, 0.1, 0.3)
    end
    UI.left, UI.mid, UI.right = left, mid, right
    UI.panelHeight = FRAME_H - TOP - PAD

    ns.List.Create(left)
    ns.Graph.Create(mid)
    ns.Details.Create(right)

    -- the size grip (bottom right): drag it to make the details panel wider and every panel taller
    local grip = CreateFrame("Button", nil, frame)
    UI.sizeGrip = grip
    grip:SetWidth(16)
    grip:SetHeight(16)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    grip:SetFrameLevel(frame:GetFrameLevel() + 10)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        -- at most the screen
        frame:SetMaxResize(math.max(FRAME_W, math.floor(UIParent:GetWidth())), math.max(FRAME_H, math.floor(UIParent:GetHeight())))
        -- keep the top left corner where it is: anchor it there before the sizing starts
        local l, t = frame:GetLeft(), frame:GetTop()
        if l and t then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
        end
        UI.sizing = true
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        if not UI.sizing then return end
        UI.sizing = false
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(false)
        UI.SavePosition()
        UI.SaveSize()
        UI.Layout(true)
    end)
    grip:SetScript("OnHide", function()
        if UI.sizing then
            UI.sizing = false
            frame:StopMovingOrSizing()
            frame:SetUserPlaced(false)
            UI.SavePosition()
            UI.SaveSize()
            UI.Layout(true)
        end
    end)
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Resize")
        GameTooltip:AddLine("Drag to make the details panel wider and the window taller. /qic reset restores the size.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- while the grip is dragged: the list, the graph and the details' height follow at once
    frame:SetScript("OnSizeChanged", function() UI.Layout(not UI.sizing) end)

    frame:SetScript("OnShow", UI.OnShow)
    frame:SetScript("OnHide", UI.OnHide)
    UI.RestorePosition()
    UI.RestoreSize()
    UI.dirty = true
    return frame
end

function UI.IsShown()
    return frame ~= nil and frame:IsShown()
end

function UI.Show()
    UI.Create()
    if not frame:IsShown() then frame:Show() end
end

function UI.Toggle()
    UI.Create()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function UI.OnShow()
    ns.QueryIfNeeded()
    if UI.dirty then UI.Refresh(true) end
end

function UI.OnHide()
    ns.List.CloseMenu()
    ns.Graph.StopPan()
    GameTooltip:Hide()
end

-- ---------------------------------------------------------------- selection
-- the instance shown in the list (nil: none); remembered as the last used one
function UI.SetInstance(index)
    ns.state.instance = index
    if index and ns.instances[index] then ns.db.lastInstance = ns.instances[index].aq end
    ns.List.Refresh(true)
end

function UI.SetFaction(f)
    if f ~= "A" and f ~= "H" then return end
    if ns.state.faction == f then return end
    ns.state.faction = f
    ns.List.ClearCache()
    ns.List.Refresh(true)
    if ns.state.root then UI.ShowChain(ns.state.root, ns.state.selected) end
end

function UI.SetMyClassOnly(v)
    ns.db.myClassOnly = v and true or false
    ns.List.ClearCache()
    ns.List.Refresh()
    if ns.state.root then UI.ShowChain(ns.state.root, ns.state.selected) end
end

function UI.SetHideCompleted(v)
    ns.db.hideCompleted = v and true or false
    ns.List.Refresh(true)
end

function UI.SetSort(v)
    if v ~= "aq" and v ~= "name" and v ~= "level" then return end
    ns.db.sort = v
    ns.List.Refresh(true)
    ns.List.ScrollToRow(ns.state.row)
end

-- a click on an instance in the search results: the search ends and the instance's quests show
function UI.OpenInstance(index)
    if not (index and ns.instances[index]) then return end
    ns.state.search = ""
    UI.SetInstance(index)
end

-- build and show the graph of `root`, with `selected` (default: root) selected
function UI.ShowChain(root, selected, keepScroll)
    local g = ns.quests[root] and ns.Chain.Build(root, ns.ChainOpts()) or nil
    ns.state.graph = g
    if not g then
        ns.state.root, ns.state.selected = nil, nil
        ns.Graph.ShowPlaceholder("No chain data for this quest")
        ns.Details.Clear()
        return
    end
    ns.state.root = root
    if not (selected and g.byId[selected]) then selected = root end
    ns.state.selected = selected
    ns.Graph.Show(g, selected, keepScroll)
    ns.Details.Show(selected)
end

-- a click on a list row
function UI.SelectRow(row)
    ns.state.row = row
    if row and row.id and ns.quests[row.id] then
        UI.ShowChain(row.id, row.id)
    elseif row then
        ns.state.root, ns.state.selected, ns.state.graph = nil, nil, nil
        ns.Graph.ShowPlaceholder("No chain data for this quest")
        ns.Details.ShowSlot(row)
    else
        ns.state.root, ns.state.selected, ns.state.graph = nil, nil, nil
        ns.Graph.ShowPlaceholder("Select a quest to view its chain")
        ns.Details.Clear()
    end
    ns.List.Refresh()
end

-- a click on a card, or on a quest in the details: select it; the graph is rebuilt only for a
-- quest that is not in it
function UI.SelectQuest(id)
    if not ns.quests[id] then return end
    -- the list selection follows when the quest is in the current list (set first: the details
    -- take the AtlasQuest slot from it)
    ns.state.row = ns.List.FindRow(id)
    local g = ns.state.graph
    if g and g.byId[id] then
        ns.state.selected = id
        ns.Graph.SetSelected(id)
        ns.Details.Show(id)
    else
        UI.ShowChain(id, id)
    end
    ns.List.Refresh()
    ns.List.ScrollToRow(ns.state.row)
end

-- open the window on a quest: from AtlasQuest (ctx = { aq=, slot=, faction= }), the quest log,
-- or /qic <id>
function UI.OpenQuest(id, ctx)
    ctx = ctx or {}
    UI.Create()
    local q = ns.quests[id]
    if not q then return end
    -- the faction: the caller's (AtlasQuest's side), else the quest's own, else the player's (the
    -- quest log and /qic show the player's own quests; a faction picked for browsing earlier must
    -- not decide which parents count)
    if ctx.faction == "A" or ctx.faction == "H" then
        ns.state.faction = ctx.faction
    elseif q.fa then
        ns.state.faction = q.fa
    elseif ns.playerFaction then
        ns.state.faction = ns.playerFaction
    end
    ns.state.search = ""
    local inst
    if ctx.aq then inst = ns.InstanceByAQ(ctx.aq) end
    if not inst then inst = ns.FirstInstanceOf(id, ns.state.faction) end
    ns.state.instance = inst
    if inst then ns.db.lastInstance = ns.instances[inst].aq end
    ns.List.ClearCache()
    ns.List.SyncControls()
    local wasShown = frame:IsShown()
    if not wasShown then
        UI.dirty = false
        frame:Show()
    end
    ns.state.row = ns.List.FindRow(id, ctx.slot)
    UI.ShowChain(id, id)
    ns.List.Refresh(true)
    ns.List.ScrollToRow(ns.state.row)
end

-- everything again: after a status change, a level up, a reset or the first show
function UI.Refresh(keepScroll)
    if not frame then return end
    UI.dirty = false
    ns.List.SyncControls()
    ns.List.Refresh()
    local st = ns.state
    if st.root and ns.quests[st.root] then
        UI.ShowChain(st.root, st.selected, keepScroll)
    elseif st.row then
        ns.Graph.ShowPlaceholder("No chain data for this quest")
        ns.Details.ShowSlot(st.row)
    else
        ns.Graph.ShowPlaceholder("Select a quest to view its chain")
        ns.Details.Clear()
    end
end

local function Changed()
    if not frame then return end
    ns.List.ClearCache()
    if frame:IsShown() then UI.Refresh(true) else UI.dirty = true end
end
ns.On("STATUS", Changed)
ns.On("LEVEL", Changed)
ns.On("RESET", function()
    if not frame then return end
    UI.RestorePosition()
    UI.RestoreSize()
    ns.state.search = ""
    Changed()
end)
