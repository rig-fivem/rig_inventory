return {

    --- @section Materials

    wood = {
        label = "Wood",
        description = {
            "Raw timber harvested from the environment.",
            "Useful for crafting and building."
        },
        image = "wood.png",
        weight = 500,
        w = 1,
        h = 1,
        stackable = 100,
        category = "materials",
        metadata = {
            rarity = "common"
        },
        actions = {
            drop = {
                model = "prop_railsleepers01"
            }
        }
    },

    stone = {
        label = "Stone",
        description = {
            "Raw rock broken off from rock deposits.",
            "Essential for primitive crafting, tools, and construction."
        },
        image = "stone.png",
        weight = 750,
        w = 1,
        h = 1,
        stackable = 100,
        category = "materials",
        metadata = {
            rarity = "common"
        },
        actions = {
            drop = {
                model = "prop_wallbrick_03"
            }
        }
    }

}