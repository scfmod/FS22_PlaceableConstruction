--[[
    Event for synchronizing settings between clients and server.
]]

---@class SetConstructionSettingsEvent : Event
---@field settings ConstructionSettings
SetConstructionSettingsEvent = {}

local SetConstructionSettingsEvent_mt = Class(SetConstructionSettingsEvent, Event)

InitEventClass(SetConstructionSettingsEvent, 'SetConstructionSettingsEvent')

function SetConstructionSettingsEvent.emptyNew()
    ---@type SetConstructionSettingsEvent
    local self = Event.new(SetConstructionSettingsEvent_mt)
    return self
end

---@param settings ConstructionSettings
function SetConstructionSettingsEvent.new(settings)
    local self = SetConstructionSettingsEvent.emptyNew()

    ---@diagnostic disable-next-line: assign-type-mismatch
    self.settings = table.copy(settings)

    return self
end

function SetConstructionSettingsEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.settings.requireActivatePermission)
    streamWriteBool(streamId, self.settings.requireHudPermission)
    streamWriteBool(streamId, self.settings.requirePlaceablePermission)
    streamWriteBool(streamId, self.settings.requireHotspotPermission)

    streamWriteBool(streamId, self.settings.enableVisitButton)
    streamWriteBool(streamId, self.settings.enablePriceOverride)
    streamWriteBool(streamId, self.settings.enableHotspots)
    streamWriteBool(streamId, self.settings.enableBuyingPallets)
    streamWriteBool(streamId, self.settings.enableHotspotsWhenCompleted)
end

function SetConstructionSettingsEvent:readStream(streamId, connection)
    ---@diagnostic disable-next-line: missing-fields
    self.settings = {}

    self.settings.requireActivatePermission = streamReadBool(streamId)
    self.settings.requireHudPermission = streamReadBool(streamId)
    self.settings.requirePlaceablePermission = streamReadBool(streamId)
    self.settings.requireHotspotPermission = streamReadBool(streamId)

    self.settings.enableVisitButton = streamReadBool(streamId)
    self.settings.enablePriceOverride = streamReadBool(streamId)
    self.settings.enableHotspots = streamReadBool(streamId)
    self.settings.enableBuyingPallets = streamReadBool(streamId)
    self.settings.enableHotspotsWhenCompleted = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetConstructionSettingsEvent:run(connection)
    if connection:getIsServer() then
        g_construction:updateSettings(self.settings, true)
    else
        g_construction:updateSettings(self.settings)
    end
end

---@param settings ConstructionSettings
---@param noEventSend boolean | nil
function SetConstructionSettingsEvent.sendEvent(settings, noEventSend)
    if not noEventSend then
        local event = SetConstructionSettingsEvent.new(settings)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
