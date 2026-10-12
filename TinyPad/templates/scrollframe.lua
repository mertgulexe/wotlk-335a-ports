-- for best results, make the contents of the scrollchild anchor left/right to the scrollchild, since its width
-- will change depending on scrollbar visibility

local _,t = ...
t.scrollFrame = {}

-- this creates a scrollframe with a scrollbar that hides/shows when it's needed, and adjust the scrollchild to the scrollbar visibility.
-- if premadeScrollChild is passed, that will be used as a scrollchild (and size adjusted for scrollbar visibility)
function t.scrollFrame:Create(parent,premadeScrollChild)

    local scrollFrame = CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    scrollFrame.scrollBar = scrollFrame.ScrollBar -- for naming consistentcy

    -- moving the scrollbar inherited from UIPanelScrollFrameTemplate into the inside of the scrollFrame
    scrollFrame.scrollBar:ClearAllPoints()
    scrollFrame.scrollBar:SetPoint("TOPRIGHT",0,-17)
    scrollFrame.scrollBar:SetPoint("BOTTOMRIGHT",0,16)
    scrollFrame.scrollBar:Hide()

    -- veritcla border to the left of the scrollbar
    scrollFrame.scrollBar.leftBorder = scrollFrame.scrollBar:CreateTexture(nil,"OVERLAY")
    scrollFrame.scrollBar.leftBorder:SetSize(8,32)
    scrollFrame.scrollBar.leftBorder:SetPoint("TOPLEFT",-8,19)
    scrollFrame.scrollBar.leftBorder:SetPoint("BOTTOMLEFT",-8,-18)
    scrollFrame.scrollBar.leftBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    scrollFrame.scrollBar.leftBorder:SetTexCoord(0.4453125,0.5,0,1)
    scrollFrame.scrollBar.leftBorder:SetVertexColor(0.5,0.5,0.5)

    -- background of the scrollbar, that should be the same framelevel as the parent frame so it draws beneath the rounded border
    scrollFrame.scrollBar.gutter = CreateFrame("Frame",nil,scrollFrame.scrollBar)
    scrollFrame.scrollBar.gutter:SetFrameLevel(parent:GetFrameLevel())
    scrollFrame.scrollBar.gutter:SetAllPoints(true)
    -- left gradient texture that meets right in center of gutter
    scrollFrame.scrollBar.gutter.left = scrollFrame.scrollBar.gutter:CreateTexture(nil,"BACKGROUND",nil,2)
    scrollFrame.scrollBar.gutter.left:SetPoint("TOPLEFT",-4,19)
    scrollFrame.scrollBar.gutter.left:SetPoint("BOTTOMRIGHT",scrollFrame.scrollBar.gutter,"BOTTOM",0,-19)
    scrollFrame.scrollBar.gutter.left:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    scrollFrame.scrollBar.gutter.left:SetGradient("horizontal",0.07,0.07,0.07,0.1,0.1,0.1)
    -- right gradient texture that meets left in center of gutter
    scrollFrame.scrollBar.gutter.right = scrollFrame.scrollBar.gutter:CreateTexture(nil,"BACKGROUND",nil,2)
    scrollFrame.scrollBar.gutter.right:SetPoint("TOPLEFT",scrollFrame.scrollBar.gutter,"TOP",0,19)
    scrollFrame.scrollBar.gutter.right:SetPoint("BOTTOMRIGHT",2,-19)
    scrollFrame.scrollBar.gutter.right:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    scrollFrame.scrollBar.gutter.right:SetGradient("horizontal",0.1,0.1,0.1,0.07,0.07,0.07)

    -- if an existing scrollchild already made, use that
    if premadeScrollChild then
        scrollFrame.scrollChild = premadeScrollChild
        premadeScrollChild:SetParent(scrollFrame)
    else -- otherwise create a new one
        scrollFrame.scrollChild = CreateFrame("Frame",nil,scrollFrame)
    end

    scrollFrame:SetScrollChild(scrollFrame.scrollChild)

    -- resizing the scrollframe should make the scrollbar show/hide depending if there's enough content to scroll,
    -- and the scrollchild should expand to fill the space (so it uses up space scrollbar would take up if shown)
    
    -- this resizeUpdate frame does a "one-off" (actually "two-off") update so the scrollbar visibility can be
    -- adjusted after the client has set hit rects
    scrollFrame.resizeUpdate = CreateFrame("Frame",nil,scrollFrame)
    scrollFrame.resizeUpdate:Hide()
    scrollFrame.resizeUpdate:SetScript("OnUpdate",t.scrollFrame.ResizeOnUpdate)

    -- when there's a size change to the scrollframe it will start the above resizeUpdate's OnUpdate for a couple frames
    scrollFrame:SetScript("OnSizeChanged",t.scrollFrame.OnSizeChanged)

    t.scrollFrame:UpdateScrollBarVisibility(scrollFrame) -- trigger an initial update

    return scrollFrame
end

-- when the scrollframe changes, we want to adjust scrollbar visibility and scrollchild's width
function t.scrollFrame:OnSizeChanged(width,height)
    self.resizeUpdate.count = 2
    self.resizeUpdate:Show()
end

-- this runs for two frames to get hit rect changes and then shuts down
function t.scrollFrame:ResizeOnUpdate(elapsed)
    self.count = self.count - 1
    if self.count<0 then
        self:Hide()
    else
        local scrollFrame = self:GetParent()
        local minRange,maxRange = scrollFrame.scrollBar:GetMinMaxValues()
        local shouldBeShown = not (minRange==0 and maxRange==0)
        if not shouldBeShown then
            scrollFrame.scrollBar:Hide()
            scrollFrame.scrollChild:SetWidth(scrollFrame:GetWidth())
        elseif shouldBeShown then
            scrollFrame.scrollBar:Show()
            scrollFrame.scrollChild:SetWidth(scrollFrame:GetWidth()-22)
        end
        scrollFrame.scrollChild:SetHeight(scrollFrame:GetHeight())
    end
end

-- call this to update the scrollbar's visibility outside of frame size changes (changing content within the scrollframe)
function t.scrollFrame:UpdateScrollBarVisibility(scrollFrame)
    t.scrollFrame.OnSizeChanged(scrollFrame,scrollFrame:GetWidth(),scrollFrame:GetHeight())
end