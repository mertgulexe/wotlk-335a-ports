-- the toolbar is always visible and always one row of buttons

local _,t = ...
t.toolbar = CreateFrame("Frame",nil,t.main)

t.init:Register("toolbar")

function t.toolbar:Init()
    t.toolbar:SetPoint("TOPLEFT",6,-6)
    t.toolbar:SetPoint("TOPRIGHT",-6,-6)
    t.toolbar:SetHeight(t.constants.BUTTON_SIZE_NORMAL)

    -- buttons on right: Settings, Bookmark, Close
    t.toolbar.closeButton = t.buttons:Create(t.toolbar,24,24,2,1,TinyPad.Toggle,{anchorPoint="RIGHT",relativeTo=t.toolbar,relativePoint="RIGHT"},"Close","TinyPad version "..GetAddOnMetadata("TinyPad","Version"))
    t.toolbar.bookmarkButton = t.buttons:Create(t.toolbar,24,24,0,4,t.toolbar.BookmarkButtonOnClick,{anchorPoint="RIGHT",relativeTo=t.toolbar.closeButton,relativePoint="LEFT",xoff=-1,yoff=0},"Bookmarks","Go to a bookmarked page or manage bookmarks.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to keep bookmarks open until closed with this button.")
    t.toolbar.settingsButton = t.buttons:Create(t.toolbar,24,24,6,0,t.toolbar.SettingsButtonOnClick,{anchorPoint="RIGHT",relativeTo=t.toolbar.bookmarkButton,relativePoint="LEFT",xoff=-1,yoff=0},"Options","Search pages for text, change font and other options.")
    t.toolbar.searchButton = t.buttons:Create(t.toolbar,24,24,4,0,t.toolbar.SearchButtonOnClick,{anchorPoint="RIGHT",relativeTo=t.toolbar.settingsButton,relativePoint="LEFT",xoff=-1,yoff=0},"Search","Search pages for text.")

    -- buttons on left: New, Delete, Run
    t.toolbar.newButton = t.buttons:Create(t.toolbar,24,24,0,0,t.toolbar.NewPageButtonOnClick,{anchorPoint="LEFT",relativeTo=t.toolbar,relativePoint="LEFT"},"New","Add a new page after the last page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to insert the new page after the current page.")
    t.toolbar.deleteButton = t.buttons:Create(t.toolbar,24,24,2,0,t.toolbar.DeletePageButtonOnClick,{anchorPoint="LEFT",relativeTo=t.toolbar.newButton,relativePoint="RIGHT",xoff=1,yoff=0},"Delete","Permanently delete this page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to delete this page without confirmation.")
    t.toolbar.runButton = t.buttons:Create(t.toolbar,24,24,0,1,t.toolbar.RunPageButtonOnClick,{anchorPoint="LEFT",relativeTo=t.toolbar.deleteButton,relativePoint="RIGHT",xoff=1,yoff=0},"Run","Run this page as a Lua script.")
    t.toolbar.undoButton = t.buttons:Create(t.toolbar,24,24,2,4,t.toolbar.UndoButtonOnClick,{anchorPoint="LEFT",relativeTo=t.toolbar.runButton,relativePoint="RIGHT",xoff=1,yoff=0},"Undo","Revert changes made since opening this page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Ctrl+Z will also perform an Undo.\nHold Shift to revert all changes made.")
    t.toolbar.redoButton = t.buttons:Create(t.toolbar,24,24,2,5,t.toolbar.RedoButtonOnClick,{anchorPoint="LEFT",relativeTo=t.toolbar.undoButton,relativePoint="RIGHT",xoff=1,yoff=0},"Redo","Restore undos made since opening this page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Ctrl+Y will also perform a Redo.\nHold Shift to restore all undos.")


    -- buttons in middle: FirstPage, PrevPage, NextPage, LastPage
    t.toolbar.prevPageButton = t.buttons:Create(t.toolbar,24,24,0,3,t.toolbar.PrevPageButtonOnClick,{anchorPoint="RIGHT",relativeTo=t.toolbar,relativePoint="CENTER",xoff=-19+24,yoff=0},"Previous Page","Go to the previous page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to move this page back one page.")
    t.toolbar.nextPageButton = t.buttons:Create(t.toolbar,24,24,2,2,t.toolbar.NextPageButtonOnClick,{anchorPoint="LEFT",relativeTo=t.toolbar,relativePoint="CENTER",xoff=19+24,yoff=0},"Next Page","Go to the next page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to move this page forward one page.")
    t.toolbar.firstPageButton = t.buttons:Create(t.toolbar,16,24,2,3,t.toolbar.FirstPageButtonOnClick,{anchorPoint="RIGHT",relativeTo=t.toolbar.prevPageButton,relativePoint="LEFT",xoff=-1,yoff=0},"First Page","Go to the first page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to move this page to the first page.")
    t.toolbar.lastPageButton = t.buttons:Create(t.toolbar,16,24,2,3,t.toolbar.LastPageButtonOnClick,{anchorPoint="LEFT",relativeTo=t.toolbar.nextPageButton,relativePoint="RIGHT",xoff=1,yoff=0},"Last Page","Go to the last page.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to move this page to the last page.")

    -- PageNumber in middle
    t.toolbar.pageNumber = t.toolbar:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    t.toolbar.pageNumber:SetPoint("CENTER",t.toolbar,"CENTER",25-13,0)

    -- 3.3.5a: the close button's OnKeyDown (ESC, Allow Ctrl Keys) is gone. 3.3.5a has no SetPropagateKeyboardInput:
    -- a frame that gets keys keeps every key, movement included, while TinyPad is on screen. Instead:
    -- ESC: this helper frame is in UISpecialFrames and is shown while ESC has something to do in TinyPad. Every
    -- CloseAllWindows() hides it: the one of the ESC key (TOGGLEGAMEMENU binding -> ToggleGameMenu), but also
    -- Blizzard's own (loading screens, death, loss of control, the world map, the main menu button). Its OnHide only
    -- notes the hide; a post-hook on ToggleGameMenu does what the OnKeyDown did for ESC, any other hide just shows
    -- the helper again a frame later.
    t.toolbar.escapeHandler = CreateFrame("Frame","TinyPadEscapeHandler")
    t.toolbar.escapeHandler:Hide()
    t.toolbar.escapeHandler:SetScript("OnHide",t.toolbar.EscapeHandlerOnHide)
    tinsert(UISpecialFrames,"TinyPadEscapeHandler")
    hooksecurefunc("ToggleGameMenu",t.toolbar.ToggleGameMenuPostHook)
    -- Allow Ctrl Keys: while TinyPad is on screen, override bindings for the keys in t.constants.CTRL_KEY_BINDINGS
    -- click this button (it has no size; it is a child of the window so it is only visible with it)
    t.toolbar.keyButton = CreateFrame("Button","TinyPadKeyButton",t.main)
    t.toolbar.keyButton:EnableMouse(false)
    t.toolbar.keyButton:RegisterForClicks("AnyDown","AnyUp")
    t.toolbar.keyButton:SetScript("OnClick",t.toolbar.KeyButtonOnClick)
    -- override bindings can't change in combat: they are removed when combat starts and restored when it ends
    t.toolbar.keyButton:RegisterEvent("PLAYER_REGEN_DISABLED")
    t.toolbar.keyButton:RegisterEvent("PLAYER_REGEN_ENABLED")
    t.toolbar.keyButton:SetScript("OnEvent",t.toolbar.UpdateKeys)

end

-- 3.3.5a: shows/hides the ESC helper frame and sets/clears the Ctrl key override bindings; called when the window
-- shows or hides, the layout changes, Lock or Allow Ctrl Keys changes, and on combat start/end
function t.toolbar:UpdateKeys(event)
    local escapeHandler = t.toolbar.escapeHandler
    if not escapeHandler then
        return -- toolbar not initialized yet
    end
    local onScreen = t.main:IsVisible() and true or false
    if onScreen and not t.toolbar.wasOnScreen then
        t.toolbar.onScreenTime = GetTime() -- the frame in which the window appeared (see EscapeHandlerOnHide)
    end
    t.toolbar.wasOnScreen = onScreen
    -- ESC closes an open panel (except pinned bookmarks); otherwise it closes the window unless it's locked
    if not escapeHandler.isHandlingEscape then -- (EscapeHandlerAfterHide updates it a frame later)
        local layout = t.layout.currentLayout
        local panelOpen = layout and layout~="default" and (not t.settings.saved.PinBookmarks or layout~="bookmarks")
        local wantEscape = onScreen and (panelOpen or not t.settings.saved.Lock) and true or false
        if wantEscape~=(escapeHandler:IsShown() and true or false) then
            escapeHandler.isUpdating = true -- OnHide: this is not an ESC
            t.compat.SetShown(escapeHandler,wantEscape)
            escapeHandler.isUpdating = nil
        end
    end
    -- Ctrl keys
    local keyButton = t.toolbar.keyButton
    if event~="PLAYER_REGEN_DISABLED" and InCombatLockdown() then
        return -- bindings can't change in combat; they were removed at PLAYER_REGEN_DISABLED
    end
    local wantKeys = onScreen and t.settings.saved.AllowCtrlKeys and event~="PLAYER_REGEN_DISABLED"
    if wantKeys and not keyButton.isBound then
        for key,action in pairs(t.constants.CTRL_KEY_BINDINGS) do
            SetOverrideBindingClick(keyButton,true,key,"TinyPadKeyButton",action)
        end
        keyButton.isBound = true
    elseif not wantKeys and keyButton.isBound then
        ClearOverrideBindings(keyButton)
        keyButton.isBound = false
    end
end

-- 3.3.5a: a CloseAllWindows() hid TinyPadEscapeHandler. Whether that was the ESC key is only known when
-- ToggleGameMenu returns (ToggleGameMenuPostHook); until then this is only noted. A hide in the frame in which the
-- window appeared is not an ESC for TinyPad: ESC that brings back a hidden UI (Alt+Z) shows UIParent, whose OnShow
-- closes all windows.
function t.toolbar:EscapeHandlerOnHide()
    if self.isUpdating then
        return -- hidden by t.toolbar:UpdateKeys()
    end
    self.closePending = t.toolbar.onScreenTime~=GetTime() or nil
    t.compat.After(0,t.toolbar.EscapeHandlerAfterHide)
end

-- 3.3.5a: after every ToggleGameMenu(), the function of the ESC key. If its CloseAllWindows() hid the ESC helper,
-- do what the close button's OnKeyDown did for ESC. (Its first case, ESC in the bookmark title editbox, is handled
-- by that editbox: OnEscapePressed clears the focus and the focus-lost timer goes back to the Add/Remove button.)
function t.toolbar.ToggleGameMenuPostHook()
    local escapeHandler = t.toolbar.escapeHandler
    if not escapeHandler.closePending then
        return
    end
    escapeHandler.closePending = nil
    escapeHandler.isHandlingEscape = true
    if t.layout.currentLayout~="default" and (not t.settings.saved.PinBookmarks or t.layout.currentLayout~="bookmarks") then
        t.layout:Show("default")
    elseif not t.settings.saved.Lock then
        TinyPad:Toggle()
    end
    escapeHandler.isHandlingEscape = nil
end

-- 3.3.5a: the frame after the ESC helper was hidden. A hide that ToggleGameMenu did not claim was Blizzard closing
-- its windows (zoning, death, fear, the world map...): TinyPad and its panel stay open. Either way the helper is
-- shown again if ESC still has something to do.
function t.toolbar.EscapeHandlerAfterHide()
    t.toolbar.escapeHandler.closePending = nil
    t.toolbar:UpdateKeys()
end

-- 3.3.5a: click of TinyPadKeyButton by a Ctrl key override binding; the binding passes the action as the "mouse
-- button". Acts once per key press whether the client clicks on key down, key up or both.
function t.toolbar:KeyButtonOnClick(action,down)
    if not down and self.downAction==action then
        self.downAction = nil
        return -- key up of a key press handled on key down
    end
    self.downAction = down and action or nil
    if action=="Undo" then
        t.toolbar:UndoButtonOnClick()
    elseif action=="Redo" then
        t.toolbar:RedoButtonOnClick()
    elseif action=="Search" then
        t.toolbar:SearchButtonOnClick()
    elseif action=="New" then
        t.toolbar:NewPageButtonOnClick()
    end
end

function t.toolbar:Resize(width,height)
    local navButtonSpacing = width >= t.constants.MIN_WIDTH_FOR_PAGE_NUM and 19 or 1 -- space PrevPageButton and NextPageButton apart when page number is shown
    local buttonSize = width >= t.constants.MIN_WIDTH_FOR_NORMAL_BUTTONS and t.constants.BUTTON_SIZE_NORMAL or t.constants.BUTTON_SIZE_SMALL

    local showPageNumber = width >= t.constants.MIN_WIDTH_FOR_PAGE_NUM
    local showRedoButton = width >= t.constants.MIN_WIDTH_FOR_REDO_BUTTON
    local showUndoButton = width >= t.constants.MIN_WIDTH_FOR_UNDO_BUTTON
    local showSearchButton = width >= t.constants.MIN_WIDTH_FOR_SEARCH_BUTTON

    t.compat.SetShown(t.toolbar.pageNumber,showPageNumber) -- 3.3.5a: was :SetShown() (4 lines)
    t.compat.SetShown(t.toolbar.redoButton,showRedoButton)
    t.compat.SetShown(t.toolbar.undoButton,showUndoButton)
    t.compat.SetShown(t.toolbar.searchButton,showSearchButton)

    local numLeftButtons = 3+(showUndoButton and 1 or 0)+(showRedoButton and 1 or 0)
    local numRightButtons = 3+(showSearchButton and 1 or 0)

    local centerOffset = (numLeftButtons-numRightButtons)*buttonSize/2
    t.toolbar.prevPageButton:SetPoint("RIGHT",t.toolbar,"CENTER",centerOffset-navButtonSpacing,0)
    t.toolbar.nextPageButton:SetPoint("LEFT",t.toolbar,"CENTER",centerOffset+navButtonSpacing,0)

    for _,button in ipairs(t.toolbar.allButtons) do
        if button==t.toolbar.firstPageButton or button==t.toolbar.lastPageButton then
            button:SetSize(buttonSize-8,buttonSize)
        else
            button:SetSize(buttonSize,buttonSize)
        end
    end

    t.toolbar:SetHeight(buttonSize)
end

-- called during layout changes; updates the state of buttons
function t.toolbar:Update()
    t.buttons:SetEnabled(t.toolbar.firstPageButton,not t.pages:IsAtFirstPage())
    t.buttons:SetEnabled(t.toolbar.prevPageButton,not t.pages:IsAtFirstPage())
    t.buttons:SetEnabled(t.toolbar.nextPageButton,not t.pages:IsAtLastPage())
    t.buttons:SetEnabled(t.toolbar.lastPageButton,not t.pages:IsAtLastPage())
    t.toolbar.pageNumber:SetText(t.pages:GetCurrentPageNum())
    t.toolbar:UpdateUndoRedoButtonState()
end

-- also called from editor when text changes
function t.toolbar:UpdateUndoRedoButtonState()
    t.buttons:SetEnabled(t.toolbar.undoButton,t.editor:CanUndo())
    t.buttons:SetEnabled(t.toolbar.redoButton,t.editor:CanRedo())
end

--[[ button onclicks ]]

function t.toolbar:SettingsButtonOnClick()
    t.settings:Toggle()
end

function t.toolbar:SearchButtonOnClick()
    t.searchbar:Toggle()
end

function t.toolbar:BookmarkButtonOnClick()
    if t.layout.currentLayout=="bookmarks" then
        t.settings.saved.PinBookmarks = false
    elseif IsShiftKeyDown() then
        t.settings.saved.PinBookmarks = true
    end
    t.bookmarks:Toggle()
end

function t.toolbar:NewPageButtonOnClick()
    t.layout:Show("default") -- collapse anything that might be open
    if IsShiftKeyDown() then
        t.pages:GoToNewPage(t.pages:GetCurrentPageNum())
    else
        t.pages:GoToNewPage()
    end
    t.editor.editBox:SetFocus(true)
end

function t.toolbar:DeletePageButtonOnClick()
    -- if shift is down, or the page is empty, then delete without confirmation
    if IsShiftKeyDown() or t.editor.editBox:GetText():trim()=="" then
        t.pages:DeletePage(t.pages:GetCurrentPageNum())
    else
        if t.layout.currentLayout~="confirmbar" then -- if not already confirming a delete
            t.confirmbar:Confirm("Delete this page?",function() t.pages:DeletePage(t.pages:GetCurrentPageNum()) end)
        else
            t.layout:Hide("confirmbar")
        end
    end
end

function t.toolbar:RunPageButtonOnClick()
    t.pages:RunPage()    
end

function t.toolbar:FirstPageButtonOnClick()
    local currentPageNum = t.pages:GetCurrentPageNum()
    if IsShiftKeyDown() and currentPageNum>1 then
        t.pages:SavePage() -- in case any edits are happening, save them before moving the page
        t.pages:MovePage(t.pages:GetCurrentPageNum(),1) -- move page to start
    end
    t.pages:GoToFirstPage(IsShiftKeyDown())
end

function t.toolbar:PrevPageButtonOnClick()
    local currentPageNum = t.pages:GetCurrentPageNum()
    if IsShiftKeyDown() and currentPageNum>1 then
        t.pages:SavePage()
        t.pages:SwapPages(currentPageNum,currentPageNum-1)
    end
    t.pages:GoToPrevPage(IsShiftKeyDown())
end

function t.toolbar:NextPageButtonOnClick()
    local currentPageNum = t.pages:GetCurrentPageNum()
    if IsShiftKeyDown() and currentPageNum<#t.pages.saved then
        t.pages:SavePage()
        t.pages:SwapPages(currentPageNum,currentPageNum+1)
    end
    t.pages:GoToNextPage(IsShiftKeyDown())
end

function t.toolbar:LastPageButtonOnClick()
    local currentPageNum = t.pages:GetCurrentPageNum()
    if IsShiftKeyDown() and currentPageNum<#t.pages.saved then
        t.pages:SavePage()
        t.pages:MovePage(t.pages:GetCurrentPageNum(),#t.pages.saved)
    end
    t.pages:GoToLastPage(IsShiftKeyDown())
end

function t.toolbar:UndoButtonOnClick()
    t.editor:Undo()
end

function t.toolbar:RedoButtonOnClick()
    t.editor:Redo()
end
