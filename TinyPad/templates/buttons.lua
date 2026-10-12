local _,t = ...
t.buttons = {}

-- order of textures to pass to t.buttons:SetTextures()
t.buttons.textureMethods = {"NormalTexture","PushedTexture","HighlightTexture","DisabledTexture"}

-- Create a standard button for use in the various bars with these arguments:
-- [1] = parent
-- [2]-[3] = width,height
-- [4]-[5] = normal texture x,y (see buttons.blp as an 8x8 table with 0,0 origin; 2,3 would be the texture in third collumn and fourth row)
-- [6] = function to run when clicked
-- [7]-[8] = tooltip title, body
-- [9]+ = SetPoint arguments (anchorPoint[, relativeTo, relativePoint, xoff, yoff])
-- Note: in buttons.blp it's assumed the pushed texcoords are always immediately to the right of the normal texcoords and the
-- highlight texture is the standard square border; call t.buttons:SetTextures for more control if this doesn't apply to the button
function t.buttons:Create(parent,width,height,normalX,normalY,func,anchor,tooltipTitle,tooltipBody)

    local isPanelButton = type(normalX)=="string"
    local button = CreateFrame("Button",nil,parent,isPanelButton and "TinyPadPanelButtonTemplate")
    button:SetSize(width,height)
    button:RegisterForClicks("AnyUp")

    if isPanelButton then -- for panel buttons without an icon, only setting text
        button.text:SetText(normalX)
    else
        t.buttons:SetTexturesByNormalCoords(button,normalX,normalY)
    end
    
    if type(anchor)=="table" then
        button:SetPoint(anchor.anchorPoint,anchor.relativeTo,anchor.relativePoint,anchor.xoff,anchor.yoff)
    end
    button:SetScript("OnClick",func)
    button.tooltipTitle = tooltipTitle
    button.tooltipBody = tooltipBody
    button:SetScript("OnEnter",t.buttons.OnEnter)
    button:SetScript("OnLeave",t.buttons.OnLeave)

    if not isPanelButton then -- panel buttons have their own OnMouseDown/Up defined in templates.xml
        button:SetScript("OnMouseDown",t.buttons.OnMouseDown)
        button:SetScript("OnMouseUp",t.buttons.OnMouseUp)
    end

    -- save created button in parent's allButtons table
    if not parent.allButtons then
        parent.allButtons = {}
    end
    tinsert(parent.allButtons,button)
    
    return button
end

-- sets the Normal, Pushed, Highlight, Disabled textures of a button where each texture is a table defined like:
-- {texture="Texture\\Path", coords={0,1,0,1}, blend="ADD"}
function t.buttons:SetTextures(button,...)
    for i=1,select("#",...) do
        local buttonTexture = select(i,...)
        if type(buttonTexture)=="table" and t.buttons.textureMethods[i] then
            button["Set"..t.buttons.textureMethods[i]](button,buttonTexture.texture)
            if buttonTexture.coords then
                button["Get"..t.buttons.textureMethods[i]](button):SetTexCoord(unpack(buttonTexture.coords))
            end
            if buttonTexture.blend then
                button["Get"..t.buttons.textureMethods[i]](button):SetBlendMode(buttonTexture.blend)
            end
        end
    end
end

-- applies a normal and pushed texture to a button based on the x,y coordinates of the normal texture, where 0,0 is the topleft
-- normal texture in media\buttons.tga, and 6,7 is the bottomright normal texture. (the pushed texture is assumed to be
-- immediately to the right; 0,1 for topleft and 7,7 for bottomright)
function t.buttons:SetTexturesByNormalCoords(button,normalX,normalY)
    t.buttons:SetTextures(button,
        {texture="Interface\\AddOns\\TinyPad\\media\\buttons",coords={(normalX*64)/512,(normalX*64+48)/512,(normalY*64)/512,(normalY*64+48)/512}},
        {texture="Interface\\AddOns\\TinyPad\\media\\buttons",coords={((normalX+1)*64)/512,((normalX+1)*64+48)/512,(normalY*64)/512,(normalY*64+48)/512}},
        {texture="Interface\\AddOns\\TinyPad\\media\\buttons",coords={0.125,0.21875,0.25,0.34375},blend="ADD"}
    )   
end

-- set a button's enabled status to true or false
function t.buttons:SetEnabled(button,enabled)
    -- if it's being disabled (and currently enabled) then set its state to normal so it's not disabled while down
    -- (these buttons don't have a DisabledTexture, where this step wouldn't be necessary)
    if not enabled and button:IsEnabled() then
        button:SetButtonState("NORMAL")
    end
    -- recolor the NormalTexture to a dim grey if disabled
    button:GetNormalTexture():SetDesaturated(not enabled)
    if enabled then
        button:GetNormalTexture():SetVertexColor(1,1,1)
    else
        button:GetNormalTexture():SetVertexColor(0.65,0.65,0.65)
    end
    -- and set its enabled state to prevent interaction with the button
    button:SetEnabled(enabled)
end

--[[ tooltips ]]

function t.buttons:OnEnter()
    if self.tooltipTitle and not t.settings.saved.HideTooltips then
        GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
        GameTooltip:AddLine(self.tooltipTitle)
        if self.tooltipBody then
            GameTooltip:AddLine(self.tooltipBody,0.95,0.95,0.95,true)
        end
        GameTooltip:Show()
    end
end

function t.buttons:OnLeave()
    GameTooltip:Hide()
end

-- when clicking elsewhere loses editbox focus, the editbox may want to keep focus if a button is being pressed;
-- this flag alerts lets the editbox choose to keep focus if a button is being clicked
function t.buttons:OnMouseDown()
    if self:IsEnabled() then
        t.buttons.isButtonBeingClicked = true
    end
end

function t.buttons:OnMouseUp()
    t.buttons.isButtonBeingClicked = false
end

