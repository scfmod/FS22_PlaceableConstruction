---@class ConstructionObjectDeliveryRequestEvent : Event
---@field placeable PlaceableConstruction
ConstructionObjectDeliveryRequestEvent = {}

local ConstructionObjectDeliveryRequestEvent_mt = Class(ConstructionObjectDeliveryRequestEvent)

InitEventClass(ConstructionObjectDeliveryRequestEvent, 'ConstructionObjectDeliveryRequestEvent')

function ConstructionObjectDeliveryRequestEvent.emptyNew()
    ---@type ConstructionObjectDeliveryRequestEvent
    local self = Event.new(ConstructionObjectDeliveryRequestEvent_mt)

    return self
end

---@param placeable PlaceableConstruction
function ConstructionObjectDeliveryRequestEvent.new(placeable)
    local self = ConstructionObjectDeliveryRequestEvent.emptyNew()

    self.placeable = placeable

    return self
end

---@param streamId number
---@param connection Connection
function ConstructionObjectDeliveryRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
end

---@param streamId number
---@param connection Connection
function ConstructionObjectDeliveryRequestEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end

---@param connection Connection
function ConstructionObjectDeliveryRequestEvent:run(connection)
    if connection:getIsClient() and self.placeable and self.placeable:getIsSynchronized() then
        self.placeable:processDeliveryAreas()
    end
end

---@param placeable PlaceableConstruction
---@param noEventSend boolean | nil
function ConstructionObjectDeliveryRequestEvent.sendEvent(placeable, noEventSend)
    if not noEventSend and g_client then
        g_client:getServerConnection():sendEvent(ConstructionObjectDeliveryRequestEvent.new(placeable))
    end
end
