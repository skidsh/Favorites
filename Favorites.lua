Favorites = LibStub("AceAddon-3.0"):NewAddon("Favorites", "AceEvent-3.0", "AceHook-3.0","AceConsole-3.0")
local defaults = {
  profile = {
	colorBackground = false,
	classColorOppositeFaction = false,
	showLevel = false,
	showClass = false,
 	classColorOtherProject = 1,
	favTypes = {
		["Favorites"] = {	},
	},
	favBTs = {	}
  }
}
ADD_FAVORITE_STATUS = "Add to Blizzard Favorites"
REMOVE_FAVORITE_STATUS = "Remove from Blizzard Favorites"
UnitPopupButtons["BN_ADD_FAVORITE"]	= { text = ADD_FAVORITE_STATUS, };
UnitPopupButtons["BN_REMOVE_FAVORITE"]	= { text = REMOVE_FAVORITE_STATUS, };
local friendSearchValue = ""
local old = FriendsFrame_UpdateFriendButton
local oldFLU = FriendsList_Update
local oldFriendsList_GetScrollFrameTopButton = FriendsList_GetScrollFrameTopButton
local oldFriendsFrame_UpdateFriends = FriendsFrame_UpdateFriends
local FriendListEntries = { }
local BNET_HEADER_TEXT = 6;
local BNET_SEARCH = 20;
FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_DIVIDER] = 10
FRIENDS_BUTTON_HEIGHTS[BNET_HEADER_TEXT] = 25;
FRIENDS_BUTTON_HEIGHTS[BNET_SEARCH] = 25;
local ONE_MINUTE = 60;
local ONE_HOUR = 60 * ONE_MINUTE;
local ONE_DAY = 24 * ONE_HOUR;
local ONE_MONTH = 30 * ONE_DAY;
local ONE_YEAR = 12 * ONE_MONTH;
-- local ONE_MILLENIUM = 1000 * ONE_YEAR; 	for the future
local INVITE_RESTRICTION_NO_GAME_ACCOUNTS = 0;
local INVITE_RESTRICTION_CLIENT = 1;
local INVITE_RESTRICTION_LEADER = 2;
local INVITE_RESTRICTION_FACTION = 3;
local INVITE_RESTRICTION_REALM = 4;
local INVITE_RESTRICTION_INFO = 5;
local INVITE_RESTRICTION_WOW_PROJECT_ID = 6;
local INVITE_RESTRICTION_WOW_PROJECT_MAINLINE = 7;
local INVITE_RESTRICTION_WOW_PROJECT_CLASSIC = 8;
local INVITE_RESTRICTION_NONE = 9;
local INVITE_RESTRICTION_MOBILE = 10;
local currentFaction = UnitFactionGroup("player");


function Favorites:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("favsDB", defaults, true)
	self:SetupOptions()
end

local function FriendsList_UpdateFIX(forceUpdate)

    local numBNetTotal, numBNetOnline, numBNetFavorite, numBNetFavoriteOnline = BNGetNumFriends();
	local numBNetOffline = numBNetTotal - numBNetOnline;
	local numBNetFavoriteOffline = numBNetFavorite - numBNetFavoriteOnline;
	local numWoWTotal = C_FriendList.GetNumFriends();
	local numWoWOnline = C_FriendList.GetNumOnlineFriends();
	local numWoWOffline = numWoWTotal - numWoWOnline;

	QuickJoinToastButton:UpdateDisplayedFriendCount();
	if ( not FriendsListFrame:IsShown() and not forceUpdate) then
		return;
	end
	local addButtonIndex = 0;
	local totalButtonHeight = 0;
	local function AddButtonInfo(buttonType, id, favName, bnSep, overrideTitle)
		if not (friendSearchValue == "") then
			if (buttonType == BNET_HEADER_TEXT and not (overrideTitle == "Search Results")) then
				return
			end
			local na = nil
			local class = nil
			if ( buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
				_, _, na, _, ca, _, _, _ = BNGetFriendInfo(id);
				class = C_BattleNet.GetFriendAccountInfo(id).gameAccountInfo.className;
			elseif ( buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
				local info = C_FriendList.GetFriendInfoByIndex(id);
				na = info.name;
				class = info.className;
			end
			if (class and (RAID_CLASS_COLORS[string.upper(friendSearchValue)] ~= nil)) then
				if (not string.find(string.lower(class), string.lower(friendSearchValue))) then
					return
				end
			else
				if (na and ca) and (not string.find(string.lower(na), string.lower(friendSearchValue)) and ca and not string.find(string.lower(ca), string.lower(friendSearchValue))) then
					return
				elseif (na and not ca) and (not string.find(string.lower(na), string.lower(friendSearchValue))) then
					return
				elseif (not na and ca) and (not string.find(string.lower(ca), string.lower(friendSearchValue))) then
					return
				end
			end
		end
		addButtonIndex = addButtonIndex + 1;
		if ( not FriendListEntries[addButtonIndex] ) then
			FriendListEntries[addButtonIndex] = { };
		end
		FriendListEntries[addButtonIndex].buttonType = buttonType;
		FriendListEntries[addButtonIndex].id = id;
		FriendListEntries[addButtonIndex].favName = favName;
		FriendListEntries[addButtonIndex].bnSep = bnSep;
		FriendListEntries[addButtonIndex].overrideTitle = overrideTitle;
		totalButtonHeight = totalButtonHeight + FRIENDS_BUTTON_HEIGHTS[buttonType];
	end
	local i = 1;
	-- invites
	local numInvites = BNGetNumFriendInvites();
	if ( numInvites > 0 ) then
		AddButtonInfo(FRIENDS_BUTTON_TYPE_INVITE_HEADER, nil);
		if ( not GetCVarBool("friendInvitesCollapsed") ) then
			for i = 1, numInvites do
				AddButtonInfo(FRIENDS_BUTTON_TYPE_INVITE, i);
			end
			-- add divider before friends
			if ( numBNetTotal + numWoWTotal > 0 ) then
				AddButtonInfo(FRIENDS_BUTTON_TYPE_DIVIDER, nil);
			end
		end
	end
	-- search
	AddButtonInfo(BNET_SEARCH, nil, nil, false);
  if (not (friendSearchValue == "")) then
    AddButtonInfo(BNET_HEADER_TEXT, nil, nil, true, "Search Results");
  end
  if (numBNetFavorite > 0) then
    AddButtonInfo(BNET_HEADER_TEXT, nil, nil, true, "Blizzard Favorites");
  end
  -- favorite friends, online and offline
  for i = 1, numBNetFavorite do
    AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i);
  end
	-- --favs
	 local favs = { };
	for l, s in pairs(Favorites.db.profile.favTypes) do
		AddButtonInfo(BNET_HEADER_TEXT, nil, l)
		-- favorite Battlenet friends
		for i = 1 + numBNetFavorite, numBNetOffline+numBNetOnline-numBNetFavoriteOnline do
			local id, _, battleTag , _, _, _, client = BNGetFriendInfo(i);
			if s[id] then
				s[id] = nil;
				s[battleTag] = true
			end
			if s[battleTag] then
				favs[i] = battleTag;
				AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i);
			end
		end
	end
	AddButtonInfo(BNET_HEADER_TEXT, nil, nil, true);

	-- online Battlenet friends
	for i = 1 + numBNetFavorite, numBNetOnline - numBNetFavoriteOnline do
		if not favs[i] then
			AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i);
		end
	end

	-- online WoW friends
	for i = 1, numWoWOnline do
		AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, i);
	end
	-- divider between online and offline friends
	if ( (numBNetOnline > 0 or numWoWOnline > 0) and (numBNetOffline > 0 or numWoWOffline > 0) ) then
		AddButtonInfo(FRIENDS_BUTTON_TYPE_DIVIDER, nil);
	end
  -- offline Battlenet friends
	for i = 1, numBNetOffline - numBNetFavoriteOffline do
		if not favs[i + numBNetOnline] then
			AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i + numBNetOnline);
		end
	end
	-- offline WoW friends
	for i = 1, numWoWOffline do
		AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, i + numWoWOnline);
	end

	FriendsListFrameScrollFrame.totalFriendListEntriesHeight = totalButtonHeight;
	FriendsListFrameScrollFrame.numFriendListEntries = addButtonIndex;

	-- selection
	local selectedFriend = 0;
	-- check that we have at least 1 friend
	if ( numBNetTotal + numWoWTotal > 0 ) then
		-- get friend
		if ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW ) then
			selectedFriend = C_FriendList.GetSelectedFriend();
		elseif ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET ) then
			selectedFriend = BNGetSelectedFriend();
		end
		-- set to first in list if no friend
		if ( not selectedFriend or selectedFriend == 0 ) then
			FriendsFrame_SelectFriend(FriendListEntries[1].buttonType, 1);
			selectedFriend = 1;
		end
    FriendsFrameSendMessageButton:SetEnabled(FriendsList_CanWhisperFriend(FriendsFrame.selectedFriendType, selectedFriend));
	else
		FriendsFrameSendMessageButton:Disable();
	end
	FriendsFrame.selectedFriend = selectedFriend;
	FriendsFrame_UpdateFriends();

	-- RID warning, upon getting the first RID invite
	local showRIDWarning = false;
	local numInvites = BNGetNumFriendInvites();
	if ( numInvites > 0 and not GetCVarBool("pendingInviteInfoShown") ) then
		local _, _, _, _, _, _, isRIDEnabled = BNGetInfo();
		if ( isRIDEnabled ) then
			for i = 1, numInvites do
				local inviteID, accountName, isBattleTag = BNGetFriendInviteInfo(i);
				if ( not isBattleTag ) then
					-- found one
					showRIDWarning = true;
					break;
				end
			end
		end
	end
	if ( showRIDWarning ) then
		FriendsListFrame.RIDWarning:Show();
		FriendsListFrameScrollFrame.scrollBar:Disable();
		FriendsListFrameScrollFrame.scrollUp:Disable();
		FriendsListFrameScrollFrame.scrollDown:Disable();
	else
		FriendsListFrame.RIDWarning:Hide();
	end
end

local function FriendsFrame_UpdateFriendsNEW()
	local scrollFrame = FriendsListFrameScrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local numFriendButtons = scrollFrame.numFriendListEntries;

	local usedHeight = 0;

	scrollFrame.dividerPool:ReleaseAll();
	scrollFrame.invitePool:ReleaseAll();
	scrollFrame.PendingInvitesHeaderButton:Hide();
	for i = 1, numButtons do
		local button = buttons[i];
		local index = offset + i;
		if ( index <= numFriendButtons ) then
			button.index = index;
			local height = FriendsFrame_UpdateFriendButton(button);
			button:SetHeight(height);
			usedHeight = usedHeight + height;
		else
			button.index = nil;
			button:Hide();
		end
	end
	HybridScrollFrame_Update(scrollFrame, scrollFrame.totalFriendListEntriesHeight, usedHeight);
end

local function ShowRichPresenceOnly(client, wowProjectID, faction, realmID)
	if (client ~= BNET_CLIENT_WOW) or (wowProjectID ~= WOW_PROJECT_ID) then
		-- If they are not in wow or in a different version of wow, always show rich presence only
		return true;
	elseif (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and ((faction ~= playerFactionGroup) or (realmID ~= playerRealmID)) then
		-- If we are both in wow classic and our factions or realms don't match, show rich presence only
		return true;
	else
		-- Otherwise show more detailed info about them
		return false;
	end;
end

local function GetOnlineInfoText(client, isMobile, rafLinkType, locationText)
	if not locationText or locationText == "" then
		return UNKNOWN;
	end
	if isMobile then
		return LOCATION_MOBILE_APP;
	end
	if (client == BNET_CLIENT_WOW) and (rafLinkType ~= Enum.RafLinkType.None) and not isMobile then
		if rafLinkType == Enum.RafLinkType.Recruit then
			return RAF_RECRUIT_FRIEND:format(locationText);
		else
			return RAF_RECRUITER_FRIEND:format(locationText);
		end
	end

	return locationText;
end

local function fix(button)
	local function getEmbeddedFactionIcon(factionGroup)
		if ( factionGroup == "Alliance" ) then
			return "Interface\\TargetingFrame\\UI-PVP-ALLIANCE";
		elseif ( factionGroup == "Horde" ) then
			return "Interface\\TargetingFrame\\UI-PVP-HORDE";
		else --Say what?
			return "";
		end
	end
	local index = button.index;
	button.buttonType = FriendListEntries[index].buttonType;
	button.id = FriendListEntries[index].id;
	button.favName = FriendListEntries[index].favName
	button.overrideTitle = FriendListEntries[index].overrideTitle
	button.bnSep = FriendListEntries[index].bnSep
	if button.header then
		button.header:Hide()
	end
	if button.searchBox and not (button.buttonType == BNET_SEARCH) then
		button.searchBox.updating = true;
		button.searchBox:Hide()
	end
	if button.facIcon then button.facIcon:Hide() end
	local height = FRIENDS_BUTTON_HEIGHTS[button.buttonType];
	local nameText, nameColor, infoText, isFavoriteFriend, statusTexture;
	local extendedInfo = "";
	local hasTravelPassButton = false;
	if ( button.buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
		local info = C_FriendList.GetFriendInfoByIndex(FriendListEntries[index].id);
		if ( info.connected ) then
			button.background:SetColorTexture(FRIENDS_WOW_BACKGROUND_COLOR.r, FRIENDS_WOW_BACKGROUND_COLOR.g, FRIENDS_WOW_BACKGROUND_COLOR.b, FRIENDS_WOW_BACKGROUND_COLOR.a);
    	  	if ( info.afk ) then
				button.status:SetTexture(FRIENDS_TEXTURE_AFK);
			elseif ( info.dnd ) then
				button.status:SetTexture(FRIENDS_TEXTURE_DND);
			else
				button.status:SetTexture(FRIENDS_TEXTURE_ONLINE);
			end
			nameText = info.name..", "..format(FRIENDS_LEVEL_TEMPLATE, info.level, info.className);
			local ix=0
			local cCount = GetNumClasses();
			for ix=0, cCount, 1 do
			  local keyClass, ClassFilename = GetClassInfo(ix)
			  if (keyClass == info.className) then
				nameColor = RAID_CLASS_COLORS[ClassFilename]
			  end
			end
		else
			button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a);
			button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE);
			nameText = info.name;
			nameColor = FRIENDS_GRAY_COLOR;
      infoText = FRIENDS_LIST_OFFLINE;
		end
		infoText = info.area;
		button.gameIcon:Hide();
		button.summonButton:ClearAllPoints();
		button.summonButton:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, -1);
		FriendsFrame_SummonButton_Update(button.summonButton);
  elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
    local accountInfo = C_BattleNet.GetFriendAccountInfo(FriendListEntries[index].id);
    		if accountInfo then
    			nameText, nameColor, statusTexture = FriendsFrame_GetBNetAccountNameAndStatus(accountInfo);
          isFavoriteFriend = accountInfo.isFavorite;

    			button.status:SetTexture(statusTexture);

				if accountInfo.gameAccountInfo.isOnline then
				local class;
				if (accountInfo.gameAccountInfo.className) then
					extendedInfo = ""
					if (Favorites.db.profile.showLevel and accountInfo.gameAccountInfo.characterLevel) then
						extendedInfo = "[Level "..accountInfo.gameAccountInfo.characterLevel.."] "
					end

					local myProject = accountInfo.gameAccountInfo.wowProjectID == WOW_PROJECT_ID
					class = string.gsub(string.upper(accountInfo.gameAccountInfo.className), "%s+", "")
					-- search for localized class and convert to localization independent class
					local ix=0
					local cCount = GetNumClasses();
					for ix=0, cCount, 1 do
						local keyClass, ClassFilename = GetClassInfo(ix)
						if (keyClass == accountInfo.gameAccountInfo.className) then
							class = ClassFilename
						end
					end

					if (myProject) then
						nameText = nameText:gsub("fffde05c", RAID_CLASS_COLORS[class].colorStr)
						if (Favorites.db.profile.classColorOppositeFaction) then
							nameText = nameText:gsub("ff7b8489", RAID_CLASS_COLORS[class].colorStr)
						end
						if (accountInfo.gameAccountInfo.factionName and currentFaction == accountInfo.gameAccountInfo.factionName) then
							if (Favorites.db.profile.showClass and accountInfo.gameAccountInfo.className) then
								extendedInfo = extendedInfo.."[|c"..RAID_CLASS_COLORS[class].colorStr..accountInfo.gameAccountInfo.className.."|r]"
							end
						else
							if (Favorites.db.profile.showClass and accountInfo.gameAccountInfo.className) then
								if (Favorites.db.profile.classColorOppositeFaction) then
									extendedInfo = extendedInfo.."[|c"..RAID_CLASS_COLORS[class].colorStr..accountInfo.gameAccountInfo.className.."|r]"
								else
									extendedInfo = extendedInfo.."["..accountInfo.gameAccountInfo.className.."]"
								end
							end
						end
					else
						if (Favorites.db.profile.classColorOtherProject == 2) then
							nameText = nameText:gsub("fffde05c", "ff7b8489")
							if (Favorites.db.profile.showClass and accountInfo.gameAccountInfo.className) then
								extendedInfo = extendedInfo.."[|cff7b8489"..accountInfo.gameAccountInfo.className.."|r]"
							end
						elseif (Favorites.db.profile.classColorOtherProject == 3) then
							nameText = nameText:gsub("fffde05c", RAID_CLASS_COLORS[class].colorStr)
							nameText = nameText:gsub("ff7b8489", RAID_CLASS_COLORS[class].colorStr)
							if (Favorites.db.profile.showClass and accountInfo.gameAccountInfo.className) then
								extendedInfo = extendedInfo.."[|c"..RAID_CLASS_COLORS[class].colorStr..accountInfo.gameAccountInfo.className.."|r]"
							end
						elseif (Favorites.db.profile.classColorOtherProject == 4) then
							nameText = nameText:gsub("fffde05c", RAID_CLASS_COLORS[class].colorStr)
							if (Favorites.db.profile.showClass and accountInfo.gameAccountInfo.className) then
								if (accountInfo.gameAccountInfo.factionName and currentFaction == accountInfo.gameAccountInfo.factionName) then
									extendedInfo = extendedInfo.."[|c"..RAID_CLASS_COLORS[class].colorStr..accountInfo.gameAccountInfo.className.."|r]"
								else
									extendedInfo = extendedInfo.."["..accountInfo.gameAccountInfo.className.."]"
								end
							end
						end
					end
				end
            button.background:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a);

            if Favorites.db.profile.colorBackground then
              if accountInfo.gameAccountInfo.factionName == "Alliance" then
                button.background:SetColorTexture(0.2, 0.2, 0.7, 0.2);
              elseif accountInfo.gameAccountInfo.factionName == "Horde" then
                button.background:SetColorTexture(0.7, 0.2, 0.2, 0.2);
              end
            end

			if not button.facIcon then 
				button.facIcon = button:CreateTexture("facIcon"); 
				button.facIcon:ClearAllPoints();
				button.facIcon:SetPoint("RIGHT", button.gameIcon, "LEFT", 7, -5);
				button.facIcon:SetWidth(button.gameIcon:GetWidth())
				button.facIcon:SetHeight(button.gameIcon:GetHeight())
			end
            button.facIcon:SetTexture(getEmbeddedFactionIcon(accountInfo.gameAccountInfo.factionName));
            button.facIcon:Show()

    				if ShowRichPresenceOnly(accountInfo.gameAccountInfo.clientProgram, accountInfo.gameAccountInfo.wowProjectID, accountInfo.gameAccountInfo.factionName, accountInfo.gameAccountInfo.realmID) then
    					infoText = GetOnlineInfoText(accountInfo.gameAccountInfo.clientProgram, accountInfo.gameAccountInfo.isWowMobile, accountInfo.rafLinkType, accountInfo.gameAccountInfo.richPresence);
    				else
    					infoText = GetOnlineInfoText(accountInfo.gameAccountInfo.clientProgram, accountInfo.gameAccountInfo.isWowMobile, accountInfo.rafLinkType, accountInfo.gameAccountInfo.areaName);
					end
    				button.gameIcon:SetTexture(BNet_GetClientTexture(accountInfo.gameAccountInfo.clientProgram));

    				local fadeIcon = (accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW) and (accountInfo.gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID);
    				if fadeIcon then
    					button.gameIcon:SetAlpha(0.2);
    				else
    					button.gameIcon:SetAlpha(1);
    				end

    				--Note - this logic should match the logic in FriendsFrame_ShouldShowSummonButton

    				local shouldShowSummonButton = FriendsFrame_ShouldShowSummonButton(button.summonButton);
    				button.gameIcon:SetShown(not shouldShowSummonButton);

    				-- travel pass
    				hasTravelPassButton = true;
    				local restriction = FriendsFrame_GetInviteRestriction(button.id);
            if restriction == INVITE_RESTRICTION_NONE then
    					button.travelPassButton:Enable();
    				else
    					button.travelPassButton:Disable();
    				end
    			else
    				button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a);
    				button.gameIcon:Hide();
    				infoText = FriendsFrame_GetLastOnlineText(accountInfo);
    			end
    			button.summonButton:ClearAllPoints();
    			button.summonButton:SetPoint("CENTER", button.gameIcon, "CENTER", 1, 0);
    			FriendsFrame_SummonButton_Update(button.summonButton);
    		end
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER ) then
		local scrollFrame = FriendsListFrameScrollFrame;
		local divider = scrollFrame.dividerPool:Acquire();
		divider:SetParent(scrollFrame.ScrollChild);
		divider:SetAllPoints(button);
		divider:Show();
		nameText = nil;
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_INVITE_HEADER ) then
		local header = FriendsListFrameScrollFrame.PendingInvitesHeaderButton;
		header:SetPoint("TOPLEFT", button, 1, 0);
		header:Show();
		header:SetFormattedText(FRIEND_REQUESTS, BNGetNumFriendInvites());
		local collapsed = GetCVarBool("friendInvitesCollapsed");
		if ( collapsed ) then
			header.DownArrow:Hide();
			header.RightArrow:Show();
		else
			header.DownArrow:Show();
			header.RightArrow:Hide();
		end
		nameText = nil;
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_INVITE ) then
		local scrollFrame = FriendsListFrameScrollFrame;
		local invite = scrollFrame.invitePool:Acquire();
		invite:SetParent(scrollFrame.ScrollChild);
		invite:SetAllPoints(button);
		invite:Show();
		local inviteID, accountName = BNGetFriendInviteInfo(button.id);
		invite.Name:SetText(accountName);
		invite.inviteID = inviteID;
		invite.inviteIndex = button.id;
		nameText = nil;
	elseif (button.buttonType == BNET_HEADER_TEXT) then
		local scrollFrame = FriendsListFrameScrollFrame;
		local header = button.header
		if not header then
			header = CreateFrame("Button", "favHeader", scrollFrame.ScrollChild);
			header:SetDisabledFontObject(GameFontNormalSmall)
			header:SetHighlightFontObject(GameFontNormalSmall)
			header:SetNormalFontObject(GameFontNormalSmall)
			header:Disable()
		end
	--	local header = FriendsListFrameScrollFrame.PendingInvitesHeaderButton;
		header:SetWidth(button:GetWidth())
		header:SetHeight(height)
		header:SetParent(scrollFrame.ScrollChild);
		header:SetAllPoints(button);
		header:Show();
		if button.bnSep then
			if button.overrideTitle then
				header:SetText(button.overrideTitle);
			else
					header:SetText("Battle Net Friends");
			end
		else
			header:SetText(button.favName);
		end
		button.header = header;
		local scrollFrame = FriendsListFrameScrollFrame;
		local divider = scrollFrame.dividerPool:Acquire();
		divider:ClearAllPoints()
		divider:SetPoint("BOTTOM", header ,"BOTTOM", 0, -8);
		divider:SetParent(scrollFrame.ScrollChild);
		divider:Show();

		nameText = nil;
	elseif (button.buttonType == BNET_SEARCH) then
		local scrollFrame = FriendsListFrameScrollFrame;
		local searchBox = button.searchBox
		if not searchBox then
			searchBox = CreateFrame("EditBox", "searchBox", scrollFrame.ScrollChild, "SearchBoxTemplate");
			searchBox.Instructions:SetText("Search Friends");
			searchBox:SetScript("OnHide", FriendSearch_OnHide)
			searchBox:SetScript("OnTextChanged", FriendSearch_OnTextChanged)
			searchBox:SetScript("OnChar", FriendSearch_OnChar)
			searchBox:SetScript("OnEditFocusLost", FriendSearch_OnEditFocusLost)
			searchBox:SetScript("OnEditFocusGained", FriendSearch_OnEditFocusGained)
			searchBox:SetWidth(button:GetWidth()-20)
			searchBox:SetHeight(30)
			searchBox:SetPoint("TOPLEFT", button, 10, 0);
		end
		searchBox:Show();
		button.searchBox = searchBox;
		nameText = nil;
	end
	-- travel pass?
	if ( hasTravelPassButton ) then
		button.travelPassButton:Show();
	else
		button.travelPassButton:Hide();
	end
	-- selection
	if  (FriendsFrame.selectedFriendType == FriendListEntries[index].buttonType) and (FriendsFrame.selectedFriend == FriendListEntries[index].id) then
		button:LockHighlight();
	else
		button:UnlockHighlight();
	end
	-- finish setting up button if it's not a header
	if ( nameText ) then
		button.name:SetWidth(200)
		button.name:SetText(nameText);
		button.name:SetTextColor(nameColor.r, nameColor.g, nameColor.b);
		button.info:SetText("["..infoText.."] "..extendedInfo);
		button.info:SetWidth(200)
		button:Show();
    if isFavoriteFriend then
      button.Favorite:Show();
      button.Favorite:ClearAllPoints()
      button.Favorite:SetPoint("TOPLEFT", button.name, "TOPLEFT", button.name:GetStringWidth(), 0);
    else
      button.Favorite:Hide();
    end
	else
		button:Hide();
	end
	-- update the tooltip if hovering over a button
	if (FriendsTooltip.button == button) or (GetMouseFocus() == button) then
		button:OnEnter();
	end
	-- if ( GetMouseFocus() == button ) then
	-- 	FriendsFrameTooltip_Show(button);
	-- end
	if button.searchBox then
		button.searchBox.updating = false;
	end

	return height;
end
function BNGetBTAG(t)
  local bTAG = nil
  for i=1, BNGetNumFriends() do
		local bnetIDAccount, _, battleTag, _, _, _, client, o = BNGetFriendInfo(i);
		if t == bnetIDAccount then
		bTAG = battleTag
		end
  end
  return bTAG
end
local function fixDropDown()
   if UIDROPDOWNMENU_OPEN_MENU.which == "BN_FRIEND" or UIDROPDOWNMENU_OPEN_MENU.which == "BN_FRIEND_OFFLINE" then
		local inOne = false
		local btag = BNGetBTAG(FriendsDropDown.bnetIDAccount)
		for s, i in pairs (Favorites.db.profile.favTypes) do
			if i[btag] then
				inOne = true
				local info = UIDropDownMenu_CreateInfo()
				info.text = i[btag] and "Remove from "..s
				info.value = s
				info.notCheckable = true;
				info.func = function(self)
					if Favorites.db.profile.favTypes[self.value][btag] then
						Favorites.db.profile.favTypes[self.value][btag] = nil
					else
						Favorites.db.profile.favTypes[self.value][btag] = true
					end
					FriendsList_Update(true)
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
		if not inOne then
			for s, i in pairs (Favorites.db.profile.favTypes) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = "Add to "..s
				info.value = s
				info.notCheckable = true;
				info.func = function(self)
					if Favorites.db.profile.favTypes[self.value][btag] then
						Favorites.db.profile.favTypes[self.value][btag] = nil
					else
						Favorites.db.profile.favTypes[self.value][btag] = true
					end
					FriendsList_Update(true)
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end
hooksecurefunc("FriendsFrameBNOfflineDropDown_Initialize", fixDropDown)
hooksecurefunc("FriendsFrameBNDropDown_Initialize", fixDropDown)
local function FriendsList_GetScrollFrameTopButtonNEW(offset)
	local usedHeight = 0;
	for i = 1, #FriendListEntries do
		local buttonHeight = FRIENDS_BUTTON_HEIGHTS[FriendListEntries[i].buttonType];
		if ( usedHeight + buttonHeight >= offset ) then
			return i - 1, offset - usedHeight;
		else
			usedHeight = usedHeight + buttonHeight;
		end
	end
end
FriendsList_Update = FriendsList_UpdateFIX
FriendsFrame_UpdateFriendButton = fix
FriendsList_GetScrollFrameTopButton = FriendsList_GetScrollFrameTopButtonNEW
FriendsFrame_UpdateFriends = FriendsFrame_UpdateFriendsNEW
FriendsListFrameScrollFrame.dynamic = FriendsList_GetScrollFrameTopButton
FriendsListFrameScrollFrame.update = FriendsFrame_UpdateFriends


function FriendSearch_OnHide(self)
	if not self.updating then
		self.clearButton:Click();
		FriendSearch_OnTextChanged(self);
	end
end

function FriendSearch_OnTextChanged(self, userChanged)
	if ( not self:HasFocus() and self:GetText() == "" ) then
		self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
		self.clearButton:Hide();
	else
		self.searchIcon:SetVertexColor(1.0, 1.0, 1.0);
		self.clearButton:Show();
	end
	friendSearchValue = self:GetText()
	FriendsList_Update(true)
	self.Instructions:SetShown(self:GetText() == "")
end

function FriendSearch_OnChar(self, text)
	-- clear focus if the player is repeating keys (ie - trying to move)
	-- TODO: move into base editbox code?
	local MIN_REPEAT_CHARACTERS = 4;
	local searchString = self:GetText();
	if (string.len(searchString) >= MIN_REPEAT_CHARACTERS) then
		local repeatChar = true;
		for i=1, MIN_REPEAT_CHARACTERS - 1, 1 do
			if ( string.sub(searchString,(0-i), (0-i)) ~= string.sub(searchString,(-1-i),(-1-i)) ) then
				repeatChar = false;
				break;
			end
		end
		if ( repeatChar ) then
			self:ClearFocus();
		end
	end
end

function FriendSearch_OnEditFocusLost(self)
	if ( self:GetText() == "" ) then
		self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
		self.clearButton:Hide();
	end
end
function FriendSearch_OnEditFocusGained(self)
	self.searchIcon:SetVertexColor(1.0, 1.0, 1.0);
	self.clearButton:Show();
end

-- 9.0.1 Depricated Function Fix
local function getDeprecatedAccountInfo(accountInfo)
	if accountInfo then
		local wowProjectID = accountInfo.gameAccountInfo.wowProjectID or 0;
		local clientProgram = accountInfo.gameAccountInfo.clientProgram ~= "" and accountInfo.gameAccountInfo.clientProgram or nil;
		return	accountInfo.bnetAccountID, accountInfo.accountName, accountInfo.battleTag, accountInfo.isBattleTagFriend,
				accountInfo.gameAccountInfo.characterName, accountInfo.gameAccountInfo.gameAccountID, clientProgram,
				accountInfo.gameAccountInfo.isOnline, accountInfo.lastOnlineTime, accountInfo.isAFK, accountInfo.isDND, accountInfo.customMessage, accountInfo.note, accountInfo.isFriend,
				accountInfo.customMessageTime, wowProjectID, accountInfo.rafLinkType == Enum.RafLinkType.Recruit, accountInfo.gameAccountInfo.canSummon, accountInfo.isFavorite, accountInfo.gameAccountInfo.isWowMobile;
	end
end

-- Use C_BattleNet.GetFriendAccountInfo instead.
BNGetFriendInfo = function(friendIndex)
	local accountInfo = C_BattleNet.GetFriendAccountInfo(friendIndex);
	return getDeprecatedAccountInfo(accountInfo);
end