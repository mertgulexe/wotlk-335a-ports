-- main frame of the addon

local _,t = ...
t.main =  CreateFrame("Frame","TinyPad",UIParent,BackdropTemplateMixin and "BackdropTemplate")

t.main:SetSize(400,400) -- setting basic position here to allow client to handle per-character positioning
t.main:SetPoint("CENTER")
t.main:SetMovable(true)
t.main:SetResizable(true)
t.main:Hide()

t.init:Register("main")

-- called on player_login
function t.main:LoginInit()
    -- broker button to toggle 
    local ldb = LibStub and LibStub.GetLibrary and LibStub:GetLibrary("LibDataBroker-1.1",true)
    if ldb then
        ldb:NewDataObject("TinyPad",{type="launcher", icon="Interface\\AddOns\\TinyPad\\media\\buttons", iconCoords={0.76171875,0.83203125,0.63671875,0.70703125}, tooltiptext="TinyPad", OnClick=TinyPad.Toggle }) 
    end    
end

-- called when ui is setup when first shown
function t.main:Init()

    -- finish defining main UI
    t.main:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",tileSize=16,tile=true,insets={left=4,right=4,top=4,bottom=4},edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    t.main:SetBackdropBorderColor(.5,.5,.5)
    t.main:SetClampedToScreen(true)
    t.main:SetToplevel(true)
    -- 3.3.5a: SetFlattensRenderLayers(true) removed (not in 3.3.5a; it only optimized drawing a faded window)
    t.main:SetHitRectInsets(-8,-8,-8,-8) -- make edges easier to grip for dragging
    t.main:EnableMouse(true) -- 3.3.5a: setting a mouse script does not enable the mouse; without this the window can't be dragged
    
    -- movement
    t.main:SetScript("OnMouseDown",function(self,button,...)
        if not t.settings.saved.Lock or IsShiftKeyDown() then
            self:StartMoving()
            t.main.isMoving = true
        end
    end)
    t.main:SetScript("OnMouseUp",function(self,button,...)
        if not t.settings.saved.Lock or t.main.isMoving then
            self:StopMovingOrSizing()
            self:SavePosition()
            t.main.isMoving = false
        end
    end)

    -- OnMouseOver doesn't respect HitRectInsets, so setting a flag when noticing mouse entering HitRectInset
    t.main:SetScript("OnEnter",function(self)
        self.isOver = true
    end)

    t.main:SetScript("OnLeave",function(self)
        self.isOver = false
    end)

    -- resizing
    t.main:SetMinResize(t.constants.MIN_WINDOW_WIDTH,t.constants.MIN_WINDOW_HEIGHT)
    t.main.resizeGrip = CreateFrame("Button",nil,t.main)
    t.main.resizeGrip:SetSize(t.constants.RESIZE_GRIP_SIZE,t.constants.RESIZE_GRIP_SIZE)
    t.main.resizeGrip:SetPoint("BOTTOMRIGHT",-2,2)
    t.main.resizeGrip:SetHitRectInsets(-2,-8,-2,-8)
    t.main.resizeGrip:SetFrameStrata("HIGH")
    t.buttons:SetTextures(t.main.resizeGrip,{texture="Interface\\AddOns\\TinyPad\\media\\buttons",coords={0,0.0625,0.25,0.3125}},
                                            {texture="Interface\\AddOns\\TinyPad\\media\\buttons",coords={0,0.0625,0.25,0.3125},blend="ADD"},
                                            {texture="Interface\\AddOns\\TinyPad\\media\\buttons",coords={0,0.0625,0.25,0.3125},blend="ADD"})

    -- MouseIsOver doesn't respect HitRectInsets, so using an OnEnter/OnLeave to capture larger HitRectInset
    t.main.resizeGrip:SetScript("OnEnter",function(self)
        self.isOver = true
    end)
    t.main.resizeGrip:SetScript("OnLeave",function(self)
        self.isOver = false
    end)

    t.main.resizeGrip:SetScript("OnMouseDown",function(self,button,...)
        if not t.settings.saved.Lock then
            self:GetParent():StartSizing()
            t.main.isSizing = true
        end
    end)
    t.main.resizeGrip:SetScript("OnMouseUp",function(self,button,...)
        if not t.settings.saved.Lock then
            self:GetParent():StopMovingOrSizing()
            self:GetParent():SavePosition()
            t.main.isSizing = false
        end
    end)

    -- when the window size changes, call every module with a Resize function
    t.main:SetScript("OnSizeChanged",function(self,width,height)
        t.init:ResizeAll()
    end)

    -- setup fadein/fadeout when mouse not over window
    t.main:SetChromeAlpha(0) -- 3.3.5a: was t.main:SetAlpha(0), see t.main:SetChromeAlpha()
    t.main.fadeTarget = 0
    t.main.isFadedOut = true
    t.main.fadeTimer = 0
    t.main:UpdateFadeBehavior()

    t.main:SetScript("OnShow",function(self)
        t.toolbar:UpdateKeys() -- 3.3.5a: ESC and Ctrl keys (see toolbar.lua)
        if t.settings.saved.SharePosition then
            if t.settings.saved.XPos and t.settings.saved.YPos then
                self:ClearAllPoints()
                self:SetPoint("BOTTOMLEFT",t.settings.saved.XPos,t.settings.saved.YPos)
            end
            if t.settings.saved.Width and t.settings.saved.Height then
                self:SetSize(t.settings.saved.Width,t.settings.saved.Height)
            end
        end
    end)

    t.main:SetScript("OnHide",function(self)
        -- 3.3.5a: also save here; the window can be hidden without TinyPad:Toggle() (UI hidden with Alt+Z, then
        -- logout), and t.pages:SavePage() only writes what the editor loaded and changed
        t.pages:SavePage()
        if not t.settings.saved.NoFade then
            t.main.isFadedOut = true
            t.main:SetChromeAlpha(0) -- 3.3.5a: was t.main:SetAlpha(0)
            t.main.fadeTarget = 0
        end
        t.toolbar:UpdateKeys() -- 3.3.5a: ESC and Ctrl keys (see toolbar.lua)
    end)

    -- 3.3.5a: the fadeout/fadein AnimationGroups are gone: 3.3.5a Alpha animations have no SetFromAlpha/SetToAlpha/
    -- SetTarget (only SetChange), and they could only fade all of t.main, the editor text included. t.main:OnUpdate()
    -- now moves the chrome alpha toward t.main.fadeTarget over FADE_INOUT_DURATION seconds.

    t.main:UpdateLock()
    t.main:UpdateScale()
    t.main:UpdateTransparency()

end

function t.main:UpdateLock()
    if t.settings.saved.Lock then
        t.main.resizeGrip:Hide()
    else
        t.main.resizeGrip:Show()
    end
    -- 3.3.5a: the border color (0.25 locked, 0.5 unlocked) is set with the chrome alpha
    t.main:SetChromeAlpha(t.main.chromeAlpha or 1)
    t.toolbar:UpdateKeys() -- 3.3.5a: ESC doesn't close a locked window
end

-- 3.3.5a: a child's alpha is always multiplied by its parent's (no SetIgnoreParentAlpha), so fading t.main would
-- fade the editor text too. Instead only the window "chrome" around the editor fades: the window's own background
-- and border, the toolbar and the resize grip. Panels (bookmarks, settings, search, confirm) keep the window faded in.
function t.main:SetChromeAlpha(alpha)
    t.main.chromeAlpha = alpha
    local border = t.settings.saved.Lock and 0.25 or 0.5
    t.main:SetBackdropColor(1,1,1,alpha)
    t.main:SetBackdropBorderColor(border,border,border,alpha)
    t.toolbar:SetAlpha(alpha)
    t.main.resizeGrip:SetAlpha(alpha)
end

function t.main:UpdateScale()
    t.main:SetScale(t.settings.saved.LargerScale and t.constants.LARGE_SCALE or t.constants.SMALL_SCALE)
end

function t.main:UpdateTransparency()
    local alpha = t.settings.saved.Transparency and (t.settings.saved.Invisible and 0 or 0.5) or 1
    -- 3.3.5a: was t.editor:SetAlpha(alpha) with the editbox ignoring its parent's alpha. Without SetIgnoreParentAlpha
    -- that would fade the text as well, so the editor's background, border, scrollbar and title get the alpha and
    -- the editbox (the text) stays opaque. (t.editor:Init() calls this again once those parts exist.)
    if not t.editor.scrollFrame then
        return
    end
    t.editor:SetBackdropColor(0.1,0.1,0.1,alpha)
    t.editor:SetBackdropBorderColor(0.5,0.5,0.5,alpha)
    t.editor.scrollFrame.scrollBar:SetAlpha(alpha)
    t.editor.gutterLeft:SetAlpha(alpha)
    t.editor.gutterRight:SetAlpha(alpha)
    t.editor.titleBackground:SetAlpha(alpha)
    t.editor.titleBorder:SetAlpha(alpha)
    t.editor.titleText:SetAlpha(alpha)
end

function t.main:UpdateFadeBehavior()
    if t.settings.saved.NoFade then
        t.main:SetChromeAlpha(1) -- 3.3.5a: was t.main:SetAlpha(1)
        t.main.fadeTarget = 1
        t.main.isFadedOut = false -- 3.3.5a: upstream typo isFadeOut fixed
        t.main:SetScript("OnUpdate",nil)
    else
        if MouseIsOver(t.main) then
            t.main.isFadedOut = false
        end
        t.main:SetScript("OnUpdate",t.main.OnUpdate)
    end
end

-- fading is set up in t.main:Init()
function t.main:OnUpdate(elapsed)
    t.main.fadeTimer = t.main.fadeTimer + elapsed
    if t.main.fadeTimer > t.constants.FADE_TICKER_DURATION then
        t.main.fadeTimer = 0 -- 3.3.5a: upstream typo fadetimer fixed (the check ran every frame and restarted the fade)
        -- if mouse is over the frame or resize grip, or a panel is open, or the main editbox has focus
        local isOver = MouseIsOver(t.main) or t.main.isOver or t.main.resizeGrip.isOver or t.layout.currentLayout~="default" or t.editor.editBox:HasFocus()
        if isOver and (t.main.isFadedOut or t.main.chromeAlpha<0.1) then -- alpha to double check that we didn't get out of sync
            t.main.isFadedOut = false
            t.main.fadeTarget = 1 -- 3.3.5a: was t.main.fadein:Play()
        elseif not isOver and (not t.main.isFadedOut or t.main.chromeAlpha>0.1) then
            t.main.isFadedOut = true
            t.main.fadeTarget = 0 -- 3.3.5a: was t.main.fadeout:Play()
        end
    end
    -- 3.3.5a: the fade itself, a linear change of the chrome alpha over FADE_INOUT_DURATION seconds
    local alpha = t.main.chromeAlpha
    if alpha~=t.main.fadeTarget then
        local change = elapsed/t.constants.FADE_INOUT_DURATION
        if t.main.fadeTarget>alpha then
            alpha = min(t.main.fadeTarget,alpha+change)
        else
            alpha = max(t.main.fadeTarget,alpha-change)
        end
        t.main:SetChromeAlpha(alpha)
    end
end

-- saves the position of the window
function t.main:SavePosition()
    t.settings.saved.XPos = self:GetLeft()
    t.settings.saved.YPos = self:GetBottom()
    t.settings.saved.Width = self:GetWidth()
    t.settings.saved.Height = self:GetHeight()
end
