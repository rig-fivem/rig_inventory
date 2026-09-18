--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module ammo
--- @file configs/items/weapons/ammo.lua
--- @description Handles all static data for items.
---
--- DO NOT FORGET TO INCLUDE THE TYPE `type = "ammo",` IF YOU ADD MORE TYPES.
--- WITHOUT THE TYPE `use_item` WILL FAIL

return {

    ammo_9mm = {
        type = "ammo",
        label = "9mm Ammo",
        description = "Standard 9x19mm Parabellum ammunition.",
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

    ammo_357 = {
        type = "ammo",
        label = ".357 Magnum Ammo",
        description = "Heavy caliber rounds for handguns and revolvers.",
        image = "ammo_357.png",
        weight = 12,
        w = 1,
        h = 1,
        stackable = 30,
        category = "ammo",
        metadata = {
            ammo_refill = 6,
        },
        actions = {
            drop = true,
            use = true
        }
    },

    ammo_12gauge = {
        type = "ammo",
        label = "12 Gauge Shells",
        description = "Heavy 12 gauge shotgun shells.",
        image = "ammo_12gauge.png",
        weight = 20,
        w = 1,
        h = 1,
        stackable = 25,
        category = "ammo",
        metadata = {
            ammo_refill = 8,
        },
        actions = {
            drop = true,
            use = true
        }
    },

    ammo_556 = {
        type = "ammo",
        label = "5.56mm Ammo",
        description = "Intermediate rifle ammunition for military carbines and assault rifles.",
        image = "ammo_556.png",
        weight = 10,
        w = 1,
        h = 1,
        stackable = 60,
        category = "ammo",
        metadata = {
            ammo_refill = 30,
        },
        actions = {
            drop = true,
            use = true
        }
    },

    ammo_762 = {
        type = "ammo",
        label = "7.62mm Ammo",
        description = "Heavy intermediate rounds used by AK-pattern rifles and light machine guns.",
        image = "ammo_762.png",
        weight = 12,
        w = 1,
        h = 1,
        stackable = 50,
        category = "ammo",
        metadata = {
            ammo_refill = 25,
        },
        actions = {
            drop = true,
            use = true
        }
    },

    ammo_308 = {
        type = "ammo",
        label = ".308 Rifle Ammo",
        description = "High-powered rifle cartridges designed for long-range engagements.",
        image = "ammo_308.png",
        weight = 15,
        w = 1,
        h = 1,
        stackable = 20,
        category = "ammo",
        metadata = {
            ammo_refill = 10,
        },
        actions = {
            drop = true,
            use = true
        }
    },

    ammo_musket = {
        type = "ammo",
        label = "Lead Balls & Black Powder",
        description = "Primitive black powder and heavy lead shot for musket firearms.",
        image = "ammo_musket.png",
        weight = 25,
        w = 1,
        h = 1,
        stackable = 15,
        category = "ammo",
        metadata = {
            ammo_refill = 1,
        },
        actions = {
            drop = true,
            use = true
        }
    },

}