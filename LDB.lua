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
	
-- TODO: Make minimap icon optional
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
					if core.transmogFrame:IsShown() then
						core.transmogFrame:Hide()
					else
						core.OpenTransmogWindow()
					end
				elseif not IsModifierKeyDown() then
					if core.wardrobeFrame:IsShown() then
						core.wardrobeFrame:Hide()
					else
						core.OpenWardrobe()
					end
				end
			elseif msg == "RightButton" then
				-- TODDO: Temporary. Undecided how/where to this
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

			tooltip:AddLine(folder)
			tooltip:AddLine(" ")
			tooltip:AddLine(core.MINIMAP_TOOLTIP_TEXT1, 1, 1, 1)
			tooltip:AddLine(core.MINIMAP_TOOLTIP_TEXT2, 1, 1, 1)
			tooltip:AddLine(core.MINIMAP_TOOLTIP_TEXT3, 1, 1, 1)
			tooltip:AddLine(" ")
			local text = RED_FONT_COLOR_CODE .. core.TRANSMOG_STATUS_UNKNOWN .. FONT_COLOR_CODE_CLOSE 
			if config then
				text = core.TRANSMOG_STATUS
				for i, name in ipairs(core.CONFIG_NAMES) do
					text = text .. (config == i and GREEN_FONT_COLOR_CODE or GRAY_FONT_COLOR_CODE) .. name .. FONT_COLOR_CODE_CLOSE .. (i < #core.CONFIG_NAMES and ", " or "")
				end
			end
			tooltip:AddLine(text, nil, nil, nil, nil)
			--tooltip:AddLine(config and "Transmog Status: " .. core.CONFIG_NAMES[config] or "Transmog Status konnte nicht abgefragt werden.")
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
