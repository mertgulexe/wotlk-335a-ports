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
