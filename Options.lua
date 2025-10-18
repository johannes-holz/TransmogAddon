local folder, core = ...

local FullAlign = {
	TOPLEFT = "TOPLEFT",
	TOP = "TOP",
	TOPRIGHT = "TOPRIGHT",
	LEFT = "LEFT",
	CENTER = "CENTER",
	RIGHT = "RIGHT",
	BOTTOMLEFT = "BOTTOMLEFT",
	BOTTOM = "BOTTOM",
	BOTTOMRIGHT = "BOTTOMRIGHT",
}

local GetWidgetValue = function(info)
	local caller = info[1]
	local caller2 = info[2]
	local arg = info["options"]["args"][caller]["args"][caller2]["arg"]
	
	return core.db.profile[caller][arg]
end

local SetWidgetValue = function(info, input)
	local caller = info[1]
	local caller2 = info[2]
	local arg = info["options"]["args"][caller]["args"][caller2]["arg"]
	
	core.db.profile[caller][arg] = input
	
	core.OnSettingsUpdate(arg)
    core.Debug("Options changed:", caller, arg, input)
end

core.OnSettingsUpdate = function(arg)
	core.UpdateMinimapIcon()
	core.UpdateSkinDropdown()
end

core.options = {
	type = "group", 
	childGroups = "tab",
	args = {
	    --[==[ Options Frames ]==]--
		OptionsHeader = {
			order = 2,
			type = "header",
			name = "", -- core.titleFull, --GetAddOnMetadata(folder, "title")," v",GetAddOnMetadata(folder, "version")
		},
		
		General = {
			order = 2.1,
			type  = "group",
			name  = "General",
			args = {
				GeneralHeader = {
					type = "header",
					order = 1,
					name = "General Options"
				},
				-- GeneralDescription = {
				-- 	type = "description",
				-- 	order = 2,
				-- 	name = "blablabla description",
				-- },		
				ShowMinimapIcon = {
                    type = "toggle",
                    order = 2.1,
                    name = "Show minimap icon",
					-- width = "full",
                    desc = "Show an icon on the minimap for this AddOn.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "showMinimapIcon",
                },
				AutoOpen = {
                    type = "toggle",
                    order = 3,
                    name = "Auto open at NPC",
					-- width = "full",
                    desc = "Directly open the AddOn's interface when talking to the transmog NPC.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "autoOpen",
                },		
				PlaySpecialSounds = {
                    type = "toggle",
                    order = 4,
                    name = "Play unlock sounds.",
					-- width = "full",
                    desc = "Play a sound when you gain Shards of Illusion or unlock visuals.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "playSpecialSounds",
                },	
				FixItemIcons = {
                    type = "toggle",
                    order = 5,
                	name = "Fix inventory icons.",
					-- width = "full",
                    desc = "Display the icons of the equipped items (instead of their visuals) in inventory and inspect frame.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "fixItemIcons",
                },
				ActiveSkinDropdown = {
                    type = "select",
                    order = 6,
                    name = "Active skin selection",
					-- width = "full",
                    desc = "Select method to select active skin in the Characterframe.",
					values = { _01_none = "None", _02_dropdown = "Dropdown", _03_button_left = "Button Left", _04_button_right = "Button Right"}, -- less cringe way to get the order right?
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "activeSkinDropdown",
                },		
				TooltipHeader = {
					type = "header",
					order = 20,
					name = "Tooltip Options"
				},
				TooltipNoCollected = {
                    type = "toggle",
                    order = 21,
                    name = "Show collected status",
					-- width = "full",
                    desc = "Add a Tooltip line that indicates if a item or visual is not collected.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "tooltipCollectedStatus",
                },
				ExtraItemTooltip = {
                    type = "toggle",
                    order = 22,
                    name = "Show visual source tooltip.",
					-- width = "full",
                    desc = "Display an extra tooltip for an item's visual by pressing shift.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "extraItemTooltip",
                },	
				ShowControlHints = {
                    type = "toggle",
                    order = 23,
                    name = "Show usage hints.",
					-- width = "full",
                    desc = "Display usage hints in certain AddOn tooltips.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "showControlHints",
                },
				CollectionHeader = {
					type = "header",
					order = 30,
					name = "Collection Options"
				},		
                ClothedMannequins = {
                    type = "toggle",
                    order = 31,
                    name = "Clothed mannequins",
					-- width = "full",
                    desc = "...",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "clothedMannequins",
                },	
				ShowUnavailableEnchants = {
                    type = "toggle",
                    order = 32,
                    name = "List unavailable enchants.",
					-- width = "full",
                    desc = "Display enchants in collection that are probably unavailable to the player.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "showQAEnchants",
                },
				DressingRoomHeader = {
					type = "header",
					order = 40,
					name = "Dressing Room Options"
				},
				DoNotResetDressUp = {
                    type = "toggle",
                    order = 41,
                    name = "Prevent reset on closing.",
					-- width = "full",
                    desc = "Dressing Room remembers the selected items during a session instead of resetting to the player's inventory.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "doNotResetDressUp",
                },				
            },		
        },
        
		-- AnotherTab = {		
		-- 	order = 4,
		-- 	type  = "group",
		-- 	name  = "Yet another tab",
		-- 	args = {			
		-- 		Header2 = {
		-- 			order = 1,
		-- 			type = "header",
		-- 			name = "Header",
		-- 		},	
        --   },
        -- },
		
		About = {
			order = 20,
			type  = "group",
			name  = "About",
			args = {
				description1 = {
					type = "description",
					order = 1,
					name = "Does transmog things.",
				},
				
				description10 = {
					type = "description",
					order = 10,
					name = "Made by Qhoernchen - qhoernchen@gmail.com",
				},
			},
		},
    },
}

core.defaults = {	
	profile = {
		General = {
			clothedMannequins = false,
			tooltipCollectedStatus = true,
			showMinimapIcon = true,
			autoOpen = true,
			extraItemTooltip = true,
			fixItemIcons = true,
			playSpecialSounds = true,
			doNotResetDressUp = false,
			showControlHints = true,
			showQAEnchants = false,
			activeSkinDropdown = "_02_dropdown",
		},
    },
}