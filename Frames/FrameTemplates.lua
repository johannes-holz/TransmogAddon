local folder, core = ...

---- Search Box -----
do  
    local alpha = 0.5
    local tex = "Interface\\AddOns\\".. folder .."\\images\\CommonSearch"

    local SearchBox_OnEditFocusLost = function(self)
        if self:GetText() == "" then
            self.searchIcon:Show()
            self.searchText:Show()
        end
    end

    core.CreateSearchBox = function(name, parent)
        local f = CreateFrame("EditBox", name, parent, "InputBoxTemplate")

        f.searchIcon = f:CreateTexture(nil, "OVERLAY")
        f.searchIcon:SetTexture(tex)
        f.searchIcon:SetTexCoord(20/256, 43/256, 43/128, 66/128)
        f.searchIcon:SetSize(10, 10)
        f.searchIcon:SetAlpha(alpha)
        f.searchIcon:SetPoint("LEFT")

        f.searchText = f:CreateFontString()
        f.searchText:SetFontObject(GameFontWhiteSmall)
        f.searchText:SetPoint("LEFT", f.searchIcon, "RIGHT", 2, 0)
        f.searchText:SetJustifyH("LEFT")
        f.searchText:SetJustifyV("MIDDLE")
        f.searchText:SetText(SEARCH)
        f.searchText:SetAlpha(alpha)

        f.clearButton = CreateFrame("Button", nil, f)
        f.clearButton:SetSize(17, 17)
        f.clearButton:SetPoint("RIGHT", -3, 0)
        f.clearButton:SetAlpha(alpha)
        
        f.clearButton.texture = f.clearButton:CreateTexture(nil, "ARTWORK")
        f.clearButton.texture:SetTexture(tex)
        f.clearButton.texture:SetTexCoord(18/256, 40/256, 68/128, 90/128)
        f.clearButton.texture:SetSize(10, 10)
        f.clearButton.texture:SetPoint("TOPLEFT", 3, -3)

        f.clearButton:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
        f.clearButton:SetScript("OnLeave", function(self) self:SetAlpha(alpha) end)
        f.clearButton:SetScript("OnMouseDown", function(self) if self:IsEnabled() then self.texture:SetPoint("TOPLEFT", 4, -4) end end)
        f.clearButton:SetScript("OnMouseUp", function(self) self.texture:SetPoint("TOPLEFT", 3, -3) end)
        f.clearButton:SetScript("OnClick", function(self)
            self:GetParent():SetText("")
            self:GetParent():ClearFocus()
            SearchBox_OnEditFocusLost(self:GetParent())
        end)
        
        f:SetScript("OnEscapePressed", f.ClearFocus)
        f:SetScript("OnEnterPressed", f.ClearFocus)
        f:SetScript("OnEditFocusGained", function(self)
            self.searchIcon:Hide()
            self.searchText:Hide()
        end)
        f:SetScript("OnEditFocusLost", SearchBox_OnEditFocusLost)
        f:SetScript("OnShow", SearchBox_OnEditFocusLost)
        f:SetScript("OnTextChanged", function(self)
            core.SetShown(self.clearButton, self:GetText() ~= "")
        end)

        return f
    end
end

---- Attempt at PortraitFrameTemplate -----
do


end


----- Some Scuffed Button utils -----
local function CreateMeAButton(parent, width, height, text,
                                upTex, upLeft, upUp, upRight, upDown,
                                downTex, downLeft, downUp, downRight, downDown,
                                highlightTex, highLeft, highUp, highRight, highDown,
                                disabledTex, disLeft, disUp, disRight, disDown)    
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    if text then b:SetText(text) end
    b:SetNormalFontObject("GameFontNormal")
    b:SetHighlightFontObject("GameFontHighlight")
    b:SetDisabledFontObject("GameFontDisable")

    local ntex = b:CreateTexture()
    ntex:SetTexture(upTex or "Interface/Buttons/UI-Panel-Button-Up")
    ntex:SetTexCoord(upLeft, upRight, upUp, upDown)
    ntex:SetAllPoints()	
    b:SetNormalTexture(ntex)	

    local ptex = b:CreateTexture()
    ptex:SetTexture(downTex or "Interface/Buttons/UI-Panel-Button-Down")
    ptex:SetTexCoord(downLeft, downRight, downUp, downDown)
    ptex:SetAllPoints()
    b:SetPushedTexture(ptex)

    local htex = b:CreateTexture()
    htex:SetTexture(highlightTex or "Interface/Buttons/UI-Panel-Button-Highlight")
    htex:SetTexCoord(highLeft, highRight, highUp, highDown)
    htex:SetAllPoints()
    b:SetHighlightTexture(htex)

    local dtex = b:CreateTexture()
    dtex:SetTexture(disabledTex or "Interface/Buttons/UI-Panel-Button-Disabled")
    dtex:SetTexCoord(disLeft, disRight, disUp, disDown)
    dtex:SetAllPoints()
    b:SetDisabledTexture(dtex)
    return b
end
core.CreateMeAButton = CreateMeAButton

local function CreateMeATextButton(parent, width, height, text)
    local b = CreateMeAButton(parent, width, height, text,
        "Interface/Buttons/UI-Panel-Button-Up", 0, 0, 0.625, 0.6875,
        "Interface/Buttons/UI-Panel-Button-Down", 0, 0, 0.625, 0.6875,
        "Interface/Buttons/UI-Panel-Button-Highlight", 0, 0, 0.625, 0.6875,
        "Interface/Buttons/UI-Panel-Button-Disabled", 0, 0, 0.625, 0.6875)
    return b
end
core.CreateMeATextButton = CreateMeATextButton

local function CreateMeACustomTexButton(parent, width, height, tex, left, up, right, down)
    local b = CreateMeAButton(parent, width, height, nil,
    "Interface/Buttons/UI-EmptySlot", 9/64, 9/64, 54/64,54/64,
    "Interface/Buttons/UI-EmptySlot-White", 9/64, 9/64, 54/64,54/64,
    "Interface/Buttons/ButtonHilight-Square", 0, 0, 1, 1,
    "Interface/Buttons/UI-EmptySlot-Disabled", 9/64, 9/64, 54/64,54/64)
    --[[		"Interface/Buttons/UI-SILVER-BUTTON-UP", 9/64, 9/64, 54/64,54/64,
    "Interface/Buttons/UI-SILVER-BUTTON-Down", 0, 0, 0.625, 0.6875,
    "Interface/Buttons/ButtonHilight-Square", 0, 0, 1, 1,
    "Interface/Buttons/UI-SILVER-BUTTON-Disabled", 0, 0, 0.625, 0.6875)]]

    b:GetHighlightTexture():SetAlpha(0.8)

    if not tex then return b end

    --b.btex = b:CreateTexture(nil, "BACKGROUND")
    --b.btex:SetTexture("Interface/Buttons/UI-EmptySlot")
    --b.btex:SetTexCoord(9/64,  54/64, 9/64,  54/64)
    --b.btex:SetAllPoints()
    --b.btex:Hide()
    --local scale = -0.09
    --b.btex:SetPoint("TOPLEFT", b ,"TOPLEFT", -width*scale, height*scale)
    --b.btex:SetPoint("BOTTOMRIGHT", b ,"BOTTOMRIGHT", width*scale, -height*scale)


    b.ctex = b:CreateTexture(nil, "OVERLAY")
    b.ctex:SetTexture(tex)
    b.ctex:SetTexCoord(left, right, up, down)
    local scale = -0.14
    b.ctex:SetPoint("TOPLEFT", b ,"TOPLEFT", -width*scale, height*scale)
    b.ctex:SetPoint("BOTTOMRIGHT", b ,"BOTTOMRIGHT", width*scale, -height*scale)

    b.SetCustomTexture = function(self, tex, g, b, a)
        self.ctex:SetTexture(type(tex) == "string" and tex or tex, g, b, a)
    end
    
    --core.am(b.ctex:GetPoint(1))
    --ctex:SetAllPoints()	
    --b.ctex:SetBlendMode("BLEND")

    return b
end
core.CreateMeACustomTexButton = CreateMeACustomTexButton
