local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.savedVarsGlobalName = "MyAddon_Settings_Global"
addon.savedVarsPerCharName = "MyAddon_Settings_Char"
addon.compartmentFuncName = "MyAddon_Compartment_Func"

function addon:Initialize()
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
    self:Debug(addonName .. ": " .. tostring(isChecked))
end

function addon:examplePanelCheckbox(isChecked)
    self:Info("Checkbox changed to: " .. tostring(isChecked))
end

-- Combat-safe function example
function addon:exampleCombatSafeAction()
    self:CombatSafe(function()
        self:Info("This action is queued during combat, executed after.")
    end)
end

-- Localization
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
