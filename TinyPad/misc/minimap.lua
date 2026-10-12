local _,t = ...
t.minimap = CreateFrame("Button","TinyPadMinimapButton",Minimap)

t.init:Register("minimap")

function t.minimap:LoginInit()
    t.minimap:SetSize(31,31)
    t.minimap:SetToplevel(true)
    t.minimap:SetFrameLevel(t.minimap:GetFrameLevel()+3)
    t.minimap:RegisterForClicks("AnyUp")
    t.minimap:RegisterForDrag("LeftButton")
    t.minimap.tooltipTitle = "TinyPad"
    t.minimap.tooltipBody = "Version "..GetAddOnMetadata("TinyPad","Version")
    t.minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    t.minimap.icon = t.minimap:CreateTexture(nil,"BACKGROUND")
    t.minimap.icon:SetTexture("Interface\\AddOns\\TinyPad\\media\\buttons")
    t.minimap.icon:SetTexCoord(0.75,0.84375,0.625,0.71875)
    t.minimap.icon:SetSize(23,23)
    t.minimap.icon:SetPoint("CENTER")
    t.minimap.border = t.minimap:CreateTexture(nil,"BORDER")
    t.minimap.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    t.minimap.border:SetSize(53,53)
    t.minimap.border:SetPoint("TOPLEFT")
    
    t.minimap:SetScript("OnMouseUp",t.minimap.OnMouseUp)
    t.minimap:SetScript("OnMouseDown",t.minimap.OnMouseDown)
    t.minimap:SetScript("OnShow",t.minimap.OnMouseUp)
    t.minimap:SetScript("OnClick",TinyPad.Toggle)
    t.minimap:SetScript("OnEnter",t.buttons.OnEnter)
    t.minimap:SetScript("OnLeave",t.buttons.OnLeave)
    t.minimap:SetScript("OnDragStart",t.minimap.OnDragStart)
    t.minimap:SetScript("OnDragStop",t.minimap.OnDragStop)

    t.minimap:UpdatePosition()

    t.minimap:SetShown(t.settings.saved.ShowMinimapButton)

end

function t.minimap:OnMouseDown()
    t.minimap.icon:SetPoint("CENTER",-1,-2)
    t.minimap.icon:SetVertexColor(0.65,0.65,0.65)
end

function t.minimap:OnMouseUp()
    t.minimap.icon:SetPoint("CENTER",0,0)
    t.minimap.icon:SetVertexColor(1,1,1)
end

function t.minimap:OnDragStart()
	self:SetScript("OnUpdate",t.minimap.OnDragUpdate)
end

function t.minimap:OnDragStop()
    t.minimap:OnMouseUp()
	self:SetScript("OnUpdate",nil)
end

function t.minimap:OnDragUpdate(elapsed)
	local x,y = GetCursorPosition()
	local minX,minY = Minimap:GetLeft(), Minimap:GetBottom()
	local scale = Minimap:GetEffectiveScale()
    t.settings.saved.MinimapPosition = math.deg(math.atan2(y/scale-minY-70,minX-x/scale+70))
    t.minimap:UpdatePosition()
end

function t.minimap:UpdatePosition()
	local angle = t.settings.saved.MinimapPosition or t.constants.DEFAULT_MINIMAP_POSITION
	t.minimap:SetPoint("TOPLEFT",Minimap,"TOPLEFT",52-(80*cos(angle)),(80*sin(angle))-52)
end
