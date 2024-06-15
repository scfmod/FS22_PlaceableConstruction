---@class ConstructionObjectDeliveryEvent : Event
---@field placeable PlaceableConstruction
ConstructionObjectDeliveryEvent = {}

local ConstructionObjectDeliveryEvent_mt = Class(ConstructionObjectDeliveryEvent, Event)

InitEventClass(ConstructionObjectDeliveryEvent, 'ConstructionObjectDeliveryEvent')

function ConstructionObjectDeliveryEvent.emptyNew()
    ---@type ConstructionObjectDeliveryEvent
    local self = Event.new(ConstructionObjectDeliveryEvent_mt)

    return self
end

---@nodiscard
---@param placeable PlaceableConstruction
---@return ConstructionObjectDeliveryEvent
function ConstructionObjectDeliveryEvent.new(placeable)
    local self = ConstructionObjectDeliveryEvent.emptyNew()

    self.placeable = placeable

    return self
end

---@param streamId number
---@param connection Connection
function ConstructionObjectDeliveryEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
end

---@param streamId number
---@param connection Connection
function ConstructionObjectDeliveryEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end

---@param connection Connection
function ConstructionObjectDeliveryEvent:run(connection)
    if connection:getIsServer() and self.placeable and self.placeable:getIsSynchronized() then
        self.placeable:playConstructionSample(SampleType.DELIVERY)
    end
end

---@param placeable PlaceableConstruction
---@param noEventSend boolean | nil
function ConstructionObjectDeliveryEvent.sendEvent(placeable, noEventSend)
    if not noEventSend and g_server ~= nil then
        g_server:broadcastEvent(ConstructionObjectDeliveryEvent.new(placeable))
    end
end
