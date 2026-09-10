return {

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

}