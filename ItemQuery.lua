local folder, core = ...

-- might wanna upgrade this at some point to behave like a stack and have dynamic query limiting, so we stay under the ~250? requests per 30s, that the client enforces
-- (when going over this limit by requesting e.g. 750 items, we don't get any info for ~1:30, at which point we receive all info at once)

local Length = core.Length

local MAX_QUERY_TIME = 180
local PERIOD = 0.1
local DEBUG = false

local tooltip = CreateFrame("GameTooltip")
local waitFrame = CreateFrame("Frame")
waitFrame.queries = {} -- [itemId] = {{timer1, f1, p1, p2, ...}, {timer2, f2, p1, p2, p3, ..}, ...}
waitFrame.elapsed = 0.0


-- For some reason the SetHyperlink call does nothing, when called during the loading process
local waitFrame_RequeryAll = function(self)
	for itemID, _ in pairs(self.queries) do
		tooltip:SetHyperlink("item:" .. itemID)
	end
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
waitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
waitFrame:SetScript("OnEvent", waitFrame_RequeryAll)

local waitFrame_OnUpdate = function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
	
    if self.elapsed >= PERIOD then
		self.elapsed = self.elapsed - PERIOD
		local time = GetTime()

        local onRemove = {}

        for itemID, tab in pairs(self.queries) do
            local itemName = GetItemInfo(itemID)
            local i = #tab
            while i >= 1 do
                local q = tab[i]
                if itemName or (MAX_QUERY_TIME and time - q[1] > MAX_QUERY_TIME) then
                    local _, f, p = unpack(table.remove(tab, i))
					if itemName then
						if DEBUG then print("Found ItemInfo for", itemID, itemName, ". Do the Func", f) end
						f(unpack(p))
					elseif DEBUG then
						print("FunctionOnItemInfo", f, "timed out for itemID", itemID)
					end
                end
                i = i - 1
            end

            if #tab == 0 then
                table.insert(onRemove, itemID)
            end
        end

		-- local l = 0
		-- for k, v in pairs(self.queries) do
		-- 	l = l + #v
		-- end
		-- print(core.Length(waitFrame.queries), l, core.Length(onRemove))

        while #onRemove > 0 do
            self.queries[table.remove(onRemove)] = nil
        end

        if next(self.queries) == nil then
            self:SetScript("OnUpdate", nil)
        end
    end
end


local DummyFunction = function() end

core.FunctionOnItemInfo = function(itemID, func, ...)	
	if type(itemID) == "string" then
		itemID = select(3, strfind(itemID, "item:(%d+)"))
	end

	assert(type(itemID) == "number" and type(func) == "function", "Wrong usage of FunctionOnItemInfo")
	
	if GetItemInfo(itemID) then
		func(...)
	else
		if not waitFrame.queries[itemID] then
			tooltip:SetHyperlink("item:" .. itemID .. ":0:0:0:0:0:0:0")
			waitFrame.queries[itemID] = {}
		end
		if func ~= DummyFunction or core.Length(waitFrame.queries[itemID]) == 0 then
			tinsert(waitFrame.queries[itemID], { GetTime(), func, {...} })
			if waitFrame:GetScript("OnUpdate") == nil then
				waitFrame:SetScript("OnUpdate", waitFrame_OnUpdate)
			end
		end
	end
end

core.FunctionOnItemInfoUnique = function(itemID, func, ...)
	if waitFrame.queries[itemID] then
		for itemID, tab in pairs(waitFrame.queries[itemID]) do
			if func == tab[2] then
				return
			end
		end
	end
	core.FunctionOnItemInfo(itemID, func, ...)
end

core.QueryItem = function(itemID)
	core.FunctionOnItemInfo(itemID, DummyFunction)
end

core.ClearAllOutstandingOIIF = function()
	if itemInfoWaitFrame then
		itemInfoWaitFrame.queries = {}
	end
end
