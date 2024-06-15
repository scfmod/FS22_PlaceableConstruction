---@class HeaderElement :BitmapElement
---@field title TextElement
---@field text TextElement
---@field progressBar ProgressBarElement
---
---@field superClass fun(): BitmapElement
HeaderElement = {}

local HeaderElement_mt = Class(HeaderElement, BitmapElement)

function HeaderElement.new(target, customMt)
    ---@type HeaderElement
    local self = BitmapElement.new(target, customMt or HeaderElement_mt)

    return self
end

function HeaderElement:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self:registerElements()
end

function HeaderElement:registerElements()
    for _, element in ipairs(self.elements) do
        if element.name ~= nil then
            self[element.name] = element
        end
    end
end

---@param title string
function HeaderElement:setTitle(title)
    if self.title then
        self.title:setText(title)
    end
end

function HeaderElement:refresh()
    local placeable = g_constructionHud:getPlaceable()

    if placeable and not placeable:getConstructionIsCompleted() then
        local state = placeable:getActiveConstructionState()

        self.text:setText(string.format(
            '%s (%i / %i)',
            state:getTitle(), state.displayIndex, placeable:getNumStatesWithInputs()
        ))

        self.progressBar:setPrimary(state:getDeliveryProgress())
        self.progressBar:setSecondary(state:getProcessingProgress())
    end
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionHudHeader'] = HeaderElement
