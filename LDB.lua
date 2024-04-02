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
	
-- TODO: Make minimap icon optional
core.InitLDB = function()
	local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)	
	if not LDBIcon then print("ERROR couldnt find LibDBIcon-1.0!") end

	if LDB then
		local LDBObj = LDB:NewDataObject(folder, {
			type = "launcher",
			label = folder,
			OnClick = function(_, msg)
				if msg == "LeftButton" then
					if IsShiftKeyDown() then
						core.OpenTransmogWindow()
					elseif not IsModifierKeyDown() then
						core.OpenWardrobe()
					end
				elseif msg == "RightButton" then
					-- TODDO: Temporary. Undecided how/where to this
					local config = core.GetConfig()
					if not config then return end
					nextConfig = config % 3 + 1
					core.RequestUpdateConfig(nextConfig)
				end
			end,
			icon = "Interface\\Icons\\Inv_chest_cloth_02",
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end

				if Icon_OnFirstTooltip then
					Icon_OnFirstTooltip(tooltip:GetOwner())
					Icon_OnFirstTooltip = nil
				end

				local config = core.GetConfig()

				tooltip:AddLine(folder)
				tooltip:AddLine(core.MINIMAP_TOOLTIP_TEXT1)
				tooltip:AddLine(core.MINIMAP_TOOLTIP_TEXT2)
				tooltip:AddLine(core.MINIMAP_TOOLTIP_TEXT3)
				tooltip:AddLine(" ")
				local text = core.TRANSMOG_STATUS_UNKNOWN
				if config then
					text = core.TRANSMOG_STATUS
					for i, name in ipairs(core.CONFIG_NAMES) do
						text = text .. (config == i and GREEN_FONT_COLOR_CODE or GRAY_FONT_COLOR_CODE) .. name .. FONT_COLOR_CODE_CLOSE .. (i < #core.CONFIG_NAMES and ", " or "")
					end
				end
				tooltip:AddLine(text)
				--tooltip:AddLine(config and "Transmog Status: " .. core.CONFIG_NAMES[config] or "Transmog Status konnte nicht abgefragt werden.")
			end,
		})


		TransmoggyDB["minimapIcon"] = TransmoggyDB["minimapIcon"] or
		{
			["minimapPos"] = 260,
			["hide"] = false
		}
		
		if LDBIcon then
			LDBIcon:Register(folder, LDBObj, TransmoggyDB.minimapIcon)
		end
	end
	core.InitLDB = nil
end