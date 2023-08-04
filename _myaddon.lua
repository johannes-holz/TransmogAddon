-- Folder, SharedTable
local folder, core = ...

-- TODO: REMOVE! just used for debug
Addy = core

--TODO: dummy items securen, deutsche item categorien etc lokalisierbar machen

-- ("(\\(\\         Made              (\\_/)")
-- ("( -.-)          by           =(´o.o`)=")
-- ("o_(\")(\")      Qhoernchen (\")_(\")")	


MyAddonDB = MyAddonDB or {}

local risingAPI = "RisingAPI"
local rAPI = LibStub(risingAPI, true)
if not rAPI then error(folder.." missing dependency "..risingAPI.."."); return end
rAPI:debug(false)

if not rAPI.Transmog then error(folder.." missing RisingAPI transmog module."); return end
core.API = rAPI.Transmog

core.TMOG_NPC_ID = 1010969

--"inv_jewelcrafting_nobletopaz_01"
--"inv_misc_gem_sapphire_03"
--"inv_enchant_shardgleamingsmall"
local SHARDS_TEXTURE = "Interface\\Icons\\inv_misc_gem_sapphire_03"
core.CURRENCY_ICON = SHARDS_TEXTURE
core.CURRENCY_NAME = "Splitter der Illusion"
core.CURRENCY_FAKE_ITEMID = -1337

core.HIDDEN = "Versteckt"
core.COSTS = "Kosten"
core.COLLECTED = "Gesammelt"
core.APPEARANCES = "Aussehen"
core.TRANSMOGRIFY = "Transmogrifizieren"
core.PAGE = "Seite"
core.ENCHANT_PREVIEW = "Verzauberungsvorschau"
core.OPTIONS = "Optionen"

core.CURRENCY_TOOLTIP_TEXT1 = "Splitter der Illusion werden für besondere Transmogrifizierungen benötigt."
core.CURRENCY_TOOLTIP_TEXT2 = "Insgesamt habt ihr aktuell:"
core.CURRENCY_TOOLTIP_TEXT3 = "Diese Woche wurden bereits verdient:"
core.TRANSMOG_NAME = "Transmogrifikation"
core.APPEARANCE_NOT_COLLECTED_TEXT_A = "Ihr habt dieses Aussehen noch nicht gesammelt." -- "You haven't collected this appearance"
core.APPEARANCE_NOT_COLLECTED_TEXT_B = "Ihr habt dieses Aussehen gesammelt, aber nicht von diesem Gegenstand." --"You've collected this appearance, but not from this item"

core.APPEARANCE_TOOLTIP_TEXT1A = "Gegenstände mit diesem Aussehen:"
core.APPEARANCE_TOOLTIP_TEXT1B = "Verfügbare Gegenstände mit diesem Aussehen:"
core.APPEARANCE_TOOLTIP_TEXT2 = "Drücke Tab oder Rechtsklick, um einen anderen Gegenstand auszuwählen."

core.ITEM_TOOLTIP_TRANSMOGRIFIED_TO = "Transmogrifiziert zu:"
core.ITEM_TOOLTIP_ACTIVE_SKIN = "Aktive Haut:"
core.ITEM_TOOLTIP_FETCHING_NAME = "Frage Iteminformation ab für "

core.TRANSMOG_TOOLTIP_PENDING_CHANGE = "Wird geändert zu:"
core.TRANSMOG_TOOLTIP_CURRENT_MOG = "Aktuelle Transmogrifikation:"
core.TRANSMOG_TOOLTIP_REMOVE_MOG = "Entferne Transmogrifikation"
core.TRANSMOG_TOOLTIP_CURRENT_SKIN = "Aktuell ausgewählt:"
core.TRANSMOG_TOOLTIP_REMOVE_SKIN = "Leerer Slot"
core.TRANSMOG_TOOLTIP_COSTS = core.COSTS .. ":"

core.MINIMAP_TOOLTIP_TEXT1 = "Linksklick: Sammlung öffnen" -- "Left-click: Open Wardrobe"
core.MINIMAP_TOOLTIP_TEXT2 = "Umschalt + Linksklick: Transmogfenster öffnen" -- "Shift + Left-click: Open Transmog Interface"
core.MINIMAP_TOOLTIP_TEXT3 = "Rechtsklick: Transmogsichtbarkeit umschalten" -- "Right-click: Toggle through visibility options"

core.TRANSMOG_STATUS = "Transmog Sichtbarkeit: "
core.TRANSMOG_STATUS_UNKNOWN = "Transmog Sichtbarkeit konnte nicht abgefragt werden."

core.SHOW_ITEMS_UNDER_SKIN_TOOLTIP_TEXT = "Aktivieren, um anzuzeigen, wie der Skin in Verbindung mit der aktuellen Ausrüstung aussehen wird."

core.BUY_SKIN_TEXT = "Seid Ihr sicher, dass Ihr einen weiteren Skin kaufen möchtet?"
core.NO_SKIN_COSTS_ERROR = "Skin Preis konnte nicht abgefragt werden"

core.RENAME_SKIN_TEXT1 = "Neuen Skinnamen für ["
core.RENAME_SKIN_TEXT2 = "] eingeben:"

core.RESET_SKIN_TEXT1 = "Seid ihr euch sicher, dass ihr  ["
core.RESET_SKIN_TEXT2 = "] zurücksetzen wollt?"

--"Die Transmogrifizierung aller ausgerüsteten Gegenstände wird von den Gegenständen entfernt und auf den Skin übertragen. Bereits gezahlte Kosten werden verrechnet. Existiert bereits eine Transmogrifikation auf einem Ausrüstungsplatz des Skins, so wird diese nicht überschrieben. Fortfahren?"
core.VISUALS_TO_SKIN_TEXT1 = "Diese Aktion entfernt folgende Transmogrifikationen von eurer Ausrüstung und überträgt sie auf den Skin"
core.VISUALS_TO_SKIN_TEXT2 = "Die bereits gezahlten Kosten sind im Preis verrechnet. Fortfahren?"

core.SKIN_NEEDS_ACTIVATION = "Skin muss benannt werden, bevor er benutzt werden kann."

core.SKIN_NAME_TOO_SHORT = "Skinnamen müssen mindestens ein Zeichen lang sein."
core.SKIN_NAME_INVALID_CHARACTERS = "Skinname enthält ungültige Zeichen."

core.UNLOCKED_BAR_TOOLTIP_TEXT1 = "Anzahl gesammelter Aussehen, die den gewählten Filtern entsprechen." -- "Unlocked Appearances for current selection. The upper bound includes items that might not be collectable for this character."
core.SEARCHBOX_TOOLTIP_TEXT1 = "Filtert Auswahl nach Gegenstandsname oder ID." -- "Filter items by name or item ID.\nSearch by name only works for cached items."

core.CONFIG_NAMES = {
	[1] = "An",
	[2] = "Im PvP aus",
	[3] = "Aus",
}

core.mogTooltipTextColor = { ["r"] = 0xff / 255, ["g"] = 0x9c / 255, ["b"] = 0xe6 / 255, ["a"] = 1, hex = "FFFF9CE6"}
core.skinTextColor = { ["r"] = 0x9c / 255, ["g"] = 0xe6 / 255, ["b"] = 0xff / 255, ["a"] = 1, hex = "FF9CE6FF" }
core.setItemTooltipTextColor = { ["r"] = 1, ["g"] = 1, ["b"] = 0.6, ["a"] = 1 }
core.setItemMissingTooltipTextColor = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 1 }
core.bonusTooltipTextColor = { ["r"] = 0, ["g"] = 1, ["b"] = 0, ["a"] = 1 }
core.appearanceNotCollectedTooltipColor = { r = 0.30, g = 0.52, b = 0.90, a = 1, hex = "4D85E6FF" } 	--Royal Blue 

local listeners = {}
local RegisterListener, UpdateListeneres

-- Functions that interact with the API. Trigger another Request or trigger SetX function on server answer. Convert to and from API set format
local RequestUnlocksSlot, RequestPriceTotal, RequestPriceSlot, RequestApplyCurrentChanges, RequestBalance, RequestSkins, RequestSkinRename
-- Functions setting data and trigger update function of registered GUI elements
local SetCosts, SetSlotCostsAndReason, SetSkinCosts, SetCurrentChanges, SetCurrentChangesSlot, SetSlotAndCategory, SetBalance, SetSkinData, SetAvailableMogs

------------------- Data we modify through Setters, that cause Listening Frames to update -----------------------------------

local balance = {}
local costs = {} -- copper = 0, points = 0, 
local skinCosts = {}
local skins = {}
local slotCostsCopper = {}
local slotCostsShards = {}
local slotValid = {}
local slotReason = {}
local config = nil


local atTransmogrifier -- used in e.g. ItemTab to get different behaviour depending wether we are using it in TransmogFrame or WardrobeFrame

MyAddonDB.sets = MyAddonDB.sets or {}
MyAddonDB.currentChanges = MyAddonDB.currentChanges or {} -- Get reset on Login and all the time atm., so no point in saving it in DB. Would have to save per character anyways

------------------- Updoots (for speed or simply for better readability) ------------------------
local GetCoinTextureStringFull = core.GetCoinTextureStringFull
local API = core.API
local Length = core.Length
local DeepCompare = core.DeepCompare
local FunctionOnItemInfo = core.FunctionOnItemInfo
local ClearAllOutstandingOIIF= core.ClearAllOutstandingOIIF
local SetTooltip = core.SetTooltip
local MyWaitFunction = core.MyWaitFunction
local am = core.am

local CreateMeAButton = core.CreateMeAButton
local CreateMeATextButton = core.CreateMeATextButton
local CreateMeACustomTexButton = core.CreateMeACustomTexButton

local GetInventoryItemID = core.GetInventoryItemID
local GetInventoryVisualID = core.GetInventoryVisualID
local GetContainerVisualID = core.GetContainerVisualID



-- Even tho we save the collection status of every item, we still need to ask the server what items are available for a specific slot
core.availableMogs = {
		["HeadSlot"] = {},
		["ShoulderSlot"] = {},
		["BackSlot"] = {},
		["ChestSlot"] = {},
		["ShirtSlot"] = {},
		["TabardSlot"] = {},
		["WristSlot"] = {},
		["HandsSlot"] = {},
		["WaistSlot"] = {},
		["LegsSlot"] = {},
		["FeetSlot"] = {},
		["MainHandSlot"] = {},
		["MainHandEnchantSlot"] = {},
		["SecondaryHandSlot"] = {},
		["SecondaryHandEnchantSlot"] = {},
		["RangedSlot"] = {},
}

core.availableMogsUpdateNeeded = {}

core.locationToInventorySlot = {
	Head = "HeadSlot",
	Shoulders = "ShoulderSlot",
	Body = "ShirtSlot",
	Chest = "ChestSlot",
	Waist = "WaistSlot",
	Legs = "LegsSlot",
	Feet = "FeetSlot",
	Wrists = "WristSlot",
	Hands = "HandsSlot",
	MainHand = "MainHandSlot",
	ShieldHandWeapon = "SecondaryHandSlot",
	OffHand = "SecondaryHandSlot",
	Ranged = "RangedSlot",
	Back = "BackSlot",
	Tabard = "TabardSlot",
}

local itemSlots = {
	"HeadSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"MainHandSlot",
	--"SecondaryHandSlot",
	"ShieldHandWeaponSlot",
	"OffHandSlot",
	--"MainHandEnchantSlot", --TODO: erlaubt?
	--"SecondaryHandEnchantSlot",
	"RangedSlot",
}
core.itemSlots = itemSlots

for k, v in pairs(itemSlots) do
	if v ~= "MainHandEnchantSlot" and v ~= "SecondaryHandEnchantSlot" then
		core.availableMogsUpdateNeeded[v] = true
	end
end

local slotToID = {
	["HeadSlot"] = 1,
	["ShoulderSlot"] = 3,
	["BackSlot"] = 15,
	["ChestSlot"] = 5,
	["ShirtSlot"] = 4,
	["TabardSlot"] = 19,
	["WristSlot"] = 9,
	["HandsSlot"] = 10,
	["WaistSlot"] = 6,
	["LegsSlot"] = 7,
	["FeetSlot"] = 8,
	["MainHandSlot"] = 16,
	["SecondaryHandSlot"] = 17,
	["ShieldHandWeaponSlot"] = 17,
	["OffHandSlot"] = 17,
	["MainHandEnchantSlot"] = -16, --TODO: erlaubt?
	["SecondaryHandEnchantSlot"] = -17,
	["RangedSlot"] = 18,
}


local idToSlot = {
	[1] = "HeadSlot",
	[3] = "ShoulderSlot",
	[15] = "BackSlot",
	[5] = "ChestSlot",
	[4] = "ShirtSlot",
	[19] = "TabardSlot",
	[9] = "WristSlot",
	[10] = "HandsSlot",
	[6] = "WaistSlot",
	[7] = "LegsSlot",
	[8] = "FeetSlot",
	[16] = "MainHandSlot",
	[17] = "SecondaryHandSlot",
	--[1???] = "MainHandEnchantSlot", --TODO: erlaubt?
	--[1???] = "SecondaryHandEnchantSlot",
	[18] = "RangedSlot",
}
core.idToSlot = idToSlot

--These IDs are referring to the inventoryType in the itemdata , not to be confused with itemSlotIDs(inventory)
slotToIDs = {
	["HeadSlot"] = {1},
	["ShoulderSlot"] = {3},
	["BackSlot"] = {16},
	["ChestSlot"] = {5, 20}, --chest, robe
	["ShirtSlot"] = {4},
	["TabardSlot"] = {19},
	["WristSlot"] = {9},
	["HandsSlot"] = {10},
	["WaistSlot"] = {6},
	["LegsSlot"] = {7},
	["FeetSlot"] = {8},
	["MainHandSlot"] = {13, 21, 17}, --1h, mh, 2h
	["SecondaryHandSlot"] = {13, 22, 17, 14, 23}, --1h, oh, 2h, shields, holdable/tomes --core.Contains twohand for warris?
	["ShieldHandWeaponSlot"] = {13, 22, 17}, -- 1H, OH, 2H
	["OffHandSlot"] = {14, 23}, -- shields, holdables
	["RangedSlot"] = {15, 25, 26}, --bow, thrown, ranged right(gun, wands, crossbow)
}

-- geplant als weg die lokalisierten armor/waffen kategorieren zu bekommen, aber dies funktioniert nicht für alle
-- Stattdessen manuelle lokalisation oder dummy items, für die wir itemquries durchführen und dann die entsprechenden felder setzen?

-- TODO: We could get our localized item types from GetAuctionItemClasses(), GetAuctionItemSubClasses(classID)
-- local itemTypeSpellID = {
-- 	-- Melee Weapons
-- 	["Daggers"] = 1180,
-- 	["FistWeapons"] = 1180,
-- 	["1HAxes"] = 1180,
-- 	["1HSwords"] = 1180,
-- 	["1HMaces"] = 1180,
-- 	["2HAxes"] = 1180,
-- 	["2HSwords"] = 1180,
-- 	["2HMaces"] = 1180,
-- 	["Polearms"] = 1180,
-- 	["Staves"] = 1180,
-- 	["FishingPoles"] = 1180,
-- 	["MiscWeapons"] = 1180,
-- 	-- Ranged Weapons
-- 	["Bows"] = 1180,
-- 	["Crossbows"] = 1180,
-- 	["Guns"] = 1180,
-- 	["Thrown"] = 1180,
-- 	["Wands"] = 1180,
-- 	-- Armor
-- 	["Cloth"] = 1180,
-- 	["Leather"] = 1180,
-- 	["Mail"] = 1180,
-- 	["Plate"] = 1180,
-- 	["Shields"] = 1180,
-- 	["MiscArmor"] = 1180,
-- 	-- Junk
-- 	["MiscJunk"] = 1180
-- }


core.slotCategories = {
	["HeadSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["ShoulderSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["BackSlot"] = {"Rüstung Stoff"},
	["ChestSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["ShirtSlot"] = {"Rüstung Verschiedenes"},
	["TabardSlot"] = {"Rüstung Verschiedenes"},
	["WristSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["HandsSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["WaistSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["LegsSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["FeetSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["MainHandSlot"] = {"Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
		"Waffe Stangenwaffen", "Waffe Stäbe", "Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Angelruten", "Waffe Verschiedenes"},
	["SecondaryHandSlot"] = {"Rüstung Schilde", "Rüstung Verschiedenes", "Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
		"Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Verschiedenes", "Verschiedenes Plunder"},

	["ShieldHandWeaponSlot"] = {"Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
		"Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Verschiedenes", "Verschiedenes Plunder"},
	["OffHandSlot"] = {"Rüstung Schilde", "Rüstung Verschiedenes"},

	["RangedSlot"] = {"Waffe Bogen", "Waffe Armbrüste",	"Waffe Schusswaffen", "Waffe Wurfwaffen", "Waffe Zauberstäbe"},
	["MainHandEnchantSlot"] = {},
	["SecondaryHandEnchantSlot"] = {},
}


core.GetTransmogLocationInfo = function(self, locationName)
	if not core.API.Slots[locationName] then return end

	local locationID = core.API.Slots[locationName]
	local inventorySlot = core.locationToInventorySlot[locationName]
	local slotID, slotTexture = GetInventorySlotInfo(core.locationToInventorySlot[locationName])
	local itemSlot = inventorySlot
	
	if locationName == "ShieldHandWeapon" then
		_, slotTexture = GetInventorySlotInfo("MainHandSlot")
		itemSlot = "ShieldHandWeaponSlot"
	end
	if locationName == "OffHand" then
		itemSlot = "OffHandSlot"
	end

	return locationID, inventorySlot, slotID, slotTexture, itemSlot
end

core.GetItemSlotInfo = function(itemSlot)
	assert(slotToID[itemSlot] ~= nil, "Invalid slot in GetItemSlotInfo")

	local slotID = slotToID[itemSlot]

	return GetInventorySlotInfo(idToSlot[slotID])
end


local invSlotToTransmogLocation = {
	HeadSlot = "Head",
	ShoulderSlot = "Shoulders",
	BackSlot = "Back",
	ChestSlot = "Chest",
	ShirtSlot = "Body",
	TabardSlot = "Tabard",
	WristSlot = "Wrists",
	HandsSlot = "Hands",
	WaistSlot = "Waist",
	LegsSlot = "Legs",
	FeetSlot = "Feet",
	MainHandSlot = "MainHand",
	ShieldHandWeaponSlot = "ShieldHandWeapon",
	OffHandSlot = "OffHand",
	--SecondaryHandSlot", special case
	--MainHandEnchantSlot, --TODO: erlaubt?
	--SecondaryHandEnchantSlot,
	RangedSlot = "Ranged",
}

ToTransmogLocation = function(itemSlot) --, special)
	if type(itemSlot) == "number" then itemSlot = idToSlot[itemSlot] end

	if invSlotToTransmogLocation[itemSlot] then
		return API.Slots[invSlotToTransmogLocation[itemSlot]]
	elseif itemSlot == "SecondaryHandSlot" then
		local equipped = GetInventoryItemID("player", 17)
		if not equipped then return API.Slots.ShieldHandWeapon end -- No offhand equipped, so the field will be nil anyway, but have to return something
		local invtype = select(9, GetItemInfo(equipped)) -- item info should always be cached/available for equipped items
		if invtype == "INVTYPE_SHIELD" or invtype == "INVTYPE_HOLDABLE" then
			return API.Slots.OffHand
		else
			return API.Slots.ShieldHandWeapon
		end
	end
end


core.GetSkinSlotVisualID = function(skinID, slotID)
	if not skinID then return end

	if not skins[skinID] then am("ERROR in GetSkinSlotVisualID: There is no skin with ID", skinID); return end

	return skins[skinID].slots[slotID]
end


core.GetInventorySkinID = function(inventorySlotID)
	local locationID = ToTransmogLocation(inventorySlotID)
	return core.GetSkinSlotVisualID(core.GetActiveSkin(), locationID)
end	

core.TransmogGetSlotInfo = function(itemSlot, skinID)
	assert(slotToID[itemSlot] ~= nil, "Invalid slot in TransmogGetSlotInfo")
	skinID = skinID or core.GetSelectedSkin() -- TODO: allow optional skinID parameter?

	local inventorySlotID = slotToID[itemSlot]
	local locationID = ToTransmogLocation(itemSlot) -- TODO: hopefully soon replaced so we work on locations instead of itemslots, PEPW
	--local locationID = core:GetTransmogLocationInfo(location)
	--print(itemSlot, "inventoryID", inventorySlotID, "location", location, "locationID", locationID, "selectedSkin", core.GetSelectedSkin())

	local itemID = core.GetInventoryItemID("player", inventorySlotID)
	local visualID = core.GetInventoryVisualID("player", inventorySlotID)
	local skinVisualID = core.GetSkinSlotVisualID(skinID, locationID)
	local pendingID = MyAddonDB.currentChanges[itemSlot]
	local pendingCostsShards = slotCostsShards[itemSlot]
	local pendingCostsCopper = slotCostsCopper[itemSlot]
	local canTransmogrify = slotValid[itemSlot]
	local cannotTransmogrifyReason = slotReason[itemSlot]

	--print(slotID, itemID, visualID, skinVisualID, pendingID)
	if itemID and (itemSlot == "OffHandSlot" or itemSlot == "ShieldHandWeaponSlot") then
		local isOffHandType = core.IsOffHandItemType(select(9, GetItemInfo(itemID)))
		if (itemSlot == "OffHandSlot" and not isOffHandType) or (itemSlot == "ShieldHandWeaponSlot" and isOffHandType) then
			itemID = nil
			visualID = nil
		end
	end

	return itemID, visualID, skinVisualID, pendingID, pendingCostsShards, pendingCostsCopper, canTransmogrify, cannotTransmogrifyReason
end

core.HasRangeSlot = function()
	local _, class = UnitClass("player")	
	return not (class == "PALADIN" or class == "DEATHKNIGHT" or class == "SHAMAN" or class == "DRUID")
end

core.HasShieldHandWeaponSlot = function()
	local _, class = UnitClass("player")	
	return class == "WARRIOR" or class == "DEATHKNIGHT" or class == "SHAMAN" or class == "ROGUE" or class == "HUNTER"
end

local ToApiSet = function(set)
	local apiSet = {}
	for slot, itemID in pairs(set) do
		if slot ~= "MainHandEnchantSlot" and slot ~= "SecondaryHandEnchantSlot" then
			assert(core.Contains(itemSlots, slot)) -- Technically only needs the transmoglocation check?
			assert(type(itemID) == "number" or (type(itemID) == "boolean" and not itemID))
			
			--local slotID, _ = GetInventorySlotInfo(slot)
			local transmogLocation = ToTransmogLocation(slot)
			if (transmogLocation == nil) then print("Could not find transmogLocation for", slot) end
			assert(transmogLocation ~= nil, "Could not find transmogLocation for "..slot)
			apiSet[transmogLocation] = itemID
		end
	end
	core.am(apiSet)
	return apiSet
end

RegisterListener = function(field, frame)
	if not listeners[field] then listeners[field] = {} end
	listeners[field][frame] = true
end
core.RegisterListener = RegisterListener

UpdateListeners = function(field)
	if not listeners[field] then print("Called GUI Update for", field, ", which has no registered elements."); return end
	
	for k, v in pairs(listeners[field]) do
		k:update()
	end
end
core.UpdateListeners = UpdateListeners


SetBalance = function(bal)
	assert(type(bal) == "table")
	
	balance = core.DeepCopy(bal)
	UpdateListeners("balance") --balanceFrame
end

core.GetBalance = function()
	return balance
end

local visibilities = {
	["visible"] = 1,
	["hidden-in-pvp"] = 2,
	["hidden"] = 3,
}

local configToAPI = {
	"visible", "hidden-in-pvp", "hidden"
}

core.SetConfig = function(c)
	if not c or not c.visibility or not visibilities[c.visibility] then core.am("ERROR: Unknown visibility in config", c); return end

	config = visibilities[c.visibility]
	print("setconfig", config)
	UpdateListeners("config")
end

core.GetConfig = function()
	return config
end

SetSkinCosts = function(points, copper)
	skinCosts.points = points
	skinCosts.copper = copper
	UpdateListeners("skinCosts") -- no one atm
end

core.GetSkinCosts = function()
	return skinCosts
end

SetSlotAndCategory = function(slot, cat, updateList)
	assert((slot == nil and cat == nil) or core.Contains(itemSlots, slot))
	assert((slot == nil and cat == nil) or core.Contains(core.slotCategories[slot], cat))
	
	if not updateList and slot == selectedSlot and cat == selectedCategory then return end
	
	if slot and selectedSlot ~= slot then core.RequestUnlocksSlot(slot) end
	
	selectedSlot = slot
	selectedCategory = cat

	--core.itemCollectionFrame:UpdateDisplayList()
	core.itemCollectionFrame:SetSlotAndCategory(slot, cat, updateList)
	
	CloseDropDownMenus()
	
	UpdateListeners("selectedSlot") --itemFrames, 
	--UpdateListeners("selectedCategory") --
end
core.SetSlotAndCategory = SetSlotAndCategory

core.GetSelectedSlot = function()
	return selectedSlot
end

core.GetSelectedCategory = function()
	return selectedCategory
end

SetCurrentChanges = function(set)
	assert(type(set) == "table")
	for slot, id in pairs(set) do
		assert(core.Contains(itemSlots, slot))
		assert(type(id) == "number" or (type(id) == "boolean" and not id))
	end

	-- MyAddonDB.currentChanges = {}
	-- wipe(slotCostsCopper)
	-- wipe(slotCostsShards)
	-- wipe(slotReason)
	-- SetCosts() -- clear slot costs and sum and trigger GUI Update

	
	-- for slot, id in pairs(set) do
	-- 	SetCurrentChangesSlot(slot, id, true)
	-- end

	for _, slot in pairs(itemSlots) do
		SetCurrentChangesSlot(slot, set[slot], true)
	end
	
	UpdateListeners("currentChanges") --itemslotframes, model, savebutton, applybutton?, savetosetbutton?, slotmodels (wenn border zur aktuellen auswahl eingebaut wird)
	--core.RequestPriceTotal() -- TODO: Remove this and sum up our slot prices instead or keep this as safety?
end
core.SetCurrentChanges = SetCurrentChanges

core.GetCurrentChanges = function()
	return MyAddonDB.currentChanges
end

SetCurrentChangesSlot = function(slot, id, silent)
	assert(core.Contains(itemSlots, slot))
	assert(id == nil or type(id) == "number") -- and GetItemData(id) or even GetItemInfo(id) to secure that id is valid item (that is cached?) and maybe even check slot?
	if not MyAddonDB.currentChanges then MyAddonDB.currentChanges = {} end
	--core.am("SetCurrentChangesSlot:", slot, "to", id)	

	local itemID, visualID, skinVisualID = core.TransmogGetSlotInfo(slot)
	local selectedSkin = core.GetSelectedSkin()

	if selectedSkin then
		if id == skinVisualID or (id == 0 and not skinVisualID) then
			id = nil
		end
	elseif itemID then
		if id == itemID then -- we chose the original item as transmog -> interpret as unmog
			id = 0
		end		
		if id == visualID then -- we chose the currently equipped visual -> no change
			id = nil
		end
	else
		id = nil
	end
	
	if MyAddonDB.currentChanges[slot] == id then return end

	MyAddonDB.currentChanges[slot] = id -- Or let change only go through, after we get an answer to RequestPriceSlot?
	slotCostsCopper[slot] = nil
	slotCostsShards[slot] = nil
	slotReason[slot] = nil

	core.RequestPriceSlot(slot)

	if not silent then	
		UpdateListeners("currentChanges")	
		--core.RequestPriceTotal()
	end
end

core.UnmogSlot = function(itemSlot)
	SetCurrentChangesSlot(itemSlot, 0)
end

core.UndressSlot = function(itemSlot)
	SetCurrentChangesSlot(itemSlot, 1)
end

core.ClearPendingSlot = function(itemSlot)
	SetCurrentChangesSlot(itemSlot, nil)
end

core.SetPending = function(itemSlot, itemID)
	SetCurrentChangesSlot(itemSlot, itemID)
end

SetSlotCostsAndReason = function(itemSlot, copper, shards, valid, reason)
	slotCostsCopper[itemSlot] = copper
	slotCostsShards[itemSlot] = shards
	slotValid[itemSlot] = valid
	slotReason[itemSlot] = reason

	local copper, shards = 0, 0
	local valid, hasPendings = true, false
	for _, itemSlot in pairs(itemSlots) do
		if valid then
			local _, _, _, pendingID, s, c, canTransmogrify = core.TransmogGetSlotInfo(itemSlot)
			if pendingID then
				hasPendings = true
				if (not s or not c or not canTransmogrify) then -- TODO: Decide whether we want to display sum, even if there are currently invalid pendings
					valid = false
				else
					copper = copper + c
					shards = shards + s
				end
			end
		end
	end
	if not valid or not hasPendings then
		copper, shards = nil, nil
	end

	SetCosts(copper, shards)
	--UpdateListeners("costs")
end

SetCosts = function(copper, points) -- TODO: Keep allowing setting costs even tho its basically just a view on slot costs now, which we update when changing slot costs?
	assert(type(copper) == "number" and type(points) == "number"
		or copper == nil and points == nil)
	
	costs.copper = copper
	costs.points = points
	UpdateListeners("costs") --moneyframe, applybutton, 
end

core.GetCosts = function()
	return costs
end

SetAvailableMogs = function(slot, items)
	--am("Updated available mogs for:", slot)
	core.availableMogs[slot] = core.availableMogs[slot] or {}
	wipe(core.availableMogs[slot])

	for k, v in pairs(items) do
		core.availableMogs[slot][v] = true
	end

	if core.transmogFrame:IsShown() then
		if slot == selectedSlot then
			--(selectedSlot, selectedCategory, true) -- TODO: This the way we want to trigger rebuilt of list and stuff?
			core.itemCollectionFrame:UpdateDisplayList()
			--core.MyWaitFunction(0.1, core.itemCollectionFrame.UpdateDisplayList, core.itemCollectionFrame)

		end
	end
	
	UpdateListeners("availableMogs") --TODO update build list?
end

core.IsAvailableSourceItem = function(item, slot)
	return core.availableMogs[slot] and core.availableMogs[slot][item]
end

--[[
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
]]
local transmogIDToInventorySlot = {
	[1] = "HeadSlot",
	[3] = "ShoulderSlot",
	[16] = "BackSlot",
	[5] = "ChestSlot",
	[4] = "ShirtSlot",
	[19] = "TabardSlot",
	[9] = "WristSlot",
	[10] = "HandsSlot",
	[6] = "WaistSlot",
	[7] = "LegsSlot",
	[8] = "FeetSlot",
	[12] = "MainHandSlot",
	[13] = "SecondaryHandSlot",
	[14] = "SecondaryHandSlot", -- -.-
	--"MainHandEnchantSlot", --TODO: erlaubt?
	--"SecondaryHandEnchantSlot",
	[15] = "RangedSlot",
}

core.SetSkin = function(skin, silent)
	local id = skin.id
	
	skins[id] = {}
	skins[id].name = skin.name
	skins[id].slots = {}

	for slotID, itemID in pairs(skin.slots) do		
		-- print(type(slotID))	
		-- slotID = tonumber(slotID) -- is supposed to be numeric acoording to API doc, but is a string at time of writing
		-- local slotName = transmogIDToInventorySlot[slotID]
		-- if not slotName then
		-- 	print("SetSets: Could not map " .. slotID .. " to an item slot name!")
		-- --if itemID == 0 then itemID = false end
		-- else
		-- 	sets[id]["transmogs"][slotName] = itemID
		-- end
		--sets[id]["transmogs"][slotID] = nil
		slotID = tonumber(slotID) -- should be numeric acoording to API doc, but is a string at time of writing
		--local itemSlot = core.TransmogLocationToItemSlot(slotID)
		skins[id].slots[slotID] = itemID
	end

	if not silent then 
		UpdateListeners("selectedSkin")
	end
end

-- SetData has now format: { {id: SkinID, name: String, slots: SlotMap} }
SetSkinData = function(skinData)
	core.am("called set skin data!")

	-- for k, skin in pairs(skinData) do
	-- 	core.am("setdata:", skin)
	-- end

	skins = {}
	for _, skin in pairs(skinData) do
		--assert blabla

		core.SetSkin(skin, true)

		-- core.am("setdata:", skin)
		-- core.am("copied data:", skins[id])
	end
	
	--core.SetSelectedSkin(core.GetSelectedSkin()) -- TODO: this needs fixing
	UpdateListeners("selectedSkin") -- TODO: is this fine?
end

core.GetSkins = function()
	return skins
end

core.SetSelectedSkin = function(skinID)
	if skinID == selectedSkin then return end

	selectedSkin = skinID -- TODO: check if it exists in skinData?
	UpdateListeners("selectedSkin")
	SetCurrentChanges({})
end

core.GetSelectedSkin = function()
	return selectedSkin
end

core.GetSelectedSkinName = function()
	local skinID = core.GetSelectedSkin()
	return skinID and skins[skinID].name
end

core.SetActiveSkin = function(skinID) -- Setter of internal var. Asking the server to change active Skin is done with Request...
	if type(skinID) ~= "number" and skinID ~= nil then print("Error in SetActiveSkin: skinID has wrong type") end -- not using assert since API swallows up error message
	activeSkin = skinID -- should our AddOn/GUI care about active skin? TODO: Add listeners
	UpdateListeners("activeSkin")
end

core.GetActiveSkin = function()
	return activeSkin
end

core.GetActiveSkinName = function()
	local skinID = core.GetActiveSkin()
	if skinID then
		local skins = core.GetSkins()
		if skins then
			return skins[skinID].name
		end
	end
end

core.SetIsAtTransmogrifier = function(atNPC)
	atTransmogrifier = atNPC -- TODO: trigger GUI update? probably better to just manually cause a fresh oder item tab
end

core.IsAtTransmogrifier = function()
	return atTransmogrifier
end

local OnVisualUnlocked = function(payload)
	core.am("unlockevent", payload)
	local itemID = payload.itemId
	core.SetUnlocked(itemID)
	print("OnVisualUnlock!", itemID, GetItemInfo(itemID))
end
rAPI:registerEvent("transmog/visual/unlocked", OnVisualUnlocked)

local OnSkinActivated = function(payload)
	--SetSelectedSkin(payload.skinId)
	print("OnSkinActivate", payload.skinId)
	core.SetActiveSkin(payload.skinId)
end
rAPI:registerEvent("transmog/skin/activated", OnSkinActivated)

local OnSkinChanged = function(payload)
	am("OnSkinUpdate", payload)
	core.SetSkin(payload)
end
rAPI:registerEvent("transmog/skin/changed", OnSkinChanged)

local OnBalanceChanged = function(payload)
	print("Balance Update!")
	SetBalance(payload)
end
rAPI:registerEvent("transmog/balance/changed", OnBalanceChanged)

local OnConfigChanged = function(payload)
	print("Config Update!")
	core.SetConfig(payload)
end
rAPI:registerEvent("transmog/config/changed", OnConfigChanged)

core.RequestGetConfig = function()
	API.GetConfig():next(function(config)
		core.SetConfig(config)
	end):catch(function(err)
		print("RequestGetConfig: An error occured:", err.message)
	end)
end

core.RequestUpdateConfig = function(config)
	--if not visibility or not visibilities[visibility] then core.am("Wrong usage of RequestUpdateConfig! Parameter:", visibility); return end
	if not config or not configToAPI[config] then core.am("Wrong usage of RequestUpdateConfig! Parameter:", config); return end

	API.UpdateConfig( { ["visibility"] = configToAPI[config] } ):next(function()
		--print("Transmog visibility successfully changed to:", configToAPI[config]) -- have event now
	end):catch(function(err)
		print("RequestUpdateConfig: An error occured:", err.message)
	end)
end

core.RequestActiveSkin = function()
	API.GetActiveSkin():next(function(skinID)
		core.SetActiveSkin(skinID)
	end):catch(function(err)
		print("RequestActiveSkin: An error occured:", err.message)
	end)
end

core.RequestActivateSkin = function(skinID)
	API.ActivateSkin(skinID):next(function(answer)
		print("Active skin activate!")
	end):catch(function(err)
		print("RequestSetActiveSkin: An error occured:", err.message)
	end)
end

local requestCounterS = 0
core.RequestSkins = function(id)
	API.GetSkins():next(function(skinData)
		core.am("received skinData:", skinData)
		SetSkinData(skinData)
		-- if id then
		-- 	SelectSet(id)
		-- end
	end):catch(function(err)
		print("RequestSkins: An error occured:", err.message)
	end)
end

core.RequestSkinRename = function(id, newName)
	API.RenameSkin(id, newName):next(function(answer)
		print("RenameSkinSuccess!")
	end):catch(function(err)
		print("RequestSkinRename: An error occured:", err.message)
	end)
end

core.RequestSkinReset = function(id)	
	API.ResetSkin(id):next(function(answer)
		print("ResetSkinSuccess!")
	end):catch(function(err)
		print("RequestSkinReset: An error occured:", err.message)
	end)
end

core.RequestTransferPriceAndOpenPopup = function(id)
	API.GetTransferVisualsToSkinPrice(id):next(function(answer)
		print("SkinPriceGet!")
		core.ShowVisualsToSkinPopup(id, answer) -- TODO: Checks that nothing has changed in the meantime, time limit etc?
	end):catch(function(err)
		print("RequestTransferVisualsToSkin: An error occured:", err.message)
	end)
end

core.RequestTransferVisualsToSkin = function(id)	
	API.TransferVisualsToSkin(id):next(function(answer)
		print("SkinAbsorbSuccess!")
	end):catch(function(err)
		print("RequestTransferVisualsToSkin: An error occured:", err.message)
	end)
end

local requestCounterSkinCosts = 0
core.RequestSkinCosts = function()	
	SetSkinCosts()
	requestCounterSkinCosts = requestCounterSkinCosts + 1
	local requestID = requestCounterSkinCosts
	API.GetSkinPrice():next(function(answer)
		if requestID ~= requestCounterSkinCosts then return end
		SetSkinCosts(answer.shards, answer.copper)
	end):catch(function(err)
		print("RequestSkinCosts: An error occured:", err.message)
	end)
end

local requestCounterBuySkin = 0
core.RequestBuySkin = function()
	-- TODO: Checks whether we have enough balance?
	requestCounterBuySkin = requestCounterBuySkin + 1
	local requestID = requestCounterBuySkin
	API.BuySkin():next(function(answer)
		print("skin get!")
		core.RequestSkinCosts()
	end):catch(function(err)
		print("RequestSkinCosts: An error occured:", err.message)
	end)
end



local requestCounterUS = {}
core.RequestUnlocksSlot = function(slot)
	local transmogLocation = ToTransmogLocation(slot)
	local skin = core.GetSelectedSkin()
	local itemID = core.TransmogGetSlotInfo(slot)
	
	SetAvailableMogs(slot, {})

	if not skin and not itemID then return end

	local f = skin and API.GetUnlockedVisualsForSlot or API.GetUnlockedVisualsForItem
	local p = skin and {transmogLocation} or {itemID, transmogLocation}

	requestCounterUS[transmogLocation] = (requestCounterUS[transmogLocation] or 0) + 1
	local requestID = requestCounterUS[transmogLocation]
	f(unpack(p)):next(function(items)
		if requestID == requestCounterUS[transmogLocation] then
			if itemID then
				table.insert(items, itemID) -- We still want equipped item in our list of transmogs ...
			end
			SetAvailableMogs(slot, items)
		else
			--core.am("This answer to RequestUnlocksSlot("..slot..") is outdated, a newer Update was already requested.")
		end
	end):catch(function(err)
		print("RequestUnlocksSlot: An error occured:", err.message)
	end)
end


-- Only calling this once on LogIn, so we do not need to trigger any updates to Interface. Could also just put the API call directly in the OnLogin
-- IF for some reason we want to call this later on, we have to change it, so that it also sets items to 0 that are not in this answer
local requestCounterUA = {}
core.RequestUnlocksAll = function(slot)
	local requestID = requestCounterUA
	API.GetUnlockedVisuals(true):next(function(items)
		if requestID == requestCounterUA then
			-- TODO: should we check our data for unlocked items, which where not received in GetUnlockedVisuals() ? smth like:
			-- for itemID, data in pairs(core.itemData) do
			--	core.SetUnlocked(itemID, 0) (option for second param not implemented atm)
			-- end

			for _, itemID in pairs(items) do
				core.SetUnlocked(itemID)
			end
			core.GenerateStringData()
		end
	end):catch(function(err)
		core.GenerateStringData() -- TODO: better way to do this?
		print("RequestUnlocksAll: An error occured:", err.message)
	end)
end

local requestCounterACC = 0
core.RequestApplyCurrentChanges = function()
	requestCounterACC = requestCounterACC + 1
	local requestID = requestCounterACC
	API.ApplyAll(ToApiSet(MyAddonDB.currentChanges), core.GetSelectedSkin()):next(function(answer)
		if requestID == requestCounterACC then
			PlaySound(6555) -- 888
			core.PlayApplyAnimations()
			SetCurrentChanges(core.GetCurrentChanges()) -- or {}, since should be applied
		end
	end):catch(function(err)
		print("RequestApplyCurrentChanges: An error occured:", err.message)		
		SetCurrentChanges(core.GetCurrentChanges()) -- unknown number of slots might have succefully applied. clears pendings where changes went through
		UIErrorsFrame:AddMessage(err.message, 1.0, 0.1, 0.1, 1.0)
	end)
end	

local requestCounterB = 0
core.RequestBalance = function()
	requestCounterB = requestCounterB + 1
	local requestID = requestCounterB
	API.GetBalance():next(function(balance)
		if requestID == requestCounterB then
			print("Your balance is: " .. balance.shards .. " moggies.")
			--balance = bal["points"] --TODO: listener + setter etc
			--balanceFrame.update()
			SetBalance(balance)
		end
	end):catch(function(err)
		print("RequestBalance: An error occured:", err.message)
	end)
end

local requestCounterPOA = 0
core.RequestPriceTotal = function()
	requestCounterPOA = requestCounterPOA + 1
	SetCosts() -- Setting costs to nil disables apply button and cost display while we are waiting for an answer

	if core.Length(MyAddonDB.currentChanges) == 0 then return end -- No changes, so nothing to apply and no costs to display

	local requestID = requestCounterPOA
	API.GetPriceAll(ToApiSet(MyAddonDB.currentChanges), core.GetSelectedSkin()):next(function(price)
		if requestID == requestCounterPOA then
			SetCosts(price.copper, price.shards)
		end
	end):catch(function(err)
		print("RequestPriceTotal: An error occured:", err.message)
		if requestID == requestCounterPOA then
			SetCosts()
		end
	end)
end

-- local requestCounterSlotPrices = {}
-- core.RequestPriceSlot = function(itemSlot)
-- 	requestCounterSlotPrices[itemSlot] = (requestCounterSlotPrices[itemSlot] or 0) + 1
-- 	--SetSlotCostsAndReason(itemSlot) -- Resetting data in SetCurrentChanges(Slot) atm

-- 	local itemID, _, _, pendingID = core.TransmogGetSlotInfo(itemSlot)
-- 	local selectedSkin = core.GetSelectedSkin()
-- 	local location = ToTransmogLocation(itemSlot)
	
-- 	if not pendingID then return end -- No pending change, so no price to request

-- 	if not (selectedSkin or itemID) then print("ERROR in RequestPriceSlot, requesting price for empty slot") end

-- 	local requestID = requestCounterSlotPrices[itemSlot]
-- 	API.GetPrice(pendingID, not selectedSkin and itemID or nil, location):next(function(price)
-- 		if requestID == requestCounterSlotPrices[itemSlot] then
-- 			--print("Got an answer Poggers Prices", itemSlot, price.copper, price.shards)
-- 			SetSlotCostsAndReason(itemSlot, price.copper, price.shards)
-- 		end
-- 	end):catch(function(err)
-- 		if requestID == requestCounterSlotPrices[itemSlot] then
-- 			print("RequestPriceSlot " .. (itemSlot or "nil") .. ": An error occured:", err.message)
-- 			SetSlotCostsAndReason(itemSlot, nil, nil, err.message)
-- 		end
-- 	end)
-- end

local requestCounterSlotPrices = {}
core.RequestPriceSlot = function(itemSlot)
	requestCounterSlotPrices[itemSlot] = (requestCounterSlotPrices[itemSlot] or 0) + 1
	SetSlotCostsAndReason(itemSlot) -- Resetting data in SetCurrentChanges(Slot) atm

	local itemID, _, _, pendingID = core.TransmogGetSlotInfo(itemSlot)
	local selectedSkin = core.GetSelectedSkin()
	local location = ToTransmogLocation(itemSlot)
	
	if not pendingID then return end -- No pending change, so no price to request

	if not (selectedSkin or itemID) then print("ERROR in RequestPriceSlot, requesting price for empty slot") end

	local requestID = requestCounterSlotPrices[itemSlot]
	API.GetPriceAndCheck(pendingID, not selectedSkin and itemID or nil, location, selectedSkin):next(function(result)
		if requestID == requestCounterSlotPrices[itemSlot] then
			--print("Got an answer Poggers Prices", itemSlot, price.copper, price.shards)
			core.am(result)
			SetSlotCostsAndReason(itemSlot, result.copper, result.shards, result.valid, result.message)
		end
	end):catch(function(err)
		if requestID == requestCounterSlotPrices[itemSlot] then
			print("RequestPriceSlot " .. (itemSlot or "nil") .. ": An error occured:", err.message)
			SetSlotCostsAndReason(itemSlot, nil, nil, false, err.message)
		end
	end)
end

-- TODO: check slot / check all?
-- Options:
-- Make a Check + Price API function with deferred lib, like the xxxAll functions in the Transmog Lib
-- Make a Check Function, and always call price + check. Most inefficient solution, since we always do both server requests and also have double updates to GUI
-- Only call Check (which takes single slot or slot table?), when loading a set/outfit and don't call it, when we set a pending from our item collection? 

local function canReceiveTransmog(mogTarget, mogSource, slot)
	local canMog = false
	--local targetSubtype = select(7,GetItemInfo(mogTarget))
	--local sourceSubtype = select(7,GetItemInfo(mogSource))
	--if targetSubtype == sourceSubtype then canMog = true end
	if core.availableMogs[slot] and core.availableMogs[slot][mogSource]
			or mogSource == 0 then -- mogSource/visual either has to be in list of available mogs, or stand for hide (1) or unmog (0) TODO: hide and unmog to fields instead of these magic numbers everywhere --or mogSource == 1 
		canMog = true
	end

	return canMog
end
core.CanReceiveTransmog = canReceiveTransmog

core.GetDefaultCategory = function(itemSlot)
	local _, class = UnitClass("player")
	local level = UnitLevel("player")
	local itemID = core.TransmogGetSlotInfo(itemSlot)
	local itemCategory
	if itemID then
		local class, subclass = select(6, GetItemInfo(itemID))
		itemCategory = class.." "..subclass
	end

	if itemSlot == "MainHandSlot" then
		return itemCategory or "Waffe Dolche"
	elseif itemSlot == "SecondaryHandSlot" then
		return itemCategory or "Rüstung Schilde"
	elseif itemSlot == "ShieldHandWeaponSlot" then
		return itemCategory or "Waffe Dolche"
	elseif itemSlot == "OffHandSlot" then
		return itemCategory or "Rüstung Schilde"
	elseif itemSlot == "RangedSlot" then
		return itemCategory or "Waffe Bogen"
	elseif itemSlot == "BackSlot" then
		return "Rüstung Stoff"
	elseif itemSlot == "ShirtSlot" or itemSlot == "TabardSlot" then
		return "Rüstung Verschiedenes"
	else
		if class == "PALADIN" or class == "WARRIOR" or class == "DEATHKNIGHT" then
			if level < 40 then
				return "Rüstung Schwere Rüstung"
			else
				return "Rüstung Platte"
			end
		elseif class == "SHAMAN" or class == "HUNTER" then
			if level < 40 then
				return "Rüstung Leder"
			else
				return "Rüstung Schwere Rüstung"
			end
		elseif class == "DRUID" or class == "ROGUE" then
			return "Rüstung Leder"
		else
			return "Rüstung Stoff"
		end
	end
end

local function canBeEnchanted(itemSlot)
	local itemID = MyAddonDB.currentChanges[itemSlot]
	--local itemID = GetInventoryItemID("player", GetInventorySlotInfo(itemSlot))
	if not itemID then return false end
	local itemSubType = select(7, GetItemInfo(itemID))
	--core.am(itemSubType)
	return core.Contains({"Dolche", "Faustwaffen", "Einhandäxte", "Einhandstreitkolben", "Einhandschwerter",
		"Stangenwaffen", "Stäbe", "Zweihandäxte", "Zweihandstreitkolben", "Zweihandschwerter"}, itemSubType)	
end



local canBeTitanGripped = {["Zweihandäxte"] = true, ["Zweihandstreitkolben"] = true, ["Zweihandschwerter"] = true}
local twoHandNoTitanGrip = {"Stangenwaffen", "Stäbe", "Angelruten"}
local DUMMY_POLEARM = 20083
local DUMMY_INVISIBLE_ONEHANDER = 45630 -- 45630 "Invisible Axe" but its the buggy cube instead, 25194 smallest knuckle duster

core.EquipOffhandNext = function(model)
	if not core.DUMMY_MODEL then
		core.DUMMY_MODEL = CreateFrame("DressUpModel", nil, UIParent)		
		core.DUMMY_MODEL:SetUnit("player")
	end
	--core.DUMMY_MODEL:SetParent(model)
	--core.DUMMY_MODEL:SetSize(100, 100)
	--core.DUMMY_MODEL:SetUnit("player")
	--core.DUMMY_MODEL:SetPoint("RIGHT", UIParent, "LEFT")
	core.DUMMY_MODEL:Show()
	core.DUMMY_MODEL:TryOn(DUMMY_POLEARM) -- reset
	core.DUMMY_MODEL:TryOn(DUMMY_INVISIBLE_ONEHANDER) -- equip 1h one time so next one goes into offhand
	core.DUMMY_MODEL:Hide()
end
-- TODO: Guarantee that only the latest Call per Model gets retried On Item Info (or ensure we always have iteminfo before setting anything) the current oniteminfo stuff would not work if needed
-- TODO?: Does not use the newest trick yet, that lets us display 2h + off hand only item for dualwielders
-- The EquipToOffhand trick relies on weaponslots being cleared, which breaks the way previewmodel uses this function, so i removed it for now in the only offhand part.
-- still has the problem for no titangrip chars that we cant put 2h into offhand there and either have to do another error message or try to do something with animations or both... should work on this later

-- Should probably do a full rework of this at some point with all the new Tricks Ive found


-- Displays Weapons mainHand and offHand on DressUpModel mod as well as possible (i.e. can't display dualwielding weapons, if the player can't dualwield and wasn't logged into a dualwielding char earlier in the session)
-- the login thing is just another DressUpModel weirdness, since it would be confusing and we can't track it anyway, we ignore that point
-- requires an undress of the weapons before usage, now that we use that EquipToOffhand trick sometimes instead of always using an "in(not so much)visible" wepaon in MH
local function ShowMeleeWeapons(mod, mainHand, offHand)
	if not (mainHand or offHand) or not mod then return end
	
	local mhSubType, mhInvType, ohSubType, ohInvType
	if mainHand then
		mhSubType, _, mhInvType = select(7, GetItemInfo(mainHand)) -- TODO: this would spout error if we dont have item cached, so this is pointless. should instead make sure iteminfo is always secured before this gets called (which we do apparently?)
		if not mhSubType then
			FunctionOnItemInfo(mainHand, ShowMeleeWeapons, mod, mainHand, offHand)
			return
		end
	end
	if offHand then
		ohSubType, _, ohInvType = select(7, GetItemInfo(offHand))
		if not ohSubType then
			FunctionOnItemInfo(offHand, ShowMeleeWeapons, mod, mainHand, offHand)
			return
		end
	end
	
	local hasTitanGrip = select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1
	local canDualWield = IsSpellKnown(674)

	if mainHand then
		mod:TryOn(DUMMY_POLEARM)
		mod:TryOn(mainHand)
		if offHand then
			if ohInvType == "INVTYPE_SHIELD" or ohInvType == "INVTYPE_HOLDABLE" or ohInvType == "INVTYPE_WEAPONOFFHAND"
				or canDualWield and (ohInvType ~= "INVTYPE_2HWEAPON" or hasTitanGrip and canBeTitanGripped[ohSubType]) then
				core.EquipOffhandNext(mod)
				mod:TryOn(offHand)
			else
				--am("MyAdddon: Cannot preview "..select(1, GetItemInfo(offHand)).." in offhand with "..select(1, GetItemInfo(mainHand)).." in mainhand.")
				return 1
			end
		end
	else
		if (ohInvType == "INVTYPE_SHIELD" or ohInvType == "INVTYPE_HOLDABLE" or ohInvType == "INVTYPE_WEAPONOFFHAND") then
			mod:TryOn(offHand)
		elseif canDualWield and (ohInvType == "INVTYPE_WEAPON" or (hasTitanGrip and canBeTitanGripped[ohSubType])) then
			if ohInvType == "INVTYPE_WEAPON" then -- trick of toggling hand on other model does not work with 1H, when nothing is equipped in mh .. 
				mod:TryOn(DUMMY_POLEARM)
				mod:TryOn(DUMMY_INVISIBLE_ONEHANDER)
			else
				core.EquipOffhandNext(mod)
			end
			--core.EquipOffhandNext(mod)
			mod:TryOn(offHand)
		else
			--core.am("MyAdddon: Cannot preview "..select(1, GetItemInfo(offHand)).." in offhand.")
			return 1
		end
	end
end
core.ShowMeleeWeapons = ShowMeleeWeapons


local CheckForInvalidSetname = function(name)
	local denyMessage
	if string.len(name) < 1 then
		denyMessage = core.SKIN_NAME_TOO_SHORT
	elseif string.find(name, "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz _.,'1234567890]") then
		denyMessage = core.SKIN_NAME_INVALID_CHARACTERS
	end
	
	return denyMessage
end

core.AttemptSkinRename = function(skinID, newName)
	local denyMessage = CheckForInvalidSetname(newName)
	if denyMessage then
		core.am(denyMessage)		
		UIErrorsFrame:AddMessage(denyMessage, 1.0, 0.1, 0.1, 1.0)
		return
	end

	core.RequestSkinRename(skinID, newName)
end



-- core.OnEquippedItemChange = function(itemSlot, itemEquipped)
-- 	if not core.transmogFrame:IsShown() then
-- 		if not itemEquipped then
-- 			core.availableMogs[itemSlot] = {}
-- 		else
-- 			core.availableMogsUpdateNeeded[itemSlot] = true -- Update when we open Transmogwindow
-- 		end
-- 	else
-- 		if not itemEquipped then
-- 			if itemSlot == selectedSlot then
-- 				SetSlotAndCategory(nil, nil)
-- 			end
-- 			SetCurrentChangesSlot(itemSlot, nil)
-- 		else
-- 			core.RequestUnlocksSlot(itemSlot)
-- 		end
-- 		UpdateListeners("inventory")
-- 	end
-- end

core.OnEquippedItemChange = function(itemSlot, itemEquipped)	
	local selectedSkin = core.GetSelectedSkin()
	local selectedSlot = core.GetSelectedSlot()
	
	if not selectedSkin then
		SetCurrentChangesSlot(itemSlot, nil)		
		if itemSlot == selectedSlot then
			SetSlotAndCategory(nil, nil)
		end
	end

	if not core.transmogFrame:IsShown() then
		if not itemEquipped then
			core.availableMogs[itemSlot] = {}
		else
			core.availableMogsUpdateNeeded[itemSlot] = true -- Update when we open Transmogwindow
		end
	else
		core.RequestUnlocksSlot(itemSlot)
	end

	UpdateListeners("inventory")
end


core.IsOffHandItemType = function(itemType)
	return itemType == "INVTYPE_SHIELD" or itemType == "INVTYPE_HOLDABLE"
end

local isWeaponSlot = {
	"MainHandSlot",
	"SecondaryHandSlot",
	"ShieldHandWeaponSlot",
	"OffHandSlot",
	"RangedSlot",
}
core.IsWeaponSlot = function(slot)
	return isWeaponSlot[slot]
end


core.OpenTransmogWindow = function()
	core.wardrobeFrame:Hide()	
	core.SetIsAtTransmogrifier(true)
	core.transmogFrame:Show()
end

core.gossipBlocker = CreateFrame("Frame", nil, GossipFrame)
core.gossipBlocker:SetAllPoints()
core.gossipBlocker:EnableMouse()
core.gossipBlocker:Hide()

core.HideGossipFrame = function()
	GossipFrameGreetingPanel:Hide() --here or onshow
	GossipFrameCloseButton:Hide()
	GossipFrame:SetAlpha(0)
	core.gossipBlocker:Show()
end

core.gossipOpenTransmogButton = core.CreateMeATextButton(GossipFrame, 112, 24, "Transmogrify")
core.gossipOpenTransmogButton:SetScript("OnClick", function()	
	core.HideGossipFrame()
	core.OpenTransmogWindow()
end)
core.gossipOpenTransmogButton:SetPoint("TOP", GossipNpcNameFrame, "BOTTOM", 0, -10)
------------------------------------------------------
-- / LOAD THE SHIT / -- and event listener frame
------------------------------------------------------  

local a = CreateFrame("Frame")
a:RegisterEvent("PLAYER_ENTERING_WORLD")
a:RegisterEvent("CHAT_MSG_ADDON")
a:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
a:RegisterEvent("GOSSIP_SHOW")
a:RegisterEvent("GOSSIP_CLOSED")
a:RegisterEvent("PLAYER_MONEY")

a:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		core.InitializeFrame() -- TODO: change to work like the other frames
		core.CreateActiveSkinDropDown(PaperDollFrame)
		
		core.InitLDB()
		core.RequestSkins()
		core.RequestActiveSkin()
		core.GenerateCompressedItemData()
		core.RequestUnlocksAll()
		core.RequestBalance()
		core.RequestSkinCosts()
		core.RequestGetConfig()
		SetCurrentChanges({})

		core.PreHook_ModifiedItemClick()
		--BackgroundItemInfoWorker.Start()		

	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		print(event, ...)
		local inventorySlotID, itemEquipped = ...
		local itemSlot = idToSlot[inventorySlotID]
		if not itemSlot then return end

		if inventorySlotID == 17 then
			local itemID = itemEquipped and core.GetInventoryItemID("player", 17) -- Here we want real inventory info
			local itemType = itemID and select(9, GetItemInfo(itemID))

			core.OnEquippedItemChange("OffHandSlot", itemType and core.IsOffHandItemType(itemType))
			core.OnEquippedItemChange("ShieldHandWeaponSlot", itemType and not core.IsOffHandItemType(itemType))
		else
			core.OnEquippedItemChange(itemSlot, itemEquipped)
		end

	elseif event == "GOSSIP_SHOW" then --TODO: Alternatively could hook gossipframe stuff and check the button names or smth to see if its the tmog npc
		if not UnitGUID("target") then return end
		
		local npcID = core.GetNPCID(UnitGUID("target"))
		core.SetShown(core.gossipOpenTransmogButton, npcID == core.TMOG_NPC_ID)
		core.replaceGossipFrame = false

		if core.replaceGossipFrame and npcID == core.TMOG_NPC_ID then
		--if GossipFrameNpcNameText:GetText() == "Warpweaver" and not GameMenuFrame:IsShown() then
			--gossipFrameWidthBackup = GossipFrame:GetWidth() --too thick, hide on characterwindow openinstead?
			--GossipFrame:SetWidth(1000)--core.transmogFrame:GetWidth())
			--GossipFrame:SetWidth(core.transmogFrame:GetWidth())
			core.transmogFrame:Hide()
			core.HideGossipFrame()
			core.OpenTransmogWindow()	
		end
	elseif event == "GOSSIP_CLOSED" then
		--GossipFrame:SetWidth(gossipFrameWidthBackup)
		GossipFrame:SetAlpha(1)
		core.gossipBlocker:Hide()
		core.transmogFrame:Hide()

	elseif event == "PLAYER_MONEY" then
		UpdateListeners("money")
	end
end)

--Hooks

CharacterFrame:HookScript("OnShow", function()
	if core.transmogFrame:IsShown() then
		--MyWaitFunction(0.01, CloseGossip)
	end
end)

--[[
--local gossipFrameWidthBackup
GossipFrame:HookScript("OnShow", function()
	if GossipFrameNpcNameText:GetText() == "Warpweaver" and not GameMenuFrame:IsShown() then
		--gossipFrameWidthBackup = GossipFrame:GetWidth() --too thick, hide on characterwindow openinstead?
		--core.am(GossipFrame:GetWidth())
		--GossipFrame:SetWidth(100)--core.transmogFrame:GetWidth())
		--GossipFrame:SetWidth(core.transmogFrame:GetWidth())
		GossipFrameGreetingPanel:Hide() --here or onshow
		GossipFrameCloseButton:Hide()
		GossipFrame:SetAlpha(0)
		--CharacterFrame:Hide()
		core.transmogFrame:Show()
	end
end)

GossipFrame:HookScript("OnHide", function()
	core.transmogFrame:Hide()
	GossipFrame:SetAlpha(1)
	GossipFrameNpcNameText:SetText("Not Warpi")
end)]]





PrintCurrentChanges = function()
	core.am(MyAddonDB.currentChanges)
end

PrintSkins = function()
	core.am(skins)
end

GetSkins = function()
	return skins
end

PrintAllCosts = function()
	for _, slot in pairs(itemSlots) do
		print(slot, slotCostsCopper[slot], slotCostsShards[slot], slotReason[itemSlot])
	end
end

PrintBalance = function()
	am(balance)
end



-- local f = CreateFrame("Frame")
-- f:RegisterEvent("CHAT_MSG_ADDON")
-- f:SetScript("OnEvent", function(self, event, ...)
-- 	if event == "CHAT_MSG_ADDON" then
-- 		local _, prefix, msg, channel, source = ...
-- 		if source == "Server" then
-- 			self.rLen = (self.rLen or 0) + strlen(msg)
-- 			print(msg)
-- 			self.rCount = (self.rCount or 0) + 1
-- 		else
-- 			print(...)
-- 		end
-- 	end
-- end)
-- f:SetScript("OnUpdate", function(self, e)
-- 	self.e = (self.e or 0) + e
-- 	if self.e > 3 then
-- 		self.e = self.e - 1
-- 		if self.rLen ~= self.rLenOld then
-- 			print("Received:", self.rLen - (self.rLenOld or 0), "length", self.rCount - (self.rCountOld or 0), "count")
-- 			self.rLenOld = self.rLen
-- 			self.rCountOld = self.rCount
-- 		end
-- 	end
-- end)

-- local g = CreateFrame("Frame")
-- g:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
-- g:RegisterEvent("UNIT_INVENTORY_CHANGED")
-- g:RegisterEvent("INSPECT_READY")
-- g:SetScript("OnEvent", function(self, event, ...)
-- 	local slot, isEquipped = ...

-- 	print(event, slot, isEquipped and core.GetTextureString(GetInventoryItemTexture("player", slot), 12))
-- end)

-- PaperDollItemSlotButton_UpdateOld = PaperDollItemSlotButton_Update 
-- PaperDollItemSlotButton_Update = function(self)
-- 	PaperDollItemSlotButton_UpdateOld(self)
-- 	if self:GetID() > 19 then return end

-- 	print("UWU", self:GetID(), core.GetTextureString(GetInventoryItemTexture("player", self:GetID()) or "", 12))
-- end

