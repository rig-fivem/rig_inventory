--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module layout
--- @file src/client/nui/layout.lua
--- @description Handles building outer NUI frame structures.

--- @section Imports

local _nui = require("src.client.modules.nui")

--- @section Initalisation

local m = {}

--- @section Functions

function m.build_header(player_data)
    return {
        layout = {
            left = { justify = "flex-start" },
            center = { justify = "center" },
            right = { justify = "flex-end" }
        },
        elements = {
            left = {
                {
                    type = "group",
                    items = {
                        { type = "logo", image = _nui.get_player_headshot() },
                        { type = "text", title = player_data.name or player_data.username or "Unknown", subtitle = player_data.unique_id }
                    }
                }
            },
            center = { { type = "tabs" } },
            right = {
                {
                    type = "buttons",
                    buttons = {
                        {
                            id = "close_inventory",
                            label = "Close",
                            class = "primary",
                            should_close = true,
                            on_action = function()
                                TriggerServerEvent("rig_inventory:server:close_inventory")
                            end
                        }
                    }
                }
            }
        }
    }
end

function m.build_footer()
    return {
        layout = {
            left = { justify = "flex-start" },
            center = { justify = "center" },
            right = { justify = "flex-end" }
        },
        elements = {
            right = {
                {
                    type = "actions",
                    actions = {
                        {
                            key = "ESCAPE",
                            label = "Close",
                            should_close = true,
                            on_action = function()
                                TriggerServerEvent("rig_inventory:server:close_inventory")
                            end
                        }
                    }
                }
            }
        }
    }
end

return m