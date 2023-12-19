---@class ProgressBarElement : BitmapElement
---@field fullWidth number
---@field fullHeight number
---@field active boolean
---
---@field primaryElement BitmapElement
---@field secondaryElement BitmapElement
---
---@field primaryColor number[]
---@field secondaryColor number[]
---@field frameColor number[]
---@field frameDisabledColor number[]
---
---@field superClass fun(): BitmapElement
ProgressBarElement = {}

local ProgressBarElement_mt = Class(ProgressBarElement, BitmapElement)

function ProgressBarElement.new(target, custom_mt)
    ---@type ProgressBarElement
    local self = BitmapElement.new(target, custom_mt or ProgressBarElement_mt)

    self.active = true

    self.primaryColor = { 1, 1, 1, 1 }
    self.secondaryColor = { 0, 0, 1, 1 }
    self.frameColor = { 0, 0, 1, 1 }
    self.frameDisabledColor = { 1, 0, 0, 1 }

    return self
end

function ProgressBarElement:loadFromXML(xmlFile, key)
    self:superClass().loadFromXML(self, xmlFile, key)

    self.primaryColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#primaryColor'), self.primaryColor)
    self.secondaryColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#secondaryColor'), self.secondaryColor)

    self.frameColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#frameColor'), self.frameColor)
    self.frameDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#frameDisabledColor'), self.frameDisabledColor)
end

function ProgressBarElement:loadProfile(profile, applyProfile)
    self:superClass().loadProfile(self, profile, applyProfile)

    self.primaryColor = GuiUtils.getColorArray(profile:getValue('primaryColor'), self.primaryColor)
    self.secondaryColor = GuiUtils.getColorArray(profile:getValue('secondaryColor'), self.secondaryColor)

    self.frameColor = GuiUtils.getColorArray(profile:getValue('frameColor'), self.frameColor)
    self.frameDisabledColor = GuiUtils.getColorArray(profile:getValue('frameDisabledColor'), self.frameDisabledColor)
end

function ProgressBarElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.fullWidth = self.absSize[1]
    self.fullHeight = self.absSize[2]

    self:registerElements()

    self:setBorderColor(self:getIsDisabled() and self.frameDisabledColor or self.frameColor)
end

function ProgressBarElement:registerElements()
    self.primaryElement = self.elements[1]
    self.secondaryElement = self.elements[2]

    if self.primaryElement then
        self.primaryElement:setImageColor(nil, unpack(self.primaryColor))
    else
        Logging.warning('ProgressBarElement:registerElements() primaryElement not found')
    end

    if self.secondaryElement then
        self.secondaryElement:setImageColor(nil, unpack(self.secondaryColor))
    end
end

function ProgressBarElement:clone(parent, includeId, suppressOnCreate)
    local clone = self:superClass().clone(self, parent, includeId, suppressOnCreate)

    clone.primaryColor = table.copy(self.primaryColor)
    clone.secondaryColor = table.copy(self.secondaryColor)

    clone.frameColor = table.copy(self.frameColor)
    clone.frameDisabledColor = table.copy(self.frameDisabledColor)

    clone:registerElements()

    return clone
end

---@param disabled boolean
---@param doNotUpdateChildren boolean | nil
function ProgressBarElement:setDisabled(disabled, doNotUpdateChildren)
    self:superClass().setDisabled(self, disabled, doNotUpdateChildren)

    self:setBorderColor(disabled and self.frameDisabledColor or self.frameColor)
end

---@param color number[]
function ProgressBarElement:setBorderColor(color)
    if self.hasFrame then
        self.frameColors[GuiElement.FRAME_LEFT] = color
        self.frameColors[GuiElement.FRAME_TOP] = color
        self.frameColors[GuiElement.FRAME_RIGHT] = color
        self.frameColors[GuiElement.FRAME_BOTTOM] = color
    end
end

---@param element BitmapElement
---@param value number
function ProgressBarElement:updateElementSize(element, value)
    ---@diagnostic disable-next-line: cast-local-type
    value = MathUtil.round(value or 0, 4)

    if value <= 0 then
        element:setVisible(false)
    else
        local width = self.absSize[1]

        value = math.min(1, value)

        element:setSize(width * value, self.absSize[2])
        element:setVisible(true)
    end
end

---@param value number
function ProgressBarElement:setPrimary(value)
    if self.primaryElement then
        self:updateElementSize(self.primaryElement, value)

        self:setDisabled(value <= 0)
    end
end

---@param value number
function ProgressBarElement:setSecondary(value)
    if self.secondaryElement then
        self:updateElementSize(self.secondaryElement, value)
    end
end

-- Register custom GUI element
Gui.CONFIGURATION_CLASS_MAPPING['constructionProgressBar'] = ProgressBarElement
