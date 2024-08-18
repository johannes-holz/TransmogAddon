local folder, core = ...

-- Could probably be changed to use 1-2 generic popups (maybe 1 with, 1 without editbox)
-- And set everything depending on a data table in OnShow()

local MAX_LETTERS_POPUP = 20
local MAX_LETTERS_DROPDOWN = 50

StaticPopupDialogs["BuySkinPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)
		local costs = core.GetSkinCosts()
		local balance = core.GetBalance()
		if not costs.copper or not balance.shards then
			UIErrorsFrame:AddMessage(core.APPLY_ERROR1, 1.0, 0.1, 0.1, 1.0)
		elseif GetMoney() < costs.copper or balance.shards < costs.points then
			UIErrorsFrame:AddMessage(core.APPLY_ERROR2, 1.0, 0.1, 0.1, 1.0)
		else
			core.RequestBuySkin()
		end
	end,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		if data.disable then
			StaticPopup1Button1:Disable()
		end
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["RenameSkinPopup"] = {
	text = "",
	button1 = SAVE,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		core.AttemptSkinRename(data.id, self.editBox:GetText())
	end,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		self.editBox:SetFocus();
		self.editBox:SetMaxLetters(50)
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		core.AttemptSkinRename(data.id, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

-- core.popupDelayEnabled = true
-- core.GetPopupDelay = function()
-- 	return 5
-- end

StaticPopupDialogs["ResetSkinPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)
		core.RequestSkinReset(data.id)
	end,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		if data.disable then
			StaticPopup1Button1:Disable()
		end
	end,
	-- StartDelay = core.popupDelayEnabled and core.GetPopupDelay or nil -- does not show a timer on the button and requires the text to be set in global var. not a fan
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["TransferVisualsToSkinPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)		
		local costs = data.costs
		local balance = core.GetBalance()
		if not costs.copper or not balance.shards then
			UIErrorsFrame:AddMessage(core.APPLY_ERROR1, 1.0, 0.1, 0.1, 1.0)
		elseif GetMoney() < costs.copper or balance.shards < costs.points then
			UIErrorsFrame:AddMessage(core.APPLY_ERROR2, 1.0, 0.1, 0.1, 1.0)
		else
			core.RequestTransferVisualsToSkin(data.id)
		end
	end,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		if data.disable then
			StaticPopup1Button1:Disable()
		end
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

core.SkinPopupDisplay = function(id, name)
	-- " \"" .. id + 1 .. ": " .. core.GetShortenedString(name, MAX_LETTERS_POPUP) .. "\" "
	return "\"" .. core.GetShortenedString(name, MAX_LETTERS_POPUP) .. "\"" .. " (" .. core.SKIN_SLOT .. " " .. (id  + 1) .. ")"
end

local ShowBuySkinPopup = function()
	local costs = core.GetSkinCosts()
	local balance = core.GetBalance()
	local data = {}
	-- data.disable = not costs.points or not costs.copper or not balance.shards or costs.points > balance.shards or costs.copper > GetMoney()
	data.text = core.BUY_SKIN_TEXT .. "\n\n" .. (costs.points and costs.copper and core.GetPriceString(costs.points, costs.copper)
														or ("|cffff1111" .. core.NO_SKIN_COSTS_ERROR .. "|r"))
				
	StaticPopup_Show("BuySkinPopup", nil, nil, data)
end

local ShowRenameSkinPopup = function(id)
	local data = {}
	data.id = id
	data.oldName = core.GetSkins()[id].name
	data.text = core.RENAME_SKIN_TEXT1 .. " " .. core.SkinPopupDisplay(data.id, data.oldName) .. " " .. core.RENAME_SKIN_TEXT2

	StaticPopup_Show("RenameSkinPopup", nil, nil, data)
end

local ShowCreateSkinPopup = function(id)
	local data = {}
	data.id = id
	data.text = core.CREATE_SKIN_TEXT1 .. data.id + 1 .. core.CREATE_SKIN_TEXT2

	StaticPopup_Show("RenameSkinPopup", nil, nil, data)
end

local ShowResetSkinPopup = function(id)
	local data = {}
	data.id = id
	data.name = core.GetSkins()[id].name
	data.text = core.RESET_SKIN_TEXT1 .. " " .. core.SkinPopupDisplay(data.id, data.name) .. " " .. core.RESET_SKIN_TEXT2

	StaticPopup_Show("ResetSkinPopup", nil, nil, data)
end

core.ShowVisualsToSkinPopup = function(id, costs)
	local skins = core.GetSkins()
	local balance = core.GetBalance()
	assert(skins and skins[id] and balance and costs)
	costs.points = costs.points or costs.shards

	local lines = {}
	for _, slot in ipairs(core.allSlots) do
		local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot, id)
		if visualID and visualID ~= core.UNMOG_ID and (not skinVisualID or skinVisualID == core.UNMOG_ID) then
			local link = visualID ~= core.HIDDEN_ID and core.LinkToColoredString(select(2, GetItemInfo(visualID))) or core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)
			tinsert(lines, core.SLOT_NAMES[slot])
			tinsert(lines, ": ")
			tinsert(lines, link or visualID)
			tinsert(lines, "\n")
		end
	end			

	local data = {}
	data.id = id
	data.name = skins[id].name
	data.costs = costs
	-- data.disable = not costs.points or not costs.copper or not balance.shards or costs.points > balance.shards or costs.copper > GetMoney()
	data.disable = not costs.points or not costs.copper or not balance.shards
	data.text = core.VISUALS_TO_SKIN_TEXT1 .. " " .. core.SkinPopupDisplay(data.id, data.name) .. ". "
					.. core.VISUALS_TO_SKIN_TEXT2 .. "\n\n"
					.. table.concat(lines) .. "\n"
					.. (costs.points and costs.copper and core.GetPriceString(costs.points, costs.copper) or "ERROR: Could not request costs from server.")				
	local popup = StaticPopup_Show("TransferVisualsToSkinPopup", nil, nil, data)
end

local HasVisualsToTransfer = function(id)
	local skins = core.GetSkins()
	if not skins or not skins[id] or not skins[id].name or skins[id].name == "" then return false end

	for _, slot in pairs(core.itemSlots) do
		local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot, id)
		if visualID and visualID > 0 and (not skinVisualID or skinVisualID == 0) then
			return true
		end
	end

	return false
end

local CanReset = function(id)
	local skins = core.GetSkins()
	return skins and skins[id] and skins[id].name and 1 or nil
end

local SkinDisplay = function(skins, id)
	if not id or not skins or not skins[id] then return end
	local name = skins[id].name
	return (core.Length(skins) > 9 and id < 9 and "  " or "") .. (id + 1) .. ":  "
		.. (name and name ~= "" and core.GetShortenedString(name, MAX_LETTERS_DROPDOWN) or core.GetColoredString(core.EMPTY_SKIN_SLOT, core.yellowTextColor.hex))
end


core.CreateSkinDropDown = function(parent)
	local skinDropDown = CreateFrame("Frame", folder .. "SkinDropDown", parent, "UIDropDownMenuTemplate")
	--UIDropDownMenu_SetWidth(skinDropDown, 100, 0) -- Use in place of dropDown:SetWidth

	skinDropDown.normalTransmog = "~~ Normal Transmog ~~"

	skinDropDown.SelectSkin = function(self, arg1, arg2, checked) -- arg1: id, arg2: name
		local skinID, skinName = arg1, arg2

		if not skinName or skinName == "" then
			ShowCreateSkinPopup(skinID)
		else
			core.SetSelectedSkin(skinID)
			core.SetSlotAndCategory(nil, nil)
		end
		CloseDropDownMenus()
	end

	skinDropDown.SetActiveSkin = function(self, arg1, arg2, checked)
		local skinID, skinName = arg1, arg2

        if core.GetActiveSkin() == skinID then return end

		if skinID and (not skinName or skinName == "") then -- Should not happen, since we deactivate button
            UIErrorsFrame:AddMessage(core.SKIN_NEEDS_ACTIVATION, 1.0, 0.1, 0.1, 1.0)
		else
			core.RequestActivateSkin(skinID)
		end
		CloseDropDownMenus()
	end
	
	skinDropDown.firstInit = true	
	skinDropDown.Initialize = function(self, level)
        local skins = core.GetSkins()
		local orderedIDs = core.GetKeySet(skins)
		local selectedID = core.GetSelectedSkin()
		--local selectedSkinName = core.GetSelectedSkinName()
		table.sort(orderedIDs)

		--UIDropDownMenu_SetSelectedName(skinDropDown, SkinDisplay(skins, selectedID) or skinDropDown.normalTransmog)
		skinDropDown.update()

		--TODO: wenn doppelnamen erlaubt, umstellen auf: Ermittle setposition in orderedIDS und benutze UIDropDownMenu_SetSelectedID: text nochmal extra setzen weil random texte von anderen DDMs auftauchen...
		--UIDropDownMenu_SetSelectedID(setDDM,2)
		--UIDropDownMenu_SetText(setDDM, orderedKeys[2])
		--core.am(UIDROPDOWNMENU_OPEN_MENU:GetName(), UIDROPDOWNMENU_OPEN_MENU, UIDROPDOWNMENU_INIT_MENU )
		
		local info
		if level == 1 then
			-- Skins
			for _, id in pairs(orderedIDs) do
				info = UIDropDownMenu_CreateInfo()
				info.text = SkinDisplay(skins, id) or id .. ":"
				info.arg1 = id
				info.arg2 = skins[id].name
				info.func = skinDropDown.SelectSkin
				info.checked = id == selectedID
				info.padding = 0
				info.hasArrow = true
				info.value = { ["levelOneKey"] = id } --sonst auch über menulist https://wow.gamepedia.com/Using_UIDropDownMenu
				--info.minWidth = 200 ace lib function
				UIDropDownMenu_AddButton(info, level)
			end

			-- Create new Set Button
			info = UIDropDownMenu_CreateInfo()
			info.text = "|TInterface\\Icons\\Spell_ChargePositive:14:14:0:0|t " .. core.BUY_SKIN_SLOT .. "|r"
			--info.icon = "Interface\\Icons\\Spell_ChargePositive"
			info.arg1 = info.text
			info.notCheckable = true
			--info.leftPadding = 100 --ace only
			--info.padding = 120
			info.func = function(self, arg1, arg2, checked)
				ShowBuySkinPopup()
				CloseDropDownMenus()
			end
			info.value = info.text
			info.colorCode = "|cff00ff00"
			info.justifyH = "CENTER" -- akzeptiert kein RIGHT?
			UIDropDownMenu_AddButton(info, level)
			
		elseif level == 2 then
			local id = UIDROPDOWNMENU_MENU_VALUE["levelOneKey"]	
			local name = skins[id].name
			if name and name ~= "" then
				----- Select -----------------------------------------------------------------------
				info = UIDropDownMenu_CreateInfo()						
				info.text = core.SELECT
				info.arg1 = id
				info.arg2 = name
				info.value = { ["levelOneKey"] = id, ["levelTwoKey"] = core.SELECT}
				info.notCheckable = true
				info.padding = 0
				info.func = skinDropDown.SelectSkin
				UIDropDownMenu_AddButton(info, level)	
				----- Activate -----------------------------------------------------------------------
				info = UIDropDownMenu_CreateInfo()						
				info.text = core.ACTIVATE
				info.arg1 = id
				info.arg2 = name
				info.value = { ["levelOneKey"] = id, ["levelTwoKey"] = core.ACTIVATE}
				info.notCheckable = true
				info.padding = 0
				info.func = skinDropDown.SetActiveSkin
				info.disabled = id == core.GetActiveSkin()
				UIDropDownMenu_AddButton(info, level)	
				----- Rename -----------------------------------------------------------------------
				info = UIDropDownMenu_CreateInfo()						
				info.text = core.RENAME
				info.arg1 = levelOneKey
				info.value = { ["levelOneKey"] = id, ["levelTwoKey"] = core.RENAME}
				info.notCheckable = true
				info.padding = 0
				info.func = function(self, arg1, arg2, checked)
					ShowRenameSkinPopup(id)
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)
				----- Transfer Visuals -----------------------------------------------------------------------
				info = UIDropDownMenu_CreateInfo()						
				info.text = core.TRANSFER
				info.arg1 = id
				info.value = { ["levelOneKey"] = id, ["levelTwoKey"] = core.TRANSFER}
				info.notCheckable = true
				info.padding = 0
				info.disabled = not HasVisualsToTransfer(id)
				info.func = function(self, arg1, arg2, checked)
					core.RequestTransferPriceAndOpenPopup(id)
					--ShowVisualsToSkinPopup(levelOneKey, {points = 10, copper = 150})
					CloseDropDownMenus()
				end
				info.value = info.text
				UIDropDownMenu_AddButton(info, level)	
				----- Reset -----------------------------------------------------------------------
				info = UIDropDownMenu_CreateInfo()						
				info.text = core.RESET
				info.arg1 = id
				info.value = { ["levelOneKey"] = id, ["levelTwoKey"] = core.RESET}
				info.notCheckable = true
				info.padding = 0
				info.disabled = not skins or not skins[id] or not skins[id].name or skins[id].name == ""
				info.func = function(self, arg1, arg2, checked)
					ShowResetSkinPopup(id)
					CloseDropDownMenus()
				end
				info.value = info.text
				UIDropDownMenu_AddButton(info, level)	
			else
				----- Create -----------------------------------------------------------------------
				info = UIDropDownMenu_CreateInfo()						
				info.text = core.CREATE
				info.arg1 = id
				info.arg2 = name
				info.value = { ["levelOneKey"] = id, ["levelTwoKey"] = core.CREATE}
				info.notCheckable = true
				info.padding = 0
				info.func = skinDropDown.SelectSkin
				UIDropDownMenu_AddButton(info, level)
			end
		end

		--UIDropDownMenu_SetWidth(skinDropDown, 100, 0) -- Use in place of dropDown:SetWidth. irrelevant for context style menu
		UIDropDownMenu_SetButtonWidth(skinDropDown, 40)
	end

	skinDropDown.update = function()
		local skinName = core.GetSelectedSkinName()
		local text = skinName and ("Editing Skin: \'" .. skinName .. "\'") or "Transmogrify items or choose a Skin ..."
		UIDropDownMenu_SetText(skinDropDown, text)
	end
	skinDropDown.update()	

	core.RegisterListener("selectedSkin", skinDropDown)
	core.RegisterListener("skins", skinDropDown)
	
	UIDropDownMenu_JustifyText(skinDropDown, "LEFT") 
	UIDropDownMenu_Initialize(skinDropDown, skinDropDown.Initialize, "MENU")
	
	return skinDropDown
end