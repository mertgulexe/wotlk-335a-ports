----------------------------------
-- Global Ignore List Variables --
----------------------------------
local addonName, addon 	= ...
local L = addon.L -- localization entries
local V = addon.V -- shared variables
local M = addon.M -- shared methods

-- 3.3.5a: private friend list/party tables (GIL_Compat335.lua) and file-local replacements for
-- the modern group/time API.  No globals: other 3.3.5a addons use these names to detect the client
-- (and a global shim another addon made is not used: it may return 1/nil instead of booleans).
local wow335			= (V.wowIs335 == true)
local C_FriendList		= addon.FL or C_FriendList
local C_PartyInfo		= addon.PI or C_PartyInfo
local GetServerTime		= (not wow335 and GetServerTime) or time
local IsInRaid			= (not wow335 and IsInRaid) or function() return GetNumRaidMembers() > 0 end
local IsInGroup			= (not wow335 and IsInGroup) or function() return (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0) end
local GetNumGroupMembers = (not wow335 and GetNumGroupMembers) or function()
	if GetNumRaidMembers() > 0 then
		return GetNumRaidMembers()
	end
	return GetNumPartyMembers()
end

V.GIL_Loaded			= false
V.GIL_SyncOK			= false
V.GIL_SyncTried			= false
V.GIL_InSync			= false
V.lastFilterError		= false

local GILFRAME			= nil
local gotLoaded			= false
local gotUpdate			= false
local gotEntering		= false
local safeToLoad		= false
local doLoginIgnore		= true
local faction			  = nil
local maxIgnoreSize		= 50
local maxSyncTries		= 3
local maxHistorySize	= 250
local maxFilterBlocked	= 50
local firstClear		= false
local firstPrune		= false
local pruneDays			= 0
local timer				  = 0
local loadedTime		= GetTime()
local lastSentIgnore	= ""
local lastFilterMsgID	= -1
local lastFilterResult	= ""
local filterNum			= 0
local filterDefDesc		= {}
local filterDefFilter	= {}
local filterDefActive   = {}
local filterDefID		= {}
local needPartyClose	= false
local gotGroup          = IsInGroup()
local partyNameUI		= ""
local groupWarning      = {}
local MSG_LOGOFF		= ERR_FRIEND_OFFLINE_S:gsub("%%s", ".+")
local MSG_LOGON			= ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h", "|Hplayer:.+|h%%[.+%%]|h")
local filterLoginMsgs   = true
local gilFloodData		= {}
local gilFloodSize		= 50
local lastReplyTime		= {}	-- 3.3.5a: per sender, whisper auto-reply rate limit
local deferredSync		= nil	-- 3.3.5a: one-shot sync waiting for IGNORELIST_UPDATE
local deferredTries		= 0

local BlizzardAddIgnore			= nil
local BlizzardDelIgnore			= nil
local BlizzardDelIgnoreByIndex	= nil
local BlizzardAddOrDelIgnore	= nil
local BlizzardInviteUnit		= nil

----------------------------------
-- Global Ignore List Functions --
----------------------------------

function M.debugMsg (msg)
--	if GlobalIgnoreDB.showIgnoreDebug == true then
		--print("|cffffff00Global Ignore: " .. msg)
--	end
end

function M.ShowMsg (msg)
	print ("|cff33ff99Global Ignore: |cffffffff" .. (msg or "Critical error"))
end

local function OnOff (value)
	if value == nil or value == false then
		return "|cffffff00" .. L["OFF"] .. "|cffffffff"
	elseif value == true then
		return "|cffffff00" .. L["ON"] .. "|cffffffff"
	else
		return "|cffff0000nil"
	end
end

function M.dayString (value)
	if value == 1 then
		return L["DAY"]
	else
		return L["DAYS"]
	end
end

local function hasDeleted (name)

	if not name then return 0 end
	
	for count = 1, #GlobalIgnoreDB.delList do
		--M.debugMsg("Comparing " .. GlobalIgnoreDB.delList[count] .. " to " .. name)
		
		if GlobalIgnoreDB.delList[count] == name then
			M.debugMsg("Has deleted TRUE for " .. name)
			return count
		end
	end
	
	M.debugMsg("Has deleted false for " .. name)
	
	return 0
end

local function addDeleted (name)

	local idx = hasDeleted(name)
	
	M.debugMsg("addDeleted: hasDeleted " .. idx)
	
	if idx == 0 then		
		if #GlobalIgnoreDB.delList >= maxHistorySize then
			table.remove(GlobalIgnoreDB.delList, 1)
		end
		
		M.debugMsg("Adding " .. name .. " (".. idx .. ") to delete list")
		
 		GlobalIgnoreDB.delList[#GlobalIgnoreDB.delList + 1] = name
 	end
end

local function removeDeleted (name)
	local idx = hasDeleted(name)
		
	if idx > 0 then
		M.debugMsg("Removing " .. name .. " (".. idx .. ") from delete list")
		table.remove(GlobalIgnoreDB.delList, idx)
		
		local idx = hasDeleted(name)
		M.debugMsg("After removal idx " .. idx)
	end
end

local function AddToList(newname, newfaction, newnote, newtype)

	local index = #GlobalIgnoreDB.ignoreList+1
	
	GlobalIgnoreDB.ignoreList[index] = newname
	GlobalIgnoreDB.factionList[index] = newfaction
	GlobalIgnoreDB.dateList[index] = date("%d %b %Y")
	GlobalIgnoreDB.notes[index] = (newnote or "")
	GlobalIgnoreDB.expList[index] = GlobalIgnoreDB.defexpire
	GlobalIgnoreDB.typeList[index] = (newtype or "player")
	GlobalIgnoreDB.syncInfo[index] = {}

	removeDeleted(newname)
	
	M.GIL_LFG_Refresh()
end

local function RemoveFromList (index)
	local name = GlobalIgnoreDB.ignoreList[index]
	if name then
		addDeleted(name)
		
		table.remove(GlobalIgnoreDB.ignoreList, index)
		table.remove(GlobalIgnoreDB.factionList, index)
		table.remove(GlobalIgnoreDB.dateList, index)
		table.remove(GlobalIgnoreDB.notes, index)
		table.remove(GlobalIgnoreDB.expList, index)
		table.remove(GlobalIgnoreDB.typeList, index)
		table.remove(GlobalIgnoreDB.syncInfo, index)
	end
end	

local function AddToBlockHistory (filterNum, message, chNumber, chName, from)
	GlobalIgnoreDB.filterBlocked[filterNum] = GlobalIgnoreDB.filterBlocked[filterNum] or {}
	
	GlobalIgnoreDB.filterBlockedLast[filterNum] = GlobalIgnoreDB.filterBlockedLast[filterNum] or 0
	GlobalIgnoreDB.filterBlockedLast[filterNum] = GlobalIgnoreDB.filterBlockedLast[filterNum] + 1

	if GlobalIgnoreDB.filterBlockedLast[filterNum] > maxFilterBlocked then
		GlobalIgnoreDB.filterBlockedLast[filterNum] = 1
	end
	
	local timestamp = date("%Y.%m.%d %H:%M:%S", GetServerTime()) -- YYYY.MM.DD HH:MM:SS

	GlobalIgnoreDB.filterBlocked[filterNum][GlobalIgnoreDB.filterBlockedLast[filterNum]] = {
		m = message,
		c = chNumber,
		n = chName,
		i = filterNum,
		s = from,
		t = timestamp
	}
	
	M.GILUpdateBlockHistory(filterNum)
end 
	
function M.RemoveChatFilter (index)
	if GlobalIgnoreDB.filterList[index] then
		table.remove(GlobalIgnoreDB.filterList, index)
		table.remove(GlobalIgnoreDB.filterDesc, index)
		table.remove(GlobalIgnoreDB.filterCount, index)
		table.remove(GlobalIgnoreDB.filterActive, index)
		table.remove(GlobalIgnoreDB.filterID, index)
		table.remove(GlobalIgnoreDB.filterBlocked, index)
		table.remove(GlobalIgnoreDB.filterBlockedLast, index)
	end
end

local function getSyncValue (index)
	-- value, index of syncInfo data
		
	local s = ""
	local p = ""
	local v = 0
	
	for c = 1, #GlobalIgnoreDB.syncInfo[index] do
	
		s = GlobalIgnoreDB.syncInfo[index][c]
		p = string.find(s, "@", 1, true)
			
		if p > 0 then
			v = tonumber(string.sub(s, p + 1))
			s = string.sub(s, 1, p - 1)
			
			if V.playerName == s then
				return v, c				
			end
		end
	end
	
	return 0, 0
end

local function setSyncValue (name, index)

	local val,idx = getSyncValue(index)
	
	if idx == 0 then
		idx = #GlobalIgnoreDB.syncInfo[index] + 1	
	end
		
	val = val + 1
	
	--M.debugMsg("Setting "..name.. " failed add attempts to "..val)
	
	GlobalIgnoreDB.syncInfo[index][idx] = V.playerName .. "@" .. val
end		

local function isServerMatch (server1, server2)

	return M.Proper(server1) == M.Proper(server2)
end

local function hasFilterID (id)

	for count = 1, #GlobalIgnoreDB.filterDesc do
		if GlobalIgnoreDB.filterID[count] == id then
			return count
		end
	end
	
	return 0
end

local function isDefFilterID (id)

	if (id == nil or id == "") then return -1 end

	for count = 1, #filterDefID do
		if filterDefID[count] == id then
			return count
		end
	end

	return 0
end

-- 3.3.5a port: the default-filter auto-update leaves built-in filters alone that the user edited or
-- removed (it used to put the stock text back, and re-add removed filters, at every login).
-- Reset Defaults clears both lists.
function M.MarkFilterEdited (index)
	local id  = GlobalIgnoreDB.filterID[index]
	local def = isDefFilterID(id)

	if def > 0 then
		GlobalIgnoreDB.filterUserEdited = GlobalIgnoreDB.filterUserEdited or {}
		local changed = GlobalIgnoreDB.filterDesc[index] ~= filterDefDesc[def] or GlobalIgnoreDB.filterList[index] ~= filterDefFilter[def]
		GlobalIgnoreDB.filterUserEdited[id] = changed or nil
	end
end

function M.MarkFilterRemoved (index)
	local id = GlobalIgnoreDB.filterID[index]

	if isDefFilterID(id) > 0 then
		GlobalIgnoreDB.filterUserRemoved = GlobalIgnoreDB.filterUserRemoved or {}
		GlobalIgnoreDB.filterUserRemoved[id] = true
	end
end

local function hasIgnored (name)

	local result = 0
	
	name = M.Proper(M.addServer(name))
		
	for count = 1, C_FriendList.GetNumIgnores() do
	
		if name == M.Proper(M.addServer(C_FriendList.GetIgnoreName(count))) then
			result = count
			
			break
		end
	end
	
	return result
end

function M.hasNPCIgnored (name)

	if not name then return 0 end
	
	for count = 1, #GlobalIgnoreDB.ignoreList do
		if GlobalIgnoreDB.ignoreList[count] == name and GlobalIgnoreDB.typeList[count] == "npc" then
			return count
		end
	end
	
	return 0
end

local function hasServerIgnored (name)

	if not name then return 0 end
	
	for count = 1, #GlobalIgnoreDB.ignoreList do
		if GlobalIgnoreDB.ignoreList[count] == name and GlobalIgnoreDB.typeList[count] == "server" then
			return count
		end
	end
	
	return 0
end

function M.hasGroupWarning (name)

	if not name then return 0 end
	
	for count = 1, #groupWarning do
		if groupWarning[count] == name then
			return count
		end
	end

	return 0
end

function M.hasGlobalIgnored (name)

	if not name then return 0 end

	for count = 1, #GlobalIgnoreDB.ignoreList do
		if GlobalIgnoreDB.ignoreList[count] == name and GlobalIgnoreDB.typeList[count] == "player" then
			return count
		end
	end
	
	return 0
end

function M.hasAnyIgnored (name)

	if not name then return 0 end

	for count = 1, #GlobalIgnoreDB.ignoreList do
	
		if GlobalIgnoreDB.ignoreList[count] == name then
			return count
		end
	end
	
	return 0
end

local function ShowIgnoreList (param)
	local days   = tonumber(param)
	local sName  = ""
	
	if not days then
	
		days  = 0
		sName = param
		
		if not sName then
			sName = ""
		end
	end
	
	if days > 0 then
		M.ShowMsg("|cffffff00" .. format(L["LIST_1"], days))
	else
		if sName ~= "" then
			sName = M.Proper(sName)
			
			if sName == "Npc" then
				M.ShowMsg("|cffffff00".. L["LIST_2"])
			else			
				if sName == "Server" then
					sName = V.serverName
				end
				
				M.ShowMsg("|cffffff00" .. format(L["LIST_3"], sName))
			end
		else
			M.ShowMsg("|cffffff00" .. L["LIST_4"])
		end
	end
	
	local count = 0
	
	for key,value in pairs(GlobalIgnoreDB.ignoreList) do
	
		local ok   = true
		local type = "P"
		
		if GlobalIgnoreDB.typeList[key] == "npc" then
			type = "N"
		elseif GlobalIgnoreDB.typeList[key] == "server" then
			type = "S"
		end
	
		if days > 0 then
			ok = M.daysFromToday(GlobalIgnoreDB.dateList[key]) >= days
		elseif sName ~= "" then
			ok = (type == "N" and sName == "Npc") or (type == "P" and isServerMatch(sName, M.getServer(value))) or (type == "S" and isServerMatch(sName, value))
		end
		
		if ok then
			local str = "  (" .. key .. ") [" .. type.. "] " .. value .. " (" .. (GlobalIgnoreDB.factionList[key] or "Unknown") .. ") " .. "[".. M.daysFromToday(GlobalIgnoreDB.dateList[key]) .. " "..L["DAYS"] .. "]"
			
			if GlobalIgnoreDB.notes[key] ~= "" then
				str = str .." (" .. GlobalIgnoreDB.notes[key] .. ")"
			end
			
			M.ShowMsg(str)

			count = count + 1			
		end
		
	end
	
	M.ShowMsg("|cffffff00" .. format(L["LIST_5"], count))
end

function M.ResetSpamFilters()
	GlobalIgnoreDB.filterList			= {}
	GlobalIgnoreDB.filterDesc			= {}
	GlobalIgnoreDB.filterCount			= {}
	GlobalIgnoreDB.filterActive			= {}
	GlobalIgnoreDB.filterID				= {}
	GlobalIgnoreDB.filterBlocked		= {}
	GlobalIgnoreDB.filterBlockedLast	= {}
	GlobalIgnoreDB.filterUserEdited		= {} -- 3.3.5a port: see M.MarkFilterEdited
	GlobalIgnoreDB.filterUserRemoved	= {}

	GlobalIgnoreDB.invertSpam = false
	GlobalIgnoreDB.spamFilter = true
	GlobalIgnoreDB.autoUpdate = true
	
	for count = 1, #filterDefDesc do
		GlobalIgnoreDB.filterDesc[count]		= filterDefDesc[count]
		GlobalIgnoreDB.filterList[count]		= filterDefFilter[count]
		GlobalIgnoreDB.filterActive[count]		= filterDefActive[count]		
		GlobalIgnoreDB.filterID[count]			= filterDefID[count]
		GlobalIgnoreDB.filterCount[count]		= 0
		GlobalIgnoreDB.filterBlocked[count]		= {}
		GlobalIgnoreDB.filterBlockedLast[count]	= 0
	end
end

local function ResetBlizzardIgnore()
	-- 3.3.5a: no DelIgnoreByIndex, and the list only shrinks when the server answers:
	-- collect the names first, then remove them by name
	local names = {}

	for count = 1, C_FriendList.GetNumIgnores() do
		names[#names + 1] = C_FriendList.GetIgnoreName(count)
	end

	for count = 1, #names do
		BlizzardDelIgnore(names[count])
	end
end

local function ResetIgnoreDB()

	GlobalIgnoreDB = {
		chatmsg				= true,
		sameserver			= true,
		samefaction			= true,
		openWithFriends		= true,
		attachFriends 	  = true,
		trackChanges		= true,
		spamFilter			= true,
		invertSpam			= true,
		autoIgnore			= true,
		autoUpdate      	= true,
		autoCount			= 3,
		autoTime			= 600,		
		defexpire			= 0,
		ignoreList			= {},
		factionList			= {},
		dateList			= {},
		notes				= {},
		expList				= {},
		typeList			= {},  
		delList				= {},
		syncInfo			= {},
		filterTotal			= 0,
		filterCount			= {},
		filterDesc			= {},
		filterList			= {},
		filterID			= {},
		filterBlocked		= {},
		filterBlockedLast	= {},
		skipGuild			= true,
		skipParty			= false,
		skipPrivate			= true,
		skipYourself		= false,
		showIgnoreDebug		= false,
		showWarning			= false,
		useUnitHacks		= true,
		useLFGHacks			= true,
		ignoreResponse		= true,
		frameStrata			= (V.wowIs335 and 2 or 3), -- 3.3.5a: HIGH (see below)
		floodFilter			= 0, -- 0=None, 1=Name+Server+Message, 2=Message
		showDeclines		= true
	}
	
	GlobalIgnoreImported = false
	
	M.ResetSpamFilters()
end

local function isValidList()

	if C_FriendList.GetNumIgnores() > 0 then
		local str	
		local found = 0
			
		for count = 1, C_FriendList.GetNumIgnores() do
			str = M.removeServer(C_FriendList.GetIgnoreName(count), true)

			if str ~= nil and str ~= _G.UNKNOWN then
				break
			end
				
			found = found + 1
		end
 			
		if str == nil or str == _G.UNKNOWN then
			if GlobalIgnoreDB.showWarning == true then
				M.ShowMsg(format(L["LOAD_5"], found, _G.UNKNOWN))
			end
					
			return false
		end
	end
	
	return true
end

-- 3.3.5a: arm one sync for the next IGNORELIST_UPDATE.  The contact list arrives shortly after
-- login and its names can read "Unknown" until the server has resolved them.  A sync deferred
-- in the startup window (at = its end) also runs when that window ends: after a /reload the
-- client already holds the list and need not fire IGNORELIST_UPDATE again.
local deferTimer = nil

local function deferSync (silent, at)

	if deferredTries >= 5 then return end

	deferredTries = deferredTries + 1
	deferredSync  = { silent = silent, at = at }

	if at == nil then return end

	if deferTimer == nil then
		deferTimer = CreateFrame("Frame")
		deferTimer:SetScript("OnUpdate", function(self)
			local d = deferredSync

			if d == nil or d.at == nil then
				self:Hide()
				return
			end

			if GetTime() < d.at then return end

			deferredSync = nil
			self:Hide()

			if V.GIL_Loaded == true and V.GIL_SyncOK == false then
				M.SyncIgnoreList(d.silent)
			end
		end)
	end

	deferTimer:Show()
end

function M.SyncIgnoreList (silent)

	if silent == nil then
		silent = false
	end
	
	-- 3.3.5a: wait until the server list has arrived (see deferSync).  A sync is never started
	-- by IGNORELIST_UPDATE itself, because the sync's own calls fire that event.
	if V.wowIs335 and V.ignoreListSeen ~= true and GetTime() < loadedTime + 15 then
		deferSync(silent, loadedTime + 15)
		return
	end

	M.ShowMsg(L["LOAD_4"])	
	
	if isValidList() == false then
		M.debugMsg ("Invalid ignore list")	

		if V.wowIs335 then
			deferSync(silent)
		end

		return
	end
	
	V.GIL_InSync = true

	-- 3.3.5a: the server answers after this function has returned; the CHAT_MSG_SYSTEM filter
	-- keeps those replies quiet (when sync messages are off) until this time
	V.quietUntil = GetTime() + 10
	
	-- import ignore list if first time sync
	
	if GlobalIgnoreImported == nil or GlobalIgnoreImported ~= true then
	
		local ignores = C_FriendList.GetNumIgnores()	
		local added   = 0
		local name
			
		if (ignores > 0) and (silent == false) then
			M.ShowMsg(L["LOAD_2"])
		end

		M.debugMsg ("First time import, ignore size ".. ignores)
		
		for count = 1, ignores do
			
			name = C_FriendList.GetIgnoreName(count)
			
			if name ~= nil then
			
				local tmp = M.removeServer(name, true)
				
				if (tmp ~= "") and (tmp ~= _G.UNKNOWN) then
					name = M.Proper(M.addServer(C_FriendList.GetIgnoreName(count)))
					
					if M.hasGlobalIgnored(name) == 0 then
						added = added + 1
						
						AddToList(name, faction)
										
						if silent == false then
							M.ShowMsg (format(L["LOAD_3"], name))
						end
					end
				end
			end				
		end
		
		GlobalIgnoreImported = true
	end	
	
	-- first remove expired entries and fix any detected broken entries
	-- 3.3.5a: walk the list backwards and remove entries directly.  The original restarted the
	-- scan after every expiry and never ended for an expired NPC or server entry (the DelIgnore
	-- wrapper only finds players, so the entry stayed: client freeze whenever defexpire > 0), and
	-- it skipped the entry after a removed blank one.
	
	for count = #GlobalIgnoreDB.ignoreList, 1, -1 do
		
		local entry = GlobalIgnoreDB.ignoreList[count]
		local tmp   = M.removeServer(entry, true)
		
		if tmp == nil or tmp == "" then
			M.debugMsg ("Blank character name found in position " .. count);
			RemoveFromList(count)
		elseif (GlobalIgnoreDB.expList[count] or 0) > 0 and M.daysFromToday(GlobalIgnoreDB.dateList[count]) >= GlobalIgnoreDB.expList[count] then
			M.debugMsg ("Removing character "..entry.." due to expiration date")
		
			if GlobalIgnoreDB.typeList[count] == "player" and hasIgnored(entry) > 0 then
				BlizzardDelIgnore(M.removeServer(entry))
			end

			if silent == false then
				M.ShowMsg(format(L["REM_1"], entry))
			end

			RemoveFromList(count)
			V.needSorted = true
		end
	end
	
	-- find account ignores that aren't on global ignore and do things
	-- 3.3.5a: read the server list first; it only changes when the server answers

	local serverNames = {}
	
	for count = 1, C_FriendList.GetNumIgnores() do
		serverNames[count] = C_FriendList.GetIgnoreName(count) or ""
	end

	for count = 1, #serverNames do
	
		local skipRemove = false
		local name       = serverNames[count]

		if (name == "") then
			-- 3.3.5a: a blank entry cannot be removed (DelIgnore only takes a name)
			if not V.wowIs335 then
				M.debugMsg("Removing blank name on Blizzard ignore list")
				BlizzardDelIgnoreByIndex(count)
			end
		end
		
		name = M.removeServer(name, true)
		
		--print ("DEBUG got name=" .. name)
		
		if (name ~= nil and name ~= "" and name ~= _G.UNKNOWN) then
			name = M.Proper(M.addServer(serverNames[count]))
			
			local globIdx = M.hasGlobalIgnored(name)

			--print ("DEBUG got ignore position=" .. globIdx .. " for "..name)
			
			if globIdx == 0 then
				if GlobalIgnoreDB.trackChanges == true then
			
					local idx = hasDeleted(name)
					
					if idx == 0 then
						M.debugMsg ("New player "..name.. " found on character, adding to Global Ignore List")
						skipRemove = true
						-- 3.3.5a: the player is already on the server list; add to GIL only
						-- (the AddIgnore wrapper would send a second AddIgnore)
						M.GILTrackAdd(name, true)
					end
				end
			
				if skipRemove == false then

					if not silent then
						M.ShowMsg (format(L["SYNC_1"], name))
					end			
				
					M.debugMsg ("Removing "..name.." from character ignore because they are not on Global Ignore List")
				
					-- 3.3.5a: by name; there is no DelIgnoreByIndex
					BlizzardDelIgnore(M.removeServer(name))
				end
			else
				GlobalIgnoreDB.syncInfo[globIdx] = {}
			end
		end
	end
	
	if GlobalIgnoreDB.trackChanges == true then
		local listCount = 0
		
		while GlobalIgnoreDB.ignoreList[listCount] do
		
			if GlobalIgnoreDB.typeList[listCount] == "player" then
			
				local tries = getSyncValue(listCount)

				if tries >= maxSyncTries then
					M.debugMsg ("Removing "..GlobalIgnoreDB.ignoreList[listCount].." after "..tries.." failed attempts to add to ignore list")
					C_FriendList.DelIgnore(M.removeServer(GlobalIgnoreDB.ignoreList[listCount]))
					listCount = listCount - 1				
				end
			end
			
			listCount = listCount + 1
		end	
	end

	-- move qualified players to account wide ignore if there is room for it

	local ignoreCount = C_FriendList.GetNumIgnores()
	
	if ignoreCount < maxIgnoreSize then

		M.debugMsg("Moving characters from GIL to Ignore")

		for key,value in pairs(GlobalIgnoreDB.ignoreList) do
		
			if GlobalIgnoreDB.typeList[key] == "player" then
		
				local name = M.Proper(M.addServer(value))
				
				--print("DEBUG processing: ".. name .. " ignored? ".. hasIgnored(name));
				
				-- 3.3.5a: a name GIL has just sent is not on the list until the server answers
				if hasIgnored(name) == 0 and not (V.wowIs335 and M.isPending(name)) then
					local ok = (GlobalIgnoreDB.factionList[key] == faction) or (GlobalIgnoreDB.samefaction == false)

					if ok then
						-- 3.3.5a: a single-realm server only takes own-realm players, whatever
						-- the "same server" option says (other realms stay GIL-only)
						ok = (isServerMatch(V.serverName, M.getServer(name))) or (GlobalIgnoreDB.sameserver == false and not V.wowIs335)
					end
					
					if ok then
						ignoreCount = ignoreCount + 1
						
						setSyncValue(name, key)
						
						--name = M.removeServer(name)

						if not silent then
							M.ShowMsg (format(L["SYNC_2"], name))
						end					
								
						-- 3.3.5a: was BlizzardAddIgnore("Name-Realm"); the server wants the plain name
						BlizzardAddIgnore(M.removeServer(name))
					end
				end
			end
			
			if ignoreCount >= maxIgnoreSize then
				break
			end
		end
	end	

	V.GIL_InSync = false
	V.GIL_SyncOK = true
end

function M.PruneIgnoreList (days, doit)

	if days == nil or days <= 0 then		
		return 0
	end

	local targets = 0
	
	-- 3.3.5a: walk the list backwards and remove entries directly (the original restarted the
	-- scan after every removal and looped forever when a removal did not shrink the list)

	for count = #GlobalIgnoreDB.ignoreList, 1, -1 do
	
		if M.daysFromToday(GlobalIgnoreDB.dateList[count]) >= days then
			targets = targets + 1
			
			local name = GlobalIgnoreDB.ignoreList[count]
					
			--if doit ~= true then
			--	M.ShowMsg("Prune will remove: "..name)
			--end
			
			if doit == true then
				if GlobalIgnoreDB.typeList[count] == "player" then
					M.ShowMsg(format(L["REM_1"], name))

					if hasIgnored(name) > 0 then
						BlizzardDelIgnore(M.removeServer(name))
					end
				end

				RemoveFromList(count)
			end
		end
	end

	if doit == true and targets > 0 then
		V.needSorted = true
		M.GILUpdateUI(true)
	end
	
	return targets
end

local function ApplicationStartup(self)

	if V.GIL_Loaded == true or safeToLoad == false then
		return
	end
			
	-- M.ShowMsg(L["LOAD_1"]) -- login message removed on request; /gi still shows help

	-- Set filter defaults
	
	filterDefDesc[#filterDefDesc + 1]     = "Filter \"Anal\" Spammers"
	filterDefFilter[#filterDefFilter + 1] = "([word=anal] or [contains=analan]) and ([link] or [words=2])"
	filterDefActive[#filterDefActive + 1] = true
	filterDefID[#filterDefID + 1]     = "GIL0001"

	filterDefDesc[#filterDefDesc + 1]     = "Filter Thunderfury linking"
	filterDefFilter[#filterDefFilter + 1] = "[item=19019]"
	filterDefActive[#filterDefActive + 1] = true
	filterDefID[#filterDefID + 1]     = "GIL0002"

	filterDefDesc[#filterDefDesc + 1]     = "Filter Mythic+/Raid Sellers"
	filterDefFilter[#filterDefFilter + 1] = "([contains=WTS] or [contains=sell] or [contains=offer] or [contains=cheap] or [word=starting]) and ([contains=m+] or [contains=boost] or [contains=carry] or [contains=raid] or [contains=mythic] or [contains=keys] or [contains=gold\\ only] or [achievement] or [journal] or [contains=afk])"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0003"

	filterDefDesc[#filterDefDesc + 1]     = "Filter Tradeskill Sellers"
	filterDefFilter[#filterDefFilter + 1] = "([contains=LFW] or [word=trade] or [contains=order] or [contains=tip] or [contains=%] or [contains=max] or [word=free] or [contains=craft] or [word=mats] or [contains=pay]) and ([trade] or [item])"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0013"
	
	filterDefDesc[#filterDefDesc + 1]     = "Filter Power Leveling Sellers"
	filterDefFilter[#filterDefFilter + 1] = "([contains=wts] or [contains=service] or [contains=sell] or [word=fast] or [contains=afk]) and (([contains=power] or [contains=pwr]) and ([contains=level] or [contains=lvl]))"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0014"
	
	filterDefDesc[#filterDefDesc + 1]     = "Filter Guild Recruitment"
	--filterDefFilter[#filterDefFilter + 1] = "(([contains=<] and [contains=>]) or ([contains=\\[] and [contains=\\]]) or ([contains=\\(] and [contains=\\)])) and ([contains=recruit] or [contains=progress] or [contains=raid] or [contains=guild] or [contains=seek] or [contains=mythic])"
	filterDefFilter[#filterDefFilter + 1] = "(([guild] or ([contains=<] and [contains=>]) or ([contains=\\[] and [contains=\\]]) or ([contains=\\(] and [contains=\\)])) and ([contains=recruit] or [contains=progress] or [contains=raid] or [contains=guild] or [contains=seek] or [contains=mythic])) or ([contains=guild] and [contains=recruit])"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0008"

	filterDefDesc[#filterDefDesc + 1]     = "Filter Community Recruitment"
	filterDefFilter[#filterDefFilter + 1] = "[community]"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0009"

	filterDefDesc[#filterDefDesc + 1]     = "Filter WTS"
	filterDefFilter[#filterDefFilter + 1] = "[contains=WTS] or [contains=WTB]"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0010"

	filterDefDesc[#filterDefDesc + 1]     = "Filter Chinese/Korean/Japanese"
	filterDefFilter[#filterDefFilter + 1] = "[nonlatin]"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0011"

	filterDefDesc[#filterDefDesc + 1]     = "Filter American Politics"
	filterDefFilter[#filterDefFilter + 1] = "[contains=trump] or [contains=communist] or [contains=communism] or [word=president] or [contains=biden] or [word=hillary] or [word=hilary] or [contains=democrat] or [contains=republican] or [contains=liberals] or [word=maga] or [word=libs] or [contains=conservatives] or [contains=libtard] or [word=pelosi] or [word=epstein] or [word=AOC] or [word=putin] or [contains=right\\ wing] or [word=dems] or [word=socialism]"
	filterDefActive[#filterDefActive + 1] = false
	filterDefID[#filterDefID + 1]     = "GIL0012"
	
	-- When adding new defaults, make sure to assign a unique filter ID that has never been used before

	faction = UnitFactionGroup("player")

	-- 3.3.5a: every key is Proper'd; recompute now that the player name is certainly known
	V.playerName = M.Proper(M.addServer(UnitName("player")))
		
	if GlobalIgnoreDB == nil then	
		ResetIgnoreDB()
	end
	
	-- set missing defaults or upgrade if needed
	
	if GlobalIgnoreDB.sameserver == nil then
		GlobalIgnoreDB.sameserver = true
	end

	if GlobalIgnoreDB.samefaction == nil then
		GlobalIgnoreDB.samefaction = true
	end

	if GlobalIgnoreDB.chatmsg == nil then
		GlobalIgnoreDB.chatmsg = true
	end
	
	if GlobalIgnoreDB.showDeclines == nil then
		GlobalIgnoreDB.showDeclines = true
	end
	
	if GlobalIgnoreDB.showWarning == nil then
		GlobalIgnoreDB.showWarning = true
	end
	
	if GlobalIgnoreDB.showIgnoreDebug == nil then
		GlobalIgnoreDB.showIgnoreDebug = false
	end

	if GlobalIgnoreDB.skipPrivate == nil then
		GlobalIgnoreDB.skipPrivate = true
	end

	if GlobalIgnoreDB.skipParty == nil then
		GlobalIgnoreDB.skipParty = false
	end

	if GlobalIgnoreDB.skipGuild == nil then
		GlobalIgnoreDB.skipGuild = true
	end

	if GlobalIgnoreDB.skipYourself == nil then
		GlobalIgnoreDB.skipYourself = false
	end
	
	if GlobalIgnoreDB.floodFilter == nil then
		GlobalIgnoreDB.floodFilter = 0
	end
	
	if GlobalIgnoreDB.filterTotal == nil then
		GlobalIgnoreDB.filterTotal = 0
	end

	if GlobalIgnoreDB.spamFilter == nil then
		GlobalIgnoreDB.spamFilter = true
	end
	
	if GlobalIgnoreDB.invertSpam == nil then
		GlobalIgnoreDB.invertSpam = false
	end
	
	if GlobalIgnoreDB.autoIgnore == nil then
		GlobalIgnoreDB.autoIgnore = true
	end
	
	if GlobalIgnoreDB.autoUpdate == nil then
		GlobalIgnoreDB.autoUpdate = true
	end
	
	if GlobalIgnoreDB.autoCount == nil then
		GlobalIgnoreDB.autoCount = 3
	end
	
	if GlobalIgnoreDB.autoTime == nil then
		GlobalIgnoreDB.autoTime = 600
	end
	
	if GlobalIgnoreDB.filterList == nil or GlobalIgnoreDB.filterDesc == nil or GlobalIgnoreDB.filterCount == nil then
		M.ResetSpamFilters()
	end
	
	if GlobalIgnoreDB.delList == nil then
		GlobalIgnoreDB.delList = {}
	end
		
	if GlobalIgnoreDB.defexpire == nil then
		GlobalIgnoreDB.defexpire = 0
	end
	
	if not tonumber(GlobalIgnoreDB.defexpire) then
		GlobalIgnoreDB.defexpire = 0
	end
	
	if GlobalIgnoreDB.trackChanges == nil then
		GlobalIgnoreDB.trackChanges = true
	end
	
	if GlobalIgnoreDB.openWithFriends == nil then
		GlobalIgnoreDB.openWithFriends = true
	end
	
	if not GlobalIgnoreDB.attachFriends == nil then
		GlobalIgnoreDB.attachFriends = true
	end
	
	if GlobalIgnoreDB.asknote == nil then
		GlobalIgnoreDB.asknote = true
	end
		
	if GlobalIgnoreDB.expList == nil then
		GlobalIgnoreDB.expList = {}
			
		for  count = 1, #GlobalIgnoreDB.ignoreList do
			GlobalIgnoreDB.expList[count] = 0
		end
	end
	
	if GlobalIgnoreDB.useUnitHacks == nil then
		GlobalIgnoreDB.useUnitHacks = true
	end
	
	if GlobalIgnoreDB.useLFGHacks == nil then
		GlobalIgnoreDB.useLFGHacks = true
	end
	
	if GlobalIgnoreDB.ignoreResponse == nil then
		GlobalIgnoreDB.ignoreResponse = true
	end

	if GlobalIgnoreDB.frameStrata == nil then
		-- 3.3.5a: HIGH by default.  StaticPopups are DIALOG frames too, and the window's rows
		-- (higher frame levels) covered the buttons of GIL's own popups.
		GlobalIgnoreDB.frameStrata = (V.wowIs335 and 2 or 3)
	end

	if GlobalIgnoreDB.syncList then
		GlobalIgnoreDB.syncList = nil
	end
	
	if GlobalIgnoreDB.syncInfo == nil then
		GlobalIgnoreDB.syncInfo = {}
		
		for count = 1, #GlobalIgnoreDB.ignoreList do
			GlobalIgnoreDB.syncInfo[count] = {}
		end
	end
	
	if GlobalIgnoreDB.typeList == nil then
		GlobalIgnoreDB.typeList = {}
		
		for count = 1, #GlobalIgnoreDB.ignoreList do
			GlobalIgnoreDB.typeList[count] = "player"
		end
	end
	
	if GlobalIgnoreDB.revision == nil then
		GlobalIgnoreDB.revision = 1
		
		for count = 1, #GlobalIgnoreDB.ignoreList do
			GlobalIgnoreDB.ignoreList[count] = M.Proper(GlobalIgnoreDB.ignoreList[count])
		end
	end
	
	if GlobalIgnoreDB.filterActive == nil then
		GlobalIgnoreDB.filterActive = {}
		
		for count = 1, #GlobalIgnoreDB.filterDesc do
			GlobalIgnoreDB.filterActive[count] = true
		end
	end
	
	if GlobalIgnoreDB.filterID == nil then
		GlobalIgnoreDB.filterID = {}
		
		for count = 1, #GlobalIgnoreDB.filterDesc do
			GlobalIgnoreDB.filterID[count] = ""
		
			for count2 = 1, #filterDefDesc do
				if GlobalIgnoreDB.filterDesc[count] == filterDefDesc[count2] then
					GlobalIgnoreDB.filterID[count] = filterDefID[count2]
				end
			end
		end
	end

	-- Erase some old alpha data that could be out there
	if GlobalIgnoreDB.filterHistory ~= nil then
		GlobalIgnoreDB.filterHistory = nil
	end
	
	if GlobalIgnoreDB.filterBlocked == nil then
		GlobalIgnoreDB.filterBlocked = {}
		
		for count = 1, #GlobalIgnoreDB.filterDesc do
			GlobalIgnoreDB.filterBlocked[count] = {}
		end		
	end
	
	if GlobalIgnoreDB.filterBlockedLast == nil then
		GlobalIgnoreDB.filterBlockedLast = {}

		for count = 1, #GlobalIgnoreDB.filterDesc do
			GlobalIgnoreDB.filterBlockedLast[count] = 0
		end
	end

	-- 3.3.5a: CheckButton:GetChecked() returns 1/nil, and the code tests "== true"; an option
	-- that was saved as 1 means "on"
	local booleanOptions = { "chatmsg", "sameserver", "samefaction", "openWithFriends", "attachFriends",
		"trackChanges", "spamFilter", "invertSpam", "autoIgnore", "autoUpdate", "skipGuild", "skipParty",
		"skipPrivate", "skipYourself", "showIgnoreDebug", "showWarning", "useUnitHacks", "useLFGHacks",
		"ignoreResponse", "showDeclines", "asknote" }

	for count = 1, #booleanOptions do
		if GlobalIgnoreDB[booleanOptions[count]] == 1 then
			GlobalIgnoreDB[booleanOptions[count]] = true
		end
	end

	for count = 1, #GlobalIgnoreDB.filterActive do
		if GlobalIgnoreDB.filterActive[count] == 1 then
			GlobalIgnoreDB.filterActive[count] = true
		end
	end

	-- 3.3.5a: a single-realm server cannot ignore players of other realms, so only same-server
	-- players can be synchronized (see M.SyncIgnoreList)
	if V.wowIs335 then
		GlobalIgnoreDB.sameserver = true
	end

	loadedTime = GetTime()

	-- 3.3.5a: after a /reload the client already holds the server list (no IGNORELIST_UPDATE)
	if V.wowIs335 and C_FriendList.GetNumIgnores() > 0 then
		V.ignoreListSeen = true
	end
		
	--M.SyncIgnoreList(GlobalIgnoreDB.chatmsg == false)
		
	V.GIL_Loaded = true
	
	M.GIL_HookFunctions()
	
	self:UnregisterEvent("IGNORELIST_UPDATE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("ADDON_LOADED")
	
	if GlobalIgnoreDB.autoUpdate == true then
	
		-- Add new and update existing default chat filters, if enabled
		-- 3.3.5a port: except built-in filters the user edited or removed (M.MarkFilterEdited/Removed)

		local userEdited  = GlobalIgnoreDB.filterUserEdited or {}
		local userRemoved = GlobalIgnoreDB.filterUserRemoved or {}

		for count = 1, #filterDefDesc do
			local found = hasFilterID(filterDefID[count])

			if (found == 0) and userRemoved[filterDefID[count]] then
				-- removed by the user: don't add it back
			elseif (found == 0) then
				M.ShowMsg (format(L["SYNC_3"], filterDefDesc[count]))
	
				GlobalIgnoreDB.filterDesc[#GlobalIgnoreDB.filterDesc + 1]		= filterDefDesc[count]
				GlobalIgnoreDB.filterList[#GlobalIgnoreDB.filterList + 1]		= filterDefFilter[count]
				GlobalIgnoreDB.filterActive[#GlobalIgnoreDB.filterActive + 1]	= filterDefActive[count]
				GlobalIgnoreDB.filterCount[#GlobalIgnoreDB.filterCount + 1]		= 0
				GlobalIgnoreDB.filterID[#GlobalIgnoreDB.filterID + 1]			= filterDefID[count]
				GlobalIgnoreDB.filterBlocked[#GlobalIgnoreDB.filterBlocked + 1]	= {}
				GlobalIgnoreDB.filterBlockedLast[#GlobalIgnoreDB.filterBlockedLast + 1] = 0
				
			elseif not userEdited[filterDefID[count]] and (GlobalIgnoreDB.filterDesc[found] ~= filterDefDesc[count] or GlobalIgnoreDB.filterList[found] ~= filterDefFilter[count]) then
				M.ShowMsg (format(L["SYNC_5"], filterDefDesc[count]))
				
				GlobalIgnoreDB.filterDesc[found] = filterDefDesc[count]
				GlobalIgnoreDB.filterList[found] = filterDefFilter[count]
			end
		end
		
		-- Remove any old filters that are no longer used as defaults
		
		local count = 1
		
		while (count < #GlobalIgnoreDB.filterID) do
			if (isDefFilterID(GlobalIgnoreDB.filterID[count]) == 0) then
				M.ShowMsg (format(L["SYNC_4"], GlobalIgnoreDB.filterDesc[count]))
				M.RemoveChatFilter(count)
			else
				count = count + 1
			end
		end
	end
end

-------------------
-- EVENT HANDLER --
-------------------

local function EventHandler (self, event, sender, ...)

	--print ("DEBUG event=".. (event or "nil") .. " sender=" .. (sender or "nil"))
	
	--if (event == "CHANNEL_INVITE_REQUEST") then
	--	print ("DEBUG RECEIVED CHANNEL INVITE REQUEST")
	--end

	if (event == "ADDON_LOADED") and (sender == "GlobalIgnoreList") then
		gotLoaded = true
	end
	
	if event == "IGNORELIST_UPDATE" then
		gotUpdate = true
	end

	if event == "PLAYER_ENTERING_WORLD" then
		gotEntering = true
	end

	-- 3.3.5a: there is no GROUP_ROSTER_UPDATE; party and raid changes have their own events
	if (event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE") and V.GIL_Loaded == true then
		if gotGroup == true and not IsInGroup() then
			gotGroup     = false
			groupWarning = {}
		elseif IsInGroup() then
			-- 3.3.5a: also check the group that was just joined (the original only noted it)
			gotGroup = true			

			local prefix  = IsInRaid() and "raid" or "party"
			local name    = ""
			local doWarn  = false
			
			for count = 1, GetNumGroupMembers() do	
				-- 3.3.5a: GetUnitName(unit, true) gives "Name - Realm"; build the key from UnitName
				name = M.unitKey(prefix..count)
			
				if name then
					
					if M.hasGlobalIgnored(name) > 0 and M.hasGroupWarning(name) == 0 then
						doWarn = true
						groupWarning[#groupWarning + 1] = name
					end
				end
			end
			
			if doWarn then
				local nameList = ""
				
				for count = 1, #groupWarning do
					nameList = nameList .. "\n" .. groupWarning[count]
				end
				
				M.ShowMsg(format(L["CHAT_1"], #groupWarning, nameList))

				StaticPopup_Show("GIL_PARTYWARN", #groupWarning, nameList)
			end
		end		
	end
	
	if event == "PARTY_INVITE_REQUEST" and V.GIL_Loaded == true then
	
		sender = M.Proper(M.addServer(sender))

		if M.hasGlobalIgnored(sender) > 0 then
			DeclineGroup()			
			if GlobalIgnoreDB.showDeclines == true then
				M.ShowMsg (format(L["MSG_2"], sender))
			end

			StaticPopup_Hide("PARTY_INVITE")
		end
		
		return
	end
	
	if event == "GUILD_INVITE_REQUEST" and V.GIL_Loaded == true then
		sender = M.Proper(M.addServer(sender))
		
		if M.hasGlobalIgnored(sender) > 0 then
			DeclineGuild()
			if GlobalIgnoreDB.showDeclines == true then
				M.ShowMsg (format(L["MSG_4"], sender))
			end

			-- 3.3.5a: DeclineGuild() leaves UIParent's GUILD_INVITE popup open
			StaticPopup_Hide("GUILD_INVITE")
		end
		
		return
	end
	
	if event == "DUEL_REQUESTED" and V.GIL_Loaded == true then
		sender = M.Proper(M.addServer(sender))
		
		if M.hasGlobalIgnored(sender) > 0 then
			CancelDuel()
			if GlobalIgnoreDB.showDeclines == true then
				M.ShowMsg (format(L["MSG_3"], sender))
			end
		end
		
		return
	end

	if event == "TRADE_REQUEST" and V.GIL_Loaded == true then
		sender = M.Proper(M.addServer(sender))
		
		if M.hasGlobalIgnored(sender) > 0 then
			CancelTrade()
			if GlobalIgnoreDB.showDeclines == true then
				M.ShowMsg (format(L["MSG_5"], sender))
			end
		end
		
		return
	end

	if gotLoaded == true and gotEntering == true then
		if safeToLoad ~= true and gotUpdate ~= true then
		
			timer = 0
		
			self:SetScript("OnUpdate", function(Self, elapsed)
			
				timer = timer + elapsed
							
				if timer < 5 then
					return
				end
												
				self:SetScript("OnUpdate", nil)
				self:Hide()
				
				safeToLoad = true			
			end)
			
		end

		safeToLoad = true
	end	

	if safeToLoad == true then
		ApplicationStartup(self)
	end
end

------------------------
-- SPAM FILTER ENGINE --
------------------------

function M.filterComplex (filterStr, chatStr, chNumber, chName)
	-- true=should be filtered
	-- chatStr should be convered to all lower
	
	local chatData	= {}
	local itemID	= {}
	local spellID	= {}
	local achieveID = {}
	local petID     = {}
	local talentID  = {}
	local gmatch	= string.gmatch
	local sub		= string.sub
	local find		= string.find
	local lower		= string.lower
	local char		= string.char
	local len		= string.len
	local icons     = 0		
	local pos1, pos2, pos3
	
	--print("DEBUG Start="..gsub(chatStr, "\124", "\124\124"))
	
	repeat
		pos1 = find(chatStr, "|htalent:", 1, true)
		if not pos1 then break end
		
		pos2 = find(chatStr, "|h|r", pos1 + 9, true)
		if not pos2 then break end
		
		talentID[#talentID + 1] = sub(chatStr, pos1 + 9, find(chatStr, "[", pos1 + 9, true) - 1)
		
		chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos2 + 4, -1)
	until false
	
	repeat
		pos1 = find(chatStr, "|cniq", 1, true)
		if not pos1 then break end
		
		pos2 = find(chatStr, "item:", pos1+6, true)
		if not pos2 then break end
		
		pos3 = find(chatStr, "|r", pos2, true)
		if not pos3 then break end
		
		itemID[#itemID + 1] = sub(chatStr, pos2 + 5, find(chatStr, ":", pos2 + 5) - 1)

		chatStr = sub(chatStr, 1, pos1 - 1) .. sub(chatStr, pos3 + 2)
	until false
	
	repeat
		pos1 = find(chatStr, "|c", 1, true)
		if not pos1 then break end
		
		chatStr = sub(chatStr, 1, pos1 - 1) .. sub(chatStr, pos1 + 10, -1)
	until false
	
	repeat
		pos1 = find(chatStr, "|hbattlepet:", 1, true)
		if not pos1 then break end
		
		pos2 = find(chatStr, "|h|r", pos1 + 12, true)
		if not pos2 then break end
		
		petID[#petID + 1] = sub(chatStr, pos1 + 12, find(chatStr, ":", pos1+13, true) - 1)
		
		chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos2 + 4, -1)
	until false
	
	-- Is this still needed?
	repeat
		pos1 = find(chatStr, "|hitem:", 1, true)
		if not pos1 then break end
		
		pos2 = find(chatStr, "|h|r", pos1 + 8, true) or find(chatStr, "|r|h", pos1 + 8, true)
		if not pos2 then break end
		
		itemID[#itemID + 1] = sub(chatStr, pos1 + 7, (find(chatStr, ":", pos1 + 7, true) or (find(chatStr, "[", pos1 + 8, true))) - 1)
		
		chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos2 + 4, -1)	
	until false
	
	repeat
		pos1 = find(chatStr, "|hspell:", 1, true)
		if not pos1 then break end

		pos2 = find(chatStr, "|h|r", pos1 + 8, true)
		if not pos2 then break end
		
		-- 3.3.5a: spell links are |Hspell:ID|h (no colon after the ID); the original searched
		-- for a colon and took a later one or left the link in the message
		pos3 = string.match(chatStr, "^|hspell:(%d+)", pos1)
		
		if pos3 then
			spellID[#spellID + 1] = pos3
		end
--		spellID[#spellID + 1] = sub(chatStr, pos1 + 8, find(chatStr, ":", pos1 + 9, true) - 1, true)

		chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos2 + 4, -1)
	until false

	-- 3.3.5a: recipe links are |Henchant:ID|h[Tailoring: ...]|h; they count as spells
	repeat
		pos1 = find(chatStr, "|henchant:", 1, true)
		if not pos1 then break end

		pos2 = find(chatStr, "|h|r", pos1 + 10, true)
		if not pos2 then break end

		pos3 = string.match(chatStr, "^|henchant:(%d+)", pos1)

		if pos3 then
			spellID[#spellID + 1] = pos3
		end
		
		chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos2 + 4, -1)
	until false

	repeat
		pos1 = find(chatStr, "|hachievement:", 1, true)
		if not pos1 then break end
		
		pos2 = find(chatStr, "|h|r", pos1 + 14, true)
		if not pos2 then break end

		achieveID[#achieveID + 1] = sub(chatStr, pos1 + 14, find(chatStr, ":", pos1 + 15, true) - 1, true)
		
		chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos2 + 4, -1)
	until false
	
	repeat
		pos1 = find(chatStr, "{rt%d}")
		
		if pos1 then
			icons   = icons + 1
			chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 5, -1)
		else
			pos1 = find(chatStr, "{x}", 1, true)
			if pos1 then		
				icons   = icons + 1
				chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 3, -1)
			else
				pos1 = find(chatStr, "{star}", 1, true)
				if pos1 then
					icons   = icons + 1
					chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 6, -1)
				else
					pos1 = find(chatStr, "{coin}", 1, true)
					if pos1 then
						icons   = icons + 1
						chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 6, -1)
					else
						pos1 = find(chatStr, "{moon}", 1, true)
						if pos1 then
							icons   = icons + 1
							chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 6, -1)
						else		
							pos1 = find(chatStr, "{cross}", 1, true)
							if pos1 then
								icons   = icons + 1
								chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 7, -1)
							else
								pos1 = find(chatStr, "{skull}", 1, true)
								if pos1 then
									icons   = icons + 1
									chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 7, -1)
								else
									pos1 = find(chatStr, "{square}", 1, true)
									if pos1 then
										icons   = icons + 1
										chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 8, -1)
									else
										pos1 = find(chatStr, "{circle}", 1, true)
										if pos1 then
											icons   = icons + 1
											chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 8, -1)
										else
											pos1 = find(chatStr, "{diamond}", 1, true)
											if pos1 then
												icons   = icons + 1
												chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 9, -1)
											else
												pos1 = find(chatStr, "{triangle}", 1, true)
												if pos1 then
													icons   = icons + 1
													chatStr = sub(chatStr, 1, pos1 - 1) .. " " .. sub(chatStr, pos1 + 10, -1)
												else
													break
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end		
		end
		
	until false
	
	local hasGuild		= find(chatStr, "|hclubfinder:", 1, true)
	local hasTrade		= find(chatStr, "|htrade:", 1, true)
	local hasJournal	= find(chatStr, "|hjournal:", 1, true)
	local hasMount		= find(chatStr, "|hmount:", 1, true)
	local hasOutfit		= find(chatStr, "|houtfit:", 1, true)
	local hasQuest		= find(chatStr, "|hquest:", 1, true)	-- 3.3.5a link types for [link]
	local hasGlyph		= find(chatStr, "|hglyph:", 1, true)
	
	--print("After="..gsub(chatStr, "\124", "\124\124"))
	
	for word in gmatch(chatStr, "%S+") do
		word = string.gsub(word, "[%p]+$", "")
		
		if word ~= "" then
			chatData[#chatData + 1] = word
			
			--print("word="..gsub(word, "\124", "\124\124"))			
		end		
	end
	
	-----------	
	
	local filterCount = 0
	
	while (filterCount < #GlobalIgnoreDB.filterList) or (filterCount == 0 and filterStr ~= nil) do
	
		if (filterCount > 0) or ((filterCount == 0) and (filterStr == nil)) then
			filterCount = filterCount + 1
		
			if GlobalIgnoreDB.filterActive[filterCount] == true then
				filterStr = "( " .. GlobalIgnoreDB.filterList[filterCount] .. " )"
			else
				filterStr = nil
			end
		else
			filterStr = "( " .. filterStr .. " )"
		end
				
		if filterStr ~= nil then

			--print ("DEBUG BEGIN ---")
			--print ("DEBUG filterStr="..filterStr)

			local filterLen		= string.len(filterStr)
			local filterPos		= 0	
			local token			= ""
			local tokenData		= ""
			local result 		= ""
			local gotPR, gotPL	= false
			local contains		= false
			local gotEscaped	= false
			local wasEscaped	= false
			local c, c2
			local tempPos	
			local found
			
			V.lastFilterError = false
	
			while (filterPos < filterLen) and (V.lastFilterError == false) do
			
				--print("DEBUG loop ".. filterPos .. " of " .. filterLen)

				wasEscaped = false
				
				if gotPL == true then
					c     = " " 
					token = "("
					gotPL = false
				elseif gotPR == true then
					c     = " "
					token = ")"
					gotPR = false
				else
					filterPos = filterPos + 1
					
					c = strbyte(filterStr, filterPos)

					if gotEscaped == true then
						if c == 32 then
							c = " "
						elseif c == 40 then
							c = "("
						elseif c == 41 then
							c = ")"							
						elseif c == 91 then
							c = "["
						elseif c == 92 then
							c = "\\"
						elseif c == 93 then
							c = "]"
						end
						
						gotEscaped = false
						wasEscaped = true
					elseif c == 92 then
						c = ""					
						gotEscaped = true
						--print("DEBUG got escaped!")						
					elseif c < 32 or c > 126 then
						c = char(c)
					else
						c = lower(char(c))			
					end
				end

				if (wasEscaped == false and (c == " " or c == "(" or c == ")") or filterPos == filterLen) then
					if c == "(" then
						gotPL = true
					elseif c == ")" then
						gotPR = true
					elseif filterPos == filterLen and c ~= " " then
						token = token .. c
					end
									
					if token ~= "" then
						--print("DEBUG tokenStart="..token)
						tempPos = string.find(token, "=", 1, true)
					
						if tempPos then
							--print("DEBUG has extra values "..tempPos)
							tokenData = string.sub(token, tempPos+1, strlen(token)-1)
							token	  = string.sub(token, 1, tempPos-1).."]"
						else
							tokenData = ""
						end
						
						token = M.trim(token)
						
						--print("DEBUG token=#"..token.. "#")
						--print("DEBUG tokenData=#"..tokenData .. "#")
						
						if token == "(" then
							result = result..token
						elseif token == ")" then
							result = result..token
						elseif token == "not" then
							result = result .. "!"
						elseif token == "and" then
						elseif token == "or" then
							result = result.."|"
						elseif token == "[word]" then
							found = false
		
							for count = 1, #chatData do
								if chatData[count] == tokenData then
									found = true
									break
								end
							end
						
							if found == true then
								result = result .. "T"
							else
								result = result .. "F"					
							end
						elseif token == "[contains]" then
							--print("DEBUG want to filter="..chatStr)
							--print("DEBUG testing against (tokenData)="..tokenData)
							--print("DEBUG result="..(string.find(chatStr, tokenData, 1, true) or "0"))
							
							if string.find(chatStr, tokenData, 1, true) ~= nil then
								result = result .. "T"						
							else
								result = result .. "F"									
							end
						elseif token == "[chname]" then
							if chName then
								chName = lower(chName)
							else
								chName = "none"
							end
							if chName == tokenData then
								result = result .. "T"
							else
								result = result .. "F"
							end
						elseif token == "[channel]" then
							if tonumber(tokenData) == chNumber then
								result = result .. "T"
							else
								result = result .. "F"
							end								
						elseif token == "[words]" then
							if tonumber(tokenData) == #chatData then
								result = result .. "T"
							else
								result = result .. "F"	
							end		
						elseif token == "[item]" then
							if tokenData == "" then
								if #itemID > 0 then
									result = result .. "T"						
								else
									result = result .. "F"
								end
							else
								found = false
							
								for count = 1, #itemID do
									if tokenData == itemID[count] then
										found = true
										break
									end
								end
							
								if found == true then
									result = result .. "T"						
								else
									result = result .. "F"						
								end
							end
						elseif token == "[spell]" then
							if tokenData == "" then
								if #spellID > 0 then
									result = result .. "T"
								else
									result = result .. "F"						
								end
							else
								found = false
								
								for count = 1, #spellID do
									if tokenData == spellID[count] then
										found = true
										break
									end
								end
								
								if found == true then
									result = result .. "T"						
								else
									result = result .. "F"
								end
							end
						elseif token == "[achievement]" then
							if tokenData == "" then
								if #achieveID > 0 then
									result = result .. "T"
								else
									result = result .. "F"
								end
							else
								found = false
							
								for count = 1, #achieveID do
									if tokenData == achieveID[count] then
										found = true
										break
									end
								end
							
								if found == true then
									result = result .. "T"						
								else
									result = result .. "F"						
								end
							end
						elseif token == "[icon]" then
							if tokenData == "" then
								if icons > 0 then
									result = result .. "T"
								else
									result = result .. "F"
								end
							else
								if icons >= (tonumber(tokenData) or 0) then
									result = result .. "T"
								else
									result = result .. "F"
								end
							end
							
						elseif token == "[pet]" then
							if tokenData == "" then
								if #petID > 0 then
									result = result .. "T"
								else
									result = result .. "F"
								end
							else
								found = false
								
								for count = 1, #petID do
									if tokenData == petID[count] then
										found = true
										break
									end
								end
								
								if found == true then
									result = result .. "T"
								else
									result = result .. "F"
								end
							end
						
						elseif token == "[link]" then
							if #achieveID > 0 or #spellID > 0 or #itemID > 0 or #talentID > 0 or hasJournal or hasGuild or hasTrade or hasOutfit or #petID > 0 or hasMount or hasQuest or hasGlyph then
								result = result .. "T"
							else
								result = result .. "F"
							end
						elseif token == "[trade]" then
							if hasTrade then
								result = result .. "T"
							else
								result = result .. "F"
							end
						elseif token == "[guild]" then
							if hasGuild then
								result = result .. "T"
							else
								result = result .. "F"
							end
						elseif token == "[outfit]" then
							if hasOutfit then
								result = result .. "T"
							else
								result = result .. "F"
							end
						elseif token == "[journal]" then
							if hasJournal then
								result = result .. "T"
							else
								result = result .. "F"
							end
						elseif token == "[mount]" then
							if hasMount then
								result = result .. "T"
							else
								result = result .. "F"
							end
						elseif token == "[community]" then							
							if find(chatStr, "|hclubticket:", 1, true) then
								result = result .. "T"
							else
								result = result .. "F"
							end
								
						elseif token == "[nonlatin]" then
							if strfind(chatStr, "[\227-\237]") then
								result = result .. "T"
							else
								result = result .. "F"
							end
						else
							--print ("DEBUG filter error="..token .. " data="..tokenData)
							V.lastFilterError = true
						end
					
						token = ""
					end
				else
					token = token .. c
				end
			end
						
			if V.lastFilterError == false then
			
				if gotPR == true then
					result = result .. ")"
				end
			
				local p1	= 0
				local p2	= 0
				local ch1
				local ch2
				local count
				local chunk
				local slen

				--print ("DEBUG filterResult start=" .. result)
	
				while find(result, "(", 1, true) do
					p2   = 1
					slen = len(result)
		
					while sub(result, p2, p2) ~= ")" and p2 <= slen do
						if sub(result, p2, p2) == "(" then
							p1 = p2
						end
		
						p2 = p2 + 1
					end
		
					chunk = sub(result, p1 + 1, p2 - 1)
		
					--print ("DEBUG filterResult chunk=" .. chunk)
		
					while find(chunk, "!", 1, true) do
						count = find(chunk, "!", 1, true) + 1
			
						if sub(chunk, count, count) == "T" then
							chunk = sub(chunk, 0, count - 2) .. "F" .. sub(chunk, count+1, len(chunk))
						elseif sub(chunk, count, count) == "F" then
							chunk = sub(chunk, 0, count - 2) .. "T" .. sub(chunk, count+1, len(chunk))			
						end				
					end
		
					while find(chunk, "|", 1, true) do
						count = find(chunk, "|", 1, true) - 1
						ch1   = sub(chunk, count, count)
						ch2   = sub(chunk, count+2, count+2)		
			
						if (ch1 == "T" or ch1 == "F") and (ch2 == "T" or ch2 == "F") then
							if ch1 == "T" or ch2 == "T" then
								chunk = sub(chunk, 0, count-1) .. "T" .. sub(chunk, count+3, len(chunk))
							else
								chunk = sub(chunk, 0, count-1) .. "F" .. sub(chunk, count+3, len(chunk))
							end
						else					
							--print("DEBUG not valid T/F")
							chunk = sub(chunk, 0, count) .. sub(chunk, count+2, len(chunk))
						end
					end
		
					while find(chunk, "TT", 1, true) do
						count = find(chunk, "TT", 1, true)
						chunk = sub(chunk, 0, count - 1) .. sub(chunk, count + 1, len(chunk))			
					end

					while find(chunk, "FF", 1, true) do
						count = find(chunk, "FF", 1, true)
						chunk = sub(chunk, 0, count - 1) .. sub(chunk, count + 1, len(chunk))			
					end
					
					while find(chunk, "TF", 1, true) do
						count = find(chunk, "TF", 1, true)
						chunk = sub(chunk, 0, count - 1) .. sub(chunk, count + 1, len(chunk))			
					end

					while find(chunk, "FT", 1, true) do
						count = find(chunk, "FT", 1, true)
						chunk = sub(chunk, 0, count) .. sub(chunk, count + 2, len(chunk))			
					end
		
					result = sub(result, 1, p1 - 1) .. chunk .. sub(result, p2+1, len(result))
		
					--print("DEBUG filterResult after="..result)
				end	
				
				--print("DEBUG filterResult end="..result)
				
				if result == "T" or result == "T)" then
					return true, filterCount
				end
			end
				
			if (filterCount == 0) then break end			
		end
	end
	
	return false	
end

----------------------------
-- CHAT FILTERING HANDLER --
----------------------------

--local lastMsg = ""

local function chatMessageFilter (self, event, message, from, t1, t2, t3, t4, t5, chNumber, chName, t8, msgID, t10, t11, t12, ...)
	
--	print("DEBUG"..
--		"\n\tFrom: "..(from or "nil")..
--		"\n\tEvent: "..(event or "nil")..
--		"\n\tChannel Number: "..chNumber..
--		"\n\tChannel Name: "..chName..
--		"\n\tMsg ID: "..msgID..
--		"\n\tMsg: "..message..
--		"\n\tT1:"..(t1 or "nil")..
--		"\n\tT2:"..(t2 or "nil")..
--		"\n\tT3:"..(t3 or "nil")..
--		"\n\tT4:"..(t4 or "nil")..
--		"\n\tT5:"..(t5 or "nil")..
	--	"\n\tT6:"..(t6 or "nil")..
--		"\n\tT8:"..(t8 or "nil")..
--		"\n\tT10:"..(t10 or "nil")..
--		"\n\tT11:"..(t11 or "nil")..
--		"\n\tT12:"..(t12 or "nil")..
--		"\nEND"
--	)
	
	--if lastMsg ~= message then	
	--	t = string.gsub(message, "|", "!")
	--	print ("chatMsg evt=" .. (event or "nil") .. " msg=".. (t or "nil") .. " from=" .. (from or "nil"))
	--	lastMsg = message
	--end

	if event == "CHAT_MSG_SYSTEM" then		
		if message == ERR_IGNORE_FULL then
			return true
		end
	
		if doLoginIgnore == true and (GetTime() - loadedTime > 90) then
				doLoginIgnore = false
		end
				
		-- 3.3.5a: the server's answers to a sync arrive after M.SyncIgnoreList has returned
		-- (V.GIL_InSync is already false then), so also check the sync's quiet window
		if (doLoginIgnore == true) or ((V.GIL_InSync == true or (V.quietUntil or 0) > GetTime()) and GlobalIgnoreDB and GlobalIgnoreDB.chatmsg == false) then
			if message == ERR_IGNORE_NOT_FOUND or message == ERR_FRIEND_ERROR then
				return true
			end

			if
				string.find(message, string.gsub(ERR_IGNORE_ADDED_S, "%%s", ""), 1, true) or
				string.find(message, string.gsub(ERR_IGNORE_REMOVED_S, "%%s", ""), 1, true) or
				string.find(message, string.gsub(ERR_IGNORE_ALREADY_S, "%%s", ""), 1, true)
			then
				return true
			end		
		end
	end
			
	if V.GIL_Loaded ~= true then
		return false
	end
	
	if event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_MONSTER_PARTY" or event == "CHAT_MSG_MONSTER_SAY" or
	   event == "CHAT_MSG_MONSTER_WHISPER" or event == "CHAT_MSG_MONSTER_YELL" then
	   
        	return (M.hasNPCIgnored(M.Proper(from, true)) > 0)
		
	elseif event == "CHAT_MSG_SYSTEM" then
	
		if filterLoginMsgs == true and (message:find(MSG_LOGOFF) or message:find(MSG_LOGON)) then		
			local pName = ""
			
			for count = 1, #GlobalIgnoreDB.ignoreList do
			
				if GlobalIgnoreDB.typeList[count] == "server" then
			
					if string.find(message, "-"..GlobalIgnoreDB.ignoreList[count], 1, true) ~= nil then
						return true
					end
				else
					if V.serverName == M.getServer(GlobalIgnoreDB.ignoreList[count]) then
						pName = M.removeServer(GlobalIgnoreDB.ignoreList[count])
					else
						pName = GlobalIgnoreDB.ignoreList[count]
					end
				
					local msgOffline = M.strDown(string.format(ERR_FRIEND_OFFLINE_S, pName))
					local msgOnline  = M.strDown(string.format(ERR_FRIEND_ONLINE_SS, pName, pName))

					message = M.strDown(message)
					
					if (message == msgOffline) or (message == msgOnline) then
						return true
					end
				end
			end			
		end

		return false

	elseif (from ~= nil) and (from ~= "") then
		local idx = string.find(from, "-", 1, true)
		
		if idx == nil then
			from = M.Proper(from .. "-" .. V.serverName)
		else
			from = M.Proper(string.sub(from, 1, idx - 1) .. "-" ..string.sub(from, idx + 1, string.len(from)))
		end
				
		if M.hasGlobalIgnored(from) > 0 or hasServerIgnored(M.getServer(from)) > 0 then
			
			if event == "CHAT_MSG_WHISPER" then
				local temp = from .. math.ceil(GetTime() - 0.5)
				
				if (temp ~= lastSentIgnore) then
					if GlobalIgnoreDB.ignoreResponse == true then
						-- 3.3.5a: whisper the plain name ("Name-Realm" is not a player on a
						-- single-realm server; other realms cannot be whispered), at most once a
						-- minute per sender (two GIL users ignoring each other would ping-pong)
						local target = from

						if V.wowIs335 then
							target = M.plainName(from)
						end

						if target and (lastReplyTime[from] == nil or GetTime() - lastReplyTime[from] >= 60) then
							lastReplyTime[from] = GetTime()
							SendChatMessage(L["MSG_1"], "WHISPER", nil, target)
						end
					end
					lastSentIgnore = temp
				end
			end

			return true
		else
		
			if GlobalIgnoreDB.spamFilter == true then
			
				if GlobalIgnoreDB.skipGuild == true and (event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER") then
					return false
				end
				
				if GlobalIgnoreDB.skipParty == true and (
					event == "CHAT_MSG_BATTLEGROUND" or
					event == "CHAT_MSG_BATTLEGROUND_LEADER" or
					event == "CHAT_MSG_INSTANCE_CHAT" or
					event == "CHAT_MSG_INSTANCE_CHAT_LEADER" or
					event == "CHAT_MSG_PARTY" or
					event == "CHAT_MSG_PARTY_LEADER" or -- 3.3.5a: party leader chat was not covered
					event == "CHAT_MSG_RAID" or 
					event == "CHAT_MSG_RAID_LEADER" or
					event == "CHAT_MSG_RAID_WARNING"					
				) then
					return false
				end
				
				if GlobalIgnoreDB.skipPrivate == true and event == "CHAT_MSG_WHISPER" then
					return false
				end
				
				if (event == "CHAT_MSG_ACHIEVEMENT") or (event == "CHAT_MSG_GUILD_ACHIEVEMENT") then			
					return false
				end
				
				if GlobalIgnoreDB.skipYourself == true and from == V.playerName then
					return false
				end
													
				local newMsg = string.lower(message)

				-- 3.3.5a: the filter runs once per chat frame that shows the message; the result
				-- is cached per message.  Some events carry a line ID of 0, so the cache key also
				-- holds the event, sender, text and the frame time (constant within one dispatch).
				msgID = event .. "\031" .. tostring(msgID) .. "\031" .. from .. "\031" .. message .. "\031" .. GetTime()
				
				if GlobalIgnoreDB.floodFilter > 0 and lastFilterMsgID ~= msgID then						
					local text = ""

					if GlobalIgnoreDB.floodFilter == 1 then
						text = from .. newMsg
					else
						text = newMsg
					end

					if #gilFloodData > 0 then
						for i = 1, #gilFloodData do
							if gilFloodData[i] == text then
								lastFilterMsgID = msgID
								lastFilterResult = true
								return true
							end
						end

						if (#gilFloodData > gilFloodSize) then
							table.remove(gilFloodData, 1)
						end
					end

					gilFloodData[#gilFloodData+1] = text
				else
					if lastFilterMsgID == msgID then
						return lastFilterResult
					end
				end
				
				if chNumber == 0 then
					chName = string.sub(event, 10, strlen(event))
				end
				
				lastFilterMsgID = msgID
					
				lastFilterResult, filterNum = M.filterComplex(nil, newMsg, chNumber, chName)
				
				if lastFilterResult == true then
						
					if GlobalIgnoreDB.invertSpam == true then
						lastFilterResult = false
					else
						GlobalIgnoreDB.filterTotal				= GlobalIgnoreDB.filterTotal + 1
						GlobalIgnoreDB.filterCount[filterNum]	= GlobalIgnoreDB.filterCount[filterNum] + 1

						local t = M.addServer(from or _G.UNKNOWN)
						AddToBlockHistory(filterNum, message, chNumber, chName, t)

						M.GILUpdateChatCount()
					end
							
					return lastFilterResult
				end
				
				if GlobalIgnoreDB.invertSpam == true then
					GlobalIgnoreDB.filterTotal = GlobalIgnoreDB.filterTotal + 1
					
					return true
				end
			end
		end
	end		  	
	
	return false
end

-- 3.3.5a: CHANNEL_INVITE_REQUEST is not a chat message event (the filter never ran for it),
-- CHAT_MSG_INSTANCE_CHAT(_LEADER) do not exist in 3.3.5a, and CHAT_MSG_PARTY_LEADER was missing
local chatEvents = (
		{
		"CHAT_MSG_ACHIEVEMENT",
		"CHAT_MSG_BATTLEGROUND",
		"CHAT_MSG_BATTLEGROUND_LEADER",
		"CHAT_MSG_CHANNEL",
		"CHAT_MSG_CHANNEL_JOIN",
		"CHAT_MSG_CHANNEL_LEAVE",
		"CHAT_MSG_CHANNEL_NOTICE_USER",
		"CHAT_MSG_EMOTE",
		"CHAT_MSG_GUILD",
		"CHAT_MSG_GUILD_ACHIEVEMENT",	
		"CHAT_MSG_MONSTER_EMOTE",
		"CHAT_MSG_MONSTER_PARTY",
		"CHAT_MSG_MONSTER_SAY",
		"CHAT_MSG_MONSTER_WHISPER",
		"CHAT_MSG_MONSTER_YELL",
		"CHAT_MSG_OFFICER",
		"CHAT_MSG_PARTY",
		"CHAT_MSG_PARTY_LEADER",
		"CHAT_MSG_RAID",
		"CHAT_MSG_RAID_LEADER",
		"CHAT_MSG_RAID_WARNING",
		"CHAT_MSG_SAY",
		"CHAT_MSG_SYSTEM",
		"CHAT_MSG_TEXT_EMOTE",
		"CHAT_MSG_WHISPER",
		"CHAT_MSG_YELL"
		}
	)

if not V.wowIs335 then
	chatEvents[#chatEvents + 1] = "CHAT_MSG_INSTANCE_CHAT"
	chatEvents[#chatEvents + 1] = "CHAT_MSG_INSTANCE_CHAT_LEADER"
end

for key, value in pairs (chatEvents) do
	ChatFrame_AddMessageEventFilter(value, chatMessageFilter)
end

-------------------
-- CHAT COMMANDS --
-------------------

local function GILTest()
end

function M.ignoreFromCmd (argStr)
	-- 3.3.5a: M.Proper("") is nil and M.trim(nil) raised an error ("/gi add" with a target), and
	-- M.Proper removed the spaces, so "/gi add name days note" stored "Namedaysnote".  Only the
	-- name is Proper'd now; the AddIgnore wrapper parses "days note" as documented.
	local note
	argStr = M.trim(argStr or "")
	argStr, note = string.match(argStr, "^(%S*)%s*(.-)$")
	argStr = M.Proper(argStr) or ""

	local server
	if argStr == "" then
		argStr, server =  UnitName("target")
					
		if server ~= nil and server ~= "" then
			argStr = argStr .. "-"..server
		end
			
		if argStr == nil or not UnitPlayerControlled("target") then
			argStr = ""
		end
	end
		
	if argStr ~= "" then
		argStr = M.Proper(argStr)

		if note ~= "" then
			argStr = argStr .. " " .. note
		end

		C_FriendList.AddIgnore (argStr)
	end
end

function SlashCmdList.GIGNORE (msg)

	msg = M.strDown(msg)
	
	local args   = {}
	local argStr = ""
	local count  = 1

	local str = M.GetWord(msg, count)
	
	while str ~= "" do
		
		table.insert(args, str)
		
		if count == 2 then
			argStr = str
		elseif count > 2 then
			argStr = argStr .. " ".. str
		end
		
		count = count + 1
		str   = M.GetWord(msg, count)
	end
	
	if args[1] == "test" then

		GILTest()

	elseif args[1] == "clear" then
	
		if firstClear and args[2] ~= nil and args[2] == "confirm" then	
			ResetIgnoreDB()
			ResetBlizzardIgnore()
			M.ShowMsg(L["CMD_2"])
			--M.SyncIgnoreList(GlobalIgnoreDB.chatmsg == false)
			firstClear = false
		else
			M.ShowMsg("|cffff0000" .. L["CMD_1"])
			firstClear = true
		end
		
	elseif args[1] == "defexpire" then
	
		if tonumber(args[2]) then
			GlobalIgnoreDB.defexpire = tonumber(args[2])
			
			M.ShowMsg (format(L["CMD_3"], GlobalIgnoreDB.defexpire, M.dayString(GlobalIgnoreDB.defexpire)))
		end
		
	elseif msg == "asknote true" or msg == "asknote on" then
	
		GlobalIgnoreDB.asknote = true
		M.ShowMsg (L["CMD_4"])

	elseif msg == "asknote false" or msg == "asknote off" then

		GlobalIgnoreDB.asknote = false
		M.ShowMsg (L["CMD_5"])
		
	elseif msg == "showmsg true" or msg == "showmsg on" then
	
		GlobalIgnoreDB.chatmsg = true
		M.ShowMsg (L["CMD_6"])

	elseif msg == "showmsg false" or msg == "showmsg off" then
	
		GlobalIgnoreDB.chatmsg = false	
		M.ShowMsg (L["CMD_7"])
	
	elseif msg == "sameserver true" or msg == "sameserver on" then
	
		GlobalIgnoreDB.sameserver = true
		M.ShowMsg(L["CMD_10"])

	elseif msg == "sameserver false" or msg == "sameserver off" then
	
		if V.wowIs335 then
			-- 3.3.5a: a single-realm server cannot ignore players of other realms
			GlobalIgnoreDB.sameserver = true
			M.ShowMsg(L["CMD_20"])
		else
			GlobalIgnoreDB.sameserver = false
			M.ShowMsg(L["CMD_11"])
		end
		
	elseif args[1] == "list" then
	
		ShowIgnoreList(argStr)
		
	elseif (args[1] == "add" or args[1] == "ignore") then
	
		M.ignoreFromCmd(argStr)

	elseif (args[1] == "remove" or args[1] == "delete") and args[2] ~= nil and args[2] ~= "" then
	
		if tonumber(argStr) then
		
			local str = GlobalIgnoreDB.typeList[tonumber(argStr)]
			
			if str == "npc" then
				M.ShowMsg (format(L["CMD_12"], M.Proper(GlobalIgnoreDB.ignoreList[tonumber(argStr)], true)))
				RemoveFromList(tonumber(argStr))
				M.GILUpdateUI(true)
			elseif str == "server" then
				-- 3.3.5a: a realm entry went to DelIgnore, whose index fallback then removed the
				-- server list's entry with that number (an unrelated player)
				M.AddOrDelServer(tonumber(argStr))
				M.GILUpdateUI(true)
			else
				C_FriendList.DelIgnore(args[2], true)
			end
		else
			argStr = M.Proper(argStr, true)
			
			local npcIndex = M.hasNPCIgnored(argStr)
		
			if npcIndex > 0 then
				M.ShowMsg (format(L["CMD_12"], argStr))
				RemoveFromList(npcIndex)
				M.GILUpdateUI(true)
			else	
				C_FriendList.DelIgnore (args[2], true)
			end
		end
		
	elseif (args[1] == "server" or args[1] == "addserver") and args[2] ~= nil and args[2] ~= "" then

		M.AddOrDelServer(argStr)
		M.GILUpdateUI(true)

	elseif (args[1] == "npc" or args[1] == "addnpc") then
	
		M.AddOrDelNPC(argStr)
		M.GILUpdateUI(true)
		
	elseif args[1] == "expire" and args[2] ~= nil and args[2] ~= "" and tonumber(args[3]) then

		if tonumber(args[2]) then
			local index = tonumber(args[2])

			if (index > 0) and (GlobalIgnoreDB.ignoreList[index]) then
			
				GlobalIgnoreDB.expList[index] = tonumber(args[3])
				M.ShowMsg(format(L["CMD_14"], GlobalIgnoreDB.ignoreList[index], tonumber(args[3])))
			end

		else
			local name        = M.Proper(M.addServer(args[2]))
			local playerIndex = M.hasGlobalIgnored(name)

			if playerIndex > 0 then
				GlobalIgnoreDB.expList[playerIndex] = tonumber(args[3])
				M.ShowMsg(format(L["CMD_14"], name, tonumber(args[3])))
			end
		end
		
	elseif args[1] == "gui" or args[1] == "ui" then	
	
		M.GIL_GUI()
		
	elseif args[1] == "sync" then
	
		M.SyncIgnoreList(false)
		
	elseif args[1] == "dellist" then
	
		for count = 1, #GlobalIgnoreDB.delList do
			print(GlobalIgnoreDB.delList[count])
		end
		
	elseif args[1] == "prune" then
	
		if args[2] == "confirm" and firstPrune == true then
		
			M.PruneIgnoreList(pruneDays, true)
			
			firstPrune = false
		elseif args[2] == nil or tonumber(args[2]) == nil then
		
			M.ShowMsg(L["CMD_15"])
		else
			if firstPrune == false then

				pruneDays = tonumber(args[2])
				
				M.ShowMsg(format(L["CMD_16"], pruneDays))
				M.ShowMsg(format(L["CMD_17"], M.PruneIgnoreList(pruneDays, false)))
				
				firstPrune = true
			end
		end

	else
		M.ShowMsg (L["HELP_1"])
		M.ShowMsg ("")
		M.ShowMsg ("  " .. L["HELP_2"])
		M.ShowMsg ("  " .. L["HELP_3"])
		M.ShowMsg ("  " .. L["HELP_4"])
		M.ShowMsg ("  " .. L["HELP_5"])
		M.ShowMsg ("  " .. L["HELP_6"])
		M.ShowMsg ("  " .. L["HELP_7"])
		M.ShowMsg ("  " .. L["HELP_8"])
		M.ShowMsg ("  " .. L["HELP_15"])
		M.ShowMsg ("  " .. L["HELP_16"])
		M.ShowMsg ("  " .. L["HELP_9"])
		M.ShowMsg ("")
		M.ShowMsg ("  " .. format(L["HELP_10"], OnOff(GlobalIgnoreDB.chatmsg)))
		M.ShowMsg ("  " .. format(L["HELP_11"], OnOff(GlobalIgnoreDB.sameserver)))
		M.ShowMsg ("  " .. format(L["HELP_12"], GlobalIgnoreDB.defexpire))
		M.ShowMsg ("  " .. format(L["HELP_13"], OnOff(GlobalIgnoreDB.asknote)))
		M.ShowMsg ("")
		M.ShowMsg (L["HELP_14"])
	end
end

-----------------------------
-- BLIZZARD FUNCTION HOOKS --
-----------------------------

-- 3.3.5a: C_FriendList/C_PartyInfo are GIL's private tables here (GIL_Compat335.lua), so the
-- Blizzard* locals are its server helpers (plain own-realm names, index -> name) and the
-- wrappers below never replace a Blizzard global.  Blizzard's own UI is post-hooked at the end.

BlizzardInviteUnit			= C_PartyInfo.InviteUnit
BlizzardAddIgnore			= C_FriendList.AddIgnore
BlizzardDelIgnore			= C_FriendList.DelIgnore
BlizzardDelIgnoreByIndex	= C_FriendList.DelIgnoreByIndex
BlizzardAddOrDelIgnore		= C_FriendList.AddOrDelIgnore

StaticPopupDialogs["GIL_PARTYCONFIRM"] = {

	preferredIndex	= STATICPOPUPS_NUMDIALOGS or STATICPOPUP_NUMDIALOGS, -- 3.3.5a: STATICPOPUP_NUMDIALOGS
	timeout			= 0, -- 3.3.5a: StaticPopup_OnUpdate needs a number (nil raised an error every frame)
	text			= L["BOX_7"],
	button1			= L["BOX_6"],
	button2			= L["BOX_5"],
	OnAccept		= 	function()
							BlizzardInviteUnit(partyNameUI)							
						end,
	whileDead		= true,
	hideOnEscape	= true,
}

StaticPopupDialogs["GIL_PARTYWARN"] = {

	preferredIndex	= STATICPOPUPS_NUMDIALOGS or STATICPOPUP_NUMDIALOGS, -- 3.3.5a: STATICPOPUP_NUMDIALOGS
	text			= L["BOX_8"],
	button1			= L["BOX_6"],
	timeout         = 15,
	whileDead		= true,
	hideOnEscape	= true,
}

-- 3.3.5a: an invite cannot be intercepted without tainting Blizzard's invite paths; GIL warns
-- after the invite was sent instead (see the InviteUnit hook at the end of this file)
StaticPopupDialogs["GIL_INVITEWARN"] = {

	preferredIndex	= STATICPOPUPS_NUMDIALOGS or STATICPOPUP_NUMDIALOGS,
	text			= L["BOX_14"],
	button1			= L["BOX_6"],
	timeout         = 15,
	whileDead		= true,
	hideOnEscape	= true,
}

C_PartyInfo.InviteUnit = function (name)

	name = M.Proper(name)
	
	if M.hasGlobalIgnored(M.addServer(name)) > 0 then
		partyNameUI = name
		
		StaticPopup_Show("GIL_PARTYCONFIRM", partyNameUI)
	else
		BlizzardInviteUnit(name)
	end
end

C_FriendList.AddIgnore = function(name, noNote)

	local okDisplay = true
	
	if (V.GIL_InSync == true and GlobalIgnoreDB.chatmsg == false) then
		okDisplay = false
	end

	--print("DEBUG: Info sent to C_FriendList.AddIgnore name="..(name or "nil") .. " note="..(noNote or "nil"))
	local server
	if (not name or name == "") then

		name, server = UnitName("target")
					
		if name and server ~= nil and server ~= "" then -- 3.3.5a: own-realm server can be ""
			name = name .. "-"..server
		end
	end
	
	if (not name or name == "") then
		return
	end

	local note  = ""
	local space = string.find(name, " ")
	local days  = GlobalIgnoreDB.defexpire
	
	if space then
		note = string.sub(name, space + 1)
		name = string.sub(name, 0, space - 1)
		
		space = string.find(note, " ")
		
		if space then
			if tonumber(string.sub(note, 0, space - 1)) then
				days = tonumber(string.sub(note, 0, space - 1))
				note = string.sub(note, space + 1)
			end
		else
			if tonumber(note) then
				days = tonumber(note)
				note = ""
			end
		end
	end
	
	V.needSorted = true
	name	   = M.Proper(M.addServer(name))
	
	local tmp = M.removeServer(name, true)
	if (tmp == "") or (tmp == _G.UNKNOWN) then return end
		
	if M.Proper(M.addServer(UnitName("player"))) ~= name then
	
		local index = M.hasGlobalIgnored(name)
	
		if index == 0 then
			AddToList(name, faction, note)

			-- 3.3.5a: "name days note" parsed the days but never stored them
			GlobalIgnoreDB.expList[#GlobalIgnoreDB.ignoreList] = days
			
			if GlobalIgnoreDB.asknote == true and not noNote then
			
				V.nameUI = name
				StaticPopup_Show("GIL_REASON", V.nameUI)
			end

			if okDisplay == true then 
				M.ShowMsg(format(L["ADD_2"], name))
			end
			
			if C_FriendList.GetNumIgnores() < maxIgnoreSize then
				BlizzardAddIgnore(M.removeServer(name))
			end
		else
			if hasIgnored(name) > 0 then
				if okDisplay == true then
					M.ShowMsg(format(L["ADD_1"], name))
				end
			end

			if C_FriendList.GetNumIgnores() < maxIgnoreSize then			
				BlizzardAddIgnore(M.removeServer(name))
			end
		end
		
		--removeDeleted(name)
		
		M.GILUpdateUI()
	else
		if okDisplay == true then
			M.ShowMsg(L["ADD_3"])
		end
	end	
end

C_FriendList.DelIgnoreByIndex = function (name)
	--print("DEBUG C_FriendList.DelIgnoreByIndex: "..(name or "nil"))
	C_FriendList.DelIgnore(name)
end

C_FriendList.DelIgnore = function(idxpos, isGIL)

	--print ("DEBUG C_FriendList.DelIgnore idx="..(idxpos or "nil"))

	local okDisplay = true
	
	if (V.GIL_InSync == true and GlobalIgnoreDB.chatmsg == false) then
		okDisplay = false
	end
	
	local name = ""
	
	if isGIL then
		if tonumber(idxpos) ~= nil then
			name = GlobalIgnoreDB.ignoreList[tonumber(idxpos)]
			
			if name == nil then
				return
			end
		else
			name = idxpos
		end
	else
		if tonumber(idxpos) ~= nil then			
			name = C_FriendList.GetIgnoreName(idxpos)
		else
			name   = idxpos
			idxpos = hasIgnored(name)
		end
	end

	if (name == nil or name == "") then
		return
	end
	
	V.needSorted = true
	name 	   = M.Proper(M.addServer(name))
	
--	if M.removeServer(name, true) ~= _G.UNKNOWN then

		--addDeleted(name)
	
		local index = M.hasGlobalIgnored(name)

		if index > 0 then
			if okDisplay == true then
				M.ShowMsg(format(L["REM_1"], name))
			end
		
			RemoveFromList(index)		
		
			name = M.removeServer(name)
		
			if hasIgnored(name) > 0 then
				BlizzardDelIgnore(name)
			else
				M.GILUpdateUI()
			end
		elseif not (isGIL and tonumber(idxpos)) then
			-- 3.3.5a: never pass a GIL index on; the server helper reads a number as a server
			-- list index (GetIgnoreName(n)) and would remove an unrelated player
			BlizzardDelIgnore(idxpos)
		end
--	end

	M.GILUpdateUI()
end

C_FriendList.AddOrDelIgnore = function(name)
	
	--print ("DEBUG C_FriendList.AddOrDel called with: "..(name or "nil"))
	local server
	if (not name or name == "") then

		name, server = UnitName("target")
					
		if name and server ~= nil and server ~= "" then -- 3.3.5a: own-realm server can be ""
			name = name .. "-"..server
		end
	end

	-- 3.3.5a: without a name and a target, find(nil) below raised an error
	if (not name or name == "") then
		return
	end
	
	local find = string.find
	local sub  = string.sub
	
	-- try to resolve server if there isn't one due to Blizzard bugs
	-- 3.3.5a: skipped.  Chat frames have no historyBuffer (error on every call), and on a
	-- single-realm server a name without "-" is an own-realm name (M.addServer below).
	
	if not V.wowIs335 and not find(name, "-", nil, true) then
		local pServers = {}
		local pServer  = ""
		local tempName, count
		
		-- check group for a name
		
		if gotGroup == true then
			local prefix = IsInRaid() and "raid" or "party"

			for count = 1, GetNumGroupMembers() do	
				tempName = GetUnitName(prefix..count, true)
			
				if tempName then
					if M.removeServer(tempName, true) == name then
						pServer = M.Proper(M.getServer(tempName), "")
						--print ("DEBUG matched name: "..name)
						
						if pServer ~= "" then
							--print ("DEBUG adding possible server by group="..pServer)
							pServers[#pServers + 1] = pServer
						end
					end
				end
			end
		end
		
		-- check chat history for a name
		
		for count = 1, 20 do
			local frameName = "ChatFrame"..count
			
			if _G[frameName] then
				local msg, pos
			
				for c = 1, _G[frameName].historyBuffer:GetNumElements() do
					msg = _G[frameName].historyBuffer:GetEntryAtIndex(_G[frameName].historyBuffer:GetNumElements() - c + 1).message
					pos = find(msg, "|Hplayer:", 1, true)
					--t = string.gsub(msg, "|", "!")
				
					if pos then
						--print("RAW="..t);
						--tempName = sub(msg, pos + 9, find(msg, ":", pos + 10, true) - 1, true)
		                tempName = sub(msg, pos + 9, (find(msg, ":", pos + 9, true) or (find(msg, "|", pos + 10, true))) - 1)
						
						
						if M.removeServer(tempName, true) == name then
							--print ("DEBUG matched name: "..name)
							
							pServer = M.Proper(M.getServer(tempName), "")
						
							if pServer ~= "" then
								--print("DEBUG Adding possible server name by chat="..pServer)
								pServers[#pServers + 1] = pServer
							end
						end
					end
				end
			end
		end
		
		if pServer ~= "" then
			name = name .. "-" .. pServer
		end
		
		--print("FINAL="..pServer.. " name="..name)
		--M.ShowMsg (L["ADD_4"])
	end

	if (not name or name == "") then
		return
	end
	
	name = M.Proper(M.addServer(name))
	
	if M.removeServer(name, true) == _G.UNKNOWN then return end

	local index = M.hasGlobalIgnored(name)

	if index == 0 then
		--print("DEBUG calling AddIgnore="..(name or "nil"))
		
		C_FriendList.AddIgnore(name)
	else
		C_FriendList.DelIgnore(index, true)
		--print("DEBUG calling DelIgnore="..(index or "nil"))
		
	end	
end

-- 3.3.5a: add a player to GIL that is already on the server list, or that Blizzard's own UI just
-- sent to the server.  Unlike the AddIgnore wrapper this never calls the server.
function M.GILTrackAdd (name, noNote)

	name = M.key(name)

	if not name then return end

	local tmp = M.removeServer(name, true)

	if (tmp == "") or (tmp == _G.UNKNOWN) or name == V.playerName then return end

	if M.hasGlobalIgnored(name) > 0 then return end

	V.needSorted = true

	AddToList(name, faction, "")

	if GlobalIgnoreDB.asknote == true and not noNote then
		V.nameUI = name
		StaticPopup_Show("GIL_REASON", V.nameUI)
	end

	if not (V.GIL_InSync == true and GlobalIgnoreDB.chatmsg == false) then
		M.ShowMsg(format(L["ADD_2"], name))
	end

	M.GILUpdateUI()
end

-- 3.3.5a: remove a player from GIL after Blizzard's own UI removed it from the server list
function M.GILTrackDel (name)

	name = M.key(name)

	local index = M.hasGlobalIgnored(name)

	if index == 0 then return end

	V.needSorted = true

	RemoveFromList(index)

	M.ShowMsg(format(L["REM_1"], name))

	M.GILUpdateUI()
end

M.AddOrDelNPC = function (argStr)
	
	if tonumber(argStr) then
	
		local nIndex = tonumber(argStr)
		
		if (nIndex > 0) and (GlobalIgnoreDB.ignoreList[nIndex]) and (GlobalIgnoreDB.typeList[nIndex] == "npc") then
				
			M.ShowMsg (format(L["CMD_12"], GlobalIgnoreDB.ignoreList[nIndex]))
			RemoveFromList(nIndex)
		end
	else
		
		if argStr ~= "" then
			argStr = (M.trim(M.Proper(argStr, true)) or "")
		end
		
		if argStr == "" then
			argStr = M.Proper(UnitName("target"), true)
				
			if argStr == nil or UnitPlayerControlled("target") then
				argStr = ""
			end
		end
			
		if argStr ~= "" then

			local npcIndex = M.hasNPCIgnored(argStr)
		
			if npcIndex > 0 then
				local name = GlobalIgnoreDB.ignoreList[npcIndex]
			
				M.ShowMsg (format(L["CMD_12"], name))
				RemoveFromList(npcIndex)
			else
				M.ShowMsg (format(L["CMD_13"], argStr))
				AddToList(argStr, faction, "", "npc")
			end
		end
	end
end

M.AddOrDelServer = function (sName)

	if not sName then return end

	if tonumber(sName) then
	
		local sIndex = tonumber(sName)
		
		if (sIndex > 0) and (GlobalIgnoreDB.ignoreList[sIndex]) and (GlobalIgnoreDB.typeList[sIndex] == "server") then
		
			M.ShowMsg(format(L["CMD_19"], GlobalIgnoreDB.ignoreList[sIndex]))
			RemoveFromList(sIndex)
		end
	
	else
	
		sName = M.Proper(sName)
		
		local sIndex = hasServerIgnored(sName)
		
		if sIndex > 0 then
		
			M.ShowMsg(format(L["CMD_19"], sName))
			RemoveFromList(sIndex)
	
		else
		
			M.ShowMsg(format(L["CMD_18"], sName))
			AddToList(sName, faction, "", "server")
		end
	end
end

-----------------------------
-- Global Ignore List Main --
-----------------------------

GILFRAME = CreateFrame("FRAME")

GILFRAME:RegisterEvent("PLAYER_ENTERING_WORLD")
GILFRAME:RegisterEvent("ADDON_LOADED")
GILFRAME:RegisterEvent("IGNORELIST_UPDATE")
GILFRAME:RegisterEvent("PARTY_INVITE_REQUEST")
GILFRAME:RegisterEvent("DUEL_REQUESTED")
GILFRAME:RegisterEvent("GUILD_INVITE_REQUEST")
GILFRAME:RegisterEvent("TRADE_REQUEST")

if V.wowIs335 then
	-- 3.3.5a: no GROUP_ROSTER_UPDATE
	GILFRAME:RegisterEvent("PARTY_MEMBERS_CHANGED")
	GILFRAME:RegisterEvent("RAID_ROSTER_UPDATE")
else
	GILFRAME:RegisterEvent("GROUP_ROSTER_UPDATE")
end

SLASH_GIGNORE1		= "/gignore"
SLASH_GIGNORE2		= "/gi"
SLASH_GIGNORE3		= "/gil"

GILFRAME:SetScript("OnEvent", EventHandler)

-----------------------------------------
-- 3.3.5a: BLIZZARD IGNORE UI AND SYNC --
-----------------------------------------

if V.wowIs335 then

	-- IGNORELIST_UPDATE: remember that the server list has arrived and run a sync that was
	-- deferred until then (once).  GILFRAME stops listening at startup, so this has its own frame.
	-- A sync is never started by every update: the sync's own calls fire this event.
	local listFrame = CreateFrame("Frame")

	listFrame:RegisterEvent("IGNORELIST_UPDATE")
	listFrame:SetScript("OnEvent", function(self, event)
		V.ignoreListSeen = true

		if deferredSync and V.GIL_Loaded == true then
			local silent = deferredSync.silent

			deferredSync = nil

			if V.GIL_SyncOK == false then
				M.SyncIgnoreList(silent)
			end
		end
	end)

	-- Blizzard's own ignore UI (/ignore, /unignore, the Friends frame buttons and its ADD_IGNORE
	-- popup, the chat name menu) calls the global AddIgnore/DelIgnore/AddOrDelIgnore.  Replacing
	-- them would taint UnitPopup_OnClick, ChatEdit_ParseText and the FriendsFrame handlers, so they
	-- are post-hooked and the change is mirrored into GIL (no server call: Blizzard sent it).
	-- GIL's own server calls use the raw functions captured in GIL_Compat335.lua and do not come here.
	local function blizzardKey (name)
		if type(name) == "number" then
			name = C_FriendList.GetIgnoreName(name)
		end

		if name == nil or name == "" then
			if UnitIsPlayer("target") then
				return M.unitKey("target")
			end

			return nil
		end

		return M.key(string.match(tostring(name), "^%s*(%S+)"))
	end

	hooksecurefunc("AddIgnore", function(name)
		if V.GIL_Loaded ~= true then return end

		M.GILTrackAdd(blizzardKey(name))
	end)

	hooksecurefunc("DelIgnore", function(name)
		if V.GIL_Loaded ~= true then return end

		M.GILTrackDel(blizzardKey(name))
	end)

	hooksecurefunc("AddOrDelIgnore", function(name)
		if V.GIL_Loaded ~= true then return end

		local key = blizzardKey(name)

		-- the server list only changes when the server answers, so it still shows the old state
		if key and hasIgnored(key) > 0 then
			M.GILTrackDel(key)
		else
			M.GILTrackAdd(key)
		end
	end)

	-- the server's confirmations, for changes the hooks did not see (another addon calling the
	-- raw functions, or AddOrDelIgnore's direction).  It calls the server in one case only (a
	-- late confirmation of a player GIL has removed since); that call is pending, so the answer
	-- to it ends here and nothing can loop.
	local function systemPattern (str)
		str = string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		str = string.gsub(str, "%%%%s", "(.+)")

		return "^" .. str .. "$"
	end

	local PAT_ADDED   = systemPattern(ERR_IGNORE_ADDED_S)
	local PAT_REMOVED = systemPattern(ERR_IGNORE_REMOVED_S)
	local systemFrame = CreateFrame("Frame")

	systemFrame:RegisterEvent("CHAT_MSG_SYSTEM")
	systemFrame:SetScript("OnEvent", function(self, event, message)
		if V.GIL_Loaded ~= true or type(message) ~= "string" then return end

		local name = string.match(message, PAT_ADDED)

		if name then
			local key = M.key(name)

			if not M.isPending(key) then
				M.GILTrackAdd(name, true)
			elseif M.hasGlobalIgnored(key) == 0 and hasDeleted(key) > 0 then
				-- GIL's add was confirmed after the player had been removed from GIL again.  The
				-- removal could not reach the server earlier (DelIgnore only finds names that are
				-- already on the list), so send it now; its answer is pending and ends here.
				BlizzardDelIgnore(M.removeServer(key))
			end

			return
		end

		name = string.match(message, PAT_REMOVED)

		if name and not M.isPending(M.key(name)) then
			M.GILTrackDel(name)
		end
	end)

	-- invites: overriding InviteUnit would taint Blizzard's invite paths (unit menu, /invite), so
	-- GIL can only warn after the invite was sent (the unit menu also shows a warning line)
	hooksecurefunc("InviteUnit", function(name)
		if V.GIL_Loaded ~= true or type(name) ~= "string" or name == "" then return end

		local key

		if UnitExists(name) then
			key = M.unitKey(name)
		else
			key = M.key(name)
		end

		if key and M.hasGlobalIgnored(key) > 0 then
			M.ShowMsg(format(L["CHAT_2"], M.removeServer(key)))
			StaticPopup_Show("GIL_INVITEWARN", M.removeServer(key))
		end
	end)
end

-------------
-- THE END --
-------------
