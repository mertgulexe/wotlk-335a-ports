-- 3.3.5a: new file in 3.0.19-wotlk335. TinyPad 3.x is written for clients newer than WoW 3.3.5a (build 12340,
-- Interface 30300). These are private replacements for the client functions it uses that 3.3.5a does not have.
-- They only live in t.compat: no new globals (no C_Timer) and no patching of widget metatables, because other
-- 3.3.5a addons test for those names to detect what the client can do.

local _,t = ...
t.compat = {}

-- region:SetShown(value)
function t.compat.SetShown(region,value)
    if value then
        region:Show()
    else
        region:Hide()
    end
end

-- button:SetEnabled(value)
function t.compat.SetEnabled(button,value)
    if value then
        button:Enable()
    else
        button:Disable()
    end
end

-- button:IsEnabled() returns 1 or 0 in 3.3.5a, and 0 is true in Lua
function t.compat.IsEnabled(button)
    local enabled = button:IsEnabled()
    return enabled~=nil and enabled~=false and enabled~=0
end

-- texture:SetColorTexture(r,g,b[,a]); in 3.3.5a SetTexture(r,g,b,a) makes a solid color texture
function t.compat.SetColorTexture(texture,r,g,b,a)
    texture:SetTexture(r,g,b,a or 1)
end

-- C_Timer.After(delay,func): runs func once, delay seconds from now but never before the next frame (so
-- t.compat.After(0,func) waits one frame like C_Timer.After(0,func)). The hidden frame's OnUpdate only runs
-- while a timer is waiting. GetTime() returns the same value for the whole frame.
local timers = {}
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate",function(self)
    local now = GetTime()
    local i = 1
    while timers[i] do
        local timer = timers[i]
        if now>timer.scheduled and now>=timer.due then
            tremove(timers,i)
            timer.func()
        else
            i = i + 1
        end
    end
    if #timers==0 then
        self:Hide()
    end
end)

function t.compat.After(delay,func)
    local now = GetTime()
    tinsert(timers,{scheduled=now,due=now+(delay or 0),func=func})
    timerFrame:Show()
end

-- 3.3.5a: the client decodes text typed on a Turkish keyboard (and pasted text) with the Western code page, so
-- g breve, dotless i, s cedilla, G breve, dotted I and S cedilla arrive as eth, y acute, thorn, ETH, Y acute and
-- THORN. Every pair is 2 bytes in UTF-8, so swapping them back keeps the cursor where it was. Runs only for user
-- input while the "Turkish Letters" setting is on (an eth, thorn or y acute typed for Icelandic, Faroese, Czech or
-- Slovak is swapped too).
-- 3.3.5a fix: only the text just typed or pasted is converted, never letters that were already in the box (an old
-- note with a genuine eth or thorn stays as it is). Every OnTextChanged of the three boxes, programmatic ones
-- included, passes through here, so editBox.tpTurkishText is the box's text before this change. A new box starts
-- empty, and the three boxes get this script before any text is set.
local TURKISH_PATTERN = "\195[\144\157\158\176\189\190]"
local TURKISH_LETTERS = {
    ["\195\176"] = "\196\159", -- U+00F0 eth      -> U+011F g breve
    ["\195\144"] = "\196\158", -- U+00D0 ETH      -> U+011E G breve
    ["\195\189"] = "\196\177", -- U+00FD y acute  -> U+0131 dotless i
    ["\195\157"] = "\196\176", -- U+00DD Y acute  -> U+0130 dotted I
    ["\195\190"] = "\197\159", -- U+00FE thorn    -> U+015F s cedilla
    ["\195\158"] = "\197\158", -- U+00DE THORN    -> U+015E S cedilla
}

-- 3.3.5a fix: the number of bytes (at most n) the strings a and b start with in common; few comparisons of
-- whole substrings rather than a Lua loop over every byte of a long page
local function CommonPrefixLength(a,b,n)
    if a:sub(1,n)==b:sub(1,n) then
        return n -- typing or pasting without a selection: the whole old text in front of the cursor is still there
    end
    local low,high = 0,n-1
    while low<high do
        local middle = ceil((low+high)/2)
        if a:sub(1,middle)==b:sub(1,middle) then
            low = middle
        else
            high = middle-1
        end
    end
    return low
end

function t.compat.FixTurkishLetters(editBox,userInput)
    local text = editBox:GetText()
    local before = editBox.tpTurkishText or "" -- 3.3.5a fix: the text before this change
    editBox.tpTurkishText = text
    if not userInput or not (t.settings.saved and t.settings.saved.TurkishLetters) or not text:find(TURKISH_PATTERN) then
        return
    end
    -- 3.3.5a fix: the cursor is a byte offset and stands right after what was typed or pasted. The text after it was
    -- there before; the new text starts after the part both texts begin with (a replaced selection is not part of it)
    local cursor = editBox:GetCursorPosition()
    local tail = #text-cursor
    local first
    if tail>=0 and tail<=#before then
        first = CommonPrefixLength(text,before,min(cursor,#before-tail))+1
    else
        first = cursor-1 -- the old text does not fit: only the letter in front of the cursor (2 bytes)
    end
    first = max(1,first)
    while first>1 and (text:byte(first) or 0)>=128 and (text:byte(first) or 0)<192 do
        first = first-1 -- start at the first byte of a letter: the common part can end inside a 2-byte letter
    end
    if first>cursor then
        return -- nothing new (a deletion)
    end
    local typed = text:sub(first,cursor)
    if typed:find(TURKISH_PATTERN) then
        text = text:sub(1,first-1)..(typed:gsub(TURKISH_PATTERN,TURKISH_LETTERS))..text:sub(cursor+1)
        editBox.tpTurkishText = text
        editBox:SetText(text)
        editBox:SetCursorPosition(cursor) -- each pair is 2 bytes to 2 bytes, so the cursor stays after the letter
    end
end
