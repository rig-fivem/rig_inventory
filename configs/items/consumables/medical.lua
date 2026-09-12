--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case ([https://caseirl.dev](https://caseirl.dev))
Repo: [https://github.com/rig-fivem/rig_inventory](https://github.com/rig-fivem/rig_inventory)
License: [https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE](https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE)
----------------------------------------
]]

--- @module medical
--- @file configs/items/consumables/medical.lua
--- @description Handles all medical consumable items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "medical",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    bandage = {
        label = "Bandage",
        description = {
            "A medical bandage treated with antiseptic.",
            "Stops light bleeding and restores health."
        },
        image = "bandage.png",
        category = "medical",
        weight = 50,
        w = 1,
        h = 1,
        metadata = {
            rarity = "common"
        },
        actions = {
            craft = {
                progress = { type = "circle", message = "Crafting Bandage..." },
                duration = 3500,
                ingredients = {
                    { id = "cloth", amount = 3 }
                },
            },
            drop = true,
            use = {
                consume = {
                    statuses = {
                        health = { min = 25, max = 35 }
                    },
                    remove_on_use = 1
                },
                animation = {
                    progress = { type = "circle", message = "Applying Bandage..." },
                    dict = "missmic4",
                    anim = "michael_tux_fidget",
                    flags = 49,
                    duration = 4000,
                    freeze = false,
                    continuous = false
                }
            }
        }
    }

}