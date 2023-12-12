---@class InputProgressElement : BitmapElement
---@field delivery ProgressElement
---@field process ProgressElement
---@field superClass fun(): BitmapElement
InputProgressElement = {}

local InputProgressElement_mt = Class(InputProgressElement, BitmapElement)

function InputProgressElement.new(target, custom_mt)
    ---@type InputProgressElement
    local self = BitmapElement.new(target, custom_mt or InputProgressElement_mt)

    return self
end

function InputProgressElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self:registerElements()
end

function InputProgressElement:registerElements()
    self.delivery = self.elements[1]
    self.process = self.elements[2]

    if self.delivery == nil then
        Logging.warning('ProgressElement:registerElements() delivery progress element not found')
    end

    if self.process == nil then
        Logging.warning('ProgressElement:registerElements() process progress element not found')
    end
end

function InputProgressElement:clone(parent, includeId, suppressOnCreate)
    local clone = self:superClass().clone(self, parent, includeId, suppressOnCreate)

    clone:registerElements()

    return clone
end

---@param element BitmapElement
---@param pct number -- [0..1]
function InputProgressElement:setElementWidth(element, pct)
    if pct > 0 then
        local fullWidth = self.absSize[1] - element.margin[1] * 2

        element:setSize(math.max(0, fullWidth * math.min(1, pct)), nil)

        element:setVisible(true)
    else
        element:setVisible(false)
    end
end

---@param value number
function InputProgressElement:setDeliveryValue(value)
    if self.delivery ~= nil then
        self.delivery:setValue(value)
    end
end

function InputProgressElement:setProcessValue(value)
    if self.process ~= nil then
        self.process:setValue(value)
    end
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionInputProgress'] = InputProgressElement
