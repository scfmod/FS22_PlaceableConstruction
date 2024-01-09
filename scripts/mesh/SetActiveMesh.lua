---@class SetActiveMesh : Mesh
---@field updateChildren boolean
---@field updatePhysics boolean
---@field collisionMask? number
---@field rigidBodyType? number
---@field lastState? boolean
SetActiveMesh = {}

local SetActiveMesh_mt = Class(SetActiveMesh, Mesh)

---@param schema XMLSchema
---@param key string
function SetActiveMesh.registerXMLPaths(schema, key)
    Mesh.registerXMLPaths(schema, key)

    schema:register(XMLValueType.BOOL, key .. '#updateChildren', 'Whether to iterate child meshes or not', false)
    schema:register(XMLValueType.BOOL, key .. '#updatePhysics', 'Add to physics when active, remove from physics when inactive', false)
    schema:register(XMLValueType.STRING, key .. '#collisionMask', 'Set collision mask (integer or #hex from GE) with updatePhysics')
    schema:register(XMLValueType.STRING, key .. '#rigidBody', 'Set rigid body type with updatePhysics')
end

---@nodiscard
---@param placeable PlaceableConstruction
---@return SetActiveMesh
function SetActiveMesh.new(placeable)
    ---@type SetActiveMesh
    local self = Mesh.new(placeable, SetActiveMesh_mt)

    return self
end

---@param xmlFile XMLFile
---@param key string
function SetActiveMesh:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.updateChildren = xmlFile:getValue(key .. '#updateChildren', false)
    self.updatePhysics = xmlFile:getValue(key .. '#updatePhysics', false)

    self.collisionMask = ConstructionUtils.getCollisionMask(xmlFile:getValue(key .. '#collisionMask'))
    self.rigidBodyType = ConstructionUtils.getRigidBodyType(xmlFile:getValue(key .. '#rigidBody'))
end

function SetActiveMesh:activate()
    self:setIsActive(true)
end

function SetActiveMesh:deactivate()
    self:setIsActive(false)
end

---@package
---@param node number
---@param isActive boolean
function SetActiveMesh:updateNode(node, isActive)
    if isActive then
        if self.rigidBodyType ~= nil and getRigidBodyType(node) ~= self.rigidBodyType then
            setRigidBodyType(node, self.rigidBodyType)
        end

        if self.collisionMask ~= nil and getCollisionMask(node) ~= self.collisionMask then
            setCollisionMask(node, self.collisionMask)
        end

        if self.updatePhysics then
            addToPhysics(node)
        end

        setVisibility(node, true)
    else
        if self.updatePhysics then
            removeFromPhysics(node)
        end

        if self.rigidBodyType ~= nil and self.rigidBodyType ~= RigidBodyType.NONE then
            setRigidBodyType(node, RigidBodyType.NONE)
        end

        setVisibility(node, false)
    end
end

---@package
---@param isActive boolean
function SetActiveMesh:setIsActive(isActive)
    if self.lastState ~= isActive then
        if g_debugConstructionMeshes then
            g_construction:debug(
                'SetActiveMesh:setIsActive() node: %s  isActive: %s  updateChildren: %s  collisionMask: %s  rigidBody: %s  updatePhysics: %s',
                getName(self.node), tostring(isActive), tostring(self.updateChildren), tostring(self.collisionMask), tostring(self.rigidBodyType), tostring(self.updatePhysics)
            )
        end

        if self.updateChildren then
            for i = 0, getNumOfChildren(self.node) - 1 do
                local node = getChildAt(self.node, i)

                if node ~= nil then
                    self:updateNode(node, isActive)
                end
            end

            setVisibility(self.node, isActive)
        else
            self:updateNode(self.node, isActive)
        end

        self.lastState = isActive
    end
end
