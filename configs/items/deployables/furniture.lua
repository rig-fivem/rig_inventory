--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module furniture
--- @file configs/items/deployables/furniture.lua
--- @description Handles all static data for items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "furniture",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    sleeping_bag = {
        label = "Sleeping Bag",
        description = {
            "Basic sleeping bag.",
            "Can be placed anywhere in the world.",
            "Saves a one time use spawn point."
        },
        image = "sleeping_bag.png",
        weight = 500,
        w = 2,
        h = 2,
        stackable = false,
        category = "furniture",
        actions = {
            craft = {
                ingredients = {
                    { id = "cloth", amount = 30 }
                }
            },
            drop = {
                model = "prop_skid_sleepbag_1"
            },
            use = function()
                print("using sleeping bag")
            end
        }
    }

}