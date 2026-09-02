--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module utils
--- @file src/server/modules/utils.lua
--- @description Handles server side utility functions.

--- @section Imports

local _items = require("configs.items")
local _inventories = require("configs.inventories")

--- @section Initialisation

local m = {}

--- @section Helpers

local function metadata_equal(a, b)
    if a == b then return true end
    if not a or not b then return false end
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

local function get_player_group_priority(source)
    local inv = exports.rig:get_inventory(source)
    local existing = inv and inv.items or {}

    local groups = {}
    for group_id, def in pairs(_inventories) do
        if def.is_player and existing[group_id] ~= nil then
            groups[#groups + 1] = { id = group_id, priority = def.priority or math.huge }
        end
    end
    table.sort(groups, function(a, b) return a.priority < b.priority end)

    local ids = {}
    for _, entry in ipairs(groups) do ids[#ids + 1] = entry.id end
    return ids
end

local function resolve_target_group(source, w, h)
    for _, group_id in ipairs(get_player_group_priority(source)) do
        local col, row = m.find_free_slot(source, group_id, w, h)
        if col then return group_id, col, row end
    end
    return nil
end

--- @section Get / Set

function m.get_item(source, col, row, group)
    local inv = exports.rig:get_inventory(source)
    if not inv or not inv.items or not inv.items[group] then return nil end
    return inv.items[group][col .. "_" .. row]
end

function m.set_item(source, col, row, group, item)
    return exports.rig:set_inventory_slots(source, {
        { group_id = group, key = col .. "_" .. row, item = item }
    })
end

--- @section Remove

function m.remove_item(source, col, row, group, amount)
    local item = m.get_item(source, col, row, group)
    if not item then return false end

    amount = amount or 1
    local qty = item.quantity or 1

    if qty <= amount then
        return m.set_item(source, col, row, group, nil)
    end

    item.quantity = qty - amount
    return m.set_item(source, col, row, group, item)
end

--- @section Free Slot

function m.find_free_slot(source, group, w, h)
    w = w or 1
    h = h or 1

    local def = _inventories[group]
    if not def then return nil end

    local inv = exports.rig:get_inventory(source)
    local items = inv and inv.items and inv.items[group] or {}

    local cols = def.columns or 10
    local rows = def.rows or 4

    local occupied = {}
    for key, item in pairs(items) do
        local ic, ir = key:match("^(%d+)_(%d+)$")
        ic, ir = tonumber(ic), tonumber(ir)
        if ic and ir then
            local iw = item.w or (_items[item.id] and _items[item.id].w) or 1
            local ih = item.h or (_items[item.id] and _items[item.id].h) or 1
            for dc = 0, iw - 1 do
                for dr = 0, ih - 1 do
                    occupied[(ic + dc) .. "_" .. (ir + dr)] = true
                end
            end
        end
    end

    for r = 1, rows - (h - 1) do
        for c = 1, cols - (w - 1) do
            local fits = true
            for dc = 0, w - 1 do
                for dr = 0, h - 1 do
                    if occupied[(c + dc) .. "_" .. (r + dr)] then
                        fits = false
                        break
                    end
                end
                if not fits then break end
            end
            if fits then return c, r end
        end
    end

    return nil, nil
end

--- @section Add

function m.add_item(source, item_id, quantity, group, metadata)
    quantity = quantity or 1
    if type(quantity) ~= "number" or quantity <= 0 then return false, "item_invalid_amount" end

    local def = _items[item_id]
    if not def then return false, "invalid_item_id" end

    metadata = metadata or nil

    local w = def.w or 1
    local h = def.h or 1
    local stackable = def.stackable
    if stackable == nil then stackable = true end
    local max_stack = type(stackable) == "number" and stackable or math.huge

    local remaining = quantity
    local search_groups = group and { group } or get_player_group_priority()

    if stackable ~= false then
        local inv = exports.rig:get_inventory(source)
        for _, group_id in ipairs(search_groups) do
            local items = inv and inv.items and inv.items[group_id] or {}
            for key, existing in pairs(items) do
                if existing.id == item_id and metadata_equal(existing.metadata, metadata) then
                    local can_add = max_stack - (existing.quantity or 1)
                    if can_add > 0 then
                        local add = math.min(can_add, remaining)
                        existing.quantity = (existing.quantity or 1) + add
                        local col, row = key:match("(%d+)_(%d+)")
                        m.set_item(source, tonumber(col), tonumber(row), group_id, existing)
                        remaining = remaining - add
                        if remaining <= 0 then return true, "item_added_success" end
                    end
                end
            end
        end
    end

    while remaining > 0 do
        local target_group, col, row

        if group then
            col, row = m.find_free_slot(source, group, w, h)
            target_group = group
        else
            target_group, col, row = resolve_target_group(source, w, h)
        end

        if not col then break end

        local add = remaining
        if stackable ~= false and type(stackable) == "number" then
            add = math.min(stackable, remaining)
        end

        m.set_item(source, col, row, target_group, {
            id = item_id,
            quantity = add,
            col = col,
            row = row,
            w = w,
            h = h,
            metadata = metadata
        })

        remaining = remaining - add
    end

    if remaining <= 0 then return true, "item_added_success" end
    if remaining < quantity then return true, "item_added_partial" end
    return false, "no_free_slot"
end

--- @section Metadata

function m.get_inventory_metadata(source)
    local inv = exports.rig:get_inventory(source)
    return inv and inv.metadata or {}
end

--- @section Sync

function m.sync_and_refresh(source)
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

return m