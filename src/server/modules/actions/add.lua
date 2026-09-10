--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions.add
--- @file src/server/modules/actions/add.lua
--- @description Add item actions.

--- @section Imports

local _items = require("src.shared.data.items")
local _inventories = require("configs.inventories")

local _utils = require("src.server.modules.utils")

--- @section Initialisation

local m = {}

--- @section Function

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
    local search_groups = group and { group } or _utils.get_player_group_priority(source)
    local added_total = 0

    if stackable ~= false then
        local inv = exports.rig:get_inventory(source)
        for _, group_id in ipairs(search_groups) do
            local items = inv and inv.items and inv.items[group_id] or {}
            for key, existing in pairs(items) do
                if existing.id == item_id and _utils.metadata_equal(existing.metadata, metadata) then
                    local can_add = max_stack - (existing.quantity or 1)
                    if can_add > 0 then
                        local add = math.min(can_add, remaining)
                        existing.quantity = (existing.quantity or 1) + add
                        local col, row = key:match("(%d+)_(%d+)")
                        _utils.set_item(source, tonumber(col), tonumber(row), group_id, existing)
                        remaining = remaining - add
                        added_total = added_total + add
                        if remaining <= 0 then
                            _utils.send_popup(source, item_id, def, added_total)
                            return true, "item_added_success"
                        end
                    end
                end
            end
        end
    end

    while remaining > 0 do
        local target_group, col, row

        if group then
            col, row = _utils.find_free_slot(source, group, w, h)
            target_group = group
        else
            for _, group_id in ipairs(search_groups) do
                col, row = _utils.find_free_slot(source, group_id, w, h)
                if col then
                    target_group = group_id
                    break
                end
            end
        end

        if not col then break end

        local add = remaining
        if stackable ~= false and type(stackable) == "number" then
            add = math.min(stackable, remaining)
        end

        _utils.set_item(source, col, row, target_group, {
            id = item_id,
            quantity = add,
            col = col,
            row = row,
            w = w,
            h = h,
            metadata = metadata
        })

        remaining = remaining - add
        added_total = added_total + add
    end

    if added_total > 0 then
        _utils.send_popup(source, item_id, def, added_total)
    end

    if remaining <= 0 then return true, "item_added_success" end
    if remaining < quantity then return true, "item_added_partial" end
    return false, "no_free_slot"
end

return m