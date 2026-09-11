--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module bags
--- @file configs/items/equipment/bags.lua
--- @description Handles all static data for items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "bags",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    dufflebag = {
        label = "Dufflebag",
        description = "It's a duffle, it holds things.",
        image = "dufflebag.png",
        weight = 1000,
        w = 2,
        h = 2,
        stackable = false,
        category = "bags",
        metadata = {
            equipped = false
        },
        actions = {
            drop = {
                model = "ch_prop_ch_duffbag_gruppe_01a"
            },
            use = {
                inventory_group = "dufflebag",
                loadout_slot = "backpack",
                clothing = {
                    component_id = 5,
                    drawable = 45,
                    texture = 0,
                    male = { drawable = 45, texture = 0 },
                    female = { drawable = 45, texture = 0 }
                },
                animation = {
                    progress = { message = "Equipping backpack..." },
                    dict = "clothingshirt",
                    anim = "try_shirt_positive_d",
                    flags = 49,
                    duration = 2000,
                    freeze = false,
                    continuous = false
                }
            }
        }
    },

}