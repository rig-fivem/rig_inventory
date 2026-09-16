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

    weapon_stonehatchet = {
        label = "Stone Hatchet",
        description = "A crude hatchet bound with stone and cord. Slow, but it'll get the job done.",
        image = "weapon_stonehatchet.png",
        weight = 900,
        w = 1,
        h = 2,
        stackable = false,
        category = "melee",
        metadata = {
            rarity = "common",
            serial = "",
            durability = 60
        },
        actions = {
            drop = { model = "w_me_stonehatchet" },
            use = {
                loadout_slot = "melee"
            }
        }
    },

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
            use = {
                loadout_slot = "melee"
            }
        }
    },

    weapon_knife = {
        label = "Knife",
        description = "A small fixed-blade knife, good for close quarters or field dressing game.",
        image = "weapon_knife.png",
        weight = 250,
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
            drop = { model = "w_me_knife_01" },
            use = {
                loadout_slot = "melee"
            }
        }
    },

    weapon_machete = {
        label = "Machete",
        description = "A long, heavy blade suited for both self-defense and heavy fieldwork.",
        image = "weapon_machete.png",
        weight = 1000,
        w = 1,
        h = 2,
        stackable = false,
        category = "melee",
        metadata = {
            rarity = "uncommon",
            serial = "",
            durability = 100
        },
        actions = {
            drop = { model = "w_me_machette_lr" },
            use = {
                loadout_slot = "melee"
            }
        }
    },

}