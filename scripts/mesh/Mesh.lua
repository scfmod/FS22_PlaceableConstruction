---@enum MeshType
MeshType = {
    SET_ACTIVE = 1,
    SET_PROGRESS = 2,
    SET_SHADER_PARAMETER = 3,
    TOGGLE = 4
}

---@class Mesh
---@field placeable PlaceableConstruction
---@field node number
---@field superClass fun(): Mesh
Mesh = {}

---@param schema XMLSchema
---@param key string
function Mesh.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Node i3d name/path', nil, true)
end

---@nodiscard
---@param placeable PlaceableConstruction
---@param mt table
---@return table
function Mesh.new(placeable, mt)
    local self = setmetatable({}, mt)

    self.placeable = placeable

    return self
end

---@param xmlFile XMLFile
---@param key string
function Mesh:load(xmlFile, key)
    self.node = xmlFile:getValue(key .. '#node', nil, self.placeable.components, self.placeable.i3dMappings)

    assert(self.node ~= nil, string.format('Mesh node not found: "%s"', key .. '#node'))
end

---@param progress number
function Mesh:update(progress)
end

function Mesh:activate()
end

function Mesh:deactivate()
end
