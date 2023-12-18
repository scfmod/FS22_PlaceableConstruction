---@class ConstructionDeliveryArea
---@field index number
---@field placeable PlaceableConstruction
---@field isServer boolean
---@field isClient boolean
---
---@field objectTrigger number | nil
---@field fillTrigger number | nil
---@field meshes table<MeshType, Mesh[]>
---
---@field enabled boolean
---@field alwaysActive boolean
---
---@field activeObjects DeliveryObject[]
---@field registeredObjects table<DeliveryObject, boolean>
ConstructionDeliveryArea = {}

local ConstructionDeliveryArea_mt = Class(ConstructionDeliveryArea)

---@param schema XMLSchema
---@param key string
function ConstructionDeliveryArea.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '.objectTrigger#node', 'Trigger node for objects with FillUnit (pallets etc.)', nil, false)
    schema:register(XMLValueType.NODE_INDEX, key .. '.fillTrigger#node', 'Trigger node for dischargeable', nil, false)
    schema:register(XMLValueType.BOOL, key .. '#alwaysActive', 'Whether delivery area should be active during the entire construction phase', false, false)

    SetActiveMesh.registerXMLPaths(schema, key .. '.meshes.mesh(?)')
end

---@param index number
---@param placeable PlaceableConstruction
---@return ConstructionDeliveryArea
function ConstructionDeliveryArea.new(index, placeable)
    ---@type ConstructionDeliveryArea
    local self = setmetatable({}, ConstructionDeliveryArea_mt)

    self.index = index
    self.placeable = placeable
    self.meshes = {
        [MeshType.SET_ACTIVE] = {}
    }
    self.alwaysActive = false
    self.activeObjects = {}
    self.registeredObjects = {}

    self.isServer = placeable.isServer
    self.isClient = placeable.isClient

    return self
end

function ConstructionDeliveryArea:delete()
    if self.isServer then
        if self.objectTrigger ~= nil then
            removeTrigger(self.objectTrigger)

            self.activeObjects = {}
            self.registeredObjects = {}
        end

        if self.fillTrigger ~= nil then
            g_currentMission.nodeToObject[self.fillTrigger] = nil
        end
    end
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
function ConstructionDeliveryArea:load(xmlFile, key)
    self.alwaysActive = xmlFile:getValue(key .. '#alwaysActive', self.alwaysActive)

    --
    -- Load and check object trigger node if defined.
    --

    self.objectTrigger = xmlFile:getValue(key .. '.objectTrigger#node', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.objectTrigger ~= nil and not CollisionFlag.getHasFlagSet(self.objectTrigger, CollisionFlag.TRIGGER_VEHICLE) then
        Logging.xmlWarning(xmlFile, 'Missing collision flag TRIGGER_VEHICLE (bit 21) on trigger node "%s"', key .. '.objectTrigger#node')
    end

    --
    -- Load and check fill trigger node if defined.
    --

    self.fillTrigger = xmlFile:getValue(key .. '.fillTrigger#node', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.fillTrigger ~= nil and not CollisionFlag.getHasFlagSet(self.fillTrigger, CollisionFlag.FILLABLE) then
        Logging.xmlWarning(xmlFile, 'Missing collision flag FILLABLE (bit 30) on trigger node "%s"', key .. '.fillTrigger#node')
    end

    --
    -- Make sure delivery area got at least one trigger.
    --

    if not self.fillTrigger and not self.objectTrigger then
        Logging.xmlError(xmlFile, 'Delivery area does not have any triggers (%s)', key)
        return false
    end

    --
    -- Load meshes.
    --

    xmlFile:iterate(key .. '.meshes.mesh', function(_, meshKey)
        local mesh = SetActiveMesh.new(self.placeable)

        mesh:load(xmlFile, meshKey)
        table.insert(self.meshes[MeshType.SET_ACTIVE], mesh)
    end)

    return true
end

function ConstructionDeliveryArea:setIsEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled

        g_construction:debug('ConstructionDeliveryArea:setIsEnabled() index: %i  enabled: %s', self.index, tostring(enabled))

        if self.isServer then
            if self.objectTrigger then
                if enabled then
                    addTrigger(self.objectTrigger, 'objectTriggerCallback', self)
                else
                    removeTrigger(self.objectTrigger)

                    self.activeObjects = {}
                    self.registeredObjects = {}
                end
            end

            if self.fillTrigger then
                if enabled then
                    g_currentMission.nodeToObject[self.fillTrigger] = self
                else
                    g_currentMission.nodeToObject[self.fillTrigger] = nil
                end
            end
        end

        self:setVisibility(enabled)
    end
end

function ConstructionDeliveryArea:getIsEnabled()
    return self.enabled == true
end

function ConstructionDeliveryArea:setVisibility(visible)
    if self.objectTrigger then
        setVisibility(self.objectTrigger, visible)
    end

    if self.fillTrigger then
        setVisibility(self.fillTrigger, visible)
    end

    for _, mesh in ipairs(self.meshes[MeshType.SET_ACTIVE]) do
        if visible then
            mesh:activate()
        else
            mesh:deactivate()
        end
    end
end

-- Process all the active objects and return true if we successfully
-- delivered any amount from one or more of the objects.
--
---@return boolean didDeliverAnyAmount
function ConstructionDeliveryArea:processActiveObjects()
    local totalAmountDelivered = 0
    local removeObjects = {}

    for _, object in ipairs(self.activeObjects) do
        local amountDelivered, remove = self:processObject(object)

        totalAmountDelivered = totalAmountDelivered + amountDelivered

        if remove then
            table.insert(removeObjects, object)
        end
    end

    for _, object in ipairs(removeObjects) do
        table.removeElement(self.activeObjects, object)
        self.registeredObjects[object] = nil
    end

    return totalAmountDelivered > 0
end

-- Process delivery object for input material(s).
--
---@param object DeliveryObject
---@return number amountDelivered
---@return boolean removeObject
function ConstructionDeliveryArea:processObject(object)
    local amountDelivered = 0

    if not object.isDeleted and object.isAddedToMission then
        for fillUnitIndex, _ in ipairs(object:getFillUnits()) do
            local fillTypeIndex = object:getFillUnitFillType(fillUnitIndex)

            if fillTypeIndex and fillTypeIndex ~= FillType.UNKNOWN and object:getFillUnitFillLevel(fillUnitIndex) > 0 then
                local input = self.placeable:getInputByFillTypeIndex(fillTypeIndex)

                if input and not input:getIsDelivered() then
                    local remainingCapacity = input.amount - input.deliveredAmount
                    local fillLevelDelta = math.abs(object:addFillUnitFillLevel(
                        object:getOwnerFarmId(),
                        fillUnitIndex,
                        -remainingCapacity,
                        fillTypeIndex,
                        ToolType.UNDEFINED
                    ))
                    local amount = input:addFillLevel(fillLevelDelta)

                    amountDelivered = amountDelivered + amount

                    g_construction:debug('ConstructionDeliveryArea:process() delivered %.2f of fillType "%s"', amount, g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))

                    --
                    -- If object is marked as deleted (or removed from g_currentMission) after we processed fillUnit,
                    -- we break out of the loop in order to not process any further.
                    --

                    if object.isDeleted or not object.isAddedToMission then
                        return amountDelivered, true
                    end
                end
            end
        end
    else
        return 0, true
    end

    return amountDelivered, false
end

--
-- Callback from trigger when object with correct collision flag enters/leaves trigger.
--
---@param triggerId number
---@param otherActorId number | nil
---@param onEnter boolean
---@param onLeave boolean
function ConstructionDeliveryArea:objectTriggerCallback(triggerId, otherActorId, onEnter, onLeave)
    if (onEnter or onLeave) and otherActorId ~= nil and otherActorId ~= 0 then
        ---@type DeliveryObject | nil
        local object = g_currentMission:getNodeObject(otherActorId)

        if object ~= nil and object:isa(Vehicle) and object.getFillUnits ~= nil then
            if onEnter and self.registeredObjects[object] == nil then
                table.insert(self.activeObjects, 1, object)
                self.registeredObjects[object] = true

                g_construction:debug('Object registered: %s (total: %i)', tostring(object), #self.activeObjects)
            elseif onLeave and self.registeredObjects[object] ~= nil then
                table.removeElement(self.activeObjects, object)
                self.registeredObjects[object] = nil

                g_construction:debug('Object removed: %s (total: %i)', tostring(object), #self.activeObjects)
            end
        end
    end
end

--
-- Fill trigger callback functions.
-- These are called from game script by registering g_currentMission.nodeToObject[trigger] = this
--

---@return number
function ConstructionDeliveryArea:getFillUnitIndexFromNode(node)
    return 1
end

---@return number
function ConstructionDeliveryArea:getFillUnitExactFillRootNode(fillUnitIndex)
    return self.fillTrigger
end

---@return number
function ConstructionDeliveryArea:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, extraAttributes)
    local input = self.placeable:getInputByFillTypeIndex(fillTypeIndex)

    if input and not input:getIsDelivered() then
        return input:addFillLevel(fillLevelDelta)
    end

    return 0
end

---@return boolean
function ConstructionDeliveryArea:getFillUnitSupportsFillType(fillUnitIndex, fillTypeIndex)
    return self.placeable:getInputByFillTypeIndex(fillTypeIndex) ~= nil
end

---@return boolean
function ConstructionDeliveryArea:getFillUnitSupportsToolType(fillUnit, toolType, fillTypeIndex)
    return true
end

---@return boolean
function ConstructionDeliveryArea:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex)
    return self.placeable:getInputByFillTypeIndex(fillTypeIndex) ~= nil
end

---@return number
function ConstructionDeliveryArea:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
    local input = self.placeable:getInputByFillTypeIndex(fillTypeIndex)

    if input ~= nil then
        return input.amount - input.deliveredAmount
    end

    return 0
end

---@param farmId number
function ConstructionDeliveryArea:getIsFillAllowedFromFarm(farmId)
    if g_construction:getRequireFarmAccess() then
        local placeableFarmId = self.placeable:getOwnerFarmId()

        return placeableFarmId == FarmManager.SPECTATOR_FARM_ID or placeableFarmId == farmId
    end

    return true
end
