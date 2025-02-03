-----------------------------------------------
-- Created by Qhoernchen - qhoernchen@gmail.com
-----------------------------------------------

local folder, core = ...

TransmoggyDB = TransmoggyDB or {}

local risingAPI = "RisingAPI"
local rAPI = LibStub(risingAPI, true)
if not rAPI then error(folder .. " missing dependency " .. risingAPI .. "."); return end
rAPI:debug(false)

if not rAPI.Transmog then error(folder .. " missing RisingAPI transmog module."); return end
core.API = rAPI.Transmog

---- Ace Options ----
core.version = GetAddOnMetadata(folder, "Version")
core.title = folder -- "Transmoggy"
core.titleFull = folder .. " - V." .. core.version -- "Transmoggy V.1.0"
core.addonDir = "Interface\\AddOns\\"..folder.."\\"
core.minimapIcon = "Interface\\Icons\\Inv_chest_cloth_02"

core.InitializeAce = function(self)	
	self.db = LibStub('AceDB-3.0'):New('TransmoggyDB', self.defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileChanged")
	
	local profile = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
	local registry = LibStub('AceConfigRegistry-3.0')
	local dialog = LibStub('AceConfigDialog-3.0')

	registry:RegisterOptionsTable(self.title, self.options)
	registry:RegisterOptionsTable("Transmoggy-Profiles", profile)
	
	self.optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(self.title, self.title)
	LibStub('AceConfigDialog-3.0'):AddToBlizOptions("Transmoggy-Profiles", 'Profiles', self.title)

	core.OpenOptions = function()
		InterfaceOptionsFrame_OpenToCategory(core.optionsFrame)
	end
	
	LibStub('AceConsole-3.0'):RegisterChatCommand("transmoggy", core.OpenOptions) -- InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) end)
end

core.OnProfileChanged = function(self, ...)
	core.OnSettingsUpdate()
	print("OnProfileChanged", ...)
end
---------------------------------------

core.TMOG_NPC_ID = 1010969

--"inv_jewelcrafting_nobletopaz_01"
--"inv_misc_gem_sapphire_03"
--"inv_enchant_shardgleamingsmall"
core.CURRENCY_ICON = "Interface\\Icons\\inv_misc_gem_sapphire_03"

-- Using any invalid ID works fine with standard interface
-- Some Inventory AddOns use item ids for currencies tho. In that case an invalid item id here causes an error.
-- Only solution for this would probably be to choose an existing but unavailable item id here and hook GameTooltip to always replace the tooltip for this item?
-- 43949 - 'zzzOLDDaily Quest Faction Token'
core.CURRENCY_FAKE_ITEMID = 43949 -- -1337

core.HIDDEN_ID = -1		-- any ID that is not already used by items or enchants. enchant visual ID 1 is in use. currently display list uses those, so dont use 1 :^)
core.UNMOG_ID = 0 		-- changing this from 0 is not fully supported (e.g. GetInventoryEnchantID)

-- 11755 -- SimonGame_Visual_LevelStart
-- 4140	 -- HumanExploration
-- 12891 -- AchievementSound
-- 1202 -- "Sound\\interface\\PickUp\\PickUpParchment_Paper.wav"
-- 1204 -- PutDownGems
core.sounds = {
	applySuccess = 6199, -- 6555, -- 888,
	unlockVisual = 12009, -- 1204, 
	gainBalance = 1204,
}

core.DUMMY_WEAPONS = {
	POLEARM = 1485,							-- 1485: Any polearm. Used to reset a DressUpModel's memory about which hand had a 1H weapon equipped last
	INVISIBLE_1H = 25194, 					-- 45630 should be "Invisible Axe", but it shows as the debug cube model instead. 25194 is smallest knuckle duster
	ENCHANT_PREVIEW_WEAPON = 864, 			-- 864: Basic looking sword for enchant preview
	ENCHANT_PREVIEW_OFFHAND_WEAPON = 12939, -- 12939: Most basic offhand weapon I could find so far. Used to display enchanted offhand weapon without dualwield
	TOOLTIP_FIX_ITEM = 32479,				-- 32479: Any item with >= 9 tooltip lines. Needed for tooltip line fix
	["1H_EXOTICA"] = 32407,					-- 32407: Only item of 1h exotica type. Needed to get (non DE/EN) localized category name
}

core.QueryItem(core.CURRENCY_FAKE_ITEMID)
for name, itemID in pairs(core.DUMMY_WEAPONS) do
	core.QueryItem(itemID)
end

-- The following tables do not need to be localized manually. We overwrite these with the correct localized names using GetAuctionItemClasses() and GetAuctionItemSubClasses()
core.ITEM_CLASSES = {
	ARMOR = "Rüstung",
	WEAPON = "Waffe",
	MISC = "Verschiedenes",
	TRADE_GOODS = "Handwerkswaren",
	CONSUMABLE = "Verbrauchbar",
	QUEST = "Quest",
}

core.ITEM_SUB_CLASSES = {
	CLOTH = "Stoff",
	LEATHER = "Leder",
	MAIL = "Schwere Rüstung",
	PLATE = "Platte",
	MISC = "Verschiedenes",
	-- WEAPON_MISC = "Verschiedenes",
	SHIELDS = "Schilde",
	DAGGERS = "Dolche",
	FIST_WEAPONS = "Faustwaffen",
	["1H_AXES"] = "Einhandäxte",
	["1H_MACES"] = "Einhandstreitkolben",
	["1H_SWORDS"] = "Einhandschwerter",
	POLEARMS = "Stangenwaffen",
	STAVES = "Stäbe",
	["2H_AXES"] = "Zweihandäxte",
	["2H_MACES"] = "Zweihandstreitkolben",
	["2H_SWORDS"] = "Zweihandschwerter",
	FISHING_POLES = "Angelruten",
	BOWS = "Bogen",
	CROSSBOWS = "Armbrüste",
	GUNS = "Schusswaffen",
	THROWN = "Wurfwaffen",
	WANDS = "Zauberstäbe",
	JUNK = "Plunder",
	MEAT = "Fleisch",
	CONSUMABLE = "Verbrauchbar",
	QUEST = "Quest",
	["1H_EXOTICA"] = "Einhandexotika",
}

core.CATEGORIES = {
	ARMOR_CLOTH = "Rüstung Stoff",
	ARMOR_LEATHER = "Rüstung Leder",
	ARMOR_MAIL = "Rüstung Schwere Rüstung",
	ARMOR_PLATE = "Rüstung Platte",
	ARMOR_MISC = "Rüstung Verschiedenes",
	ARMOR_SHIELDS = "Rüstung Schilde",
	WEAPON_DAGGERS = "Waffe Dolche",
	WEAPON_FIST_WEAPONS = "Waffe Faustwaffen",
	WEAPON_1H_AXES = "Waffe Einhandäxte",
	WEAPON_1H_MACES = "Waffe Einhandstreitkolben",
	WEAPON_1H_SWORDS = "Waffe Einhandschwerter",
	WEAPON_POLEARMS = "Waffe Stangenwaffen",
	WEAPON_STAVES = "Waffe Stäbe",
	WEAPON_2H_AXES = "Waffe Zweihandäxte",
	WEAPON_2H_MACES = "Waffe Zweihandstreitkolben",
	WEAPON_2H_SWORDS = "Waffe Zweihandschwerter",
	WEAPON_FISHING_POLES = "Waffe Angelruten",
	WEAPON_MISC = "Waffe Verschiedenes",
	WEAPON_BOWS = "Waffe Bogen",
	WEAPON_CROSSBOWS = "Waffe Armbrüste",
	WEAPON_GUNS = "Waffe Schusswaffen",
	WEAPON_THROWN = "Waffe Wurfwaffen",
	WEAPON_WANDS = "Waffe Zauberstäbe",
	MISC_JUNK = "Verschiedenes Plunder",
	-- Troll Types
	TRADE_GOODS_MEAT = "Handwerkswaren Fleisch",
	CONSUMABLE_CONSUMABLE = "Verbrauchbar Verbrauchbar",
	QUEST_QUEST = "Quest Quest",
	WEAPON_1H_EXOTICA = "Waffe Einhandexotika",
}

do
	-- localize item categories by using auction house item classes + subclasses
	local classes = { GetAuctionItemClasses() }
	core.ITEM_CLASSES = {
		ARMOR = classes[2],
		WEAPON = classes[1],
		MISC = classes[11],
		TRADE_GOODS = classes[6],
		CONSUMABLE = classes[4],
		QUEST = classes[12],
	}

	local weaponSubClasses, armorSubClasses, miscSubClasses = { GetAuctionItemSubClasses(1) }, { GetAuctionItemSubClasses(2) }, { GetAuctionItemSubClasses(11) }
	local tradeGoodsSubClasses = { GetAuctionItemSubClasses(6) }
	local _, _, _, _, _, _, exoticaSubClass = GetItemInfo(core.DUMMY_WEAPONS["1H_EXOTICA"])
	local loc = GetLocale()
	core.ITEM_SUB_CLASSES = {
		CLOTH = armorSubClasses[2],
		LEATHER = armorSubClasses[3],
		MAIL = armorSubClasses[4],
		PLATE = armorSubClasses[5],
		MISC = armorSubClasses[1], -- there exists armor and weapon misc subtype in english and german, hopefully it's the same in every language ._.
		-- WEAPON_MISC = weaponSubClasses[12],
		SHIELDS = armorSubClasses[6],
		DAGGERS = weaponSubClasses[13],
		FIST_WEAPONS = weaponSubClasses[11],
		["1H_AXES"] = weaponSubClasses[1],
		["1H_MACES"] = weaponSubClasses[5],
		["1H_SWORDS"] = weaponSubClasses[8],
		POLEARMS = weaponSubClasses[7],
		STAVES = weaponSubClasses[10],
		["2H_AXES"] = weaponSubClasses[2],
		["2H_MACES"] = weaponSubClasses[6],
		["2H_SWORDS"] = weaponSubClasses[9],
		FISHING_POLES = weaponSubClasses[17],
		BOWS = weaponSubClasses[3],
		CROSSBOWS = weaponSubClasses[15],
		GUNS = weaponSubClasses[4],
		THROWN = weaponSubClasses[14],
		WANDS = weaponSubClasses[16],
		JUNK = miscSubClasses[1],
		-- Troll Types
		MEAT = tradeGoodsSubClasses[5],
		CONSUMABLE = classes[4], -- weird case. subclass is also consummable (the same as class), but that subclass does not get listed in AuctionSubClasses
		QUEST = classes[12], -- same as above
		["1H_EXOTICA"] = exoticaSubClass or (loc == "deDE" and "Einhandexotika") or "One-Handed Exotics",
	}

	core.CATEGORIES = {
		ARMOR_CLOTH = core.ITEM_CLASSES.ARMOR .. " " .. core.ITEM_SUB_CLASSES.CLOTH,
		ARMOR_LEATHER = core.ITEM_CLASSES.ARMOR .. " " .. core.ITEM_SUB_CLASSES.LEATHER,
		ARMOR_MAIL = core.ITEM_CLASSES.ARMOR .. " " .. core.ITEM_SUB_CLASSES.MAIL,
		ARMOR_PLATE = core.ITEM_CLASSES.ARMOR .. " " .. core.ITEM_SUB_CLASSES.PLATE,
		ARMOR_MISC = core.ITEM_CLASSES.ARMOR .. " " .. core.ITEM_SUB_CLASSES.MISC,
		ARMOR_SHIELDS = core.ITEM_CLASSES.ARMOR .. " " .. core.ITEM_SUB_CLASSES.SHIELDS,
		WEAPON_DAGGERS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.DAGGERS,
		WEAPON_FIST_WEAPONS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.FIST_WEAPONS,
		WEAPON_1H_AXES = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES["1H_AXES"],
		WEAPON_1H_MACES = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES["1H_MACES"],
		WEAPON_1H_SWORDS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES["1H_SWORDS"],
		WEAPON_POLEARMS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.POLEARMS,
		WEAPON_STAVES = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.STAVES,
		WEAPON_2H_AXES = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES["2H_AXES"],
		WEAPON_2H_MACES = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES["2H_MACES"],
		WEAPON_2H_SWORDS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES["2H_SWORDS"],
		WEAPON_FISHING_POLES = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.FISHING_POLES,
		WEAPON_MISC = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.MISC,
		WEAPON_BOWS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.BOWS,
		WEAPON_CROSSBOWS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.CROSSBOWS,
		WEAPON_GUNS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.GUNS,
		WEAPON_THROWN = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.THROWN,
		WEAPON_WANDS = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES.WANDS,
		MISC_JUNK = core.ITEM_CLASSES.MISC .. " " .. core.ITEM_SUB_CLASSES.JUNK,
		-- Troll Types
		TRADE_GOODS_MEAT = core.ITEM_CLASSES.TRADE_GOODS .. " " .. core.ITEM_SUB_CLASSES.MEAT,
		CONSUMABLE_CONSUMABLE = core.ITEM_CLASSES.CONSUMABLE .. " " .. core.ITEM_SUB_CLASSES.CONSUMABLE,
		QUEST_QUEST = core.ITEM_CLASSES.QUEST .. " " .. core.ITEM_SUB_CLASSES.QUEST,
		WEAPON_1H_EXOTICA = core.ITEM_CLASSES.WEAPON .. " " .. core.ITEM_SUB_CLASSES["1H_EXOTICA"]
	}

	core.CATEGORY_DISPLAY_NAME = {
		[core.CATEGORIES.TRADE_GOODS_MEAT] = core.ITEM_SUB_CLASSES.MEAT,
	}
	
end

-- hex colors are encoded as "AARRGGBB" (alpha first!) for string formatting
-- core.mogTooltipTextColor = { ["r"] = 0xff / 255, ["g"] = 0x9c / 255, ["b"] = 0xe6 / 255, ["a"] = 1, hex = "FFFF9CE6"}
core.mogTooltipTextColor = { ["r"] = 0xff / 255, ["g"] = 0x80 / 255, ["b"] = 0xff / 255, ["a"] = 1, hex = "ffff80ff"}
core.skinTextColor = { ["r"] = 0x9c / 255, ["g"] = 0xe6 / 255, ["b"] = 0xff / 255, ["a"] = 1, hex = "FF9CE6FF" }
core.setItemTooltipTextColor = { ["r"] = 1, ["g"] = 1, ["b"] = 0.6, ["a"] = 1 }
core.setItemMissingTooltipTextColor = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 1 }
core.bonusTooltipTextColor = { ["r"] = 0, ["g"] = 1, ["b"] = 0, ["a"] = 1 }
core.appearanceNotCollectedTooltipColor = { r = 0.30, g = 0.52, b = 0.90, a = 1, hex = "FF4D85E6" } 	--Royal Blue 
core.greyTextColor = { r = 0.53, g = 0.62, b = 0.62, a = 1, hex = "FF889D9D"}
core.yellowTextColor = { r = 1, g = 242 / 255, b = 15 / 255, a = 1, hex = "FFfff30f"}
core.normalFontColor = { r = 1, g = 0.82, b = 0, a = 1, hex = "ffffd200"}

-- scuffed listener pattern to update the correct frames on data changes
local listeners = {}
local RegisterListener, UpdateListeneres

-- Functions that interact with the API. Trigger another Request or trigger SetX function on server answer. Convert to and from API set format
local RequestUnlocksSlot, RequestPriceTotal, RequestPriceSlot, RequestApplyCurrentChanges, RequestBalance, RequestSkins, RequestSkinRename
-- Functions setting data and trigger update function of registered GUI elements
local SetCosts, SetSlotCostsAndReason, SetSkinCosts, SetCurrentChanges, SetCurrentChangesSlot, SetSlotAndCategory, SetBalance, SetSkinData, SetAvailableMogs

------------------- Data we modify through Setters, that cause frames registered with RegisterListener to call their .update function -----------------------------------

-- TransmoggyDB.currentChanges = TransmoggyDB.currentChanges or {} -- Get reset on Login and all the time atm., so no point in saving it in DB. Would have to save per character anyways
local balance = {}
local costs = {} -- copper = 0, points = 0, 
local skinCosts = {}
local skins = {}
local slotCostsCopper = {}
local slotCostsShards = {}
local slotValid = {}
local slotReason = {}
local config = nil

local atTransmogrifier -- bad var name. used in e.g. itemCollectionFrame to get different behaviour depending on whether we are using it in the TransmogFrame or the WardrobeFrame

------------------- Updoots (for speed and readability) ------------------------
local GetCoinTextureStringFull = core.GetCoinTextureStringFull
local API = core.API
local Length = core.Length
local DeepCompare = core.DeepCompare
local FunctionOnItemInfo = core.FunctionOnItemInfo
local ClearAllOutstandingOIIF = core.ClearAllOutstandingOIIF
local SetTooltip = core.SetTooltip
local MyWaitFunction = core.MyWaitFunction
local am = core.am

local CreateMeAButton = core.CreateMeAButton
local CreateMeATextButton = core.CreateMeATextButton
local CreateMeACustomTexButton = core.CreateMeACustomTexButton

local GetInventoryItemID = core.GetInventoryItemID
local GetContainerVisualID = core.GetContainerVisualID

------------------------------------------------------------------------------------------

-- maps Transmog API locations to game inventory slots
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
	MainHandWeapon = "MainHandSlot",
	OffHandWeapon = "SecondaryHandSlot",
	OffHand = "SecondaryHandSlot",
	Ranged = "RangedSlot",
	Back = "BackSlot",
	Tabard = "TabardSlot",
}

-- transmog location names that the addon uses
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
	-- "SecondaryHandSlot",
	"ShieldHandWeaponSlot",
	"OffHandSlot",
	"RangedSlot",
}
core.itemSlots = itemSlots

-- extra table for enchants. need different behaviour and are not really supported so far
core.enchantSlots = {
	"MainHandEnchantSlot",
	"SecondaryHandEnchantSlot",
}

core.allSlots = {
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
	"MainHandEnchantSlot",
	-- "SecondaryHandSlot",
	"ShieldHandWeaponSlot",
	"SecondaryHandEnchantSlot",
	"OffHandSlot",
	"RangedSlot",
}

core.IsEnchantSlot = function(slot)
	return slot and (slot == core.enchantSlots[1] or slot == core.enchantSlots[2])
end

local isWeaponSlot = {
	MainHandSlot = true,
	SecondaryHandSlot = true,
	ShieldHandWeaponSlot = true,
	OffHandSlot = true,
	RangedSlot = true,
}
core.IsWeaponSlot = function(slot)
	return slot and isWeaponSlot[slot]
end

-- Although we save and track the collection status of every item, we still need to ask the server what items are available for a specific slot and item
-- Currently we just always update these, when we click on a slot in the transmog interface
-- Would be nice if we could cache this info to reduce server requests, but we have no reliable way to know when the available mogs have changed
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

-- see above. we could try to catch all events, that might change our available mogs and their unlock status, but that will probably not be reliable
-- core.availableMogsUpdateNeeded = {}

-- for k, v in pairs(itemSlots) do
-- 	core.availableMogsUpdateNeeded[v] = true
-- end

-- itemSlots to game inventorySlot IDs
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
	["MainHandEnchantSlot"] = -16, --TODO: allowed? better to add a ToCorrespondingSlot function instead of this hacky minus stuff?
	["SecondaryHandEnchantSlot"] = -17,
	["RangedSlot"] = 18,
}
core.slotToID = slotToID

core.GetCorrespondingSlot = function(slot)
	local id = core.slotToID[slot]
	return id and core.idToSlot[-id]
end

-- Backwards map to GetInventorySlotInfo("slotName")
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
	[-16] = "MainHandEnchantSlot", -- TODO: Kinda scuffed to mix reversed InventorySlot and AddOnSlot maps?
	[-17] = "SecondaryHandEnchantSlot",
	[18] = "RangedSlot",
}
core.idToSlot = idToSlot

core.slotCategories = {
	["HeadSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC},
	["ShoulderSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC},
	["BackSlot"] = {core.CATEGORIES.ARMOR_CLOTH},
	["ChestSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC, core.CATEGORIES.MISC_JUNK},
	["ShirtSlot"] = {core.CATEGORIES.ARMOR_MISC},
	["TabardSlot"] = {core.CATEGORIES.ARMOR_MISC},
	["WristSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC},
	["HandsSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC},
	["WaistSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC, core.CATEGORIES.CONSUMABLE_CONSUMABLE},
	["LegsSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC},
	["FeetSlot"] = {core.CATEGORIES.ARMOR_CLOTH, core.CATEGORIES.ARMOR_LEATHER, core.CATEGORIES.ARMOR_MAIL, core.CATEGORIES.ARMOR_PLATE, core.CATEGORIES.ARMOR_MISC},
	["MainHandSlot"] = {core.CATEGORIES.WEAPON_DAGGERS, core.CATEGORIES.WEAPON_FIST_WEAPONS, core.CATEGORIES.WEAPON_1H_AXES, core.CATEGORIES.WEAPON_1H_MACES, core.CATEGORIES.WEAPON_1H_SWORDS, core.CATEGORIES.WEAPON_POLEARMS,
						core.CATEGORIES.WEAPON_STAVES, core.CATEGORIES.WEAPON_2H_AXES, core.CATEGORIES.WEAPON_2H_MACES, core.CATEGORIES.WEAPON_2H_SWORDS, core.CATEGORIES.WEAPON_FISHING_POLES, core.CATEGORIES.WEAPON_MISC},

	["SecondaryHandSlot"] = {core.CATEGORIES.ARMOR_SHIELDS, core.CATEGORIES.ARMOR_MISC, core.CATEGORIES.WEAPON_DAGGERS, core.CATEGORIES.WEAPON_FIST_WEAPONS, core.CATEGORIES.WEAPON_1H_AXES, core.CATEGORIES.WEAPON_1H_MACES,
							core.CATEGORIES.WEAPON_1H_SWORDS, core.CATEGORIES.WEAPON_2H_AXES, core.CATEGORIES.WEAPON_2H_MACES, core.CATEGORIES.WEAPON_2H_SWORDS, core.CATEGORIES.WEAPON_MISC, core.CATEGORIES.MISC_JUNK,
							core.CATEGORIES.TRADE_GOODS_MEAT},

	["ShieldHandWeaponSlot"] = {core.CATEGORIES.WEAPON_DAGGERS, core.CATEGORIES.WEAPON_FIST_WEAPONS, core.CATEGORIES.WEAPON_1H_AXES, core.CATEGORIES.WEAPON_1H_MACES, core.CATEGORIES.WEAPON_1H_SWORDS,
		core.CATEGORIES.WEAPON_2H_AXES, core.CATEGORIES.WEAPON_2H_MACES, core.CATEGORIES.WEAPON_2H_SWORDS, core.CATEGORIES.WEAPON_MISC},
	["OffHandSlot"] = {core.CATEGORIES.ARMOR_SHIELDS, core.CATEGORIES.ARMOR_MISC, core.CATEGORIES.MISC_JUNK, core.CATEGORIES.TRADE_GOODS_MEAT},

	["RangedSlot"] = {core.CATEGORIES.WEAPON_BOWS, core.CATEGORIES.WEAPON_CROSSBOWS, core.CATEGORIES.WEAPON_GUNS, core.CATEGORIES.WEAPON_THROWN, core.CATEGORIES.WEAPON_WANDS},
	["MainHandEnchantSlot"] = {},
	["SecondaryHandEnchantSlot"] = {},
}

-- the following inserts are additional slot categories for items that are in the game, but are either quest items (-> not transmogable?) or weird bugged test items, that can't be unlocked by normal means
if true then -- TODO: Options to en-/disable these?
	tinsert(core.slotCategories.MainHandSlot, core.CATEGORIES.WEAPON_1H_EXOTICA)
end

if true then 
	tinsert(core.slotCategories.HeadSlot, core.CATEGORIES.QUEST_QUEST)
	tinsert(core.slotCategories.BackSlot, core.CATEGORIES.QUEST_QUEST)
	tinsert(core.slotCategories.BackSlot, core.CATEGORIES.ARMOR_MISC) -- one quest cloak has armor type misc., even gets unlocked when added, but quest is deactivated
	tinsert(core.slotCategories.ChestSlot, core.CATEGORIES.QUEST_QUEST)
	tinsert(core.slotCategories.MainHandSlot, core.CATEGORIES.QUEST_QUEST)
	tinsert(core.slotCategories.SecondaryHandSlot, core.CATEGORIES.QUEST_QUEST)
	tinsert(core.slotCategories.OffHandSlot, core.CATEGORIES.QUEST_QUEST)
	tinsert(core.slotCategories.RangedSlot, core.CATEGORIES.QUEST_QUEST)
end

if true then
	tinsert(core.slotCategories.ShirtSlot, core.CATEGORIES.ARMOR_CLOTH) -- martins fury
end

if true then -- completely bugged items, that should probably not be included?
	-- INVTYPE_WEAPON: staves, 2hswords, 2haxes, polearms. these are all included in mhslot already, but would technically be usable as tmog for 1h in offhand?
	-- INVTYPE_2HWEAPON: armor misc (obtainable quest item o.O),
	-- INVTYPE_WEAPONMAINHAND: 2hswords,
	-- INVTYPE_RANGEDRIGHT: 1haxes, 
end

-- dict format of slotCategories for faster lookup
core.slotHasCategory = {}
for _, slot in pairs(core.itemSlots) do
	core.slotHasCategory[slot] = {}
	for _, category in pairs(core.slotCategories[slot]) do
		core.slotHasCategory[slot][category] = true
	end
end

core.GetTransmogLocationInfo = function(locationName)
	if not core.API.Slot[locationName] then return end

	local locationID = core.API.Slot[locationName]
	local inventorySlot = core.locationToInventorySlot[locationName]
	local slotID, slotTexture = GetInventorySlotInfo(core.locationToInventorySlot[locationName])
	local itemSlot = inventorySlot
	
	if locationName == "OffHandWeapon" then
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
	local isEnchantSlot = core.IsEnchantSlot(itemSlot)

	if isEnchantSlot then
		return slotID, "Interface\\Icons\\INV_Scroll_05"
	else
		return GetInventorySlotInfo(idToSlot[slotID])
	end
end


--[[


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
	EnchantOffHandWeapon  = "21",]]

local itemSlotToTransmogLocation = {
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
	MainHandSlot = "MainHandWeapon",
	ShieldHandWeaponSlot = "OffHandWeapon",
	OffHandSlot = "OffHand",
	-- SecondaryHandSlot", special case
	MainHandEnchantSlot = "EnchantMainHandWeapon", -- TODO: do we allow this?
	SecondaryHandEnchantSlot = "EnchantOffHandWeapon",
	RangedSlot = "Ranged",
}

core.ToTransmogLocation = function(itemSlot) --, special)
	if type(itemSlot) == "number" then
		if itemSlot == core.slotToID["MainHandEnchantSlot"] then
			itemSlot = "MainHandEnchantSlot"
		elseif itemSlot == core.slotToID["SecondaryHandEnchantSlot"] then
			itemSlot = "SecondaryHandEnchantSlot"
		else
			itemSlot = idToSlot[itemSlot]
		end
	end

	if itemSlotToTransmogLocation[itemSlot] then
		return API.Slot[itemSlotToTransmogLocation[itemSlot]]
	elseif itemSlot == "SecondaryHandSlot" then -- not sure if we still use this at all
		local equipped = GetInventoryItemID("player", 17)
		if not equipped then return API.Slot.OffHandWeapon end -- No offhand equipped, so the field will be nil anyway, but have to return something
		local invtype = select(9, GetItemInfo(equipped)) -- item info should always be cached/available for equipped items
		if invtype == "INVTYPE_SHIELD" or invtype == "INVTYPE_HOLDABLE" then
			return API.Slot.OffHand
		else
			return API.Slot.OffHandWeapon
		end
	end
end

local transmogLocationToItemSlot = {}
for itemSlot, transmogLocation in pairs(itemSlotToTransmogLocation) do
	transmogLocationToItemSlot[core.API.Slot[transmogLocation]] = itemSlot
end

-- Currently skins use api locations for some reason ...
core.GetSkinSlotVisualID = function(skinID, slotID)
	if not skinID then return end

	if not skins[skinID] then am("ERROR in GetSkinSlotVisualID: There is no skin with ID", skinID); return end

	return skins[skinID].slots[slotID]
end

core.GetInventorySkinID = function(inventorySlotID)
	local locationID = core.ToTransmogLocation(inventorySlotID)
	return core.GetSkinSlotVisualID(core.GetActiveSkin(), locationID)
end	

core.TransmogGetSlotInfo = function(itemSlot, skinID)
	assert(slotToID[itemSlot] ~= nil, "Invalid slot in TransmogGetSlotInfo: " .. (itemSlot or "nil"))
	skinID = skinID or core.GetSelectedSkin() -- TODO: always expect explicit specification of skinID instead?

	local isEnchantSlot = core.IsEnchantSlot(itemSlot)
	local correspondingWeaponSlot = isEnchantSlot and core.GetCorrespondingSlot(itemSlot)
	local inventorySlotID = slotToID[itemSlot]
	local locationID = core.ToTransmogLocation(itemSlot) -- TODO: hopefully soon replaced so we work on locations instead of itemslots (not gonna happen PEPW)
	--local locationID = core.GetTransmogLocationInfo(location)
	--print(itemSlot, "inventoryID", inventorySlotID, "location", location, "locationID", locationID, "selectedSkin", core.GetSelectedSkin())

	local itemID = isEnchantSlot and core.GetInventoryEnchantID("player", correspondingWeaponSlot) or core.GetInventoryItemID("player", inventorySlotID)
	local visualID = isEnchantSlot and core.GetInventoryEnchantVisualID("player", correspondingWeaponSlot) or core.GetInventoryVisualID("player", inventorySlotID)
	local skinVisualID = core.GetSkinSlotVisualID(skinID, locationID)
	local pendingID = TransmoggyDB.currentChanges and TransmoggyDB.currentChanges[itemSlot]
	local pendingCostsShards = slotCostsShards[itemSlot]
	local pendingCostsCopper = slotCostsCopper[itemSlot]
	local canTransmogrify = slotValid[itemSlot]
	local cannotTransmogrifyReason = slotReason[itemSlot]

	--print(slotID, itemID, visualID, skinVisualID, pendingID)
	if itemID and (itemSlot == "OffHandSlot" or itemSlot == "ShieldHandWeaponSlot" or itemSlot == "SecondaryHandEnchantSlot") then
		local offHand = core.GetInventoryItemID("player", 17)
		local isOffHandType = offHand and core.IsOffHandItemType(select(9, GetItemInfo(offHand)))
		if (itemSlot == "OffHandSlot" and not isOffHandType) or ((itemSlot == "ShieldHandWeaponSlot" or itemSlot == "SecondaryHandEnchantSlot") and isOffHandType) then
			itemID = nil
			visualID = nil
		end
	end

	return itemID, visualID, skinVisualID, pendingID, pendingCostsShards, pendingCostsCopper, canTransmogrify, cannotTransmogrifyReason
end

core.GetDefaultCategory = function(itemSlot)
	if core.IsEnchantSlot(itemSlot) then
		return
	end

	local _, class = UnitClass("player")
	local level = UnitLevel("player")
	local itemID = core.TransmogGetSlotInfo(itemSlot)
	local itemCategory
	if itemID then
		local _, _, _, _, _, class, subclass = GetItemInfo(itemID) -- it is possible, that equipped items are not cached for a short while
		itemCategory = class and (class .. " " .. subclass) or nil
	end

	-- TODO: Would be better if these also rely on player class? Clothies with wands, people who cant wear daggers etc. ...
	if itemSlot == "MainHandSlot" then
		return itemCategory or core.CATEGORIES.WEAPON_DAGGERS
	elseif itemSlot == "SecondaryHandSlot" then
		return itemCategory or core.CATEGORIES.ARMOR_SHIELDS
	elseif itemSlot == "ShieldHandWeaponSlot" then
		return itemCategory or core.CATEGORIES.WEAPON_DAGGERS
	elseif itemSlot == "OffHandSlot" then
		return itemCategory or core.CATEGORIES.ARMOR_SHIELDS
	elseif itemSlot == "RangedSlot" then
		return itemCategory or core.CATEGORIES.WEAPON_BOWS
	elseif itemSlot == "BackSlot" then
		return core.CATEGORIES.ARMOR_CLOTH
	elseif itemSlot == "ShirtSlot" or itemSlot == "TabardSlot" then
		return core.CATEGORIES.ARMOR_MISC
	else
		if class == "PALADIN" or class == "WARRIOR" or class == "DEATHKNIGHT" then
			if level < 40 then
				return core.CATEGORIES.ARMOR_MAIL
			else
				return core.CATEGORIES.ARMOR_PLATE
			end
		elseif class == "SHAMAN" or class == "HUNTER" then
			if level < 40 then
				return core.CATEGORIES.ARMOR_LEATHER
			else
				return core.CATEGORIES.ARMOR_MAIL
			end
		elseif class == "DRUID" or class == "ROGUE" then
			return core.CATEGORIES.ARMOR_LEATHER
		else
			return core.CATEGORIES.ARMOR_CLOTH
		end
	end
end

core.HasRangedSlot = function()
	local _, class = UnitClass("player")	
	return not (class == "PALADIN" or class == "DEATHKNIGHT" or class == "SHAMAN" or class == "DRUID")
end

core.HasShieldHandWeaponSlot = function()
	local _, class = UnitClass("player")	
	return class == "WARRIOR" or class == "DEATHKNIGHT" or class == "SHAMAN" or class == "ROGUE" or class == "HUNTER"
end

local ToApiSet = function(set, withEnchants)
	local apiSet = {}
	for slot, itemID in pairs(set) do
		local isEnchantSlot = core.IsEnchantSlot(slot)
		if withEnchants or not isEnchantSlot then
			-- assert(core.Contains(itemSlots, slot) or (withEnchants and core.Contains(core.enchantSlots, slot))) -- Technically only needs the transmoglocation check?
			assert(type(itemID) == "number" or (type(itemID) == "boolean" and not itemID)) --  TODO: remove the boolean stuff? artifact from when hidden was encoded as "false" ...?
			
			if isEnchantSlot then
				-- TODO: do we only allow enchants when there is a weapon in the set? or should we allow setting enchantSlot for e.g. skins without a weapon in the set?
			end
			
			--local slotID, _ = GetInventorySlotInfo(slot)
			local transmogLocation = core.ToTransmogLocation(slot)
			if (transmogLocation == nil) then print("Could not find transmogLocation for", slot) end
			assert(transmogLocation ~= nil, "Could not find transmogLocation for " .. (slot or "nil"))
			apiSet[transmogLocation] = (itemID == core.HIDDEN_ID and API.HideItem) or (itemID == core.UNMOG_ID and API.NoTransmog) or itemID
		end
	end
	-- am("From set:", set, withEnchants)
	-- am("To apiSet:", apiSet)
	return apiSet
end
core.ToApiSet = ToApiSet

core.FromApiSet = function(apiSet)
	local set = {}
	for slotID, itemID in pairs(apiSet) do
		if itemID ~= API.NoTransmog then
			local itemSlot = transmogLocationToItemSlot[slotID]
			set[itemSlot] = (itemID == API.HideItem and core.HIDDEN_ID) or itemID
		end
	end
	return set
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
	UpdateListeners("balance") -- balanceFrame
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
	if not c or not c.visibility or not visibilities[c.visibility] then core.am("ERROR: Unknown visibility in SetConfig:", c); return end

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
	UpdateListeners("skinCosts") -- no one atm. could technically close the buy skin popup here
end

core.GetSkinCosts = function()
	return skinCosts
end

SetSlotAndCategory = function(slot, cat, updateList)
	assert((slot == nil and cat == nil) or core.Contains(core.allSlots, slot))
	-- assert((slot == nil and cat == nil) or core.Contains(core.slotCategories[slot], cat))
	
	if not updateList and slot == selectedSlot and cat == selectedCategory then return end
	
	-- If we chose a new slot, request available transmogrifications
	-- This also clears the available list until the server answers and also triggers an update to the display list each time, if slot == selected slot
	-- So calling this before setting slot avoids an unnecessary display list update
	if slot and selectedSlot ~= slot then
		core.RequestUnlocksSlot(slot)
	end
	
	selectedSlot = slot
	selectedCategory = cat

	core.itemCollectionFrame:SetSlotAndCategory(slot, cat, updateList)

	CloseDropDownMenus()
	
	UpdateListeners("selectedSlot")
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
		assert(core.Contains(itemSlots, slot) or core.Contains(core.enchantSlots, slot))
		assert(type(id) == "number" or (type(id) == "boolean" and not id))
	end

	for _, slot in pairs(core.enchantSlots) do
		SetCurrentChangesSlot(slot, set[slot], true)
	end

	for _, slot in pairs(itemSlots) do
		SetCurrentChangesSlot(slot, set[slot], true)
	end
	
	UpdateListeners("currentChanges")
end
core.SetCurrentChanges = SetCurrentChanges

core.GetCurrentChanges = function()
	if not TransmoggyDB.currentChanges then TransmoggyDB.currentChanges = {} end
	return TransmoggyDB.currentChanges
end

SetCurrentChangesSlot = function(slot, id, silent)
	-- core.am("SetCurrentChangesSlot:", slot, "to", id)
	assert(core.Contains(itemSlots, slot) or core.Contains(core.enchantSlots, slot))
	assert(id == nil or type(id) == "number") -- and GetItemData(id) or even GetItemInfo(id) to secure that id is valid item (that is cached?) and maybe even check slot?
	if not TransmoggyDB.currentChanges then TransmoggyDB.currentChanges = {} end

	local isEnchantSlot = core.IsEnchantSlot(slot)
	local correspondingWeaponID = isEnchantSlot and core.TransmogGetSlotInfo(core.GetCorrespondingSlot(slot))

	-- if isEnchantSlot then		
	-- 	print("Can not set enchant transmog.")
	-- 	return -- do not allow setting enchant slots atm
	-- end

	local itemID, visualID, skinVisualID = core.TransmogGetSlotInfo(slot)
	local selectedSkin = core.GetSelectedSkin()

	print(isEnchantSlot, itemID, visualID, id)

	if selectedSkin then
		if id == skinVisualID or (id == core.UNMOG_ID and not skinVisualID) then -- skin and no change to current skinVisual
			id = nil
		end
	elseif itemID or (isEnchantSlot and correspondingWeaponID) then
		if isEnchantSlot then
			itemID = itemID or core.UNMOG_ID
			visualID = visualID or core.UNMOG_ID 	-- TODO: currently no way to know what enchant mog is used
			if itemID == core.UNMOG_ID and id == core.HIDDEN_ID then -- hiding without enchant not possible. allow and show the error or catch like this?
				id = core.UNMOG_ID
			end
		end		
		if id == itemID then -- we chose the original item as transmog -> interpret as unmog
			id = core.UNMOG_ID
		end		
		if id == visualID then -- we chose the currently equipped visual -> no change
			id = nil
		end
	else
		id = nil -- no skin and no equipped item to mog
	end

	if (slot == "ShieldHandWeaponSlot" or slot == "SecondaryHandEnchantSlot") and not core.HasShieldHandWeaponSlot() then
		id = nil -- e.g. we tried copying an outfit with shieldhand weapon into skin on character without dualwield
	end

	if slot == "RangedSlot" and not core.HasRangedSlot() then
		id = nil -- same as before
	end
	
	if TransmoggyDB.currentChanges[slot] == id then return end

	-- Set slot and clear costs (this also disables apply button until we receive costs from server)
	TransmoggyDB.currentChanges[slot] = id -- Or let change only go through, after we get an answer to RequestPriceSlot?
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
	SetCurrentChangesSlot(itemSlot, core.UNMOG_ID)
end

core.UndressSlot = function(itemSlot)
	SetCurrentChangesSlot(itemSlot, core.HIDDEN_ID)
end

core.ClearPendingSlot = function(itemSlot)
	SetCurrentChangesSlot(itemSlot, nil)
end

core.SetPending = function(itemSlot, itemID)
	SetCurrentChangesSlot(itemSlot, itemID)
end

--  TODO: Decide whether we want to display (only the valid?) cost sum, even if there are currently invalid pendings
--  Would have to add another another var for all valid, currently using cost nil check for that
SetSlotCostsAndReason = function(itemSlot, copper, shards, valid, reason)
	slotCostsCopper[itemSlot] = copper
	slotCostsShards[itemSlot] = shards
	slotValid[itemSlot] = valid
	slotReason[itemSlot] = reason

	local copper, shards = 0, 0
	local valid, hasPendings = true, false
	for _, itemSlot in pairs(core.allSlots) do
		if valid then
			local _, _, _, pendingID, s, c, canTransmogrify = core.TransmogGetSlotInfo(itemSlot)
			if pendingID then
				hasPendings = true
				if (not s or not c or not canTransmogrify) then
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

	costs.copper = copper
	costs.points = shards
	UpdateListeners("costs") -- moneyframe, applybutton, 
end

-- SetCosts = function(copper, points) -- TODO: Keep allowing setting costs even tho its basically just a view on slot costs now, which we update when changing slot costs?
-- 	assert(type(copper) == "number" and type(points) == "number"
-- 		or copper == nil and points == nil)
	
-- 	costs.copper = copper
-- 	costs.points = points
-- 	UpdateListeners("costs") --moneyframe, applybutton, 
-- end

core.GetCosts = function()
	return costs
end

SetAvailableMogs = function(slot, items)
	--am("Updated available mogs for:", slot)
	core.availableMogs[slot] = core.availableMogs[slot] or {}
	wipe(core.availableMogs[slot])

	for _, itemID in pairs(items) do
		itemID = (itemID == core.API.HideItem and core.HIDDEN_ID) or (itemID == core.API.NoTransmog and core.UNMOG_ID) or itemID
		core.availableMogs[slot][itemID] = true
	end

	if core.transmogFrame:IsShown() then
		if slot == selectedSlot then
			-- TODO: This the way we want to trigger rebuilt of list and stuff?
			--(selectedSlot, selectedCategory, true) 
			core.itemCollectionFrame:UpdateDisplayList()
		end
	end
	
	UpdateListeners("availableMogs") --TODO update build list?
end

core.IsAvailableSourceItem = function(item, slot)
	return core.availableMogs[slot] and core.availableMogs[slot][item]
end

-- Why do we not translate skins to our own set format? :)
-- Only TransmogGetSlotInfo needs to know this format, but we still have to translate the ids?
core.SetSkin = function(skin, silent)
	local id = skin.id
	
	skins[id] = {}
	skins[id].name = skin.name
	skins[id].slots = {}

	for slotID, itemID in pairs(skin.slots) do
		-- slotID = tonumber(slotID)
		-- local itemSlot = core.TransmogLocationToItemSlot(slotID)
		skins[id].slots[slotID] = (itemID == API.NoTransmog and nil) or (itemID == API.HideItem and core.HIDDEN_ID) or itemID
	end

	if skin.id == core.GetSelectedSkin() and not skin.name or skin.name == "" then -- If we reset our currently selected skin, flip back to inventory
		core.SetSelectedSkin()
	elseif not silent then 
		UpdateListeners("selectedSkin")
	end
end

-- SkinData now has format: { {id: SkinID, name: String, slots: SlotMap} }
SetSkinData = function(skinData)
	core.am("called set skin data!")

	-- for k, skin in pairs(skinData) do
	-- 	core.am("setdata:", skin)
	-- end
	for _, skin in pairs(skinData) do
		--assert blabla

		core.SetSkin(skin, true)

		-- core.am("setdata:", skin)
		-- core.am("copied data:", skins[id])
	end

	local selectedName = core.GetSelectedSkinName()
	if not selectedName or selectedName == "" then -- If we reset our currently selected skin, flip back to inventory
		core.SetSelectedSkin()
	else	
		--core.SetSelectedSkin(core.GetSelectedSkin()) -- TODO: this needs fixing
		UpdateListeners("selectedSkin") -- TODO: is this fine?
	end
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
	if type(skinID) ~= "number" and skinID ~= nil then print("Error in SetActiveSkin: skinID has wrong type") end
	activeSkin = skinID
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

-- This is used to modify behaviour of shared frames between the wardrobe and transmog frame
-- (Could've probably just checked which frame is shown for that)
-- It does not really say whether we are at the npc :^)
core.SetIsAtTransmogrifier = function(atNPC)
	atTransmogrifier = atNPC
end

core.IsAtTransmogrifier = function()
	return atTransmogrifier
end

local OnVisualUnlocked = function(payload)
	core.am(payload)
	local enchantSpellID, itemID, available = payload.spellId, payload.itemId, payload.available and 1 or 0

	if itemID then
		core.SetUnlocked(itemID)
	end

	if enchantSpellID then
		core.SetEnchantUnlocked(enchantSpellID, 1)
	end

	if core.db and core.db.profile.General.playSpecialSounds then
		PlaySound(core.sounds.unlockVisual, "SFX")
	end
	print("OnVisualUnlock!", itemID, GetItemInfo(itemID or 0), enchantSpellID, GetSpellInfo(enchantSpellID or 0))	
	UpdateListeners("unlocks")
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
	core.UpdateSkinDropdown()
end
rAPI:registerEvent("transmog/skin/changed", OnSkinChanged)

local OnBalanceChanged = function(payload)
	print("Balance Update!")
	
	if core.db and core.db.profile.General.playSpecialSounds then
		local balance = core.GetBalance()
		if payload and payload.shards and balance and balance.shards and payload.shards > balance.shards then
			PlaySound(core.sounds.gainBalance, "SFX")
		end
	end

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

-- Only needed once on login. Otherwise we listen to OnSkinChanged
core.RequestActiveSkin = function()
	API.GetActiveSkin():next(function(skinID)
		core.SetActiveSkin(skinID)
	end):catch(function(err)
		print("RequestActiveSkin: An error occured:", err.message)
	end)
end

core.RequestActivateSkin = function(skinID)
	API.ActivateSkin(skinID):next(function(answer)
		print("Active skin activate!") -- Changes trigered by OnSkinUpdate
	end):catch(function(err)
		print("RequestSetActiveSkin: An error occured:", err.message)
	end)
end

local requestCounterS = 0
core.RequestSkins = function(id)
	API.GetSkins():next(function(skinData)
		-- core.am("received skinData:", skinData)
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
		print("RenameSkinSuccess!") -- Changes triggered by OnSkinUpdate
	end):catch(function(err)
		print("RequestSkinRename: An error occured:", err.message)
	end)
end

core.RequestSkinReset = function(id)	
	API.ResetSkin(id):next(function(answer)
		print("ResetSkinSuccess!") -- Changes triggered by OnSkinUpdate
	end):catch(function(err)
		print("RequestSkinReset: An error occured:", err.message)
	end)
end

core.RequestTransferPriceAndOpenPopup = function(id)
	API.GetTransferVisualsToSkinPrice(id):next(function(answer)
		print("SkinPriceGet!")
		core.ShowVisualsToSkinPopup(id, answer) -- TODO: Add check that nothing has changed in the meantime, time limit etc?
	end):catch(function(err)
		print("RequestTransferVisualsToSkin: An error occured:", err.message)
	end)
end

core.RequestTransferVisualsToSkin = function(id)	
	API.TransferVisualsToSkin(id):next(function(answer)
		print("SkinAbsorbSuccess!") -- Changes triggered by OnSkinUpdate. Maybe play sound?
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
	requestCounterBuySkin = requestCounterBuySkin + 1
	local requestID = requestCounterBuySkin
	API.BuySkin():next(function(answer)
		print("skin get!")
		core.RequestSkinCosts()
	end):catch(function(err)
		print("RequestSkinCosts: An error occured:", err.message)
	end)
end

local requestCounterUnlockVisuals = 0
core.RequestUnlockVisuals = function(items) -- use enchant scroll from interface to unlock its visual
	requestCounterUnlockVisuals = requestCounterUnlockVisuals + 1
	local requestID = requestCounterUnlockVisual
	API.UnlockVisualAll(items):next(function(answer)
		core.am(answer)
	end):catch(function(err)
		print("RequestUnlockVisuals: An error occured:", err.message)
		UIErrorsFrame:AddMessage(err.message, 1.0, 0.1, 0.1, 1.0)
	end)
end


local requestCounterUS = {}
core.RequestUnlocksSlot = function(slot)
	local transmogLocation = core.ToTransmogLocation(slot)
	local skin = core.GetSelectedSkin()
	local itemID = core.IsEnchantSlot(slot) and core.TransmogGetSlotInfo(core.GetCorrespondingSlot(slot)) or core.TransmogGetSlotInfo(slot)
	
	SetAvailableMogs(slot, {})

	if not skin and not itemID then return end

	local f = skin and API.GetUnlockedVisualsForSlot or API.GetUnlockedVisualsForItem
	local p = skin and {transmogLocation} or {itemID, transmogLocation}

	requestCounterUS[transmogLocation] = (requestCounterUS[transmogLocation] or 0) + 1
	local requestID = requestCounterUS[transmogLocation]
	f(unpack(p)):next(function(answer)
		if requestID == requestCounterUS[transmogLocation] then
			-- Imo we still want to show our current item/mog in the list of available transmogs to "deselect mog/pending"?
			-- A bit confusing that items with the same displayID as the equipped item also get hidden, why even disallow this?
			-- TODO: Instead of adding itemID to this list, might wanna just add it at the start of the list together with 'hidden slot item'
			core.am(answer)
			local items = core.IsEnchantSlot(slot) and answer.spellIds or answer.itemIds
			if itemID and not skin then
				table.insert(items, itemID)
			end
			SetAvailableMogs(slot, items)
		end
	end):catch(function(err)
		print("RequestUnlocksSlot: An error occured:", err.message)
	end)
end

-- Should only be called once on login, so we do not need to trigger updates to interface
local requestCounterUA = 0
core.RequestUnlocksAll = function(slot)
	requestCounterUA = requestCounterUA + 1
	local requestID = requestCounterUA
	API.GetUnlockedVisuals(true):next(function(answer)
		if requestID == requestCounterUA then
			core.requestUnlocksAllFailed = nil
			if requestID == requestCounterUA then
				core.SetUnlocks(answer.itemIds or {})
				core.SetEnchantUnlocks(answer.spellIds or {})
				-- core.MyWaitFunction(0.1, core.SetUnlocks, items) -- used delay to be able to see errors, can remove this now
			end
		end
	end):catch(function(err)		
		if requestID == requestCounterUA then
			core.requestUnlocksAllFailed = 1
			core.SetUnlocks({})
			core.SetEnchantUnlocks({})
			print("RequestUnlocksAll: An error occured:", err.message)
		end
	end)
end

local requestCounterACC = 0
core.RequestApplyCurrentChanges = function()
	requestCounterACC = requestCounterACC + 1
	local requestID = requestCounterACC
	API.ApplyAll(ToApiSet(TransmoggyDB.currentChanges, true), core.GetSelectedSkin()):next(function(answer)
		if requestID == requestCounterACC then
			PlaySound(core.sounds.applySuccess)
			core.PlayApplyAnimations()
			SetCurrentChanges(core.GetCurrentChanges()) -- or just {}, since apply should have been successfull?
		end
	end):catch(function(err)
		print("RequestApplyCurrentChanges: An error occured:", err.message)		
		SetCurrentChanges(core.GetCurrentChanges()) -- unknown number of slots might have successfully applied. this clears pendings where changes went through
		UIErrorsFrame:AddMessage(err.message, 1.0, 0.1, 0.1, 1.0)
	end)
end	

local requestCounterB = 0
core.RequestBalance = function()
	requestCounterB = requestCounterB + 1
	local requestID = requestCounterB
	API.GetBalance():next(function(balance)
		if requestID == requestCounterB then
			-- print("Your balance is: " .. balance.shards .. " moggies.")
			SetBalance(balance)
		end
	end):catch(function(err)
		SetBalance({})
		print("RequestBalance: An error occured:", err.message)
	end)
end

-- Not used. Instead of tracking the total price we keep track of the costs+validity of each slot
-- local requestCounterPOA = 0
-- core.RequestPriceTotal = function()
-- 	requestCounterPOA = requestCounterPOA + 1
-- 	SetCosts() -- Setting costs to nil disables apply button and cost display while we are waiting for an answer

-- 	if core.Length(TransmoggyDB.currentChanges) == 0 then return end -- No changes, so nothing to apply and no costs to display

-- 	local requestID = requestCounterPOA
-- 	API.GetPriceAll(ToApiSet(TransmoggyDB.currentChanges), core.GetSelectedSkin()):next(function(price)
-- 		if requestID == requestCounterPOA then
-- 			SetCosts(price.copper, price.shards)
-- 		end
-- 	end):catch(function(err)
-- 		print("RequestPriceTotal: An error occured:", err.message)
-- 		if requestID == requestCounterPOA then
-- 			SetCosts()
-- 		end
-- 	end)
-- end

-- local requestCounterSlotPrices = {}
-- core.RequestPriceSlot = function(itemSlot)
-- 	requestCounterSlotPrices[itemSlot] = (requestCounterSlotPrices[itemSlot] or 0) + 1
-- 	--SetSlotCostsAndReason(itemSlot) -- Resetting data in SetCurrentChanges(Slot) atm

-- 	local itemID, _, _, pendingID = core.TransmogGetSlotInfo(itemSlot)
-- 	local selectedSkin = core.GetSelectedSkin()
-- 	local location = core.ToTransmogLocation(itemSlot)
	
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

-- Combines price + validity check
local requestCounterSlotPrices = {}
core.RequestPriceSlot = function(itemSlot)
	requestCounterSlotPrices[itemSlot] = (requestCounterSlotPrices[itemSlot] or 0) + 1
	SetSlotCostsAndReason(itemSlot) -- Resetting data in SetCurrentChanges(Slot) atm

	local itemID, _, _, pendingID = core.TransmogGetSlotInfo(itemSlot)
	local selectedSkin = core.GetSelectedSkin()
	local location = core.ToTransmogLocation(itemSlot)
	if core.IsEnchantSlot(itemSlot) then
		itemID = core.TransmogGetSlotInfo(core.GetCorrespondingSlot(itemSlot))
	end
	
	if not pendingID then return end -- No pending change, so no price to request

	pendingID = (pendingID == core.HIDDEN_ID and API.HideItem) or (pendingID == core.UNMOG_ID and API.NoTransmog) or pendingID -- translate to API ID

	if not (selectedSkin or itemID) then print("ERROR in RequestPriceSlot, requesting price for empty slot") end

	local requestID = requestCounterSlotPrices[itemSlot]
	API.GetPriceAndCheck(pendingID, not selectedSkin and itemID or nil, location, selectedSkin):next(function(result)
		if requestID == requestCounterSlotPrices[itemSlot] then
			-- core.am(result)
			SetSlotCostsAndReason(itemSlot, result.copper, result.shards, result.valid, result.message)
		end
	end):catch(function(err)
		if requestID == requestCounterSlotPrices[itemSlot] then
			print("RequestPriceSlot " .. (itemSlot or "nil") .. ": An error occured:", err.message)
			SetSlotCostsAndReason(itemSlot, nil, nil, false, err.message)
		end
	end)
end

-- Unused. We now always allow setting a slot and then ask the server for a check + price.
-- After the server answer, this info can be retrieved with TransmogGetSlotInfo
core.CanReceiveTransmog = function(mogTarget, mogSource, slot)
	local canMog = false
	--local targetSubtype = select(7,GetItemInfo(mogTarget))
	--local sourceSubtype = select(7,GetItemInfo(mogSource))
	--if targetSubtype == sourceSubtype then canMog = true end
	-- hidden id is part of availables list, if it is valid for the slot
	if core.availableMogs[slot] and core.availableMogs[slot][mogSource] or mogSource == core.UNMOG_ID then
		canMog = true
	end
	return canMog
end

-- local function canBeEnchanted(itemSlot)
-- 	local itemID = TransmoggyDB.currentChanges[itemSlot]
-- 	--local itemID = GetInventoryItemID("player", GetInventorySlotInfo(itemSlot))
-- 	if not itemID then return false end
-- 	local itemSubType = select(7, GetItemInfo(itemID))
-- 	--core.am(itemSubType)
-- 	return core.Contains({core.ITEM_SUB_CLASSES.DAGGERS, core.ITEM_SUB_CLASSES.FIST_WEAPONS, core.ITEM_SUB_CLASSES["1H_AXES"], core.ITEM_SUB_CLASSES["1H_MACES"], core.ITEM_SUB_CLASSES["1H_SWORDS"],
-- 						core.ITEM_SUB_CLASSES.POLEARMS, core.ITEM_SUB_CLASSES.STAVES, core.ITEM_SUB_CLASSES["2H_AXES"], core.ITEM_SUB_CLASSES["2H_MACES"], core.ITEM_SUB_CLASSES["2H_SWORDS"]}, itemSubType)	
-- end

core.HasTitanGrip = function()
	return select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1
end

core.CanDualWield = function()
	return IsSpellKnown(674)
end

local canBeTitanGripped = {[core.ITEM_SUB_CLASSES["2H_AXES"]] = true, [core.ITEM_SUB_CLASSES["2H_MACES"]] = true, [core.ITEM_SUB_CLASSES["2H_SWORDS"]] = true,
						   [core.CATEGORIES.WEAPON_2H_AXES] = true, [core.CATEGORIES.WEAPON_2H_MACES] = true, [core.CATEGORIES.WEAPON_2H_SWORDS] = true,}
core.CanBeTitanGripped = function(itemSubClass)
	return canBeTitanGripped[itemSubClass]
end

core.EquipOffhandNext = function(model)
	if not core.DUMMY_MODEL then
		core.DUMMY_MODEL = CreateFrame("DressUpModel", nil, UIParent)		
		core.DUMMY_MODEL:SetUnit("player")
	end

	core.DUMMY_MODEL:Show()
	core.DUMMY_MODEL:TryOn(core.DUMMY_WEAPONS.POLEARM) -- reset with polearm
	core.DUMMY_MODEL:TryOn(core.DUMMY_WEAPONS.INVISIBLE_1H) -- equip 1h one time so next one goes into offhand
	core.DUMMY_MODEL:Hide()
end

-- Displays weapons mainHand and offHand on DressUpModel mod as well as possible (i.e. can't display dualwielding weapons, if the player can't dualwield (and wasn't logged into a dualwielding char earlier in the session))
-- the "logged in on dualwielder before" thing is just another DressUpModel weirdness, since it would be confusing and we can't track it anyway, we don't try to use that feature
-- requires an undress of the weapons before usage, now that we use that EquipToOffhand trick sometimes instead of always using an "invisible" weapon in MH
local currentID = {}
core.ShowMeleeWeapons = function(mod, mainHand, offHand, callID)
	if not (mainHand or offHand) or not mod then return end	
	if callID and currentID[mod] and callID < currentID[mod] then return end 	-- OnItemInfo called ShowMeleeWeapons, but another ShowMeleeWeapons call was made for this model in the meantime
	currentID[mod] = currentID[mod] and (currentID[mod] + 1) or 0				-- increase counter for this model

	local mainHandID = core.GetItemIDFromLink(mainHand)
	local offHandID = core.GetItemIDFromLink(offHand)

	if not mainHandID or mainHandID == core.HIDDEN_ID then mainHand = nil end
	if not offHandID or offHandID == core.HIDDEN_ID then offHand = nil end
	
	local _, _, _, _, _, _, mhSubType, _, mhInvType = GetItemInfo(mainHand or 0)
	local _, _, _, _, _, _, ohSubType, _, ohInvType = GetItemInfo(offHand or 0)
	if mainHand and not mhSubType or offHand and not ohSubType then
		-- TODO: This approach should be fine in regards to not overwriting other ShowMeleeWeapon calls, but what about e.g. Undress calls after this?
		if mainHand then core.QueryItem(mainHandID) end
		if offHand then core.QueryItem(offHandID) end
		local missingID = (mainHand and not mhSubType) and mainHandID or offHandID
		core.FunctionOnItemInfo(missingID, core.ShowMeleeWeapons, mod, mainHand, offHand, currentID[mod]) -- Retry after item info got retrieved for a missing item
	end
	
	local TryOn = mod.TryOnOld or mod.TryOn -- Incase our model has modified TryOn. Hacky as fuck, probably better to take the correct TryOn method as optional parameter?
	local hasTitanGrip = core.HasTitanGrip()
	local canDualWield = core.CanDualWield()

	-- print("equipMWeps", mainHand, offHand)

	if mainHand then
		TryOn(mod, core.DUMMY_WEAPONS.POLEARM)
		TryOn(mod, mainHand)
		if offHand then
			if ohInvType == "INVTYPE_SHIELD" or ohInvType == "INVTYPE_HOLDABLE" or ohInvType == "INVTYPE_WEAPONOFFHAND"
				or canDualWield and (ohInvType ~= "INVTYPE_2HWEAPON" or hasTitanGrip and canBeTitanGripped[ohSubType]) then
				core.EquipOffhandNext(mod)
				TryOn(mod, offHand)
			else
				--am("MyAdddon: Cannot preview "..select(1, GetItemInfo(offHand)).." in offhand with "..select(1, GetItemInfo(mainHand)).." in mainhand.")
				return true
			end
		end
	else
		if (ohInvType == "INVTYPE_SHIELD" or ohInvType == "INVTYPE_HOLDABLE" or ohInvType == "INVTYPE_WEAPONOFFHAND") then
			TryOn(mod, offHand)
		elseif canDualWield and (ohInvType == "INVTYPE_WEAPON" or (hasTitanGrip and canBeTitanGripped[ohSubType])) then
			if ohInvType == "INVTYPE_WEAPON" then -- trick of toggling hand on other model does not work with 1H, when nothing is equipped in mh .. 
				TryOn(mod, core.DUMMY_WEAPONS.POLEARM)
				TryOn(mod, core.DUMMY_WEAPONS.INVISIBLE_1H)
			else
				core.EquipOffhandNext(mod)
			end
			--core.EquipOffhandNext(mod)
			TryOn(mod, offHand)
		else
			--core.am("MyAdddon: Cannot preview "..select(1, GetItemInfo(offHand)).." in offhand.")
			return true
		end
	end
end

local CheckForInvalidSkinName = function(name)
	local denyMessage
	if string.len(name) < 1 then
		denyMessage = core.SKIN_NAME_TOO_SHORT
	elseif string.find(name, "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz _.,'1234567890]") then
		denyMessage = core.SKIN_NAME_INVALID_CHARACTERS
	end
	
	return denyMessage
end

core.AttemptSkinRename = function(skinID, newName)
	local denyMessage = CheckForInvalidSkinName(newName)
	if denyMessage then
		core.am(denyMessage)		
		UIErrorsFrame:AddMessage(denyMessage, 1.0, 0.1, 0.1, 1.0)
		return
	end

	core.RequestSkinRename(skinID, newName)
end

core.OnEquippedItemChange = function(itemSlot, itemEquipped)	
	local selectedSkin = core.GetSelectedSkin()
	local selectedSlot = core.GetSelectedSlot()
	local correspondingEnchantSlot = core.GetCorrespondingSlot(itemSlot)
	
	if not selectedSkin then
		SetCurrentChangesSlot(itemSlot, nil)
		if correspondingEnchantSlot then
			SetCurrentChangesSlot(correspondingEnchantSlot, nil)
		end
		if selectedSlot == itemSlot or selectedSlot == correspondingEnchantSlot then
			SetSlotAndCategory(nil, nil)
		end
	end

	-- Just clear slot and request again when selecting a slot instead
	-- if not core.transmogFrame:IsShown() then
	-- 	if not itemEquipped then
	-- 		core.availableMogs[itemSlot] = {}
	-- 	else
	-- 		-- core.availableMogsUpdateNeeded[itemSlot] = true -- Update when we open Transmogwindow. (not used atm. instead we always update when selecting a slot)
	-- 	end
	-- else
	-- 	core.RequestUnlocksSlot(itemSlot) -- does nothing if slot is nil
	-- end

	UpdateListeners("inventory")
end


core.IsOffHandItemType = function(itemType)
	return itemType == "INVTYPE_SHIELD" or itemType == "INVTYPE_HOLDABLE"
end

core.OpenTransmogWindow = function(fromGossip)
	core.wardrobeFrame:Hide()	
	core.SetIsAtTransmogrifier(true)
	core.SetShown(core.transmogFrame.minimizeButton, fromGossip)
	core.transmogFrame:Show()
end

core.gossipOpenTransmogButton = core.CreateMeATextButton(GossipFrame, 112, 24, "Transmogrify")
core.gossipOpenTransmogButton:SetScript("OnClick", function()
	-- hide frame without calling CloseGossip()
	local onHideScript = GossipFrame:GetScript("OnHide")
	GossipFrame:SetScript("OnHide", nil)
	HideUIPanel(GossipFrame)
	GossipFrame:SetScript("OnHide", onHideScript)

	core.OpenTransmogWindow(true)
end)
core.gossipOpenTransmogButton:SetPoint("TOP", GossipNpcNameFrame, "BOTTOM", 0, -10)

------------------------------------------------------
-- loading and event stuff
------------------------------------------------------  

local a = CreateFrame("Frame")
a:RegisterEvent("PLAYER_ENTERING_WORLD")
a:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
a:RegisterEvent("GOSSIP_SHOW")
a:RegisterEvent("GOSSIP_CLOSED")
a:RegisterEvent("PLAYER_MONEY")
-- a:RegisterEvent("PLAYER_REGEN_ENABLED")

local lastClosed = 0
a:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		SetCurrentChanges({})
		
		core.InitLDB()

		core:InitializeAce()

		core.GenerateStringData()

		core.RequestSkins()
		core.RequestActiveSkin()
		core.RequestUnlocksAll()
		core.RequestBalance()
		core.RequestSkinCosts()
		core.RequestGetConfig()

		core.PreHook_ModifiedItemClick()
		-- BackgroundItemInfoWorker.Start()
		
		core.FixTooltip(core.extraItemTooltip)
		
		if AtlasLootTooltip then
			core.HookItemTooltip(AtlasLootTooltip)
		end

		-- Remove unneeded stuff

		-- ItemCollection
		core.CreateSlotButtonFrame = nil
		core.CreateEnchantSlotButton = nil
		core.CreateItemTypeDDM = nil
		core.CreateOptionsDDM = nil
		-- core.CreateMannequinFrame = nil -- Still need this, as Itemcollection can dynamically create more models when the row/col counts are increased. Might wanna remove this functionality
		core.CreateWardrobeModelFrame = nil
		-- TransmogFrame
		core.CreatePreviewModel = nil
		core.CreateSlotButton = nil
		core.CreateItemSlotOptionsFrame = nil
		core.CreateSkinDropDown = nil
		core.CreateUnlockEnchantsButton = nil
		-- Outfit/DressUpFrame
		core.CreateSlotListButton = nil
		core.CreateOutfitFrame = nil
		core.CreateOutfitDDM = nil
		-- UnlocksOverviewFrame
		core.CreateUnlocksOverviewFrame = nil
		core.CreateUnlockedBar = nil

	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
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

	elseif event == "GOSSIP_SHOW" then -- TODO: Alternatively could hook gossipframe stuff and check the button names or smth to see if its the tmog npc?
		if GetTime() - lastClosed < 0.2 then return end -- ignore refresh when clicking around the menu
		local npcID = core.GetNPCID(UnitGUID("target"))
		local isTransmogNPC = npcID == core.TMOG_NPC_ID

		core.SetShown(core.gossipOpenTransmogButton, isTransmogNPC)

		if isTransmogNPC and core.db.profile.General.autoOpen then
			core.gossipOpenTransmogButton:Click()
		end

	elseif event == "GOSSIP_CLOSED" then
		lastClosed = GetTime()
		--GossipFrame:SetWidth(gossipFrameWidthBackup)
		core.transmogFrame:Hide()
		-- GossipFrame:SetAttribute("UIPanelLayout-" .. "area", "left")
		-- UpdateUIPanelPositions(GossipFrame)
		-- UIPanelWindows["GossipFrame"].width = core.defaultGossipFrameWidth

	elseif event == "PLAYER_MONEY" then
		UpdateListeners("money")
	
	-- Not needed anymore. We reset TAB bind with a SecureHandlerStateTemplate on getting infight instead. We could restore mannequin tabbing here ...
	-- elseif event == "PLAYER_REGEN_ENABLED" then
	-- 	for _, mannequin in pairs(core.itemCollectionFrame.mannequins) do
	-- 		ClearOverrideBindings(mannequin)
	-- 	end
	end
end)


-- can we make transmog/gossip frame exclusive to other uipanels without closing gossip itself? haven't found a satisfying solution so far
-- CharacterFrame:HookScript("OnShow", function()
-- 	if core.transmogFrame:IsShown() then
-- 		MyWaitFunction(0.01, CloseGossip)
-- 	end
-- end)

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