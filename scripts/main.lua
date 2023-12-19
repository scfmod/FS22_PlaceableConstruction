---@diagnostic disable: lowercase-global

local modFolder = g_currentModDirectory
local generateSchema = false

---@param path string
local function load(path)
    source(modFolder .. 'scripts/' .. path)
end

if generateSchema then
    load('schema.lua')
end

g_constructionUIFilename = modFolder .. 'textures/ui_elements.png'
g_debugConstruction = false

-- Load utils
load('utils/ConstructionUtils.lua')
load('utils/ConstructionSoundUtils.lua')

-- Check if debug.lua exists, if so load it
if fileExists(modFolder .. 'scripts/debug.lua') then
    load('debug.lua')
end

-- Load base files
load('events/SetConstructionSettingsEvent.lua')
load('Construction.lua')
load('ConstructionActivatable.lua')
load('ConstructionDeliveryArea.lua')
load('ConstructionHotspot.lua')
load('ConstructionInput.lua')
load('ConstructionState.lua')

-- Load mesh classes
load('mesh/Mesh.lua')
load('mesh/SetActiveMesh.lua')
load('mesh/SetProgressMesh.lua')
load('mesh/SetShaderParameterMesh.lua')
load('mesh/ToggleMesh.lua')

-- Load GUI
load('gui/elements/LayoutOptionElement.lua')
load('gui/elements/ProgressBarElement.lua')
load('gui/dialogs/ConstructionInputsDialog.lua')
load('gui/dialogs/ConstructionSettingsDialog.lua')
load('gui/InGameMenuConstructionsFrame.lua')
load('gui/ConstructionGUI.lua')

-- Load HUD
load('hud/elements/HeaderElement.lua')
load('hud/elements/InputListElement.lua')
load('hud/elements/InputListItemElement.lua')
load('hud/ConstructionHUD.lua')

-- Load extensions to add/fix functionality to base game classes/functions
load('extensions/ConstructionScreenExtension.lua')
load('extensions/EconomyManagerExtension.lua')
load('extensions/FSBaseMissionExtension.lua')
load('extensions/GuiOverlayExtension.lua')
load('extensions/SaveGameControllerExtention.lua')
load('extensions/SellPlaceableEventExtension.lua')

g_constructionGui = ConstructionGUI.new()
g_constructionHud = ConstructionHUD.new()

g_construction:loadUserSettings()

if g_client then
    g_constructionGui:load()
    g_constructionHud:load()

    addModEventListener(g_constructionGui)
end
