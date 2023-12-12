---@class SetShaderParameterMesh : Mesh
---@field node number
---@field lastIndex? number
---@field startIndex number
---@field stopIndex number
---@field direction number
SetShaderParameterMesh = {}

local SetShaderParameterMesh_mt = Class(SetShaderParameterMesh, Mesh)

local DIRECTION_POSITIVE = 1
local DIRECTION_NEGATIVE = -1

---@param schema XMLSchema
---@param key string
function SetShaderParameterMesh.registerXMLPaths(schema, key)
    Mesh.registerXMLPaths(schema, key)

    schema:register(XMLValueType.INT, key .. '#startIndex', nil, 0, false)
    schema:register(XMLValueType.INT, key .. '#stopIndex', nil, nil, true)
    schema:register(XMLValueType.INT, key .. '#direction', nil, 1, false)
end

---@param placeable PlaceableConstruction
function SetShaderParameterMesh.new(placeable)
    ---@type SetShaderParameterMesh
    local self = Mesh.new(placeable, SetShaderParameterMesh_mt)

    return self
end

---@param xmlFile XMLFile
---@param key string
function SetShaderParameterMesh:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.startIndex = xmlFile:getValue(key .. '#startIndex', 0)
    self.stopIndex = xmlFile:getValue(key .. '#stopIndex')
    self.direction = xmlFile:getValue(key .. '#direction', 1)

    assert(self.stopIndex ~= nil, string.format('#stopIndex not defined: "%s"', key))

    if self.direction ~= DIRECTION_POSITIVE and self.direction ~= DIRECTION_NEGATIVE then
        Logging.xmlWarning(xmlFile, 'Invalid direction value "%s", reverting to default (%s)', tostring(self.direction), key .. '#direction')
        self.direction = DIRECTION_POSITIVE
    end
end

---@param progress number
function SetShaderParameterMesh:update(progress)
    progress = MathUtil.clamp(progress, 0, 1)

    if self.direction == -1 then
        progress = 1 - progress
    end

    local index = MathUtil.round(MathUtil.lerp(self.startIndex, self.stopIndex, progress))

    ---@cast index number

    if self.lastIndex ~= index then
        if g_debugConstructionMeshes then
            g_construction:debug(
                'SetShaderParameterMesh:update() node: %s  progress: %.2f  currentIndex: %i  startIndex: %i  stopIndex: %i  direction: %i',
                getName(self.node), progress, index, self.startIndex, self.stopIndex, self.direction
            )
        end
        setVisibility(self.node, progress > 0)
        setShaderParameter(self.node, 'hideByIndex', index, 0, 0, 0, false)

        self.lastIndex = index
    end
end
