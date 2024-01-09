---@class SetProgressMesh : Mesh
---@field node number
---@field lastIndex number
---@field direction number
---@field startIndex number
---@field stopIndex number
SetProgressMesh = {}

local SetProgressMesh_mt = Class(SetProgressMesh, Mesh)

local DIRECTION_POSITIVE = 1
local DIRECTION_NEGATIVE = -1

---@param schema XMLSchema
---@param key string
function SetProgressMesh.registerXMLPaths(schema, key)
    Mesh.registerXMLPaths(schema, key)

    schema:register(XMLValueType.INT, key .. '#startIndex')
    schema:register(XMLValueType.INT, key .. '#stopIndex')
    schema:register(XMLValueType.INT, key .. '#direction', 'Child iterate direction, 1 for positive, -1 for negative', 1)
end

---@nodiscard
---@param placeable PlaceableConstruction
---@return SetProgressMesh
function SetProgressMesh.new(placeable)
    ---@type SetProgressMesh
    local self = Mesh.new(placeable, SetProgressMesh_mt)

    return self
end

---@param xmlFile XMLFile
---@param key string
function SetProgressMesh:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.direction = xmlFile:getValue(key .. '#direction', DIRECTION_POSITIVE)

    if self.direction ~= DIRECTION_POSITIVE and self.direction ~= DIRECTION_NEGATIVE then
        Logging.xmlWarning(xmlFile, 'Invalid direction value "%s", reverting to default (%s)', tostring(self.direction), key .. '#direction')
        self.direction = DIRECTION_POSITIVE
    end

    local startIndex = xmlFile:getValue(key .. '#startIndex')
    local stopIndex = xmlFile:getValue(key .. '#stopIndex')

    if startIndex == nil then
        if self.direction == DIRECTION_POSITIVE then
            startIndex = 0
        else
            startIndex = getNumOfChildren(self.node) - 1
        end
    end

    self.startIndex = startIndex

    if stopIndex == nil then
        if self.direction == DIRECTION_POSITIVE then
            stopIndex = getNumOfChildren(self.node) - 1
        else
            stopIndex = 0
        end
    end

    self.stopIndex = stopIndex
end

---@param progress number
function SetProgressMesh:update(progress)
    local isReversedDirection = self.direction ~= DIRECTION_POSITIVE

    if isReversedDirection then
        progress = 1 - progress
    end

    progress = MathUtil.clamp(progress, 0, 1)

    local index = math.floor(MathUtil.lerp(self.startIndex, self.stopIndex + 1, progress))

    if self.lastIndex ~= index then
        if g_debugConstructionMeshes then
            g_construction:debug(
                'SetProgressMesh:update()  node: %s  progress: %.2f  currentInternalIndex: %i  startIndex: %i  stopIndex: %i  direction: %i',
                getName(self.node), progress, index, self.startIndex, self.stopIndex, self.direction
            )
        end

        local startIndex = self.startIndex
        local stopIndex = self.stopIndex

        if self.lastIndex == nil then
            setVisibility(self.node, true)
        else
            startIndex = self.lastIndex

            if isReversedDirection then
                stopIndex = math.max(index, self.startIndex)
            else
                stopIndex = math.min(index, self.stopIndex)
            end
        end

        if g_debugConstructionMeshes then
            g_construction:debug('  iterate children: startIndex: %i  stopIndex: %i', startIndex, stopIndex)
        end

        for i = startIndex, stopIndex do
            local node = getChildAt(self.node, i)

            if node == nil then
                break
            end

            if isReversedDirection then
                setVisibility(node, i > index)
            else
                setVisibility(node, i < index)
            end
        end

        self.lastIndex = index
    end
end
