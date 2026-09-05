--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module inventory
--- @file src/client/nui/inventory.lua
--- @description Handles client-side inventory UI orchestration.

--- @section Imports

local _nui = require("src.client.modules.nui")
local _layout = require("src.client.nui.layout")
local _panels = require("src.client.nui.panels")

--- @section Initialisation

local m = {}

--- @section Functions

function m.build(payload)
    local player_data = payload and payload.player_data
    if not player_data then return end

    _nui.build_ui({
        header = _layout.build_header(player_data),
        footer = _layout.build_footer(),
        content = {
            pages = {
                inventory_page = {
                    index = 1,
                    title = "Inventory",
                    layout = { left = 3, center = 2, spacer3 = 4, right = 3 },
                    left = {
                        type = "grid",
                        title = { text = "Inventories" },
                        layout = { scroll_x = "none", scroll_y = "scroll" },
                        groups = _panels.build_player_groups(player_data)
                    },
                    center = _panels.build_center(player_data),
                    right = _panels.build_right()
                }
            },
            hotbar = _panels.build_hotbar(player_data)
        }
    })
end

return m