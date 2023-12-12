--[[
    Every time the ConstructionScreen opens it will rebuild the list of
    placeables with prices.

    If price override setting is enabled we iterate over each placeable and then
    check if the storeItem has our custom price variable set.

    Reference: scripts/extensions/EconomyManagerExtension.lua
        - function InsertCustomStoreItemVariable:loadMap()
]]


---@param self ConstructionScreen
local function post_ConstructionScreen_rebuildData(self)
    if g_construction:getIsPriceOverrideEnabled() then
        for _, category in ipairs(self.items) do
            for _, tabs in ipairs(category) do
                for _, entry in ipairs(tabs) do
                    local storeItem = entry.storeItem

                    if StoreItemUtil.getIsPlaceable(storeItem) and storeItem.constructionPrice ~= nil then
                        entry.price = storeItem.constructionPrice
                    end
                end
            end
        end
    end
end

ConstructionScreen.rebuildData = Utils.appendedFunction(ConstructionScreen.rebuildData, post_ConstructionScreen_rebuildData)
