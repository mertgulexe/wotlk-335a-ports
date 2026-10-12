------------------------------------------
-- 3.3.5a COMPATIBILITY (WotLK 3.3.5a)  --
------------------------------------------

-- 3.3.5a: new file, loaded by GlobalIgnoreList.toc right after GIL_Globals.lua (the flavor
-- TOCs do not load it).  It creates no globals and patches no widget metatables: other 3.3.5a
-- addons test for C_FriendList, IsInGroup, GetServerTime, ... to detect the client, so every
-- shim stays private (addon.FL, addon.PI and file-local helpers in the other files).  A global
-- shim of that kind made by another addon is not used either.

local addonName, addon = ...
local L = addon.L -- localization entries
local V = addon.V -- shared variables
local M = addon.M -- shared methods

local _, _, _, tocVersion = GetBuildInfo()
tocVersion = tonumber(tocVersion) or 0

-- 3.3.5a: build 12340 reports 30300; Wrath Classic (30403) has the modern APIs
V.wowIs335   = (tocVersion >= 30000 and tocVersion < 30400)
V.hasLFGList = (not V.wowIs335) and (C_LFGList ~= nil and LFGListFrame ~= nil)
V.hasMenuAPI = (not V.wowIs335) and (Menu ~= nil and MenuUtil ~= nil)

-- (the name helpers M.key, M.unitKey, M.plainName and M.isPending live in GIL_Globals.lua)

---------------------------------------
-- PRIVATE FRIEND LIST AND PARTY API --
---------------------------------------

if V.wowIs335 or C_FriendList == nil then

	-- 3.3.5a: the ignore API is a set of globals.  Capture the raw C functions now, before
	-- GlobalIgnoreList.lua post-hooks the globals, so GIL's own server calls never re-enter
	-- its hooks.  GlobalIgnoreList.lua copies these helpers into its Blizzard* locals and then
	-- installs its wrappers into this private table (never into Blizzard globals).

	local rawAddIgnore      = AddIgnore
	local rawDelIgnore      = DelIgnore
	local rawAddOrDelIgnore = AddOrDelIgnore
	local rawGetNumIgnores  = GetNumIgnores
	local rawGetIgnoreName  = GetIgnoreName

	local FL = {}

	-- server calls only ever get plain own-realm names (a single-realm server cannot ignore
	-- other realms; such a call would only produce "Player not found.")
	local function send (rawFunc, name)

		name = M.plainName(name)

		if not name or name == "" or name == UNKNOWN then return false end

		V.pending[M.key(name)] = GetTime() + 15
		rawFunc(name)

		return true
	end

	FL.GetNumIgnores = function ()
		return rawGetNumIgnores()
	end

	FL.GetIgnoreName = function (index)
		return rawGetIgnoreName(index)
	end

	FL.AddIgnore = function (name)
		return send(rawAddIgnore, name)
	end

	FL.AddOrDelIgnore = function (name)
		return send(rawAddOrDelIgnore, name)
	end

	-- 3.3.5a DelIgnore only takes a name (a number would be sent as the name "3")
	FL.DelIgnore = function (nameOrIndex)

		local index = tonumber(nameOrIndex)

		if index then
			if index < 1 then return false end

			nameOrIndex = rawGetIgnoreName(index)
		end

		return send(rawDelIgnore, nameOrIndex)
	end

	-- 3.3.5a has no DelIgnoreByIndex
	FL.DelIgnoreByIndex = function (index)
		return FL.DelIgnore(tonumber(index) or 0)
	end

	addon.FL = FL
else
	addon.FL = C_FriendList
end

if V.wowIs335 or C_PartyInfo == nil then
	-- 3.3.5a: invites go through the global InviteUnit, which GIL only post-hooks (a warning);
	-- this private table keeps GIL's (now unused) invite confirmation code working
	addon.PI = { InviteUnit = InviteUnit }
else
	addon.PI = C_PartyInfo
end
