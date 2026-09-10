--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module configs.items
--- @description Handles all static data for items.

local items = {}

local categories = { "ammo", "attachments", "consumables", "containers", "resources", "weapons" }

for _, category in ipairs(categories) do
    local category_items = require(("configs.items.%s"):format(category))
    for item_id, data in pairs(category_items) do
        items[item_id] = data
    end
end

return items

--[[
return {

    --- @section Food/Drinks

    water = {
        label = "Water",
        description = {
            "A refreshing bottle of clean water.",
            "Can be purchased from most stores."
        },
        image = "water.png",
        weight = 330,
        w = 1,
        h = 1,
        metadata = {
            rarity = "common",
            quality = 100,
            degrade_rate = 0.25
        },
        actions = {
            drop = {
                model = "ba_prop_club_water_bottle"
            },
            use = {
                animation = {
                    progress = { message = "Drinking Water.." },
                    dict = "mp_player_intdrink",
                    anim = "loop_bottle",
                    flags = 49,
                    duration = 5000,
                    freeze = false,
                    continuous = false,
                    props = {
                        {
                            model = "ba_prop_club_water_bottle",
                            bone = 60309,
                            coords = { x = 0.0, y = 0.0, z = -0.05 },
                            rotation = { x = 0.0, y = 0.0, z = 0.0 },
                            soft_pin = false,
                            collision = false,
                            is_ped = true,
                            rot_order = 1,
                            sync_rot = true
                        }
                    },
                    callback = function(source, data)
                        print("source: ", source)
                        print("data: ", json.encode(data))
                    end
                }
            }
        }
    },

    --- @section Ammo

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

    --- @section Attachments

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

    --- @section Weapons

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
            use = true
        }
    },

    --- @section Player Inventories

    dufflebag = {
        label = "Dufflebag",
        description = "It's a duffle, it holds things.",
        image = "dufflebag.png",
        weight = 1000,
        w = 2,
        h = 2,
        stackable = false,
        category = "player_inventory",
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
                    continuous = false,
                    callback = function(source, data)
                        core.toggle_player_inventory(source, data)
                    end
                }
            }
        }
    },

    --- @section Materials

    wood = {
        label = "Water",
        description = {
            "A refreshing bottle of clean water.",
            "Can be purchased from most stores."
        },
        image = "water.png",
    }

}
    ]]