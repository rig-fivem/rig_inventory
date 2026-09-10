--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions.remove
--- @file src/server/modules/actions/remove.lua
--- @description Remove item actions.

--- @section Imports

local _utils = require("src.server.modules.utils")

--- @section Initalisation

local m = {}

--- @section Functions

function m.remove_item(source, col, row, group, amount)
    local item = _utils.get_item(source, col, row, group)
    if not item then return false end

    amount = amount or 1
    local qty = item.quantity or 1

    if qty <= amount then
        return _utils.set_item(source, col, row, group, nil)
    end

    item.quantity = qty - amount
    return _utils.set_item(source, col, row, group, item)
end

return m