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
	- Show/Hide Minimap Icon? Look at how other AddOns do this?

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
	
	-- core.Reload()
    print("Options changed.")
end

core.options = {
	type = "group", 
	args = {
	    --[==[ Options Frames ]==]--
		OptionsHeader = {
			order = 2,
			type = "header",
			name = "" --"Hoernchen's Plate Extensions",--GetAddOnMetadata(folder, "title")," v",GetAddOnMetadata(folder, "version")
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
                    order = 3,
                    name = "Hide collection status in tooltips.",
					width = "full",
                    desc = "Activate in order to not show whether in item has been collected in its tooltip.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "tooltipNoCollectedStatus",
                },
            },		
        },
        
		CCTracker = {		
			order = 4,
			type  = "group",
			name  = "Aura Widget",
			args = {			
				Header2 = {
					order = 1,
					type = "header",
					name = "Aura Widget",
				},	
				description1 = {
					type = "description",
					order = 2,
					name = "Shows the strongest type of CC or certain buffs beside nameplates, similar to LoseControl.",
				},		
				CCTrackerEnable = {
					type = "toggle",
					order = 3,
						width = "full",
					name = "Enable",
					get = GetWidgetValue,
					set = SetWidgetValue,
					arg = "Enable",
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
		},
		CCTracker = {
			Enable = true,
        },
    },
}