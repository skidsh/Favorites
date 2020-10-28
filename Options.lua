local Favorites = LibStub("AceAddon-3.0"):GetAddon("Favorites")
function Favorites:UpdateOptions()
	local favTypes = {}
	local selectedFav = 1
	local c = 1
	for i in pairs(Favorites.db.profile.favTypes) do
		favTypes[c] = i
		c = c + 1
	end

	Favorites.favTypes = favTypes
	Favorites.selectedFav = selectedFav
end
function Favorites:SetupOptions()
	Favorites:UpdateOptions()
	self.options = {
		type = "group",
		childGroups = "tab",
		plugins = {},
		args = {
			author = {
			  name = "|cff1fd700Author:|r Jax",
			  type = "description"
			},
			version = {
			  name = "|cff1fd700Version:|r "..GetAddOnMetadata("Favorites", "Version").."\n",
			  type = "description"
			},
			moreoptions={
			  name = "General",
			  type = "group",
			  args={
				 ccBG = {
				  order = 1,
				  width = 1.5,
				  name = "Faction Color Backgrounds",
				  desc = "Color the Background of Each Friend Based on Faction",
				  type = "toggle",
				  set = function(info,val) self.db.profile.colorBackground = val
										   FriendsList_Update(true)
					    end,
				  get = function(info) return self.db.profile.colorBackground end
				},
				ccOF = {
				  order = 2,
				  width = 1.5,
				  name = "Class Color Opposite Faction",
				  desc = "Class Color Friends of the Opposite Faction",
				  type = "toggle",
				  set = function(info,val) self.db.profile.classColorOppositeFaction = val
										   FriendsList_Update(true)
						end,
				  get = function(info) return self.db.profile.classColorOppositeFaction end
				},

				cl = {
					order = 3,
					width = 1.5,
					name = "Show Character Level",
					desc = "Show character level on friends list",
					type = "toggle",
					set = function(info,val) self.db.profile.showLevel = val
											 FriendsList_Update(true)
						  end,
					get = function(info) return self.db.profile.showLevel end
				  },
				  sc = {
					order = 4,
					width = 1.5,
					name = "Show Character class",
					desc = "Show character class on friends list",
					type = "toggle",
					set = function(info,val) self.db.profile.showClass = val
											 FriendsList_Update(true)
						  end,
					get = function(info) return self.db.profile.showClass end
				  },
				  sc2 = {
					order = 5,
					name = "",
					type = "header"
				  },
				ccOP = {
					order = 6,
					width = "double",
					name = "Color WoW Classic Friends",
					desc = "Color of the names of Friends playing WoW Classic",
					type = "select",
					style = "dropdown",
					values = {
						[1] = "Default",
						[2] = "Grey both factions",
						[3] = "Class color both factions",
						[4] = "Class color my faction & Grey opposite faction"
					},
					set = function(info,val) self.db.profile.classColorOtherProject = val
											 FriendsList_Update(true)
						end,
					get = function(info) return self.db.profile.classColorOtherProject end
				},
				favTypes={
					order = 7,
					name = "Current Favorite Groups",
					type = "select",
					values = Favorites.favTypes,
					get = function(i) return Favorites.selectedFav end,
					set = function(i, v, s) Favorites.selectedFav = v end,
					style = "radio"
				},
				delFav={
					order = 8,
					width = "normal",
					name = "Remove Group",
					type = "execute",
					disabled  = function()
						return #Favorites.favTypes == 1 or Favorites.favTypes[Favorites.selectedFav] == "Favorites"
					end,
					confirm = function(i,v)
						return "Are you sure you want to remove the "..Favorites.favTypes[Favorites.selectedFav].." favorites group?"
					end,
					func = function(i, v)
						Favorites.db.profile.favTypes[Favorites.favTypes[Favorites.selectedFav]] = nil
						Favorites:UpdateOptions()

						Favorites.options.args.moreoptions.args.favTypes.values = Favorites.favTypes
						--LibStub("AceConfigRegistry-3.0"):NotifyChange("|cff1fd700Favorites|r")
						FriendsList_Update(true)
					end,
			    },
					resetFav={
						order = 9,
						width = "nomral",
						name = "Full Reset",
						type = "execute",
						confirm = function(i,v)
							return "Are you sure you want to reset all of your favorites?"
						end,
						func = function(i, v)
							for s, j in pairs (Favorites.db.profile.favTypes) do
								if s == "Favorites" then
									for ff,_ in pairs (Favorites.db.profile.favTypes[s]) do
										Favorites.db.profile.favTypes[s][ff] = nil
									end
								else
									Favorites.db.profile.favTypes[s] = nil
								end
							end
				--			Favorites.db.profile.favTypes["Favorites"] = { }
							Favorites:UpdateOptions()

							Favorites.options.args.moreoptions.args.favTypes.values = Favorites.favTypes
							--LibStub("AceConfigRegistry-3.0"):NotifyChange("|cff1fd700Favorites|r")
							FriendsList_Update(true)
						end,
				    },
				spacer = {
				   type = "description",
				   name="", --use an empty value for name
				   order = 10,
				   width="small", --forces a new line after the items above it
				},
				addFav={
					order = 11,
					name = "Add Custom Favorites Group",
					type = "input",
					get = function() return "" end,
					set = function(i, v)
						Favorites.db.profile.favTypes[v] = { }
						Favorites:UpdateOptions()
						Favorites.options.args.moreoptions.args.favTypes.values = Favorites.favTypes
						--LibStub("AceConfigRegistry-3.0"):NotifyChange("|cff1fd700Favorites|r")
						FriendsList_Update(true)
						end,
			    },
				notes = {
				   type = "description",
				   name="\n\nThe default favorites group cannot be deleted.", --use an empty value for name
				   order =12,
				   width="full", --forces a new line after the items above it
				},

			  }
			}
		}
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("|cff1fd700Favorites|r", self.options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("|cff1fd700Favorites|r", "|cff1fd700Favorites|r")
	self:RegisterChatCommand("favs", function() InterfaceOptionsFrame_OpenToCategory("|cff1fd700Favorites|r") InterfaceOptionsFrame_OpenToCategory("|cff1fd700Favorites|r") end)
	self:RegisterChatCommand("favorites", function() InterfaceOptionsFrame_OpenToCategory("|cff1fd700Favorites|r") InterfaceOptionsFrame_OpenToCategory("|cff1fd700Favorites|r") end)
end
