--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions.drop
--- @file src/server/modules/actions/drop.lua
--- @description Handles item drop/pickup actions.

--- @section Imports

local _items = require("configs.items")
local _utils = require("src.server.modules.utils")

--- @section Initialisation

local m = {}

--- @section Drop Item

function m.drop_item(source, data)
    if not data or not data.col or not data.row or not data.group then
        return log("warn", "[drop_item] missing data")
    end

    local item = _utils.get_item(source, data.col, data.row, data.group)
    if not item then return log("info", "[drop_item] no item at position") end

    local def = _items[item.id]
    if not def or not def.actions or not def.actions.drop then
        return log("info", "[drop_item] item not droppable: " .. item.id)
    end

    local quantity = math.min(tonumber(data.quantity) or item.quantity or 1, item.quantity or 1)
    if quantity <= 0 then return log("warn", "[drop_item] zero quantity") end

    local model = type(def.actions.drop) == "table" and def.actions.drop.model or def.model or "prop_paper_bag_small"

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return log("error", "[drop_item] no ped") end

    local removed = _utils.remove_item(source, data.col, data.row, data.group, quantity)
    if not removed then return log("error", "[drop_item] remove failed") end

    local coords = GetEntityCoords(ped)
    local drop_id = core.drops:add({
        item_id = item.id,
        label = def.label,
        description = def.description,
        image = def.image or item.id,
        category = def.category,
        weight = def.weight,
        w = def.w or 1,
        h = def.h or 1,
        model = model,
        quantity = quantity,
        metadata = item.metadata,
        coords = { x = coords.x, y = coords.y, z = coords.z - 1.0 }
    })

    _utils.sync_and_refresh(source)
    log("success", ("[drop_item] src:%s dropped %s x%d drop_id:%d"):format(source, item.id, quantity, drop_id))
end

--- @section Pickup Drop

function m.pickup_drop(source, drop_id)
    if not drop_id then return log("warn", "[pickup_drop] no drop_id") end

    local drop = core.drops:get(drop_id)
    if not drop then return log("warn", "[pickup_drop] drop missing: " .. tostring(drop_id)) end

    if not core.drops:lock(drop_id) then
        return log("warn", "[pickup_drop] drop already locked: " .. tostring(drop_id))
    end

    local success = _utils.add_item(source, drop.item_id, drop.quantity, nil, drop.metadata)
    if not success then
        core.drops:unlock(drop_id)
        return log("warn", "[pickup_drop] add_item failed for: " .. drop.item_id)
    end

    core.drops:remove(drop_id)
    _utils.sync_and_refresh(source)
    log("success", ("[pickup_drop] src:%s picked up %s x%d"):format(source, drop.item_id, drop.quantity))
end

return m