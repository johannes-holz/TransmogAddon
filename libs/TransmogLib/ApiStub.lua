--MyAddon, myadd = ...

local MyAddonDB
SetDBRef = function(db)
	MyAddonDB = db
end

local InitDBValue = function(key, value)
	MyAddonDB["API"] = MyAddonDB["API"] or {}
	MyAddonDB["API"][key] = MyAddonDB["API"][key] or value
	
	return MyAddonDB["API"][key]
end

local deepCopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function contains(tab, element)
  for _, value in pairs(tab) do
    if value == element then
      return true
    end
  end
  return false
end

local GetUnusedSetID = function()
	local id = 1
	local usedIDs = {}
	MyAddonDB.API.sets = MyAddonDB.API.sets or {}
	for _, set in pairs(MyAddonDB.API.sets) do
		table.insert(usedIDs, set["id"])
	end
	
	while true do
		if contains(usedIDs, id) then
			id = id + 1
		else
			return id
		end
	end
end

IncreaseBalance = function()
	MyAddonDB.API.balance =  MyAddonDB.API.balance + 10000
end


local API = LibStub:NewLibrary("RisingAPI", 1)

local Promise = LibStub:GetLibrary("deferred")

local currentMog = {
	[3] = 30053,
	[5] = 30102,
	[6] = 21598,
	[7] = 29950,
	[8] = 54586,
	[16] = 48513,
	[17] = 21269,
	[10] = 29998,
}
function calculateCosts(set)	
	local sum, cost = 0, 0
	for slotID, itemID in pairs(set) do
		if itemID ~= MyAddonDB.API.currentMogs.inventory[slotID] then
			cost = select(11, GetItemInfo(itemID))
			if not cost or cost == 0 then
				cost = itemID
			end
			if cost then
				sum = sum + cost
			end
		end
	end
	
	return sum
end

function calculatePointCosts(id, set)	
	local sum, cost = 0, 0
	local currentSet
	local isSpecial
	for _, set in pairs(MyAddonDB.API.sets) do
		if set["id"] == id then
			currentSet = set["transmogs"]
			isSpecial = set["isSpecial"]
		end
	end
	
	for slotID, itemID in pairs(set) do
		if itemID ~= 0 and (not currentSet or not isSpecial or currentSet[slotID] ~= itemID) then
			cost = select(11, GetItemInfo(itemID))
			if not cost or cost == 0 then
				cost = itemID
			end
			if cost then
				sum = sum + cost
			end
		end
	end
	
	return sum
end

local function assertSlotId(slotId)
	assert(type(slotId) == "number")
	assert(slotId >= 0 and slotId < 20)
end

local function assertSetDesc(set)
	assert(type(set) == "table")
	for slot, item in pairs(set) do
		assertSlotId(slot)
		assert(type(item) == "number")
	end
end

local C_Timer = {
	frame = nil,
	timers = {},
}
function C_Timer.After(duration, callback)
	if not C_Timer.frame then -- setup
		C_Timer.frame = CreateFrame("Frame")
		C_Timer.frame:SetScript("OnUpdate", function (self, elapsed)
			local i = 1
			while i <= #C_Timer.timers do
				local timer = C_Timer.timers[i]

				if elapsed >= timer.duration then
					timer.callback()
					table.remove(C_Timer.timers, i)
				else
					timer.duration = timer.duration - elapsed
					i = i + 1
				end
			end
		end)
	end

	table.insert(C_Timer.timers, { callback = callback, duration = duration })
end

local function wait(duration)
	local promise = Promise.New()
	C_Timer.After(duration, function()
		promise:resolve()
	end)
	return promise
end

API_DELAY = 0.05
--local count, cap = 0, 13
local function simulateAPICall(response, error)
	--count = count + 1
	--if count > cap then
	--	count = 0
	--	API_DELAY = API_DELAY / 2
	--end
	local p = Promise.New()
	wait(API_DELAY):next(function()
		if (error) then
			p:reject("error")
		else
			p:resolve(response)
		end
	end)
	return p
end

function API.GetCurrentTransmogs()
	local bag
	local _, count = GetContainerItemInfo(0, 1)
	if (count == 1) then
		bag = {
			[1] = 51156,
		}
	end
	
	local mogs = InitDBValue("currentMogs", {
		--[[equipment = {
			[1] = 51158,
		},]]
		["inventory"] = currentMog,
		["container"] = {
			[0] = bag,
		}
	})

	return simulateAPICall(mogs)
end


local ITEMS = {
	[1] = { 51158, 51281 }, -- head
	[3] = { 51155 }, -- shoulder
}

function API.AddTestMoggables(slotID, itemID)
	if not ITEMS[slotID] then ITEMS[slotID] = {} end
	table.insert(ITEMS[slotID], itemID)
end

function API.GetAvailableTransmogs(slot)
	assertSlotId(slot)

	return simulateAPICall(ITEMS[slot] or {})
end

function API.GetPriceOfApplying(set)
	assertSetDesc(set)
	return simulateAPICall({
		copper = calculateCosts(set),
	})
end

function API.GetPriceOfSaving(setId, set)
	assert(type(setId) == "number")
	assertSetDesc(set)

	return simulateAPICall({
		copper = calculatePointCosts(setId, set)*111,
		points =  math.floor(calculatePointCosts(setId, set) / 100),
	})
end

function API.GetBalance()
	local balance = InitDBValue("balance", 1000)
	
	return simulateAPICall({
		points = balance,
	})
end

local lastApplyItemSuccessful = false
function API.ApplyTransmogs(set)
	--lastApplyItemSuccessful = not lastApplyItemSuccessful
	assertSetDesc(set)
	local costs = calculateCosts(set)
	SendChatMessage(".mod money -"..costs, "SAY")
	
	--currentMog = set
	MyAddonDB.API.currentMogs.inventory = set
	

	return simulateAPICall({
		success = true
	})
end

function API.GetSets()
	local sets = InitDBValue("sets", {
		{
			id = 5,
			name = "Mein erstes Set",
			isSpecial = false,
			transmogs = {
				[1] = 46212,
			}
		},
		{
			id = 7,
			name = "Mein zweites Set",
			isSpecial = true,
			transmogs = {
				[1] = 40829,
			}
		}
	})
	
	return simulateAPICall(sets)
end

function API.AddSet(setName)
	assert(type(setName) == "string")
	local freeID = GetUnusedSetID()
	
	table.insert(MyAddonDB.API.sets, {
		id = freeID,
		name = setName,
		isSpecial = false,
		transmogs = {}
	})
	
	return simulateAPICall(freeID)
end

function API.RemoveSet(setId)
	assert(type(setId) == "number")
	
	local foundID = false
	for k, set in pairs(MyAddonDB.API.sets) do
		if set["id"] == setId then
			table.remove(MyAddonDB.API.sets, k)
			foundID = true
		end
	end
	assert(foundID)
	
	return simulateAPICall({
		success = true
	})
end

function API.RenameSet(setId, name)
	assert(type(setId) == "number")
	assert(type(name) == "string")	
	
	local foundID = false
	for k, set in pairs(MyAddonDB.API.sets) do
		if set["id"] == setId then
			MyAddonDB.API.sets[k]["name"] = name
			foundID = true
		end
	end
	assert(foundID)

	return simulateAPICall({
		success = true
	})
end

function API.SaveSet(setId, set)
	assert(type(setId) == "number")
	assertSetDesc(set)
	
--	assert(MyAddonDB.API.sets[setId] ~= nil)
	local foundID = false
	for k, apiSet in pairs(MyAddonDB.API.sets) do
		if apiSet["id"] == setId then
			if MyAddonDB.API.sets[k]["isSpecial"] then
				MyAddonDB.API.balance = MyAddonDB.API.balance -  math.floor(calculatePointCosts(setId, set) / 100)
				SendChatMessage(".mod money -"..(calculatePointCosts(setId, set)*111), "SAY")
			end
			MyAddonDB.API.sets[k]["transmogs"] = deepCopy(set)
			foundID = true
		end
	end
	assert(foundID)
	
	return simulateAPICall({
		success = true,
	})
end

function API.UpgradeSet(setId, set)
	assert(type(setId) == "number")
	assertSetDesc(set)
	
	local foundID = false
	for k, apiSet in pairs(MyAddonDB.API.sets) do
		if apiSet["id"] == setId then
			foundID = true
			assert(apiSet["isSpecial"] == false)
			
			MyAddonDB.API.balance = MyAddonDB.API.balance - math.floor(calculatePointCosts(setId, set) / 100)
			SendChatMessage(".mod money -"..(calculatePointCosts(setId, set) * 111), "SAY")
			
			MyAddonDB.API.sets[k]["isSpecial"] = true
		end
	end
	assert(foundID)
	
	return simulateAPICall({
		success = true,
	})
end

function API.ApplySet(setId)
	assert(type(setId) == "number")
	
	local foundID = false
	for k, apiSet in pairs(MyAddonDB.API.sets) do
		if apiSet["id"] == setId then
			foundID = true
			assert(apiSet["isSpecial"] == true)
			
			MyAddonDB.API.currentMogs.inventory = deepCopy(apiSet["transmogs"])
		end
	end
	assert(foundID)
	
	return simulateAPICall({
		success = true,
	})
end
