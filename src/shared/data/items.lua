--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module configs.items
--- @description Handles all static data for items.

--- @section Constants

local CATEGORIES = {
    "consumables.drinks",
    "consumables.food",
    "consumables.medical",

    "crafting.materials",

    "deployables.furniture",
    "deployables.stations",
    
    "equipment.bags",
    
    "weapons.ammo",
    "weapons.attachments",
    "weapons.firearms",
    "weapons.melee",
    "weapons.thrown"
}

--- @section Initalisation

local items = {}

for _, category in ipairs(CATEGORIES) do
    local category_items = require(("configs.items.%s"):format(category))
    for item_id, data in pairs(category_items) do
        items[item_id] = data
    end
end

return items