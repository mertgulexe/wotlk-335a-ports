-- handles the layout of frames
-- right now, all views of the addon include main+toolbar+editor, and only one other panel is visible at a time

local _,t = ...
t.layout = {}

-- each view of the addon is defined in this table, with a key of the layout name, and an ordered
-- list of actions to run in the order they're listed, among "anchor", "hide" or "show"
t.layout.layouts = {
    default = {
        {"anchor","editor","TOPLEFT","toolbar","BOTTOMLEFT",-2,0},
        {"anchor","editor","BOTTOMRIGHT",nil,"BOTTOMRIGHT",-4,4},
        {"hide","confirmbar"},
        {"hide","bookmarks"},
        {"hide","searchbar"},
        {"hide","settings"},
    },
    bookmarks = {
        {"anchor","editor","TOPLEFT","toolbar","BOTTOMLEFT",-2,0},
        {"anchor","editor","BOTTOMRIGHT","bookmarks","BOTTOMLEFT",2,0},
        {"hide","confirmbar"},
        {"show","bookmarks"},
        {"hide","searchbar"},
        {"hide","settings"},
    },
    confirmbar = {
        {"anchor","editor","TOPLEFT","confirmbar","BOTTOMLEFT",0,1},
        {"anchor","editor","BOTTOMRIGHT",nil,"BOTTOMRIGHT",-4,4},
        {"show","confirmbar"},
        {"hide","bookmarks"},
        {"hide","searchbar"},
        {"hide","settings"},
    },
    searchbar = {
        {"anchor","editor","TOPLEFT","searchbar","BOTTOMLEFT",-2,0},
        {"anchor","editor","BOTTOMRIGHT",nil,"BOTTOMRIGHT",-4,4},
        {"hide","bookmarks"},
        {"hide","confirmbar"},
        {"show","searchbar"},
        {"hide","settings"},
    },
    settings = {
        {"anchor","editor","TOPLEFT","toolbar","BOTTOMLEFT",-2,0},
        {"anchor","editor","BOTTOMRIGHT","settings","BOTTOMLEFT",2,0},
        {"hide","confirmbar"},
        {"hide","bookmarks"},
        {"hide","searchbar"},
        {"show","settings"},
    },
}

-- for now, hiding any specific layout will change to default
function t.layout:Hide(layout)
    if not layout or t.layout.currentLayout==layout then
        t.layout:Show("default")
    end
end

-- showing a layout will go through layouts above
function t.layout:Show(layout)

    -- if bookmarks are pinned, then going to default should show bookmarks
    if layout=="default" and t.settings.saved.PinBookmarks then
        layout="bookmarks"
    end

    if t.layout.currentLayout == layout then
        return -- if already on this layout then nothing to do, leave
    end

    t.layout.currentLayout = layout -- changing to new layout

    local layout = t.layout.layouts[layout] -- not layout reference here changing to layout table

    if not layout then
        return -- the given layout is not defined, leave
    end

    -- first clear anchors of anything about to be anchored
    for _,action in ipairs(layout) do
        if action[1]=="anchor" then
            t[action[2]]:ClearAllPoints()
        end
    end

    for _,action in ipairs(layout) do
        if action[1]=="anchor" then
            t[action[2]]:SetPoint(action[3],action[4] and t[action[4]] or t.main,action[5],action[6],action[7])
        elseif action[1]=="hide" then
            t[action[2]]:Hide()
        elseif action[1]=="show" then
            t[action[2]]:Show()
        end
    end

    t.init:RunAll("Update")
    t.init:ResizeAll()

    -- special handling; whenever searchbar is opened it should always set focus to the searchbox
    if t.layout.currentLayout=="searchbar" then
        t.searchbar.searchBox:SetFocus()
    end

end

function t.layout:Toggle(layout)
    if t.layout.currentLayout == layout or not t.layout.layouts[layout] then
        t.layout:Hide(layout)
    else
        t.layout:Show(layout)
    end
end
