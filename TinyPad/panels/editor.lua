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

    -- 3.3.5a: SetIgnoreParentAlpha(true) removed (not in 3.3.5a); the window fades only its chrome instead, see
    -- t.main:SetChromeAlpha() in main.lua
    t.editor:EnableMouse(true) -- 3.3.5a: setting a mouse script does not enable the mouse (click-to-focus below)

    -- 3.3.5a: the scrollframe needs a name: the 3.3.5a template's OnLoad and scripts find the scrollbar as
    -- <name>.."ScrollBar" (there is no ScrollBar parentKey)
    t.editor.scrollFrame = CreateFrame("ScrollFrame","TinyPadEditorScrollFrame",t.editor,"UIPanelScrollFrameTemplate")
    t.editor.scrollFrame:SetPoint("TOPLEFT",6,-6)
    t.editor.scrollFrame:SetPoint("BOTTOMRIGHT",-6,6) -- -28,6 for space for original scrollbar
    t.editor.scrollBarHideable = true
    t.editor.scrollFrame.scrollBar = _G[t.editor.scrollFrame:GetName().."ScrollBar"] -- 3.3.5a: was .ScrollBar; pedantic, I know! ScrollBar is inherited from UIPanelScrollFrameTemplate

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
    -- (3.3.5a: no texture sublevels, so the 4th CreateTexture argument is dropped here and below; SetGradient with six
    -- color values is the native 3.3.5a signature, orientation written in upper case as 3.3.5a FrameXML does)
    t.editor.gutterLeft = t.editor:CreateTexture(nil,"BACKGROUND")
    t.editor.gutterLeft:SetPoint("TOPLEFT",t.editor,"TOPRIGHT",-24,-4)
    t.editor.gutterLeft:SetPoint("BOTTOMRIGHT",-14,4)
    t.editor.gutterLeft:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    t.editor.gutterLeft:SetGradient("HORIZONTAL",0.07,0.07,0.07,0.1,0.1,0.1)
    -- two gradient textures meeting together
    t.editor.gutterRight = t.editor:CreateTexture(nil,"BACKGROUND")
    t.editor.gutterRight:SetPoint("TOPLEFT",t.editor,"TOPRIGHT",-14,-4)
    t.editor.gutterRight:SetPoint("BOTTOMRIGHT",-4,4)
    t.editor.gutterRight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    t.editor.gutterRight:SetGradient("HORIZONTAL",0.1,0.1,0.1,0.07,0.07,0.07)

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
    -- 3.3.5a: SetIgnoreParentAlpha(true) removed (not in 3.3.5a). 3.3.5a editboxes have no SetHyperlinksEnabled (they
    -- draw links by themselves), so it is only called where it exists; clicking links is done in t.editor:OnMouseUp()
    if t.editor.editBox.SetHyperlinksEnabled then
        t.editor.editBox:SetHyperlinksEnabled(true)
    end

    t.editor.scrollFrame:SetScrollChild(t.editor.editBox)

    -- page title background and horizontal border beneath it
    t.editor.titleBackground = t.editor:CreateTexture(nil,"BORDER")
    t.editor.titleBackground:SetPoint("TOPLEFT",3,-3)
    t.editor.titleBackground:SetPoint("BOTTOMRIGHT",t.editor,"TOPRIGHT",-3,-20)
    t.compat.SetColorTexture(t.editor.titleBackground,0.2,0.2,0.2) -- 3.3.5a: was :SetColorTexture()
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
    t.editor.titleFrame:EnableMouse(true) -- 3.3.5a: setting a mouse script does not enable the mouse
    t.editor.titleFrame:SetScript("OnMouseDown",function(self) t.main:GetScript("OnMouseDown")(t.main) end)
    t.editor.titleFrame:SetScript("OnMouseUp",function(self) t.main:GetScript("OnMouseUp")(t.main) end)
    
    -- event handling
    t.editor.editBox:SetScript("OnEscapePressed",t.editor.OnEscapePressed)
    t.editor.editBox:SetScript("OnTextChanged",t.editor.OnTextChanged)
    t.editor.editBox:SetScript("OnCursorChanged",t.editor.OnCursorChanged)
    -- 3.3.5a: editboxes have no OnHyperlinkClick script (both SetScript("OnHyperlinkClick") lines removed); a link
    -- is clicked through the cursor position on mouse up, as TinyPad 1.x did
    t.editor.editBox:SetScript("OnMouseUp",t.editor.OnMouseUp)
    t.editor.editBox:SetScript("OnKeyDown",t.editor.OnKeyDown)
    t.editor.editBox:SetScript("OnTabPressed",t.editor.OnTabPressed) -- 3.3.5a: TAB has its own editbox script

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
    t.main:UpdateTransparency() -- 3.3.5a: the transparency is set on the editor's parts, which exist from here on

    -- hooking the inserting of chat links with a secure hook this time to insert into TinyPad if it has focus
    hooksecurefunc("ChatEdit_InsertLink",function(text)
        t.editor:InsertLink(text) -- 3.3.5a: moved to t.editor:InsertLink() (also used by the hooks below)
    end)
    t.editor:HookLinkSources() -- 3.3.5a: quest log, achievements, copying links to chat
    
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
    t.compat.SetShown(t.editor.scrollFrame.scrollBar,value) -- 3.3.5a: was :SetShown() (3 lines)
    t.compat.SetShown(t.editor.gutterLeft,value)
    t.compat.SetShown(t.editor.gutterRight,value)
    local scrollbarOffset = value and t.constants.SCROLLBAR_WIDTH or 0
    t.editor.titleBackground:SetPoint("BOTTOMRIGHT",t.editor,"TOPRIGHT",-3-scrollbarOffset,-20)
    t.editor.titleBorder:SetPoint("TOPRIGHT",-4-scrollbarOffset,-20)
    t.editor.titleText:SetPoint("TOPRIGHT",-8-scrollbarOffset,-16)
end

function t.editor:TitleSetShown(value)
    t.compat.SetShown(t.editor.titleBackground,value) -- 3.3.5a: was :SetShown() (3 lines)
    t.compat.SetShown(t.editor.titleBorder,value)
    t.compat.SetShown(t.editor.titleText,value)
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
    -- 3.3.5a port (notes import): t.pages:SavePage() only writes back the page recorded here
    t.editor.loadedPageNum = nil
    -- never let the letter limit cut a stored page (it would be saved back cut); the limit counts letters and
    -- strlenutf8 counts every letter of the link codes too, so this is always enough
    t.editor.editBox:SetMaxLetters(max(t.constants.MAX_EDITBOX_CHARACTERS,strlenutf8(text)+t.constants.MAX_EDITBOX_CHARACTERS))
    t.editor:SetText(text)
    t.editor.loadedPageNum = t.pages:GetCurrentPageNum()
    t.editor.loadedText = text
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
        -- 3.3.5a: if the client could not load an addon font file (Inconsolata.otf is an OpenType/CFF font) the
        -- editbox keeps its old font; use FALLBACK_FONT at the same size then. (The stock Fonts\ files always load.)
        if not family[2]:lower():find("^fonts\\") then
            local file = t.editor.editBox:GetFont()
            local wanted = (family[2]:match("([^\\/]+)$") or ""):lower()
            if not file or (file:match("([^\\/]+)$") or ""):lower()~=wanted then
                t.editor.editBox:SetFont(t.constants.FALLBACK_FONT,family[t.settings.saved.FontSize+2])
            end
        end
    end
end

--[[ editbox handlers ]]

-- when userInput is true, the user added text and it wasn't added programatically
function t.editor:OnTextChanged(userInput)
    t.compat.FixTurkishLetters(self,userInput) -- 3.3.5a: Turkish keyboard input, see compat.lua
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
    -- 3.3.5a: where the cursor is drawn (x from the left edge, y negative from the top edge of the editbox, h its
    -- height) and at which position, for clicks next to a link (t.editor:GetClickSide())
    t.editor.cursorX,t.editor.cursorY,t.editor.cursorH,t.editor.cursorPos = x,y,h,self:GetCursorPosition()
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

-- 3.3.5a: TAB moved from OnKeyDown to the editbox's own OnTabPressed script (so it can't be inserted twice)
function t.editor:OnTabPressed()
    t.editor.editBox:Insert((" "):rep(t.constants.TAB_NUM_SPACES)) -- misc\constants.lua to change the number of spaces in a tab
end

-- this OnKeyDown only happens while the editbox has focus
function t.editor:OnKeyDown(key)
    if IsControlKeyDown() then
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

-- 3.3.5a: inserts a link into the page if the editbox has focus (was the body of the ChatEdit_InsertLink hook)
function t.editor:InsertLink(text)
    if type(text)=="string" and t.editor.editBox:HasFocus() then
        -- 3.3.5a: TradeSkillLinkButton calls ChatEdit_InsertLink twice in one click when no chat edit box is open
        local now = GetTime()
        if text==t.editor.lastInsertedLink and now==t.editor.lastInsertedLinkTime then
            return
        end
        t.editor.lastInsertedLink,t.editor.lastInsertedLinkTime = text,now
        t.editor.editBox:Insert(text)
        -- shift+click may summon a StackSplitFrame, cancel it if so
        StackSplitFrame:SetAlpha(0)
        t.compat.After(0,t.editor.CancelStackSplit) -- 3.3.5a: was C_Timer.After
    end
end

-- 3.3.5a: link sources that call ChatEdit_InsertLink only when a chat edit box is open (QuestLogFrame.lua,
-- Blizzard_AchievementUI.lua), so they never reach the hook above; TinyPad 1.x hooked them too. Also remembers a
-- chat edit box that a click into the pad deactivated, so a Shift+click on a link in the pad can copy it there.
function t.editor:HookLinkSources()
    hooksecurefunc("QuestLogTitleButton_OnClick",t.editor.QuestLogTitleButtonOnClick)
    if IsAddOnLoaded("Blizzard_AchievementUI") then
        t.editor:HookAchievementUI()
    else
        t.editor:RegisterEvent("ADDON_LOADED")
        t.editor:SetScript("OnEvent",function(self,event,addon)
            if event=="ADDON_LOADED" and addon=="Blizzard_AchievementUI" then
                self:UnregisterEvent("ADDON_LOADED")
                t.editor:HookAchievementUI()
            end
        end)
    end
    hooksecurefunc("ChatEdit_DeactivateChat",function(editBox)
        t.editor.deactivatedChat,t.editor.deactivatedChatTime = editBox,GetTime()
    end)
end

function t.editor:HookAchievementUI()
    hooksecurefunc("AchievementButton_OnClick",t.editor.AchievementButtonOnClick)
end

-- true when a Shift+click (CHATLINK) elsewhere should put a link into the pad instead of chat
function t.editor:WantsChatLink()
    return t.editor.editBox:HasFocus() and IsModifiedClick("CHATLINK") and not ChatEdit_GetActiveWindow()
end

-- after QuestLogTitleButton_OnClick(self,button): with no chat edit box open, Blizzard's code treated the Shift+click
-- as QUESTWATCHTOGGLE (same key by default); insert the quest link and undo that watch toggle. (1.x replaced this
-- function, so its click never toggled the watch; a secure hook runs afterwards and can only undo it)
function t.editor:QuestLogTitleButtonOnClick(button)
    if self.isHeader or not t.editor:WantsChatLink() then
        return
    end
    local questIndex = self:GetID()
    local link = GetQuestLink(questIndex)
    if link then
        t.editor:InsertLink(link)
        if IsModifiedClick("QUESTWATCHTOGGLE") then
            if IsQuestWatched(questIndex) then -- the click added the watch
                RemoveQuestWatch(questIndex)
            elseif GetNumQuestWatches()<MAX_WATCHABLE_QUESTS then -- the click removed it
                AddQuestWatch(questIndex)
            else -- the list was full: the click added nothing and showed "You may only watch 25 quests at a time."
                t.editor:ClearToggleError()
            end
            WatchFrame_Update()
            QuestLog_Update()
        end
    end
end

-- after AchievementButton_OnClick(self,ignoreModifiers): same for achievements (QUESTWATCHTOGGLE tracks them)
function t.editor:AchievementButtonOnClick(ignoreModifiers)
    if ignoreModifiers or not self.id or not t.editor:WantsChatLink() then
        return
    end
    local id = self.id
    local link = GetAchievementLink(id)
    if link then
        t.editor:InsertLink(link)
        if IsModifiedClick("QUESTWATCHTOGGLE") then
            if IsTrackedAchievement(id) then -- the click started tracking it
                RemoveTrackedAchievement(id)
            elseif GetNumTrackedAchievements()<WATCHFRAME_MAXACHIEVEMENTS and not select(4,GetAchievementInfo(id)) then
                AddTrackedAchievement(id) -- the click stopped tracking it
            else -- a completed one or a full list: the click tracked nothing and showed a red error
                t.editor:ClearToggleError()
            end
            -- Blizzard redrew the list (its Track check) before the undo above
            if AchievementFrameAchievements_ForceUpdate then
                AchievementFrameAchievements_ForceUpdate()
            end
            WatchFrame_Update()
        end
    end
end

-- 3.3.5a: a Shift+click into the pad that Blizzard's code also took as QUESTWATCHTOGGLE and refused ("This
-- achievement has already been completed.", "You may only track 10 achievements at a time.", "You may only watch
-- 25 quests at a time."): remove the red error it just added. It is cleared in the same frame, so it is never
-- drawn; other errors of the last seconds go with it.
function t.editor:ClearToggleError()
    if UIErrorsFrame and UIErrorsFrame.Clear then
        UIErrorsFrame:Clear()
    end
end

-- 3.3.5a: EditBox:GetCursorPosition() is the number of bytes before the cursor. Returns the hyperlink part
-- ("item:5996:0:0:0:0:0:0:0:25") and the whole link with its color codes of the link a click put the cursor in or
-- at the edge of (TinyPad 1.x found links by the cursor too). A cursor at an edge is a click on the link only on the
-- link's side of the cursor (see GetClickSide); clicking the empty space after a line that ends with a link, or
-- just before a link, also puts the cursor there.
function t.editor:FindLinkAtCursor(text,cursor,side)
    local init = 1
    while true do
        local s,e,ref = text:find("|H(.-)|h.-|h",init)
        if not s then
            return
        end
        local first,last = s,e
        if text:sub(s-10,s-9)=="|c" then
            first = s-10
        end
        if text:sub(e+1,e+2)=="|r" then
            last = e+2
        end
        if (cursor>first-1 and cursor<last) or (cursor==last and side~="after") or (cursor==first-1 and side~="before") then
            return ref,text:sub(first,last)
        end
        init = e+1
    end
end

-- 3.3.5a: where the mouse is compared to the cursor, in reading order: "before" (above the cursor's line, or on it
-- and left of the cursor), "after" (below it, or on it and right of the cursor), "at", or nil when it is not known
-- where the cursor is drawn (then a click at either edge of a link counts as a click on it)
function t.editor:GetClickSide(cursor)
    local editBox = t.editor.editBox
    local left,top,scale = editBox:GetLeft(),editBox:GetTop(),editBox:GetEffectiveScale()
    if t.editor.cursorPos~=cursor or not t.editor.cursorX or not t.editor.cursorY or not left or not top or not scale or scale<=0 then
        return
    end
    local mouseX,mouseY = GetCursorPosition()
    local x = mouseX/scale-left
    local down = top-mouseY/scale
    local lineTop = -t.editor.cursorY
    local lineBottom = lineTop+(t.editor.cursorH or 0)
    if down<lineTop then
        return "before"
    elseif down>lineBottom then
        return "after"
    elseif x<t.editor.cursorX then
        return "before"
    elseif x>t.editor.cursorX then
        return "after"
    end
    return "at"
end

-- 3.3.5a: replaces OnHyperlinkClick (editboxes have none in 3.3.5a): a click on a link opens it (SetItemRef); a
-- Shift+click (CHATLINK) copies it into the chat edit box instead of pasting it back into the pad
function t.editor:OnMouseUp(button)
    local cursor = self:GetCursorPosition()
    local ref,link = t.editor:FindLinkAtCursor(self:GetText(),cursor,t.editor:GetClickSide(cursor))
    if not ref then
        return
    end
    if IsModifiedClick("CHATLINK") then
        local chat = ChatEdit_GetActiveWindow()
        -- the click into the pad took the keyboard focus from the chat edit box, which deactivated it: reopen it
        if not chat and t.editor.deactivatedChat and GetTime()-t.editor.deactivatedChatTime<=t.constants.CHAT_LINK_RESTORE_TIME then
            chat = t.editor.deactivatedChat
            ChatEdit_ActivateChat(chat)
        end
        if chat then
            chat:Insert(link)
        end
        t.editor.deactivatedChat = nil
    else
        t.editor:OnHyperlinkClick(ref,link,button)
    end
end

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
-- (3.3.5a: called by t.editor:OnMouseUp(); the 3.3.5a SetItemRef shows these links in ItemRefTooltip)
function t.editor:OnHyperlinkClick(link,text,button)
    SetItemRef(link,text,button)
end
