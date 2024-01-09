---@class ConstructionUtils
ConstructionUtils = {}

---@nodiscard
---@param placeable PlaceableConstruction
---@param name string | nil
---@return string | nil
function ConstructionUtils.getPlaceableText(placeable, name)
    if name ~= nil then
        if name:startsWith('$l10n_') then
            name = name:sub(7)
        end

        local modEnv = Utils.getModNameAndBaseDirectory(placeable.configFileName)
        ---@type I18N | nil
        local i18n = g_i18n.modEnvironments[modEnv]

        if i18n ~= nil and i18n.texts[name] ~= nil then
            return i18n.texts[name]
        end

        return g_i18n:getText(name)
    end
end

---@nodiscard
---@param value number
---@return string
function ConstructionUtils.formatNumber(value)
    local str = string.format("%d", math.floor(value))
    local pos = string.len(str) % 3

    if pos == 0 then
        pos = 3
    end

    return string.sub(str, 1, pos) .. string.gsub(string.sub(str, pos + 1), "(...)", ",%1")
end

---@nodiscard
---@param placeable PlaceableConstruction
---@return boolean
function ConstructionUtils.getShowPlaceableHotspot(placeable)
    if g_construction:getIsHotspotsEnabled() then
        return ConstructionUtils.getPlayerHasAccess(placeable)
    end

    return false
end

---@nodiscard
---@param placeable PlaceableConstruction
---@return boolean
function ConstructionUtils.getPlayerHasAccess(placeable)
    if not g_construction:getIsMultiplayer() then
        return true
    elseif g_construction:getIsMasterUser() then
        return true
    elseif not g_construction:getRequireFarmAccess() then
        return true
    elseif g_currentMission:getFarmId() == FarmManager.SPECTATOR_FARM_ID then
        return false
    elseif placeable:getOwnerFarmId() == FarmManager.SPECTATOR_FARM_ID then
        return true
    end

    return placeable:getOwnerFarmId() == g_currentMission:getFarmId()
end

---@nodiscard
---@param value string | nil
function ConstructionUtils.getCollisionMask(value)
    if value == nil or value == '' then
        return nil
    elseif value:startsWith('#') then
        return tonumber(value:sub(2), 16)
    end

    return tonumber(value)
end

---@nodiscard
---@param value string | nil
---@return RigidBodyType | nil
function ConstructionUtils.getRigidBodyType(value)
    if value ~= nil and RigidBodyType[value] ~= nil then
        return RigidBodyType[value]
    end
end

function ConstructionUtils.updatePalletStoreItems()
    g_construction:debug('ConstructionUtils.updatePalletStoreItems()')

    if not g_modIsLoaded[Construction.MOD_NAME_PRODUCTS] then
        g_construction:debug('ConstructionUtils.updatePalletStoreItems() Mod "%s" is not loaded, skipping', Construction.MOD_NAME_PRODUCTS)
        return
    end

    if g_client ~= nil then
        ---@type StoreItem[]
        local items = g_storeManager:getItems()

        for _, item in ipairs(items) do
            local modName = Utils.getModNameAndBaseDirectory(item.xmlFilename)

            if modName == Construction.MOD_NAME_PRODUCTS then
                if item.xmlFilename:startsWith('multiPurchase_') then
                    item.showInStore = g_construction:getIsBuyingPalletsEnabled()

                    if item.showInStore then
                        g_construction:debug('enable pallet storeItem: %s', item.xmlFilename)
                    else
                        g_construction:debug('disable pallet storeItem: %s', item.xmlFilename)
                    end
                end
            end
        end

        g_messageCenter:publish(MessageType.STORE_ITEMS_RELOADED)
    end
end
