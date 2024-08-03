local folder, core = ...

local counter = 1
core.CreateActiveSkinDropDown = function(parent, menu)
	local skinDropDown = CreateFrame("Frame", folder .. "ActiveSkinDropDown" .. counter, parent, "UIDropDownMenuTemplate")
	counter = counter + 1

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
	-- core.RegisterListener("selectedSkin", skinDropDown) -- stands for any skin changes. as we only need to update the displayed name, we just care about active skin tho
	
	UIDropDownMenu_JustifyText(skinDropDown, "LEFT") 
	UIDropDownMenu_Initialize(skinDropDown, skinDropDown.Initialize, menu and "MENU" or nil)

	if not menu then
		UIDropDownMenu_SetButtonWidth(skinDropDown, 40)
		UIDropDownMenu_SetWidth(skinDropDown, 100, 0)
		skinDropDown:SetScale(0.9)
		skinDropDown:Hide()
	end
	
	return skinDropDown
end

core.activeSkinDropDown = core.CreateActiveSkinDropDown(PaperDollFrame)

core.activeSkinButton = core.CreateMeATextButton(CharacterModelFrame, 70, 20, core.SKINS)
core.activeSkinButton:SetFrameLevel(core.activeSkinButton:GetFrameLevel() + 2)
core.activeSkinButton:SetPoint("BOTTOMLEFT", 2, 24)
_G[folder .. "ActiveSkinButton"] = core.activeSkinButton -- dirty hack, so ToggleDropDownMenu can find the button
core.activeSkinButton.ddm = core.CreateActiveSkinDropDown(core.activeSkinButton, true)

core.activeSkinButton:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		ToggleDropDownMenu(nil, nil, self.ddm, _G[folder .. "ActiveSkinButton"], 0, 0)
	end
end)

-- show when we have bought a skin or when we have usable skins?
-- local usableSkinCount = 0
-- for _, skin in pairs(skins) do
-- 	if skin.name and skin.name ~= "" then
-- 		usableSkinCount = usableSkinCount + 1
-- 	end
-- end
core.UpdateSkinDropdown = function()
	local selected = core.db and core.db.profile.General.activeSkinDropdown
	local skins = core.GetSkins()
	local enableActiveSkinDropDown = (not selected or selected == "_02_dropdown") and skins and core.Length(skins) > 0 -- or check for usable skins?
	local enableActiveSkinButton = selected == "_03_button"
	-- TODO: can we remember the "before" title dropdown width? titleFrameWidthOrig = UIDropDownMenu_GetWidth(PlayerTitleFrame)
	-- also remember point?

	-- /run print(PlayerTitleFrame:IsShown()) works as we want, so check this and place skins full width if we have no titles (which is probably never the case, that we have a skin but no title ...)

	if enableActiveSkinDropDown and not core.activeSkinDropDown:IsShown() then
		UIDropDownMenu_SetWidth(PlayerTitleFrame, 90)
		PlayerTitleFrame:ClearAllPoints()
		PlayerTitleFrame:SetPoint("TOPRIGHT", CharacterLevelText, "BOTTOM", 0, -9)
		core.activeSkinDropDown:SetPoint("LEFT", PlayerTitleFrameButton, "RIGHT", -12, -2)
		core.activeSkinDropDown:SetFrameLevel(core.activeSkinDropDown:GetParent():GetFrameLevel() + 2)
		core.activeSkinDropDown:Show()
	elseif not enableActiveSkinDropDown and core.activeSkinDropDown:IsShown() then
		core.activeSkinDropDown:Hide()
		UIDropDownMenu_SetWidth(PlayerTitleFrame, 160)
		PlayerTitleFrame:ClearAllPoints()
		PlayerTitleFrame:SetPoint("TOP", CharacterLevelText, "BOTTOM", 0, -9)
	end

	core.SetShown(core.activeSkinButton, enableActiveSkinButton)
end

PaperDollFrame:HookScript("OnShow", core.UpdateSkinDropdown)