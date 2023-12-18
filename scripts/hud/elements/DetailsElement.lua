---@class DetailsElement : BitmapElement
---@field isLoaded boolean
---@field icon BitmapElement
---@field title TextElement
---@field subTitle TextElement
---@field text TextElement
---@field progressBar InputProgressElement
---
---@field superClass fun(): BitmapElement
DetailsElement = {}

local DetailsElement_mt = Class(DetailsElement, BitmapElement)

function DetailsElement.new(target, customMt)
    ---@type DetailsElement
    local self = BitmapElement.new(target, customMt or DetailsElement_mt)

    return self
end

function DetailsElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    if not self.isLoaded then
        self:registerElements()

        self.isLoaded = true
    end
end

function DetailsElement:registerElements()
    for _, element in ipairs(self.elements) do
        if element.name ~= nil then
            self[element.name] = element
        end
    end
end

function DetailsElement:refresh()
    local placeable = g_constructionHud:getPlaceable()

    if placeable ~= nil then
        if not placeable:getIsCompleted() then
            local state = placeable:getActiveState()

            self.title:setText(state:getTitle())
            self.subTitle:setText(string.format('%i / %i', state.displayIndex, placeable:getNumStatesWithInputs()))

            local isAwaitingDelivery = state:getIsAwaitingDelivery()
            local isProcessing = state:getIsProcessing()

            if isAwaitingDelivery then
                self.icon:setImageUVs(nil, unpack(Construction.STATUS_ICON_UVS[Construction.STATE_ACTIVE]))

                local text = Construction.STATUS_L10N[Construction.STATE_ACTIVE]

                if isProcessing then
                    text = text .. '\n' .. Construction.STATUS_L10N[Construction.STATE_PROCESSING]
                end

                self.text:setText(text)
            elseif isProcessing then
                self.icon:setImageUVs(nil, unpack(Construction.STATUS_ICON_UVS[Construction.STATE_PROCESSING]))
                self.text:setText(Construction.STATUS_L10N[Construction.STATE_PROCESSING])
            end

            self.progressBar:setDeliveryValue(state:getDeliveryProgress())
            self.progressBar:setProcessValue(state:getProcessingProgress())
        end
    end
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionHudDetails'] = DetailsElement
