---@class HeaderElement :BitmapElement
---@field text TextElement
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
    HeaderElement:superClass().onGuiSetupFinished(self)

    self:registerElements()
end

function HeaderElement:registerElements()
    for _, element in ipairs(self.elements) do
        if element.name ~= nil then
            self[element.name] = element
        end
    end
end

---@param text string
function HeaderElement:setText(text)
    if self.text ~= nil then
        self.text:setText(text)
    end
end

-- Register custom gui element
Gui.CONFIGURATION_CLASS_MAPPING['constructionHudHeader'] = HeaderElement
