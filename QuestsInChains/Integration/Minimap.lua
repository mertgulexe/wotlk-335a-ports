-- Integration/Minimap.lua: the minimap button. Drag it around the minimap; left-click toggles
-- the window. /qic minimap hides or shows it.
local _, ns = ...

local MM = {}
ns.MinimapButton = MM

local RADIUS = 80

local button = CreateFrame("Button", "QuestsInChainsMinimapButton", Minimap)
MM.button = button
button:SetWidth(31)
button:SetHeight(31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local overlay = button:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
local background = button:CreateTexture(nil, "BACKGROUND")
background:SetWidth(20)
background:SetHeight(20)
background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
background:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetWidth(17)
icon:SetHeight(17)
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -6)
MM.icon = icon

function MM.SetAngle(angle)
    angle = (tonumber(angle) or 200) % 360
    local r = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.floor(math.cos(r) * RADIUS + 0.5), math.floor(math.sin(r) * RADIUS + 0.5))
    MM.angle = angle
end

function MM.Update()
    MM.SetAngle(ns.db.minimap.angle)
    if ns.db.minimap.hide then button:Hide() else button:Show() end
end

-- the angle of the cursor around the minimap's centre, in degrees
local function CursorAngle()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not (mx and my and scale and scale > 0) then return nil end
    px, py = px / scale, py / scale
    return math.deg(math.atan2(py - my, px - mx)) % 360
end

-- dragging only moves the button while it sits on the minimap: a minimap button bag (MBB) that
-- collected it anchors it elsewhere, and a drag there must not change the saved angle
button:SetScript("OnDragStart", function(self)
    local _, relativeTo = self:GetPoint(1)
    if relativeTo ~= Minimap then return end
    self.dragging = true
    self:LockHighlight()
    GameTooltip:Hide()
    self:SetScript("OnUpdate", function()
        local a = CursorAngle()
        if a then MM.SetAngle(a) end
    end)
end)
button:SetScript("OnDragStop", function(self)
    if not self.dragging then return end
    self.dragging = nil
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
    local a = CursorAngle()
    if a then MM.SetAngle(a) end
    ns.db.minimap.angle = MM.angle
end)
button:SetScript("OnClick", function(self, mouse)
    if mouse == "LeftButton" then ns.Toggle() end
end)
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(ns.TITLE)
    GameTooltip:AddLine("Left-click: show or hide the window", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: move this button", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("/qic minimap hides it", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

MM.SetAngle(200)
ns.On("DB", MM.Update)
ns.On("MINIMAP", MM.Update)
