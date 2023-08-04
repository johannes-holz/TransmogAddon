local folder, core = ...

local WIDTH, HEIGHT = 660, 480
local HEADER_HEIGHT = 60

local WardrobeFrame_OnShow = function(self)
    self:SetToplevel(true)
    self:SelectItemTab()
end

core.wardrobeFrame = CreateFrame("Frame", folder .. "WardrobeFrame", UIParent)
local wardrobeFrame = core.wardrobeFrame
wardrobeFrame:SetSize(WIDTH, HEIGHT)
wardrobeFrame:SetPoint("CENTER")
wardrobeFrame:SetBackdrop(BACKDROP_TOAST_12_12)
wardrobeFrame:EnableMouse()
tinsert(UISpecialFrames, wardrobeFrame:GetName())

-- itemCollectionFrame:SetAttribute("UIPanelLayout-defined", true)
-- itemCollectionFrame:SetAttribute("UIPanelLayout-enabled", true)
-- itemCollectionFrame:SetAttribute("UIPanelLayout-area", "doublewide")
-- itemCollectionFrame:SetAttribute("UIPanelLayout-pushable", 5)
-- --MyFrameName:SetAttribute("UIPanelLayout-width", width) -- Custom width is not recommended.
-- itemCollectionFrame:SetAttribute("UIPanelLayout-whileDead", true)

-- ToggleWardrobe = function()
-- 	if itemCollectionFrame:IsShown() then
-- 		HideUIPanel(itemCollectionFrame)
-- 	else
-- 		ShowUIPanel(itemCollectionFrame)
-- 	end
-- end

wardrobeFrame:SetScript("OnShow", WardrobeFrame_OnShow)

core.OpenWardrobe = function()
    core.transmogFrame:Hide()
	core.SetIsAtTransmogrifier(false)
	core.wardrobeFrame:Show()
end

DressUpFrame:HookScript("OnShow", function()
    wardrobeFrame:ClearAllPoints()
    wardrobeFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPRIGHT", 0, -12 + HEADER_HEIGHT / 2)
    core.OpenWardrobe()
end)

DressUpFrame:HookScript("OnHide", function()
    wardrobeFrame:Hide()
end)

wardrobeFrame.SelectItemTab = function(self)
    -- core.wardrobeCollectionFrame:SetContainer(self)
    core.itemCollectionFrame:SetParent(self)
    core.itemCollectionFrame:SetPoint("TOPLEFT", 6, -HEADER_HEIGHT)
    core.itemCollectionFrame:Show()
end

local exitButton = core.CreateMeAButton(wardrobeFrame, 22, 22, nil,
    "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 90/512, 118/512, 451/512, 481/512,
    "Interface\\Buttons\\UI-Panel-MinimizeButton-Down", 90/512, 118/512, 451/512, 481/512,
    "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", 90/512, 118/512, 451/512, 481/512,
    "Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled", 90/512, 118/512, 451/512, 481/512)
exitButton:SetPoint("TOPRIGHT", -4, -7)
exitButton:SetScript("OnClick", function(self, button)
    self:GetParent():Hide()
end)

local titleFrame = wardrobeFrame:CreateFontString()
titleFrame:SetFontObject("GameFontNormal")
titleFrame:SetText(core.APPEARANCES)
titleFrame:SetPoint("TOP", 0, -7)