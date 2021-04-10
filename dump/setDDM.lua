MyAddon, myadd = ...


local function NewSet(name)
	if string.len(name)<1 then
		am("Setnames must be at least one character long.")
	else
		MyAddonDB.sets[name] = deepCopy(MyAddonDB.currentChanges) or {}
		MyAddonDB.selectedSet = name
		UIDropDownMenu_SetText(setDDMNew, name) --Selection checkmark gets set, when setDDMNew gets opened
		SetSlotAndCategory(nil, nil)
		UpdateItemSlots() --still needed for changes between selected set and currentchanges update (altho slotandcat triggers itemslotsupdates anyway)
		return true
	end
end

local function TryRenameSet(id, new)
	if string.len(new)<1 then
		am("Setnames must be at least one character long.")
	else
		RequestSetRename(id, new)
	end
end

local GetFreeSetID = function() --TODO: temporary while having to create own ids
	local id = 1
	local usedIDs = {}
	MyAddonDB.sets = MyAddonDB.sets or {}
	for k, _ in pairs(MyAddonDB.sets) do
		usedIDs[k] = true
	end
	
	while true do
		if contains(usedIDs, id) do
			id = id + 1
		else
			return id
		end
	end
end

AddSet = function(name)
	if string.len(name)<1 then
		am("Setnames must be at least one character long.")
		return
	end
	
	local id = GetFreeSetID()
	
	MyAddonDB.sets = MyAddonDB.sets or {}
	MyAddonDB.sets[id] = {["name"] = name, ["isSpecial"] = false, ["transmogs"] = {}}
	SetSelectedSet(id)
	
	am(MyAddonDB.sets)
	am(MyAddonDB.selectedSet)
end

RenameSet = function(id, newName) --just changes name, so no updates to anything needed except updating the DDM Text? (TODO: change ddm to listener model?)
	--assert existing setID
	if string.len(name)<1 then
		am("Setnames must be at least one character long.")
		return
	end
	
	mySets[id]["name"] = newName
	am("rename", id, "to", newName)
	
	if MyAddonDB.selectedSet and id == MyAddonDB.selectedSet then
		UpdateListeneres("selectedSet")
	end
end



StaticPopupDialogs["NewSetPopup"] = {
	text = "Enter Outfit Name:",
	button1 = SAVE,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		AddSet(self.editBox:GetText())
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
		self.editBox:SetMaxLetters(22)
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		AddSet(self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["RenameSetPopup"] = {
	text = "Enter new Outfit Name for %s:",
	button1 = SAVE,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		RenameSet(toBeRenamed, self.editBox:GetText())
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
		self.editBox:SetMaxLetters(22)
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		RenameSet(toBeRenamed, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
}

local GetSetIDsOrderedByName = function()
	local ids = {}
	for id, _ in pairs(MyAddonDB.sets) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		local nameA = string.lower(MyAddonDB.sets[a]["name"])
		local nameB = string.lower(MyAddonDB.sets[b]["name"])
		
		if nameA == nameB then
			return a < b
		else
			return nameA < nameB
		end
	end
	
	return ids
end

MyAddonDB.sets = MyAddonDB.sets or {}

CreateSetDDM = function(parent)
	local setDDMNew = CreateFrame("Frame", "SetDDMNew", parent, "UIDropDownMenuTemplate")
	setDDMNew:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", -12, -8)
	UIDropDownMenu_SetWidth(setDDMNew, 160) -- Use in place of dropDown:SetWidth

	setDDMNew.SelectSet = function(self, arg1, arg2, checked) -- arg1: id, arg2: name
		SetSelectedSet(arg1)
		SetCurrentChanges(MyAddonDB.sets[arg1]["transmogs"])
		SetSlotAndCategory(nil, nil)
		--am(MyAddonDB.sets[MyAddonDB.selectedSet]["ChestSlot"])
		--MyAddonDB.currentChanges = deepCopy(MyAddonDB.sets[MyAddonDB.selectedSet]) --TODO: completely fucked up model view stuff, überlegen wies richtig geht
		--UpdateItemSlots() --gets called 3 times here :/ inefficient, but probably still preferable from a programming standpoint?
		--TODO: codedopplung in remove
		--currentChanges = MyAddonDB.sets[selectedSet]
		--updateModel()
		--UIDropDownMenu_SetSelectedName(setDDMNew,arg1)
		--UIDropDownMenu_SetText(setDDMNew, arg1) --wird bei buttons with hasArrow nicht gesetzt, ffs
		
		--UIDropDownMenu_SetSelectedName(setDDMNew,"Blue")
		--am(arg1)
	end
	--setDDMNew.deleteSet = function(self, arg1, arg2, checked)
		
	setDDMNew.firstInit = true	
	local orderedIDs
	
	setDDMNew.Initialize = function(self, level)		
		if MyAddonDB.selectedSet then 
			UIDropDownMenu_SetSelectedName(setDDMNew, MyAddonDB.sets[MyAddonDB.selectedSet]["name"]) --We can't set selection until menu opens again, so we do it here
		end
		--TODO: wenn doppelnamen erlaubt, umstellen auf: Ermittle setposition in orderedIDS und benutze UIDropDownMenu_SetSelectedID: text nochmal extra setzen weil random texte von anderen DDMs auftauchen...
		--UIDropDownMenu_SetSelectedID(setDDM,2)
		--UIDropDownMenu_SetText(setDDM, orderedKeys[2])
		--am(UIDROPDOWNMENU_OPEN_MENU:GetName(), UIDROPDOWNMENU_OPEN_MENU, UIDROPDOWNMENU_INIT_MENU )
		orderedIDs = GetSetIDsOrderedByName()
		
		local info
		if level == 1 then
			--Sets
			for _, id in pairs(orderedIDs) do
				info = UIDropDownMenu_CreateInfo()
				info.text = MyAddonDB.sets[id]["name"]
				info.func = setDDMNew.SelectSet
				info.arg1 = id
				info.arg2 = name
				--info.icon = "Interface\\AddOns\\_myaddon\\images\\sm2"
				info.padding = 20
				info.hasArrow = true
				info.value = { ["levelOneKey"] = id} --sonst auch über menulist https://wow.gamepedia.com/Using_UIDropDownMenu
				--info.minWidth = 200 ace lib function
				UIDropDownMenu_AddButton(info, level)
			end
			--Create new Set Button
			info = UIDropDownMenu_CreateInfo()
			info.text = "New Outfit|r"
			info.icon = "Interface\\Icons\\Spell_ChargePositive"
			info.arg1 = info.text
			info.notCheckable = true
			--info.leftPadding = 100 --ace only
			info.padding = 120
			info.func = function(self, arg1, arg2, checked)
				StaticPopup_Show("NewSetPopup")
			end
			info.value = info.text
			info.colorCode = "|cff00ff00"
			info.justifyH = "CENTER"--akzeptiert kein RIGHT?
			UIDropDownMenu_AddButton(info, level)
			
		elseif level == 2 then
			local levelOneKey = UIDROPDOWNMENU_MENU_VALUE["levelOneKey"]
			
			info = UIDropDownMenu_CreateInfo()
			
			
			
			--TODO: Share
			
			
			
			----------------------------------------------------------------------------			
			info.text = "Rename"
			info.arg1 = info.text
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = "Rename"}
			info.notCheckable = true
			info.padding = 20
			info.func = function(self, arg1, arg2, checked)
				local toBeRenamed = levelOneKey
				StaticPopup_Show("RenameSetPopup", toBeRenamed)
				CloseDropDownMenus()
			end
			info.value = info.text
			UIDropDownMenu_AddButton(info, level)			
			----------------------------------------------------------------------------
			--[[info.text = "Delete"
			info.arg1 = info.text
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = "Delete"}
			info.notCheckable = true
			info.padding = 20
			info.func = function(self, arg1, arg2, checked)
				--TODO: codeDopplung, methode schreiben?!
				MyAddonDB.sets[levelOneKey] = nil
				if MyAddonDB.selectedSet == levelOneKey then
					wipe(orderedKeys)		
					for k in pairs(MyAddonDB.sets) do
						table.insert(orderedKeys, k)
					end
					table.sort(orderedKeys, function(a, b)
						return string.lower(a) < string.lower(b)
					end)
					MyAddonDB.selectedSet = orderedKeys[1]
					if MyAddonDB.selectedSet then
						SetCurrentChanges(MyAddonDB.sets[MyAddonDB.selectedSet])
						UIDropDownMenu_SetSelectedName(setDDMNew, MyAddonDB.selectedSet)
						UIDropDownMenu_SetText(setDDMNew, MyAddonDB.selectedSet)
					else
						SetCurrentChanges({})
						UIDropDownMenu_SetText(setDDMNew, "Sets")
					end
					SetSlotAndCategory(nil, nil)
				end
				CloseDropDownMenus()
			end
			info.value = info.text
			UIDropDownMenu_AddButton(info, level)
			--]]
			
		end
		if setDDMNew.firstInit then
			if MyAddonDB.selectedSet then
				UIDropDownMenu_SetSelectedName(setDDMNew,MyAddonDB.selectedSet)
				UIDropDownMenu_SetText(setDDMNew, MyAddonDB.selectedSet)
			else
				UIDropDownMenu_SetText(setDDMNew, "Sets")
			end
			setDDMNew.firstInit = false
		end
	end
	setDDMNew.update = function()		
		if MyAddonDB.selectedSet then
			UIDropDownMenu_SetSelectedName(setDDMNew,MyAddonDB.selectedSet)
			UIDropDownMenu_SetText(setDDMNew, MyAddonDB.selectedSet)
		else
			UIDropDownMenu_SetText(setDDMNew, "Sets")
		end
	end
	setDDMNew.update()
	RegisterListener("selectedSet", setDDMNew)
	
	UIDropDownMenu_JustifyText(setDDMNew, "LEFT") 
	UIDropDownMenu_Initialize(setDDMNew, setDDMNew.Initialize)
	
	return setDDMNew
end