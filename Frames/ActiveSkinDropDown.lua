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
		local text = skinName or core.SELECT_SKIN
		UIDropDownMenu_SetText(skinDropDown, text)
	end
	skinDropDown.update()	

	core.RegisterListener("activeSkin", skinDropDown)
	core.RegisterListener("skins", skinDropDown)
	
	UIDropDownMenu_JustifyText(skinDropDown, "LEFT") 
	UIDropDownMenu_Initialize(skinDropDown, skinDropDown.Initialize)
    UIDropDownMenu_SetButtonWidth(skinDropDown, 40)

	UIDropDownMenu_SetWidth(skinDropDown, 100, 0)
    skinDropDown:SetScale(0.9)
    skinDropDown:Hide()
	
	return skinDropDown
end

core.activeSkinDropDown = core.CreateActiveSkinDropDown(PaperDollFrame)

PaperDollFrame:HookScript("OnShow", function(self)
	local skins = core.GetSkins()
	-- local usableSkinCount = 0
	-- for _, skin in pairs(skins) do
	-- 	if skin.name and skin.name ~= "" then
	-- 		usableSkinCount = usableSkinCount + 1
	-- 	end
	-- end
	-- show when we have bought a skin or when we have usable skins?
	if skins and core.Length(skins) > 0 and not core.activeSkinDropDown:IsShown() then  -- TODO: dropdown / button / nothing? option
		UIDropDownMenu_SetWidth(PlayerTitleFrame, 90)
		PlayerTitleFrame:ClearAllPoints()
		PlayerTitleFrame:SetPoint("TOPRIGHT", CharacterLevelText, "BOTTOM", 0, -9)
		core.activeSkinDropDown:SetPoint("LEFT", PlayerTitleFrameButton, "RIGHT", -12, -2)
		core.activeSkinDropDown:SetFrameLevel(core.activeSkinDropDown:GetParent():GetFrameLevel() + 2)
		core.activeSkinDropDown:Show()
	end
end)