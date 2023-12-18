---@class InputListElement : BitmapElement
---@field isLoaded boolean
---@field itemTemplate InputListItemElement
---@field itemRowHeight number
---@field itemStartPositionY number
---@field items InputListItemElement[]
---
---@field superClass fun(): BitmapElement
InputListElement = {}

local InputListElement_mt = Class(InputListElement, BitmapElement)

function InputListElement.new(target, customMt)
    ---@type InputListElement
    local self = BitmapElement.new(target, customMt or InputListElement_mt)

    self.isLoaded = false
    self.items = {}
    self.itemStartPositionY = 0

    return self
end

function InputListElement:delete()
    self:clear()

    if self.itemTemplate ~= nil then
        self.itemTemplate:delete()
        self.itemTemplate = nil
    end

    self:superClass().delete(self)
end

function InputListElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    if not self.isLoaded then
        self:createItemTemplate()
        self.isLoaded = true
    end
end

function InputListElement:createItemTemplate()
    ---@type InputListItemElement | nil
    local itemElement = self:getFirstDescendant(function(element)
        return element:isa(InputListItemElement)
    end)

    if itemElement == nil then
        Logging:warning('InputListElement:createItemTemplate() Could not find item template')
        return
    end

    self.itemTemplate = itemElement
    self.itemRowHeight = self.itemTemplate.absSize[2] + self.itemTemplate.margin[2] * 2

    itemElement:unlinkElement()
end

function InputListElement:clear()
    for _, item in ipairs(self.items) do
        item:delete()
    end

    self.items = {}
end

function InputListElement:build()
    local placeable = g_constructionHud:getPlaceable()

    if placeable ~= nil then
        local state = placeable:getActiveState()

        if state:getHasInputs() then
            for _, input in ipairs(state:getInputs()) do
                ---@type InputListItemElement
                local element = self.itemTemplate:clone(self, nil, true)

                table.insert(self.items, element)

                local fillType = input:getFillType()

                if fillType ~= nil then
                    element:setTitle(fillType.title)
                else
                    element:setTitle(input.fillTypeName)
                end

                element:setFillTypeIcon(fillType)
                element:setText(('%s / %s'):format(ConstructionUtils.formatNumber(input.deliveredAmount), ConstructionUtils.formatNumber(input.amount)))

                element:setDeliveryProgress(1 / input.amount * input.deliveredAmount)
                element:setProcessProgress(1 / input.amount * input.processedAmount)
            end
        end
    end
end

function InputListElement:updateElementPositions()
    for index, item in ipairs(self.items) do
        item:setPosition(nil, self.itemStartPositionY - self.itemRowHeight * (index - 1))
    end
end

function InputListElement:refresh()
    local placeable = g_constructionHud:getPlaceable()

    if placeable ~= nil then
        local state = placeable:getActiveState()

        if state:getHasInputs() then
            for _, input in ipairs(state:getInputs()) do
                local element = self.items[input.index]

                if element ~= nil then
                    element:setDeliveryProgress(1 / input.amount * input.deliveredAmount)
                    element:setProcessProgress(1 / input.amount * input.processedAmount)
                    element:setText(('%s / %s'):format(ConstructionUtils.formatNumber(input.deliveredAmount), ConstructionUtils.formatNumber(input.amount)))
                end
            end
        end
    end
end

function InputListElement:reloadData()
    self:clear()
    self:build()
    self:updateElementPositions()
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionHudInputList'] = InputListElement
