folder, core = ...

-- Not included atm. could revisited after we have managed item queries


local BackgroundItemInfoWorker = CreateFrame("Frame", nil, UIParent)

BackgroundItemInfoWorker.FindNextItemBatch = function(size)
	local batch = {}
	for itemID, _ in pairs(myadd.itemInfo["displayID"]) do
		if not GetItemInfo(itemID) then
			table.insert(batch, itemID)
		end
		if length(batch) >= size then
			break
		end
	end
	
	return batch
end

BackgroundItemInfoWorker.Start = function()
	if not BackgroundItemInfoWorker.batch or length(BackgroundItemInfoWorker.batch) == 0 then
		BackgroundItemInfoWorker.batch = BackgroundItemInfoWorker.FindNextItemBatch(1000)
	end
	
	if length(BackgroundItemInfoWorker.batch) == 0 then return end
	
	local itemID = table.remove(BackgroundItemInfoWorker.batch)
	MyWaitFunction(0.12, FunctionOnItemInfo, itemID, BackgroundItemInfoWorker.Start)
end

