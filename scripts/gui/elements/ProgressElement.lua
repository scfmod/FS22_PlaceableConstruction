---@class ProgressElement : BitmapElement
---@field progress BitmapElement
---@field fullWidth number
---@field activeColor number[]
---@field completedColor number[]
---@field superClass fun(): BitmapElement
ProgressElement = {}

local ProgressElement_mt = Class(ProgressElement, BitmapElement)

function ProgressElement.new(target, custom_mt)
    ---@type ProgressElement
    local self = BitmapElement.new(target, custom_mt or ProgressElement_mt)

    self.activeColor = { 0.8, 0.28, 0.02, 1 }
    self.completedColor = { 0.7, 0.85, 0.04, 1 }

    return self
end

function ProgressElement:loadFromXML(xmlFile, key)
    self:superClass().loadFromXML(self, xmlFile, key)

    self.activeColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#progressColor'), self.activeColor)
    self.completedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#progressCompletedColor'), self.completedColor)
end

function ProgressElement:loadProfile(profile, applyProfile)
    self:superClass().loadProfile(self, profile, applyProfile)

    self.activeColor = GuiUtils.getColorArray(profile:getValue('progressColor'), self.activeColor)
    self.completedColor = GuiUtils.getColorArray(profile:getValue('progressCompletedColor'), self.completedColor)
end

function ProgressElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self:registerElements()
end

function ProgressElement:registerElements()
    self.progress = self.elements[1]

    if self.progress == nil then
        Logging.warning('ProgressElement:registerElements() unable to find progress element')
    end
end

---@return ProgressElement
function ProgressElement:clone(parent, includeId, suppressOnCreate)
    local clone = self:superClass().clone(self, parent, includeId, suppressOnCreate)

    clone:registerElements()
    clone.activeColor = table.copy(self.activeColor)
    clone.completedColor = table.copy(self.completedColor)

    return clone
end

function ProgressElement:setValue(value)
    value = value or 0
    value = MathUtil.round(value, 4)

    if self.progress ~= nil then
        if value <= 0 then
            self.progress:setVisible(false)
        else
            local fullWidth = self.absSize[1] - self.progress.margin[1] * 2

            self.progress:setSize(math.max(0, fullWidth * math.min(1, value)), nil)

            if value < 1 then
                self.progress:setImageColor(GuiOverlay.STATE_NORMAL, unpack(self.activeColor))
            else
                self.progress:setImageColor(GuiOverlay.STATE_NORMAL, unpack(self.completedColor))
            end

            self.progress:setVisible(true)
        end
    end
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionProgress'] = ProgressElement
