-- initialization of the addon, coordinates modules loading

local _,t = ...
t.init = CreateFrame("Frame")

t.init.isInitialized = false -- becomes true when every module has been initialized
t.init.modules = {} -- ordered list of modules "main", "editor",etc for initialization and resizing

t.init:RegisterEvent("PLAYER_LOGIN")
t.init:RegisterEvent("PLAYER_LOGOUT")
t.init:SetScript("OnEvent",function(self,event)
    if event=="PLAYER_LOGIN" then
        t.init:RunAll("LoginInit")
        if t.settings.saved.OpenOnLogin then
            C_Timer.After(1,TinyPad.Toggle)
        end
    elseif event=="PLAYER_LOGOUT" and t.main:IsVisible() then -- if page on screen, it may not have been saved yet
        t.pages:SavePage()
    end
end)

-- modules should call this with their name to join the RunAll()/ResizeAll() calls
function t.init:Register(module)
    if not tContains(t.init.modules,module) then
        tinsert(t.init.modules,module)
    end
end

-- called when the window is first summoned, sets up the UI
function t.init:Initialize()
    -- run the Init function for all registered modules
    t.init:RunAll("Init")
    t.layout:Show("default") -- start with default layout
    -- run the Update function for all registered modules
    t.init:RunAll("Update")
    -- run the resize for all registered modules
    t.init:ResizeAll()
    t.init.isInitialized = true
    return true
end

-- runs func for every registered module that has one; for instance t.init:RunAll("Init") to run
-- t.main:Init(), t.toolbar:Init(), etc.
function t.init:RunAll(func)
    for _,module in ipairs(t.init.modules) do
        if t[module] and t[module][func] then
            t[module][func]()
        end
    end
end

-- runs every module:Resize() that has one. This runs when the main window resizes. It will kick off
-- a 0-frame timer to wait to run the module:Resize() functions.
function t.init:ResizeAll()
    if not t.init.isResizing then
        t.init.isResizing = C_Timer.NewTimer(0,t.init.DelayedResizeAll)
    end
end

-- waiting one frame for resize functions to run to allow hitrects to update
function t.init:DelayedResizeAll()
    for _,module in ipairs(t.init.modules) do
        if t[module] and t[module].Resize then
            t[module]:Resize(t.main:GetSize())
        end
    end
    t.init.isResizing = nil
end