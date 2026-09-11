--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module ammo
--- @file configs/items/weapons/ammo.lua
--- @description Handles all static data for items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "ammo",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    ammo_9mm = {
        label = "9mm Ammo",
        description = "Standard 9x19mm Parabellum ammunition",
        image = "ammo_9mm.png",
        weight = 8,
        w = 1,
        h = 1,
        stackable = 50,
        category = "ammo",
        metadata = {
            ammo_refill = 12,
        },
        actions = {
            drop = true,
            use = true
        }
    },

}