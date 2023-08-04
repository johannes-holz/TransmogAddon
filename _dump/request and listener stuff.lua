
--[=====[
local listeners = {} 

local RegisterListener, UpdateListeners, SetCurrentChanges, SetCurrentChangesSlot, ToApiSet, RequestPriceOfApplyingUpdate, RequestPriceOfSavingUpdate

RegisterListener = function(field, frame)
	if not listeners[field] then listeners[field] = {} end
	listeners[field][frame] = true --does that work?
end

UpdateListeners = function(field)
	assert(listeners[field])
	
	for k, v in pairs(listeners[field]) do
		k.update()
	end
end

SetCosts = function(copper)
	assert(type(copper) == "number")
	
	costs = copper
	UpdateListeneres("costs") --moneyframe, applybutton, 
end

SetCurrentChanges = function(set)
	assert(type(set) == "table")
	for slot, id in pairs(set) do
		assert(contains(itemSlots, slot))
		assert(type(id) == "number" or (type(id) == "boolean" and not id))
	end
	
	--do changehistory stuff here	
	
	MyAddonDB.currentChanges = deepCopy(set)
	
	UpdateListeners("currentChanges") --itemslotframes, model, savebutton, applybutton?, savetosetbutton?, slotmodels (wenn border zur aktuellen auswahl eingebaut wird)

	RequestPriceOfApplyingUpdate()
	--API.GetPriceOfSaving(setId, set)
	--RequestPriceOfSavingUpdate()
end

SetCurrentChangesSlot = function(slot, id)
	assert(contains(itemSlots, slot))
	assert(type(id) == "number" or (type(id) == "boolean" and not id))	
	if not MyAddonDB.currentChanges then MyAddonDB.currentChanges = {} end
	
	if MyAddonDB.currentChanges[slot] == id then return end
	
	--do changehistory stuff here	
	
	MyAddonDB.currentChanges[slot] = id
	
	UpdateListeners("currentChanges")
	
	RequestPriceOfApplyingUpdate()
	--API.GetPriceOfSaving(setId, set)
	--RequestPriceOfSavingUpdate()
end

was behalten von den bisherigen methoden?
undressslott wahrscheinlich einfach anpassen und behalten?

for setName, setTable in pairs(MyAddonDB.sets) do
	for slot, itemID in pairs(setTable) do
		if type(itemID) == "string" do
			MyAddonDB.sets[setName][slot] = tonumber(itemID)
		end
	end
end


function RequestPriceOfApplyingUpdate() --bei änderungen an currentchanges, gearänderung
	API.GetPriceOfApplying(ToApiSet(MyAddonDB.currentChanges)):next(function(copper)
		SetCosts(copper)
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

function ToApiSet(set)
	local apiSet = {}
	for slot, id in pairs(set) do
		assert(contains(itemSlots, slot))
		assert(type(id) == "number" or (type(id) == "boolean" and not id))
		
		local slotID, _ = GetInventorySlotInfo(slot)
		local itemID = id
		if not type(id) == "number" then
			itemID = 0
		end
	end
	
	return apiSet
end


--]=====] 

--[[--------- available mogs stuff
myadd.availableMogs = {
		["HeadSlot"] = {[48902] = true}
		["ShoulderSlot"] = {[24996] = true},
		["BackSlot"] = {[34190] = true},
		["ChestSlot"] = {[30896] = true},
		["ShirtSlot"] = {[42378] = true},
		["TabardSlot"] = {[42378] = true},
		["WristSlot"] = {[31636] = true},
		["HandsSlot"] = {[31636] = true},
		["WaistSlot"] = {[24934] = true},
		["LegsSlot"] = {[30536] = true},
		["FeetSlot"] = {[13527] = true},
		["MainHandSlot"] = {[29329] = true},
		["MainHandEnchantSlot"] = {[3789] = true},
		["SecondaryHandSlot"] = {[29329] = true},
		["SecondaryHandEnchantSlot"] = {[3789] = true},
		["RangedSlot"] = {[29329] = true},
}

if event == "PLAYER_EQUIPMENT_CHANGED" then
	local equipmentSlotID, hasCurrent = ...
	local equipmentSlot = idToSlot[equipmentSlotID]
	if not table.contains(itemSlots, equipmentSlot) then return end
	if not windorFrame:IsShown() then
		if not hasCurrent then
			myadd.availableMogs[equipmentSlot] = {}
		else
			availableMogsUpdateNeeded[equipmentSlot] = true
		end
	else
		UpdateModel()
		RequestAvailableMogsUpdate(equipmentSlot)
	end
end

addonframe:onshow()
	..
	for k, v inpairs(availableMogsUpdateNeeeded) do
		RequestAvailableMogsUpdate(slot)
	end
	..

function RequestAvailableMogsUpdate(slot)
	API.GetAvailableTransmogs(slot):next(function(items)
		UpdateAvailableMogs(k, items)		
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

function UpdateAvailableMogs(slot, items)
	for k, v in pairs(items) do
		myadd.availableMogs[v] = true
	end
	if windowFrame:IsShown() then
		selectedSlot = nil --slot and list can be left alone if slot is not the selectedSlot (care slotid vs slotname here). still choose to always reset for more consistent behaviour?
		selectedCategory = nil
		--UpdateModel()
		UpdateItemSlots() -- needed to show correct border
		BuildList()
		SetPage(1)
	end
end
]]