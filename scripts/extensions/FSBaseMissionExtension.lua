--[[
    Synchronize settings when client joins multiplayer game.
]]

---@param connection Connection
---@param user User
---@param farm Farm
local function post_FSBaseMission_sendInitialClientState(self, connection, user, farm)
    local event = SetConstructionSettingsEvent.new(g_construction.settings)

    connection:sendEvent(event)
end

if g_server ~= nil then
    FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, post_FSBaseMission_sendInitialClientState)
end
