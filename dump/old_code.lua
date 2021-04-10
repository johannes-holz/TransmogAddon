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




















































