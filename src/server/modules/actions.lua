--- @module actions
--- @file src/server/modules/actions.lua
--- @description Handles all inventory actions; use, move, drop, etc.

--- @section Imports

local inv_defs = require("configs.inventories")

--- @section Initialisation

local m = {}

--- @section Helpers

local function resolve_group(section)
    if not section then return nil end
    return section:gsub("^left_", ""):gsub("^right_", ""):gsub("^center_", "")
end

local function is_player_group(group_id)
    local def = inv_defs[group_id]
    return def and def.is_player == true
end

local function sync_and_refresh(source)
    local synced = exports.rig:sync_player_data(source)
    if not synced then print("player data sync failed") return end

    local inv_data = exports.rig:get_inventory(source)
    if inv_data then
        print("sync inv data; ", json.encode(inv_data))
        TriggerClientEvent("rig_inventory:client:inventory_changed", source, inv_data)
        return
    end

    TriggerClientEvent("rig_inventory:client:inventory_changed", source)
end

--- @section Move Item

function m.move_item(source, move_data)
    if not move_data then return log("error", "[move_item] no data") end

    local from_col = tonumber(move_data.from_col)
    local from_row = tonumber(move_data.from_row)
    local to_col = tonumber(move_data.to_col)
    local to_row = tonumber(move_data.to_row)
    local from_group = resolve_group(move_data.from_section or move_data.from_group)
    local to_group = resolve_group(move_data.to_section or move_data.to_group)

    if not from_col or not from_row or not to_col or not to_row or not from_group or not to_group then
        return log("error", ("[move_item] incomplete data: %s"):format(json.encode(move_data)))
    end

    log("debug", ("[move_item] src:%s | from:%s_%s(%s) -> to:%s_%s(%s)"):format(source, from_col, from_row, from_group, to_col, to_row, to_group))

    if to_group == "vicinity" then
        m.drop_item(source, { col = from_col, row = from_row, group = from_group })
        return
    end

    if from_group == "vicinity" then
        local drop_id = move_data.dataset and tonumber(move_data.dataset.drop_id)
        if drop_id then m.pickup_drop(source, drop_id) end
        return
    end

    local from_is_player = is_player_group(from_group)
    local to_is_player = is_player_group(to_group)

    if from_is_player and to_is_player then
        local inv_data = exports.rig:get_inventory(source)
        if not inv_data or not inv_data.items then 
            return log("error", "[move_item] no player inventory data") 
        end

        local from_key = from_col .. "_" .. from_row
        local to_key = to_col .. "_" .. to_row

        local from_items = inv_data.items[from_group]
        local to_items = inv_data.items[to_group]

        local source_item = from_items and from_items[from_key]
        if not source_item then 
            return log("warn", "[move_item] source item missing") 
        end

        local target_item = to_items and to_items[to_key]

        source_item.col = to_col
        source_item.row = to_row

        local changes = {
            { group_id = from_group, key = from_key, item = target_item },
            { group_id = to_group, key = to_key, item = source_item }
        }

        if target_item then
            target_item.col = from_col
            target_item.row = from_row
        end

        local success = exports.rig:set_inventory_slots(source, changes)
        if success then
            sync_and_refresh(source)
            log("success", "[move_item] player -> player ok")
        else
            log("warn", "[move_item] player move failed")
        end
        return
    end

    log("error", "[move_item] unhandled move case")
end

return m