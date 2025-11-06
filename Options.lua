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
		-- OptionsHeader = {
		-- 	order = 2,
		-- 	type = "header",
		-- 	name = "", -- core.titleFull, --GetAddOnMetadata(folder, "title")," v",GetAddOnMetadata(folder, "version")
		-- },
		
		General = {
			order = 2.1,
			type  = "group",
			name  = core.GENERAL_TAB_NAME,
			args = {
				GeneralHeader = {
					type = "header",
					order = 1,
					name = core.GENERAL_OPTIONS_NAME,
				},
				-- GeneralDescription = {
				-- 	type = "description",
				-- 	order = 2,
				-- 	name = "blablabla description",
				-- },		
				ShowMinimapIcon = {
                    type = "toggle",
                    order = 2.1,
                    name = core.SHOW_MINIMAP_ICON_NAME,
					-- width = "full",
                    desc = core.SHOW_MINIMAP_ICON_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "showMinimapIcon",
                },
				AutoOpen = {
                    type = "toggle",
                    order = 3,
                    name = core.AUTO_OPEN_NAME,
					-- width = "full",
                    desc = core.AUTO_OPEN_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "autoOpen",
                },		
				PlaySpecialSounds = {
                    type = "toggle",
                    order = 4,
                    name = core.PLAY_SPECIAL_SOUNDS_NAME,
					-- width = "full",
                    desc = core.PLAY_SPECIAL_SOUNDS_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "playSpecialSounds",
                },	
				FixItemIcons = {
                    type = "toggle",
                    order = 5,
                	name = core.FIX_ITEM_ICONS_NAME,
					-- width = "full",
                    desc = core.FIX_ITEM_ICONS_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "fixItemIcons",
                },
				ActiveSkinDropdown = {
                    type = "select",
                    order = 6,
                    name = core.ACTIVE_SKIN_SELECTION_NAME,
					-- width = "full",
                    desc = core.ACTIVE_SKIN_SELECTION_DESC,
					values = { _01_none = core.NONE, _02_dropdown = core.DROPDOWN, _03_button_left = core.BUTTON_LEFT, _04_button_right = core.BUTTON_RIGHT}, -- less cringe way to get the order right?
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "activeSkinDropdown",
                },		
				TooltipHeader = {
					type = "header",
					order = 20,
					name = core.TOOLTIP_OPTIONS_NAME,
				},
				TooltipCollectedStatus = {
                    type = "toggle",
                    order = 21,
                    name = core.EXTRA_ITEM_TOOLTIP_NAME,
					-- width = "full",
                    desc = core.EXTRA_ITEM_TOOLTIP_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "tooltipCollectedStatus",
                },
				ExtraItemTooltip = {
                    type = "toggle",
                    order = 22,
                    name = core.TOOLTIP_COLLECTED_STATUS_NAME,
					-- width = "full",
                    desc = core.TOOLTIP_COLLECTED_STATUS_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "extraItemTooltip",
                },	
				ShowControlHints = {
                    type = "toggle",
                    order = 23,
                    name = core.SHOW_CONTROL_HINTS_NAME,
					-- width = "full",
                    desc = core.SHOW_CONTROL_HINTS_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "showControlHints",
                },
				CollectionHeader = {
					type = "header",
					order = 30,
					name = core.COLLECTION_OPTIONS_NAME,
				},		
                ClothedMannequins = {
                    type = "toggle",
                    order = 31,
                    name = core.CLOTHED_MANNEQUINS_NAME,
					-- width = "full",
                    desc = core.CLOTHED_MANNEQUINS_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "clothedMannequins",
                },	
				ShowUnavailableEnchants = {
                    type = "toggle",
                    order = 32,
                    name = core.SHOW_UNAVAILABLE_ENCHANTS_NAME,
					-- width = "full",
                    desc = core.SHOW_UNAVAILABLE_ENCHANTS_DESC,
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "showQAEnchants",
                },
				DressingRoomHeader = {
					type = "header",
					order = 40,
					name = core.DRESSING_ROOM_OPTIONS_NAME,
				},
				DoNotResetDressUp = {
                    type = "toggle",
                    order = 41,
                    name = core.DRESSING_ROOM_NO_RESET_NAME,
					-- width = "full",
                    desc = core.DRESSING_ROOM_NO_RESET_DESC,
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
			name  = core.ABOUT_TAB_NAME,
			args = {
				AboutHeader = {
					type = "header",
					order = 1,
					name = core.ABOUT_HEADER_NAME:format(GetAddOnMetadata(folder, "title")),
				},		
				About1 = {
					type = "description",
					order = 2,
					name = core.ABOUT_NAME1,
				},		
				About2 = {
					type = "description",
					order = 3,
					name = core.ABOUT_NAME2,
				},			
				About3 = {
					type = "description",
					order = 4,
					name = core.ABOUT_NAME3,
				},		
				About4 = {
					type = "description",
					order = 5,
					name = core.ABOUT_NAME4,
				},			
				About5 = {
					type = "description",
					order = 6,
					name = core.ABOUT_NAME5,
				},				
				MadeBy = {
					type = "description",
					order = 10,
					name = core.ABOUT_MADE_BY_NAME,
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