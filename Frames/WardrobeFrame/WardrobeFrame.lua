local folder, core = ...

local WIDTH, HEIGHT = 660, 480
local HEADER_HEIGHT = 68

core.OpenWardrobe = function()
    core.transmogFrame:Hide()
	core.SetIsAtTransmogrifier(false)
	core.wardrobeFrame:Show()
    core.wardrobeFrame:Raise()
end

local WardrobeFrame_OnShow = function(self)
    PlaySound("igCharacterInfoOpen")
    self:SelectItemTab()
end

local WardrobeFrame_OnHide = function(self)
    PlaySound("igCharacterInfoClose")
end

core.wardrobeFrame = CreateFrame("Frame", folder .. "WardrobeFrame", UIParent, "UIPanelDialogTemplate")
local wardrobeFrame = core.wardrobeFrame
wardrobeFrame:SetSize(WIDTH, HEIGHT)
wardrobeFrame:SetPoint("CENTER")
-- wardrobeFrame:SetBackdrop(BACKDROP_TOAST_12_12)
wardrobeFrame:EnableMouse(true)
wardrobeFrame:SetMovable(true)
wardrobeFrame:SetToplevel(true) -- raises frame level to be on top of other frames on mouse click
tinsert(UISpecialFrames, wardrobeFrame:GetName()) -- close on escape

wardrobeFrame.title:SetText(core.APPEARANCES)

wardrobeFrame:SetScript("OnShow", WardrobeFrame_OnShow)
wardrobeFrame:SetScript("OnHide", WardrobeFrame_OnHide)

wardrobeFrame:SetScript("OnMouseDown",function(self,button)
    CloseDropDownMenus()
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
wardrobeFrame:SetScript("OnMouseUp",function(self,button)
    if button == "LeftButton" then
        self:StopMovingOrSizing()
    end
end)

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



-- DressUpFrame:HookScript("OnShow", function()
--     wardrobeFrame:ClearAllPoints()
--     wardrobeFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPRIGHT", 0, -12 + HEADER_HEIGHT / 2)
--     core.OpenWardrobe()
-- end)

-- DressUpFrame:HookScript("OnHide", function()
--     wardrobeFrame:Hide()
-- end)

wardrobeFrame.SelectItemTab = function(self)
    -- core.wardrobeCollectionFrame:SetContainer(self)
    core.itemCollectionFrame:SetParent(self)
    -- core.itemCollectionFrame:SetPoint("TOPLEFT", 6, -HEADER_HEIGHT)
    core.itemCollectionFrame:ClearAllPoints()
    core.itemCollectionFrame:SetPoint("TOP", self, "TOP", 1, -HEADER_HEIGHT)
    core.itemCollectionFrame:Show()

    wardrobeFrame.buttons[1]:Click()
end

-- local exitButton = core.CreateMeAButton(wardrobeFrame, 22, 22, nil,
--     "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 90/512, 118/512, 451/512, 481/512,
--     "Interface\\Buttons\\UI-Panel-MinimizeButton-Down", 90/512, 118/512, 451/512, 481/512,
--     "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", 90/512, 118/512, 451/512, 481/512,
--     "Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled", 90/512, 118/512, 451/512, 481/512)
-- exitButton:SetPoint("TOPRIGHT", -4, -7)
-- exitButton:SetScript("OnClick", function(self, button)
--     self:GetParent():Hide()
-- end)

-- local titleFrame = wardrobeFrame:CreateFontString()
-- titleFrame:SetFontObject("GameFontNormal")
-- titleFrame:SetText(core.APPEARANCES)
-- titleFrame:SetPoint("TOP", 0, -7)



core.ShowItemInWardrobe = function(itemID, slot)
    core.OpenWardrobe()
    core.itemCollectionFrame:SetSlotAndCategory(slot, nil)
    core.itemCollectionFrame:GoToItem(itemID)
end

core.unlocksOverviewFrame = core.CreateUnlocksOverviewFrame(core.wardrobeFrame)
core.unlocksOverviewFrame:Hide()

local TAB_NAMES = { ITEMS, core.OVERVIEW }
wardrobeFrame.tabs = { "itemCollectionFrame", "unlocksOverviewFrame" }
wardrobeFrame.tabButtons = {}

local function TabButton_OnClick(self)
    -- local currenTabID = PanelTemplates_GetSelectedTab(self:GetParent())
    -- local tab = core[wardrobeFrame.tabs[currenTabID]]
    -- if tab ~= nil then
    -- 	tab:Hide()
    -- end
    for i, tab in ipairs(wardrobeFrame.tabs) do
        if core[tab] then
            core[tab]:Hide()
        end
    end

    local id = self:GetID()
    local tab = core[wardrobeFrame.tabs[id]]
    tab:SetParent(wardrobeFrame)
    tab:ClearAllPoints()
    tab:SetPoint("TOP", 1, -HEADER_HEIGHT)
    tab:Show()
    PanelTemplates_SetTab(wardrobeFrame, id)
    PlaySound("gsTitleOptionOK")
end

wardrobeFrame.buttons = {}
for i, tabName in ipairs(TAB_NAMES) do
    wardrobeFrame.buttons[i] = CreateFrame("Button", "$parentTab" .. i, wardrobeFrame, "TabButtonTemplate")
    local btn = wardrobeFrame.buttons[i]
    btn:SetText(tabName)
    btn:SetID(i)
    if i == 1 then
        btn:SetPoint("BOTTOMLEFT", wardrobeFrame, "TOPLEFT", 10, -HEADER_HEIGHT - 3)
    else
        btn:SetPoint("BOTTOMLEFT", wardrobeFrame.buttons[i - 1], "BOTTOMRIGHT")
    end
    btn:SetScript("OnClick", TabButton_OnClick)
    PanelTemplates_TabResize(btn, -5)
end	
PanelTemplates_SetNumTabs(wardrobeFrame, #TAB_NAMES)
