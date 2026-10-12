local _, ns = ...

-- Helpers for APIs that differ between the modern Classic clients and 3.3.5a.
-- Deliberately no globals and no widget metatable patching: other 3.3.5 addons
-- (e.g. Questie-335) feature-test methods such as SetColorTexture.
local Compat = {}
ns.Compat = Compat

local ITEM_REQUEST_INTERVAL = 0.125
local ITEM_POLL_INTERVAL = 0.5
local ITEM_REQUEST_TIMEOUT = 10
local SCAN_TOOLTIP_NAME = "AtlasLootRevivalScanTooltip"

-- 3.3.5a: textures have no SetColorTexture; SetTexture(r, g, b, a) draws a solid color.
function Compat.SetSolidColor(texture, red, green, blue, alpha)
    if texture.SetColorTexture then
        texture:SetColorTexture(red, green, blue, alpha)
    else
        texture:SetTexture(red, green, blue, alpha or 1)
    end
end

-- 3.3.5a: regions and frames have no SetShown.
function Compat.SetShown(region, shown)
    if shown then
        region:Show()
    else
        region:Hide()
    end
end

-- Sets a texture file and reports whether it loaded. 3.3.5a's SetTexture returns
-- nil for a missing file (Atlas relies on this); other clients are not checked.
function Compat.SetTextureFile(texture, path)
    local loaded = texture:SetTexture(path)
    if WOW_PROJECT_ID == nil then
        return loaded and true or false
    end
    return true
end

-- Item info for uncached items. 3.3.5a has neither C_Item nor GET_ITEM_INFO_RECEIVED,
-- and GetItemInfo never asks the server, so items are requested through a hidden
-- tooltip (one SetHyperlink per item, throttled) and then polled until they resolve.
local queue = {}
local queued = {}
local requested = {}
local pending = {}
local pendingCount = 0
local callbacks = {}
local scanTooltip
local itemFrame
local requestElapsed = 0
local pollElapsed = 0

local function IsItemCached(itemID)
    return GetItemInfo(itemID) ~= nil
end

local function GetScanTooltip()
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", SCAN_TOOLTIP_NAME, UIParent,
            "GameTooltipTemplate")
    end
    return scanTooltip
end

local function AddPending(itemID)
    if not pending[itemID] then
        pendingCount = pendingCount + 1
    end
    pending[itemID] = GetTime()
end

local function SendNextRequest()
    while #queue > 0 do
        local itemID = table.remove(queue, 1)
        queued[itemID] = nil
        if not IsItemCached(itemID) then
            requested[itemID] = true
            local tooltip = GetScanTooltip()
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            tooltip:SetHyperlink("item:" .. itemID .. ":0:0:0:0:0:0:0")
            AddPending(itemID)
            return
        end
    end
end

local function PollPending()
    local now = GetTime()
    local resolved
    for itemID, startedAt in pairs(pending) do
        local cached = IsItemCached(itemID)
        if cached or now - startedAt > ITEM_REQUEST_TIMEOUT then
            pending[itemID] = nil
            pendingCount = pendingCount - 1
            if cached then
                resolved = resolved or {}
                resolved[itemID] = true
            end
        end
    end
    if resolved then
        for _, callback in ipairs(callbacks) do
            callback(resolved)
        end
    end
end

local function OnUpdate(frame, elapsed)
    requestElapsed = requestElapsed + elapsed
    if requestElapsed >= ITEM_REQUEST_INTERVAL then
        requestElapsed = 0
        SendNextRequest()
    end

    pollElapsed = pollElapsed + elapsed
    if pollElapsed >= ITEM_POLL_INTERVAL then
        pollElapsed = 0
        PollPending()
    end

    if #queue == 0 and pendingCount <= 0 then
        frame:Hide()
    end
end

local function StartItemFrame()
    if not itemFrame then
        itemFrame = CreateFrame("Frame")
        itemFrame:Hide()
        itemFrame:SetScript("OnUpdate", OnUpdate)
    end
    if not itemFrame:IsShown() then
        requestElapsed = ITEM_REQUEST_INTERVAL
        pollElapsed = 0
        itemFrame:Show()
    end
end

-- Queues a server request for an uncached item; each item is requested once.
function Compat.RequestItemInfo(itemID)
    itemID = tonumber(itemID)
    if not itemID or requested[itemID] or queued[itemID] or IsItemCached(itemID) then
        return
    end
    queued[itemID] = true
    table.insert(queue, itemID)
    StartItemFrame()
end

-- Drops requests that have not been sent yet (e.g. rows that scrolled out of view);
-- they are queued again if they become visible.
function Compat.CancelItemRequests()
    for index = #queue, 1, -1 do
        queued[queue[index]] = nil
        queue[index] = nil
    end
end

-- Polls an item that was requested elsewhere (e.g. by a GameTooltip hover).
function Compat.WatchItemInfo(itemID)
    itemID = tonumber(itemID)
    if not itemID or IsItemCached(itemID) then
        return
    end
    AddPending(itemID)
    StartItemFrame()
end

-- callback(resolvedItemIDs) runs at most once per poll with a set of item IDs.
function Compat.RegisterItemInfoCallback(callback)
    table.insert(callbacks, callback)
end
