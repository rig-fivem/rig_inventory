--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module drinks
--- @file configs/items/consumables/drinks.lua
--- @description Handles all static data items.
---
--- DO NOT FORGET TO INCLUDE THE CATEGORY `category = "drinks",` IF YOU ADD MORE TYPES.
--- WITHOUT THE CATEGORY `use_item` WILL FAIL

return {

    water_empty = {
        label = "Empty Bottle",
        description = {
            "An empty plastic water bottle.",
            "Can be filled at water pumps, rivers, or lakes."
        },
        image = "water_empty.png",
        weight = 30,
        w = 1,
        h = 2,
        actions = {
            drop = {
                model = "ba_prop_club_water_bottle"
            }
        }
    },

    water_dirty = {
        label = "Dirty Water Bottle",
        description = {
            "Water collected from an unsterilized source.",
            "Needs to be boiled before safe consumption."
        },
        image = "water_dirty.png",
        category = "drinks",
        weight = 330,
        w = 1,
        h = 2,
        actions = {
            drop = {
                model = "ba_prop_club_water_bottle"
            },
            use = {
                consume = {
                    statuses = {
                        thirst = { min = 20, max = 30 },
                        health = { min = -15, max = -5 }
                    },
                    remove_on_use = 1,
                    return_item = { id = "water_empty", amount = 1 }
                },
                animation = {
                    progress = { message = "Drinking Dirty Water..." },
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
                    }
                }
            }
        }
    },

    water_salt = {
        label = "Salt Water Bottle",
        description = {
            "Water collected directly from the ocean.",
            "Drinking this will cause severe dehydration."
        },
        image = "water_salt.png",
        category = "drinks",
        weight = 330,
        w = 1,
        h = 2,
        actions = {
            drop = {
                model = "ba_prop_club_water_bottle"
            },
            use = {
                consume = {
                    statuses = {
                        thirst = { min = -30, max = -20 }
                    },
                    remove_on_use = 1,
                    return_item = { id = "water_empty", amount = 1 }
                },
                animation = {
                    progress = { message = "Drinking Salt Water..." },
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
                    }
                }
            }
        }
    },

    water_clean = {
        label = "Clean Water Bottle",
        description = {
            "A refreshing bottle of purified water.",
            "Safe for drinking."
        },
        image = "water_clean.png",
        weight = 330,
        w = 1,
        h = 2,
        category = "drinks",
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
                consume = {
                    statuses = {
                        thirst = { min = 45, max = 65 }
                    },
                    remove_on_use = 1,
                    return_item = { id = "water_empty", amount = 1 }
                },
                animation = {
                    progress = { message = "Drinking Water..." },
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
                    }
                }
            }
        }
    }

}