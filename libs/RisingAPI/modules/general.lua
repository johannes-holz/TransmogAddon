local M, API = LibStub:GetLibrary("RisingAPI"):newModule("General")
local Utils = API.Utils

function M.GetSupportedFeatures(features)
	return API:request("features", { features = features }):next(
		Utils.Extract("features")
	)
end
