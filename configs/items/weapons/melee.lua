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
--- DO NOT FORGET TO INCLUDE THE TYPE `type = "weapon",` IF YOU ADD MORE TYPES.
--- WITHOUT THE TYPE `use_item` WILL FAIL

return {

    weapon_crowbar = {
        type = "weapon",
        label = "Crowbar",
        description = "A heavy steel tool useful for prying things open.",
        image = "weapon_crowbar.png",
        weight = 1200,
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
            drop = { model = "w_me_crowbar" },
            use = {
                loadout_slot = "melee"
            }
        }
    },

    weapon_hatchet = {
        type = "weapon",
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
        type = "weapon",
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
        type = "weapon",
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