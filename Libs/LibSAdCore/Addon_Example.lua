local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.savedVarsGlobalName = "MyAddon_Settings_Global"
addon.savedVarsPerCharName = "MyAddon_Settings_Char"
addon.compartmentFuncName = "MyAddon_Compartment_Func"

function addon:LoadConfig()
    self.config.version = "1.0"
    self.author = "Rôkk-Wyrmrest Accord"

    -- Example - Add Settings to Main Settings Panel
    self.config.settings.main = {
        title = "exampleTitle",
        controls = {
            {
                type = "header",
                name = "exampleHeader"
            },
            {
                type = "checkbox",
                name = "exampleCheckbox",
                default = true,
                onValueChange = self.exampleCheckbox
            },
        }
    }

    -- Example - Add a New Child Settings Panel
    self.config.settings.examplePanel = {
        title = "examplePanelTitle",
        controls = {
            {
                type = "header",
                name = "examplePanelHeader"
            },            
            {
                type = "checkbox",
                name = "examplePanelCheckbox",
                default = true,
                onValueChange = self.examplePanelCheckbox
            },
        }
    }
end

function addon:exampleCheckbox(isChecked)
    self:debug(addonName .. ": " .. tostring(isChecked))
end

function addon:examplePanelCheckbox(isChecked)
    self:info("Checkbox changed to: " .. tostring(isChecked))
end

-- Combat-safe functions example
-- Initialize the CombatSafe table
addon.CombatSafe = addon.CombatSafe or {}

addon.CombatSafe.exampleCombatSafeFunction = function(self, message)
    -- This function can safely modify UI elements even if called during combat
    -- It will be queued automatically and executed when combat ends
    self:info("Combat-safe function executed: " .. message)
    return true
end

-- Localization
addon.locale = {}

addon.locale.enEN = {
    -- Main settings localization strings
    exampleTitle = "My Addon Settings",
    exampleHeader = "Example Settings",
    exampleCheckbox = "Example Checkbox on Main Settings",
    exampleCheckboxTooltip = "Tooltip for example checkbox control",

    -- Custom panel localization strings
    examplePanelTitle = "Example Panel Settings",
    examplePanelHeader = "Example Panel Header",
    examplePanelCheckbox = "Example Checbox on Custom Panel",
    examplePanelCheckboxTooltip = "Tooltip for checkbox on the custom panel",    
}
