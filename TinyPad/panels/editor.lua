local _,t = ...
t.editor = CreateFrame("Frame",nil,t.main,BackdropTemplateMixin and "BackdropTemplate")

t.init:Register("editor")

t.editor.undoStack = {} -- undo/redo ordered list: "<cursorpos>~text"
t.editor.undoIndex = 1 -- pointer of current undo/redo step

function t.editor:Init()
    t.editor:SetPoint("TOPLEFT",t.toolbar,"BOTTOMLEFT",-2,0)
    t.editor:SetPoint("BOTTOMRIGHT",-4,4)

    t.editor:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tileSize=16,tile=true,insets={left=4,right=4,top=4,bottom=4},edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    t.editor:SetBackdropBorderColor(0.5,0.5,0.5)
    t.editor:SetBackdropColor(0.1,0.1,0.1)

    t.editor:SetIgnoreParentAlpha(true) -- allows editor to remain on screen when parent frame's alpha fades to 0

    t.editor.scrollFrame = CreateFrame("ScrollFrame",nil,t.editor,"UIPanelScrollFrameTemplate")
    t.editor.scrollFrame:SetPoint("TOPLEFT",6,-6)
    t.editor.scrollFrame:SetPoint("BOTTOMRIGHT",-6,6) -- -28,6 for space for original scrollbar
    t.editor.scrollBarHideable = true
    t.editor.scrollFrame.scrollBar = t.editor.scrollFrame.ScrollBar -- pedantic, I know! ScrollBar is inherited from UIPanelScrollFrameTemplate

    -- moving scrollbar inherited from UIPanelScrollFrameTemplate into the inside of the scrollframe rather than anchored outside
    t.editor.scrollFrame.scrollBar:ClearAllPoints()
    t.editor.scrollFrame.scrollBar:SetPoint("TOPRIGHT",t.editor,"TOPRIGHT",-6,-24)
    t.editor.scrollFrame.scrollBar:SetPoint("BOTTOMRIGHT",t.editor,"BOTTOMRIGHT",-6,22)

    -- vertical border to left of the scrollbar
    t.editor.scrollFrame.scrollBar.leftBorder = t.editor.scrollFrame.scrollBar:CreateTexture(nil,"OVERLAY")
    t.editor.scrollFrame.scrollBar.leftBorder:SetSize(8,32)
    t.editor.scrollFrame.scrollBar.leftBorder:SetPoint("TOPLEFT",t.editor,"TOPRIGHT",-30,-4)
    t.editor.scrollFrame.scrollBar.leftBorder:SetPoint("BOTTOMLEFT",t.editor,"BOTTOMRIGHT",-30,4)
    t.editor.scrollFrame.scrollBar.leftBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    t.editor.scrollFrame.scrollBar.leftBorder:SetTexCoord(0.4453125,0.5,0,1)
    t.editor.scrollFrame.scrollBar.leftBorder:SetVertexColor(0.5,0.5,0.5)

    -- this is the background of the scrollbar, that's created off the parent frame so it can draw beneath the parent's rounded border
    t.editor.gutterLeft = t.editor:CreateTexture(nil,"BACKGROUND",nil,2)
    t.editor.gutterLeft:SetPoint("TOPLEFT",t.editor,"TOPRIGHT",-24,-4)
    t.editor.gutterLeft:SetPoint("BOTTOMRIGHT",-14,4)
    t.editor.gutterLeft:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    t.editor.gutterLeft:SetGradient("horizontal",0.07,0.07,0.07,0.1,0.1,0.1)
    -- two gradient textures meeting together
    t.editor.gutterRight = t.editor:CreateTexture(nil,"BACKGROUND",nil,2)
    t.editor.gutterRight:SetPoint("TOPLEFT",t.editor,"TOPRIGHT",-14,-4)
    t.editor.gutterRight:SetPoint("BOTTOMRIGHT",-4,4)
    t.editor.gutterRight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    t.editor.gutterRight:SetGradient("horizontal",0.1,0.1,0.1,0.07,0.07,0.07)

    -- primary EditBox that's the focus of the addon
    t.editor.editBox = CreateFrame("EditBox",nil,t.editor)
    t.editor.editBox:SetMultiLine(true)
    t.editor.editBox:SetMaxLetters(t.constants.MAX_EDITBOX_CHARACTERS)
    t.editor.editBox:SetAutoFocus(false)
    t.editor.editBox:SetSize(100,100)
    t.editor.editBox:SetPoint("TOPLEFT",6,-8)
    t.editor.editBox:SetPoint("BOTTOMRIGHT")
    t.editor.editBox:SetFontObject("GameFontHighlight")
    t.editor.editBox:SetTextInsets(2,1,2,2)
    t.editor.editBox:SetIgnoreParentAlpha(true)
    t.editor.editBox:SetHyperlinksEnabled(true)

    t.editor.scrollFrame:SetScrollChild(t.editor.editBox)

    -- page title background and horizontal border beneath it
    t.editor.titleBackground = t.editor:CreateTexture(nil,"BORDER",nil,-1)
    t.editor.titleBackground:SetPoint("TOPLEFT",3,-3)
    t.editor.titleBackground:SetPoint("BOTTOMRIGHT",t.editor,"TOPRIGHT",-3,-20)
    t.editor.titleBackground:SetColorTexture(0.2,0.2,0.2)
    t.editor.titleBorder = t.editor:CreateTexture(nil,"ARTWORK")
    t.editor.titleBorder:SetHeight(7)
    t.editor.titleBorder:SetPoint("TOPLEFT",4,-16)
    t.editor.titleBorder:SetPoint("TOPRIGHT",-4,-16)
    t.editor.titleBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    t.editor.titleBorder:SetTexCoord(0.5625,0.6875,0,0.4375)
    t.editor.titleBorder:SetVertexColor(0.5,0.5,0.5)
    t.editor.titleText = t.editor:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    t.editor.titleText:SetPoint("TOPLEFT",8,-6)
    t.editor.titleText:SetPoint("BOTTOMRIGHT",t.editor,"TOPRIGHT",-8,-16)
    -- purpose of this frame is to capture clicks so they don't go to the editor and set focus;
    -- clicks to this frame should go to the underlying t.main to move the frame
    t.editor.titleFrame = CreateFrame("Frame",nil,t.editor)
    t.editor.titleFrame:SetPoint("TOPLEFT",-3,-3)
    t.editor.titleFrame:SetPoint("BOTTOMRIGHT",t.editor,"TOPRIGHT",-3,-20)
    t.editor.titleFrame:SetScript("OnMouseDown",function(self) t.main:GetScript("OnMouseDown")(t.main) end)
    t.editor.titleFrame:SetScript("OnMouseUp",function(self) t.main:GetScript("OnMouseUp")(t.main) end)
    
    -- event handling
    t.editor.editBox:SetScript("OnEscapePressed",t.editor.OnEscapePressed)
    t.editor.editBox:SetScript("OnTextChanged",t.editor.OnTextChanged)
    t.editor.editBox:SetScript("OnCursorChanged",t.editor.OnCursorChanged)
    t.editor.editBox:SetScript("OnHyperlinkClick",t.editor.OnHyperlinkClick)
    t.editor.editBox:SetScript("OnKeyDown",t.editor.OnKeyDown)
    t.editor.editBox:SetScript("OnHyperlinkClick",t.editor.OnHyperlinkClick)

    -- when the text in the editbox doesn't span the whole height of the scrollframe, then it won't receive
    -- mouse events to gain focus; this click of the underlying frame will focus the editbox
    t.editor:SetScript("OnMouseDown",function(self)
        t.editor.editBox:SetCursorPosition(t.editor.editBox:GetText():len())
        t.editor.editBox:SetFocus(true)
    end)

    -- when window shown, update page to current page
    t.editor:SetScript("OnShow",t.editor.Update)

    t.editor:ScrollBarSetShown(false)
    t.editor:TitleSetShown(false)
    t.editor:UpdateFont()

    -- hooking the inserting of chat links with a secure hook this time to insert into TinyPad if it has focus
    hooksecurefunc("ChatEdit_InsertLink",function(text)
        if t.editor.editBox:HasFocus() then
            t.editor.editBox:Insert(text)
            -- shift+click may summon a StackSplitFrame, cancel it if so
            StackSplitFrame:SetAlpha(0)
            C_Timer.After(0,t.editor.CancelStackSplit)
        end
    end)
    
    t.editor:SetCurrentPage() -- update to current page (should be last page from pages.Init)
end

function t.editor:Resize(width,height)
    if not width then
        width,height = t.main:GetSize()
    end
    local adjust = t.constants.EDITBOX_WIDTH_ADJUSTMENT_NORMAL
    if t.layout.currentLayout=="bookmarks" then
        adjust = adjust + t.constants.BOOKMARKS_PANEL_WIDTH - 2
    elseif t.layout.currentLayout=="settings" then
        adjust = adjust + t.constants.SETTINGS_PANEL_WIDTH - 2
    end


    if not t.editor.scrollFrame.scrollBar.isShown then
        adjust = adjust - t.constants.SCROLLBAR_WIDTH
    end
    t.editor.editBox:SetWidth(width-adjust)
    t.editor:UpdateScrollBarVisibility()
end

--[[ updating editor ]]

function t.editor:ScrollBarSetShown(value)
    t.editor.scrollFrame.scrollBar.isShown = value
    t.editor.scrollFrame.scrollBar:SetShown(value)
    t.editor.gutterLeft:SetShown(value)
    t.editor.gutterRight:SetShown(value)
    local scrollbarOffset = value and t.constants.SCROLLBAR_WIDTH or 0
    t.editor.titleBackground:SetPoint("BOTTOMRIGHT",t.editor,"TOPRIGHT",-3-scrollbarOffset,-20)
    t.editor.titleBorder:SetPoint("TOPRIGHT",-4-scrollbarOffset,-20)
    t.editor.titleText:SetPoint("TOPRIGHT",-8-scrollbarOffset,-16)
end

function t.editor:TitleSetShown(value)
    t.editor.titleBackground:SetShown(value)
    t.editor.titleBorder:SetShown(value)
    t.editor.titleText:SetShown(value)
    t.editor.scrollFrame:SetPoint("TOPLEFT",6,value and -23 or -6)
end

-- for programatically setting the page's text, it restarts the undo stack and positions cursor at start
function t.editor:SetText(text)
    wipe(t.editor.undoStack)
    tinsert(t.editor.undoStack,"0~"..text)
    t.editor.editBox:SetText(text)
    t.editor.editBox:SetCursorPosition(0)
    t.editor.undoIndex = 1
end

-- this sets the editor to the current page. to go to a specific page, use the pages:GoTo<etc>()
-- functions which calls this function
function t.editor:SetCurrentPage()
    local text,title = t.pages:GetPage()
    t.editor:SetText(text)
    if title then -- if this is a bookmarked page it has a title to display
        t.editor.titleText:SetText(title)
        t.editor:TitleSetShown(true)
    else
        t.editor:TitleSetShown(false)
    end
end

-- sets the editbox font to the current savedvar's choice (see settings.lua)
function t.editor:UpdateFont()
    local family = t.settings.fonts[t.settings.saved.FontFamily]
    if family and family[t.settings.saved.FontSize+2] then
        t.editor.editBox:SetFont(family[2],family[t.settings.saved.FontSize+2])
    end
end

--[[ editbox handlers ]]

-- when userInput is true, the user added text and it wasn't added programatically
function t.editor:OnTextChanged(userInput)
    if userInput then
        -- remove any "redo" after a user input happens
        for i=#t.editor.undoStack,t.editor.undoIndex+1,-1 do
            tremove(t.editor.undoStack,i)
        end
        -- add new text state to the t.editor.undoStack
        tinsert(t.editor.undoStack,self:GetCursorPosition().."~"..self:GetText())
        t.editor.undoIndex = #t.editor.undoStack
        t.toolbar:UpdateUndoRedoButtonState()
    end
end

-- this makes the cursor stay within the scrollframe
function t.editor:OnCursorChanged(x,y,w,h)
    t.editor.editBox.cursorOffset = y
    t.editor.editBox.cursorHeight = h
    t.editor.editBox.handleCursorChange = true
    self:SetScript("OnUpdate",t.editor.OnCursorOnUpdate)
end

-- this runs ScrollingEdit_OnUpdate and handles the scrollbar hiding
function t.editor:OnCursorOnUpdate(elapsed)
    self:SetScript("OnUpdate",nil)
    ScrollingEdit_OnUpdate(t.editor.editBox,elapsed,t.editor.editBox:GetParent())
    t.editor:UpdateScrollBarVisibility()
end

function t.editor:UpdateScrollBarVisibility()
    local minRange,maxRange = t.editor.scrollFrame.scrollBar:GetMinMaxValues()
    local shouldBeShown = not (minRange==0 and maxRange==0)
    if not shouldBeShown and t.editor.scrollFrame.scrollBar.isShown then
        t.editor:ScrollBarSetShown(false)
        t.editor:Resize() -- editbox should be resized with scrollbar going away
    elseif shouldBeShown and not t.editor.scrollFrame.scrollBar.isShown then
        t.editor:ScrollBarSetShown(true)
        t.editor:Resize() -- editbox should be resized with scrollbar appearing
    end
end

-- this OnKeyDown only happens while the editbox has focus
function t.editor:OnKeyDown(key)
    if key=="TAB" then
        t.editor.editBox:Insert((" "):rep(t.constants.TAB_NUM_SPACES)) -- misc\constants.lua to change the number of spaces in a tab
    elseif IsControlKeyDown() then
        if key=="Z" then
            t.toolbar:UndoButtonOnClick()
        elseif key=="Y" then
            t.toolbar:RedoButtonOnClick()
        elseif key=="F" then
            t.toolbar:SearchButtonOnClick()
        elseif key=="N" then
            t.toolbar:NewPageButtonOnClick()
        end
    end
end

-- when escape pressed, close any open panels if layout is not default; otherwise clear focus
function t.editor:OnEscapePressed()
    if t.layout.currentLayout=="default" or (t.layout.currentLayout=="bookmarks" and t.settings.saved.PinBookmarks) then
        self:ClearFocus()
    else
        t.layout:Show("default")
    end
end

--[[ undo/redo ]]

function t.editor:SetPageToUndoStack(index)
    if index>0 and index<=#t.editor.undoStack then
        local cursorPosition,text = t.editor.undoStack[index]:match("(%d+)~(.*)")
        t.editor.editBox:SetText(text)
        t.editor.editBox:SetCursorPosition(cursorPosition)
    end
end

function t.editor:Undo()
    if t.editor.undoIndex > 1 then
        if IsShiftKeyDown() then -- either shift+click of Undo or shift+ctrl+z will undo to bottom of undo stack
            t.editor.undoIndex = 1
        else
            t.editor.undoIndex = t.editor.undoIndex - 1
        end
        t.editor:SetPageToUndoStack(t.editor.undoIndex)
        t.toolbar:UpdateUndoRedoButtonState()
    end
end

function t.editor:Redo()
    if t.editor.undoIndex < #t.editor.undoStack then
        if IsShiftKeyDown() then -- either shift+click of Redo or shift+ctrl+y will redo to top of undo stack
            t.editor.undoIndex = #t.editor.undoStack
        else
            t.editor.undoIndex = t.editor.undoIndex + 1
        end
        t.editor:SetPageToUndoStack(t.editor.undoIndex)
        t.toolbar:UpdateUndoRedoButtonState()
    end
end

function t.editor:CanUndo()
    return t.editor.undoIndex > 1
end

function t.editor:CanRedo()
    return t.editor.undoIndex < #t.editor.undoStack
end

--[[ links ]]

-- called in hooksecurefunc for ChatEdit_InsertLink, dismisses the StackSplitFrame if it was summoned
function t.editor:CancelStackSplit()
    StackSplitFrame:SetAlpha(1)
    if StackSplitFrame:IsVisible() then
        if StackSplitCancelButton then -- classic
            StackSplitCancelButton:Click()
        elseif StackSplitFrame.CancelButton then -- retail
            StackSplitFrame.CancelButton:Click()
        end
    end
end

-- it looks like Blizzard made some nice updates to SetItemRef; it can handle everything including battlepets and tradeskills
function t.editor:OnHyperlinkClick(link,text,button)
    SetItemRef(link,text,button)
end
