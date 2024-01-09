---@class SetConstructionStateRequestEvent : Event
---@field index number
---@field placeable PlaceableConstruction
SetConstructionStateRequestEvent = {}

local SetConstructionStateRequestEvent_mt = Class(SetConstructionStateRequestEvent, Event)

InitEventClass(SetConstructionStateRequestEvent, 'SetConstructionStateRequestEvent')

function SetConstructionStateRequestEvent.emptyNew()
    ---@type SetConstructionStateRequestEvent
    local self = Event.new(SetConstructionStateRequestEvent_mt)

    return self
end

---@nodiscard
---@param index number
---@param placeable PlaceableConstruction
---@return SetConstructionStateRequestEvent
function SetConstructionStateRequestEvent.new(index, placeable)
    local self = SetConstructionStateRequestEvent.emptyNew()

    self.index = index
    self.placeable = placeable

    return self
end

---@param streamId number
---@param connection Connection
function SetConstructionStateRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUInt8(streamId, self.index)
end

---@param streamId number
---@param connection Connection
function SetConstructionStateRequestEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUInt8(streamId)

    self:run(connection)
end

---@param connection Connection
function SetConstructionStateRequestEvent:run(connection)
    if connection:getIsClient() and self.placeable and self.placeable:getIsSynchronized() then
        self.placeable:setStateIndex(self.index)
    end
end

---@param stateIndex number
---@param placeable PlaceableConstruction
---@param noEventSend boolean | nil
function SetConstructionStateRequestEvent.sendEvent(stateIndex, placeable, noEventSend)
    if not noEventSend and g_client then
        g_client:getServerConnection():sendEvent(SetConstructionStateRequestEvent.new(stateIndex, placeable))
    end
end
