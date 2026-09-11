--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions
--- @file src/server/modules/actions.lua
--- @description Entry point merging split action modules.

--- @section Guard

if rawget(_G, "__server_actions_module") then
    return _G.__server_actions_module
end

--- @section Imports

local _use = require("src.server.modules.actions.use")
local _move = require("src.server.modules.actions.move")
local _drop = require("src.server.modules.actions.drop")


local _utils = require("src.server.modules.utils")

--- @section Initialisation

local m = {}
_G.__server_actions_module = m

m.use_item = _use.use_item
m.move_item = _move.move_item
m.drop_item = _drop.drop_item
m.pickup_drop = _drop.pickup_drop
m.add_item = _utils.add_item
m.remove_item = _utils.remove_item

--- @section Exports

exports("add_item", _utils.add_item)
exports("remove_item", _utils.remove_item)
exports("get_item_count", _utils.get_item_count)
exports("has_item", _utils.has_item)

return m