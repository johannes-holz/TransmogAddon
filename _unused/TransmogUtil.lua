local folder, core = ...

core.transmogUtil = {}
local transmogUtil = core.transmogUtil

local order = {"Head", "Shoulders", "Back", "Chest", "Body", "Tabard", "Wrists", "Hands", "Waist", "Legs", "Feet", "MainHand", "ShieldHandWeapon", "OffHand", "Ranged"}

-- core.API.Slots
local slots = {
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
	[slots.Head] = 1,
	[slots.Shoulders] = 3,
	[slots.Body] = 4,
	[slots.Chest] = 5,
	[slots.Waist] = 6,
	[slots.Legs] = 7,
	[slots.Feet] = 8,
	[slots.Wrists] = 9,
	[slots.Hands] = 10,
	[slots.MainHand] = 16,
	[slots.ShieldHandWeapon] = 17,
	[slots.OffHand] = 17,
	[slots.Ranged] = 18,
	[slots.Back] = 15,
	[slots.Tabard] = 19,
}

local transmogSlotItemTypes = {
	[slots.Head] = {[1] = true},
	[slots.Shoulders] = {[3] = true},
	[slots.Body] = {[4] = true}, -- shirt
	[slots.Chest] = {[5] = true, [20] = true}, -- chest, robe
	[slots.Waist] = {[6] = true},
	[slots.Legs] = {[7] = true},
	[slots.Feet] = {[8] = true},
	[slots.Wrists] = {[9] = true},
	[slots.Hands] = {[10] = true},
	[slots.MainHand] = {[13] = true, [21] = true, [17] = true}, -- 1H, MH, 2H
	[slots.ShieldHandWeapon] = {[13] = true, [22] = true, [17] = true}, -- 1H, OH, 2H
	[slots.OffHand] = {[14] = true, [23] = true}, -- shields, holdables
	[slots.Ranged] = {[15] = true, [25] = true, [26] = true}, -- bow, thrown, ranged right (gun, wands, crossbow)
	[slots.Back] = {[16] = true},
	[slots.Tabard] = {[19] = true},
}

-- GetItemInfo return these as itemEquipLoc, probably dont need this mapping (unless we have to be able to handle items, that are not in our itemData)
local itemEquipLoc = {
    INVTYPE_HEAD = 1,
    --INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    --ring? = 11,
    --trinket? = 12
    INVTYPE_WEAPON = 13,
    INVTYPE_SHIELD = 14,
    INVTYPE_RANGED = 15,
    INVTYPE_CLOAK = 16,
    INVTYPE_2HWEAPON = 17,
    --= 18,
    INVTYPE_TABARD = 19,
    INVTYPE_ROBE = 20,
    INVTYPE_WEAPONMAINHAND = 21,
    INVTYPE_WEAPONOFFHAND = 22,
    INVTYPE_HOLDABLE = 23,
    INVTYPE_THROWN = 25,
    INVTYPE_RANGEDRIGHT = 26,
}

-- local transmogSlotItemTypes = {
-- 	["HeadSlot"] = {1},
-- 	["ShoulderSlot"] = {3},
-- 	["BackSlot"] = {16},
-- 	["ChestSlot"] = {5, 20}, --chest, robe
-- 	["ShirtSlot"] = {4},
-- 	["TabardSlot"] = {19},
-- 	["WristSlot"] = {9},
-- 	["HandsSlot"] = {10},
-- 	["WaistSlot"] = {6},
-- 	["LegsSlot"] = {7},
-- 	["FeetSlot"] = {8},
-- 	["MainHandSlot"] = {13, 21, 17}, --1h, mh, 2h
-- 	--["SecondaryHandSlot"] = {13, 22, 17, 14, 23}, --1h, oh, 2h, shields, holdable/tomes --myadd.Contains twohand for warris?
-- 	["SecondaryHandShieldSlot"] = {14, 23}, -- shields, holdable
-- 	["SecondaryHandWeaponSlot"] = {13, 22, 17}, -- 1H, OH, 2H
-- 	["RangedSlot"] = {15, 25, 26}, --bow, thrown, ranged right(gun, wands, crossbow)
-- }

myadd.GetTransmogLocationInfo = function(self, locationName)
	--if not myadd.API.Slots[locationName] then return end
    assert(myadd.API.Slots[locationName], "Invalid Transmog Slot in GetTransmogLocationInfo")

	local locationID = myadd.API.Slots[locationName]
	local inventorySlot = myadd.locationToInventorySlot[locationName]
	local slotID, slotTexture = GetInventorySlotInfo(myadd.locationToInventorySlot[locationName])
	
	if locationName == "ShieldHandWeapon" then
		_, slotTexture = GetInventorySlotInfo("MainHandSlot")
	end

	return locationID, inventorySlot, slotID, slotTexture
end
