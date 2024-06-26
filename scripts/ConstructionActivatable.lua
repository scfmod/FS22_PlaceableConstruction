---@class ConstructionActivatable
---@field placeable PlaceableConstruction
---@field activateText string
---@field activateEventId string | nil
---@field openMenuEventId string | nil
ConstructionActivatable = {}

ConstructionActivatable.L10N_TEXTS = {
    ACTIVATE = g_i18n:getText('action_deliverMaterials'),
    OPEN_MENU = g_i18n:getText('action_openMenu')
}

local ConstructionActivatable_mt = Class(ConstructionActivatable)

---@nodiscard
---@param placeable PlaceableConstruction
---@return ConstructionActivatable
function ConstructionActivatable.new(placeable)
    ---@type ConstructionActivatable
    local self = setmetatable({}, ConstructionActivatable_mt)

    self.placeable = placeable
    self.activateText = ConstructionActivatable.L10N_TEXTS.ACTIVATE

    return self
end

function ConstructionActivatable:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self)
end

function ConstructionActivatable:activate()
    g_constructionHud:setPlaceable(self.placeable)
end

function ConstructionActivatable:deactivate()
    g_constructionHud:setPlaceable(nil)
end

---@nodiscard
---@return boolean
function ConstructionActivatable:getIsActivatable()
    if not self.placeable:getConstructionIsCompleted() then
        return ConstructionUtils.getPlayerHasAccess(self.placeable)
    end

    return false
end

function ConstructionActivatable:onPressActivate()
    if self.placeable:getConstructionIsAwaitingDelivery() then
        if self.placeable.isServer then
            self.placeable:processConstructionDeliveryAreas()
        else
            ConstructionObjectDeliveryRequestEvent.sendEvent(self.placeable)
        end
    end
end

function ConstructionActivatable:onPressMenu()
    g_gui:showGui('InGameMenu')
    g_messageCenter:publishDelayed(MessageType.GUI_INGAME_OPEN_CONSTRUCTIONS_SCREEN, self.placeable)
end

---@nodiscard
---@return number
function ConstructionActivatable:getDistance(x, y, z)
    local tx, ty, tz = self.placeable:getActivationTriggerPosition()

    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end

---
--- Register custom input action events.
---
function ConstructionActivatable:registerCustomInput(context)
    local _, actionEventId = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onPressActivate, false, true, false, true)

    g_inputBinding:setActionEventText(actionEventId, ConstructionActivatable.L10N_TEXTS.ACTIVATE)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventTextVisibility(actionEventId, true)

    self.activateEventId = actionEventId

    _, actionEventId = g_inputBinding:registerActionEvent(InputAction.ATTACH, self, self.onPressMenu, false, true, false, true)

    g_inputBinding:setActionEventText(actionEventId, ConstructionActivatable.L10N_TEXTS.OPEN_MENU)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
    g_inputBinding:setActionEventTextVisibility(actionEventId, true)

    self.openMenuEventId = actionEventId
end

---
--- Remove custom input action events.
---
function ConstructionActivatable:removeCustomInput()
    if self.activateEventId ~= nil then
        g_inputBinding:removeActionEvent(self.activateEventId)
        self.activateEventId = nil
    end

    if self.openMenuEventId ~= nil then
        g_inputBinding:removeActionEvent(self.openMenuEventId)
        self.openMenuEventId = nil
    end
end
