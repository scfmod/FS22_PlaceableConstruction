local modFolder = g_currentModDirectory

---@class ConstructionHotspot : MapHotspot
---@field placeable PlaceableConstruction
---@field icon Overlay
---@field width number
---@field height number
---@field teleportWorldX number
---@field teleportWorldY number
---@field teleportWorldZ number
---@field clickArea table
---@field superClass fun(): MapHotspot
ConstructionHotspot = {}

ConstructionHotspot.ICON_UVS = GuiUtils.getUVs('0.25 0 0.25 0.25')

local ConstructionHotspot_mt = Class(ConstructionHotspot, MapHotspot)


---@param schema XMLSchema
---@param key string
function ConstructionHotspot.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#icon', 'Path to icon texture file')
    schema:register(XMLValueType.STRING, key .. '#iconUVs', 'Optional UVs')
end

---@nodiscard
---@param placeable PlaceableConstruction
function ConstructionHotspot.new(placeable)
    ---@type ConstructionHotspot
    local self = MapHotspot.new(ConstructionHotspot_mt)

    self.isVisible = false
    self.placeable = placeable
    self.width, self.height = getNormalizedScreenValues(60, 60)
    self.icon = Overlay.new(nil, 0, 0, self.width, self.height)
    self.clickArea = MapHotspot.getClickArea({ 13, 13, 74, 74 }, { 100, 100 }, math.rad(45))

    return self
end

---@param xmlFile XMLFile
---@param key string
function ConstructionHotspot:load(xmlFile, key)
    --
    -- Optional attribute to set custom icon texture for
    -- construction hotspot on map.
    --
    -- Optional icon UVs is also supported.
    --

    local iconFile = xmlFile:getValue(key .. '#icon')

    if iconFile ~= nil then
        local _, modBaseDirectory = Utils.getModNameAndBaseDirectory(self.placeable.configFileName)

        if modBaseDirectory ~= nil and modBaseDirectory ~= '' then
            local textureFilename = modBaseDirectory .. iconFile

            self.icon.overlayId = createImageOverlay(textureFilename)

            if self.icon.overlayId == nil or self.icon.overlayId == 0 then
                Logging.warning('Failed to load hotspot icon texture file: %s', textureFilename)
            else
                local iconUVs = xmlFile:getValue(key .. '#iconUVs')

                if iconUVs ~= nil then
                    self.icon:setUVs(GuiUtils.getUVs(iconUVs))
                end
            end
        end
    end

    if self.icon.overlayId == nil or self.icon.overlayId == 0 then
        self.icon.overlayId = createImageOverlay(g_constructionUIFilename)
        self.icon:setUVs(ConstructionHotspot.ICON_UVS)
    end

    local x, y, z = self.placeable:getActivationTriggerPosition()

    y = math.max(y, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.5)

    self:setWorldPosition(x, z)
    self:setTeleportWorldPosition(x, y, z)

    g_currentMission:addMapHotspot(self)
end

---@param x number
---@param y number
---@param z number
function ConstructionHotspot:setTeleportWorldPosition(x, y, z)
    self.teleportWorldX = x
    self.teleportWorldY = y
    self.teleportWorldZ = z
end

---@return number worldX
---@return number worldY
---@return number worldZ
function ConstructionHotspot:getTeleportWorldPosition()
    return self.teleportWorldX, self.teleportWorldY, self.teleportWorldZ
end

---@return boolean
function ConstructionHotspot:getBeVisited()
    return self.teleportWorldX ~= nil and g_construction:getIsVisitButtonEnabled()
end

---@return number
function ConstructionHotspot:getCategory()
    return MapHotspot.CATEGORY_OTHER
end

---@return string
function ConstructionHotspot:getName()
    return self.placeable:getName()
end

function ConstructionHotspot:delete()
    g_currentMission:removeMapHotspot(self)

    self:superClass().delete(self)
end

---@param class any
---@return boolean
function ConstructionHotspot:isa(class)
    if class == PlaceableHotspot then
        return true
    end

    return self:superClass().isa(self, class)
end

---@return PlaceableConstruction
function ConstructionHotspot:getPlaceable()
    return self.placeable
end
