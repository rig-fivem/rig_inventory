--[[
--------------------------------------------------

This file is part of RIG.
Please retain this header in all files.
Support honest open source development.

Author: Case @ BOII Development
Website: https://boii.dev
GitHub: https://github.com/rig-framework/rig
License: LGPL-3.0

--------------------------------------------------
]]

--- @module configs.inventories
--- @description Handles all static data for different inventory types.

return {

    --- @section Player

    pockets = {
        label = "Pockets",
        icon = "fa-solid fa-hand",
        is_player = true,
        columns = 10,
        rows = 2,
        max_weight = 20000,
        collapsible = true,
        collapsed = false,
    },

    dufflebag = {
        label = "Dufflebag",
        icon = "fa-solid fa-bag-shopping",
        is_player = true,
        columns = 10,
        rows = 5,
        max_weight = 60000,
        collapsible = true,
        collapsed = false,
    }

}