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

--- @section Imports

local _use = require("src.server.modules.actions.use")
local _move = require("src.server.modules.actions.move")
local _drop = require("src.server.modules.actions.drop")

--- @section Initialisation

local m = {}

m.use_item = _use.use_item
m.move_item = _move.move_item
m.drop_item = _drop.drop_item
m.pickup_drop = _drop.pickup_drop

return m