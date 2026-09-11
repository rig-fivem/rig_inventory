--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module food
--- @file configs/items/consumables/food.lua
--- @description Handles all static data items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "food",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module food
--- @file configs/items/consumables/food.lua
--- @description Handles all static data items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "food",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    bread = {
        label = "Bread",
        description = {
            "A loaf of bread.",
            "Fills you up, but doesn't quench thirst."
        },
        image = "bread.png",
        category = "food",
        weight = 200,
        w = 1,
        h = 1,
        metadata = {
            rarity = "common",
            quality = 100,
            degrade_rate = 0.5
        },
        actions = {
            drop = {
                model = "prop_bread_01"
            },
            use = {
                consume = {
                    statuses = {
                        hunger = { min = 30, max = 45 }
                    },
                    remove_on_use = 1
                },
                animation = {
                    progress = { message = "Eating Bread..." },
                    dict = "mp_player_int_uppr_food",
                    anim = "mp_player_int_eat_burger",
                    flags = 49,
                    duration = 4000,
                    freeze = false,
                    continuous = false
                }
            }
        }
    },

    canned_dog_food = {
        label = "Dog Food",
        description = {
            "A can of dog food.",
            "Edible in a pinch, but you won't enjoy it."
        },
        image = "canned_dog_food.png",
        category = "food",
        weight = 400,
        w = 1,
        h = 1,
        metadata = {
            rarity = "common"
        },
        actions = {
            drop = {
                model = "prop_cs_dog_food"
            },
            use = {
                consume = {
                    statuses = {
                        hunger = { min = 45, max = 65 },
                        health = { min = -5, max = 0 }
                    },
                    remove_on_use = 1
                },
                animation = {
                    progress = { message = "Eating Dog Food..." },
                    dict = "mp_player_int_uppr_food",
                    anim = "mp_player_int_eat_burger",
                    flags = 49,
                    duration = 4000,
                    freeze = false,
                    continuous = false
                }
            }
        }
    }

}