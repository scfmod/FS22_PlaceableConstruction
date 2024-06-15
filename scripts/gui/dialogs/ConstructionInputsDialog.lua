---@class Input
---@field fillTypeName string
---@field title string
---@field icon string | nil
---@field totalAmount number
---@field deliveredAmount number

---@class ConstructionInputsDialog : MessageDialog
---@field inputs Input[]
---@field inputList SmoothListElement
---@field placeable PlaceableConstruction
---@field superClass fun(): MessageDialog
ConstructionInputsDialog = {}

ConstructionInputsDialog.CLASS_NAME = 'ConstructionInputsDialog'
ConstructionInputsDialog.XML_FILENAME = g_currentModDirectory .. 'xml/gui/dialogs/ConstructionInputsDialog.xml'
ConstructionInputsDialog.CONTROLS = {
    'inputList'
}

local ConstructionInputsDialog_mt = Class(ConstructionInputsDialog, MessageDialog)

---@nodiscard
---@return ConstructionInputsDialog
function ConstructionInputsDialog.new()
    ---@type ConstructionInputsDialog
    local self = MessageDialog.new(nil, ConstructionInputsDialog_mt)

    self:registerControls(ConstructionInputsDialog.CONTROLS)

    self.inputs = {}

    return self
end

function ConstructionInputsDialog:load()
    g_gui:loadGui(ConstructionInputsDialog.XML_FILENAME, ConstructionInputsDialog.CLASS_NAME, self)
end

function ConstructionInputsDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[ConstructionInputsDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function ConstructionInputsDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.inputList:setDataSource(self)
end

function ConstructionInputsDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateInputs()
    self.inputList:reloadData()

    g_messageCenter:subscribe(MessageType.CONSTRUCTION_PLACEABLE_REMOVED, self.onPlaceableRemoved, self)
end

function ConstructionInputsDialog:onClose()
    self:superClass().onClose(self)

    self.inputs = {}
    self.placeable = nil

    g_messageCenter:unsubscribeAll(self)
end

---@param placeable PlaceableConstruction
function ConstructionInputsDialog:show(placeable)
    self.placeable = placeable
    g_gui:showDialog(ConstructionInputsDialog.CLASS_NAME)
end

---@param a Input
---@param b Input
local function sortInputs(a, b)
    return a.fillTypeName < b.fillTypeName
end

function ConstructionInputsDialog:updateInputs()
    ---@type table<string, Input>
    local inputByFillType = {}

    for _, input in ipairs(self.placeable:getAllConstructionInputs()) do
        if inputByFillType[input.fillTypeName] == nil then
            ---@type FillTypeObject | nil
            local fillType = g_fillTypeManager:getFillTypeByName(input.fillTypeName)
            local title = input.fillTypeName
            local icon = 'dataS/menu/hud/fillTypes/hud_fill_unknown.png'

            if fillType ~= nil then
                title = fillType.title
                icon = fillType.hudOverlayFilename
            end

            inputByFillType[input.fillTypeName] = {
                fillTypeName = input.fillTypeName,
                title = title,
                icon = icon,
                totalAmount = 0,
                deliveredAmount = 0
            }
        end

        local targetInput = inputByFillType[input.fillTypeName]

        targetInput.totalAmount = targetInput.totalAmount + input.amount
        targetInput.deliveredAmount = targetInput.deliveredAmount + input.deliveredAmount
    end

    self.inputs = {}

    for _, input in pairs(inputByFillType) do
        table.insert(self.inputs, input)
    end

    table.sort(self.inputs, sortInputs)
end

function ConstructionInputsDialog:getNumberOfItemsInSection()
    return #self.inputs
end

---@param list SmoothListElement
---@param sectionIndex number
---@param index number
---@param cell ListItemElement
function ConstructionInputsDialog:populateCellForItemInSection(list, sectionIndex, index, cell)
    local input = self.inputs[index]

    if input ~= nil then
        ---@type ProgressBarElement
        local progressBar = cell:getAttribute('progressBar')

        progressBar:setPrimary(1 / input.totalAmount * input.deliveredAmount)

        cell:setDisabled(progressBar.value == 1)

        cell:getAttribute('title'):setText(input.title)
        cell:getAttribute('icon'):setImageFilename(input.icon)
        cell:getAttribute('progressText'):setText(('%s / %s'):format(ConstructionUtils.formatNumber(input.deliveredAmount), ConstructionUtils.formatNumber(input.totalAmount)))
    end
end

function ConstructionInputsDialog:onPlaceableRemoved(placeable)
    if self.isOpen and placeable == self.placeable then
        self:close()
    end
end
