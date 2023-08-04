local folder, core = ...

core.CreateActiveSkinDropDown = function(parent)
	local skinDropDown = CreateFrame("Frame", folder .. "ActiveSkinDropDown", parent, "UIDropDownMenuTemplate")

	skinDropDown.noTransmogInfo = "No Data"

	skinDropDown.SetActiveSkin = function(self, arg1, arg2, checked)
		local skinID, skinName = arg1, arg2

        if core.GetActiveSkin() == skinID then return end

		if skinID and (not skinName or skinName == "") then -- Should not happen, since we don't add empty skin slots to our buttons
            UIErrorsFrame:AddMessage(core.SKIN_NEEDS_ACTIVATION, 1.0, 0.1, 0.1, 1.0)
		else
			core.RequestActivateSkin(skinID)
		end
		CloseDropDownMenus()
	end
	
	skinDropDown.Initialize = function(self, level)
        local skins = core.GetSkins()
		local orderedIDs = core.GetKeySet(skins)
        local activeSkin = core.GetActiveSkin()
		table.sort(orderedIDs) -- Give option to sort by name instead?

		skinDropDown.update()

		local info
		if level == 1 then
			-- No Skin
			info = UIDropDownMenu_CreateInfo()
			info.text = NONE
			info.arg1 = nil
			info.arg2 = nil
            info.func = self.SetActiveSkin
            info.checked = not activeSkin
			info.padding = 0
			UIDropDownMenu_AddButton(info, level)

			-- Skins
			for _, id in pairs(orderedIDs) do
                if skins[id].name and skins[id].name ~= "" then
                    info = UIDropDownMenu_CreateInfo()
                    info.text = skins[id].name -- SkinDisplay(skins, id) or (id .. ":") -- core.GetShortenedString(skins[id].name, 14) ?
                    info.arg1 = id
                    info.arg2 = skins[id].name
                    info.func = self.SetActiveSkin
                    info.checked = id == activeSkin
                    info.padding = 0
                    UIDropDownMenu_AddButton(info, level)
                end
			end
		end
	end

	skinDropDown.update = function()
		local skinName = core.GetActiveSkinName()
		local text = skinName or NONE
		UIDropDownMenu_SetText(skinDropDown, text)
	end
	skinDropDown.update()	

	core.RegisterListener("activeSkin", skinDropDown)
	core.RegisterListener("skins", skinDropDown)
	
	UIDropDownMenu_JustifyText(skinDropDown, "LEFT") 
	UIDropDownMenu_Initialize(skinDropDown, skinDropDown.Initialize)
    UIDropDownMenu_SetButtonWidth(skinDropDown, 40) -- Buttons get extended to fit biggest info.text

	UIDropDownMenu_SetWidth(skinDropDown, 100, 0)
    skinDropDown:SetScale(0.9)

    UIDropDownMenu_SetWidth(PlayerTitleFrame, 90)
    PlayerTitleFrame:ClearAllPoints()
    PlayerTitleFrame:SetPoint("TOPRIGHT", CharacterLevelText, "BOTTOM", 0, -9)
    skinDropDown:SetPoint("LEFT", PlayerTitleFrameButton, "RIGHT", 0, -2)
    skinDropDown:SetFrameLevel(skinDropDown:GetParent():GetFrameLevel() + 2 )
    skinDropDown:Show()
	
	return skinDropDown
end

