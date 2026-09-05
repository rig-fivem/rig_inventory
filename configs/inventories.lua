--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
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
        rows = 3,
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
    },

    --- @section Containers

    storage_crate = {
        label = "Storage Crate",
        model = "prop_drop_crate_01",
        columns = 10,
        rows = 10,
        max_weight = 1000000,
        is_container = true,
        can_access = function(source, metadata)
            return true
        end
    },

    fridge = {
        label = "Fridge",
        model = "prop_fridge_03",
        columns = 10,
        rows = 4,
        max_weight = 500000,
        is_container = true,
        effects = {
            allowed_categories = { "food", "drink", "medical" },
            quality_preservation = 4.0
        }
    },

}