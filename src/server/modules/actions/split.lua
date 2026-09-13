--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions.split
--- @file src/server/modules/actions/split.lua
--- @description Handles splitting a stack of items into a free slot

--- @section Imports

local _inventories = require("configs.inventories")
local _items = require("src.shared.data.items")
local _utils = require("src.server.modules.utils")

--- @section Helpers

local function resolve_group(section)
    if not section then return nil end
    return section:gsub("^left_", ""):gsub("^right_", ""):gsub("^center_", "")
end

local function is_player_group(group_id)
    local def = _inventories[group_id]
    return def and def.is_player == true
end

--- @section Initialisation

local m = {}

--- @section Split Item

function m.split_item(source, data)
    if not data then return log("error", "[split_item] no data") end

    local group = resolve_group(data.group or data.group_id)
    local col = tonumber(data.col)
    local row = tonumber(data.row)
    local split_qty = tonumber(data.quantity)

    if not group or not col or not row or not split_qty then
        return log("error", ("[split_item] incomplete data: %s"):format(json.encode(data)))
    end

    if group == "hotbar" or group == "vicinity" then
        return log("warn", ("[split_item] src:%s rejected, '%s' can't be split against"):format(source, group))
    end

    if not is_player_group(group) then
        return log("warn", ("[split_item] src:%s rejected, '%s' is not a player group"):format(source, group))
    end

    if split_qty <= 0 or split_qty ~= math.floor(split_qty) then
        return log("warn", ("[split_item] src:%s invalid split quantity: %s"):format(source, tostring(split_qty)))
    end

    local item = _utils.get_item(source, col, row, group)
    if not item then
        return log("warn", ("[split_item] src:%s no item at %s_%s(%s)"):format(source, col, row, group))
    end

    local def = _items[item.id]
    if not def then
        return log("error", ("[split_item] no item definition for %s"):format(item.id))
    end

    local stackable = def.stackable
    if stackable == nil then stackable = true end
    if stackable == false then
        return log("warn", ("[split_item] src:%s item %s is not stackable"):format(source, item.id))
    end

    local current_qty = item.quantity or 1

    if split_qty >= current_qty then
        exports.rig:notify(source, {
            type = "error", header = "Inventory",
            message = "You can't split off the whole stack",
            duration = 3000
        })
        return
    end

    local w = item.w or def.w or 1
    local h = item.h or def.h or 1

    local target_col, target_row = _utils.find_free_slot(source, group, w, h)
    if not target_col then
        exports.rig:notify(source, {
            type = "error", header = "Inventory",
            message = "Not enough space to split that stack",
            duration = 3000
        })
        return
    end

    local removed = _utils.remove_item(source, col, row, group, split_qty)
    if not removed then
        return log("error", ("[split_item] src:%s failed to remove %s from source stack"):format(source, split_qty))
    end

    local placed, place_msg = _utils.place_item(source, group, target_col, target_row, {
        id = item.id,
        quantity = split_qty,
        metadata = item.metadata,
        w = w,
        h = h
    })

    if not placed then
        _utils.place_item(source, group, col, row, {
            id = item.id, quantity = split_qty, metadata = item.metadata, w = w, h = h
        })
        return log("error", ("[split_item] src:%s failed to place split stack: %s"):format(source, tostring(place_msg)))
    end

    _utils.sync_and_refresh(source)

    log("success", ("[split_item] src:%s split %sx %s from %s_%s(%s) -> %s_%s"):format(
        source, split_qty, item.id, col, row, group, target_col, target_row
    ))
end

return m