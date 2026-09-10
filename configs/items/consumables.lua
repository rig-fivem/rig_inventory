return {

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

}