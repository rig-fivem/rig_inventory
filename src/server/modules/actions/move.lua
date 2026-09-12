--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions.move
--- @file src/server/modules/actions/move.lua
--- @description Handles item move/swap actions

--- @section Imports

local _items = require("src.shared.data.items")
local _inventories = require("configs.inventories")
local _drop = require("src.server.modules.actions.drop")
local _utils = require("src.server.modules.utils")

--- @section Constants

local HOTBAR_ALLOWED_CATEGORIES = {
    food = true,
    drinks = true,
    medical = true
}

--- @section Initialisation

local m = {}

--- @section Helpers

local function resolve_group(section)
    if not section then return nil end
    return section:gsub("^left_", ""):gsub("^right_", ""):gsub("^center_", "")
end

local function is_player_group(group_id)
    local def = _inventories[group_id]
    return def and def.is_player == true
end

local function parse_vehicle_group(group_id)
    local inv_type, plate = group_id:match("^vehicle:([^:]+):(.+)$")
    return inv_type ~= nil, inv_type, plate
end

local function is_hotbar_allowed(item_id)
    local def = _items[item_id]
    return def and HOTBAR_ALLOWED_CATEGORIES[def.category] == true
end

--- @section Adapters

local function player_adapter(source)
    return {
        kind = "player",
        key = "player:" .. source,
        container = nil,
        get_item = function(col, row, group)
            return _utils.get_item(source, col, row, group)
        end,
        remove_item = function(col, row, group, qty)
            return _utils.remove_item(source, col, row, group, qty)
        end,
        place_item = function(group, col, row, item)
            return _utils.place_item(source, group, col, row, item)
        end,
    }
end

local function container_adapter(container)
    return {
        kind = "container",
        key = "container:" .. container.identifier,
        container = container,
        get_item = function(col, row, group)
            return container:get_item({ col = col, row = row }, 1, group)
        end,
        remove_item = function(col, row, group, qty)
            return container:remove_item({ col = col, row = row }, qty, group)
        end,
        place_item = function(group, col, row, item)
            return container:place_item(group, col, row, item)
        end,
    }
end

local function resolve_side(source, group, is_vehicle, vehicle_inv_type, vehicle_plate)
    if is_vehicle then
        local container = core.containers:get(("vehicle:%s:%s"):format(vehicle_inv_type, vehicle_plate))
            or core.containers:get_or_create_vehicle(vehicle_plate, vehicle_inv_type)
        if not container then return nil, "vehicle_container_missing" end
        return container_adapter(container)
    end

    if is_player_group(group) then
        return player_adapter(source)
    end

    local container_id = core.containers:get_locked_by_player(source)
    if not container_id then return nil, "no_locked_container" end

    local container = core.containers:get(container_id)
    if not container then return nil, "locked_container_missing" end

    return container_adapter(container)
end

--- @section Generic Move

local function perform_move(from_side, from_col, from_row, from_group, to_side, to_col, to_row, to_group)
    if from_side.key == to_side.key and from_col == to_col and from_row == to_row and from_group == to_group then
        return false, "item_move_same_slot"
    end

    local source_item = from_side.get_item(from_col, from_row, from_group)
    if not source_item then return false, "source_item_missing" end

    local move_payload = {
        id = source_item.id,
        quantity = source_item.quantity or 1,
        metadata = source_item.metadata,
        w = source_item.w,
        h = source_item.h
    }

    local removed = from_side.remove_item(from_col, from_row, from_group, move_payload.quantity)
    if not removed then return false, "source_remove_failed" end

    local placed, place_msg, displaced = to_side.place_item(to_group, to_col, to_row, move_payload)

    if not placed then
        from_side.place_item(from_group, from_col, from_row, move_payload)
        return false, place_msg or "destination_place_failed"
    end

    if displaced then
        local restored = from_side.place_item(from_group, from_col, from_row, {
            id = displaced.id, quantity = displaced.quantity, metadata = displaced.metadata,
            w = displaced.w, h = displaced.h
        })
        if not restored then
            log("error", ("[move_item] displaced item lost during swap: %s"):format(json.encode(displaced)))
        end
    end

    return true, place_msg
end

--- @section Move Item

function m.move_item(source, move_data)
    if not move_data then return log("error", "[move_item] no data") end

    local from_group = resolve_group(move_data.from_section or move_data.from_group)
    local to_group = resolve_group(move_data.to_section or move_data.to_group)

    if not from_group or not to_group then
        return log("error", ("[move_item] incomplete data: %s"):format(json.encode(move_data)))
    end

    if to_group == "hotbar" and from_group ~= "hotbar" then
        local from_col = tonumber(move_data.from_col)
        local from_row = tonumber(move_data.from_row)
        if not from_col or not from_row then
            return log("error", "[move_item] hotbar assign missing from_col/from_row")
        end

        local item = _utils.get_item(source, from_col, from_row, from_group)
        if not item or not is_hotbar_allowed(item.id) then
            exports.rig:notify(source, {
                type = "error", header = "Inventory",
                message = "That item can't go in your hotbar",
                duration = 3000
            })
            return _utils.sync_and_refresh(source)
        end

        return _utils.assign_to_hotbar(source, from_col, from_row, from_group, move_data.to_slot)
    end

    if from_group == "hotbar" and to_group ~= "hotbar" then
        local to_col = tonumber(move_data.to_col)
        local to_row = tonumber(move_data.to_row)
        if not to_col or not to_row then
            return log("error", ("[move_item] hotbar move missing to_col/to_row: %s"):format(json.encode(move_data)))
        end
        return _utils.move_from_hotbar(source, move_data.from_slot, to_col, to_row, to_group)
    end

    if from_group == "hotbar" and to_group == "hotbar" then
        return _utils.swap_hotbar_slots(source, move_data.from_slot, move_data.to_slot)
    end

    if to_group == "vicinity" then
        local from_col = tonumber(move_data.from_col)
        local from_row = tonumber(move_data.from_row)
        _drop.drop_item(source, { col = from_col, row = from_row, group = from_group })
        return
    end

    if from_group == "vicinity" then
        local drop_id = move_data.dataset and tonumber(move_data.dataset.drop_id)
        if drop_id then _drop.pickup_drop(source, drop_id) end
        return
    end

    local from_col = tonumber(move_data.from_col)
    local from_row = tonumber(move_data.from_row)
    local to_col = tonumber(move_data.to_col)
    local to_row = tonumber(move_data.to_row)

    if not from_col or not from_row or not to_col or not to_row then
        return log("error", ("[move_item] incomplete data: %s"):format(json.encode(move_data)))
    end

    log("debug", ("[move_item] src:%s | from:%s_%s(%s) -> to:%s_%s(%s)"):format(source, from_col, from_row, from_group, to_col, to_row, to_group))

    local from_is_vehicle, from_inv_type, from_plate = parse_vehicle_group(from_group)
    local to_is_vehicle, to_inv_type, to_plate = parse_vehicle_group(to_group)

    local from_side, from_err = resolve_side(source, from_group, from_is_vehicle, from_inv_type, from_plate)
    if not from_side then
        return log("error", ("[move_item] could not resolve source side (%s): %s"):format(from_group, from_err))
    end

    local to_side, to_err = resolve_side(source, to_group, to_is_vehicle, to_inv_type, to_plate)
    if not to_side then
        return log("error", ("[move_item] could not resolve destination side (%s): %s"):format(to_group, to_err))
    end

    local success, msg = perform_move(from_side, from_col, from_row, from_group, to_side, to_col, to_row, to_group)

    if not success then
        return log("warn", ("[move_item] src:%s %s -> %s failed: %s"):format(source, from_group, to_group, tostring(msg)))
    end

    if from_side.container then from_side.container:save() end
    if to_side.container and to_side.container ~= from_side.container then to_side.container:save() end

    _utils.sync_and_refresh(source, to_side.container or from_side.container)

    log("success", ("[move_item] src:%s %s -> %s ok (%s)"):format(source, from_group, to_group, tostring(msg)))
end

return m