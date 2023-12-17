local modFolder = g_currentModDirectory

---@param path string
local function load(path)
    source(modFolder .. 'scripts/placeableSpecializations/' .. path)
end

-- Load specialization events
load('events/ConstructionObjectDeliveryEvent.lua')
load('events/ConstructionObjectDeliveryRequestEvent.lua')
load('events/SetConstructionStateEvent.lua')
load('events/SetConstructionStateRequestEvent.lua')

---@class ConstructionSpecialization
---@field price number | nil
---
---@field states ConstructionState[]
---@field stateIndex number
---@field pendingStateIndex number | nil
---@field numStatesWithInput number
---
---@field isSavegameCompleted boolean
---@field isCompleted boolean
---@field isProcessing boolean
---
---@field meshes table<MeshType, Mesh[]>
---@field deliveryAreas ConstructionDeliveryArea[]
---@field activationTriggerNode number
---@field hotspot ConstructionHotspot
---@field activatable ConstructionActivatable
---@field dirtyFlagInput number
---
---@field soundNode number
---@field samples table<string, Sample>
---@field defaultSampleName table<SampleType, string>
---
---@class PlaceableConstruction : Placeable
PlaceableConstruction = {}

PlaceableConstruction.SPEC_NAME = 'spec_' .. g_currentModName .. '.construction'

function PlaceableConstruction.prerequisitesPresent()
    return true
end

--
-- Register XML schema values for placeable construction xml.
--
---@param schema XMLSchema
function PlaceableConstruction.registerXMLPaths(schema)
    local key = 'placeable.construction'

    schema:setXMLSpecializationType('Construction')

    schema:register(XMLValueType.FLOAT, key .. '#price', 'Override price for placeable', nil, false)
    schema:register(XMLValueType.NODE_INDEX, key .. '.activationTrigger#node', 'Player activation trigger node', nil, true)

    -- Register audio samples.
    ConstructionSoundUtils.registerXMLPaths(schema, key .. '.samples')

    -- Register construction meshes.
    schema:register(XMLValueType.STRING, key .. '.meshes.activate(?)#status', 'PREVIEW|ACTIVE|PROCESSING|COMPLETED', nil, true)
    SetActiveMesh.registerXMLPaths(schema, key .. '.meshes.activate(?).mesh(?)')

    -- Register delivery areas.
    ConstructionDeliveryArea.registerXMLPaths(schema, key .. '.deliveryAreas.deliveryArea(?)')

    -- Register construction hotspot.
    ConstructionHotspot.registerXMLPaths(schema, key .. '.hotspot')

    -- Register construction state.
    ConstructionState.registerXMLPaths(schema, key .. '.states.state(?)')
    -- ConstructionStateBuilding.registerXMLPaths(schema, key .. '.states.state(?)')

    schema:setXMLSpecializationType()
end

--
-- Register XML schema values for placeable savegame xml.
--
---@param schema XMLSchema
---@param key string
function PlaceableConstruction.registerSavegameXMLPaths(schema, key)
    ConstructionState.registerSavegameXMLPaths(schema, key)
end

--
-- Register specialization functions.
--
function PlaceableConstruction.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, 'constructionActivationTriggerCallback', PlaceableConstruction.constructionActivationTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, 'finalizeConstruction', PlaceableConstruction.finalizeConstruction)
    SpecializationUtil.registerFunction(placeableType, 'getActiveState', PlaceableConstruction.getActiveState)
    SpecializationUtil.registerFunction(placeableType, 'getActivationTriggerPosition', PlaceableConstruction.getActivationTriggerPosition)
    SpecializationUtil.registerFunction(placeableType, 'getAllInputs', PlaceableConstruction.getAllInputs)
    SpecializationUtil.registerFunction(placeableType, 'getConstructionSellPrice', PlaceableConstruction.getConstructionSellPrice)
    SpecializationUtil.registerFunction(placeableType, 'getDeliveryAreas', PlaceableConstruction.getDeliveryAreas)
    SpecializationUtil.registerFunction(placeableType, 'getInputByFillTypeIndex', PlaceableConstruction.getInputByFillTypeIndex)
    SpecializationUtil.registerFunction(placeableType, 'getIsAwaitingDelivery', PlaceableConstruction.getIsAwaitingDelivery)
    SpecializationUtil.registerFunction(placeableType, 'getIsCompleted', PlaceableConstruction.getIsCompleted)
    SpecializationUtil.registerFunction(placeableType, 'getIsProcessing', PlaceableConstruction.getIsProcessing)
    SpecializationUtil.registerFunction(placeableType, 'getNumStatesWithInputs', PlaceableConstruction.getNumStatesWithInputs)
    SpecializationUtil.registerFunction(placeableType, 'getOwnerFarm', PlaceableConstruction.getOwnerFarm)
    SpecializationUtil.registerFunction(placeableType, 'getOwnerFarmName', PlaceableConstruction.getOwnerFarmName)
    SpecializationUtil.registerFunction(placeableType, 'getSampleByName', PlaceableConstruction.getSampleByName)
    SpecializationUtil.registerFunction(placeableType, 'getSampleByType', PlaceableConstruction.getSampleByType)
    SpecializationUtil.registerFunction(placeableType, 'getStateIndex', PlaceableConstruction.getStateIndex)
    SpecializationUtil.registerFunction(placeableType, 'getStates', PlaceableConstruction.getStates)
    SpecializationUtil.registerFunction(placeableType, 'playSample', PlaceableConstruction.playSample)
    SpecializationUtil.registerFunction(placeableType, 'processDeliveryAreas', PlaceableConstruction.processDeliveryAreas)
    SpecializationUtil.registerFunction(placeableType, 'updateHotspot', PlaceableConstruction.updateHotspot)
    SpecializationUtil.registerFunction(placeableType, 'setIsProcessing', PlaceableConstruction.setIsProcessing)
    SpecializationUtil.registerFunction(placeableType, 'setStateIndex', PlaceableConstruction.setStateIndex)
    SpecializationUtil.registerFunction(placeableType, 'startConstruction', PlaceableConstruction.startConstruction)
    SpecializationUtil.registerFunction(placeableType, 'stopSample', PlaceableConstruction.stopSample)
end

--
-- Register specialization event listeners.
--
function PlaceableConstruction.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, 'onLoad', PlaceableConstruction)
    SpecializationUtil.registerEventListener(placeableType, 'onPostLoad', PlaceableConstruction)
    SpecializationUtil.registerEventListener(placeableType, 'onDelete', PlaceableConstruction)
    SpecializationUtil.registerEventListener(placeableType, 'onFinalizePlacement', PlaceableConstruction)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdate', PlaceableConstruction)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteStream', PlaceableConstruction)
    SpecializationUtil.registerEventListener(placeableType, 'onReadStream', PlaceableConstruction)
    SpecializationUtil.registerEventListener(placeableType, 'onWriteUpdateStream', PlaceableConstruction)
    SpecializationUtil.registerEventListener(placeableType, 'onReadUpdateStream', PlaceableConstruction)
end

--
-- Register functions we want to override with the specialization.
--
function PlaceableConstruction.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, 'getPrice', PlaceableConstruction.getPrice)
    SpecializationUtil.registerOverwrittenFunction(placeableType, 'getSellPrice', PlaceableConstruction.getSellPrice)
end

--
-- Called when loading specialization on a placeable.
--
function PlaceableConstruction:onLoad()
    g_construction:debug('PlaceableConstruction:onLoad()')

    ---@type XMLFile
    local xmlFile = self.xmlFile

    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    spec.isCompleted = false
    spec.isProcessing = false
    spec.isSavegameCompleted = false

    spec.dirtyFlagInput = self:getNextDirtyFlag()

    spec.pendingStateIndex = 1

    --
    -- Load price override if set in xml.
    --
    spec.price = xmlFile:getValue('placeable.construction#price')

    --
    -- Load data only needed by client (i.e not dedicated server)
    --
    if self.isClient then
        --
        -- Load activation trigger node
        --
        spec.activationTriggerNode = xmlFile:getValue('placeable.construction.activationTrigger#node', nil, self.components, self.i3dMappings)

        if spec.activationTriggerNode ~= nil then
            if CollisionFlag.getHasFlagSet(spec.activationTriggerNode, CollisionFlag.TRIGGER_PLAYER) then
                addTrigger(spec.activationTriggerNode, 'constructionActivationTriggerCallback', self)
            else
                Logging.xmlWarning(xmlFile, 'Missing TRIGGER_PLAYER flag on "placeable.construction.activationTrigger#node"')
            end

            setVisibility(spec.activationTriggerNode, true)
        else
            Logging.xmlError(xmlFile, 'Missing "placeable.construction.activationTrigger#node"')

            self:setLoadingState(Placeable.LOADING_STATE_ERROR)
            return
        end

        --
        -- Load sound samples.
        --

        spec.soundNode = xmlFile:getValue('placeable.construction.samples#node', self.rootNode, self.components, self.i3dMappings)
        spec.samples = ConstructionSoundUtils.loadSamples(xmlFile, 'placeable.construction.samples', self, spec.soundNode)

        spec.defaultSampleName = {}
        spec.defaultSampleName[SampleType.DELIVERY] = xmlFile:getValue('placeable.construction.samples#deliverySample')
        spec.defaultSampleName[SampleType.PROCESSING] = xmlFile:getValue('placeable.construction.samples#processingSample')
        spec.defaultSampleName[SampleType.COMPLETION] = xmlFile:getValue('placeable.construction.samples#completionSample')

        if spec.defaultSampleName[SampleType.DELIVERY] ~= nil and spec.samples[spec.defaultSampleName[SampleType.DELIVERY]] == nil then
            Logging.xmlWarning(xmlFile, 'Sample "%s" not found: %s', spec.defaultSampleName[SampleType.DELIVERY], 'placeable.construction.samples#deliverySample')
        end

        if spec.defaultSampleName[SampleType.PROCESSING] ~= nil and spec.samples[spec.defaultSampleName[SampleType.PROCESSING]] == nil then
            Logging.xmlWarning(xmlFile, 'Sample "%s" not found: %s', spec.defaultSampleName[SampleType.PROCESSING], 'placeable.construction.samples#processingSample')
        end

        if spec.defaultSampleName[SampleType.COMPLETION] ~= nil and spec.samples[spec.defaultSampleName[SampleType.COMPLETION]] == nil then
            Logging.xmlWarning(xmlFile, 'Sample "%s" not found: %s', spec.defaultSampleName[SampleType.COMPLETION], 'placeable.construction.samples#completionSample')
        end

        --
        -- Load map construction hotspot.
        --

        spec.hotspot = ConstructionHotspot.new(self)
        spec.hotspot:load(xmlFile, 'placeable.construction.hotspot')

        --
        -- Create activatable for player interaction/HUD.
        --

        spec.activatable = ConstructionActivatable.new(self)
    end

    --
    -- Load delivery areas for materials.
    --

    spec.deliveryAreas = {}

    xmlFile:iterate('placeable.construction.deliveryAreas.deliveryArea', function(_, key)
        local deliveryArea = ConstructionDeliveryArea.new(#spec.deliveryAreas + 1, self)

        if deliveryArea:load(xmlFile, key) then
            table.insert(spec.deliveryAreas, deliveryArea)
        else
            Logging.xmlError(xmlFile, 'Failed to load delivery area: %s', key)

            self:setLoadingState(Placeable.LOADING_STATE_ERROR)
            return
        end
    end)

    if #spec.deliveryAreas == 0 then
        Logging.xmlError(xmlFile, 'No delivery areas found (placeable.construction.deliveryAreas)')

        self:setLoadingState(Placeable.LOADING_STATE_ERROR)
        return
    end

    --
    -- Load states.
    --

    spec.states = {}
    spec.numStatesWithInput = 0

    xmlFile:iterate('placeable.construction.states.state', function(_, key)
        local state = ConstructionState.new(#spec.states + 1, self)

        state:load(xmlFile, key)

        table.insert(spec.states, state)

        if state:getHasInputs() then
            spec.numStatesWithInput = spec.numStatesWithInput + 1
            state.displayIndex = spec.numStatesWithInput
        end
    end)

    if #spec.states == 0 then
        Logging.xmlError(xmlFile, 'No construction states found (placeable.construction.states.state(%))')

        self:setLoadingState(Placeable.LOADING_STATE_ERROR)
        return
    end

    --
    -- Load construction meshes
    --

    spec.meshes = {
        [Construction.STATE_ACTIVE] = {},
        [Construction.STATE_PROCESSING] = {},
        [Construction.STATE_COMPLETED] = {},
        [Construction.STATE_PREVIEW] = {}
    }

    xmlFile:iterate('placeable.construction.meshes.activate', function(_, key)
        local status = xmlFile:getValue(key .. '#status')

        if spec.meshes[status] ~= nil then
            xmlFile:iterate(key .. '.mesh', function(_, meshKey)
                local mesh = SetActiveMesh.new(self)

                mesh:load(xmlFile, meshKey)

                table.insert(spec.meshes[status], mesh)
            end)
        else
            Logging.xmlError(xmlFile, 'Invalid status condition: "%s" (%s)', tostring(status), key)
        end
    end)

    --
    -- Subscribe to settings changed event if we're not in placement preview mode.
    --
    if self.propertyState ~= Placeable.PROPERTY_STATE_CONSTRUCTION_PREVIEW then
        g_messageCenter:subscribe(MessageType.CONSTRUCTION_SETTINGS_CHANGED, PlaceableConstruction.onSettingsChanged, self)
    end
end

function PlaceableConstruction:onPostLoad()
    g_construction:debug('PlaceableConstruction:onPostLoad()')

    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    if self.propertyState == Placeable.PROPERTY_STATE_CONSTRUCTION_PREVIEW then
        for _, mesh in ipairs(spec.meshes[Construction.STATE_ACTIVE]) do
            mesh:deactivate()
        end

        for _, mesh in ipairs(spec.meshes[Construction.STATE_PROCESSING]) do
            mesh:deactivate()
        end

        for _, mesh in ipairs(spec.meshes[Construction.STATE_COMPLETED]) do
            mesh:deactivate()
        end

        for _, mesh in ipairs(spec.meshes[Construction.STATE_PREVIEW]) do
            mesh:activate()
        end
    else
        for _, mesh in ipairs(spec.meshes[Construction.STATE_PREVIEW]) do
            mesh:deactivate()
        end
    end
end

--
-- Called when placeable is deleted.
--
function PlaceableConstruction:onDelete()
    g_construction:debug('PlaceableConstruction:onDelete()')

    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    if self.isClient then
        -- Delete loaded samples.
        g_soundManager:deleteSamples(spec.samples)
        spec.samples = nil

        -- Delete activatable
        spec.activatable:delete()
        spec.activatable = nil

        -- Delete hotspot
        spec.hotspot:delete()
        spec.hotspot = nil

        -- Remove activation trigger
        removeTrigger(spec.activationTriggerNode)
        spec.activationTriggerNode = nil
    end

    -- Delete delivery areas.
    for _, deliveryArea in ipairs(spec.deliveryAreas) do
        deliveryArea:delete()
    end
    spec.deliveryAreas = {}

    -- Remove placeable from Construction if we're not in preview mode
    if self.propertyState ~= Placeable.PROPERTY_STATE_CONSTRUCTION_PREVIEW then
        g_construction:unregister(self)
    end

    -- Unsubscribe all message events
    g_messageCenter:unsubscribeAll(self)

    -- Delete construction states
    for _, state in ipairs(spec.states) do
        state:delete()
    end
    spec.states = {}
end

function PlaceableConstruction:onFinalizePlacement()
    g_construction:debug('PlaceableConstruction:onFinalizePlacement()')

    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    self:startConstruction()

    if self.isServer then
        self:setStateIndex(1)

        while true do
            if spec.stateIndex == spec.pendingStateIndex then
                break
            end

            if spec.states[spec.stateIndex + 1] ~= nil then
                self:setStateIndex(spec.stateIndex + 1)
            else
                Logging.warning('PlaceableConstruction:onFinalizePlacement() This message should not appear ..')
                break
            end
        end

        spec.pendingStateIndex = nil

        self:raiseActive()
    end

    g_construction:register(self)
end

--
-- Save data to savegame.
--
---@param xmlFile XMLFile
---@param key string
function PlaceableConstruction:saveToXMLFile(xmlFile, key)
    local state = self:getActiveState()

    xmlFile:setValue(key .. '#stateIndex', state.index)

    state:saveToXMLFile(xmlFile, key)
end

--
-- Load data from savegame.
--
---@param xmlFile XMLFile
---@param key string
function PlaceableConstruction:loadFromXMLFile(xmlFile, key)
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    spec.pendingStateIndex = MathUtil.clamp(xmlFile:getValue(key .. '#stateIndex', 1), 1, #spec.states)

    local state = spec.states[spec.pendingStateIndex]

    state:loadFromXMLFile(xmlFile, key)

    if state:getIsFinalState() and state:getIsCompleted() then
        spec.isSavegameCompleted = true
    end
end

--[[
    Specialization functions
]]

--
-- Get placeable owner farm object
--
---@return Farm | nil
function PlaceableConstruction:getOwnerFarm()
    return g_farmManager:getFarmById(self:getOwnerFarmId())
end

---@return string
function PlaceableConstruction:getOwnerFarmName()
    local farm = self:getOwnerFarm()

    if farm ~= nil then
        return farm.name
    end

    return 'Unknown farm'
end

--
-- Called when starting construction.
--
function PlaceableConstruction:startConstruction()
    g_construction:debug('PlaceableConstruction:startConstruction()')

    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    for _, mesh in ipairs(spec.meshes[Construction.STATE_ACTIVE]) do
        mesh:activate()
    end

    for _, mesh in ipairs(spec.meshes[Construction.STATE_PROCESSING]) do
        mesh:deactivate()
    end

    for _, mesh in ipairs(spec.meshes[Construction.STATE_COMPLETED]) do
        mesh:deactivate()
    end

    for _, deliveryArea in ipairs(spec.deliveryAreas) do
        deliveryArea:setIsEnabled(deliveryArea.alwaysActive)
    end

    self:updateHotspot()
end

--
-- Called when all constructions states are completed.
--
function PlaceableConstruction:finalizeConstruction()
    g_construction:debug('PlaceableConstruction:finalizeConstruction()')

    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    spec.isCompleted = true

    -- Check if we're loading (savegame/mp sync), if so we don't want to play completion sound.
    if not spec.isSavegameCompleted then
        self:playSample(SampleType.COMPLETION)
    end

    for _, mesh in ipairs(spec.meshes[Construction.STATE_ACTIVE]) do
        mesh:deactivate()
    end

    for _, mesh in ipairs(spec.meshes[Construction.STATE_PROCESSING]) do
        mesh:deactivate()
    end

    for _, mesh in ipairs(spec.meshes[Construction.STATE_COMPLETED]) do
        mesh:activate()
    end

    for _, deliveryArea in ipairs(spec.deliveryAreas) do
        deliveryArea:setIsEnabled(false)
    end

    self:updateHotspot()

    if self.isClient then
        removeTrigger(spec.activationTriggerNode)
        setVisibility(spec.activationTriggerNode, false)

        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end

    g_messageCenter:publish(MessageType.CONSTRUCTION_COMPLETED, self)
end

--
-- Get current state index
--
---@return number
function PlaceableConstruction:getStateIndex()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return spec.stateIndex
end

--
-- Get the current active construction state.
--
---@return ConstructionState
function PlaceableConstruction:getActiveState()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return spec.states[spec.stateIndex]
end

function PlaceableConstruction:getNumStatesWithInputs()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return spec.numStatesWithInput
end

--
-- Get all construction states.
--
---@return ConstructionState[]
function PlaceableConstruction:getStates()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return spec.states
end

--
-- Change current construction state index.
--
---@param index number
function PlaceableConstruction:setStateIndex(index)
    g_construction:debug('PlaceableConstruction:setStateIndex() index: %i', index)

    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    if self.isServer then
        SetConstructionStateEvent.sendEvent(index, self)
    end

    if spec.stateIndex ~= index then
        local previousState = spec.states[spec.stateIndex]

        if previousState then
            previousState:deactivate()
        end

        spec.stateIndex = index

        spec.states[index]:activate()
    end
end

---@param isProcessing boolean
function PlaceableConstruction:setIsProcessing(isProcessing)
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    if spec.isProcessing ~= isProcessing then
        g_construction:debug('PlaceableConstruction:setIsProcessing() isProcessing: %s', tostring(isProcessing))

        spec.isProcessing = isProcessing

        if isProcessing then
            for _, mesh in ipairs(spec.meshes[Construction.STATE_PROCESSING]) do
                mesh:activate()
            end
        else
            for _, mesh in ipairs(spec.meshes[Construction.STATE_PROCESSING]) do
                mesh:deactivate()
            end
        end
    end
end

--
-- Get all inputs from all construction states.
--
---@return ConstructionInput[]
function PlaceableConstruction:getAllInputs()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    ---@type ConstructionInput[]
    local result = {}

    for _, state in ipairs(spec.states) do
        for _, input in ipairs(state:getInputs()) do
            table.insert(result, input)
        end
    end

    return result
end

--
-- Get input by fillTypeIndex from current state.
--
---@param fillTypeIndex number
---@return ConstructionInput | nil
function PlaceableConstruction:getInputByFillTypeIndex(fillTypeIndex)
    local state = self:getActiveState()

    return state:getInputByFillTypeIndex(fillTypeIndex)
end

--
-- Returns true if activate state is last state and is completed.
--
---@return boolean
function PlaceableConstruction:getIsCompleted()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return spec.isCompleted
end

--
-- Returns true if current state is processing any inputs.
--
function PlaceableConstruction:getIsProcessing()
    local state = self:getActiveState()

    return state:getIsProcessing()
end

--
-- Returns true if current state is missing any input materials.
--
function PlaceableConstruction:getIsAwaitingDelivery()
    local state = self:getActiveState()

    return state:getIsAwaitingDelivery()
end

--
-- Get all delivery areas.
--
---@return ConstructionDeliveryArea[]
function PlaceableConstruction:getDeliveryAreas()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return spec.deliveryAreas
end

--
-- Process all active delivery areas.
-- Server only.
--
function PlaceableConstruction:processDeliveryAreas()
    g_construction:debug('PlaceableConstruction:processDeliveryAreas()')

    if self.isServer then
        local state = self:getActiveState()

        if state:getIsAwaitingDelivery() then
            local deliveredAnyAmount = false

            for _, deliveryArea in ipairs(self:getDeliveryAreas()) do
                if deliveryArea:getIsEnabled() and deliveryArea:processActiveObjects() then
                    deliveredAnyAmount = true
                end
            end

            if deliveredAnyAmount then
                ConstructionObjectDeliveryEvent.sendEvent(self)

                self:playSample(SampleType.DELIVERY)
            end
        else
            Logging.warning('PlaceableConstruction:processDeliveryAreas() active state is not awaiting any deliveries')
        end
    end
end

--
-- Update construction hotspot visibility accordingly.
-- Client only.
--
function PlaceableConstruction:updateHotspot()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    if self.isClient then
        if self:getIsCompleted() then
            spec.hotspot:setVisible(ConstructionUtils.getShowPlaceableHotspot(self) and g_construction:getIsHotspotsEnabledWhenCompleted())
        else
            spec.hotspot:setVisible(ConstructionUtils.getShowPlaceableHotspot(self))
        end
    end
end

--[[
    Placeable construction sound functions.
]]

--
-- Play sample by type.
-- Client only.
--
---@param type SampleType
function PlaceableConstruction:playSample(type)
    if self.isClient then
        ConstructionSoundUtils.playSample(type, self)
    end
end

--
-- Stop playing sample by type.
-- Client only.
--
---@param type SampleType
function PlaceableConstruction:stopSample(type)
    if self.isClient then
        ConstructionSoundUtils.stopSample(type, self)
    end
end

--
-- Get audio sample by unique name
--
---@return Sample | nil
function PlaceableConstruction:getSampleByName(name)
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return spec.samples[name]
end

--
-- Get audio sample by type.
--
---@param type SampleType
---@return Sample | nil
function PlaceableConstruction:getSampleByType(type)
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    local state = self:getActiveState()
    local name = state:getSampleName(type) or spec.defaultSampleName[type]

    if name then
        return self:getSampleByName(name)
    end
end

--[[
    Placeable construction price (override) functions.
]]

--
-- Override placeable price if applicable.
--
---@return number
function PlaceableConstruction:getPrice()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    if g_construction:getIsPriceOverrideEnabled() and spec.price ~= nil then
        return spec.price
    end

    return Placeable.getPrice(self)
end

--
-- Override placeable sell price if applicable.
--
---@return number
---@return boolean | nil
function PlaceableConstruction:getSellPrice()
    if g_construction:getIsPriceOverrideEnabled() then
        if self.undoTimer > g_time - Placeable.UNDO_DURATION and g_currentMission.lastConstructionScreenOpenTime < self.undoTimer and g_currentMission.lastConstructionScreenOpenTime > 0 then
            return self:getPrice(), true
        end

        local priceMultiplier = 0.5
        local maxAge = self.storeItem.lifetime

        if maxAge ~= nil and maxAge ~= 0 then
            priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(self.age / maxAge, 1))
        end

        return math.floor(self:getConstructionSellPrice() * math.max(priceMultiplier, 0.05))
    end

    return Placeable.getSellPrice(self)
end

--
-- Get sell price of placeable construction depending on whether it's completed or not.
-- If price override is not set in xml it will default to base game calculation using storeData price.
--
---@return number
function PlaceableConstruction:getConstructionSellPrice()
    if self:getIsCompleted() then
        return Placeable.getPrice(self)
    else
        return self:getPrice()
    end
end

--[[
    Placeable construction player activation trigger functions.
]]

--
-- Get world position of activation trigger node.
--
---@return number x
---@return number y
---@return number z
function PlaceableConstruction:getActivationTriggerPosition()
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    return getWorldTranslation(spec.activationTriggerNode)
end

--
-- Player activation trigger callback.
-- Client only.
--
---@param triggerId number
---@param otherActorId number | nil
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function PlaceableConstruction:constructionActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        elseif onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end

--[[
    Events.
]]

--
-- Message center event callback for contruction settings changed.
-- Client only.
--
function PlaceableConstruction:onSettingsChanged()
    g_construction:debug('onSettingsChanged()')
    DebugUtil.printTableRecursively(g_construction.settings)

    if self.isClient then
        self:updateHotspot()
    end
end

--
-- Placeable update event called when active.
--
---@param dt number
function PlaceableConstruction:onUpdate(dt)
    if not self:getIsCompleted() then
        local state = self:getActiveState()

        if state:getIsFinalState() then
            if state:getIsCompleted() then
                self:finalizeConstruction()
                return
            end
        elseif self.isServer then
            if state:getIsCompleted() then
                self:setStateIndex(state.index + 1)

                state = self:getActiveState()
            end

            self:raiseActive()
        end

        state:update(dt)
    end
end

--
-- Send current state data to client in order to sync.
--
---@param streamId number
---@param connection Connection
function PlaceableConstruction:onWriteStream(streamId, connection)
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    local state = self:getActiveState()

    streamWriteUInt8(streamId, spec.stateIndex)

    state:writeStream(streamId, connection)
end

--
-- Read state data from server.
--
---@param streamId number
---@param connection Connection
function PlaceableConstruction:onReadStream(streamId, connection)
    ---@type ConstructionSpecialization
    local spec = self[PlaceableConstruction.SPEC_NAME]

    local stateIndex = streamReadUInt8(streamId)

    self:setStateIndex(1)

    while true do
        if spec.stateIndex == stateIndex then
            break
        end

        self:setStateIndex(spec.stateIndex + 1)
    end

    local state = self:getActiveState()

    state:readStream(streamId, connection)

    if state:getIsFinalState() and state:getIsCompleted() then
        spec.isSavegameCompleted = true
    end
end

--
-- Send data update stream to client if needed.
--
---@param streamId number
---@param connection Connection
---@param dirtyMask number
function PlaceableConstruction:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        self:getActiveState():writeUpdateStream(streamId, connection, dirtyMask)
    end
end

--
-- Read data update stream from server.
--
---@param streamId number
---@param timestamp number
---@param connection Connection
function PlaceableConstruction:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self:getActiveState():readUpdateStream(streamId, timestamp, connection)
    end
end
