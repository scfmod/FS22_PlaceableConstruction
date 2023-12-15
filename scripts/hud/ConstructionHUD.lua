---@class ConstructionHUD
---@field timeSinceLastUpdate number
---@field placeable PlaceableConstruction | nil
---@field layout BoxLayoutElement
---@field header HeaderElement
---@field details DetailsElement
---@field inputList InputListElement
---@field lastIndex number
ConstructionHUD = {}

ConstructionHUD.UPDATE_INTERVAL = 400
ConstructionHUD.XML_FILENAME = g_currentModDirectory .. 'xml/hud/ConstructionHUD.xml'

local ConstructionHUD_mt = Class(ConstructionHUD)

function ConstructionHUD.new()
    ---@type ConstructionHUD
    local self = setmetatable({}, ConstructionHUD_mt)

    self.timeSinceLastUpdate = 0

    if g_client then
        g_messageCenter:subscribe(MessageType.CONSTRUCTION_PLACEABLE_REMOVED, self.onPlaceableRemoved, self)
    end

    return self
end

function ConstructionHUD:load()
    ---@type XMLFile | nil
    local xmlFile = XMLFile.load('constructionHud', ConstructionHUD.XML_FILENAME)

    if xmlFile ~= nil then
        self:loadHudElement(xmlFile, 'HUD')

        self.layout:updateAbsolutePosition()
        self.layout:onGuiSetupFinished()

        self:updatePosition()

        xmlFile:delete()
    else
        Logging.error('ConstructionHUD:load() Failed to load xml file: %s', ConstructionHUD.XML_FILENAME)
    end
end

function ConstructionHUD:reload()
    if self.layout ~= nil then
        self.layout:delete()
        self.layout = nil
    end

    self:load()
end

---@param xmlFile XMLFile
---@param basePath string
---@param parent GuiElement | nil
function ConstructionHUD:loadHudElement(xmlFile, basePath, parent)
    basePath = string.format('%s.HudElement', basePath)

    xmlFile:iterate(basePath, function(_, key)
        local type = xmlFile:getString(key .. '#type', 'empty')
        local class = Gui.CONFIGURATION_CLASS_MAPPING[type] or GuiElement

        ---@type GuiElement
        local element = class.new()

        element:loadFromXML(xmlFile.handle, key)
        element:applyProfile(xmlFile:getString(key .. '#profile'))

        if parent ~= nil then
            parent:addElement(element)
        end

        self:loadHudElement(xmlFile, key, element)

        self:onCreateElement(element, parent)
    end)
end

---@param element GuiElement
---@param parent GuiElement | nil
function ConstructionHUD:onCreateElement(element, parent)
    if element.id ~= nil then
        self[element.id] = element
    end
end

function ConstructionHUD:updatePosition()
    if self.layout ~= nil then
        self.layout:applyProfile(Construction.HUD_POSITION_PROFILE[g_construction:getHudPosition()])
    end
end

function ConstructionHUD:getPlaceable()
    return self.placeable
end

---@param placeable PlaceableConstruction | nil
function ConstructionHUD:setPlaceable(placeable)
    if self.placeable ~= placeable then
        self.placeable = placeable

        if placeable ~= nil then
            self:activate(placeable)
        else
            self:deactivate()
        end
    end
end

---@param placeable PlaceableConstruction
function ConstructionHUD:activate(placeable)
    self.timeSinceLastUpdate = 0
    self.lastIndex = placeable:getStateIndex()

    if self.layout ~= nil then
        self.header:setText(placeable:getName())
        self.details:refresh()
        self.inputList:reloadData()
    end

    g_currentMission:addDrawable(self)
    g_currentMission:addUpdateable(self)
end

function ConstructionHUD:deactivate()
    g_currentMission:removeDrawable(self)
    g_currentMission:removeUpdateable(self)
end

---@param dt number
function ConstructionHUD:update(dt)
    if self.layout ~= nil then
        local placeable = self:getPlaceable()

        if placeable ~= nil and not placeable:getIsCompleted() then
            self.timeSinceLastUpdate = self.timeSinceLastUpdate + dt

            if self.timeSinceLastUpdate > ConstructionHUD.UPDATE_INTERVAL then
                if self.inputList ~= nil then
                    self.inputList:reloadData()
                    self.lastIndex = placeable:getStateIndex()
                end

                self.timeSinceLastUpdate = 0
            end
        end
    end
end

function ConstructionHUD:draw()
    if self.layout ~= nil then
        local placeable = self:getPlaceable()

        if placeable ~= nil and not placeable:getIsCompleted() and ConstructionUtils.getPlayerHasAccess(placeable) then
            local state = placeable:getActiveState()

            if state:getIsAwaitingDelivery() or state:getIsProcessing() then
                if self.lastIndex ~= state.index then
                    self.inputList:reloadData()
                    self.lastIndex = state.index
                else
                    self.inputList:refresh()
                end
                self.inputList:setVisible(true)
            else
                self.inputList:setVisible(false)
            end

            self.details:refresh()
            self.layout:draw()
        end
    end
end

--
-- Callback from message center.
--
function ConstructionHUD:onPlaceableRemoved(placeable)
    if self:getPlaceable() == placeable then
        self:setPlaceable(nil)
    end
end
