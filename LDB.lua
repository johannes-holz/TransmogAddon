local folder, core = ...

local Icon_OnFirstTooltip = function(self)
	self.update = function(self)
		if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
			GameTooltip:ClearLines()		
			self.dataObject.OnTooltipShow(GameTooltip)
		end
	end

	core.RegisterListener("config", self)
end

core.UpdateMinimapIcon = function()
	if core.LDBIcon then
		if core.db.profile.General.showMinimapIcon then
			core.LDBIcon:Show(folder)
		else
			core.LDBIcon:Hide(folder)
		end
	end
end
	
core.InitLDB = function()
	local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)	
	if not LDB or not LDBIcon then print(folder, "ERROR: Could not find LibDataBroker-1.1 or LibDBIcon-1.0!"); return end

	local LDBObj = LDB:NewDataObject(folder, {
		type = "launcher",
		label = folder,
		OnClick = function(_, msg)
			if msg == "LeftButton" then
				if IsShiftKeyDown() then
					if InterfaceOptionsFrame:IsShown() then
						InterfaceOptionsFrame:Hide()
					end
					if core.transmogFrame:IsShown() then
						core.transmogFrame:Hide()
					else
						core.OpenTransmogWindow()
					end
				elseif IsControlKeyDown() then
					core.transmogFrame:Hide()
					core.wardrobeFrame:Hide()
					if InterfaceOptionsFrame:IsShown() and InterfaceOptionsFramePanelContainer.displayedPanel and InterfaceOptionsFramePanelContainer.displayedPanel.name == core.title then
						InterfaceOptionsFrame:Hide()
					else
						core.OpenOptions()
					end
				elseif not IsModifierKeyDown() then
					if InterfaceOptionsFrame:IsShown() then
						InterfaceOptionsFrame:Hide()
					end
					if core.wardrobeFrame:IsShown() then
						core.wardrobeFrame:Hide()
					else
						core.OpenWardrobe()
					end
				end
			elseif msg == "RightButton" then
				-- TODO: Undecided how/where to this
				local config = core.GetConfig()
				if not config then return end
				local nextConfig = config % 3 + 1
				core.RequestUpdateConfig(nextConfig)
			end
		end,
		icon = core.minimapIcon,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end

			if Icon_OnFirstTooltip then
				Icon_OnFirstTooltip(tooltip:GetOwner())
				Icon_OnFirstTooltip = nil
			end

			local config = core.GetConfig()
			local cl, cr = ORANGE_FONT_COLOR, RAID_CLASS_COLORS.PRIEST

			tooltip:AddLine(folder)
			tooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(core.LEFT_CLICK, core.OPEN_WARDROBE, cl.r, cl.g, cl.b, cr.r, cr.g, cr.b)
			GameTooltip:AddDoubleLine(core.SHIFT_LEFT_CLICK, core.OPEN_TRANSMOG, cl.r, cl.g, cl.b, cr.r, cr.g, cr.b)
			GameTooltip:AddDoubleLine(core.CONTROL_LEFT_CLICK, core.OPEN_OPTIONS, cl.r, cl.g, cl.b, cr.r, cr.g, cr.b)
			GameTooltip:AddDoubleLine(core.RIGHT_CLICK, core.TOGGLE_VISIBILITY, cl.r, cl.g, cl.b, cr.r, cr.g, cr.b)			
			tooltip:AddLine(" ")
			local text = RED_FONT_COLOR_CODE .. core.TRANSMOG_STATUS_UNKNOWN .. FONT_COLOR_CODE_CLOSE 
			if config then
				text = core.TRANSMOG_STATUS
				for i, name in ipairs(core.CONFIG_NAMES) do
					text = text .. (config == i and GREEN_FONT_COLOR_CODE or GRAY_FONT_COLOR_CODE) .. name .. FONT_COLOR_CODE_CLOSE .. (i < #core.CONFIG_NAMES and ", " or "")
				end
			end
			tooltip:AddLine(text, nil, nil, nil, nil)
		end,
	})

	TransmoggyDB["minimapIcon"] = TransmoggyDB["minimapIcon"] or
	{
		["minimapPos"] = 260,
		["hide"] = false
	}
	
	LDBIcon:Register(folder, LDBObj, TransmoggyDB.minimapIcon)

	core.LDBIcon = LDBIcon
	core.InitLDB = nil
end
