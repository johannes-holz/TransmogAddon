local folder, core = ...

--[[
	I went through multiple iterations how the data gets stored so that it takes up as little space as possible while keeping access and iteration times fast and unnoticeable.

	Storing everything in tables is obviously the fastest, but takes up a lot of ram, even when grouping data by field instead of itemID
	(other AddOns like e.g. DressMe that store less Data and are overall much smaller need ~7MB).

	Bit operations are very slow in Lua, so packing our data in bits of numbers or strings makes item iteration very noticeable (.1 - .2 seconds or something like that).

	What does save a lot of space compared to table data while only being slightly slower is using byte strings to store our data.
	Each item gets its data converted to a string of certain length and for numbers that are not in our data we add a string of equal length that contains all '\0's.
	Like this we can still index data by using `strbyte()` and we only need bit operations when we need to store or read values that do not fit into one byte.

	First I used one big byte string to store all item information (unlocked, displayGroup, invType, class, subclass).
	This approach works well enough and indexing is simple. But with this we need to iterate over all items every time and we can't utilize, that we only need about 1/15 of all items per slot.
	Furthermore, if we want to store more information like class, race or level requirements etc., we need to fill a lot of empty entries (55kB per extra date byte).

	In the current version we still save data to byte strings, but now order them into tables by inventoryType and category (= class + subclass).
	These substrings also do not contain empty filler data anymore, because we do not index them directly. Instead we add itemIDs to the data.
	With this we can write iterators, that only look at the selection of the data that we need instead of iterating over the whole itemID range (~[1, 55000]).
	In order to still be able to look up item data directly by index, we additionally need one byte string that stores inventoryType, category and index in the corresponding substring.
	
	Uncached names also get stored in byte strings. Here we obviously don't want to assign a static number of bytes per entry.
	Instead we use a delimiter '#' between entries. With this we can still iterate somewhat quickly, but since this is slightly slower and creates a lot of temporary names	as garbage,
	we only use the iterator with itemnames, when we need it (there is an non-numerical search term).
	GetItemName offers the option to get a name by itemID, but this goes over the whole name substring each time, so this should not be used in a loop.
	We could store additional name indices in our data to get constant time access instead, but the only place where we need names at the moment is when generating a filtered item list, so there we can just use our iterator.

	Display groups are now also encoded by having items link to their displayGroupID as well as the next item in their group.
	The first gets used to create temporary groupings in the item list. The latter gets used like a linked list to be able to iterate over a group for `IsVisualUnlocked()`.

	Overall item data currently takes up about 1mb when there are no items cached by the client.

	Enchant and Recipe data is small enough, that we can just use tables.

	TODO:
		-Decide whether it is worth compressing name strings with LibDeflate.
			- Would save up to 440kB, but increases iteration time per slot by up to 0.04s on my laptop and creates like 2-4mB of extra garbage per slot search
			- Maybe implement with boolean for now, but idk. its fast enough imo but that is a lot of garbage on every iteration with search term
			- When we click through e.g. all armmor slots with a search term to equip a certain set we would create like 40mB of garbage
		
		- Can save another 55kB in the index byte string at the cost of another bit operation (or at almost no cost if we instead encode all possible invType + category combinations in one byte)

		- Lots of hardcoded magic numbers in the new version atm. (e.g. byte lengths per date), fix at some point!
			- Also the delimiter and its byte value is hardcoded atm. should fix this and also be sure to use a symbol, that does not occur in any name string

		- When happy with solution write/load strings directly from file so they don't have to be generated every time?
]]

local LibDeflate = LibStub and LibStub:GetLibrary("LibDeflate")

-- UPDOOTS (here they are justified for once) --
local rshift = bit.rshift
local lshift = bit.lshift
local mod = bit.mod

local strbyte = strbyte
local strchar  = strchar
local strsub = strsub

local GetItemInfo = GetItemInfo

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

local slotItemTypes = {
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
	["MainHandSlot"] = {[13] = true, [21] = true, [17] = true}, --1h, mh, 2h
	["SecondaryHandSlot"] = {[13] = true, [22] = true, [17] = true, [14] = true, [23] = true}, --1h, oh, 2h, shields, holdable/tomes --myadd.Contains twohand for warris?
	["ShieldHandWeaponSlot"] = {[13] = true, [22] = true, [17] = true}, -- 1H, OH, 2H
	["OffHandSlot"] = {[14] = true, [23] = true}, -- shields, holdables
	["RangedSlot"] = {[15] = true, [25] = true, [26] = true}, --bow, thrown, ranged right(gun, wands, crossbow)
}
core.slotItemTypes = slotItemTypes

-- Utility functions to efficiently build large strings (from PIL: https://www.lua.org/pil/11.6.html)
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

ReplaceChar = function(s, pos, c)
    return s:sub(1, pos - 1) .. c .. s:sub(pos + 1)
end

-- These `Add...()` functions are used to load in the item/enchant data. Afterwards the generated tables get converted to a more compact data format.
-- They can not be used to add new items later on after the loading process!
core.AddEnchant = function(visualID, enchantID, spellID)
	if not (visualID and enchantID) then return false end
	--core.am(visualID..", "..enchantID)
	core.enchants = core.enchants or {}
	if core.enchants[visualID] then
		table.insert(core.enchants[visualID]["enchantIDs"], enchantID)
	else 
		core.enchants[visualID] = {["enchantIDs"] = {enchantID}}
	end
	core.enchantInfo = core.enchantInfo or {}
	core.enchantInfo["visualID"] = core.enchantInfo["visualID"] or {}
	core.enchantInfo["spellID"] = core.enchantInfo["spellID"] or {}
	
	core.enchantInfo["visualID"][enchantID] = visualID
	core.enchantInfo["spellID"][enchantID] = spellID
end

core.GetEnchantInfo = function(enchantID)
	local spellID = core.enchantInfo.spellID[enchantID]
	if spellID then
		return GetSpellInfo(spellID)
	end
end

core.itemInfo = {
	displayID = {},
	class = {},
	subClass = {},
	inventoryType = {},
	-- quality = {},
	-- requiredLevel = {},
	-- allowableClass = {},
	-- allowableFaction = {},
	-- allowableRace = {},
	unlocked = {},
}
core.displayIDs = {}
core.AddItem = function(displayID,itemID,class,subClass,inventoryType,quality,requiredLevel,allowableRace,allowableClass,allowableFaction)
	if not core.inventoryTypes[inventoryType] then return end -- only want transmogable item types

	if core.displayIDs[displayID] then
		if core.Contains(core.displayIDs[displayID], itemID) then return end
		table.insert(core.displayIDs[displayID], itemID)
	else 
		core.displayIDs[displayID] = { itemID }
	end
		
	core.itemInfo["displayID"][itemID] = displayID
	core.itemInfo["class"][itemID] = class
	core.itemInfo["subClass"][itemID] = subClass
	core.itemInfo["inventoryType"][itemID] = inventoryType
	-- core.itemInfo["quality"][itemID] = quality
	-- core.itemInfo["requiredLevel"][itemID] = requiredLevel
	-- core.itemInfo["allowableRace"][itemID] = allowableRace
	-- core.itemInfo["allowableClass"][itemID] = allowableClass
	-- core.itemInfo["allowableFaction"][itemID] = allowableFaction
end

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

core.recipeData = { recipes = {}, spells = {} }
core.LoadRecipe = function(recipeID, spellID, itemID)
	core.recipeData.recipes[recipeID] = itemID
	core.recipeData.spells[spellID] = itemID
end

-- maps itemID of recipes to the crafted (wearable) item
core.GetRecipeInfo = function(recipe)
	local recipe = core.GetItemIDFromLink(recipe)
	return recipe and core.recipeData.recipes[recipe]
end

-- maps spellID of a spell to the (wearable) item it produces
core.GetSpellRecipeInfo = function(spell)
	local spell = core.GetSpellIDFromLink(spell)
	return spell and core.recipeData.spells[spell]
end

local GetItemData = function(itemID)
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
core.GetItemData = GetItemData

-- TODO: As long as visualGroups contain items of different types (MH + OH, cloth + leather, etc) this information is not that useful imo
	-- Should probably either split up visual groups by item type or indicate whether the unlocked item shares the same item type
core.IsVisualUnlocked = function(itemID)
	local unlocked, visualGroup = core.GetItemData(itemID)
	
	if not visualGroup or visualGroup == 0 then
		return unlocked
	end

	for alternativeItemID in core.DisplayGroupIterator(itemID) do
		local unlocked = core.GetItemData(alternativeItemID)
		if unlocked == 1 then return 1 end
	end

	return 0
end

core.IsItemUnlocked = function(itemID)
	local unlocked = core.GetItemData(itemID)

	return unlocked
end

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
		print("ERROR in SetUnlocked: Neither string, nor table data exists to write to!")
	end
end

local ToByteString2 = function(itemID)
	local a = strchar(rshift(itemID, 8))
	local b = strchar(bit.band(itemID, 0xFF))

	return a .. b
end

local ToByteString3 = function(inventoryType, category, index)
	local a = strchar(inventoryType)
	local b = strchar(core.categoryToID[category])	 -- needs 5 bit
	local c = strchar(rshift(index, 8))				 -- biggest index is 950, so we could save another byte (x55k) at the cost of adding another bit operation here and combining byte b and c
	local d = strchar(bit.band(index, 0xFF))

	return a .. b .. c .. d
end

core.GenerateStringData = function()
	-- sort itemIDs into tables indexed by invType and category
	local itemData = {}
	for invTypeID, invTypeName in pairs(core.inventoryTypes) do
		itemData[invTypeID] = {}
	end
	
	core.IDToCategory, core.categoryToID = {}, {}
	for key, category in pairs(core.CATEGORIES) do
		tinsert(core.IDToCategory, category)
	end
	for id, category in ipairs(core.IDToCategory) do
		core.categoryToID[category] = id
	end

	local tmp = {}	-- temporarily store info about what item comes after a certain item in their displayGroup. add to stringData so that we can reconstruct displayGroup from these chained links
	for groupID, tab in pairs(core.groupData) do
		for i, itemID in ipairs(tab) do
			tmp[itemID] = tab[i % #tab + 1] -- link item to the next item in its displayGroup
		end
	end

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
			
			if GetItemInfo(i) then core.names[i] = nil end -- item is cached, do not need to save the name
		else
			addString(dataPositions, "\0\0\0\0")
		end
	end
	core.stringDataPos = table.concat(dataPositions) -- save where we put our item data

	-- iterate over all subtables and generate the byte strings
	local stringData = {}
	for inventoryType, tab1 in pairs(itemData) do
		stringData[inventoryType] = {}
		for category, tab2 in pairs(tab1) do
			local itemIDs = newStack()
			local displayGroups = newStack()
			local nextInGroups = newStack()
			local unlockedStates = newStack()
			local names = newStack()
			for i, itemID in ipairs(tab2) do
				local displayGroup = core.itemInfo["displayGroup"][itemID]
				local unlocked = core.itemInfo["unlocked"][itemID] or 0
				local nxt = tmp[itemID] or itemID
				addString(itemIDs, ToByteString2(itemID))
				addString(displayGroups, ToByteString2(displayGroup))
				addString(nextInGroups, ToByteString2(nxt))
				addString(unlockedStates, strchar(unlocked))
				addString(names, (core.names[itemID] or "") .. "#")
			end
			stringData[inventoryType][category] = {}
			stringData[inventoryType][category].itemIDs = table.concat(itemIDs)
			stringData[inventoryType][category].displayGroups = table.concat(displayGroups)
			stringData[inventoryType][category].nextInGroup = table.concat(nextInGroups)
			stringData[inventoryType][category].unlockedStates = table.concat(unlockedStates)
			stringData[inventoryType][category].names = table.concat(names)
		end
	end
	core.stringData = stringData

	core.itemInfo = nil
	core.groupData = nil
	core.names = nil

	collectgarbage("collect")
	print(folder, "Succesfully encoded string data.")
end

-- Do not use in a loop unless you want quadratic runtime! Use iterator below with withNames=True instead
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
	for i = 1, #names do
		local c = strbyte(names, i)
		if c == 35 then
			count = count + 1
			if count == index then
				index = i + 1
				break
			end
		end
	end
	if index > #names then
		print(itemID, inventoryType, category, index, #names, names)
	end

	return strsub(names, index, index + strfind(strsub(names, index, math.min(index + 100, #names)), "#") - 2)
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

-- Nice explanations of Lua custom iterators:
	-- https://www.lua.org/pil/7.1.html
	-- https://stackoverflow.com/questions/46006462/lua-custom-iterator-proper-way-to-define
-- Called like this: for alternativeItemID in core.DisplayGroupIterator(itemID) do print(alternativeItemID) end
core.DisplayGroupIterator = function(itemID)
	local cur = itemID
	local done
	local i = 0
	return function()
		assert(i < 100) -- safety measure to avoid possibility of perma loop (even tho it should never happen)
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
	for inventoryType, _ in pairs(slotItemTypes[slot]) do
		for cat, stringData in pairs(core.stringData[inventoryType]) do
			if not category or category == cat then
				tinsert(idStrings, stringData.itemIDs) -- strings are unique in lua, this does not copy the string  
			end
		end
	end
	if #idStrings == 0 then return function() return nil end end -- return empty iterator incase our selection is empty

	local i, j, k = 0, 1, 0
	if withNames then -- slot iterator with names. slightly slower and creates a lot of temporary strings, so use only when u need item names
		local nameStrings = {}
		for inventoryType, _ in pairs(slotItemTypes[slot]) do
			for cat, stringData in pairs(core.stringData[inventoryType]) do
				if not category or category == cat then
					tinsert(nameStrings, stringData.names) 
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
				assert(k <= #nameStrings[j]) -- TODO: safety condition like this needed, even tho this should not happen?
				k = k + 1
			end
			
			local a, b = strbyte(idStrings[j], i - 1, i)
			local id = lshift(a, 8) + b
			local name = (l == k) and GetItemInfo(id) or strsub(nameStrings[j], l, k - 1)
			
			return id, name
		end
	else -- slot iterator without nameData
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