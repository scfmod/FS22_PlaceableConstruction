---@class ConstructionState
---@field index number
---@field title string | nil
---@field sampleName table<SampleType, string>
---@field displayIndex number
---
---@field inputs ConstructionInput[]
---@field inputByFillTypeName table<string, ConstructionInput>
---@field inputsByArea table<number, ConstructionInput[]>
---@field meshes table<MeshType, Mesh[]>
---
---@field totalAmount number
---@field totalDeliveredAmount number
---@field totalProcessedAmount number
---
---@field placeable PlaceableConstruction
---@field components table
---@field i3dMappings table
---@field isServer boolean
---@field isClient boolean
---@field dirtyFlagInput number
---
ConstructionState = {}

local ConstructionState_mt = Class(ConstructionState)

---@param schema XMLSchema
---@param key string
function ConstructionState.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#title', 'Title for construction state', nil, false)
    schema:register(XMLValueType.STRING, key .. '#processingSample', 'Set/override processing sample', nil, false)

    ConstructionInput.registerXMLPaths(schema, key .. '.inputs.input(?)')

    ToggleMesh.registerXMLPaths(schema, key .. '.toggleMesh(?)')
    SetProgressMesh.registerXMLPaths(schema, key .. '.meshes.mesh(?)')
    SetShaderParameterMesh.registerXMLPaths(schema, key .. '.meshes.shaderMesh(?)')
end

---@param schema XMLSchema
---@param key string
function ConstructionState.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. '#stateIndex')
    ConstructionInput.registerSavegameXMLPaths(schema, key .. '.input(?)')
end

---@nodiscard
---@param index number
---@param placeable PlaceableConstruction
---@param mt table | nil
---@return ConstructionState
function ConstructionState.new(index, placeable, mt)
    ---@type ConstructionState
    local self = setmetatable({}, mt or ConstructionState_mt)

    self.index = index
    self.placeable = placeable
    self.sampleName = {}
    self.displayIndex = 0

    self.inputs = {}
    self.inputByFillTypeName = {}
    self.inputsByArea = {}

    self.meshes = {
        [MeshType.TOGGLE] = {},
        [MeshType.SET_PROGRESS] = {},
        [MeshType.SET_SHADER_PARAMETER] = {}
    }

    self.totalAmount = 0
    self.totalDeliveredAmount = 0
    self.totalProcessedAmount = 0

    self.components = placeable.components
    self.i3dMappings = placeable.i3dMappings
    self.isServer = placeable.isServer
    self.isClient = placeable.isClient

    ---@type ConstructionSpecialization
    local spec = placeable[PlaceableConstruction.SPEC_NAME]

    self.dirtyFlagInput = spec.dirtyFlagInput

    return self
end

function ConstructionState:delete()
    self.inputs = {}
    self.inputByFillTypeName = {}
    self.inputsByArea = {}
end

---
--- Load construction state from placeable XML
---
---@param xmlFile XMLFile
---@param key string
function ConstructionState:load(xmlFile, key)
    self.title = ConstructionUtils.getPlaceableText(self.placeable, xmlFile:getValue(key .. '#title'))

    local sampleName = xmlFile:getValue(key .. '#processingSample')

    if sampleName ~= nil then
        if sampleName == 'nil' or self.placeable:getSampleByName(sampleName) ~= nil then
            self.sampleName[SampleType.PROCESSING] = sampleName
        else
            Logging.warning('Uknown sample name: %s (%s)', sampleName, key .. '#processingSample')
        end
    end

    xmlFile:iterate(key .. '.toggleMesh', function(_, meshKey)
        local mesh = ToggleMesh.new(self.placeable)
        mesh:load(xmlFile, meshKey)
        table.insert(self.meshes[MeshType.TOGGLE], mesh)
    end)

    xmlFile:iterate(key .. '.meshes.mesh', function(_, meshKey)
        local mesh = SetProgressMesh.new(self.placeable)

        mesh:load(xmlFile, meshKey)
        table.insert(self.meshes[MeshType.SET_PROGRESS], mesh)
    end)

    xmlFile:iterate(key .. '.meshes.shaderMesh', function(_, meshKey)
        local mesh = SetShaderParameterMesh.new(self.placeable)

        mesh:load(xmlFile, meshKey)
        table.insert(self.meshes[MeshType.SET_SHADER_PARAMETER], mesh)
    end)

    xmlFile:iterate(key .. '.inputs.input', function(_, inputKey)
        local input = ConstructionInput.new(#self.inputs + 1, self)

        assert(input:load(xmlFile, inputKey), 'Failed to load construction state input')
        assert(self.inputByFillTypeName[input.fillTypeName] == nil, string.format('Duplicate input fillType: %s', input.fillTypeName))

        table.insert(self.inputs, input)
        self.inputByFillTypeName[input.fillTypeName] = input

        self.totalAmount = self.totalAmount + input.amount

        if self.inputsByArea[input.deliveryAreaIndex] == nil then
            self.inputsByArea[input.deliveryAreaIndex] = {}
        end

        table.insert(self.inputsByArea[input.deliveryAreaIndex], input)
    end)
end

---
--- Load input states from savegame
---
---@param xmlFile XMLFile
---@param key string
function ConstructionState:loadFromXMLFile(xmlFile, key)
    if #self.inputs > 0 then
        xmlFile:iterate(key .. '.input', function(index, inputKey)
            local input = self.inputs[index]

            if input ~= nil then
                input:loadFromXMLFile(xmlFile, inputKey)
            else
                Logging.xmlWarning(xmlFile, 'Could not find input with index: %i', index)
            end
        end)

        self:updateTotals()
    end
end

---
--- Save input states to savegame
---
---@param xmlFile XMLFile
---@param key string
function ConstructionState:saveToXMLFile(xmlFile, key)
    for i, input in ipairs(self.inputs) do
        local inputKey = string.format('%s.input(%i)', key, i - 1)

        input:saveToXMLFile(xmlFile, inputKey)
    end
end

---@nodiscard
---@return string
function ConstructionState:getTitle()
    return self.title or string.format('state %i', self.index)
end

---
--- Update total delivered and processed amounts.
--- Only use when #inputs > 0
---
function ConstructionState:updateTotals()
    self.totalDeliveredAmount = 0
    self.totalProcessedAmount = 0

    for _, input in ipairs(self.inputs) do
        self.totalDeliveredAmount = self.totalDeliveredAmount + input.deliveredAmount
        self.totalProcessedAmount = self.totalProcessedAmount + input.processedAmount
    end

    self.totalDeliveredAmount = math.min(self.totalAmount, self.totalDeliveredAmount)
end

---@protected
function ConstructionState:fillAllInputs()
    if #self.inputs > 0 then
        self.totalDeliveredAmount = 0
        self.totalProcessedAmount = 0

        for _, input in ipairs(self.inputs) do
            input.deliveredAmount = input.amount
            input.processedAmount = input.amount

            self.totalDeliveredAmount = self.totalDeliveredAmount + input.amount
        end

        self.totalProcessedAmount = self.totalDeliveredAmount
    end
end

---
--- Activate construction state
---
function ConstructionState:activate()
    g_construction:debug('ConstructionState:activate() index: %i  title: %s', self.index, tostring(self.title))

    self:activateToggleMeshes()
    self:updateMeshProgress(0)

    for _, deliveryArea in ipairs(self.placeable:getDeliveryAreas()) do
        if not deliveryArea.alwaysActive then
            deliveryArea:setIsEnabled(self.inputsByArea[deliveryArea.index] ~= nil)
        end
    end
end

---
--- Deactivate construction state
---
function ConstructionState:deactivate()
    g_construction:debug('ConstructionState:deactivate() index: %i  title: %s', self.index, tostring(self.title))
    --
    -- Stop playing processing sample if it's still playing.
    --
    self.placeable:stopSample(SampleType.PROCESSING)
    self.placeable:setIsProcessing(false)

    self:updateMeshProgress(1)

    self:fillAllInputs()
end

---
--- Returns true if state is last state
---
---@nodiscard
---@return boolean
function ConstructionState:getIsFinalState()
    local states = self.placeable:getStates()

    return self.index == #states
end

---@nodiscard
---@return number
function ConstructionState:getDeliveryProgress()
    if self.totalAmount > 0 then
        return 1 / self.totalAmount * self.totalDeliveredAmount
    end

    return 1
end

---@nodiscard
---@return number
function ConstructionState:getProcessingProgress()
    if self.totalAmount > 0 then
        return 1 / self.totalAmount * self.totalProcessedAmount
    end

    return 1
end

---
--- Returns true if any inputs are processing
---
---@nodiscard
---@return boolean
function ConstructionState:getIsProcessing()
    for _, input in ipairs(self.inputs) do
        if input:getIsProcessing() then
            return true
        end
    end

    return false
end

---
--- Returns true if any inputs are awaiting delivery
---
---@nodiscard
---@return boolean
function ConstructionState:getIsAwaitingDelivery()
    for _, input in ipairs(self.inputs) do
        if not input:getIsDelivered() then
            return true
        end
    end

    return false
end

---
--- Returns true if all inputs are completed
--- Returns true if no inputs defined
---
---@nodiscard
---@return boolean
function ConstructionState:getIsCompleted()
    for _, input in ipairs(self.inputs) do
        if not input:getIsCompleted() then
            return false
        end
    end

    return true
end

---@nodiscard
---@param type SampleType
---@return string | nil
function ConstructionState:getSampleName(type)
    return self.sampleName[type]
end

---@param dt number
function ConstructionState:update(dt)
    if self:getIsProcessing() then
        if self.isServer then
            local updateProgress = false

            for _, input in ipairs(self.inputs) do
                if input:update(dt) then
                    updateProgress = true
                end
            end

            self:updateTotals()

            if updateProgress and self.isClient then
                self:updateMeshProgress()
            end
        end

        if not self:getIsCompleted() then
            if self.isClient then
                self.placeable:playSample(SampleType.PROCESSING)
            end

            self.placeable:setIsProcessing(true)
        end
    else
        if self.isClient then
            self.placeable:stopSample(SampleType.PROCESSING)
        end

        self.placeable:setIsProcessing(false)
    end
end

---
--- Construction state inputs functions.
---

---
--- Returns true if state has inputs.
---
---@nodiscard
---@return boolean
function ConstructionState:getHasInputs()
    return #self.inputs > 0
end

--
-- Find input by index
--
---@nodiscard
---@param index number
---@return ConstructionInput | nil
function ConstructionState:getInputByIndex(index)
    return self.inputs[index]
end

---
--- Find input by fill type name
---
---@nodiscard
---@param fillTypeName string
---@return ConstructionInput | nil
function ConstructionState:getInputByFillTypeName(fillTypeName)
    return self.inputByFillTypeName[fillTypeName]
end

---
--- Find input by fill type index
---
---@nodiscard
---@param fillTypeIndex number
---@return ConstructionInput | nil
function ConstructionState:getInputByFillTypeIndex(fillTypeIndex)
    ---@type FillTypeObject | nil
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    if fillType ~= nil then
        return self:getInputByFillTypeName(fillType.name)
    end
end

---
--- Get all inputs, filtered by delivery area index (optional)
---
---@nodiscard
---@param deliveryAreaIndex number | nil
---@return ConstructionInput[]
function ConstructionState:getInputs(deliveryAreaIndex)
    if deliveryAreaIndex and #self.inputs > 0 then
        if self.inputsByArea[deliveryAreaIndex] ~= nil then
            return self.inputsByArea[deliveryAreaIndex]
        end

        return {}
    end

    return self.inputs
end

---
--- Construction state network functions.
---

---
--- Sync. input values to client on connect.
---
---@param streamId number
---@param connection Connection
function ConstructionState:writeStream(streamId, connection)
    if #self.inputs > 0 then
        for _, input in ipairs(self.inputs) do
            input:writeStream(streamId, connection)
        end
    end
end

---
--- Read initial input values from server.
---
---@param streamId number
---@param connection Connection
function ConstructionState:readStream(streamId, connection)
    if #self.inputs > 0 then
        for _, input in ipairs(self.inputs) do
            input:readStream(streamId, connection)
        end

        self:updateTotals()
        self:updateMeshProgress()
    end
end

---@param streamId number
---@param connection Connection
---@param dirtyMask number
function ConstructionState:writeUpdateStream(streamId, connection, dirtyMask)
    if #self.inputs > 0 then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlagInput) ~= 0) then
            for _, input in ipairs(self.inputs) do
                if streamWriteBool(streamId, input.isDirty) then
                    input:writeUpdateStream(streamId, connection, dirtyMask)
                end
            end
        end
    end
end

---@param streamId number
---@param timestamp number
---@param connection Connection
function ConstructionState:readUpdateStream(streamId, timestamp, connection)
    if #self.inputs > 0 then
        if streamReadBool(streamId) then
            for _, input in ipairs(self.inputs) do
                if streamReadBool(streamId) then
                    input:readUpdateStream(streamId, timestamp, connection)
                end
            end

            self:updateTotals()
            self:updateMeshProgress()
        end
    end
end

---
--- Construction state mesh functions.
---

---@protected
---@param forcedValue number | nil
function ConstructionState:updateMeshProgress(forcedValue)
    local value = forcedValue or self:getProcessingProgress()

    for _, mesh in ipairs(self.meshes[MeshType.SET_PROGRESS]) do
        mesh:update(value)
    end

    for _, mesh in ipairs(self.meshes[MeshType.SET_SHADER_PARAMETER]) do
        mesh:update(value)
    end
end

---@protected
function ConstructionState:activateToggleMeshes()
    for _, mesh in ipairs(self.meshes[MeshType.TOGGLE]) do
        mesh:activate()
    end
end
