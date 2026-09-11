--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module firearms
--- @file configs/items/weapons/firearms.lua
--- @description Handles all static data for items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "firearms",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    weapon_pistol = {
        label = "Pistol",
        description = "9mm semi-automatic pistol",
        image = "weapon_pistol.png",
        weight = 710,
        w = 2,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "common",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_9mm" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_pi_pistol" },
            use = true
        }
    }
    
}