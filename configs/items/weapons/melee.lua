--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module melee
--- @file configs/items/weapons/melee.lua
--- @description Handles all static data for items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "melee",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    weapon_hatchet = {
        label = "Hatchet",
        description = "A sturdy wood-cutting utility hatchet, doubles well in a pinch.",
        image = "weapon_hatchet.png",
        weight = 1200,
        w = 1,
        h = 2,
        stackable = false,
        category = "melee",
        metadata = {
            rarity = "common",
            serial = "",
            durability = 100
        },
        actions = {
            drop = { model = "w_me_hatchet" },
            use = true
        }
    },

}