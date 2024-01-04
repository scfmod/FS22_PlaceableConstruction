--[[
    Append function to SavegameController:onSaveComplete() so that we can
    use it to save our settings.
]]

local function post_SavegameController_onSaveComplete(self, errorCode)
    if errorCode == Savegame.ERROR_OK and g_construction ~= nil then
        g_construction:saveSettings()
    end
end

if g_server ~= nil then
    SavegameController.onSaveComplete = Utils.appendedFunction(SavegameController.onSaveComplete, post_SavegameController_onSaveComplete)
end
