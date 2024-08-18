local M, API = LibStub:GetLibrary("RisingAPI"):newModule("Transmog")
local Utils = API.Utils
local deferred = LibStub("deferred")

M.Slot = {
	Head                  = "1",
	Shoulders             = "3",
	Body                  = "4", -- shirt
	Chest                 = "5",
	Waist                 = "6",
	Legs                  = "7",
	Feet                  = "8",
	Wrists                = "9",
	Hands                 = "10",
	MainHandWeapon        = "12",
	OffHandWeapon         = "13",
	OffHand               = "14",
	Ranged                = "15",
	Back                  = "16",
	Tabard                = "19",

	EnchantMainHandWeapon = "20",
	EnchantOffHandWeapon  = "21",
}

local transmogSlotToInvSlot = {
	[M.Slot.Head] = 1,
	[M.Slot.Shoulders] = 3,
	[M.Slot.Body] = 4,
	[M.Slot.Chest] = 5,
	[M.Slot.Waist] = 6,
	[M.Slot.Legs] = 7,
	[M.Slot.Feet] = 8,
	[M.Slot.Wrists] = 9,
	[M.Slot.Hands] = 10,
	[M.Slot.MainHandWeapon] = 16,
	[M.Slot.OffHandWeapon] = 17,
	[M.Slot.OffHand] = 17,
	[M.Slot.Ranged] = 18,
	[M.Slot.Back] = 15,
	[M.Slot.Tabard] = 19,

	[M.Slot.EnchantMainHandWeapon] = 16,
	[M.Slot.EnchantOffHandWeapon] = 17,
}

M.NoTransmog = 0
M.HideItem = 1

local function checkSlotMap(slots, forSkin)
	if (not forSkin and slots[M.Slot.OffHand] ~= nil and slots[M.Slot.OffHandWeapon] ~= nil) then
		error("cannot transmogrify both shield and offhand at the same time")
	end
end

function M.GetUnlockedVisuals(permanent)
	return API:request("transmog/visual/list", { permanent = permanent })
end

function M.GetUnlockedVisualsForSlot(slot, permanent)
	return API:request("transmog/visual/list", { slot = slot, permanent = permanent })
end

function M.GetUnlockedVisualsForItem(itemId, slot, permanent)
	return API:request("transmog/visual/list", { itemId = itemId, slot = slot, permanent = permanent })
end

function M.UnlockVisual(itemId)
	return API:request("transmog/visual/unlock", { itemId = itemId })
end

function M.GetBalance()
	return API:request("transmog/balance")
end

function M.GetPrice(visualId, itemId, slot)
	return API:request("transmog/price", { visualId = visualId, itemId = itemId, slot = slot })
end

function M.GetPriceAll(slots, forSkin)
	checkSlotMap(slots, forSkin)

	local futures = {}
	for slot, visualId in pairs(slots) do
		if (transmogSlotToInvSlot[slot] == nil) then
			error("invalid slot: " .. tostring(slot))
		end

		local itemId
		if (forSkin) then
			itemId = nil
		else
			itemId = GetInventoryItemID("player", transmogSlotToInvSlot[slot])
		end
		table.insert(futures, M.GetPrice(visualId, itemId, slot))
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

function M.Apply(visualId, skinId, slot)
	return API:request("transmog/apply", { visualId = visualId, skinId = skinId, slot = slot })
end

function M.ApplyAll(slots, skinId)
	checkSlotMap(slots, skinId ~= nil)

	local futures = {}
	for slot, visualId in pairs(slots) do
		if (transmogSlotToInvSlot[slot] == nil) then
			error("invalid slot: " .. tostring(slot))
		end

		table.insert(futures, M.Apply(visualId, skinId, slot))
	end

	return deferred.All(futures):next(Utils.Noop)
end

function M.Check(visualId, skinId, slot)
	return API:request("transmog/check", { visualId = visualId, skinId = skinId, slot = slot })
end

function M.CheckAll(slots, skinId)
	checkSlotMap(slots, skinId ~= nil)

	local futures = {}
	for slot, visualId in pairs(slots) do
		if (transmogSlotToInvSlot[slot] == nil) then
			error("invalid slot: " .. tostring(slot))
		end

		table.insert(
			futures,
			M.Check(visualId, skinId, slot):next(function(result)
				return { valid = result.valid, message = result.message, slot = slot }
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
	local suffixId, uniqueId = select(8, string.split(":", itemLink))
	suffixId = tonumber(suffixId) or 0
	uniqueId = tonumber(uniqueId) or 0

	local itemVisual = bit.rshift(uniqueId, 16)

	local enchantVisual = nil
	if (suffixId == 0) then
		enchantVisual = bit.band(uniqueId, 0xFFFF)
	end
	return itemVisual, enchantVisual
end

local linkIndexToTransmogSlot = {
	M.Slot.Head,
	M.Slot.Shoulders,
	M.Slot.Body,
	M.Slot.Chest,
	M.Slot.Waist,
	M.Slot.Legs,
	M.Slot.Feet,
	M.Slot.Wrists,
	M.Slot.Hands,
	M.Slot.MainHandWeapon,
	M.Slot.OffHandWeapon,
	M.Slot.OffHand,
	M.Slot.Ranged,
	M.Slot.Back,
	M.Slot.Tabard,
	M.Slot.EnchantMainHandWeapon,
	M.Slot.EnchantOffHandWeapon,
}

local EMPTY = '#'
local HIDDEN = '!'
local OFFSET = 38
local BASE = 86
local MAX_ID = math.pow(BASE, 3) - 1

function M.EncodeOutfitLink(slots, text)
	local data = ""
	local pending = ""
	for _, slot in ipairs(linkIndexToTransmogSlot) do
		local visual = slots[slot]
		if (visual == nil or visual == M.NoTransmog) then
			pending = pending .. EMPTY
		else
			local encoded
			if (visual == M.HideItem) then
				encoded = HIDDEN
			else
				if (visual > MAX_ID) then
					error("EncodeOutfitLink: invalid visual (" .. visual .. ")")
				end
				encoded = ""
				for i = 1, 3 do
					encoded = string.char(visual % BASE + OFFSET) .. encoded
					visual = math.floor(visual / BASE)
				end
				assert(visual == 0)
			end
			data = data .. pending .. encoded
			pending = ""
		end
	end
	return "|cffff80ff|Hplayer::outfit:" .. data .. "|h[" .. (text or "Outfit") .. "]|h|r"
end

function M.DecodeOutfitLink(link)
	local pos = select(2, link:find("player::outfit:"))
	if (pos == nil) then
		return nil
	end
	pos = pos + 1
	local slots = {}
	for _, slot in ipairs(linkIndexToTransmogSlot) do
		local c = link:sub(pos, pos)
		if (c == "" or c == "|") then
			slots[slot] = M.NoTransmog
		elseif (c == EMPTY) then
			slots[slot] = M.NoTransmog
			pos = pos + 1
		elseif (c == HIDDEN) then
			slots[slot] = M.HideItem
			pos = pos + 1
		else
			if (pos + 2 > #link) then
				return nil
			end
			local visual = 0
			for i = 0, 2 do
				local decoded = link:byte(pos + i) - OFFSET
				if (decoded < 0 or decoded >= BASE) then
					return nil
				end
				visual = visual * BASE + decoded
			end
			slots[slot] = visual
			pos = pos + 3
		end
	end

	return slots
end
