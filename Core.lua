-- Created by Qhoernchen - qhoernchen@gmail.com

local folder, core = ...

TransmoggyDB = TransmoggyDB or {}

local risingAPI = "RisingAPI"
local rAPI = LibStub(risingAPI, true)
if not rAPI then error(folder .. " missing dependency " .. risingAPI .. "."); return end
rAPI:debug(false)

if not rAPI.Transmog then error(folder .. " missing RisingAPI transmog module."); return end
core.API = rAPI.Transmog

-- Attempt at options implementation --
core.title = "Transmoggy"
core.titleFull = "Transmoggy V.1.0"
core.addonDir = "Interface\\AddOns\\"..folder.."\\"

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
	--LibStub('AceConfigDialog-3.0'):AddToBlizOptions("HPE-CCTracker", 'CCTracker', "self.ccOptions")
	LibStub('AceConfigDialog-3.0'):AddToBlizOptions("Transmoggy-Profiles", 'Profiles', self.title)
	
	--self:RegisterChatCommand("HPE", function () InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) end)
	LibStub('AceConsole-3.0'):RegisterChatCommand("transmoggy", function () InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) end)
end

core.OnProfileChanged = function(self, ...)
	print("OnProfileChanged", ...)
end
---------------------------------------

core.TMOG_NPC_ID = 1010969

--"inv_jewelcrafting_nobletopaz_01"
--"inv_misc_gem_sapphire_03"
--"inv_enchant_shardgleamingsmall"
core.CURRENCY_ICON = "Interface\\Icons\\inv_misc_gem_sapphire_03"
core.CURRENCY_FAKE_ITEMID = -1337

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
	local _, _, _, _, _, _, exoticaSubClass = GetItemInfo(32407)
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


local atTransmogrifier -- used in e.g. itemCollectionFrame to get different behaviour depending on whether we are using it in the TransmogFrame or the WardrobeFrame

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
local GetInventoryVisualID = core.GetInventoryVisualID
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
	MainHand = "MainHandSlot",
	ShieldHandWeapon = "SecondaryHandSlot",
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
	--"SecondaryHandSlot",
	"ShieldHandWeaponSlot",
	"OffHandSlot",
	--"MainHandEnchantSlot", --TODO: erlaubt?
	--"SecondaryHandEnchantSlot",
	"RangedSlot",
}
core.itemSlots = itemSlots

-- extra table for enchants. need different behaviour and are not really supported so far
core.enchantSlots = {
	"MainHandEnchantSlot",
	"OffHandEnchantSlot",
}

core.IsEnchantSlot = function(slot)
	return slot and (slot == core.enchantSlots[0] or slot == core.enchantSlots[1])
end

local isWeaponSlot = {
	"MainHandSlot",
	"SecondaryHandSlot",
	"ShieldHandWeaponSlot",
	"OffHandSlot",
	"RangedSlot",
}
core.IsWeaponSlot = function(slot)
	return slot and isWeaponSlot[slot]
end

-- Although we save the collection status of every item, we still need to ask the server what items are available for a specific slot (for the currently equipped item)
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

for k, v in pairs(itemSlots) do
	if v ~= "MainHandEnchantSlot" and v ~= "SecondaryHandEnchantSlot" then
		core.availableMogsUpdateNeeded[v] = true
	end
end

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
	["MainHandEnchantSlot"] = -16, --TODO: erlaubt?
	["SecondaryHandEnchantSlot"] = -17,
	["RangedSlot"] = 18,
}
core.slotToID = slotToID

-- InventorySlots
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

-- the following inserts are additional slot categories for items that are in the game, but are either quest items (-> not transmogable) or weird bugged test items, that can't be unlocked by normal means
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
	-- INVTYPE_2HWEAPON: armor misc (obtainable quest item),
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

core.DUMMY_WEAPONS = {
	POLEARM = 1485,
	INVISIBLE_1H = 25194, 			-- 45630 should be "Invisible Axe", but it shows as the debug cube model instead. 25194 is smallest knuckle duster
	ENCHANT_PREVIEW_WEAPON = 2000, 	-- 2000: Archeus, basic 2H sword
	TOOLTIP_FIX_ITEM = 32479,		-- needed for tooltip line fix
}

for name, itemID in pairs(core.DUMMY_WEAPONS) do
	core.QueryItem(itemID)
end

core.GetTransmogLocationInfo = function(self, locationName)
	if not core.API.Slot[locationName] then return end

	local locationID = core.API.Slot[locationName]
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
	MainHandEnchantSlot = "EnchantMainHand", --TODO: erlaubt?
	SecondaryHandEnchantSlot = "EnchantOffHand",
	RangedSlot = "Ranged",
}

ToTransmogLocation = function(itemSlot) --, special)
	if type(itemSlot) == "number" then itemSlot = idToSlot[itemSlot] end

	if invSlotToTransmogLocation[itemSlot] then
		return API.Slot[invSlotToTransmogLocation[itemSlot]]
	elseif itemSlot == "SecondaryHandSlot" then
		local equipped = GetInventoryItemID("player", 17)
		if not equipped then return API.Slot.ShieldHandWeapon end -- No offhand equipped, so the field will be nil anyway, but have to return something
		local invtype = select(9, GetItemInfo(equipped)) -- item info should always be cached/available for equipped items
		if invtype == "INVTYPE_SHIELD" or invtype == "INVTYPE_HOLDABLE" then
			return API.Slot.OffHand
		else
			return API.Slot.ShieldHandWeapon
		end
	end
end

local transmogLocationToItemSlot = {}
for itemSlot, transmogLocation in pairs(invSlotToTransmogLocation) do
	transmogLocationToItemSlot[core.API.Slot[transmogLocation]] = itemSlot
end
core.am(transmogLocationToItemSlot)

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
	local pendingID = TransmoggyDB.currentChanges[itemSlot]
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

core.GetDefaultCategory = function(itemSlot)
	local _, class = UnitClass("player")
	local level = UnitLevel("player")
	local itemID = core.TransmogGetSlotInfo(itemSlot)
	local itemCategory
	if itemID then
		local _, _, _, _, _, class, subclass = GetItemInfo(itemID) -- it is possible to force a situation, where equipped items are not cached for a short while
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
core.ToApiSet = ToApiSet

core.FromApiSet = function(apiSet)
	local set = {}
	for slotID, itemID in pairs(apiSet) do
		if itemID ~= 0 then
			local itemSlot = transmogLocationToItemSlot[slotID]
			set[itemSlot] = itemID
		end
	end
	am("apiset:", apiSet)
	am("set:", set)
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

	-- TransmoggyDB.currentChanges = {}
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
	return TransmoggyDB.currentChanges
end

SetCurrentChangesSlot = function(slot, id, silent)
	assert(core.Contains(itemSlots, slot))
	assert(id == nil or type(id) == "number") -- and GetItemData(id) or even GetItemInfo(id) to secure that id is valid item (that is cached?) and maybe even check slot?
	if not TransmoggyDB.currentChanges then TransmoggyDB.currentChanges = {} end
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

	if slot == "ShieldHandWeaponSlot" and not core.HasShieldHandWeaponSlot() then
		id = nil
	end
	
	if TransmoggyDB.currentChanges[slot] == id then return end

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

	for _, itemID in pairs(items) do
		core.availableMogs[slot][itemID] = true
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

	if skin.id == core.GetSelectedSkin() and not skin.name or skin.name == "" then -- If we reset our currently selected skin, flip back to inventory
		core.SetSelectedSkin()
	elseif not silent then 
		UpdateListeners("selectedSkin")
	end
end

-- SetData has now format: { {id: SkinID, name: String, slots: SlotMap} }
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

	-- local playUnlockSoundOption = 1202 -- "Sound\\interface\\PickUp\\PickUpParchment_Paper.wav"
	-- if playUnlockSoundOption then
	-- 	PlaySound(playUnlockSoundOption, "SFX")
	-- end

	UpdateListeners("unlocks")
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
			-- Imo we still want our equipped item in our list of item transmogs to "deselect"? A bit confusing that tems with the same displayID as the equipped item also get hidden :/
			if itemID and not skin then
				table.insert(items, itemID)
			end
			SetAvailableMogs(slot, items)
		else
			--core.am("This answer to RequestUnlocksSlot("..slot..") is outdated, a newer Update was already requested.")
		end
	end):catch(function(err)
		print("RequestUnlocksSlot: An error occured:", err.message)
	end)
end


-- Only calling this once on LogIn, so we do not need to trigger any updates to Interface
local requestCounterUA = {}
core.RequestUnlocksAll = function(slot)
	local requestID = requestCounterUA
	API.GetUnlockedVisuals(true):next(function(items)
		if requestID == requestCounterUA then
			core.MyWaitFunction(0.1, core.SetUnlocks, items) -- just want to see errors bra -.-
		end
	end):catch(function(err)
		core.MyWaitFunction(0.1, core.SetUnlocks, {}) -- -.-
		-- core.SetUnlocks({})
		print("RequestUnlocksAll: An error occured:", err.message)
	end)
end

local requestCounterACC = 0
core.RequestApplyCurrentChanges = function()
	requestCounterACC = requestCounterACC + 1
	local requestID = requestCounterACC
	API.ApplyAll(ToApiSet(TransmoggyDB.currentChanges), core.GetSelectedSkin()):next(function(answer)
		if requestID == requestCounterACC then
			PlaySound(6555) -- 888
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

	if core.Length(TransmoggyDB.currentChanges) == 0 then return end -- No changes, so nothing to apply and no costs to display

	local requestID = requestCounterPOA
	API.GetPriceAll(ToApiSet(TransmoggyDB.currentChanges), core.GetSelectedSkin()):next(function(price)
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

-- Should probably do a full rework of this at some point with all the newfound tricks
-- The EquipToOffhand trick relies on weaponslots being cleared, which breaks the way previewmodel uses this function, so I removed it for now in case where only an offHand is equipped.
-- still has the problem for chars without titangrip that we cant put 2h into offhand there and either have to do another error message or try to fake this with animations or both...

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

	if not mainHandID or mainHandID < 0 then mainHand = nil end
	if not offHandID or offHandID < 0 then offHand = nil end
	
	local _, _, _, _, _, _, mhSubType, _, mhInvType = GetItemInfo(mainHand or 0)
	local _, _, _, _, _, _, ohSubType, _, ohInvType = GetItemInfo(offHand or 0)
	if mainHand and not mhSubType or offHand and not ohSubType then
		-- print(folder, "- Error/wrong usage of ShowMeleeWeapons. Please assure the weapons are cached before using ShowMeleeWeapons!") -- should be fine now
		if mainHand then core.QueryItem(mainHandID) end
		if offHand then core.QueryItem(offHandID) end
		local uncached = (mainHand and not mhSubType) and mainHand or offHand
		core.FunctionOnItemInfo(uncached, core.ShowMeleeWeapons, mod, mainHand, offHand, currentID[mod]) -- Retry after item info got retrieved for a missing item
	end
	
	local TryOn = mod.TryOnOld or mod.TryOn -- Incase our model has modified TryOn. Hacky as fuck, probably better to take the correct TryOn method as optional parameter?
	local hasTitanGrip = core.HasTitanGrip()
	local canDualWield = core.CanDualWield()

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
				return 1
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
			return 1
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
	-- core.defaultGossipFrameWidth = core.defaultGossipFrameWidth or GossipFrame:GetWidth()
	-- UIPanelWindows["GossipFrame"].width = 2000
	-- core.gossipFramedefaultWidth = core.gossipFramedefaultWidth or UIPanelWindows.GossipFrame.width or GossipFrame:GetWidth()
	-- GossipFrame:SetWidth(1020)
	-- GossipFrame:SetAttribute("UIPanelLayout-" .. "width", 1020)
	-- GossipFrame:SetAttribute("UIPanelLayout-" .. "pushable", 0)
	-- GossipFrame:SetAttribute("UIPanelLayout-" .. "area", "center")
	-- UIPanelWindows["GossipFrame"].width = 1020
	-- UIPanelWindows["GossipFrame"].pushable = 0
	-- UIPanelWindows["GossipFrame"].area = "center"
	-- UpdateUIPanelPositions(GossipFrame)
end


core.gossipOpenTransmogButton = core.CreateMeATextButton(GossipFrame, 112, 24, "Transmogrify")
core.gossipOpenTransmogButton:SetScript("OnClick", function()	
	core.HideGossipFrame()
	core.OpenTransmogWindow()
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

a:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		SetCurrentChanges({})
		
		core.InitLDB()

		core:InitializeAce()

		core.GenerateStringData() -- TODO: or do this on AddOn Loaded event?

		core.RequestSkins()
		core.RequestActiveSkin()
		core.RequestUnlocksAll()
		core.RequestBalance()
		core.RequestSkinCosts()
		core.RequestGetConfig()

		core.PreHook_ModifiedItemClick()
		--BackgroundItemInfoWorker.Start()
		
		core.FixTooltip(core.extraItemTooltip)

		-- Clear up Space from the CreateXFrame functions:

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
		-- Outfit/DressUpFrame
		core.CreateSlotListButton = nil
		core.CreateOutfitFrame = nil
		core.CreateOutfitDDM = nil
		-- UnlocksOverviewFrame
		core.CreateUnlocksOverviewFrame = nil
		core.CreateUnlockedBar = nil


		-- core.transmogFrame:HookScript("OnShow", function()
		-- 	local unpushable = { area = "doublewide", pushable = 0, width = 840, xoffset = 80}
		-- 	for attribute, value in pairs(unpushable) do
		-- 		GossipFrame:SetAttribute("UIPanelLayout-" .. attribute, value)
		-- 	end
		-- 	UpdateUIPanelPositions(GossipFrame)
		-- end)

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

	elseif event == "GOSSIP_SHOW" then --TODO: Alternatively could hook gossipframe stuff and check the button names or smth to see if its the tmog npc?
		local npcID = core.GetNPCID(UnitGUID("target"))
		core.SetShown(core.gossipOpenTransmogButton, npcID == core.TMOG_NPC_ID)
		
		local autoOpen = true

		if autoOpen and core.gossipOpenTransmogButton:IsShown() then
			core.gossipOpenTransmogButton:Click()
		end

	elseif event == "GOSSIP_CLOSED" then
		--GossipFrame:SetWidth(gossipFrameWidthBackup)
		GossipFrame:SetAlpha(1)
		core.gossipBlocker:Hide()
		core.transmogFrame:Hide()
		-- GossipFrame:SetAttribute("UIPanelLayout-" .. "area", "left")
		-- UpdateUIPanelPositions(GossipFrame)
		-- UIPanelWindows["GossipFrame"].width = core.defaultGossipFrameWidth

	elseif event == "PLAYER_MONEY" then
		UpdateListeners("money")
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


-- DEBUG




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

