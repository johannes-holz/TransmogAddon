local folder, core = ...

--[[
	Current item data format:

	stringDataPos = "string1string2string3 ...", where stringX is the encoded inventoryType, category and substring index of item with ID X if it exists in the data, otherwise "\0\0\0\0"
	stringData = {inventoryType1 = {category1 = {itemIDs = "...", displayGroups = "...", nextInGroup = "...", unlockedStates = "...", names = "..."}, ...}, ...}
	
	To look up an item, we first look up the place where it is stored by decoding its four bytes in stringDataPos into inventoryType, category and index.
	With this we get e.g. the unlocked state with strbyte(core.stringData[inventoryType][category].unlockedStates, index).

	There are utility functions and iterators to efficiently access item data.

	The data strings are cached in WTF, so that they do not have to be generated on each load. If there are updates/changes to the item data,
	one can update 'Items.lua' (and possibly 'ItemNamesLanX.lua') and increase the stringDataVersion variable to trigger a regeneration of the dataStrings.
	
	Overall item data currently takes up about 600kB with compressed names and 1mB with uncompressed names.
	Enchant and recipe data is small enough, that we can just use tables.
]]

local LibDeflate = LibStub and LibStub:GetLibrary("LibDeflate")

-- Set this boolean to choose if you want to compress the name strings. Saves up to ~400kB but creates a lot of temporary strings during searches
-- Requires reload to take effect and will generate new stringData instead of loading the strings from WTF
local useCompression = LibDeflate and false

local stringDataVersion = 1.0

core.inventoryTypes = { -- These IDs are used in our original item Data
	[1] = "INVTYPE_HEAD",
	[3] = "INVTYPE_SHOULDER",
	[4] = "INVTYPE_BODY",
	[5] = "INVTYPE_CHEST",
	[20] = "INVTYPE_ROBE",
	[6] = "INVTYPE_WAIST",
	[7] = "INVTYPE_LEGS",
	[8] = "INVTYPE_FEET",
	[9] = "INVTYPE_WRIST",
	[10] = "INVTYPE_HAND",
	[16] = "INVTYPE_CLOAK",
	[19] = "INVTYPE_TABARD",
	[13] = "INVTYPE_WEAPON",
	[14] = "INVTYPE_SHIELD",
	[17] = "INVTYPE_2HWEAPON",
	[21] = "INVTYPE_WEAPONMAINHAND",
	[22] = "INVTYPE_WEAPONOFFHAND",
	[23] = "INVTYPE_HOLDABLE",
	[15] = "INVTYPE_RANGED",
	[25] = "INVTYPE_THROWN",
	[26] = "INVTYPE_RANGEDRIGHT",
}

core.inventoryTypeToID = {} -- backwards map
for id, invType in pairs(core.inventoryTypes) do
	core.inventoryTypeToID[invType] = id
end

core.slotItemTypes = {
	["HeadSlot"] = {[1] = true},
	["ShoulderSlot"] = {[3] = true},
	["BackSlot"] = {[16] = true},
	["ChestSlot"] = {[5] = true, [20] = true}, -- chest, robe
	["ShirtSlot"] = {[4] = true},
	["TabardSlot"] = {[19] = true},
	["WristSlot"] = {[9] = true},
	["HandsSlot"] = {[10] = true},
	["WaistSlot"] = {[6] = true},
	["LegsSlot"] = {[7] = true},
	["FeetSlot"] = {[8] = true},
	["MainHandSlot"] = {[13] = true, [21] = true, [17] = true}, --1H, MH, 2H
	["SecondaryHandSlot"] = {[13] = true, [22] = true, [17] = true, [14] = true, [23] = true}, -- 1H, OH, 2H, shields, holdables/tomes
	["ShieldHandWeaponSlot"] = {[13] = true, [22] = true, [17] = true}, -- 1H, OH, 2H
	["OffHandSlot"] = {[14] = true, [23] = true}, -- shields, holdables
	["RangedSlot"] = {[15] = true, [25] = true, [26] = true}, -- bow, thrown, ranged right(gun, wands, crossbow)
}

core.typeToClassSubclass = {
	[core.CATEGORIES.ARMOR_CLOTH] = {4, 1},
	[core.CATEGORIES.ARMOR_LEATHER] = {4, 2},
	[core.CATEGORIES.ARMOR_MAIL] = {4, 3},
	[core.CATEGORIES.ARMOR_PLATE] = {4, 4},
	[core.CATEGORIES.ARMOR_MISC] = {4, 0},
	[core.CATEGORIES.ARMOR_SHIELDS] = {4, 6},
	[core.CATEGORIES.WEAPON_DAGGERS] = {2, 15},
	[core.CATEGORIES.WEAPON_FIST_WEAPONS] = {2, 13},
	[core.CATEGORIES.WEAPON_1H_AXES] = {2, 0},
	[core.CATEGORIES.WEAPON_1H_MACES] = {2, 4},
	[core.CATEGORIES.WEAPON_1H_SWORDS] = {2, 7},
	[core.CATEGORIES.WEAPON_POLEARMS] = {2, 6},
	[core.CATEGORIES.WEAPON_STAVES] = {2, 10},
	[core.CATEGORIES.WEAPON_2H_AXES] = {2, 1},
	[core.CATEGORIES.WEAPON_2H_MACES] = {2, 5},
	[core.CATEGORIES.WEAPON_2H_SWORDS] = {2, 8},
	[core.CATEGORIES.WEAPON_FISHING_POLES] = {2, 20},
	[core.CATEGORIES.WEAPON_MISC] = {2, 14},
	[core.CATEGORIES.MISC_JUNK] = {15, 0},
	[core.CATEGORIES.WEAPON_BOWS] = {2, 2},
	[core.CATEGORIES.WEAPON_CROSSBOWS] = {2, 18},
	[core.CATEGORIES.WEAPON_GUNS] = {2, 3},
	[core.CATEGORIES.WEAPON_THROWN] = {2, 16},
	[core.CATEGORIES.WEAPON_WANDS] = {2, 19},
	[core.CATEGORIES.TRADE_GOODS_MEAT] = {7, 8},
	[core.CATEGORIES.CONSUMABLE_CONSUMABLE] = {0, 0},
	[core.CATEGORIES.QUEST_QUEST] = {12, 0},
	[core.CATEGORIES.WEAPON_1H_EXOTICA] = {2, 11},
	--["Rüstung Buchbände"] = {4, 7},
	--["Rüstung Götzen"] = {4, 8},
	--["Rüstung Totems"] = {4, 9},
	--["Rüstung Siegel"] = {4, 10},
}

-- reversed mapping (class, subclass -> category)
core.classSubclassToType = {}
for category, tab in pairs(core.typeToClassSubclass) do
	local class, subclass = unpack(tab)
	core.classSubclassToType[class] = core.classSubclassToType[class] or {}	
	core.classSubclassToType[class][subclass] = category
end

----------- UPDOOTS (here they are useful for once) -----------
local rshift = bit.rshift
local lshift = bit.lshift
local mod = bit.mod

local strbyte = strbyte
local strchar  = strchar
local strsub = strsub

local GetItemInfo = GetItemInfo

----------- String utility functions to efficiently build large strings (from PIL: https://www.lua.org/pil/11.6.html) -----------
local function newStack()
	return {""}
end
  
local function addString(stack, s)
	table.insert(stack, s)
	for i = table.getn(stack) - 1, 1, -1 do
		if string.len(stack[i]) > string.len(stack[i + 1]) then
			break
		end
		stack[i] = stack[i] .. table.remove(stack)
	end
end

local ReplaceChar = function(s, pos, c)
    return s:sub(1, pos - 1) .. c .. s:sub(pos + 1)
end

----------- Enchants -----------
core.enchants = {}

core.enchantInfo = {
	visualID = {},		-- spellID to visualID (the way the enchant looks and by which we group in the list)
	enchantID = {},		-- spellID to enchantID
	itemToSpellID = {}, -- (scroll/consumable) itemID to spellID
	spellID = {},		-- enchantID to spellID (not always unique and no way? to find out the source spell of an enchant. just choosing one of the spellIDs arbitrarily atm
	itemID = {},		-- spellID to scroll itemID
	class = {},			-- class mask
	available = {},		-- wether the enchant should be available to players (to filter out test items etc.)
	unlocked = {},
}

core.AddEnchant = function(visualID, enchantID, spellID, scrollID, class, available)
	if not (visualID and enchantID) then return false end
	
	if core.enchants[visualID] then
		table.insert(core.enchants[visualID]["spellIDs"], spellID)
	else 
		core.enchants[visualID] = {["spellIDs"] = {spellID}}
	end
	
	core.enchantInfo["visualID"][spellID] = visualID
	core.enchantInfo["enchantID"][spellID] = enchantID
	core.enchantInfo["class"][spellID] = class
	core.enchantInfo["available"][spellID] = available
	core.enchantInfo["itemID"][spellID] = scrollID

	if available or not core.enchantInfo["spellID"][enchantID] then -- Do not overwrite valid enchantID -> spellID mapping with spellID that is unavailable to players (like QAEnchants)
		core.enchantInfo["spellID"][enchantID] = spellID
	end

	if scrollID then
		core.enchantInfo["itemToSpellID"][scrollID] = spellID
	end
end

core.EnchantToSpellID = function(enchantID)
	return enchantID and core.enchantInfo.spellID[enchantID]
end

core.SpellToEnchantID = function(spellID)
	return spellID and core.enchantInfo.enchantID[spellID]
end

-- Any point in imitating the style of GetItemData like this or should we just lookup relevant stuff in enchantInfo?
core.GetEnchantData = function(spellID)
	local unlocked, enchantID, visualID = core.enchantInfo["unlocked"][spellID] or 0, core.enchantInfo["enchantID"][spellID], core.enchantInfo["visualID"][spellID]
	local item, class, available = core.enchantInfo["itemID"][spellID], core.enchantInfo["class"][spellID], core.enchantInfo["available"][spellID]

	return unlocked, enchantID, visualID, item, class, available
end

core.SetEnchantUnlocks = function(spellIDs)
	core.enchantInfo["unlocked"] = {}
	for _, spellID in pairs(spellIDs) do
		core.enchantInfo["unlocked"][spellID] = 1
	end
end

core.SetEnchantUnlocked = function(spellID, unlocked)
	core.enchantInfo["unlocked"][spellID] = unlocked
end

----------- Recipes -----------
core.recipeData = { recipes = {}, spells = {} }
core.LoadRecipe = function(recipeID, spellID, itemID)
	if recipeID then
		core.recipeData.recipes[recipeID] = itemID
	end
	if spellID then
		core.recipeData.spells[spellID] = itemID
	end
end

-- Maps itemID of recipes to the crafted (wearable) item
core.GetRecipeInfo = function(recipe)
	local recipe = core.GetItemIDFromLink(recipe)
	return recipe and core.recipeData.recipes[recipe]
end

-- Maps spellID of a spell to the (wearable) item it produces
core.GetSpellRecipeInfo = function(spell)
	local spell = core.GetSpellIDFromLink(spell)
	return spell and core.recipeData.spells[spell]
end


----------- Items -----------
core.itemInfo = {
	displayID = {},
	class = {},
	subClass = {},
	inventoryType = {},
	-- quality = {},
	-- requiredLevel = {},
	allowableClass = {},
	allowableFaction = {},
	allowableRace = {},
	unlocked = {},
}

-- Overview of non-nil entries for race, class, faction:
-- 			itemCount	uniqueCount
-- race		59			5
-- class	4804		31
-- faction	2254		4??
-- The weird factions are all bugged/hidden set items? Imo fine to ignore them in filters, as they are irrelevant for normal play?
-- -> class and faction get encoded in one byte string, race can be just kept as a normal table

local classFactionMap = {}
local toClassFaction = {}
local cfCount = 0
core.displayIDs = {}
-- AddItem only works during loading proccess. Data gets converted afterwards
core.AddItem = function(displayID, itemID, class, subClass, inventoryType, quality, requiredLevel, allowableRace, allowableClass, allowableFaction)
	if not core.inventoryTypes[inventoryType] then return end -- only want transmogable item types

	if core.displayIDs[displayID] then
		if core.Contains(core.displayIDs[displayID], itemID) then return end
		table.insert(core.displayIDs[displayID], itemID)
	else 
		core.displayIDs[displayID] = { itemID }
	end

	local allowableClassTemp, allowableFactionTemp = allowableClass or 0, allowableFaction or 0
		
	core.itemInfo["displayID"][itemID] = displayID
	core.itemInfo["class"][itemID] = class
	core.itemInfo["subClass"][itemID] = subClass
	core.itemInfo["inventoryType"][itemID] = inventoryType
	-- core.itemInfo["quality"][itemID] = quality
	-- core.itemInfo["requiredLevel"][itemID] = requiredLevel
	core.itemInfo["allowableRace"][itemID] = allowableRace
	core.itemInfo["allowableClass"][itemID] = allowableClassTemp
	core.itemInfo["allowableFaction"][itemID] = allowableFactionTemp

	if not classFactionMap[allowableClassTemp] then classFactionMap[allowableClassTemp] = {} end
	if not classFactionMap[allowableClassTemp][allowableFactionTemp] then
		classFactionMap[allowableClassTemp][allowableFactionTemp] = cfCount
		toClassFaction[cfCount] = { allowableClass, allowableFaction }
		cfCount = cfCount + 1
	end
end

-- Instead of using the original displayIDs we remap them to a consecutive and smaller value range
-- DisplayIDs that are used by only one item are also dropped completely and are encoded by displayGroup = 0
-- This was advantageous when this information was still saved in a table
core.GenerateDisplayGroups = function()
	assert(core.groupData == nil, "GenerateDisplayGroups should only be called once after all items have been loaded!")

	core.groupData = {}

	local displayGroups = {} -- find displayIDs which are used by more than one item, the rest can be dropped and receives displayGroup = 0
	local groupCount = 0
	for displayID, itemIDs in pairs(core.displayIDs) do
		if table.getn(itemIDs) > 1 then
			groupCount = groupCount + 1
			displayGroups[displayID] = groupCount

			core.groupData[groupCount] = {}
			for _, itemID in pairs(itemIDs) do
				table.insert(core.groupData[groupCount], itemID)
			end
		end
	end
	
	core.itemInfo["displayGroup"] = {}
	for itemID, displayID in pairs(core.itemInfo.displayID) do
		core.itemInfo["displayGroup"][itemID] = displayGroups[displayID] or 0
	end

	core.displayIDs = nil
end

local ToByteString2 = function(itemID)
	local a = strchar(rshift(itemID, 8))
	local b = strchar(bit.band(itemID, 0xFF))

	return a .. b
end

local ToByteString3 = function(inventoryType, category, index)
	local a = strchar(inventoryType)				 -- better would be to encode invType + category in one byte with lookup table
	local b = strchar(core.categoryToID[category])	 
	local c = strchar(rshift(index, 8))				 -- could split up strings so that indices are capped to 256, but would need another table index then. only gain is that we save on the bit operation
	local d = strchar(bit.band(index, 0xFF))

	return a .. b .. c .. d
end

core.GenerateStringData = function()
	-- TODO: predefine static category IDs to get rid of this locale dependency?
	core.IDToCategory, core.categoryToID = {}, {}
	for key, category in pairs(core.CATEGORIES) do
		tinsert(core.IDToCategory, category)
	end
	for id, category in ipairs(core.IDToCategory) do
		core.categoryToID[category] = id
	end

	core.itemInfoNonTemp = {}
	-- core.itemInfoNonTemp.allowableClass = core.itemInfo.allowableClass
	-- core.itemInfoNonTemp.allowableFaction = core.itemInfo.allowableFaction
	core.itemInfoNonTemp.allowableRace = core.itemInfo.allowableRace

	-- check if there is pregenerated stringData, that fits our version, compression setting and client language
	if TransmoggyDB.stringData and stringDataVersion == TransmoggyDB.stringDataVersion
			and TransmoggyDB.stringDataIsCompressed == useCompression and TransmoggyDB.stringDataLocale == GetLocale() then
		core.stringData = TransmoggyDB.stringData
		core.stringDataPos = TransmoggyDB.stringDataPos
		
		core.itemInfo = nil
		core.groupData = nil
		core.names = nil
		core.displayIDs = nil
		classFactionMap = nil
		collectgarbage("collect")

		core.Debug("Loaded stringData from cache.")
		return
	end

	core.GenerateDisplayGroups()

	local t1 = GetTime()
	-- sort itemIDs into tables indexed by invType and category. afterwards we convert itemData to stringData
	local itemData = {}
	for invTypeID, invTypeName in pairs(core.inventoryTypes) do
		itemData[invTypeID] = {}
	end

	-- temporarily store info about what item comes after a certain item in their displayGroup. add to stringData so that we can reconstruct displayGroup from these chained links
	local tmp = {}	
	for groupID, tab in pairs(core.groupData) do
		for i, itemID in ipairs(tab) do
			tmp[itemID] = tab[i % #tab + 1] -- link item to the next item in its displayGroup
		end
	end

	-- sort itemIDs into tables according to invType and category. encode and store these positions into one large position bytestring
	local dataPositions = newStack()
	for i = 1, 55000 do
		if core.itemInfo["class"][i] then
			local inventoryType, class, subclass = core.itemInfo["inventoryType"][i], core.itemInfo["class"][i], core.itemInfo["subClass"][i]
			local category = core.classSubclassToType[class][subclass]

			if not itemData[inventoryType][category] then
				itemData[inventoryType][category] = {}
			end

			tinsert(itemData[inventoryType][category], i)

			addString(dataPositions, ToByteString3(inventoryType, category, #itemData[inventoryType][category]))
			
			-- if GetItemInfo(i) then core.names[i] = nil end -- item is cached, do not need to save the name (not if we cache our strings in WTF. then they have to contain all names)
		else
			addString(dataPositions, "\0\0\0\0")
		end
	end
	core.stringDataPos = table.concat(dataPositions) -- save where we put our item data

	-- iterate over these temporary subtables and generate the data byte strings
	local stringData = {}
	for inventoryType, tab1 in pairs(itemData) do
		stringData[inventoryType] = {}
		for category, tab2 in pairs(tab1) do
			local itemIDs = newStack()
			local displayGroups = newStack()
			local nextInGroups = newStack()
			local unlockedStates = newStack()
			local names = newStack()
			local classFactionCodes = newStack()
			
			for i, itemID in ipairs(tab2) do
				local displayGroup = core.itemInfo["displayGroup"][itemID]
				local unlocked = 0 -- gets set later
				local nxt = tmp[itemID] or itemID
				local cf = classFactionMap[core.itemInfo["allowableClass"][itemID] or 0][core.itemInfo["allowableFaction"][itemID] or 0]

				addString(itemIDs, ToByteString2(itemID))
				addString(displayGroups, ToByteString2(displayGroup))
				addString(nextInGroups, ToByteString2(nxt))
				addString(unlockedStates, strchar(unlocked))
				addString(names, (core.names[itemID] or "") .. "#")
				addString(classFactionCodes, strchar(cf))
			end
			stringData[inventoryType][category] = {}
			stringData[inventoryType][category].itemIDs = table.concat(itemIDs)
			stringData[inventoryType][category].displayGroups = table.concat(displayGroups)
			stringData[inventoryType][category].nextInGroup = table.concat(nextInGroups)
			stringData[inventoryType][category].unlockedStates = table.concat(unlockedStates)
			stringData[inventoryType][category].names = table.concat(names)
			stringData[inventoryType][category].classFactionCodes = table.concat(classFactionCodes)
		end
	end
	core.stringData = stringData

	local t2 = GetTime()
	
	-- optional compression of name data
	if useCompression then
		for inventoryType, tab1 in pairs(core.stringData) do
			for cat, stringData in pairs(tab1) do
				stringData.names = LibDeflate:CompressDeflate(stringData.names)
			end
		end
	end

	core.itemInfo = nil
	core.groupData = nil
	core.names = nil
	core.displayIDs = nil
	classFactionMap = nil

	TransmoggyDB.stringDataPos = core.stringDataPos
	TransmoggyDB.stringData = stringData
	TransmoggyDB.stringDataIsCompressed = useCompression
	TransmoggyDB.stringDataLocale = GetLocale()
	TransmoggyDB.stringDataVersion = stringDataVersion

	collectgarbage("collect")
	core.Debug(folder, "Succesfully encoded string data.")
	core.Debug("time for normal stringData:", t2 - t1, ". time for compression and garbage collection:", GetTime() - t2)
end

-- Overwrites all unlock data such that only ItemIDs in `unlocks` array will be unlocked
core.SetUnlocks = function(unlocks)
	local isUnlocked = {}
	for _, itemID in pairs(unlocks) do
		isUnlocked[itemID] = true
	end
	
	for inventoryType, tab1 in pairs(core.stringData) do
		for cat, stringData in pairs(tab1) do
			local unlockedStates = newStack()

			for itemID in core.InventoryTypeItemIterator(inventoryType, cat) do
				addString(unlockedStates, strchar(isUnlocked[itemID] and 1 or 0))
			end

			stringData.unlockedStates = table.concat(unlockedStates)
		end
	end
	
	core.Debug("set all unlocks!")
	core.MyWaitFunction(3.0, collectgarbage, "collect")
end

-- Any need for setting unlocked to 0 again?
core.SetUnlocked = function(itemID)
	assert(itemID and type(itemID) == "number" and itemID > 0 and itemID < 55000)

	if core.stringDataPos then
		local s = 4 * (itemID - 1) + 1
		local inventoryType, b, c, d = strbyte(core.stringDataPos, s, s + 3)
		local category = core.IDToCategory[b]
		if not category then return end
		local index = lshift(c, 8) + d

		core.stringData[inventoryType][category].unlockedStates = ReplaceChar(core.stringData[inventoryType][category].unlockedStates, index, strchar(1))
	elseif core.itemInfo then
		core.itemInfo["unlocked"][itemID] = 1
	else
		core.Debug("ERROR in SetUnlocked: Neither string, nor table data exists to write to!")
	end
end

core.GetItemData = function(itemID)
	if not itemID or itemID < 1 or itemID > 55000 then return end
	local s = 4 * (itemID - 1) + 1
	local inventoryType, b, c, d = strbyte(core.stringDataPos, s, s + 3)
	local category = core.IDToCategory[b]
	if not category then return end
	local index = lshift(c, 8) + d

	local unlocked = strbyte(core.stringData[inventoryType][category].unlockedStates, index)
	local a, b = strbyte(core.stringData[inventoryType][category].displayGroups, index * 2 - 1, index * 2)
	local displayGroup = lshift(a, 8) + b
	local class = core.typeToClassSubclass[category][1]
	local subclass = core.typeToClassSubclass[category][2]

	return unlocked, displayGroup, inventoryType, class, subclass  -- class, subclass should be retired and replaced by category or better yet category IDs
end

core.IsItemUnlocked = function(itemID)
	local unlocked = core.GetItemData(itemID)
	return unlocked == 1
end

-- TODO: decide whether to merge with GetItemData returns
core.GetItemData2 = function(itemID)
	if not itemID or itemID < 1 or itemID > 55000 then return end
	local s = 4 * (itemID - 1) + 1
	local inventoryType, b, c, d = strbyte(core.stringDataPos, s, s + 3)
	local category = core.IDToCategory[b]
	if not category then return end
	local index = lshift(c, 8) + d

	local cf = strbyte(core.stringData[inventoryType][category].classFactionCodes, index)

	-- print(itemID, inventoryType, category, index, cf)

	return toClassFaction[cf][1], toClassFaction[cf][2], core.itemInfoNonTemp.allowableRace[itemID]
end

core.GetItemTypeInfo = function(itemID)
	local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
	local category = class and core.classSubclassToType[class][subClass]
	local equipLoc = inventoryType and core.inventoryTypes[inventoryType]
	return category, equipLoc, inventoryType
end

-- TODO: As long as visualGroups contain items of different types (MH + OH, cloth + leather, etc) this information is not that useful imo
-- Should probably either split up visual groups by type or indicate whether the unlocked item shares the same item type
core.IsVisualUnlocked = function(itemID)
	local unlocked, visualGroup = core.GetItemData(itemID)
	
	if unlocked == 1 or not visualGroup or visualGroup == 0 then
		return unlocked
	end

	for alternativeItemID in core.DisplayGroupIterator(itemID) do
		local unlocked = core.GetItemData(alternativeItemID)
		if unlocked == 1 then return 1 end
	end

	return 0
end

-- Do not use in a loop unless you want to freeze the client! Use fitting iterator below with withNames=True instead
core.GetItemName = function(itemID)
	if not itemID or itemID < 1 or itemID > 55000 then return end
	local name = GetItemInfo(itemID)
	if name then return name end

	local s = 4 * (itemID - 1) + 1
	local inventoryType, b, c, d = strbyte(core.stringDataPos, s, s + 3)
	local category = core.IDToCategory[b]
	if not category then return end
	local index = lshift(c, 8) + d

	local count = 1
	local names = core.stringData[inventoryType][category].names
	names = useCompression and LibDeflate:DecompressDeflate(names) or names

	for i = 1, #names do -- run through name string and count the delimiter symbols to find where our name starts
		local c = strbyte(names, i)
		if c == 35 then
			count = count + 1
			if count == index then
				index = i + 1
				break
			end
		end
	end

	if index > #names then -- If we got a valid index from stringDataPos, we should find the name in the name string.
		core.Debug("Error in GetItemName.", itemID, inventoryType, category, index, #names, names)
		return
	end

	local name = strsub(names, index, index + strfind(strsub(names, index, math.min(index + 100, #names)), "#") - 2)
	return name and #name > 0 and name
end

local GetNextGroupItem = function(itemID)	
	if not itemID or itemID < 1 or itemID > 55000 then return end
	local s = 4 * (itemID - 1) + 1
	local inventoryType, b, c, d = strbyte(core.stringDataPos, s, s + 3)
	local category = core.IDToCategory[b]
	if not category then return end
	local index = lshift(c, 8) + d

	local a, b = strbyte(core.stringData[inventoryType][category].nextInGroup, index * 2 - 1, index * 2)
	local nxt = lshift(a, 8) + b
	return nxt
end

-- Info on Lua custom iterators:
	-- https://www.lua.org/pil/7.1.html
	-- https://stackoverflow.com/questions/46006462/lua-custom-iterator-proper-way-to-define
-- Called like this: for alternativeItemID in core.DisplayGroupIterator(itemID) do print(alternativeItemID) end
core.DisplayGroupIterator = function(itemID)
	local cur = itemID
	local done
	local i = 0
	return function()
		assert(i < 100) -- safety measure to avoid perma loop (although this should not happen)
		if done then return end
		local tmp = cur
		cur = GetNextGroupItem(cur)
		i = i + 1
		if cur == itemID then
			done = true -- next iteration would return start item again, so break after this
		end
		return tmp
	end
end

core.GetDisplayGroupSize = function(itemID)
	local s = 0
	for _ in core.DisplayGroupIterator(itemID) do
		s = s + 1
	end
	return s
end

-- Example usage:
	-- local c = 0; for itemID in core.ItemIterator() do c = c + 1 end print("Our data contains", c, "items.")
	-- for itemID in core.ItemIterator("HeadSlot", core.CATEGORIES.ARMOR_CLOTH) do print(itemID) end
	-- for itemID, itemName in core.ItemIterator("ChestSlot", nil, true) do print(itemID, itemName) end
-- Currently does not offer the option to iterate over all items with names. We never have to iterate over all items anyway and with names it would be pretty slow
-- If really neccessary, one could just iterate all slots with names
core.ItemIterator = function(slot, category, withNames)
	-- iterates over all items:
	if not slot then
		local i = 0
		return function()
			repeat
				if i > 55000 then return nil end
				i = i + 1
			until
				strbyte(core.stringDataPos, (i - 1) * 4 + 1) ~= 0

			return i
		end
	end

	-- slot (+ category) retricted iterators:
	local idStrings = {}
	for inventoryType, _ in pairs(core.slotItemTypes[slot]) do
		for cat, stringData in pairs(core.stringData[inventoryType]) do
			if core.slotHasCategory[slot][cat] then
				if not category or category == cat then
					tinsert(idStrings, stringData.itemIDs) -- strings are unique in lua, this does not copy the string  
				end
			end
		end
	end
	if #idStrings == 0 then return function() return nil end end -- return empty iterator incase our selection is empty

	local i, j, k = 0, 1, 0
	if withNames then -- slot iterator with names. slower and creates a lot of temporary strings, so use only when u need item names
		local nameStrings = {}
		for inventoryType, _ in pairs(core.slotItemTypes[slot]) do
			for cat, stringData in pairs(core.stringData[inventoryType]) do
				if core.slotHasCategory[slot][cat] then
					if not category or category == cat then
						local nameString = useCompression and LibDeflate:DecompressDeflate(stringData.names) or stringData.names
						tinsert(nameStrings, nameString)
					end
				end
			end
		end
		return function()
			i = i + 2
			k = k + 1
			if i > #idStrings[j] then
				j = j + 1
				i = 2
				k = 1
			end
			if j > #idStrings then return nil end
			
			local l = k
			while strbyte(nameStrings[j], k) ~= 35 do
				assert(k <= #nameStrings[j]) -- should not happen, but better be save then sorry
				k = k + 1
			end
			
			local a, b = strbyte(idStrings[j], i - 1, i)
			local id = lshift(a, 8) + b
			local name = (l == k) and GetItemInfo(id) or strsub(nameStrings[j], l, k - 1)
			
			return id, name
		end
	else -- slot iterator without names
		return function()
			i = i + 2
			if i > #idStrings[j] then
				j = j + 1
				i = 2
			end
			if j > #idStrings then return nil end
			
			local a, b = strbyte(idStrings[j], i - 1, i)
			return lshift(a, 8) + b
		end
	end
end

core.InventoryTypeItemIterator = function(inventoryType, category)
	local idString = core.stringData[inventoryType][category].itemIDs
	local i = 0

	return function()
		i = i + 2
		if i > #idString then
			return nil
		end
		
		local a, b = strbyte(idString, i - 1, i)
		return lshift(a, 8) + b
	end
end