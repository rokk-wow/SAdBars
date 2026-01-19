local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.savedVarsGlobalName = "SAdBars_Settings_Global"
addon.savedVarsPerCharName = "SAdBars_Settings_Char"
addon.compartmentFuncName = "SAdBars_Compartment_Func"
addon.actionBars = {
    { name = "MainMenuBar", frame = MainMenuBar, buttonPrefix = "ActionButton" },
    { name = "MultiBarBottomLeft", frame = MultiBarBottomLeft, buttonPrefix = "MultiBarBottomLeftButton" },
    { name = "MultiBarBottomRight", frame = MultiBarBottomRight, buttonPrefix = "MultiBarBottomRightButton" },
    { name = "MultiBarRight", frame = MultiBarRight, buttonPrefix = "MultiBarRightButton" },
    { name = "MultiBarLeft", frame = MultiBarLeft, buttonPrefix = "MultiBarLeftButton" },
    { name = "MultiBar5", frame = MultiBar5, buttonPrefix = "MultiBar5Button" },
    { name = "MultiBar6", frame = MultiBar6, buttonPrefix = "MultiBar6Button" },
    { name = "MultiBar7", frame = MultiBar7, buttonPrefix = "MultiBar7Button" },
}

addon.vars = addon.vars or {
    borderWidth = 1,
    borderColor = "000000FF",
    iconZoom = 0.1,
    buttonPadding = 2
}

addon.gcdButtons = {}

function addon:UpdateActionBars()
    self:CustomizeProcGlow()
    self:HideSpellActivationOverlay()
    self:AddActionButtonBorders()
    self:SetButtonPadding()
    self:HideMacroText()
    self:HideKeybindText()
    self:HideSpellCastAnimFrame()
    self:AddActionBarBackgrounds()
    self:UpdateAssistedHighlightVisibility()
    self:CustomizeAssistedHighlightGlow()
    self:ZoomButtonIcons()
    self:CustomizeCooldownFont()
    self:CreateCustomGCDFrames()
end

function addon:Initialize()
    self.config.version = "1.0"
    self.author = "Rôkk-Wyrmrest Accord"
    
    self:RegisterSlashCommand("debug", function()
        addon:BuildGCDButtonList()
    end)
    
    self:RegisterSlashCommand("offgcd", function()
        local count = 0
        for _ in pairs(addon.offGCDSpells) do
            count = count + 1
        end
        
        if count == 0 then
            print("SAdBars: No OFF-GCD spells in list.")
            return
        end
        
        print(string.format("SAdBars: OFF-GCD Spells (%d):", count))
        for spellID, spellName in pairs(addon.offGCDSpells) do
            print(string.format("  - %s (ID: %d)", spellName, spellID))
        end
    end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
        self:CombatSafe(function()
            self:UpdateActionBars()
        end)
    end)
    
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(...)
        local eventTable, eventName, unit, castGUID, spellID = ...
        
        if unit == "player" and spellID then
            addon:TriggerGCDAnimation(spellID)
        end
    end)
end

function addon:IterateActionButtons(callback)
    if type(callback) ~= "function" then return end
    
    for _, barInfo in ipairs(self.actionBars) do
        local prefix = barInfo.buttonPrefix
        for i = 1, 12 do
            local buttonName = prefix .. i
            local button = _G[buttonName]
            if button then
                callback(button, buttonName)
            end
        end
    end
end

function addon:IterateActionBars(callback)
    if type(callback) ~= "function" then return end
    
    for _, barInfo in ipairs(self.actionBars) do
        if barInfo.frame then
            callback(barInfo.frame, barInfo.name)
        end
    end
end

function addon:addBorder(bar, borderWidth, borderColor)
    if not bar then return end
    
    local size = borderWidth or addon.vars.borderWidth
    local colorHex = borderColor or addon.vars.borderColor
    local r, g, b, a = self:HexToRGB(colorHex)
    
    local borders = bar.SAdBars_Borders
    
    if borders then
        borders.top:SetColorTexture(r, g, b, a)
        borders.top:SetHeight(size)
        borders.bottom:SetColorTexture(r, g, b, a)
        borders.bottom:SetHeight(size)
        borders.left:SetColorTexture(r, g, b, a)
        borders.left:SetWidth(size)
        borders.right:SetColorTexture(r, g, b, a)
        borders.right:SetWidth(size)
    else
        borders = {}
        
        borders.top = bar:CreateTexture(nil, "OVERLAY")
        borders.top:SetColorTexture(r, g, b, a)
        borders.top:SetHeight(size)
        borders.top:ClearAllPoints()
        borders.top:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        borders.top:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
        
        borders.bottom = bar:CreateTexture(nil, "OVERLAY")
        borders.bottom:SetColorTexture(r, g, b, a)
        borders.bottom:SetHeight(size)
        borders.bottom:ClearAllPoints()
        borders.bottom:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        borders.bottom:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        
        borders.left = bar:CreateTexture(nil, "OVERLAY")
        borders.left:SetColorTexture(r, g, b, a)
        borders.left:SetWidth(size)
        borders.left:ClearAllPoints()
        borders.left:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        borders.left:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        
        borders.right = bar:CreateTexture(nil, "OVERLAY")
        borders.right:SetColorTexture(r, g, b, a)
        borders.right:SetWidth(size)
        borders.right:ClearAllPoints()
        borders.right:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
        borders.right:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        
        bar.SAdBars_Borders = borders
    end
end

function addon:CustomizeProcGlow()
    self:IterateActionButtons(function(button, buttonName)
        if button and button.SpellActivationAlert then
            button.SpellActivationAlert:Hide()
            button.SpellActivationAlert:SetAlpha(0)
            
            if not button.SpellActivationAlert.__SAdUI_HideHooked then
                button.SpellActivationAlert.__SAdUI_HideHooked = true
                hooksecurefunc(button.SpellActivationAlert, "Show", function(self)
                    self:Hide()
                    self:SetAlpha(0)
                end)
            end
        end
    end)
    
    if ActionButtonSpellAlertManager and not ActionButtonSpellAlertManager.__SAdUI_Hooked then
        ActionButtonSpellAlertManager.__SAdUI_Hooked = true
        hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(self, actionButton)
            if type(actionButton) ~= "table" then
                actionButton = self
            end
            
            if actionButton and actionButton.SpellActivationAlert then
                actionButton.SpellActivationAlert:Hide()
                actionButton.SpellActivationAlert:SetAlpha(0)
            end
        end)
    end
end

function addon:HideSpellActivationOverlay()
    if SpellActivationOverlayFrame then
        SpellActivationOverlayFrame:Hide()
        SpellActivationOverlayFrame:SetAlpha(0)
        
        hooksecurefunc(SpellActivationOverlayFrame, "Show", function(self)
            self:Hide()
            self:SetAlpha(0)
        end)
    end
end

function addon:AddActionButtonBorders()
    local function addButtonBorder(button, buttonName)
        if button then
            local normalTexture = button:GetNormalTexture()
            if normalTexture then
                normalTexture:SetAlpha(0)
                normalTexture:Hide()
            end
            
            if button.NormalTexture then
                button.NormalTexture:SetAlpha(0)
                button.NormalTexture:Hide()
            end
            
            addon:addBorder(button)
        end
    end
    
    self:IterateActionButtons(addButtonBorder)
end

function addon:SetButtonPadding()
    local padding = addon.vars.buttonPadding
    
    self:IterateActionBars(function(bar, name)
        if bar.SetAttribute then
            bar:SetAttribute("buttonSpacing", padding)
        end
        
        if bar.UpdateGridLayout then
            hooksecurefunc(bar, "UpdateGridLayout", function(self)
                if self.SetAttribute then
                    self:SetAttribute("buttonSpacing", padding)
                end
            end)
        end
        
        if bar.UpdateGridLayout then
            bar:UpdateGridLayout()
        elseif bar.Layout then
            bar:Layout()
        end
    end)
end

function addon:HideMacroText()
    local function hideButtonMacroText(button, buttonName)
        if button and button.Name then
            button.Name:SetAlpha(0)
            button.Name:Hide()
            hooksecurefunc(button.Name, "Show", function(self)
                self:SetAlpha(0)
            end)
        end
    end
    
    self:IterateActionButtons(hideButtonMacroText)
end

function addon:HideKeybindText()
    local function hideButtonKeybind(button, buttonName)
        if button and button.HotKey then
            button.HotKey:SetAlpha(0)
            button.HotKey:Hide()
            hooksecurefunc(button.HotKey, "Show", function(self)
                self:SetAlpha(0)
            end)
        end
    end
    
    self:IterateActionButtons(hideButtonKeybind)
end

function addon:HideSpellCastAnimFrame()
    local function hideButtonGlow(button)
        if button and button.SpellCastAnimFrame then
            button.SpellCastAnimFrame:SetAlpha(0)
            button.SpellCastAnimFrame:Hide()
            
            hooksecurefunc(button.SpellCastAnimFrame, "Show", function(self)
                self:SetAlpha(0)
            end)
            
            if button.SpellCastAnimFrame.Fill then
                button.SpellCastAnimFrame.Fill:SetAlpha(0)
                button.SpellCastAnimFrame.Fill:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.Fill, "Show", function(self)
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.InnerGlow then
                button.SpellCastAnimFrame.InnerGlow:SetAlpha(0)
                button.SpellCastAnimFrame.InnerGlow:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.InnerGlow, "Show", function(self)
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.FillMask then
                button.SpellCastAnimFrame.FillMask:SetAlpha(0)
                button.SpellCastAnimFrame.FillMask:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.FillMask, "Show", function(self)
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.Ants then
                button.SpellCastAnimFrame.Ants:SetAlpha(0)
                button.SpellCastAnimFrame.Ants:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.Ants, "Show", function(self)
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.Spark then
                button.SpellCastAnimFrame.Spark:SetAlpha(0)
                button.SpellCastAnimFrame.Spark:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.Spark, "Show", function(self)
                    self:SetAlpha(0)
                end)
            end
        end
        
        if button and button.InterruptDisplay then
            button.InterruptDisplay:SetAlpha(0)
            button.InterruptDisplay:Hide()
            hooksecurefunc(button.InterruptDisplay, "Show", function(self)
                self:SetAlpha(0)
            end)
            if button.InterruptDisplay.Base then
                button.InterruptDisplay.Base:SetAlpha(0)
                button.InterruptDisplay.Base:Hide()
            end
            if button.InterruptDisplay.Highlight then
                button.InterruptDisplay.Highlight:SetAlpha(0)
                button.InterruptDisplay.Highlight:Hide()
            end
        end
        
        if button then
            local checkedTexture = button:GetCheckedTexture()
            if checkedTexture then
                checkedTexture:SetAlpha(0)
                checkedTexture:Hide()
            end
            hooksecurefunc(button, "SetChecked", function(self)
                if self:GetChecked() then
                    local tex = self:GetCheckedTexture()
                    if tex then
                        tex:SetAlpha(0)
                        tex:Hide()
                    end
                end
            end)
        end
    end
    
    self:IterateActionButtons(function(button, buttonName)
        hideButtonGlow(button)
    end)
end

function addon:AddActionBarBackgrounds()
    self:IterateActionBars(function(bar, name)
        if bar.GetSettingValueBool then
            local alwaysShowButtons = bar:GetSettingValueBool(9)
            
            if alwaysShowButtons and not bar.SAdUI_Background then
                local bg = bar:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(bar)
                bg:SetColorTexture(0, 0, 0, 0.5)
                bar.SAdUI_Background = bg
            end
        end
    end)
end

function addon:UpdateAssistedHighlightVisibility()
    local inCombat = UnitAffectingCombat("player")
    
    self:IterateActionButtons(function(button, buttonName)
        if button.AssistedCombatHighlightFrame then
            local highlightFrame = button.AssistedCombatHighlightFrame
            if not inCombat then
                highlightFrame:Hide()
            end
        end
    end)
end

function addon:CustomizeAssistedHighlightGlow()
    local function UpdateAssistedHighlight(actionButton, shown)
        local highlightFrame = actionButton.AssistedCombatHighlightFrame
        local inCombat = UnitAffectingCombat("player")
        
        if highlightFrame and highlightFrame:IsVisible() and shown and inCombat then
            local flipbook = highlightFrame.Flipbook
            if flipbook then
                flipbook:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
                flipbook:SetDesaturated(true)
                flipbook:SetVertexColor(1.0, 0.0, 1.0, 1.0) -- Magenta
                
                local anim = flipbook.Anim:GetAnimations()
                if anim then
                    flipbook:ClearAllPoints()
                    flipbook:SetSize(flipbook:GetSize())
                    flipbook:SetPoint("CENTER", highlightFrame, "CENTER", -1.5, 1)
                    
                    flipbook.Anim:Stop()
                    flipbook.Anim:Play()
                end
            end
        elseif highlightFrame and not inCombat then
            highlightFrame:Hide()
        end
    end
    
    if AssistedCombatManager then
        hooksecurefunc(AssistedCombatManager, "SetAssistedHighlightFrameShown", function(self, actionButton, shown)
            UpdateAssistedHighlight(actionButton, shown)
        end)
    end
end

function addon:ZoomButtonIcons()
    local zoom = addon.vars.iconZoom
    local inset = zoom / 2
    
    local function zoomButtonIcon(button, buttonName)
        if button and button.icon then
            button.icon:SetTexCoord(inset, 1 - inset, inset, 1 - inset)
            
            if button.cooldown then
                button.cooldown:ClearAllPoints()
                button.cooldown:SetAllPoints(button)
            end
        end
    end
    
    self:IterateActionButtons(zoomButtonIcon)
end

function addon:CustomizeCooldownFont()
    local function adjustCooldownFont(button, buttonName)
        if button and button.cooldown then
            for _, region in pairs({button.cooldown:GetRegions()}) do
                if region:GetObjectType() == "FontString" then
                    local font, _, flags = region:GetFont()
                    if font then
                        region:SetFont(font, 20, flags)
                    end
                end
            end
            
            if not button.cooldown.__SAdBars_FontHooked then
                button.cooldown.__SAdBars_FontHooked = true
                hooksecurefunc(button.cooldown, "SetCooldown", function(self)
                    for _, region in pairs({self:GetRegions()}) do
                        if region:GetObjectType() == "FontString" then
                            local font, _, flags = region:GetFont()
                            if font then
                                region:SetFont(font, 20, flags)
                            end
                        end
                    end
                end)
            end
        end
    end
    
    self:IterateActionButtons(adjustCooldownFont)
end

























function addon:DetectGCDSpell(spellID)
    if not spellID then return nil end
    
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then return nil end
    
    local gcdInfo = C_Spell.GetSpellCooldown(61304)
    local isOnGCD = gcdInfo and gcdInfo.duration > 0
    
    return isOnGCD
end

-- Static list of OFF-GCD spells: [spellID] = "SpellName"
addon.offGCDSpells = {
    [116849] = "Life Cocoon",
}

-- Buttons that should show GCD swipe
addon.gcdEnabledButtons = {
    ["ActionButton3"] = true,
    ["ActionButton4"] = true,
    ["ActionButton6"] = true,
    ["ActionButton7"] = true,
    ["ActionButton8"] = true,
    ["MultiBarBottomLeftButton1"] = true,
    ["MultiBarBottomLeftButton5"] = true,
    ["MultiBarBottomLeftButton6"] = true,
    ["MultiBarBottomLeftButton7"] = true,
    ["MultiBarBottomLeftButton9"] = true,
    ["MultiBarBottomLeftButton10"] = true,
    ["MultiBarBottomLeftButton11"] = true,
    ["MultiBarBottomLeftButton12"] = true,
}

function addon:CreateCustomGCDFrames()
    local function createGCDFrame(button, buttonName)
        if button and not button.SAdBars_GCDCooldown then
            local gcdCooldown = CreateFrame("Cooldown", buttonName .. "_SAdBars_GCD", button, "CooldownFrameTemplate")
            gcdCooldown:SetAllPoints(button)
            gcdCooldown:SetDrawSwipe(true)
            gcdCooldown:SetDrawEdge(true)
            gcdCooldown:SetDrawBling(false)
            gcdCooldown:SetSwipeColor(0, 0, 0, 0.8)
            gcdCooldown:SetHideCountdownNumbers(true)
            gcdCooldown:SetFrameStrata("HIGH")
            gcdCooldown:SetFrameLevel(button:GetFrameLevel() + 10)
            gcdCooldown:Show()
            button.SAdBars_GCDCooldown = gcdCooldown
        end
    end
    
    self:IterateActionButtons(createGCDFrame)
end

function addon:TriggerGCDAnimation(spellID)
    if not spellID then return end
    
    if addon.offGCDSpells[spellID] then return end

    local gcdInfo = C_Spell.GetSpellCooldown(61304)
    
    if not gcdInfo or gcdInfo.duration == 0 then
        return
    end
    
    local startTime = gcdInfo.startTime
    local gcdDuration = gcdInfo.duration
    
    self:IterateActionButtons(function(button, buttonName)
        if button and button.SAdBars_GCDCooldown and button.action and addon.gcdEnabledButtons[buttonName] then
            local actionType, actionID = GetActionInfo(button.action)
            
            if actionType == "spell" or actionType == "macro" then
                button.SAdBars_GCDCooldown:SetCooldown(startTime, gcdDuration)
            end
        end
    end)
end
