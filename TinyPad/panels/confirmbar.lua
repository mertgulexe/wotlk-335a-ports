local _,t = ...
t.confirmbar = CreateFrame("Frame",nil,t.main,BackdropTemplateMixin and "BackdropTemplate")

t.init:Register("confirmbar")

function t.confirmbar:Init()
    t.confirmbar:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tileSize=16,tile=true,insets={left=4,right=4,top=4,bottom=4},edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    t.confirmbar:SetBackdropBorderColor(0.5,0.5,0.5)
    t.confirmbar:SetBackdropColor(0.15,0.15,0.15)

    t.confirmbar:SetPoint("TOPLEFT",t.toolbar,"BOTTOMLEFT",-2,-1)
    t.confirmbar:SetPoint("TOPRIGHT",t.toolbar,"BOTTOMRIGHT",2,0)
    t.confirmbar:SetHeight(t.constants.BUTTON_SIZE_NORMAL+11)

    t.confirmbar.text = t.confirmbar:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    t.confirmbar.text:SetText("Delete this page?")
    t.confirmbar.text:SetPoint("CENTER",-t.constants.BUTTON_SIZE_NORMAL-8,0)

    t.confirmbar.yesButton = t.buttons:Create(t.confirmbar,t.constants.BUTTON_SIZE_NORMAL,t.constants.BUTTON_SIZE_NORMAL,6,1,nil,{anchorPoint="LEFT",relativeTo=t.confirmbar.text,relativePoint="RIGHT",xoff=8,yoff=0},"Yes","Delete this page.")
    t.confirmbar.noButton = t.buttons:Create(t.confirmbar,t.constants.BUTTON_SIZE_NORMAL,t.constants.BUTTON_SIZE_NORMAL,6,2,t.confirmbar.NoButtonOnClick,{anchorPoint="LEFT",relativeTo=t.confirmbar.yesButton,relativePoint="RIGHT",xoff=6,yoff=0},"No","Don't delete this page.")

    t.confirmbar.yesButton:SetScript("PostClick",function() t.layout:Hide("confirmbar") end)
end

function t.confirmbar:Resize(width,height)
    local isWide = width >= t.constants.MIN_MEDIUM_WIDTH
    local buttonSize = isWide and t.constants.BUTTON_SIZE_NORMAL or t.constants.BUTTON_SIZE_SMALL
    t.confirmbar.yesButton:SetSize(buttonSize,buttonSize)
    t.confirmbar.noButton:SetSize(buttonSize,buttonSize)
    t.confirmbar:SetHeight(buttonSize+11)
    t.confirmbar.text:SetFontObject(isWide and "GameFontHighlight" or "GameFontHighlightSmall")
    t.confirmbar.text:SetPoint("CENTER",-buttonSize-(buttonSize/3),0)
end

function t.confirmbar:NoButtonOnClick()
    t.layout:Hide("confirmbar")
end

function t.confirmbar:Confirm(text,func)
    t.confirmbar.text:SetText(text)
    t.confirmbar.yesButton:SetScript("OnClick",func)
    t.layout:Show("confirmbar")
end