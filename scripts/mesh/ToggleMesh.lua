---@class ToggleMesh : Mesh
---@field active boolean
---@field updateChildren boolean
---@field updatePhysics boolean
---@field collisionMask? number
---@field rigidBodyType? RigidBodyType
ToggleMesh = {}

local ToggleMesh_mt = Class(ToggleMesh, Mesh)

---@param schema XMLSchema
---@param key string
function ToggleMesh.registerXMLPaths(schema, key)
    Mesh.registerXMLPaths(schema, key)

    schema:register(XMLValueType.BOOL, key .. '#active', nil, nil, true)
    schema:register(XMLValueType.BOOL, key .. '#updateChildren')
    schema:register(XMLValueType.BOOL, key .. '#updatePhysics')
    schema:register(XMLValueType.STRING, key .. '#collisionMask')
    schema:register(XMLValueType.STRING, key .. '#rigidBody')
end

---@param placeable PlaceableConstruction
function ToggleMesh.new(placeable)
    ---@type ToggleMesh
    local self = Mesh.new(placeable, ToggleMesh_mt)

    return self
end

---@param xmlFile XMLFile
---@param key string
function ToggleMesh:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.active = xmlFile:getValue(key .. '#active', false)
    self.updateChildren = xmlFile:getValue(key .. '#updateChildren', false)
    self.updatePhysics = xmlFile:getValue(key .. '#updatePhysics', false)

    self.collisionMask = ConstructionUtils.getCollisionMask(xmlFile:getValue(key .. '#collisionMask'))
    self.rigidBodyType = ConstructionUtils.getRigidBodyType(xmlFile:getValue(key .. '#rigidBody'))
end

---@package
---@param node number
function ToggleMesh:updateNode(node)
    if self.active then
        if self.collisionMask ~= nil then
            setCollisionMask(node, self.collisionMask)
        end

        if self.rigidBodyType ~= nil and getRigidBodyType(node) ~= self.rigidBodyType then
            setRigidBodyType(node, self.rigidBodyType)
        end

        if self.updatePhysics then
            addToPhysics(node)
        end

        setVisibility(node, true)
    else
        if self.updatePhysics then
            removeFromPhysics(node)
        end

        if self.collisionMask ~= nil then
            setCollisionMask(node, self.collisionMask)
        end

        if self.rigidBodyType ~= nil and getRigidBodyType(node) ~= self.rigidBodyType then
            setRigidBodyType(node, self.rigidBodyType)
        end

        setVisibility(node, false)
    end
end

function ToggleMesh:activate()
    if g_debugConstructionMeshes then
        g_construction:debug(
            'ToggleMesh:activate() node: %s  active: %s  updateChildren: %s  collisionMask: %s  rigidBody: %s  updatePhysics: %s',
            getName(self.node), tostring(self.active), tostring(self.updateChildren), tostring(self.collisionMask), tostring(self.rigidBodyType), tostring(self.updatePhysics)
        )
    end

    if self.updateChildren then
        for i = 0, getNumOfChildren(self.node) - 1 do
            local node = getChildAt(self.node, i)

            if node == nil then
                break
            end

            self:updateNode(node)
        end
    else
        self:updateNode(self.node)
    end
end
