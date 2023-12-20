---@class ConstructionSettingsDialog : MessageDialog
---@field isFirstTime boolean
---@field settings ConstructionSettings
---@field hasChanged boolean
---@field boxLayout ScrollingLayoutElement
---@field layoutOption LayoutOptionElement
---@field soundOption CheckedOptionElement
---@field notificationsOption CheckedOptionElement
---@field applyButton ButtonElement
---@field requireFarmAccessOption CheckedOptionElement
---@field enableBuyingPalletsOption CheckedOptionElement
---
---@field superClass fun(): MessageDialog
ConstructionSettingsDialog = {}

ConstructionSettingsDialog.CLASS_NAME = 'ConstructionSettingsDialog'
ConstructionSettingsDialog.XML_FILENAME = g_currentModDirectory .. 'xml/gui/dialogs/ConstructionSettingsDialog.xml'
ConstructionSettingsDialog.CONTROLS = {
    'boxLayout',
    'applyButton',
    'layoutOption',
    'soundOption',
    'notificationsOption',

    'requireFarmAccessOption',

    'enableVisitButtonOption',
    'enablePriceOverrideOption',
    'enableHotspotsOption',
    'enableBuyingPalletsOption',
    'enableHotspotsWhenCompletedOption'
}

local ConstructionSettingsDialog_mt = Class(ConstructionSettingsDialog, MessageDialog)

function ConstructionSettingsDialog.new()
    ---@type ConstructionSettingsDialog
    local self = MessageDialog.new(nil, ConstructionSettingsDialog_mt)

    self:registerControls(ConstructionSettingsDialog.CONTROLS)

    self.isFirstTime = true
    self.hasChanged = false
    ---@diagnostic disable-next-line: missing-fields
    self.settings = {}

    g_messageCenter:subscribe(MessageType.CONSTRUCTION_SETTINGS_CHANGED, self.onSettingsChanged, self)

    return self
end

function ConstructionSettingsDialog:load()
    g_gui:loadGui(ConstructionSettingsDialog.XML_FILENAME, ConstructionSettingsDialog.CLASS_NAME, self)
end

function ConstructionSettingsDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[ConstructionSettingsDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function ConstructionSettingsDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)
end

function ConstructionSettingsDialog:onOpen()
    self:superClass().onOpen(self)

    ---@diagnostic disable-next-line: assign-type-mismatch
    self.settings = table.copy(g_construction.settings)
    self.hasChanged = false

    self.layoutOption:setState(g_construction:getHudPosition())
    self.soundOption:setIsChecked(g_construction:getIsSoundEnabled())
    self.notificationsOption:setIsChecked(g_construction:getIsNotificationsEnabled())

    self:updateSettings()
    self:updateMenuButtons()

    if self.isFirstTime then
        self.enableBuyingPalletsOption:setVisible(g_modIsLoaded[Construction.MOD_NAME_PRODUCTS] == true)
        self.isFirstTime = false
    end

    if g_construction:getIsMultiplayer() then
        self.requireFarmAccessOption:setDisabled(not g_construction:getCanModifySettings())
    else
        self.requireFarmAccessOption:setDisabled(true)
    end

    self.boxLayout:invalidateLayout()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == ConstructionSettingsDialog.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function ConstructionSettingsDialog:onSettingsChanged()
    if self.isOpen then
        self:updateSettings()

        self.boxLayout:invalidateLayout()

        self.hasChanged = false
        self:updateMenuButtons()
    end
end

function ConstructionSettingsDialog:updateSettings()
    local canModifySettings = g_construction:getCanModifySettings()

    for name, value in pairs(self.settings) do
        ---@type CheckedOptionElement | nil
        local element = self[name .. 'Option']

        if element ~= nil then
            element:setIsChecked(value)

            if element.disabled ~= not canModifySettings then
                element:setDisabled(not canModifySettings)
            end
        end
    end
end

function ConstructionSettingsDialog:updateMenuButtons()
    self.applyButton:setVisible(self.hasChanged)
end

function ConstructionSettingsDialog:onClickApplyButton()
    if g_construction:getCanModifySettings() then
        if g_server ~= nil then
            ---@diagnostic disable-next-line: param-type-mismatch
            g_construction:updateSettings(self.settings)
        else
            SetConstructionSettingsEvent.sendEvent(self.settings)
        end
    end
end

---@param state number
---@param element CheckedOptionElement
function ConstructionSettingsDialog:onClickOption(state, element)
    if element.name ~= nil and self.settings[element.name] ~= nil then
        self.settings[element.name] = state == CheckedOptionElement.STATE_CHECKED

        self.hasChanged = true
        self:updateMenuButtons()
    end
end

function ConstructionSettingsDialog:onClickLayoutOption(state)
    g_construction:setHudPosition(state)
end

function ConstructionSettingsDialog:onClickSoundOption(state)
    g_construction:setIsSoundEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

function ConstructionSettingsDialog:onClickNotificationsOption(state)
    g_construction:setIsNotificationsEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

function ConstructionSettingsDialog:show()
    g_gui:showDialog(ConstructionSettingsDialog.CLASS_NAME)
end
