local folder, core = ...

local deferred = LibStub("deferred")
local API = LibStub("RisingAPI", true)
local M = API and API.Transmog
if not deferred or not API or not M then print(folder, "ERROR: Could not find all required transmog libraries."); return end

core.GetPriceAndCheck = function(visualItemId, itemId, slotId, skinId)
    local futures = {
        M.GetPrice(visualItemId, itemId, slotId),
        M.Check(visualItemId, skinId, slotId),
    }

    return deferred.All(futures):next(function(results) -- should probably use AllSettled, but rejection message from GetPrice is more helpful than message in Check ._.
        local answer = {}

		-- core.am("GetPriceAndCheck", results)

        for _, result in pairs(results) do
            for k, v in pairs(result) do
                answer[k] = v
            end
        end
        
        return answer
    end)
end

core.UnlockVisualAll = function(items)
	local futures = {}
	for i, itemID in ipairs(items) do
        table.insert(futures, M.UnlockVisual(itemID))
	end

	return deferred.All(futures):next(API.Utils.Noop)
end