-- external/global stuff for outside interaction with the addon

local _,t = ...
_TinyPad = t -- global reference for debugging and hooking at need

-- TinyPad is the parent frame created in t.main

function TinyPad:Toggle()
    if not t.init.isInitialized then
        t.init:Initialize()
    end
    if t.main:IsShown() then
        t.pages:SavePage() -- save page contents while closing it
        t.layout:Show("default")
        t.main:Hide()
    else
        t.main:Show()
    end
end

-- opens (never closes/toggles) TinyPad to the search box
function TinyPad:OpenSearch()
    if not t.main:IsVisible() then
        TinyPad:Toggle()
    end
    t.layout:Show("searchbar")
end
TinyPad.TogglePanel = TinyPad.OpenSearch -- in case anyone uses previously bound function to do this


--[[ slash command: /tinypad or /pad ]]

-- /pad # will go to a page, /pad run # will run a page, /pad alone toggles window
function TinyPad.SlashHandler(msg)
	msg = (msg or ""):lower():trim()
	local runPageNum = tonumber(msg:match("^run (%d+)$"))
    local pageNum = tonumber(msg:match("^(%d+)$"))
	if msg=="run" then -- run alone will run current page
		TinyPad:Run(t.pages:GetCurrentPageNum())
	elseif runPageNum then -- run <num> will run page <num>
		TinyPad:Run(runPageNum)
	elseif pageNum then -- <num> alone will jump to page <num>
		TinyPad:ShowPage(pageNum)
	else
		TinyPad:Toggle()
	end
end

SLASH_TINYPADSLASH1 = "/tinypad"
SLASH_TINYPADSLASH2 = "/pad"
SlashCmdList["TINYPADSLASH"] = TinyPad.SlashHandler

-- shows the given page number: /tinypad 42
function TinyPad:ShowPage(pageNum)
    pageNum = type(self)=="table" and tonumber(pageNum) or tonumber(self) -- in case TinyPage.ShowPage(pageNum) used
    if pageNum then -- it's okay if it's out of range, just as long as it's a number; GoToPage will handle out of range
        if not t.main:IsVisible() then
            TinyPad:Toggle()
        end
        t.pages:GoToPage(pageNum)
    end
end

-- this will run the give page number as a Lua script: /tinypad run 42
function TinyPad:Run(pageNum)
    pageNum = type(self)=="table" and tonumber(pageNum) or tonumber(self) -- in case TinyPage.Run(pageNum) used
    if pageNum and (t.init.isInitialized or t.init:Initialize()) then -- possible addon hasn't been initialized yet
        t.pages:RunPage(pageNum)
    end
end

-- this will--without confirmation--delete all pages that contain the given pattern; it's primarily used
-- for addons that generate reports in TinyPad and want to clean up old copies of data. Use Carefully!
function TinyPad:DeletePagesContaining(regex)
    regex = type(self)=="table" and regex or self -- in case TinyPad.DeletePagesContaining(regex) used
    if type(regex)=="string" and regex:len()>0 then
        local pageNumsToDelete = {}
        for pageNum=1,#t.pages.saved do
            if t.pages:GetPage(pageNum):match(regex) then
                tinsert(pageNumsToDelete,pageNum)
            end
        end
        if #pageNumsToDelete>0 and (t.init.isInitialized or t.init:Initialize()) then
            t.pages:DeletePage(pageNumsToDelete)
        end
    end
    if t.init.isInitialized or t.init:Initialize() then
        t.pages:GoToPage(nil,true)
    end
end

-- TinyPad:Insert("body") -- creates a new page at the end with "body"
-- TinyPad:Insert("body","title") -- creates a new page at the end bookmarked as "title" that contains "body"
-- TinyPad:Insert("body",<number>) -- creates a new page with "body" at page <number>
-- TinyPad:Insert("body",<number>,"title") -- creates a new page bookmarked as "title" that contains "body" at page <number>
function TinyPad:Insert(body,pageNum,title)
	if type(self)=="string" then -- TinyPad.Insert was used instead of TinyPad:Insert
		title = pageNum
		pageNum = body
		body = self
	end
    if not type(body)=="string" then
        return -- a valid body not given, leave
    end
    if not t.init.isInitialized then
        t.init:Initialize()
    end
    t.pages:SavePage() -- going past here, save whatever work was done
    -- 3.3.5a port (notes import): the moves below pass dontSave (already saved above); saving again after inserting
    -- at or before the current page wrote the editor into the shifted slot and overwrote the previous page
    if not pageNum then -- ("body")
        tinsert(t.pages.saved,body)
        t.pages:GoToLastPage(true)
    elseif type(pageNum)=="string" then -- ("body","title")
        tinsert(t.pages.saved,{pageNum,body}) -- pageNum is "title"
        t.pages:GoToLastPage(true)
    elseif type(pageNum)=="number" then -- pageNum is an actual pageNum
        pageNum = max(1,min(#t.pages.saved+1,pageNum))
        if not title then
            tinsert(t.pages.saved,pageNum,body) -- ("body",<number>)
        else
            tinsert(t.pages.saved,pageNum,{title,body}) -- ("body",<number>,"title")
        end
        t.pages:GoToPage(pageNum,true)
    end
    if not t.main:IsVisible() then
        TinyPad:Toggle()
    end
end