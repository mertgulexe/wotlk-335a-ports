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
-- input while the "Turkish Letters" setting is on (genuine eth/thorn, e.g. Icelandic, would be swapped too).
local TURKISH_PATTERN = "\195[\144\157\158\176\189\190]"
local TURKISH_LETTERS = {
    ["\195\176"] = "\196\159", -- U+00F0 eth      -> U+011F g breve
    ["\195\144"] = "\196\158", -- U+00D0 ETH      -> U+011E G breve
    ["\195\189"] = "\196\177", -- U+00FD y acute  -> U+0131 dotless i
    ["\195\157"] = "\196\176", -- U+00DD Y acute  -> U+0130 dotted I
    ["\195\190"] = "\197\159", -- U+00FE thorn    -> U+015F s cedilla
    ["\195\158"] = "\197\158", -- U+00DE THORN    -> U+015E S cedilla
}

function t.compat.FixTurkishLetters(editBox,userInput)
    if not userInput or not (t.settings.saved and t.settings.saved.TurkishLetters) then
        return
    end
    local text = editBox:GetText()
    if text:find(TURKISH_PATTERN) then
        local cursor = editBox:GetCursorPosition()
        editBox:SetText((text:gsub(TURKISH_PATTERN,TURKISH_LETTERS)))
        editBox:SetCursorPosition(cursor)
    end
end
