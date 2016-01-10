-----------------------------------------------------------------------------------------------
-- Client Lua Script for SoeysFriends
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- SoeysFriends Module Definition
-----------------------------------------------------------------------------------------------
local SoeysFriends = {} 

-----------------------------------------------------------------------------------------------
-- OneVersion Versioning
-----------------------------------------------------------------------------------------------
-- for OneVersion see: 
--   http://www.curse.com/ws-addons/wildstar/231062-oneversion
-- for Suffix Numbers see:
--   https://github.com/NexusInstruments/1Version/wiki/OneVersion_ReportAddonInfo-event#suffix-list

local Major, Minor, Patch, Suffix = 1, 0, 1, 0

local SOEYSFRIENDS_CURRENT_VERSION = string.format("%d.%d.%d", Major, Minor, Patch)
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function SoeysFriends:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function SoeysFriends:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- SoeysFriends OnLoad
-----------------------------------------------------------------------------------------------
function SoeysFriends:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("SoeysFriends.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.Rover = Apollo.GetAddon("Rover");

	self.tAccountFriends = {}	
	self.tAccountFriendsCurrentChar = {}

	self:InitCachedAccountFriends();
    Apollo.RegisterEventHandler("FriendshipAccountDataUpdate", "OnFriendshipAccountDataUpdate", self)

	-- report Addon Version to OneVersion
	Event_FireGenericEvent("OneVersion_ReportAddonInfo", "SoeysFriends", Major, Minor, Patch, Suffix, false)
end

-----------------------------------------------------------------------------------------------
-- SoeysFriends OnDocLoaded
-----------------------------------------------------------------------------------------------
function SoeysFriends:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "SoeysFriendsForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
	    self.xmlDoc = nil;	    
	end
end

-----------------------------------------------------------------------------------------------
-- SoeysFriends Functions
-----------------------------------------------------------------------------------------------

function SoeysFriends:OnFriendshipAccountDataUpdate(nAccountFriendId)	
	self:UpdateCachedAccountFriends();
	
	local tAccountFriend = self.tAccountFriends[nAccountFriendId];
	if(tAccountFriend == nil) then 
		return;
	end
	
	self:CheckAccountFriendStatusChange(tAccountFriend, false);
end

function SoeysFriends:InitCachedAccountFriends()
	self:UpdateCachedAccountFriends();

	for k, tAccountFriend in pairs(self.tAccountFriends) do	
		self:CheckAccountFriendStatusChange(tAccountFriend, true);
	end
end

-- Update Cached Account Friend Data
function SoeysFriends:UpdateCachedAccountFriends() 
	local tAccountList = FriendshipLib:GetAccountList() or {}	
	
    for k, tAccountFriend in pairs(tAccountList) do	
		self.tAccountFriends[tAccountFriend.nId] = tAccountFriend;
	end
end

-- Compare Cached Account Friend status to changed data
function SoeysFriends:CheckAccountFriendStatusChange(tAccountFriend, bSilent)
	if tAccountFriend.arCharacters then
		if(self.tAccountFriendsCurrentChar[tAccountFriend.nId] == nil and bSilent ~= true) then
			self:OnAccountFriendNowOnline(tAccountFriend, tAccountFriend.arCharacters[1]);
		end
		self.tAccountFriendsCurrentChar[tAccountFriend.nId] = tAccountFriend.arCharacters[1];
	else
		if(self.tAccountFriendsCurrentChar[tAccountFriend.nId] ~= nil and bSilent ~= true) then
			self:OnAccountFriendNowOffline(tAccountFriend, self.tAccountFriendsCurrentChar[tAccountFriend.nId]);
		end
		self.tAccountFriendsCurrentChar[tAccountFriend.nId] = nil;
	end
end

-- Fires the SoeysFriends_AccountFriendOnline event and displays a message
function SoeysFriends:OnAccountFriendNowOnline(tAccountFriend, tAccountFriendsCharacter)
	Event_FireGenericEvent("SoeysFriends_AccountFriendOnline", tAccountFriend, tAccountFriendsCharacter);
	
	local msg = String_GetWeaselString(Apollo.GetString("Friends_HasComeOnline"), tAccountFriend.strCharacterName .. " (" .. tAccountFriendsCharacter.strCharacterName .. ")");
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, msg, "Account Friend");
	Sound.Play(Sound.PlayUISocialFriendAlert);
end

-- Fires the SoeysFriends_AccountFriendOffline event and displays a message
function SoeysFriends:OnAccountFriendNowOffline(tAccountFriend, tAccountFriendsCharacter)
	Event_FireGenericEvent("SoeysFriends_AccountFriendOffline", tAccountFriend, tAccountFriendsCharacter);
	
	local msg = String_GetWeaselString(Apollo.GetString("Friends_HasGoneOffline"), tAccountFriend.strCharacterName .. " (" .. tAccountFriendsCharacter.strCharacterName .. ")");
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, msg, "Account Friend");
	Sound.Play(Sound.PlayUISocialFriendAlert);
end

-----------------------------------------------------------------------------------------------
-- SoeysDebugPrint
--   prints the type and content of a variable to Debug Chat
--   even works recursively for tables and metatables
-----------------------------------------------------------------------------------------------

function SoeysDebugPrint(strLabel, var, nIndent) 
	if nIndent== nil then
		nIndent= 0;
	end		
			
	local strIndent = "";

	for i=1, nIndent do 
		strIndent = strIndent .. "    ";
	end
	
	if type(var) == "table" or type(var) == "metatable" then			
		Print(strIndent .. strLabel.. " (" .. type(var) .. "): ");	
		for strLabelSub, varSub in pairs(var) do	
			SoeysDebugPrint(strLabelSub, varSub , nIndent + 1);		
		end		
	else 		
		if(var == nil) then
			Print(strIndent .. strLabel.. " (" .. type(var) .. "): nil");
		else
			Print(strIndent .. strLabel.. " (" .. type(var) .. "): '" .. tostring(var) .. "'");	
		end
	end
end



-----------------------------------------------------------------------------------------------
-- SoeysFriendsForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function SoeysFriends:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function SoeysFriends:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- SoeysFriends Instance
-----------------------------------------------------------------------------------------------
local SoeysFriendsInst = SoeysFriends:new()
SoeysFriendsInst:Init()
