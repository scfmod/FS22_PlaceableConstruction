--[[
    Override the loadOverlay to enable us to reference global filenames
    referenced in "imageFilename" property by BitmapElement and inherited elements.

    [Gui/GuiProfiles XML]
]]

local function inj_GuiOverlay_loadOverlay(self, superFunc, overlay, ...)
    ---@type Overlay
    local result_overlay = superFunc(self, overlay, ...)

    if overlay ~= nil and result_overlay ~= nil then
        if overlay.filename == 'g_constructionUIFilename' then
            result_overlay.filename = g_constructionUIFilename
        end
    end

    return result_overlay
end

GuiOverlay.loadOverlay = Utils.overwrittenFunction(GuiOverlay.loadOverlay, inj_GuiOverlay_loadOverlay)
