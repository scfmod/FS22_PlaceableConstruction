-- Register new message types
MessageType.CONSTRUCTION_SETTINGS_CHANGED = nextMessageTypeId()
MessageType.CONSTRUCTION_PLACEABLE_ADDED = nextMessageTypeId()
MessageType.CONSTRUCTION_PLACEABLE_REMOVED = nextMessageTypeId()
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

---@type table<string, table>
Construction.STATUS_ICON_UVS = {
    [Construction.STATE_ACTIVE] = GuiUtils.getUVs("0 0 0.25 0.25"),
    [Construction.STATE_PROCESSING] = GuiUtils.getUVs("0.25 0 0.25 0.25"),
    [Construction.STATE_COMPLETED] = GuiUtils.getUVs("0.5 0 0.25 0.25")
}

---@type table<string, string>
Construction.STATUS_L10N = {
    [Construction.STATE_ACTIVE] = g_i18n:getText('ui_constructionActive'),
    [Construction.STATE_PROCESSING] = g_i18n:getText('ui_constructionProcessing'),
    [Construction.STATE_COMPLETED] = g_i18n:getText('ui_constructionCompleted')
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

    schema:register(XMLValueType.BOOL, 'settings.requireActivatePermission')
    schema:register(XMLValueType.BOOL, 'settings.requireHudPermission')
    schema:register(XMLValueType.BOOL, 'settings.requirePlaceablePermission')
    schema:register(XMLValueType.BOOL, 'settings.requireHotspotPermission')

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

    return schema
end)()

local Construction_mt = Class(Construction)

function Construction.new()
    ---@type Construction
    local self = setmetatable({}, Construction_mt)

    self.placeables = {}
    self.modName = g_currentModName
    self.modFolder = g_currentModDirectory

    self.settings = {
        requireActivatePermission = true,
        requireHudPermission = false,
        requirePlaceablePermission = true,
        requireHotspotPermission = true,

        enableVisitButton = true,
        enablePriceOverride = true,
        enableHotspots = true,
        enableBuyingPallets = true,
        enableHotspotsWhenCompleted = true
    }

    self.userSettings = {
        hudPosition = Construction.HUD_POSITION.RIGHT,
        enableSound = true
    }

    if g_debugConstruction then
        addConsoleCommand('csNextState', '', 'consoleNextState', self)
        addConsoleCommand('csDeliverAll', '', 'consoleDeliverAllInputs', self)
        addConsoleCommand('csDeliverInput', '', 'consoleDeliverInput', self)
    end

    g_messageCenter:subscribe(MessageType.CONSTRUCTION_SETTINGS_CHANGED, self.onSettingsChanged, self)

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

---@return boolean
function Construction:getIsMasterUser()
    return g_currentMission.isMasterUser
end

function Construction:getCanModifySettings()
    if g_server ~= nil then
        return true
    elseif g_currentMission ~= nil and g_currentMission.missionDynamicInfo ~= nil then
        return not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission.isMasterUser
    end

    return false
end

function Construction:getPlaceables()
    local playerFarmId = g_currentMission:getFarmId()

    if playerFarmId == FarmManager.SPECTATOR_FARM_ID then
        return {}
    elseif self:getIsMasterUser() or not self:getPlaceableRequiresPermission() then
        return self.placeables
    end

    ---@param placeable PlaceableConstruction
    local filterFunc = function(placeable)
        return placeable:getOwnerFarmId() == playerFarmId
    end

    return table.filter(self.placeables, filterFunc)
end

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

--[[
    Whether players can only use material delivery activation
    for constructions owned by farm or not. [FarmId | All]
--]]
function Construction:getActivateRequiresPermission()
    return self.settings.requireActivatePermission
end

--[[
    Whether players can only see HUD for constructions
    owned by farm or not. [FarmId | All]
--]]
function Construction:getHudRequiresPermission()
    return self.settings.requireHudPermission
end

--[[
    Whether players can only see constructions in menu
    owned by farm or not. [FarmId | All]
--]]
function Construction:getPlaceableRequiresPermission()
    return self.settings.requirePlaceablePermission
end

--[[
    Whether players can only see hotspots for constructions
    owned by farm or not. [FarmId | All]
--]]
function Construction:getHotspotRequiresPermission()
    return self.settings.requireHotspotPermission
end

--[[
    Whether to enable visit button in GUI or not.
]]
function Construction:getIsVisitButtonEnabled()
    return self.settings.enableVisitButton
end

--[[
    Whether to enable construction price override or not.
]]
function Construction:getIsPriceOverrideEnabled()
    return self.settings.enablePriceOverride
end

--[[
    Whether to enable construction hotspots or not.
]]
function Construction:getIsHotspotsEnabled()
    return self.settings.enableHotspots
end

--[[
    Specific setting for pallets mod [TBD]
]]
function Construction:getIsBuyingPalletsEnabled()
    return self.settings.enableBuyingPallets
end

--[[
    Whether to show construction hotspots when construction
    is completed or not.
]]
function Construction:getIsHotspotsEnabledWhenCompleted()
    return self.settings.enableHotspotsWhenCompleted
end

---@return string
function Construction:consoleNextState()
    local placeable = g_constructionHud:getPlaceable()

    if placeable ~= nil then
        if placeable:getIsCompleted() then
            return 'Construction already completed'
        end

        local state = placeable:getActiveState()

        if g_server ~= nil then
            placeable:setStateIndex(state.index + 1)

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
        local state = placeable:getActiveState()
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
        local state = placeable:getActiveState()

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

-- ---@return string
-- function Construction:consoleDeliver_old(pct, fillAll)
--     local placeable = g_constructionHud:getPlaceable()

--     pct = pct or '1'
--     pct = MathUtil.clamp(tonumber(pct), 0, 1)

--     if placeable ~= nil then
--         local state = placeable:getActiveState()

--         if state:getIsAwaitingDelivery() then
--             if g_server ~= nil then
--                 for _, input in ipairs(state:getInputs()) do
--                     input.deliveredAmount = input.amount * pct
--                     input:raiseDirtyFlag()

--                     if fillAll == 'false' then
--                         break
--                     end
--                 end

--                 state:updateTotals()

--                 return string.format('Updated inputs (%.0f delivered of %.0f total amount)', state.totalDeliveredAmount, state.totalAmount)
--                 -- else
--                 --     ConstructionDeliveryRequestEvent.sendEvent(placeable)

--                 --     return 'Request sent to server'
--             end
--         else
--             return 'Materials already delivered'
--         end
--     end

--     return 'No active construction (HUD)'
-- end

---@param previous ConstructionSettings
function Construction:onSettingsChanged(previous)
    if self:getIsBuyingPalletsEnabled() ~= previous.enableBuyingPallets then
        ConstructionUtils.updatePalletStoreItems()
    end
end

---@param settings ConstructionSettings
---@param noEventSend boolean | nil
function Construction:updateSettings(settings, noEventSend)
    if settings ~= nil then
        local previous = self.settings

        ---@diagnostic disable-next-line: assign-type-mismatch
        self.settings = table.copy(self.settings)

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
            xmlFile:setValue('settings.requireActivatePermission', self.settings.requireActivatePermission)
            xmlFile:setValue('settings.requireHudPermission', self.settings.requireHudPermission)
            xmlFile:setValue('settings.requirePlaceablePermission', self.settings.requirePlaceablePermission)
            xmlFile:setValue('settings.requireHotspotPermission', self.settings.requireHotspotPermission)

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
                self.settings.requireActivatePermission = xmlFile:getValue('settings.requireActivatePermission', self.settings.requireActivatePermission)
                self.settings.requireHudPermission = xmlFile:getValue('settings.requireHudPermission', self.settings.requireHudPermission)
                self.settings.requirePlaceablePermission = xmlFile:getValue('settings.requirePlaceablePermission', self.settings.requirePlaceablePermission)
                self.settings.requireHotspotPermission = xmlFile:getValue('settings.requireHotspotPermission', self.settings.requireHotspotPermission)

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
