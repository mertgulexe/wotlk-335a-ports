local _,t = ...
t.searchbar = CreateFrame("Frame",nil,t.main)

t.init:Register("searchbar")

function t.searchbar:Init()
    t.searchbar:Hide()
    t.searchbar:SetPoint("TOPLEFT",t.toolbar,"BOTTOMLEFT",0,-1)
    t.searchbar:SetPoint("TOPRIGHT",t.toolbar,"BOTTOMRIGHT",0,-1)
    t.searchbar:SetHeight(t.constants.BUTTON_SIZE_NORMAL)

    t.searchbar.searchButton = t.buttons:Create(t.searchbar,24,24,4,0,t.searchbar.SearchButtonOnClick,{anchorPoint="TOPRIGHT",relativeTo=t.searchbar,relativePoint="TOPRIGHT"},"Find","Find the next page with this text.\n\n"..t.constants.TOOLTIP_SUBTEXT_COLOR.."Hold Shift to find the previous page with this text.")

    -- search box is an editbox that spans the panel up to the searchbutton on the far right
    t.searchbar.searchBox = CreateFrame("EditBox",nil,t.searchbar,"TinyPadEditBoxWithInstructionsTemplate")
    t.searchbar.searchBox.instructions:SetText("Search")
    t.searchbar.searchBox:SetPoint("TOPLEFT",t.searchbar,"TOPLEFT")
    t.searchbar.searchBox:SetPoint("TOPRIGHT",t.searchbar.searchButton,"TOPLEFT")
    t.searchbar.searchBox:SetAutoFocus(false)
    t.searchbar.searchBox:SetScript("OnEscapePressed",t.searchbar.Toggle)
    t.searchbar.searchBox:SetScript("OnTextChanged",t.searchbar.SearchOnTextChanged)
    t.searchbar.searchBox:SetScript("OnEditFocusLost",t.searchbar.SearchOnEditFocusLost)
    t.searchbar.searchBox:SetScript("OnEnterPressed",t.searchbar.SearchButtonOnClick) -- hitting enter in searchbox will /click the find button
    t.searchbar.searchBox:SetTextInsets(7,70,1,1)
    
    t.searchbar.searchBox.count = t.searchbar.searchBox:CreateFontString(nil,"ARTWORK")
    t.searchbar.searchBox.count:SetFont("Fonts\\ARIALN.ttf",10)
    t.searchbar.searchBox.count:SetPoint("RIGHT",-20,0)
    t.searchbar.searchBox.count:SetTextColor(0.5,0.5,0.5)
    t.searchbar.searchBox.count:SetText("9999 found")

    -- for a visual indicator when search is entered and there are no search hits
    t.searchbar.searchBox.flash = CreateFrame("Frame",nil,t.searchbar.searchBox,"TinyPadFlashTemplate")

    -- add number of search hits to the tooltip of the "Find" button (searchButton)
    t.searchbar.searchButton:HookScript("OnEnter",function(self)
        local count = t.pages:FindCount(t.searchbar.searchBox:GetText())
        GameTooltip:AddLine(format("\n%d matches found",count),1,0.82,0)
        GameTooltip:Show()
    end)
end

function t.searchbar:Toggle()
    if t.searchbar.searchBox.flash.animation:IsPlaying() then
        t.searchbar.searchBox.flash.animation:Stop()
    end
    t.layout:Toggle("searchbar")
    if t.layout.currentLayout=="searchbar" then
        t.searchbar.searchBox:SetFocus()
    end
end

function t.searchbar:Resize(width,height)
    local buttonSize = width >= t.constants.MIN_WIDTH_FOR_NORMAL_BUTTONS and t.constants.BUTTON_SIZE_NORMAL or t.constants.BUTTON_SIZE_SMALL
    t.searchbar.searchBox:SetHeight(buttonSize)
    t.searchbar.searchButton:SetSize(buttonSize,buttonSize)
    t.searchbar:SetHeight(buttonSize)
end

function t.searchbar:SearchOnTextChanged()
    local hasText = t.searchbar.searchBox:GetText():trim():len() > 0
    t.searchbar.searchBox.instructions:SetShown(not hasText)
    t.searchbar.searchBox.clearButton:SetShown(hasText)
    t.buttons:SetEnabled(t.searchbar.searchButton,hasText)
    t.searchbar.searchBox.count:SetShown(hasText)
    if hasText then
        -- update the number of search hits in the instruction-like text within searchBox
        local count = t.pages:FindCount(t.searchbar.searchBox:GetText())
        t.searchbar.searchBox.count:SetText(format(t.constants.SEARCH_COUNT_FORMAT,count))
        -- if mouse is over the "Find"/searchButton, then update its tooltip with new count
        if GetMouseFocus()==t.searchbar.searchButton then
            t.searchbar.searchButton:GetScript("OnEnter")(t.searchbar.searchButton)
        end
    end
end

-- clicking elsewhere will lose focus from the editbox; hide searchbar if it hasn't gotten focus back or a button is being clicked
function t.searchbar:SearchOnEditFocusLost()
    C_Timer.After(t.constants.EDIT_FOCUS_TIMER,function()
        local clickingSearchButton = GetMouseFocus()==t.searchbar.searchButton -- special case for potentially disabled search button
        if not t.searchbar.searchBox:HasFocus() and t.searchbar:IsVisible() and not t.buttons.isButtonBeingClicked and not clickingSearchButton and not t.main.isSizing and not t.main.isMoving then
            t.layout:Hide("searchbar")
        elseif clickingSearchButton or t.main.isSizing or t.main.isMoving then -- clickingSearchButton is true if mouse is over a disabled searchButton too
            t.searchbar.searchBox:SetFocus(true)
        end
    end)
end

-- flashes the border of the searchbox the given r,g,b color
function t.searchbar:SearchBoxFlash(r,g,b)
    if t.searchbar.searchBox.flash.animation:IsPlaying() then
        t.searchbar.searchBox.flash.animation:Stop()
    end
    t.searchbar.searchBox.flash.left:SetVertexColor(r,g,b)
    t.searchbar.searchBox.flash.mid:SetVertexColor(r,g,b)
    t.searchbar.searchBox.flash.right:SetVertexColor(r,g,b)
    t.searchbar.searchBox.flash.animation:Play()
end

function t.searchbar:SearchButtonOnClick()
    local text = t.searchbar.searchBox:GetText():trim()
    if text and text:len()>0 then
        local pageNum = t.pages:FindNext(text,IsShiftKeyDown())
        if pageNum then
            t.searchbar:SearchBoxFlash(0,1,0)
            t.pages:GoToPage(pageNum)
        else
            t.searchbar:SearchBoxFlash(1,0,0)
        end
    end
    t.searchbar.searchBox:SetFocus()
end
