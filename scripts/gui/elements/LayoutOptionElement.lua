---@class LayoutOptionElement : MultiTextOptionElement
---@field iconElement BitmapElement
---@field isLoaded boolean
---@field superClass fun(): MultiTextOptionElement
LayoutOptionElement = {}

local LayoutOptionElement_mt = Class(LayoutOptionElement, MultiTextOptionElement)

function LayoutOptionElement.new(target, custom_mt)
    ---@type LayoutOptionElement
    local self = MultiTextOptionElement.new(target, custom_mt or LayoutOptionElement_mt)

    self.isLoaded = false

    return self
end

function LayoutOptionElement:onGuiSetupFinished()
    LayoutOptionElement:superClass().onGuiSetupFinished(self)

    self:setTexts({
        g_constructionUIFilename,
        g_constructionUIFilename,
        g_constructionUIFilename
    })

    self.isLoaded = true
end

function LayoutOptionElement:updateContentElement()
    LayoutOptionElement:superClass().updateContentElement(self)

    if self.isLoaded and self.iconElement ~= nil then
        self.iconElement:setImageUVs(nil, unpack(Construction.HUD_POSITION_ICON_UVS[self.state]))
    end
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionLayoutOption'] = LayoutOptionElement
-- Required for sounds to work on the option element
Gui.ELEMENT_PROCESSING_FUNCTIONS['constructionLayoutOption'] = Gui.assignPlaySampleCallback
