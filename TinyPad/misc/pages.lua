local _,t = ...
t.pages = {}

TinyPadPages = {} -- savedvar that's an ordered list of pages, which are either text or {title,text} for bookmarked pages

-- current page number, index into TinyPadPages; this is made local because it's very important that this not
-- be played around with outside of this module
local currentPageNum 


t.init:Register("pages")

function t.pages:LoginInit()
    t.pages.saved = TinyPadPages
    -- if no pages at all, add a Welcome to TinyPad! page
    if #t.pages.saved==0 then
        tinsert(t.pages.saved,t.constants.WELCOME_MESSAGE)
    end
    currentPageNum = t.settings.saved.StartOnPage1 and 1 or #t.pages.saved
end

--[[ returning page information ]]

function t.pages:GetCurrentPageNum()
    return currentPageNum
end

function t.pages:IsAtLastPage()
    return currentPageNum==#t.pages.saved
end

function t.pages:IsAtFirstPage()
    return currentPageNum==1
end

--[[ saving and getting pages ]]

-- saves the contents of the current page; call before moving away from a page, closing window or doing anything
-- that depends on the contents (like run or chat)
function t.pages:SavePage()
    if type(t.pages.saved[currentPageNum])=="table" then
        t.pages.saved[currentPageNum][2] = t.editor.editBox:GetText()
    elseif type(t.pages.saved[currentPageNum])=="string" then
        t.pages.saved[currentPageNum] = t.editor.editBox:GetText()
    end
end

-- returns text[,title] from saved pages at the given index, or "" if it doesn't exist
function t.pages:GetPage(index)
    index = index or currentPageNum -- if no argument, use current page
    if index>=1 and index<=#t.pages.saved then
        local pageType = type(t.pages.saved[index])
        if pageType=="table" then
            return t.pages.saved[index][2],t.pages.saved[index][1]
        elseif pageType=="string" then
            return t.pages.saved[index]
        end
    end
    return ""
end

function t.pages:RunPage(index)
    index = index or currentPageNum -- if no argument, use current page
    t.pages:SavePage()
    t.layout:Show("default") -- collapse anything that might be open
    RunScript(t.pages:GetPage(index):gsub("^/run ",""):gsub("^/script ",""))
end

-- converts a page from "text" to {"title","text"} or renames title if already {"title","text"}
function t.pages:AddTitle(title)
    t.pages:SavePage() -- save any changes before changing title
    local text = t.pages:GetPage()
    t.pages.saved[currentPageNum] = {title,text}
    t.pages:GoToPage(currentPageNum,true)
end

-- converts a page from {"title","text"} to just "text", removing the title
function t.pages:RemoveTitle()
    t.pages:SavePage()
    local text = t.pages:GetPage()
    t.pages.saved[currentPageNum] = text
    t.pages:GoToPage(currentPageNum,true)
end

--[[ page navigation ]]

-- all of these navigations include a dontSave to prevent saving the current page when moving
-- to the next page. for instance, after a page swap, dontSave should be true before going to
-- the other page, or will overwrite the swapped version of the current page number
function t.pages:GoToNextPage(dontSave)
    t.pages:GoToPage(min(currentPageNum+1,#t.pages.saved),dontSave)
end

function t.pages:GoToLastPage(dontSave)
    t.pages:GoToPage(#t.pages.saved,dontSave)
end

function t.pages:GoToPrevPage(dontSave)
    t.pages:GoToPage(max(currentPageNum-1,1),dontSave)
end

function t.pages:GoToFirstPage(dontSave)
    t.pages:GoToPage(1,dontSave)
end

function t.pages:GoToNewPage(index)
    if index and index>=1 and index<#t.pages.saved then
        tinsert(t.pages.saved,index+1,"")
        t.pages:GoToPage(index+1)
    else
        tinsert(t.pages.saved,"")
        t.pages:GoToPage(#t.pages.saved)
    end
end

-- always use this to go to a page; it will do validation and housekeeping before changing the page.
-- if this page change is due to pages being deleted, pass dontSave as true so it doesn't write
-- the current editor contents to another page
function t.pages:GoToPage(pageNum,dontSave)
    -- keep pageNum within 1 to last page
    pageNum = min(#t.pages.saved,max(1,(pageNum or currentPageNum))) 
    -- if the page no longer exists there (gaps in ordered list), create a blank one
    if not t.pages.saved[pageNum] then
        t.pages.saved[pageNum] = ""
    end
    -- unless told otherwise, save the current page from the editor before moving on to next page
    if not dontSave then
        t.pages:SavePage()
    end
    t.layout:Hide("confirmbar") -- close opened stuff
    currentPageNum = pageNum -- set the current page to the one given
    t.editor:SetCurrentPage() -- change the editor to the new current page
    t.toolbar:Update() -- and update toolbar nav buttons
    t.bookmarks:Update() -- and add/remove bookmark button if panel open
end

--[[ page manipulation ]]

-- deletes a single or multiple pages. for a single page, pass the page number to delete;
-- for multiple pages pass an ordered list of page numbers.
function t.pages:DeletePage(index)
    if type(index)=="table" then -- if this is a list of pages to delete
        local list = index
        table.sort(list) -- make sure they're in order
        for i=#list,1,-1 do
            tremove(t.pages.saved,list[i])
        end
    elseif type(index)=="number" then -- this is just a single page to delete
        tremove(t.pages.saved,index)
    end
    t.pages:GoToPage(currentPageNum,true)
end

-- moves a page from the source and puts it in the destination (use for first/last)
function t.pages:MovePage(source,destination)
    if source<1 or source>#t.pages.saved or destination<1 or destination>#t.pages.saved then
        return -- don't allow a page to move beyond the range of pages
    end
    local save = t.pages.saved[source]
    tremove(t.pages.saved,source)
    tinsert(t.pages.saved,destination,save)
end

-- swaps two pages (use for prev/next)
function t.pages:SwapPages(page1,page2)
    if t.pages.saved[page1] and t.pages.saved[page2] then
        local save = t.pages.saved[page1]
        t.pages.saved[page1] = t.pages.saved[page2]
        t.pages.saved[page2] = save
    end
end

-- for escaping special characters (literal) and case inensitive (caseinsensitive) in searches
local function literal(c) return "%"..c end
local function caseinsensitive(c) return format("[%s%s]",c:lower(),c:upper()) end

-- returns the number of pages that contain the given text
function t.pages:FindCount(text)
    local count = 0
    if text and text:trim():len()>0 then
        local search = text:trim():gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]",literal):gsub("%a",caseinsensitive)
        for _,page in ipairs(t.pages.saved) do
            if type(page)=="table" and page[2]:match(search) or type(page)=="string" and page:match(search) then
                count = count + 1
            end
        end
    end
    return count
end

-- returns the next page number containing the given text; backwards is true to find previous page
function t.pages:FindNext(text,backwards)
    local pageNum = currentPageNum
    local pageCount = #t.pages.saved
    local search = text:trim():gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]",literal):gsub("%a",caseinsensitive)
    for i=1,pageCount do
        pageNum = (pageNum + (backwards and (pageCount-2) or 0))%pageCount + 1
        if t.pages:GetPage(pageNum):match(search) then
            return pageNum
        end
    end
end
