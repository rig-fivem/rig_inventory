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

    --- @section Pistols

    weapon_pistol = {
        label = "Pistol",
        description = "9mm semi-automatic pistol.",
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
            use = {
                loadout_slot = "secondary"
            }
        }
    },

    --- @section Revolvers

    weapon_navyrevolver = {
        label = "Navy Revolver",
        description = "An old cap-and-ball revolver chambered for lead balls and black powder.",
        image = "weapon_navyrevolver.png",
        weight = 1100,
        w = 2,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "common",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_musket" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_pi_navyrevolver" },
            use = {
                loadout_slot = "secondary"
            }
        }
    },

    weapon_doubleaction = {
        label = "Double-Action Revolver",
        description = "A lightweight six-shooter with a quick trigger.",
        image = "weapon_doubleaction.png",
        weight = 900,
        w = 2,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "uncommon",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_357" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_pi_doubleaction" },
            use = {
                loadout_slot = "secondary"
            }
        }
    },

    --- @section SMGs

    weapon_microsmg = {
        label = "Micro SMG",
        description = "A compact, rapid-fire submachine gun chambered in 9mm.",
        image = "weapon_microsmg.png",
        weight = 1600,
        w = 2,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "uncommon",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_9mm" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_sb_microsmg" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

    weapon_smg = {
        label = "SMG",
        description = "A well-balanced submachine gun with a higher rate of fire.",
        image = "weapon_smg.png",
        weight = 2200,
        w = 2,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "rare",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_9mm" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_sb_smg" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

    --- @section Shotguns

    weapon_pumpshotgun = {
        label = "Pump Shotgun",
        description = "12 gauge pump-action shotgun.",
        image = "weapon_pumpshotgun.png",
        weight = 3500,
        w = 3,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "uncommon",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_12gauge" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_sg_pumpshotgun" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

    --- @section Rifles

    weapon_musket = {
        label = "Musket",
        description = "Black powder musket firing lead ball shot.",
        image = "weapon_musket.png",
        weight = 4200,
        w = 4,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "common",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_musket" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_ar_musket" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

    weapon_carbinerifle = {
        label = "Carbine Rifle",
        description = "5.56mm semi-automatic carbine.",
        image = "weapon_carbinerifle.png",
        weight = 3200,
        w = 3,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "uncommon",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_556" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_ar_carbinerifle" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

    weapon_assaultrifle = {
        label = "Assault Rifle",
        description = "7.62mm AK-pattern assault rifle.",
        image = "weapon_assaultrifle.png",
        weight = 3300,
        w = 3,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "rare",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_762" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_ar_assaultrifle" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

    weapon_sniperrifle = {
        label = "Sniper Rifle",
        description = ".308 bolt-action sniper rifle.",
        image = "weapon_sniperrifle.png",
        weight = 4500,
        w = 4,
        h = 2,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "epic",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_308" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_sr_sniperrifle" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

    --- @section LMGs

    weapon_mg = {
        label = "Machine Gun",
        description = "A belt-fed 7.62mm machine gun, heavy but relentless in a firefight.",
        image = "weapon_mg.png",
        weight = 6500,
        w = 4,
        h = 3,
        stackable = false,
        category = "firearms",
        metadata = {
            rarity = "epic",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_762" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_mg_mg" },
            use = {
                loadout_slot = "primary"
            }
        }
    },

}