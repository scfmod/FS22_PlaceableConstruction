---@class InputListItemElement : BitmapElement
---@field icon BitmapElement
---@field title TextElement
---@field text TextElement
---@field progressBar ProgressBarElement
---
---@field superClass fun(): BitmapElement
InputListItemElement = {}

local InputListItemElement_mt = Class(InputListItemElement, BitmapElement)

function InputListItemElement.new(target, customMt)
    ---@type InputListItemElement
    local self = BitmapElement.new(target, customMt or InputListItemElement_mt)

    return self
end

function InputListItemElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self:registerElements()
end

function InputListItemElement:registerElements()
    for _, element in ipairs(self.elements) do
        if element.name ~= nil then
            self[element.name] = element
        end
    end
end

function InputListItemElement:clone(parent, includeId, suppressOnCreate)
    ---@type InputListItemElement
    local element = BitmapElement.clone(self, parent, includeId, suppressOnCreate)

    element:registerElements()

    return element
end

---@param title string
function InputListItemElement:setTitle(title)
    if self.title ~= nil then
        self.title:setText(title)
    end
end

---@param text string
function InputListItemElement:setText(text)
    if self.text ~= nil then
        self.text:setText(text)
    end
end

---@param fillType FillTypeObject | nil
function InputListItemElement:setFillTypeIcon(fillType)
    if self.icon ~= nil then
        if fillType ~= nil then
            self.icon:setImageFilename(fillType.hudOverlayFilename)
        else
            self.icon:setImageFilename('dataS/menu/hud/fillTypes/hud_fill_empty.png')
        end
    end
end

---@param value number
function InputListItemElement:setDeliveryProgress(value)
    if self.progressBar ~= nil then
        self.progressBar:setPrimary(value)
    end
end

---@param value number
function InputListItemElement:setProcessProgress(value)
    if self.progressBar ~= nil then
        self.progressBar:setSecondary(value)
    end
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionHudInputListItem'] = InputListItemElement
