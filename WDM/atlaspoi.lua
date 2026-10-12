local WDM = LibStub("AceAddon-3.0"):GetAddon("WDM")
local AtlasPOI = WDM:NewModule("AtlasPOI", "AceHook-3.0")
local DData = WDM:GetModule("DungeonData")

local Astrolabe = DongleStub("Astrolabe-0.4")
local L = LibStub("AceLocale-3.0"):GetLocale("WDM")

local defaults = {
    profile = {
        ["show_minimap"] = false,
        ["show_zonelevel"] = false,
        ["show_taxinode"] = true,
        ["show_taxinode_opposite"] = false,
        ["show_taxinode_continent"] = true,
        ["show_taxinode_continent_opposite"] = false,
        ["show_instance"] = true,
        ["microdungeons"] = false,
        ["debugmode"] = false
    }
}

NUM_WORLDMAP_ATLAS_POI = 0;

function AtlasPOI:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WDMdb", defaults, true)
end

function AtlasPOI:AddTrackingOptions()
    local menu = {
        {text = L["atlas_tracking_title_text"], isTitle = true}, {
            text = self:GetAtlasTOtext("taxinode", false),
            keepShownOnClick = 1,
            checked = function() return self.db.profile.show_taxinode end,
            func = function()
                self.db.profile.show_taxinode = not self.db.profile
                                                    .show_taxinode
                -- 3.3.5a taint fix: redraw only WDM's icons. WorldMapFrame_Update() called from addon code
                -- tainted Blizzard's map globals (NUM_WORLDMAP_DEBUG_ZONEMAP, ...) until /reload.
                self:ShowPOIs()
            end,
            hasArrow = true,
            menuList = {
                {
                    text = self:GetAtlasTOtext("taxinode", true),
                    keepShownOnClick = 1,
                    checked = function()
                        return self.db.profile.show_taxinode_opposite
                    end,
                    func = function()
                        self.db.profile.show_taxinode_opposite = not self.db
                                                                     .profile
                                                                     .show_taxinode_opposite
                        self:ShowPOIs() -- 3.3.5a taint fix: was WorldMapFrame_Update()
                    end
                }
            }
        }, {
            text = self:GetAtlasTOtext("taxinode_continent", false),
            keepShownOnClick = 1,
            checked = function()
                return self.db.profile.show_taxinode_continent
            end,
            func = function()
                self.db.profile.show_taxinode_continent = not self.db.profile
                                                              .show_taxinode_continent
                self:ShowPOIs() -- 3.3.5a taint fix: was WorldMapFrame_Update()
            end,
            hasArrow = true,
            menuList = {
                {
                    text = self:GetAtlasTOtext("taxinode_continent", true),
                    keepShownOnClick = 1,
                    checked = function()
                        return self.db.profile.show_taxinode_continent_opposite
                    end,
                    func = function()
                        self.db.profile.show_taxinode_continent_opposite =
                            not self.db.profile.show_taxinode_continent_opposite
                        self:ShowPOIs() -- 3.3.5a taint fix: was WorldMapFrame_Update()
                    end
                }
            }
        }, {
            text = L["show_instance_text"],
            keepShownOnClick = 1,
            checked = function() return self.db.profile.show_instance end,
            func = function()
                self.db.profile.show_instance = not self.db.profile
                                                    .show_instance
                self:ShowPOIs() -- 3.3.5a taint fix: was WorldMapFrame_Update()
            end
        }, {
            text = L["show_zonelevel_text"],
            keepShownOnClick = 1,
            checked = function()
                return self.db.profile.show_zonelevel
            end,
            func = function()
                self.db.profile.show_zonelevel = not self.db.profile
                                                     .show_zonelevel
                -- 3.3.5a taint fix: no WorldMapFrame_Update() here; zonelevel.lua's OnUpdate hook applies it next frame
            end
        }
    }

    local button = CreateFrame("Button", "WDM_WorldMapButton", WorldMapButton)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", WorldMapButton, "TOPRIGHT", -4, -4)
    button:SetFrameStrata("TOOLTIP")
    button:SetFrameLevel(WorldMapButton:GetFrameLevel() + 2)
    button:SetSize(32, 32)

    local function UpdateWDMWorldMapButtonScale()
        if not button or not button.GetParent then
            return
        end

        local parent = button:GetParent()
        if not parent then
            return
        end

        local parentScale = parent.GetEffectiveScale and parent:GetEffectiveScale() or parent:GetScale() or 1
        local frameScale = WorldMapFrame and WorldMapFrame.GetEffectiveScale and WorldMapFrame:GetEffectiveScale() or 1

        if parentScale == 0 then
            parentScale = 1
        end

        button:SetScale(frameScale / parentScale)
    end

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(25, 25)
    background:SetPoint("TOPLEFT", 2, -4)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 6, -5)
    icon:SetTexture("Interface\\Minimap\\Tracking\\None")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local menuFrame
    button:SetScript("OnClick", function(self, button, down)
        if not menuFrame then
            menuFrame = CreateFrame("Frame", "MyMenuFrame", UIParent, "UIDropDownMenuTemplate")
        end
        -- 3.3.5a taint fix: no "MENU" displayMode. EasyMenu would store MyMenuFrame.displayMode, and the frame stays
        -- UIDROPDOWNMENU_OPEN_MENU after the menu closes, so Blizzard's UIDropDownMenu_AddButton read that tainted
        -- field while building the world map's dropdowns (WorldMapFrame_UpdateMap). The menu look is restored below.
        EasyMenu(menu, menuFrame, self, 0, 0, nil, 0)
    end)

    -- 3.3.5a taint fix: give WDM's own lists the menu backdrop (what displayMode "MENU" did) after Blizzard
    -- opened them; only widget calls on the list frames, nothing Blizzard code reads is written.
    self:SecureHook("ToggleDropDownMenu", function(level)
        local list = _G["DropDownList" .. (level or 1)]
        if menuFrame and UIDROPDOWNMENU_OPEN_MENU == menuFrame and list and list:IsShown() then
            local backdrop = _G[list:GetName() .. "Backdrop"]
            local menuBackdrop = _G[list:GetName() .. "MenuBackdrop"]
            if backdrop and menuBackdrop then
                backdrop:Hide()
                menuBackdrop:Show()
            end
        end
    end)

    UpdateWDMWorldMapButtonScale()

    if not button.wdmScaleHooked then
        button.wdmScaleHooked = true

        WorldMapButton:HookScript("OnShow", UpdateWDMWorldMapButtonScale)
        WorldMapButton:HookScript("OnSizeChanged", UpdateWDMWorldMapButtonScale)

        if WorldMapFrame then
            WorldMapFrame:HookScript("OnShow", UpdateWDMWorldMapButtonScale)
            WorldMapFrame:HookScript("OnSizeChanged", UpdateWDMWorldMapButtonScale)
        end

        if type(WorldMapFrame_Update) == "function" then
            hooksecurefunc("WorldMapFrame_Update", UpdateWDMWorldMapButtonScale)
        end
    end

end

function AtlasPOI:ShowPOIs()

    local generated_array = DData:GetListAtlasPOI(GetCurrentMapContinent());
    local numAtlasPOI = #generated_array;
    if (NUM_WORLDMAP_ATLAS_POI < numAtlasPOI) then
        for i = NUM_WORLDMAP_ATLAS_POI + 1, numAtlasPOI do
            DData:CreateAtlasPOI(i);
        end
        NUM_WORLDMAP_ATLAS_POI = numAtlasPOI;
    end

    for i = 1, NUM_WORLDMAP_ATLAS_POI do
        local worldMapAtlasPOIName = "WorldMapFrameAtlasPOI" .. i;
        local worldMapAtlasPOI = _G[worldMapAtlasPOIName];
        if (i <= numAtlasPOI) then
            local faction, x, y, text, desc, twidth, theight, tleft, tright,
                  ttop, tbottom = unpack(generated_array[i]);
            _G[worldMapAtlasPOIName .. "Texture"]:SetSize(twidth, theight)
            _G[worldMapAtlasPOIName .. "GlowTexture"]:SetSize(twidth, theight)
            _G[worldMapAtlasPOIName .. "HighlightTexture"]:SetSize(twidth,
                                                                   theight)

            _G[worldMapAtlasPOIName .. "Texture"]:SetTexCoord(tleft, tright,
                                                              ttop, tbottom);
            _G[worldMapAtlasPOIName .. "GlowTexture"]:SetTexCoord(tleft, tright,
                                                                  ttop, tbottom);
            _G[worldMapAtlasPOIName .. "HighlightTexture"]:SetTexCoord(tleft,
                                                                       tright,
                                                                       ttop,
                                                                       tbottom);
            x = x * WorldMapButton:GetWidth();
            y = -y * WorldMapButton:GetHeight();
            worldMapAtlasPOI:SetPoint("CENTER", "WorldMapButton", "TOPLEFT", x,
                                      y);
            worldMapAtlasPOI.name = text;
            worldMapAtlasPOI.description = desc;
            --worldMapAtlasPOI.mapLinkID = 0;
            worldMapAtlasPOI:Show();
        else
            worldMapAtlasPOI:Hide();
        end
    end
end

function AtlasPOI:GetAtlasTOtext(category, opposite)
    local faction, _ = UnitFactionGroup("player"):lower()
    if opposite then
        if faction == "alliance" then
            faction = "horde"
        else
            faction = "alliance"
        end
    end

    local twidth, theight, tleft, tright, ttop, tbottom =
        DData:GetAtlasTextureCoords(category, faction)

    local textureWidth = 1024
    local textureHeight = 1024

    local x1 = math.ceil(tleft * textureWidth)
    local x2 = math.ceil(tleft * textureWidth) + (math.ceil(tright * textureWidth) - math.ceil(tleft * textureWidth))
    local y1 = math.ceil(ttop * textureHeight)
    local y2 = math.ceil(ttop * textureHeight) + (math.ceil(tbottom * textureHeight) - math.ceil(ttop * textureHeight))

    return
        "|TInterface\\AddOns\\WDM\\textures\\objecticonsatlas:".. twidth ..":".. theight.. ":0:0:" ..
        textureWidth .. ":" .. textureHeight .. ":" ..
        x1 .. ":" .. x2 .. ":" .. y1 .. ":" .. y2 .. "|t " ..
        L["show_" .. category .. "_" .. faction .. "_text"]
end


function AtlasPOI:WorldMapFrame_Update()
    self:ShowPOIs()
    DData:DebugCoords()
end

-- 3.3.5a taint fix: WDM's icons no longer use Blizzard's WorldMapPOI_OnEnter/OnLeave/OnClick (set by WDM, they ran
-- tainted: hovering wrote WorldMapFrame.poiHighlight, clicking zoomed the map from addon code). The icons now let
-- the mouse through to WorldMapButton, so clicks run Blizzard's own zoom handler, and the hover label is set here,
-- after Blizzard's WorldMapButton_OnUpdate (widget calls only).
local hoveredPOI
function AtlasPOI:WorldMapButton_OnUpdate()
    local poi
    if not WorldMapFrame.poiHighlight and WorldMapButton:IsMouseOver() then
        for i = 1, NUM_WORLDMAP_ATLAS_POI do
            local p = _G["WorldMapFrameAtlasPOI" .. i]
            if p:IsShown() and p:IsMouseOver() then
                poi = p
                break
            end
        end
    end
    if hoveredPOI and hoveredPOI ~= poi then
        hoveredPOI:UnlockHighlight()
        if not WorldMapFrame.poiHighlight then
            WorldMapFrameAreaDescription:SetText("")
        end
    end
    hoveredPOI = poi
    if poi then
        poi:LockHighlight()
        WorldMapFrameAreaLabel:SetText(poi.name)
        WorldMapFrameAreaDescription:SetText(poi.description or "")
    end
end

function AtlasPOI:OnEnable()
    self:SecureHook("WorldMapFrame_Update")
    self:SecureHookScript(WorldMapButton, "OnUpdate", "WorldMapButton_OnUpdate") -- 3.3.5a taint fix: icon hover label
    self:AddTrackingOptions()
end

function AtlasPOI:OnDisable()
    self:UnhookAll()
    -- 3.3.5a taint fix: hide only WDM's own icons (was WorldMapFrame_Update() from addon code)
    for i = 1, NUM_WORLDMAP_ATLAS_POI do
        _G["WorldMapFrameAtlasPOI" .. i]:Hide()
    end
end