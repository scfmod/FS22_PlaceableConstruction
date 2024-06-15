---@class SetConstructionStateEvent : Event
---@field index number
---@field placeable PlaceableConstruction
SetConstructionStateEvent = {}

local SetConstructionStateEvent_mt = Class(SetConstructionStateEvent, Event)

InitEventClass(SetConstructionStateEvent, 'SetConstructionStateEvent')

function SetConstructionStateEvent.emptyNew()
    ---@type SetConstructionStateEvent
    local self = Event.new(SetConstructionStateEvent_mt)

    return self
end

---@nodiscard
---@param index number
---@param placeable PlaceableConstruction
---@return SetConstructionStateEvent
function SetConstructionStateEvent.new(index, placeable)
    local self = SetConstructionStateEvent.emptyNew()

    self.index = index
    self.placeable = placeable

    return self
end

---@param streamId number
---@param connection Connection
function SetConstructionStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUInt8(streamId, self.index)
end

---@param streamId number
---@param connection Connection
function SetConstructionStateEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUInt8(streamId)

    self:run(connection)
end

---@param connection Connection
function SetConstructionStateEvent:run(connection)
    if connection:getIsServer() and self.placeable and self.placeable:getIsSynchronized() then
        self.placeable:setConstructionStateIndex(self.index)
    end
end

---@param stateIndex number
---@param placeable PlaceableConstruction
---@param noEventSend boolean | nil
function SetConstructionStateEvent.sendEvent(stateIndex, placeable, noEventSend)
    if not noEventSend and g_server then
        g_server:broadcastEvent(SetConstructionStateEvent.new(stateIndex, placeable))
    end
end
