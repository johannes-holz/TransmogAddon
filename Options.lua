local folder, core = ...


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
					name = "MOBA-style health bars"
				},
				MobaDescription = {
					type = "description",
					order = 2,
					name = "Overlay lines for 1k and 10k segments over health bars.",
				},		
                RulerToggle = {
                    type = "toggle",
                            --width = 1.5, --apparently numerics arent supported
                    order = 3,
                    name = "Enable",
                        width = "full",
                    desc = "Display lines for 1k and 10k segments on healthbars.",
                    get = GetWidgetValue,
                    set = SetWidgetValue,
                    arg = "Enable",
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
			Enable = true,
		},
		CCTracker = {
			Enable = true,
        },
    },
}