--[[
    The original function fails to use the Placeable:getPrice()

    This override will fix this issue and ensure the specialization
    function override works correctly.
]]
---@param self SellPlaceableEvent
local function inj_SellPlaceableEvent_run(self, superFunc, connection)
    if not connection:getIsServer() then
        local state = SellPlaceableEvent.STATE_FAILED
        local sellPrice = 0

        if self.placeable ~= nil then
            if g_currentMission:getHasPlayerPermission("sellPlaceable", connection) then
                if self.placeable:canBeSold() then
                    self.placeable:onSell()

                    if not self.forFree then
                        if self.forFullPrice then
                            sellPrice = self.placeable:getPrice()
                        else
                            sellPrice = self.placeable:getSellPrice()
                        end
                    end

                    state = SellPlaceableEvent.STATE_SUCCESS

                    g_currentMission:addMoney(sellPrice, self.placeable:getOwnerFarmId(), MoneyType.SHOP_PROPERTY_SELL, true, true)

                    if self.placeable:getSellAction() == Placeable.SELL_AND_SPECTATOR_FARM then
                        self.placeable:setOwnerFarmId(FarmManager.SPECTATOR_FARM_ID)
                    else
                        g_currentMission:addPlaceableToDelete(self.placeable)
                    end
                else
                    state = SellPlaceableEvent.STATE_IN_USE
                end
            else
                state = SellPlaceableEvent.STATE_NO_PERMISSION
            end
        end

        g_messageCenter:publish(SellPlaceableEvent, state, sellPrice)
        connection:sendEvent(SellPlaceableEvent.newServerToClient(state, sellPrice))
    else
        g_messageCenter:publish(SellPlaceableEvent, self.state, self.sellPrice)
    end
end

SellPlaceableEvent.run = Utils.overwrittenFunction(SellPlaceableEvent.run, inj_SellPlaceableEvent_run)
