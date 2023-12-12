local outputDirectory = g_currentModDirectory .. 'docs/'
---@type string | nil
local overrideFileOpen
local mod = g_modManager:getModByName(g_currentModName)

if mod ~= nil and not mod.isDirectory then
    outputDirectory = g_modSettingsDirectory
end

SpecializationManager.postInitSpecializations = Utils.overwrittenFunction(
    SpecializationManager.postInitSpecializations,

    ---@param self SpecializationManager
    function(self)
        if self.typeName == 'placeable' then
            ---@type XMLSchema
            local schema = Placeable.xmlSchema

            overrideFileOpen = 'placeable_construction.xsd'
            schema:generateSchema()

            overrideFileOpen = 'placeable_construction.html'
            schema:generateHTML()

            ---@diagnostic disable-next-line: undefined-global
            requestExit()
        end
    end
)

io.open = Utils.overwrittenFunction(io.open,
    ---@param filename string
    ---@param superFunc fun(filename: string, options: any): any
    ---@param options any
    ---@return table
    function(filename, superFunc, options)
        if overrideFileOpen ~= nil then
            filename = outputDirectory .. overrideFileOpen
        end

        return superFunc(filename, options)
    end
)
