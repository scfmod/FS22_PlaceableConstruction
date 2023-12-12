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

    -- self:deleteMenuFrame()
end

function ConstructionGUI:reload()
    local guiName = g_gui.currentGuiName
    local settingsDialogIsOpen = g_constructionSettingsDialog.isOpen

    self:delete()

    Logging.info('Reloading GUI ..')

    self:loadProfiles()
    self:loadDialogs()
    -- self:loadMenuFrame()

    Logging.info('Reloading HUD ..')

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

-- function ConstructionGUI:deleteMenuFrame()
--     -- Unsubscribe from message center event
--     g_messageCenter:unsubscribe(MessageType.GUI_INGAME_OPEN_CONSTRUCTIONS_SCREEN, self)

--     ---@type InGameMenu
--     local inGameMenu = g_currentMission.inGameMenu

--     -- Remove page from ingame menu
--     inGameMenu:removePage(InGameMenuConstructionsFrame)

--     -- Delete local reference to frame element
--     self.constructionsFrame = nil
-- end

-- function ConstructionGUI:loadMenuFrame()
--     g_construction:debug('ConstructionGUI:loadMenuFrame()')

--     if self.constructionsFrame ~= nil then
--         Logging.warning('ConstructionGUI:loadMenuFrame() constructionsFrame already created, skipping')
--         return
--     end

--     -- Create new frame element
--     self.constructionsFrame = InGameMenuConstructionsFrame.new()

--     -- Load frame GUI elements
--     g_gui:loadGui(InGameMenuConstructionsFrame.XML_FILENAME, InGameMenuConstructionsFrame.MENU_PAGE_NAME, self.constructionsFrame, true)

--     ---@type InGameMenu
--     local inGameMenu = g_currentMission.inGameMenu

--     -- Add page to ingame menu
--     inGameMenu:addPage(self.constructionsFrame, nil, g_constructionUIFilename, InGameMenuConstructionsFrame.ICON_UVS, function()
--         return true
--     end)

--     inGameMenu[InGameMenuConstructionsFrame.MENU_PAGE_NAME] = self.constructionsFrame

--     -- Update alignment and position
--     self.constructionsFrame:applyScreenAlignment()
--     self.constructionsFrame:updateAbsolutePosition()

--     -- Subscribe to messsage center event
--     g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_CONSTRUCTIONS_SCREEN, self.openConstructionsScreen, self)
-- end

function ConstructionGUI:loadMenuFrame()
    self.constructionsFrame = InGameMenuConstructionsFrame.new()

    g_gui:loadGui(InGameMenuConstructionsFrame.XML_FILENAME, InGameMenuConstructionsFrame.MENU_PAGE_NAME, self.constructionsFrame, true)

    ---@type InGameMenu
    local inGameMenu = g_currentMission.inGameMenu

    inGameMenu[InGameMenuConstructionsFrame.MENU_PAGE_NAME] = self.constructionsFrame
    inGameMenu:registerPage(self.constructionsFrame, nil, function()
        return true
    end)
    inGameMenu:addPageTab(self.constructionsFrame, g_constructionUIFilename, InGameMenuConstructionsFrame.ICON_UVS)

    ---@type PagingElement
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
    ---@type InGameMenu
    local inGameMenu = g_currentMission.inGameMenu

    inGameMenu:changeScreen(InGameMenu)
    local pageIndex = inGameMenu.pagingElement:getPageMappingIndexByElement(g_constructionGui.constructionsFrame)

    ---@diagnostic disable-next-line: undefined-field
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
