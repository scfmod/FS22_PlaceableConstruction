-- Register new message types
MessageType.CONSTRUCTION_SETTINGS_CHANGED = nextMessageTypeId()
MessageType.CONSTRUCTION_PLACEABLE_ADDED = nextMessageTypeId()
MessageType.CONSTRUCTION_PLACEABLE_REMOVED = nextMessageTypeId()
MessageType.CONSTRUCTION_STARTED = nextMessageTypeId()
MessageType.CONSTRUCTION_COMPLETED = nextMessageTypeId()
MessageType.GUI_INGAME_OPEN_CONSTRUCTIONS_SCREEN = nextMessageTypeId()

local modSettingsFolder = g_currentModSettingsDirectory

---@class Construction
---@field placeables PlaceableConstruction[]
---@field modName string
---@field modFolder string
---@field settings ConstructionSettings
---@field userSettings ConstructionUserSettings
Construction = {}

Construction.STATE_PREVIEW = 'PREVIEW'
Construction.STATE_ACTIVE = 'ACTIVE'
Construction.STATE_PROCESSING = 'PROCESSING'
Construction.STATE_COMPLETED = 'COMPLETED'

Construction.NOTIFICATION_L10N = {
    CONSTRUCTION_STARTED = g_i18n:getText('ui_notificationTitleConstructionStarted'),
    CONSTRUCTION_COMPLETED = g_i18n:getText('ui_notificationTitleConstructionCompleted'),
}

---@enum HUDPosition
Construction.HUD_POSITION = {
    LEFT = 1,
    TOP = 2,
    RIGHT = 3
}

---@type table<HUDPosition, string>
Construction.HUD_POSITION_PROFILE = {
    [Construction.HUD_POSITION.LEFT] = 'constructionHud_layoutLeft',
    [Construction.HUD_POSITION.TOP] = 'constructionHud_layoutTop',
    [Construction.HUD_POSITION.RIGHT] = 'constructionHud_layout'
}

---@type table<HUDPosition, table>
Construction.HUD_POSITION_ICON_UVS = {
    [Construction.HUD_POSITION.LEFT] = GuiUtils.getUVs("0 0.25 0.25 0.25"),
    [Construction.HUD_POSITION.TOP] = GuiUtils.getUVs("0.25 0.25 0.25 0.25"),
    [Construction.HUD_POSITION.RIGHT] = GuiUtils.getUVs("0.5 0.25 0.25 0.25")
}

Construction.USER_SETTINGS_FILE = g_currentModSettingsDirectory .. 'userSettings.xml'

-- TODO: if needed
Construction.MOD_NAME_PRODUCTS = 'FS22_1_ConstructionProducts'

Construction.xmlSettingsSchema = (function()
    ---@type XMLSchema
    local schema = XMLSchema.new('constructionSettings')

    schema:register(XMLValueType.BOOL, 'settings.requireFarmAccess')

    schema:register(XMLValueType.BOOL, 'settings.enableVisitButton')
    schema:register(XMLValueType.BOOL, 'settings.enablePriceOverride')
    schema:register(XMLValueType.BOOL, 'settings.enableHotspots')
    schema:register(XMLValueType.BOOL, 'settings.enableBuyingPallets')
    schema:register(XMLValueType.BOOL, 'settings.enableHotspotsWhenCompleted')

    return schema
end)()

Construction.xmlUserSettingsSchema = (function()
    ---@type XMLSchema
    local schema = XMLSchema.new('constructionUserSettings')

    schema:register(XMLValueType.INT, 'userSettings.hudPosition')
    schema:register(XMLValueType.BOOL, 'userSettings.enableSound')
    schema:register(XMLValueType.BOOL, 'userSettings.enableNotifications')

    return schema
end)()

local Construction_mt = Class(Construction)

---@nodiscard
---@return Construction
function Construction.new()
    ---@type Construction
    local self = setmetatable({}, Construction_mt)

    self.placeables = {}
    self.modName = g_currentModName
    self.modFolder = g_currentModDirectory

    self.settings = {
        requireFarmAccess = true,

        enableVisitButton = true,
        enablePriceOverride = true,
        enableHotspots = true,
        enableBuyingPallets = true,
        enableHotspotsWhenCompleted = true
    }

    self.userSettings = {
        hudPosition = Construction.HUD_POSITION.RIGHT,
        enableSound = true,
        enableNotifications = true
    }

    if g_debugConstruction then
        addConsoleCommand('csNextState', '', 'consoleNextState', self)
        addConsoleCommand('csDeliverAll', '', 'consoleDeliverAllInputs', self)
        addConsoleCommand('csDeliverInput', '', 'consoleDeliverInput', self)
    end

    g_messageCenter:subscribe(MessageType.CONSTRUCTION_SETTINGS_CHANGED, self.onSettingsChanged, self)
    g_messageCenter:subscribe(MessageType.CONSTRUCTION_STARTED, self.onConstructionStarted, self)
    g_messageCenter:subscribe(MessageType.CONSTRUCTION_COMPLETED, self.onConstructionCompleted, self)

    return self
end

function Construction:debug(message, ...)
    if g_debugConstruction then
        print(string.format("  Debug: " .. message, ...))
    end
end

---@param placeable PlaceableConstruction
function Construction:register(placeable)
    table.insert(self.placeables, placeable)

    g_messageCenter:publish(MessageType.CONSTRUCTION_PLACEABLE_ADDED, placeable)
end

---@param placeable PlaceableConstruction
function Construction:unregister(placeable)
    if table.removeElement(self.placeables, placeable) then
        g_messageCenter:publish(MessageType.CONSTRUCTION_PLACEABLE_REMOVED, placeable)
    end
end

---@nodiscard
---@return boolean
function Construction:getIsMasterUser()
    return g_currentMission.isMasterUser
end

---@nodiscard
---@return boolean
function Construction:getCanModifySettings()
    if self:getIsMultiplayer() then
        return self:getIsMasterUser()
    end

    return true
end

---@nodiscard
---@return PlaceableConstruction[]
function Construction:getPlaceables()
    if not self:getRequireFarmAccess() then
        return self.placeables
    end

    ---@param placeable PlaceableConstruction
    local filterFunc = function(placeable)
        return ConstructionUtils.getPlayerHasAccess(placeable)
    end

    return table.filter(self.placeables, filterFunc)
end

---@nodiscard
---@return boolean
function Construction:getIsSoundEnabled()
    return self.userSettings.enableSound
end

---@param enabled boolean
function Construction:setIsSoundEnabled(enabled)
    if self.userSettings.enableSound ~= enabled then
        self.userSettings.enableSound = enabled

        self:saveUserSettings()
    end
end

---@param enabled boolean
function Construction:setIsNotificationsEnabled(enabled)
    if self.userSettings.enableNotifications ~= enabled then
        self.userSettings.enableNotifications = enabled

        self:saveUserSettings()
    end
end

---@nodiscard
---@return HUDPosition
function Construction:getHudPosition()
    return self.userSettings.hudPosition
end

---@param position HUDPosition
function Construction:setHudPosition(position)
    if self.userSettings.hudPosition ~= position then
        self.userSettings.hudPosition = position

        g_constructionHud:updatePosition()

        self:saveUserSettings()
    end
end

---
--- Whether to enable visit button in GUI + hotspot or not.
---
---@nodiscard
---@return boolean
function Construction:getIsVisitButtonEnabled()
    return self.settings.enableVisitButton
end

---
--- Whether to enable construction price override or not.
---
---@nodiscard
---@return boolean
function Construction:getIsPriceOverrideEnabled()
    return self.settings.enablePriceOverride
end

---
--- Whether to enable construction hotspots or not.
---
---@nodiscard
---@return boolean
function Construction:getIsHotspotsEnabled()
    return self.settings.enableHotspots
end

---
--- Specific setting for pallets mod [TBD]
---
---@nodiscard
---@return boolean
function Construction:getIsBuyingPalletsEnabled()
    return self.settings.enableBuyingPallets
end

---
--- Whether to show construction hotspots when construction
--- is completed or not.
---
---@nodiscard
---@return boolean
function Construction:getIsHotspotsEnabledWhenCompleted()
    return self.settings.enableHotspotsWhenCompleted
end

---@nodiscard
---@return boolean
function Construction:getIsNotificationsEnabled()
    return self.userSettings.enableNotifications
end

---@nodiscard
---@return boolean
function Construction:getIsMultiplayer()
    if g_currentMission ~= nil and g_currentMission.missionDynamicInfo ~= nil then
        return g_currentMission.missionDynamicInfo.isMultiplayer
    end

    return false
end

---@nodiscard
---@return boolean
function Construction:getRequireFarmAccess()
    return self.settings.requireFarmAccess
end

---@return string
function Construction:consoleNextState()
    local placeable = g_constructionHud:getPlaceable()

    if placeable ~= nil then
        if placeable:getConstructionIsCompleted() then
            return 'Construction already completed'
        end

        local state = placeable:getActiveConstructionState()

        if g_server ~= nil then
            placeable:setConstructionStateIndex(state.index + 1)

            return string.format('Changing state index from %i to %i', state.index, state.index + 1)
        else
            SetConstructionStateRequestEvent.sendEvent(state.index + 1, placeable)

            return string.format('Request sent to server to change state index from %i to %i', state.index, state.index + 1)
        end
    end

    return 'No active construction (HUD)'
end

---@return string
function Construction:consoleDeliverInput(index, pct)
    if g_server == nil then
        return 'Only available server side'
    end

    if index == nil then
        return 'Usage: csDeliverInput <index> [<percentage 0..1>]'
    end

    pct = pct or '1'
    pct = MathUtil.clamp(tonumber(pct), 0, 1)
    index = tonumber(index)

    local placeable = g_constructionHud:getPlaceable()

    if placeable ~= nil then
        local state = placeable:getActiveConstructionState()
        local input = state:getInputs()[index]

        if input == nil then
            return string.format('Invalid input index: %s', tostring(index))
        end

        input.deliveredAmount = MathUtil.clamp(input.amount * pct, input.deliveredAmount, input.amount)
        input:raiseDirtyFlag()

        state:updateTotals()

        return string.format('Set input delivered amount to: %.2f', input.deliveredAmount)
    end

    return 'No active construction (HUD)'
end

function Construction:consoleDeliverAllInputs()
    if g_server == nil then
        return 'Only available server side'
    end

    local placeable = g_constructionHud:getPlaceable()

    if placeable ~= nil then
        local state = placeable:getActiveConstructionState()

        if not state:getIsAwaitingDelivery() then
            return 'No inputs awaiting delivery'
        end

        for _, input in ipairs(state:getInputs()) do
            input.deliveredAmount = input.amount
            input:raiseDirtyFlag()
        end

        state:updateTotals()

        return 'Delivered to all inputs'
    end

    return 'No active construction (HUD)'
end

---@param title string | nil
---@param message string
---@param duration number | nil
function Construction:showNotification(title, message, duration)
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, title .. ' ' .. message)
end

---@param previous ConstructionSettings
function Construction:onSettingsChanged(previous)
    if self:getIsBuyingPalletsEnabled() ~= previous.enableBuyingPallets then
        ConstructionUtils.updatePalletStoreItems()
    end
end

---@param placeable PlaceableConstruction
function Construction:onConstructionStarted(placeable)
    ---@type ConstructionSpecialization
    local spec = placeable[PlaceableConstruction.SPEC_NAME]

    if placeable.isClient and not spec.isLoadingFromSavegame and self:getIsNotificationsEnabled() and ConstructionUtils.getPlayerHasAccess(placeable) then
        local message = placeable:getName()

        if self:getIsMultiplayer() and (self:getIsMasterUser() or not self:getRequireFarmAccess() or placeable:getOwnerFarmId() == FarmManager.SPECTATOR_FARM_ID) then
            message = message .. ' (' .. placeable:getOwnerFarmName() .. ')'
        end

        self:showNotification(Construction.NOTIFICATION_L10N.CONSTRUCTION_STARTED, message)
    end
end

---@param placeable PlaceableConstruction
function Construction:onConstructionCompleted(placeable)
    ---@type ConstructionSpecialization
    local spec = placeable[PlaceableConstruction.SPEC_NAME]

    if placeable.isClient and not spec.isLoadingFromSavegame and self:getIsNotificationsEnabled() and ConstructionUtils.getPlayerHasAccess(placeable) then
        local message = placeable:getName()

        if self:getIsMultiplayer() and (self:getIsMasterUser() or not self:getRequireFarmAccess() or placeable:getOwnerFarmId() == FarmManager.SPECTATOR_FARM_ID) then
            message = message .. ' (' .. placeable:getOwnerFarmName() .. ')'
        end

        self:showNotification(Construction.NOTIFICATION_L10N.CONSTRUCTION_COMPLETED, message)
    end
end

---@param settings ConstructionSettings
---@param noEventSend boolean | nil
function Construction:updateSettings(settings, noEventSend)
    if settings ~= nil then
        local previous = self.settings

        self.settings = table.copy(settings)

        SetConstructionSettingsEvent.sendEvent(self.settings, noEventSend)

        g_messageCenter:publish(MessageType.CONSTRUCTION_SETTINGS_CHANGED, previous)
    end
end

function Construction:saveSettings()
    if g_server ~= nil then
        local xmlFilename = g_currentMission.missionInfo.savegameDirectory .. '/constructionSettings.xml'

        ---@type XMLFile | nil
        local xmlFile = XMLFile.create('constructionSettings_tmp', xmlFilename, 'settings', Construction.xmlSettingsSchema)

        if xmlFile ~= nil then
            xmlFile:setValue('settings.requireFarmAccess', self.settings.requireFarmAccess)

            xmlFile:setValue('settings.enableVisitButton', self.settings.enableVisitButton)
            xmlFile:setValue('settings.enablePriceOverride', self.settings.enablePriceOverride)
            xmlFile:setValue('settings.enableHotspots', self.settings.enableHotspots)
            xmlFile:setValue('settings.enableBuyingPallets', self.settings.enableBuyingPallets)
            xmlFile:setValue('settings.enableHotspotsWhenCompleted', self.settings.enableHotspotsWhenCompleted)

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function Construction:loadSettings()
    if g_server ~= nil then
        if g_currentMission.missionInfo.savegameDirectory ~= nil then
            local xmlFilename = g_currentMission.missionInfo.savegameDirectory .. '/constructionSettings.xml'

            ---@type XMLFile | nil
            local xmlFile = XMLFile.loadIfExists('constructionSettings_tmp', xmlFilename, Construction.xmlSettingsSchema)

            if xmlFile ~= nil then
                self.settings.requireFarmAccess = xmlFile:getValue('settings.requireFarmAccess', self.settings.requireFarmAccess)

                self.settings.enableVisitButton = xmlFile:getValue('settings.enableVisitButton', self.settings.enableVisitButton)
                self.settings.enablePriceOverride = xmlFile:getValue('settings.enablePriceOverride', self.settings.enablePriceOverride)
                self.settings.enableHotspots = xmlFile:getValue('settings.enableHotspots', self.settings.enableHotspots)
                self.settings.enableBuyingPallets = xmlFile:getValue('settings.enableBuyingPallets', self.settings.enableBuyingPallets)
                self.settings.enableHotspotsWhenCompleted = xmlFile:getValue('settings.enableHotspotsWhenCompleted', self.settings.enableHotspotsWhenCompleted)

                xmlFile:delete()

                return
            end
        end
    end
end

function Construction:saveUserSettings()
    if g_client ~= nil then
        createFolder(modSettingsFolder)

        ---@type XMLFile |nil
        local xmlFile = XMLFile.create('constructionUserSettings_tmp', Construction.USER_SETTINGS_FILE, 'userSettings', Construction.xmlUserSettingsSchema)

        if xmlFile ~= nil then
            xmlFile:setValue('userSettings.hudPosition', self:getHudPosition())
            xmlFile:setValue('userSettings.enableSound', self:getIsSoundEnabled())
            xmlFile:setValue('userSettings.enableNotifications', self:getIsNotificationsEnabled())

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function Construction:loadUserSettings()
    if g_client ~= nil then
        ---@type XMLFile | nil
        local xmlFile = XMLFile.loadIfExists('constructionUserSettings_tmp', Construction.USER_SETTINGS_FILE, Construction.xmlUserSettingsSchema)

        if xmlFile ~= nil then
            self.userSettings.hudPosition = xmlFile:getValue('userSettings.hudPosition', self.userSettings.hudPosition)
            self.userSettings.enableSound = xmlFile:getValue('userSettings.enableSound', self.userSettings.hudPosition)
            self.userSettings.enableNotifications = xmlFile:getValue('userSettings.enableNotifications', self.userSettings.enableNotifications)

            xmlFile:delete()
        end
    end
end

function Construction:loadMap()
    self:loadSettings()
end

---@diagnostic disable-next-line: lowercase-global
g_construction = Construction.new()

if g_server ~= nil then
    addModEventListener(g_construction)
end
