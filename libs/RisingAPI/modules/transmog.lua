local M, API = LibStub:GetLibrary("RisingAPI"):newModule("Transmog")
local Utils = API.Utils
local deferred = LibStub("deferred")

M.Slots = {
	Head                = 1,
	Shoulders           = 3,
	Body                = 4, -- shirt
	Chest               = 5,
	Waist               = 6,
	Legs                = 7,
	Feet                = 8,
	Wrists              = 9,
	Hands               = 10,
	MainHand            = 12,
	ShieldHandWeapon    = 13,
	OffHand             = 14,
	Ranged              = 15,
	Back                = 16,
	Tabard              = 19,
}

local transmogSlotToInvSlot = {
	[M.Slots.Head] = 1,
	[M.Slots.Shoulders] = 3,
	[M.Slots.Body] = 4,
	[M.Slots.Chest] = 5,
	[M.Slots.Waist] = 6,
	[M.Slots.Legs] = 7,
	[M.Slots.Feet] = 8,
	[M.Slots.Wrists] = 9,
	[M.Slots.Hands] = 10,
	[M.Slots.MainHand] = 16,
	[M.Slots.ShieldHandWeapon] = 17,
	[M.Slots.OffHand] = 17,
	[M.Slots.Ranged] = 18,
	[M.Slots.Back] = 15,
	[M.Slots.Tabard] = 19,
}

M.HideItem = 1

local function checkSlotMap(slots, forSkin)
	if (not forSkin and slots[M.Slots.OffHand] ~= nil and slots[M.Slots.ShieldHandWeapon] ~= nil) then
		error("cannot transmogrify both shield and offhand at the same time")
	end
end

function M.GetUnlockedVisuals(permanent)
	return API:request("transmog/visual/list", { permanent = permanent })
end

function M.GetUnlockedVisualsForSlot(slotId, permanent)
	return API:request("transmog/visual/list", { slotId = slotId, permanent = permanent })
end

function M.GetUnlockedVisualsForItem(itemId, slotId, permanent)
	return API:request("transmog/visual/list", { itemId = itemId, slotId = slotId, permanent = permanent })
end

function M.GetBalance()
	return API:request("transmog/balance")
end

function M.GetPrice(visualItemId, itemId, slotId)
	return API:request("transmog/price", { visualItemId = visualItemId, itemId = itemId, slotId = slotId })
end

function M.GetPriceAll(slots, forSkin)
	checkSlotMap(slots, forSkin)

	local futures = {}
	for slotId, visualItemId in pairs(slots) do
		if (transmogSlotToInvSlot[slotId] == nil) then
			error("invalid slotId: " .. tostring(slotId))
		end

		local itemId
		if (forSkin) then
			itemId = nil
		else
			itemId = GetInventoryItemID("player", transmogSlotToInvSlot[slotId])
		end
		table.insert(futures, M.GetPrice(visualItemId, itemId, slotId))
	end

	return deferred.All(futures):next(function(prices)
		local total = { copper = 0, shards = 0 }
		for _, price in ipairs(prices) do
			total.copper = total.copper + price.copper
			total.shards = total.shards + price.shards
		end
		return total
	end)
end

function M.Apply(visualItemId, skinId, slotId)
	return API:request("transmog/apply", { visualItemId = visualItemId, skinId = skinId, slotId = slotId })
end

function M.ApplyAll(slots, skinId)
	checkSlotMap(slots, skinId ~= nil)

	local futures = {}
	for slotId, visualItemId in pairs(slots) do
		if (transmogSlotToInvSlot[slotId] == nil) then
			error("invalid slotId: " .. tostring(slotId))
		end

		table.insert(futures, M.Apply(visualItemId, skinId, slotId))
	end

	return deferred.All(futures):next(Utils.Noop)
end

function M.Check(visualItemId, skinId, slotId)
	return API:request("transmog/check", { visualItemId = visualItemId, skinId = skinId, slotId = slotId })
end

function M.CheckAll(slots, skinId)
	checkSlotMap(slots, skinId ~= nil)

	local futures = {}
	for slotId, visualItemId in pairs(slots) do
		if (transmogSlotToInvSlot[slotId] == nil) then
			error("invalid slotId: " .. tostring(slotId))
		end

		table.insert(
			futures,
			M.Check(visualItemId, skinId, slotId):next(function(result)
				return { valid = result.valid, message = result.message, slot = slotId }
			end)
		)
	end

	return deferred.All(futures):next(function(results)
		local valid = true
		local messages = {}

		for _, result in ipairs(results) do
			if (not result.valid) then
				valid = false
				messages[result.slot] = result.message
			end
		end

		return { valid = valid, messages = messages }
	end)
end

function M.GetSkins()
	return API:request("transmog/skin/list")
end

function M.GetSkinPrice()
	return API:request("transmog/skin/price")
end

function M.BuySkin()
	return API:request("transmog/skin/buy")
end

function M.RenameSkin(skinId, newName)
	return API:request("transmog/skin/rename", { skinId = skinId, newName = newName })
end

function M.GetActiveSkin()
	return API:request("transmog/skin/active")
end

function M.ActivateSkin(skinId)
	return API:request("transmog/skin/activate", { skinId = skinId })
end

function M.ResetSkin(skinId)
	return API:request("transmog/skin/reset", { skinId = skinId })
end

function M.GetTransferVisualsToSkinPrice(skinId)
	return API:request("transmog/skin/transfer/price", { skinId = skinId })
end

function M.TransferVisualsToSkin(skinId)
	return API:request("transmog/skin/transfer/apply", { skinId = skinId })
end

function M.GetConfig()
	return API:request("transmog/config/show")
end

function M.UpdateConfig(newValues)
	return API:request("transmog/config/update", newValues)
end

function M.GetVisualFromItemLink(itemLink)
	local uniqueId = select(9, string.split(":", itemLink))
	if (uniqueId) then
		return bit.rshift(tonumber(uniqueId), 16)
	else
		return nil
	end
end
