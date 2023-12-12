--[[
    Override getBuyPrice on storeItems if applicable.
]]

---@param self EconomyManager
---@return number price
---@return number upgradePrice
local function inj_EconomyManager_getBuyPrice(self, superFunc, storeItem, configurations, saleItem)
    if g_construction:getIsPriceOverrideEnabled() and StoreItemUtil.getIsPlaceable(storeItem) then
        if storeItem.constructionPrice ~= nil then
            return storeItem.constructionPrice, 0
        end
    end

    return superFunc(self, storeItem, configurations, saleItem)
end

EconomyManager.getBuyPrice = Utils.overwrittenFunction(EconomyManager.getBuyPrice, inj_EconomyManager_getBuyPrice)

--[[
    Iterate over storeItems to check if it's a placeable Construction.

    If the Construction has a price override set we add a custom variable
    to the storeItem object.
]]

local InsertCustomStoreItemVariable = {}

function InsertCustomStoreItemVariable:loadMap()
    local items = g_storeManager:getItems()

    for _, storeItem in ipairs(items) do
        if StoreItemUtil.getIsPlaceable(storeItem) then
            local xmlFile = loadXMLFile('tmp_placeable', storeItem.xmlFilename)

            if xmlFile ~= nil and xmlFile ~= 0 then
                local price = getXMLFloat(xmlFile, 'placeable.construction.price')
                delete(xmlFile)

                if price ~= nil then
                    storeItem.constructionPrice = price
                    -- g_construction:debug('Found construction price in: %s', storeItem.xmlFilename)
                end
            end
        end
    end
end

addModEventListener(InsertCustomStoreItemVariable)
