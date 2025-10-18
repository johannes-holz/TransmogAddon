local M, API = LibStub:GetLibrary("RisingAPI"):newModule("General")
if not M then return end
local Utils = API.Utils

function M.GetSupportedFeatures(features)
	return API:request("features", { features = features }):next(
		Utils.Extract("features")
	)
end
