local maxRetries, batchSize = 2, 10000 --Länger läuft ne session eh nicht

local function CheckItemBatch(itemID, retries, remainingItems)
	retries = retries or maxRetries
	remainingItems = remainingItems or batchSize
	--am(itemID..", "..retries..", "..remainingItems)
	--itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent
	if not itemID then return end
	if GetItemInfo(itemID) == nil then
		if retries < 1 then
			MyAddonDB.lastChecked = MyAddonDB.lastChecked + 1
			if remainingItems > 1 then
				CheckItemBatch(itemID+1, maxRetries, remainingItems-1)
			else
				am("Itembatch complete.")
			end
			return
		end
		GameTooltip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0"); --TODO: Beste Lösung um auf server daten zu warten bevor weiter gemacht wird?
		MyWaitFunction(0.1*(maxRetries+1-retries), CheckItemBatch, itemID, retries-1, remainingItems)
	else
		--am("Got item info: "..itemID)
		local iName, _, _, _, _, iType, iSubType, _, itemSlot = GetItemInfo(itemID);
		local itemType = iType.." "..iSubType
		--am(itemType)
		if invSlots[itemSlot] then
			--am("Found chest: "..itemID)
			--table.insert(chests, itemID)
			if not MyAddonDB.items then
				MyAddonDB.items = {
					["plate"] = {
						["head"] = {}, ["shoulder"] = {}, ["chest"] = {}, ["wrist"] = {}, ["hands"] = {}, ["waist"] = {}, ["legs"] = {}, ["feet"] = {}, },
					["mail"] = {
						["head"] = {}, ["shoulder"] = {}, ["chest"] = {}, ["wrist"] = {}, ["hands"] = {}, ["waist"] = {}, ["legs"] = {}, ["feet"] = {}, },
					["leather"] = {
						["head"] = {}, ["shoulder"] = {}, ["chest"] = {}, ["wrist"] = {}, ["hands"] = {}, ["waist"] = {}, ["legs"] = {}, ["feet"] = {}, },
					["cloth"] = {
						["head"] = {}, ["shoulder"] = {}, ["chest"] = {}, ["wrist"] = {}, ["hands"] = {}, ["waist"] = {}, ["legs"] = {}, ["feet"] = {}, },
					["misc"] = {
						["head"] = {}, ["shoulder"] = {}, ["chest"] = {}, ["wrist"] = {}, ["hands"] = {}, ["waist"] = {}, ["legs"] = {}, ["feet"] = {}, },
					["onehanded"] = {
						["axe"] = {}, ["dagger"] = {}, ["fistweapon"] = {}, ["mace"] = {}, ["sword"] = {}, ["misc"] = {}, },
					["mainhand"] = {
						["axe"] = {}, ["dagger"] = {}, ["fistweapon"] = {}, ["mace"] = {}, ["sword"] = {}, ["misc"] = {}, },
					["offhand"] = {
						["axe"] = {}, ["dagger"] = {}, ["fistweapon"] = {}, ["mace"] = {}, ["sword"] = {}, ["misc"] = {}, },
					["twohanded"] = {
						["axe"] = {}, ["polearm"] = {}, ["staff"] = {}, ["mace"] = {}, ["sword"] = {}, ["fishingpole"] = {}, ["misc"] = {}, },
					["ranged"] = {
						["bow"] = {}, ["crossbow"] = {}, ["gun"] = {}, ["thrown"] = {}, ["wand"] = {}, ["misc"] = {}, },
					["other"] = {
						["shield"] = {}, ["offhand"] = {}, ["cloak"] = {}, ["misc"] = {}, },						
					["accessories"] = {
						["shirt"] = {}, ["tabard"] = {},},}
			end
			local cat, slot
			if itemType == "Rüstung Platte" then
				cat = "plate"
				if invSlots[itemSlot] == "HeadSlot" then
					slot = "head"
				elseif invSlots[itemSlot] == "ShoulderSlot" then
					slot = "shoulder"
				elseif invSlots[itemSlot] == "ChestSlot" then
					slot = "chest"
				elseif invSlots[itemSlot] == "WristSlot" then
					slot = "wrist"
				elseif invSlots[itemSlot] == "HandsSlot" then
					slot = "hands"
				elseif invSlots[itemSlot] == "WaistSlot" then
					slot = "waist"
				elseif invSlots[itemSlot] == "LegsSlot" then
					slot = "legs"
				elseif invSlots[itemSlot] == "FeetSlot" then
					slot = "feet"
				end
			elseif itemType == "Rüstung Schwere Rüstung" then
				cat = "mail"
				if invSlots[itemSlot] == "HeadSlot" then
					slot = "head"
				elseif invSlots[itemSlot] == "ShoulderSlot" then
					slot = "shoulder"
				elseif invSlots[itemSlot] == "ChestSlot" then
					slot = "chest"
				elseif invSlots[itemSlot] == "WristSlot" then
					slot = "wrist"
				elseif invSlots[itemSlot] == "HandsSlot" then
					slot = "hands"
				elseif invSlots[itemSlot] == "WaistSlot" then
					slot = "waist"
				elseif invSlots[itemSlot] == "LegsSlot" then
					slot = "legs"
				elseif invSlots[itemSlot] == "FeetSlot" then
					slot = "feet"
				end
			elseif itemType == "Rüstung Leder" then
				cat = "leather"
				if invSlots[itemSlot] == "HeadSlot" then
					slot = "head"
				elseif invSlots[itemSlot] == "ShoulderSlot" then
					slot = "shoulder"
				elseif invSlots[itemSlot] == "ChestSlot" then
					slot = "chest"
				elseif invSlots[itemSlot] == "WristSlot" then
					slot = "wrist"
				elseif invSlots[itemSlot] == "HandsSlot" then
					slot = "hands"
				elseif invSlots[itemSlot] == "WaistSlot" then
					slot = "waist"
				elseif invSlots[itemSlot] == "LegsSlot" then
					slot = "legs"
				elseif invSlots[itemSlot] == "FeetSlot" then
					slot = "feet"
				end
			elseif itemType == "Rüstung Stoff" then
				cat = "cloth"
				if invSlots[itemSlot] == "HeadSlot" then
					slot = "head"
				elseif invSlots[itemSlot] == "ShoulderSlot" then
					slot = "shoulder"
				elseif invSlots[itemSlot] == "ChestSlot" then
					slot = "chest"
				elseif invSlots[itemSlot] == "WristSlot" then
					slot = "wrist"
				elseif invSlots[itemSlot] == "HandsSlot" then
					slot = "hands"
				elseif invSlots[itemSlot] == "WaistSlot" then
					slot = "waist"
				elseif invSlots[itemSlot] == "LegsSlot" then
					slot = "legs"
				elseif invSlots[itemSlot] == "FeetSlot" then
					slot = "feet"
				elseif itemSlot == "INVTYPE_CLOAK" then
					cat = "other"
					slot = "cloak"
				end
			elseif itemType == "Rüstung Verschiedenes" then
				cat = "misc"
				if invSlots[itemSlot] == "HeadSlot" then
					slot = "head"
				elseif invSlots[itemSlot] == "ShoulderSlot" then
					slot = "shoulder"
				elseif invSlots[itemSlot] == "ChestSlot" then
					slot = "chest"
				elseif invSlots[itemSlot] == "WristSlot" then
					slot = "wrist"
				elseif invSlots[itemSlot] == "HandsSlot" then
					slot = "hands"
				elseif invSlots[itemSlot] == "WaistSlot" then
					slot = "waist"
				elseif invSlots[itemSlot] == "LegsSlot" then
					slot = "legs"
				elseif invSlots[itemSlot] == "FeetSlot" then
					slot = "feet"
				elseif itemSlot == "INVTYPE_HOLDABLE" then
					cat = "other"
					slot = "offhand"
				elseif itemSlot == "INVTYPE_BODY" then
					cat = "accessories"
					slot = "shirt"
				elseif itemSlot == "INVTYPE_TABARD" then
					cat = "accessories"
					slot = "tabard"
				end
			elseif itemType == "Waffe Dolche" then
				slot = "dagger"
				if itemSlot == "INVTYPE_WEAPON" then
					cat = "onehanded"
				elseif itemSlot == "INVTYPE_WEAPONMAINHAND" then
					cat = "mainhand"
				elseif itemSlot == "INVTYPE_WEAPONOFFHAND" then
					cat = "offhand"
				end
			elseif itemType == "Waffe Einhandäxte" then
				slot = "axe"
				if itemSlot == "INVTYPE_WEAPON" then
					cat = "onehanded"
				elseif itemSlot == "INVTYPE_WEAPONMAINHAND" then
					cat = "mainhand"
				elseif itemSlot == "INVTYPE_WEAPONOFFHAND" then
					cat = "offhand"
				end
			elseif itemType == "Waffe Einhandschwerter" then
				slot = "sword"
				if itemSlot == "INVTYPE_WEAPON" then
					cat = "onehanded"
				elseif itemSlot == "INVTYPE_WEAPONMAINHAND" then
					cat = "mainhand"
				elseif itemSlot == "INVTYPE_WEAPONOFFHAND" then
					cat = "offhand"
				end
			elseif itemType == "Waffe Einhandstreitkolben" then
				slot = "mace"
				if itemSlot == "INVTYPE_WEAPON" then
					cat = "onehanded"
				elseif itemSlot == "INVTYPE_WEAPONMAINHAND" then
					cat = "mainhand"
				elseif itemSlot == "INVTYPE_WEAPONOFFHAND" then
					cat = "offhand"
				end
			elseif itemType == "Waffe Faustwaffen" then
				slot = "fistweapon"
				if itemSlot == "INVTYPE_WEAPON" then
					cat = "onehanded"
				elseif itemSlot == "INVTYPE_WEAPONMAINHAND" then
					cat = "mainhand"
				elseif itemSlot == "INVTYPE_WEAPONOFFHAND" then
					cat = "offhand"
				end
			elseif itemType == "Waffe Zweihandäxte" then
				slot = "axe"
				if itemSlot == "INVTYPE_2HWEAPON" then
					cat = "twohanded"
				end	
			elseif itemType == "Waffe Zweihandstreitkolben" then
				slot = "mace"
				if itemSlot == "INVTYPE_2HWEAPON" then
					cat = "twohanded"
				end	
			elseif itemType == "Waffe Zweihandschwerter" then
				slot = "sword"
				if itemSlot == "INVTYPE_2HWEAPON" then
					cat = "twohanded"
				end	
			elseif itemType == "Waffe Stangenwaffen" then
				slot = "polearm"
				if itemSlot == "INVTYPE_2HWEAPON" then
					cat = "twohanded"
				end	
			elseif itemType == "Waffe Angelruten" then
				slot = "fishingpole"
				if itemSlot == "INVTYPE_2HWEAPON" then
					cat = "twohanded"
				end	
			elseif itemType == "Waffe Stäbe" then
				slot = "staff"
				if itemSlot == "INVTYPE_2HWEAPON" then
					cat = "twohanded"
				end	
			elseif itemType == "Waffe Bogen" then
				slot = "bow"
				if itemSlot == "INVTYPE_RANGED" or itemSlot == "INVTYPE_RANGEDRIGHT" then
					cat = "ranged"
				end	
			elseif itemType == "Waffe Armbrüste" then
				slot = "crossbow"
				if itemSlot == "INVTYPE_RANGED" or itemSlot == "INVTYPE_RANGEDRIGHT" then
					cat = "ranged"
				end	
			elseif itemType == "Waffe Schusswaffen" then
				slot = "gun"
				if itemSlot == "INVTYPE_RANGED" or itemSlot == "INVTYPE_RANGEDRIGHT" then
					cat = "ranged"
				end	
			elseif itemType == "Waffe Wurfwaffen" then
				slot = "thrown"
				if itemSlot == "INVTYPE_THROWN" then
					cat = "ranged"
				end	
			elseif itemType == "Waffe Zauberstäbe" then
				slot = "wand"
				if itemSlot == "INVTYPE_RANGED" or itemSlot == "INVTYPE_RANGEDRIGHT" then
					cat = "ranged"
				end	
			elseif itemType == "Rüstung Schilde" then
				slot = "shield"
				if itemSlot == "INVTYPE_SHIELD" then
					cat = "other"
				end	
			elseif itemType == "Waffe Verschiedenes" then
				slot = "misc"
				if itemSlot == "INVTYPE_WEAPON" then
					cat = "onehanded"
				elseif itemSlot == "INVTYPE_WEAPONMAINHAND" then
					cat = "mainhand"
				elseif itemSlot == "INVTYPE_WEAPONOFFHAND" then
					cat = "offhand"
				elseif itemSlot == "INVTYPE_2HWEAPON" then
					cat = "twohanded"
				elseif itemSlot == "INVTYPE_RANGED" or itemSlot == "INVTYPE_RANGEDRIGHT" or itemSlot == "INVTYPE_THROWN" then
					cat = "ranged"
				end	
			elseif itemType == "Verschiedenes Plunder" then
				slot = "misc"
				if itemSlot == "INVTYPE_HOLDABLE" then
					cat = "offhand"
				end	
			end
			
						--	table.insert(MyAddonDB.items[")
			if not contains(itemTypes, itemType) then am("Unbekannter Itemtyp: "..itemType) end
			if cat and slot then
				if not contains(MyAddonDB.items[cat][slot], itemID) then
					table.insert(MyAddonDB.items[cat][slot], itemID)
					am("Found new " .. cat .." "..slot..": ".. itemID.." - "..iName)
				else
					am("Already known: "..itemID.." - "..iName)
				end
			else
				if not MyAddonDB.itemDump then MyAddonDB.itemDump = {} end
				table.insert(MyAddonDB.itemDump, itemID)
				am("Couldn't handle " .. itemID.."-"..iName..", ".. itemType .. ", " .. itemSlot)
			end
			--table.insert(MyAddonDB.items, itemID)
		end
		if remainingItems > 1 then
			MyAddonDB.lastChecked = MyAddonDB.lastChecked + 1
			CheckItemBatch(itemID+1, maxRetries, remainingItems-1)
		else
			am("Itembatch complete.")
		end
	end
end	





--todo
local function PassesFilter(itemID)
	--local blueFilterEnabled = true
	--local passes = true
	--if blueFilterEnabled and not myadd.colors["blue"][itemID] then passes = false end
	
	return true --TODO
end

--[[
Class Subclass Slot
4 0-4 ]]

local function BuildListHelper()		
	local cat, slot
	if selectedCategory == "Rüstung Platte" then
		cat = "plate"
		if selectedSlot == "HeadSlot" then
			slot = "head"
		elseif selectedSlot == "ShoulderSlot" then
			slot = "shoulder"
		elseif selectedSlot == "ChestSlot" then
			slot = "chest"
		elseif selectedSlot == "WristSlot" then
			slot = "wrist"
		elseif selectedSlot == "HandsSlot" then
			slot = "hands"
		elseif selectedSlot == "WaistSlot" then
			slot = "waist"
		elseif selectedSlot == "LegsSlot" then
			slot = "legs"
		elseif selectedSlot == "FeetSlot" then
			slot = "feet"
		end
	elseif selectedCategory == "Rüstung Schwere Rüstung" then
		cat = "mail"
		if selectedSlot == "HeadSlot" then
			slot = "head"
		elseif selectedSlot == "ShoulderSlot" then
			slot = "shoulder"
		elseif selectedSlot == "ChestSlot" then
			slot = "chest"
		elseif selectedSlot == "WristSlot" then
			slot = "wrist"
		elseif selectedSlot == "HandsSlot" then
			slot = "hands"
		elseif selectedSlot == "WaistSlot" then
			slot = "waist"
		elseif selectedSlot == "LegsSlot" then
			slot = "legs"
		elseif selectedSlot == "FeetSlot" then
			slot = "feet"
		end
	elseif selectedCategory == "Rüstung Leder" then
		cat = "leather"
		if selectedSlot == "HeadSlot" then
			slot = "head"
		elseif selectedSlot == "ShoulderSlot" then
			slot = "shoulder"
		elseif selectedSlot == "ChestSlot" then
			slot = "chest"
		elseif selectedSlot == "WristSlot" then
			slot = "wrist"
		elseif selectedSlot == "HandsSlot" then
			slot = "hands"
		elseif selectedSlot == "WaistSlot" then
			slot = "waist"
		elseif selectedSlot == "LegsSlot" then
			slot = "legs"
		elseif selectedSlot == "FeetSlot" then
			slot = "feet"
		end
	elseif selectedCategory == "Rüstung Stoff" then
		cat = "cloth"
		if selectedSlot == "HeadSlot" then
			slot = "head"
		elseif selectedSlot == "ShoulderSlot" then
			slot = "shoulder"
		elseif selectedSlot == "ChestSlot" then
			slot = "chest"
		elseif selectedSlot == "WristSlot" then
			slot = "wrist"
		elseif selectedSlot == "HandsSlot" then
			slot = "hands"
		elseif selectedSlot == "WaistSlot" then
			slot = "waist"
		elseif selectedSlot == "LegsSlot" then
			slot = "legs"
		elseif selectedSlot == "FeetSlot" then
			slot = "feet"
		elseif selectedSlot == "BackSlot" then
			cat = "other"
			slot = "cloak"
		end
	elseif selectedCategory == "Rüstung Verschiedenes" then
		cat = "misc"
		if selectedSlot == "HeadSlot" then
			slot = "head"
		elseif selectedSlot == "ShoulderSlot" then
			slot = "shoulder"
		elseif selectedSlot == "ChestSlot" then
			slot = "chest"
		elseif selectedSlot == "WristSlot" then
			slot = "wrist"
		elseif selectedSlot == "HandsSlot" then
			slot = "hands"
		elseif selectedSlot == "WaistSlot" then
			slot = "waist"
		elseif selectedSlot == "LegsSlot" then
			slot = "legs"
		elseif selectedSlot == "FeetSlot" then
			slot = "feet"
		elseif selectedSlot == "SecondaryHandSlot" then
			cat = "other"
			slot = "offhand"
		elseif selectedSlot == "ShirtSlot" then
			cat = "accessories"
			slot = "shirt"
		elseif selectedSlot == "TabardSlot" then
			cat = "accessories"
			slot = "tabard"
		end
	elseif selectedCategory == "Waffe Dolche" then
		slot = "dagger"
		if selectedSlot == "MainHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["mainhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		elseif selectedSlot == "SecondaryHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["offhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		end
	elseif selectedCategory == "Waffe Einhandäxte" then
		slot = "axe"
		if selectedSlot == "MainHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["mainhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		elseif selectedSlot == "SecondaryHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["offhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		end
	elseif selectedCategory == "Waffe Einhandschwerter" then
		slot = "sword"
		if selectedSlot == "MainHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["mainhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		elseif selectedSlot == "SecondaryHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["offhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		end
	elseif selectedCategory == "Waffe Einhandstreitkolben" then
		slot = "mace"
		if selectedSlot == "MainHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["mainhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		elseif selectedSlot == "SecondaryHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["offhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		end
	elseif selectedCategory == "Waffe Faustwaffen" then
		slot = "fistweapon"
		if selectedSlot == "MainHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["mainhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		elseif selectedSlot == "SecondaryHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["offhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		end
	elseif selectedCategory == "Waffe Zweihandäxte" then
		slot = "axe"
		cat = "twohanded"	
	elseif selectedCategory == "Waffe Zweihandstreitkolben" then
		slot = "mace"
		cat = "twohanded"	
	elseif selectedCategory == "Waffe Zweihandschwerter" then
		slot = "sword"
		cat = "twohanded"	
	elseif selectedCategory == "Waffe Stangenwaffen" then
		slot = "polearm"
		cat = "twohanded"	
	elseif selectedCategory == "Waffe Angelruten" then
		slot = "fishingpole"
		cat = "twohanded"	
	elseif selectedCategory == "Waffe Stäbe" then
		slot = "staff"
		cat = "twohanded"	
	elseif selectedCategory == "Waffe Bogen" then
		slot = "bow"
		cat = "ranged"	
	elseif selectedCategory == "Waffe Armbrüste" then
		slot = "crossbow"
		cat = "ranged"	
	elseif selectedCategory == "Waffe Schusswaffen" then
		slot = "gun"
		cat = "ranged"	
	elseif selectedCategory == "Waffe Wurfwaffen" then
		slot = "thrown"
		cat = "ranged"	
	elseif selectedCategory == "Waffe Zauberstäbe" then
		slot = "wand"
		cat = "ranged"	
	elseif selectedCategory == "Rüstung Schilde" then
		slot = "shield"
		cat = "other"
	elseif selectedCategory == "Waffe Verschiedenes" then
		slot = "misc"
		if selectedSlot == "MainHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["mainhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["twohanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		elseif selectedSlot == "SecondaryHandSlot" then
			for k, v in pairs(MyAddonDB.items["onehanded"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			for k, v in pairs(MyAddonDB.items["offhand"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		elseif selectedSlot == "RangedSlot" then
			for k, v in pairs(MyAddonDB.items["ranged"][slot]) do
				if PassesFilter(v) then table.insert(list, v) end
			end
			return
		end
	elseif selectedCategory == "Verschiedenes Plunder" then
		slot = "misc"
		cat = "offhand"
	end
	if cat and slot then
		for k, v in pairs(MyAddonDB.items[cat][slot]) do
			if PassesFilter(v) then table.insert(list, v) end
		end
	end
	return
end







	
local setModelButton = CreateMeATextButton(UIParent, 70, 24, "Set Model")
setModelButton:SetFrameStrata("FULLSCREEN")
setModelButton:SetPoint("LEFT", showButton, "RIGHT", 0, 0)
setModelButton:SetScript("OnClick", function()
		--model:SetModel( "Models/Character/OrcFemale.m2" )

		if not UnitIsVisible("target") or not UnitIsPlayer("target") then return end			
		model:ClearModel()
		model:SetUnit("target")
		--model:SetCustomRace(3, 0)
		model:SetModelScale(1)
		local bla, race = UnitRace("target")
		local x, y, z = modelPositions[race]
		model:SetPosition(x, y, z)
		model:SetFacing(0)
		model:Undress()
		--UpdateModel()
		model.update()
		--UpdateItemSlots()
		model:Show()
	end)	
setModelButton:Show()

	
local showButton = CreateMeATextButton(UIParent, 70, 24, "Show")
showButton:SetFrameStrata("FULLSCREEN")
showButton:SetPoint("TOP", UIParent)
local textoTmp = CreateFrame("EditBox", nil, bar)
textoTmp:SetFrameStrata("FULLSCREEN")
--idTexField:Raise()
textoTmp:SetPoint("RIGHT", showButton, "LEFT", 0, 0)
textoTmp:SetSize(70, 24)
textoTmp:SetBackdrop({
  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
  tile=1, tileSize=12, edgeSize=12, 
  insets={left=4, right=4, top=4, bottom=4}
})
textoTmp:SetFontObject("ChatFontNormal")
textoTmp:SetAutoFocus(false)
--textoTmp:SetNumeric(true)
textoTmp:SetMaxLetters(5)
textoTmp:SetScript("OnEscapePressed",function(self)
	self:ClearFocus()
end)
textoTmp:SetScript("OnEnterPressed",function(self)
	local id = tonumber(self:GetText())
	if type(id) == "number" then
		model.ChangeSequence(id)
	end
	--[[if(UnitGUID("target")) then
		model:ClearModel()
		local a=strsub(UnitGUID("target"),9,12)
		local b = tonumber(a,16)
		--myadd.am("NPC ID(\""..UnitName("target").."\") = 0x"..a.." = "..b)
		myadd.am("Target NPC ID:", tonumber((UnitGUID("target")):sub(-12, -9), 16))
		--myadd.am(UnitGUID("target"))
		model:SetCreature(b)
	end]]
	self:SetText("")
	--self:ClearFocus()
end)
textoTmp:Show()




showButton:SetScript("OnClick", function()
		windowFrame:Show()
		--model:Hide()
		--model:Show()
		--model:SetModel("CREATURE/FireDancer/FireDancer.m2")
		--model:SetModelScale(2)
		--UpdateModel()
		
		--SetPortraitTexture(windowFrame.charTexture, "player")
	end)	
showButton:Show()















local function TryOn(mod, itemID, slot, retriesLeft) --TODO: anders handlen when enchant slot ausgewählt ist? 
	--myadd.am(retriesLeft)
	slot = slot or nil
	local maxTries = 3
	retriesLeft = retriesLeft or maxTries
	--itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent
	if not itemID then return end
	if not (slot == "MainHandEnchantSlot" or slot == "SecondaryHandEnchantSlot") and GetItemInfo(itemID) == nil then
		if retriesLeft < 1 then 
			myadd.am("Could not retrieve item info for "..itemID..".")
			return
		end
		GameTooltip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
		MyWaitFunction(0.1*(maxTries-retriesLeft+1), TryOn, mod, itemID, slot, retriesLeft-1)
	else
		local itemSubtype, _, itemSlot = select(7,GetItemInfo(itemID))
		
		if slot == "MainHandEnchantSlot" or slot == "SecondaryHandEnchantSlot" or invSlots[itemSlot] then
			local titanGrip = false
			if select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1 then
				titanGrip = true
			end		
			--Capture Unequipable stuff and end here
			if slot == "SecondaryHandSlot" and itemSlot == "INVTYPE_2HWEAPON" and not (titanGrip and (itemSubtype == "Zweihandschwerter" or itemSubtype == "Zweihandstreitkolben" or itemSubtype == "Zweihandäxte")) then return end			
			
			--Save in currentChanges	
			if not MyAddonDB.currentChanges then MyAddonDB.currentChanges = {} end
			
			--TODO: Decide if equipping 2h removes offhand from set (if not: probably problems with only offhand getting shown if not specifically handled)
			--titangrib sets would get automatically edited just by equipping on a non titangrib char! have to find other solution (hiding+blocking offhand and handling in "apply" function?)
			--if itemSlot == "INVTYPE_2HWEAPON" and not (titanGrip and (itemSubtype == "Zweihandschwerter" or itemSubtype == "Zweihandstreitkolben" or itemSubtype == "Zweihandäxte")) then
				--MyAddonDB.currentChanges["SecondaryHandSlot"] = nil
				--MyAddonDB.currentChanges["SecondaryHandEnchantSlot"] = nil
			--end
			
			if slot then
				--MyAddonDB.currentChanges[slot] = itemID
				SetCurrentChangesSlot(slot, itemID)
			else
				--MyAddonDB.currentChanges[invSlots[itemSlot]] = itemID --TODO: besser nicht  mehr erlauben?
				SetCurrentChangesSlot(invSlots[itemSlot], itemID)
			end
			
			local showRanged
			if slot == "RangedSlot" or invSlots[itemSlot] == "RangedSlot" then
				showRanged = true
			end
			--UpdateModel(showRanged)
			--UpdateItemSlots() --TODO: wird so viel öfter aufgerufen als nötig, aber ohne werden slots nicht geupdatet bis zur nächsten aktion, falls die items nicht gecached waren
		else
			myadd.am("Can't equip spezified item.")
		end
	end
end




















	
	--local testButton = CreateFrame("Button","testButton",bar,"UIPanelButtonTemplate2");
	--testButton:SetWidth(80)
	--testButton:SetText("I'm a button :)")
	
	local idTextField = CreateFrame("EditBox", nil, bar)
	idTextField:SetFrameStrata("FULLSCREEN")
	--idTexField:Raise()
	idTextField:SetPoint("LEFT", setModelButton, "RIGHT", 0, 0)
	idTextField:SetSize(70, 24)
	idTextField:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=12, edgeSize=12, 
      insets={left=4, right=4, top=4, bottom=4}
	})
	idTextField:SetFontObject("ChatFontNormal")
	idTextField:SetAutoFocus(false)	
	idTextField:SetJustifyH("CENTER")
	--idTextField:SetNumeric(true)
	--idTextField:SetMaxLetters(5)
	idTextField:SetScript("OnEscapePressed",function(self)
		self:ClearFocus()
	end)
	idTextField:SetScript("OnEnterPressed",function(self)
		local num = tonumber(self:GetText())
		if num then
			TryOn(model, num)
			--UpdateItemSlots()	
			self:SetText("")
		else
			--TODO: regex to recognize if its a wowhead string
			for k, v in pairs(itemSlots) do
				--MyAddonDB.currentChanges[v] = false
				SetCurrentChangesSlot(v, 1)
			end
			local bla, itemString = strsplit("=", self:GetText())
			local items = { strsplit(":", itemString) }			
			self:SetText("")
			self:ClearFocus()
			if Length(items) < 1 then return end
			myadd.am("WoWhead/MogIt import:")
			myadd.am(items)
			model:Undress()
			for k, v in pairs(items) do
				if strfind(v, ".") then
					local idk = { strsplit(".", v) }
					v = idk[1]
				end
				v = tonumber(v)
				TryOn(model, v) --TODO: make v int and parse the 0.0.0.0.0.0 out
			end
			--UpdateItemSlots()
		end
		--self:ClearFocus()
	end)
	idTextField:Show()


	myFind = function(s1, s2)
		local m, n = strlen(s1), strlen(s2)
		local dif = m - n
		for i = 0, dif do
			local same = true
			for j = 1, n do
				if strbyte(s1, i + j) ~= strbyte(s2, j) then same = false; break end
			end
			if same then return true end
		end
		return false
	end