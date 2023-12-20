---@class ProgressBarElement : BitmapElement
---@field fullWidth number
---@field fullHeight number
---@field active boolean
---@field value number
---
---@field primaryElement BitmapElement
---@field secondaryElement BitmapElement
---
---@field primaryColor number[]
---@field primaryDisabledColor number[]
---
---@field secondaryColor number[]
---@field secondaryDisabledColor number[]
---
---@field backgroundColor number[]
---@field backgroundDisabledColor number[]
---
---@field frameColor number[]
---@field frameDisabledColor number[]
---@field frameInactiveColor number[]
---
---@field superClass fun(): BitmapElement
ProgressBarElement = {}

local ProgressBarElement_mt = Class(ProgressBarElement, BitmapElement)

function ProgressBarElement.new(target, custom_mt)
    ---@type ProgressBarElement
    local self = BitmapElement.new(target, custom_mt or ProgressBarElement_mt)

    self.value = 0
    self.active = true

    self.primaryColor = { 1, 1, 1, 1 }
    self.primaryDisabledColor = { 1, 1, 1, 0.1 }

    self.secondaryColor = { 0, 0, 1, 1 }
    self.secondaryDisabledColor = { 0, 0, 1, 0.1 }

    self.frameColor = { 0, 0, 1, 1 }
    self.frameInactiveColor = { 1, 0, 0, 1 }
    self.frameDisabledColor = { 1, 0, 0, 0.1 }

    self.backgroundColor = { 0, 0, 0, 0.75 }
    self.backgroundDisabledColor = { 0, 0, 0, 0.15 }

    return self
end

function ProgressBarElement:loadFromXML(xmlFile, key)
    self:superClass().loadFromXML(self, xmlFile, key)

    self.primaryColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#primaryColor'), self.primaryColor)
    self.primaryDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#primaryDisabledColor'), self.primaryDisabledColor)

    self.secondaryColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#secondaryColor'), self.secondaryColor)
    self.secondaryDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#secondaryDisabledColor'), self.secondaryDisabledColor)

    self.backgroundColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#backgroundColor'), self.backgroundColor)
    self.backgroundDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#backgroundDisabledColor'), self.backgroundDisabledColor)

    self.frameColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#frameColor'), self.frameColor)
    self.frameDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#frameDisabledColor'), self.frameDisabledColor)
    self.frameInactiveColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#frameInactiveColor'), self.frameInactiveColor)
end

function ProgressBarElement:loadProfile(profile, applyProfile)
    self:superClass().loadProfile(self, profile, applyProfile)

    self.primaryColor = GuiUtils.getColorArray(profile:getValue('primaryColor'), self.primaryColor)
    self.primaryDisabledColor = GuiUtils.getColorArray(profile:getValue('primaryDisabledColor'), self.primaryDisabledColor)

    self.secondaryColor = GuiUtils.getColorArray(profile:getValue('secondaryColor'), self.secondaryColor)
    self.secondaryDisabledColor = GuiUtils.getColorArray(profile:getValue('secondaryDisabledColor'), self.secondaryDisabledColor)

    self.backgroundColor = GuiUtils.getColorArray(profile:getValue('backgroundColor'), self.backgroundColor)
    self.backgroundDisabledColor = GuiUtils.getColorArray(profile:getValue('backgroundDisabledColor'), self.backgroundDisabledColor)

    self.frameColor = GuiUtils.getColorArray(profile:getValue('frameColor'), self.frameColor)
    self.frameDisabledColor = GuiUtils.getColorArray(profile:getValue('frameDisabledColor'), self.frameDisabledColor)
    self.frameInactiveColor = GuiUtils.getColorArray(profile:getValue('frameInactiveColor'), self.frameInactiveColor)
end

function ProgressBarElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.fullWidth = self.absSize[1]
    self.fullHeight = self.absSize[2]

    self:registerElements()

    self:updateBorderColor()
    self:updateBackgroundColor()
    self:updateElementColors()
end

function ProgressBarElement:registerElements()
    self.primaryElement = self.elements[1]
    self.secondaryElement = self.elements[2]

    if not self.primaryElement then
        Logging.warning('ProgressBarElement:registerElements() primaryElement not found')
    end
end

function ProgressBarElement:clone(parent, includeId, suppressOnCreate)
    local clone = self:superClass().clone(self, parent, includeId, suppressOnCreate)

    clone.primaryColor = table.copy(self.primaryColor)
    clone.primaryDisabledColor = table.copy(self.primaryDisabledColor)

    clone.secondaryColor = table.copy(self.secondaryColor)
    clone.secondaryDisabledColor = table.copy(self.secondaryDisabledColor)

    clone.backgroundColor = table.copy(self.backgroundColor)
    clone.backgroundDisabledColor = table.copy(self.backgroundDisabledColor)

    clone.frameColor = table.copy(self.frameColor)
    clone.frameDisabledColor = table.copy(self.frameDisabledColor)
    clone.frameInactiveColor = table.copy(self.frameInactiveColor)

    clone:registerElements()

    return clone
end

---@param disabled boolean
---@param doNotUpdateChildren boolean | nil
function ProgressBarElement:setDisabled(disabled, doNotUpdateChildren)
    local previous = self.disabled

    self:superClass().setDisabled(self, disabled, doNotUpdateChildren)

    if disabled ~= previous then
        self:updateBorderColor()
        self:updateElementColors()
        self:updateBackgroundColor()
    end
end

---@param active boolean
function ProgressBarElement:setActive(active)
    if self.active ~= active then
        self.active = active

        self:updateBorderColor()
    end
end

function ProgressBarElement:updateBackgroundColor()
    if self.disabled then
        self:setImageColor(nil, unpack(self.backgroundDisabledColor))
    else
        self:setImageColor(nil, unpack(self.backgroundColor))
    end
end

function ProgressBarElement:updateBorderColor()
    if self.hasFrame then
        if self.disabled then
            self:setBorderColor(self.frameDisabledColor)
        else
            self:setBorderColor(self.active and self.frameColor or self.frameInactiveColor)
        end
    end
end

function ProgressBarElement:updateElementColors()
    if self.disabled then
        self:setElementColor(self.primaryElement, self.primaryDisabledColor)
        self:setElementColor(self.secondaryElement, self.secondaryDisabledColor)
    else
        self:setElementColor(self.primaryElement, self.primaryColor)
        self:setElementColor(self.secondaryElement, self.secondaryColor)
    end
end

---@param element BitmapElement | nil
---@param color number[]
function ProgressBarElement:setElementColor(element, color)
    if element ~= nil then
        element:setImageColor(nil, unpack(color))
    end
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
---@param setAsValue boolean | nil
function ProgressBarElement:updateElementSize(element, value, setAsValue)
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

    if setAsValue then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.value = value
    end
end

---@param value number
function ProgressBarElement:setPrimary(value)
    if self.primaryElement then
        self:updateElementSize(self.primaryElement, value, true)
        self:setActive(value > 0)
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
