---@class InGameMenuConstructionsFrame : TabbedMenuFrameElement
---@field isOpen boolean
---@field placeables table<number, PlaceableConstruction[]>
---@field states ConstructionState[]
---
---@field timeSinceLastUpdate number
---@field constructionListLayout BitmapElement
---@field constructionList SmoothListElement
---@field inputListLayout BitmapElement
---@field inputList SmoothListElement
---@field statusLayout BitmapElement
---@field statusIcon BitmapElement
---@field statusText TextElement
---@field statusProgressBar ProgressBarElement
---@field backButtonInfo table
---
---@field superClass fun(): TabbedMenuFrameElement
InGameMenuConstructionsFrame = {}

InGameMenuConstructionsFrame.XML_FILENAME = g_currentModDirectory .. 'xml/gui/InGameMenuConstructionsFrame.xml'
InGameMenuConstructionsFrame.MENU_PAGE_NAME = 'ingameMenuConstructions'
InGameMenuConstructionsFrame.ICON_UVS = GuiUtils.getUVs('0 0 0.25 0.25')
InGameMenuConstructionsFrame.UPDATE_INTERVAL = 4000
InGameMenuConstructionsFrame.CONTROLS = {
    'constructionListLayout',
    'constructionList',
    'inputListLayout',
    'inputList',
    'statusLayout',
    'statusIcon',
    'statusText',
    'statusProgressBar'
}

---@type table<string, string>
InGameMenuConstructionsFrame.L10N_SECTION_TITLE = {
    g_i18n:getText('ui_sectionTitleActive'),
    g_i18n:getText('ui_sectionTitleCompleted')
}

local InGameMenuConstructionsFrame_mt = Class(InGameMenuConstructionsFrame, TabbedMenuFrameElement)

function InGameMenuConstructionsFrame.new()
    ---@type InGameMenuConstructionsFrame
    local self = TabbedMenuFrameElement.new(nil, InGameMenuConstructionsFrame_mt)

    self.isOpen = false

    self:registerControls(InGameMenuConstructionsFrame.CONTROLS)

    self.timeSinceLastUpdate = 0
    self.hasCustomMenuButtons = true
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }

    self.placeables = {
        {},
        {}
    }

    self.states = {}

    return self
end

function InGameMenuConstructionsFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.constructionList:setDataSource(self)
    self.inputList:setDataSource(self)

    self:initialize()
end

function InGameMenuConstructionsFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self.isOpen = true

    self:updatePlaceables()
    self:updateMenuButtons()

    FocusManager:setFocus(self.constructionList)

    -- Subscribe to message events when opening frame
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
    g_messageCenter:subscribe(MessageType.CONSTRUCTION_PLACEABLE_ADDED, self.onPlaceableAdded, self)
    g_messageCenter:subscribe(MessageType.CONSTRUCTION_PLACEABLE_REMOVED, self.onPlaceableRemoved, self)
    g_messageCenter:subscribe(MessageType.CONSTRUCTION_SETTINGS_CHANGED, self.onSettingsChanged, self)
    g_messageCenter:subscribe(MessageType.CONSTRUCTION_STARTED, self.onConstructionStarted, self)
    g_messageCenter:subscribe(MessageType.CONSTRUCTION_COMPLETED, self.onConstructionCompleted, self)
end

function InGameMenuConstructionsFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    self.isOpen = false
    self.placeables = {
        {},
        {}
    }
    self.states = {}

    g_messageCenter:unsubscribeAll(self)
end

function InGameMenuConstructionsFrame:initialize()
    self.visitButtonInfo = {
        profile = 'buttonVisitPlace',
        inputAction = InputAction.MENU_ACTIVATE,
        text = g_i18n:getText('action_visit'),
        callback = function()
            self:onClickVisitButton()
        end
    }

    self.settingsButtonInfo = {
        profile = 'buttonVisitPlace',
        inputAction = InputAction.MENU_EXTRA_2,
        text = g_i18n:getText('action_settings'),
        callback = function()
            self:onClickSettingsButton()
        end
    }

    self.inputsButtonInfo = {
        profile = 'buttonVisitPlace',
        inputAction = InputAction.MENU_EXTRA_1,
        text = g_i18n:getText('action_inputs'),
        callback = function()
            self:onClickInputsButton()
        end
    }

    self.statusLayout:setVisible(false)
end

function InGameMenuConstructionsFrame:updateMenuButtons()
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.settingsButtonInfo
    }

    if self:getSelectedPlaceable() ~= nil then
        if g_construction:getIsVisitButtonEnabled() then
            table.insert(self.menuButtonInfo, self.visitButtonInfo)
        end

        table.insert(self.menuButtonInfo, self.inputsButtonInfo)
    end

    self:setMenuButtonInfoDirty()
end

function InGameMenuConstructionsFrame:updatePlaceables()
    self.placeables = {
        {},
        {}
    }

    for _, placeable in ipairs(g_construction:getPlaceables()) do
        if placeable:getConstructionIsCompleted() then
            table.insert(self.placeables[2], placeable)
        else
            table.insert(self.placeables[1], placeable)
        end
    end

    self:sortPlaceables()
    self.constructionList:reloadData()

    self:updateStatus()
    self:updateInputs()

    self.timeSinceLastUpdate = 0
end

function InGameMenuConstructionsFrame:sortPlaceables()
    ---@param a PlaceableConstruction
    ---@param b PlaceableConstruction
    local function sort(a, b)
        return a:getName() < b:getName()
    end

    table.sort(self.placeables[1], sort)
    table.sort(self.placeables[2], sort)
end

function InGameMenuConstructionsFrame:updateInputs()
    self.states = {}

    local placeable = self:getSelectedPlaceable()

    if placeable ~= nil then
        for _, state in ipairs(placeable:getConstructionStates()) do
            if state:getHasInputs() then
                table.insert(self.states, state)
            end
        end

        self.inputList:setVisible(true)
    else
        self.inputList:setVisible(false)
    end

    self.inputList:reloadData()
end

function InGameMenuConstructionsFrame:updateStatus()
    local placeable = self:getSelectedPlaceable()

    if placeable ~= nil then
        self.statusLayout:setVisible(true)

        self.statusText:setText(placeable:getName())
        self.statusIcon:setImageFilename(placeable.storeItem.imageFilename)

        if not placeable:getConstructionIsCompleted() then
            local state = placeable:getActiveConstructionState()

            self.statusProgressBar:setPrimary(state:getDeliveryProgress())
            self.statusProgressBar:setSecondary(state:getProcessingProgress())

            self.statusProgressBar:setVisible(true)
        else
            self.statusProgressBar:setVisible(false)
        end
    else
        self.statusLayout:setVisible(false)
    end
end

---@nodiscard
---@return PlaceableConstruction | nil
function InGameMenuConstructionsFrame:getSelectedPlaceable()
    local section = self.placeables[self.constructionList.selectedSectionIndex]

    if section ~= nil then
        return section[self.constructionList.selectedIndex]
    end
end

---@param placeable PlaceableConstruction
function InGameMenuConstructionsFrame:setSelectedPlaceable(placeable)
    local sectionIndex = placeable:getConstructionIsCompleted() and 2 or 1

    for index, entry in ipairs(self.placeables[sectionIndex]) do
        if entry == placeable then
            self.constructionList:setSoundSuppressed(true)
            self.constructionList:setSelectedItem(sectionIndex, index, true)
            self.constructionList:setSoundSuppressed(false)

            break
        end
    end
end

---@param dt number
function InGameMenuConstructionsFrame:update(dt)
    self:superClass().update(self, dt)

    if self.isOpen then
        self.timeSinceLastUpdate = self.timeSinceLastUpdate + dt

        if self.timeSinceLastUpdate > InGameMenuConstructionsFrame.UPDATE_INTERVAL then
            self.timeSinceLastUpdate = 0
            self.constructionList:reloadData()
        end

        self:updateStatus()
    end
end

---
--- Callback functions from SmoothListElement
---

---@param list SmoothListElement
---@return number
function InGameMenuConstructionsFrame:getNumberOfSections(list)
    if list == self.constructionList then
        return 2
    elseif list == self.inputList then
        if self:getSelectedPlaceable() then
            return #self.states
        end
    end

    return 0
end

---@param list SmoothListElement
---@param sectionIndex number
---@return string
function InGameMenuConstructionsFrame:getTitleForSectionHeader(list, sectionIndex)
    if list == self.constructionList then
        return InGameMenuConstructionsFrame.L10N_SECTION_TITLE[sectionIndex]
    elseif list == self.inputList then
        local state = self.states[sectionIndex]

        if state ~= nil then
            return state:getTitle()
        end
    end

    return ''
end

---@param list SmoothListElement
---@param sectionIndex number
---@return number
function InGameMenuConstructionsFrame:getNumberOfItemsInSection(list, sectionIndex)
    if list == self.constructionList then
        return #self.placeables[sectionIndex]
    elseif list == self.inputList then
        local state = self.states[sectionIndex]

        if state ~= nil then
            return #state:getInputs()
        end
    end

    return 0
end

---@param list SmoothListElement
---@param sectionIndex number
---@param index number
---@param cell ListItemElement
function InGameMenuConstructionsFrame:populateCellForItemInSection(list, sectionIndex, index, cell)
    if list == self.constructionList then
        local placeable = self.placeables[sectionIndex][index]

        if placeable ~= nil then
            cell:getAttribute('icon'):setImageFilename(placeable.storeItem.imageFilename)
            cell:getAttribute('name'):setText(placeable:getName())
            cell:getAttribute('farm'):setText(placeable:getOwnerFarmName())
        else
            cell:getAttribute('name'):setText('nil')
        end
    elseif list == self.inputList then
        local state = self.states[sectionIndex]

        if state ~= nil then
            local input = state:getInputByIndex(index)

            if input ~= nil then
                local placeable = state.placeable
                local activeState = placeable:getActiveConstructionState()

                local fillType = input:getFillType()
                local isActive = state == activeState

                cell:setDisabled(not isActive)

                if fillType ~= nil then
                    cell:getAttribute('icon'):setImageFilename(fillType.hudOverlayFilename)
                    cell:getAttribute('fillType'):setText(fillType.title)
                else
                    cell:getAttribute('icon'):setImageFilename('dataS/menu/hud/fillTypes/hud_fill_unknown.png')
                    cell:getAttribute('fillType'):setText(input.fillTypeName)
                end

                ---@type ProgressBarElement
                local progressBar = cell:getAttribute('progressBar')

                if isActive then
                    cell:getAttribute('fillLevel'):setText(('%s / %s'):format(ConstructionUtils.formatNumber(input.deliveredAmount), ConstructionUtils.formatNumber(input.amount)))

                    progressBar:setPrimary(1 / input.amount * input.deliveredAmount)
                    progressBar:setSecondary(1 / input.amount * input.processedAmount)
                    progressBar:setDisabled(false)
                else
                    cell:getAttribute('fillLevel'):setText(ConstructionUtils.formatNumber(input.amount))

                    if state.index < activeState.index then
                        progressBar:setSecondary(1)
                    else
                        progressBar:setSecondary(0)
                    end

                    progressBar:setDisabled(true)
                    progressBar:setPrimary(0)
                end
            end
        end
    end
end

---@param list SmoothListElement
---@param sectionIndex number
---@param index number
function InGameMenuConstructionsFrame:onListSelectionChanged(list, sectionIndex, index)
    if list == self.constructionList then
        self:updateStatus()
        self:updateInputs()
        self:updateMenuButtons()
    end
end

---
--- Button callbacks
---

function InGameMenuConstructionsFrame:onClickVisitButton()
    local placeable = self:getSelectedPlaceable()

    if placeable ~= nil then
        local x, y, z = placeable:getActivationTriggerPosition()
        y = math.max(y, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.5)

        if g_currentMission.controlledVehicle ~= nil then
            g_currentMission:onLeaveVehicle(x, y, z, true, false)
        else
            g_currentMission.player:moveToAbsolute(x, y, z)
        end

        g_gui:changeScreen()
    end
end

function InGameMenuConstructionsFrame:onClickSettingsButton()
    g_constructionGui:openSettingsDialog()
end

function InGameMenuConstructionsFrame:onClickInputsButton()
    g_constructionGui:openInputsDialog(self:getSelectedPlaceable())
end

---
--- Message center events
---

---@param user User
function InGameMenuConstructionsFrame:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self:updatePlaceables()
        self:updateMenuButtons()
    end
end

---@param placeable PlaceableConstruction
function InGameMenuConstructionsFrame:onPlaceableAdded(placeable)
    self:updatePlaceables()
    self:updateMenuButtons()
end

---@param placeable PlaceableConstruction
function InGameMenuConstructionsFrame:onPlaceableRemoved(placeable)
    self:updatePlaceables()
    self:updateMenuButtons()
end

---@param placeable PlaceableConstruction
function InGameMenuConstructionsFrame:onConstructionStarted(placeable)
    if ConstructionUtils.getPlayerHasAccess(placeable) then
        self:updatePlaceables()
        self:updateMenuButtons()
    end
end

---@param placeable PlaceableConstruction
function InGameMenuConstructionsFrame:onConstructionCompleted(placeable)
    if ConstructionUtils.getPlayerHasAccess(placeable) then
        self:updatePlaceables()
        self:updateMenuButtons()
    end
end

---@param previous ConstructionSettings
function InGameMenuConstructionsFrame:onSettingsChanged(previous)
    if previous.requireFarmAccess ~= g_construction:getRequireFarmAccess() then
        self:updatePlaceables()
    end

    self:updateMenuButtons()
end
