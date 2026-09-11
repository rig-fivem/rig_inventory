--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module attachments
--- @file configs/items/weapons/attachments.lua
--- @description Handles all static data for items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "attachments",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    pistol_mag_extended = {
        label = "Extended Mag: Pistol",
        description = {
            "Extended magazine for supported 9mm pistols."
        },
        image = "pistol_mag_extended.png",
        weight = 250,
        w = 1,
        h = 1,
        category = "attachments",
        metadata = {
            rarity = "rare",
        },
        actions = {
            drop = true,
            use = {
                attachments = {
                    { weapon = "weapon_pistol", component = "COMPONENT_PISTOL_CLIP_02" },
                    { weapon = "weapon_pistol_mk2", component = "COMPONENT_PISTOL_MK2_CLIP_02" },
                    { weapon = "weapon_combatpistol", component = "COMPONENT_COMBATPISTOL_CLIP_02" },
                    { weapon = "weapon_appistol", component = "COMPONENT_APPISTOL_CLIP_02" },
                    { weapon = "weapon_pistol50", component = "COMPONENT_PISTOL50_CLIP_02" },
                    { weapon = "weapon_snspistol", component = "COMPONENT_SNSPISTOL_CLIP_02" },
                    { weapon = "weapon_snspistol_mk2", component = "COMPONENT_SNSPISTOL_MK2_CLIP_02" },
                    { weapon = "weapon_heavypistol", component = "COMPONENT_HEAVYPISTOL_CLIP_02" },
                    { weapon = "weapon_vintagepistol", component = "COMPONENT_VINTAGEPISTOL_CLIP_02" },
                    { weapon = "weapon_ceramicpistol", component = "COMPONENT_CERAMICPISTOL_CLIP_02" }
                }
            }
        }
    },
    
}