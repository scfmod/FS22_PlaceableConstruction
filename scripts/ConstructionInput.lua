---@class ConstructionInput
---@field index number
---@field state ConstructionState
---@field fillTypeName string
---@field amount number
---@field processPerHour number
---@field deliveryAreaIndex number
---@field isDirty boolean
---
---@field deliveredAmount number -- Amount delivered
---@field processedAmount number -- Amount processed
---
---@field lastSyncedDeliveredAmount number
---@field lastSyncedProcessedAmount number
ConstructionInput = {}

local ConstructionInput_mt = Class(ConstructionInput)

---@param schema XMLSchema
---@param key string
function ConstructionInput.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#fillType', 'Fill type name', nil, true)
    schema:register(XMLValueType.FLOAT, key .. '#amount', 'Amount required', nil, true)
    schema:register(XMLValueType.FLOAT, key .. '#processPerHour', 'Amount processed per ingame hour', nil, true)
    schema:register(XMLValueType.INT, key .. '#deliveryAreaIndex', 'Specify delivery area', 1, false)
end

---@param schema XMLSchema
---@param key string
function ConstructionInput.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.FLOAT, key .. '#deliveredAmount')
    schema:register(XMLValueType.FLOAT, key .. '#processedAmount')
end

---@nodiscard
---@param index number
---@param state ConstructionState
---@return ConstructionInput
function ConstructionInput.new(index, state)
    ---@type ConstructionInput
    local self = setmetatable({}, ConstructionInput_mt)

    self.index = index
    self.state = state
    self.isDirty = false

    self.deliveredAmount = 0
    self.processedAmount = 0

    self.lastSyncedDeliveredAmount = 0
    self.lastSyncedProcessedAmount = 0

    return self
end

---
--- Load from placeable xml
---
---@param xmlFile XMLFile
---@param key string
---@return boolean
function ConstructionInput:load(xmlFile, key)
    self.fillTypeName = xmlFile:getValue(key .. '#fillType')
    self.amount = xmlFile:getValue(key .. '#amount')
    self.processPerHour = xmlFile:getValue(key .. '#processPerHour')
    self.deliveryAreaIndex = xmlFile:getValue(key .. '#deliveryAreaIndex', 1)

    if not self.fillTypeName then
        Logging.xmlError(xmlFile, 'Missing input fillType: %s', key .. '#fillType')
        return false
    end

    if not self.amount then
        Logging.xmlError(xmlFile, 'Missing input amount: %s', key .. '#amount')
        return false
    end

    if not self.processPerHour then
        Logging.xmlError(xmlFile, 'Missing input processPerHour: %s', key .. '#processPerHour')
        return false
    end

    return true
end

---
--- Load from savegame xml
---
---@param xmlFile XMLFile
---@param key string
function ConstructionInput:loadFromXMLFile(xmlFile, key)
    self.deliveredAmount = MathUtil.clamp(xmlFile:getValue(key .. '#deliveredAmount', 0), 0, self.amount)
    self.processedAmount = MathUtil.clamp(xmlFile:getValue(key .. '#processedAmount', 0), 0, self.deliveredAmount)
end

---
--- Save to savegame xml
---
---@param xmlFile XMLFile
---@param key string
function ConstructionInput:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. '#deliveredAmount', self.deliveredAmount)
    xmlFile:setValue(key .. '#processedAmount', self.processedAmount)
end

---
--- Return true if total amount is delivered and processed
---
---@nodiscard
---@return boolean
function ConstructionInput:getIsCompleted()
    return self:getIsDelivered() and self.processedAmount >= self.amount
end

---
--- Return true if total amount is delivered
---
---@nodiscard
---@return boolean
function ConstructionInput:getIsDelivered()
    return self.deliveredAmount >= self.amount
end

---
--- Return true if input is processing
---
---@nodiscard
---@return boolean
function ConstructionInput:getIsProcessing()
    return self.processedAmount < self.deliveredAmount
end

---
--- Add delivered amount
---
---@nodiscard
---@param delta number
function ConstructionInput:addFillLevel(delta)
    local previousDeliveredAmount = self.deliveredAmount

    self.deliveredAmount = math.min(self.amount, self.deliveredAmount + delta)

    if self.deliveredAmount > previousDeliveredAmount then
        self.state:updateTotals()
        self:raiseDirtyFlag()
    end

    return self.deliveredAmount - previousDeliveredAmount
end

---
--- Get the actual FillType object from fillTypeName
---
---@nodiscard
---@return FillTypeObject | nil
function ConstructionInput:getFillType()
    return g_fillTypeManager:getFillTypeByName(self.fillTypeName)
end

---@param dt number
---@return boolean processUpdate
function ConstructionInput:update(dt)
    if self:getIsProcessing() then
        local amountPerMs = self.processPerHour / 3600 / 1000
        local amount = amountPerMs * dt * g_currentMission.missionInfo.timeScale

        self.processedAmount = math.min(self.deliveredAmount, self.processedAmount + amount)

        if math.abs(self.processedAmount - self.lastSyncedProcessedAmount) > self.amount / 100 or self.processedAmount == self.amount then
            self.lastSyncedProcessedAmount = self.processedAmount
            self:raiseDirtyFlag()
            return true
        end
    end

    return false
end

function ConstructionInput:raiseDirtyFlag()
    if g_server == nil then
        Logging.warning('ConstructionInput:raiseDirtyFlag() should not be called client side !')
        return
    end

    if not self.isDirty then
        self.isDirty = true
        self.state.placeable:raiseDirtyFlags(self.state.dirtyFlagInput)
        self.state.placeable:raiseActive()
    end
end

---@param streamId number
---@param connection Connection
function ConstructionInput:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.deliveredAmount)
    streamWriteFloat32(streamId, self.processedAmount)
end

---@param streamId number
---@param connection Connection
function ConstructionInput:readStream(streamId, connection)
    self.deliveredAmount = streamReadFloat32(streamId)
    self.processedAmount = streamReadFloat32(streamId)
end

function ConstructionInput:writeUpdateStream(streamId, connection, dirtyMask)
    streamWriteFloat32(streamId, self.deliveredAmount)
    streamWriteFloat32(streamId, self.processedAmount)

    self.isDirty = false
end

function ConstructionInput:readUpdateStream(streamId, timestamp, connection)
    self.deliveredAmount = streamReadFloat32(streamId)
    self.processedAmount = streamReadFloat32(streamId)
end
