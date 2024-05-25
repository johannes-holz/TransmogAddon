local folder, core = ...

--[[
Possible options:
	- Automaticly open transmog frame at npc?
	- Outfit features:
		- enable
		- Dont reset on close, in options or in frame?
		- Maybe not as options but in general:
			Remember visibility of list frame? Show Cloak/Helmet according to interface setting like default DressUpFrame? Allow OH-only weapons for non-dualwield?
	- Extra tooltip for transmogification source:
		- enable, used modifier?
	- Active Skin Dropdown:
		- enable, position?
	- Tooltip modifications:
		- enable
	- Option for Data Compression?
	- Balance display/hooks?
	- Show/Hide Minimap Icon?

]]

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
	
	-- Update our stuff
	core.OnSettingsUpdate(arg)
    print("Options changed:", caller, arg, input)
end

core.OnSettingsUpdate = function(arg)
	core.UpdateMinimapIcon()
	core.UpdateSkinDropdown()
end

core.options = {
	type = "group", 
	args = {
	    --[==[ Options Frames ]==]--
		OptionsHeader = {
			order = 2,
			type = "header",
			name = "", -- core.titleFull, --"Hoernchen's Plate Extensions",--GetAddOnMetadata(folder, "title")," v",GetAddOnMetadata(folder, "version")
		},
		
		General = {
			order = 2.1,
			type  = "group",
			name  = "General Options",
			args = {
				Header = {
					type = "header",
					order = 1,
					name = "Header Title"
				},
				MobaDescription = {
					type = "description",
					order = 2,
					name = "blablabla description",
				},		
				ShowMinimapIcon = {
                    type = "toggle",
                    order = 2.1,
                    name = "Show minimap icon",
					width = "full",
                    desc = "Activate in order to show a minimap icon for this AddOn.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "showMinimapIcon",
                },
                ClothedMannequins = {
                    type = "toggle",
                    order = 3,
                    name = "Clothed mannequins",
					width = "full",
                    desc = "Put some cloth on for Anzu's sake.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "clothedMannequins",
                },
				TooltipNoCollected = {
                    type = "toggle",
                    order = 4,
                    name = "Hide collection status in tooltips",
					width = "full",
                    desc = "Activate in order to not show whether in item has been collected in tooltips.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "tooltipNoCollectedStatus",
                },
				AutoOpen = {
                    type = "toggle",
                    order = 6,
                    name = "Open transmog window automatically",
					width = "full",
                    desc = "When activated, the transmog window will open automatically when you talk to the transmog NPC.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "autoOpen",
                },				
				ExtraItemTooltip = {
                    type = "toggle",
                    order = 7,
                    name = "Show extra item tooltip.",
					width = "full",
                    desc = "Activate to show the transmogrification source in an extra tooltip when pressing shift.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "extraItemTooltip",
                },			
				UseWrongTextures = {
                    type = "toggle",
                    order = 8,
                    name = "Show wrong textures.",
					width = "full",
                    desc = "Activate to not fix the bug where the character and inspect frame show the texture of the transmog items instead of the original items.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "useWrongTextures",
                },	
				PlaySpecialSounds = {
                    type = "toggle",
                    order = 8.1,
                    name = "Play unlock sounds.",
					width = "full",
                    desc = "Activate to play a sound when you gain Shards of Illusion or unlock visuals.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "playSpecialSounds",
                },
				DoNotResetDressUp = {
                    type = "toggle",
                    order = 9,
                    name = "Do not reset dressing room on closing.",
					width = "full",
                    desc = "Active to have the dressing room remember its last state when closing.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "doNotResetDressUp",
                },				
				HideControlHints = {
                    type = "toggle",
                    order = 10,
                    name = "Hide control hints in slot tooltips.",
					width = "full",
                    desc = "Activate to hide certain lines regarding the controls in tooltip.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "hideControlHints",
                },		
				ActiveSkinDropdown = {
                    type = "select",
                    order = 11,
                    name = "Active skin selection",
					-- width = "full",
                    desc = "Select method to select active skin in the Characterframe.",
					values = { _01_none = "None", _02_dropdown = "Dropdown", _03_button = "Button" }, -- less cringe way to get the order right?
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "activeSkinDropdown",
                },
            },		
        },
        
		-- CCTracker = {		
		-- 	order = 4,
		-- 	type  = "group",
		-- 	name  = "Aura Widget",
		-- 	args = {			
		-- 		Header2 = {
		-- 			order = 1,
		-- 			type = "header",
		-- 			name = "Aura Widget",
		-- 		},	
		-- 		description1 = {
		-- 			type = "description",
		-- 			order = 2,
		-- 			name = "Shows the strongest type of CC or certain buffs beside nameplates, similar to LoseControl.",
		-- 		},		
		-- 		CCTrackerEnable = {
		-- 			type = "toggle",
		-- 			order = 3,
		-- 				width = "full",
		-- 			name = "Enable",
		-- 			get = GetWidgetValue,
		-- 			set = SetWidgetValue,
		-- 			arg = "Enable",
		-- 		},
        --     },
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
			},
		},
    },
}

core.defaults = {	
	profile = {
		General = {
			clothedMannequins = false,
			tooltipNoCollectedStatus = false,
			showMinimapIcon = true,
			autoOpen = true,
			extraItemTooltip = true,
			useWrongTextures = false,
			playSpecialSounds = true,
			doNotResetDressUp = false,
			hideControlHints = false,
			activeSkinDropdown = "_02_dropdown",
		},
    },
}