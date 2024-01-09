---@class ConstructionGUI
---@field constructionsFrame InGameMenuConstructionsFrame
---@field pageName string
ConstructionGUI = {}

ConstructionGUI.PROFILE_FILENAME = g_currentModDirectory .. 'xml/gui/guiProfiles.xml'

local ConstructionGUI_mt = Class(ConstructionGUI)

function ConstructionGUI.new()
    ---@type ConstructionGUI
    local self = setmetatable({}, ConstructionGUI_mt)

    if g_debugConstruction then
        addConsoleCommand('csReloadGui', '', 'consoleReloadGui', self)
    end

    return self
end

function ConstructionGUI:consoleReloadGui()
    self:reload()

    return 'GUI reloaded'
end

function ConstructionGUI:load()
    self:loadProfiles()
    self:loadDialogs()
end

function ConstructionGUI:delete()
    if g_constructionSettingsDialog.isOpen then
        g_constructionSettingsDialog:close()
    end

    if g_constructionInputsDialog.isOpen then
        g_constructionInputsDialog:close()
    end

    g_gui:showGui(nil)

    g_constructionSettingsDialog:delete()
    g_constructionInputsDialog:delete()
end

function ConstructionGUI:reload()
    local guiName = g_gui.currentGuiName
    local settingsDialogIsOpen = g_constructionSettingsDialog.isOpen

    self:delete()

    g_construction:debug('Reloading GUI ..')

    self:loadProfiles()
    self:loadDialogs()

    g_construction:debug('Reloading HUD ..')

    g_constructionHud:reload()

    g_gui:showGui(guiName)

    if settingsDialogIsOpen then
        g_constructionSettingsDialog:show()
    end
end

function ConstructionGUI:loadProfiles()
    -- Need to set this variable to true in order to allow overwriting existing GUI profiles
    g_gui.currentlyReloading = true

    if not g_gui:loadProfiles(ConstructionGUI.PROFILE_FILENAME) then
        Logging.error('Failed to load profiles: %s', ConstructionGUI.PROFILE_FILENAME)
    end

    g_gui.currentlyReloading = false
end

function ConstructionGUI:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_constructionSettingsDialog = ConstructionSettingsDialog.new()
    g_constructionSettingsDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_constructionInputsDialog = ConstructionInputsDialog.new()
    g_constructionInputsDialog:load()
end

function ConstructionGUI:loadMenuFrame()
    self.constructionsFrame = InGameMenuConstructionsFrame.new()

    g_gui:loadGui(InGameMenuConstructionsFrame.XML_FILENAME, InGameMenuConstructionsFrame.MENU_PAGE_NAME, self.constructionsFrame, true)

    local inGameMenu = g_currentMission.inGameMenu

    inGameMenu[InGameMenuConstructionsFrame.MENU_PAGE_NAME] = self.constructionsFrame
    inGameMenu:registerPage(self.constructionsFrame, nil, function()
        return true
    end)
    inGameMenu:addPageTab(self.constructionsFrame, g_constructionUIFilename, InGameMenuConstructionsFrame.ICON_UVS)

    local pagingElement = inGameMenu.pagingElement
    pagingElement:addElement(self.constructionsFrame)

    self.constructionsFrame:applyScreenAlignment()
    self.constructionsFrame:updateAbsolutePosition()

    g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_CONSTRUCTIONS_SCREEN, self.openConstructionsScreen, self)
end

function ConstructionGUI:loadMap()
    self:loadMenuFrame()
end

---@param placeable PlaceableConstruction | nil
function ConstructionGUI:openConstructionsScreen(placeable)
    local inGameMenu = g_currentMission.inGameMenu

    inGameMenu:changeScreen(InGameMenu)
    local pageIndex = inGameMenu.pagingElement:getPageMappingIndexByElement(g_constructionGui.constructionsFrame)

    inGameMenu.pageSelector:setState(pageIndex, true)

    if placeable ~= nil then
        self.constructionsFrame:setSelectedPlaceable(placeable)
    end
end

function ConstructionGUI:openSettingsDialog()
    g_constructionSettingsDialog:show()
end

---@param placeable PlaceableConstruction | nil
function ConstructionGUI:openInputsDialog(placeable)
    if placeable ~= nil then
        g_constructionInputsDialog:show(placeable)
    end
end
