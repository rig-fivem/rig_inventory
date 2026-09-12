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

local _items = require("src.shared.data.items")
local _inventories = require("configs.inventories")
local _vehicles = require("configs.vehicles")

--- @section Initialisation

local m = {}

--- @section General Utilities

function m.metadata_equal(a, b)
    if a == b then return true end
    if not a or not b then return false end
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

function m.resolve_target_group(source, w, h)
    for _, group_id in ipairs(m.get_player_group_priority(source)) do
        local col, row = m.find_free_slot(source, group_id, w, h)
        if col then return group_id, col, row end
    end
    return nil
end

function m.get_player_group_priority(source)
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

--- @section Actions

function m.get_item(source, col, row, group)
    if group == "hotbar" then
        local inv_meta = m.get_inventory_metadata(source)
        return inv_meta and inv_meta.hotbar and inv_meta.hotbar[tostring(col)]
    end

    local inv = exports.rig:get_inventory(source)
    if not inv or not inv.items or not inv.items[group] then return nil end
    return inv.items[group][col .. "_" .. row]
end

function m.set_item(source, col, row, group, item)
    if group == "hotbar" then
        local inv_meta = m.get_inventory_metadata(source) or {}
        inv_meta.hotbar = inv_meta.hotbar or {}
        inv_meta.hotbar[tostring(col)] = item
        
        exports.rig:set_inventory_metadata(source, inv_meta, false)
        return true
    end

    return exports.rig:set_inventory_slots(source, {
        { group_id = group, key = col .. "_" .. row, item = item }
    })
end

function m.remove_item(source, col, row, group, amount, popup)
    local item = m.get_item(source, col, row, group)
    if not item then return false end

    amount = amount or 1
    local qty = item.quantity or 1
    local removed_qty = (qty <= amount) and qty or amount

    local ok = false

    if qty <= amount then
        ok = m.set_item(source, col, row, group, nil)
    else
        item.quantity = qty - amount
        ok = m.set_item(source, col, row, group, item)
    end

    if ok and popup then
        m.send_popup(source, item.id, removed_qty, "removed")
    end

    return ok
end

function m.remove_item_by_id(source, item_id, amount, metadata, popup)
    amount = amount or 1

    local inv = exports.rig:get_inventory(source)
    if not inv or not inv.items then return false, "no_inventory" end

    local remaining = amount
    local removed_total = 0

    for group_id, group_items in pairs(inv.items) do
        for key, item in pairs(group_items) do
            if remaining <= 0 then break end

            if item.id == item_id and (not metadata or m.metadata_equal(item.metadata, metadata)) then
                local col, row = key:match("^(%d+)_(%d+)$")
                col, row = tonumber(col), tonumber(row)

                if col and row then
                    local qty = item.quantity or 1
                    local take = math.min(qty, remaining)

                    if qty <= take then
                        m.set_item(source, col, row, group_id, nil)
                    else
                        item.quantity = qty - take
                        m.set_item(source, col, row, group_id, item)
                    end

                    remaining = remaining - take
                    removed_total = removed_total + take
                end
            end
        end
    end

    if removed_total > 0 and popup then
        m.send_popup(source, item_id, removed_total, "removed")
    end

    if removed_total > 0 then
        return remaining <= 0, removed_total
    end

    return false, 0
end

function m.place_item(source, group, col, row, item_data)
    if not group or not col or not row or not item_data or not item_data.id then
        return false, "invalid_args"
    end

    local def = _items[item_data.id]
    if not def then return false, "invalid_item_id" end

    local w = item_data.w or def.w or 1
    local h = item_data.h or def.h or 1
    local stackable = def.stackable
    if stackable == nil then stackable = true end
    local max_stack = type(stackable) == "number" and stackable or math.huge

    local existing = m.get_item(source, col, row, group)

    if not existing then
        local ok = m.set_item(source, col, row, group, {
            id = item_data.id, quantity = item_data.quantity or 1, metadata = item_data.metadata,
            col = col, row = row, w = w, h = h
        })
        return ok, "item_placed_success", nil
    end

    if stackable ~= false and existing.id == item_data.id and m.metadata_equal(existing.metadata, item_data.metadata) then
        local can_add = max_stack - (existing.quantity or 1)
        if can_add >= (item_data.quantity or 1) then
            existing.quantity = (existing.quantity or 1) + (item_data.quantity or 1)
            local ok = m.set_item(source, col, row, group, existing)
            return ok, "item_stacked_success", nil
        end
    end

    local displaced = existing
    local ok = m.set_item(source, col, row, group, {
        id = item_data.id, quantity = item_data.quantity or 1, metadata = item_data.metadata,
        col = col, row = row, w = w, h = h
    })
    return ok, "item_swapped_success", displaced
end

function m.add_item(source, item_id, quantity, group, metadata, popup)
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
    local search_groups = group and { group } or m.get_player_group_priority(source)
    local added_total = 0

    if stackable ~= false then
        local inv = exports.rig:get_inventory(source)
        for _, group_id in ipairs(search_groups) do
            local items = inv and inv.items and inv.items[group_id] or {}
            for key, existing in pairs(items) do
                if existing.id == item_id and m.metadata_equal(existing.metadata, metadata) then
                    local can_add = max_stack - (existing.quantity or 1)
                    if can_add > 0 then
                        local add = math.min(can_add, remaining)
                        existing.quantity = (existing.quantity or 1) + add
                        local col, row = key:match("(%d+)_(%d+)")
                        m.set_item(source, tonumber(col), tonumber(row), group_id, existing)
                        remaining = remaining - add
                        added_total = added_total + add
                        if remaining <= 0 and popup then
                            m.send_popup(source, item_id, added_total)
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
            col, row = m.find_free_slot(source, group, w, h)
            target_group = group
        else
            for _, group_id in ipairs(search_groups) do
                col, row = m.find_free_slot(source, group_id, w, h)
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
        added_total = added_total + add
    end

    if added_total > 0 and popup then
        m.send_popup(source, item_id, added_total)
    end

    if remaining <= 0 then return true, "item_added_success" end
    if remaining < quantity then return true, "item_added_partial" end
    return false, "no_free_slot"
end

--- @section Inventory Data

function m.get_inventory_metadata(source)
    local inv = exports.rig:get_inventory(source)
    return inv and inv.metadata or {}
end

function m.sync_and_refresh(source, container)
    local synced = exports.rig:sync_player_data(source)
    if not synced then print("player data sync failed") return end

    local inv_data = exports.rig:get_inventory(source)
    local container_data = nil

    if container then
        container_data = {
            id = container.identifier,
            subtype = container.subtype or container.type,
            items = container:get_items()
        }
    end

    if inv_data then
        TriggerClientEvent("rig_inventory:client:inventory_changed", source, inv_data, container_data)
        return
    end

    TriggerClientEvent("rig_inventory:client:inventory_changed", source, nil, container_data)
end

--- @section Vehicles

function m.get_vehicle_config(model_name, class_name, inv_type)
    local config = _vehicles[model_name] or (_vehicles.vehicle_defaults and _vehicles.vehicle_defaults[class_name]) or (_vehicles.vehicle_defaults and _vehicles.vehicle_defaults.sedan)
    return config and config[inv_type] or { columns = 10, rows = 4, max_weight = 100000 }
end

function m.get_nearby_vehicles(coords, radius, models)
        local pool = GetGamePool("CVehicle")
        local results = {}
        local count = 0
        local r2 = radius * radius

        local model_filter = nil
        if models then
            model_filter = {}
            for i = 1, #models do
                model_filter[models[i]] = true
            end
        end

        for i = 1, #pool do
            local veh = pool[i]
            local vcoords = GetEntityCoords(veh)
            local dx = vcoords.x - coords.x
            local dy = vcoords.y - coords.y
            local dz = vcoords.z - coords.z

            if (dx*dx + dy*dy + dz*dz) <= r2 then
                if not model_filter or model_filter[GetEntityModel(veh)] then
                    count = count + 1
                    results[count] = veh
                end
            end
        end

        return results
    end

function m.get_vehicle_plate(vehicle)
    if not vehicle or vehicle == 0 then return "" end
    local plate = GetVehicleNumberPlateText(vehicle)
    return plate:gsub("^%s*(.-)%s*$", "%1")
end

function m.get_vehicle_plate_index(vehicle)
    if not vehicle or vehicle == 0 then return 0 end
    return GetVehicleNumberPlateTextIndex(vehicle)
end

function m.get_vehicle_info(vehicle, options)
    options = options or {}

    if not vehicle or vehicle == 0 then
        local coords = options.coords or GetEntityCoords(GetPlayerPed(options.source))
        local radius = options.radius or 5.0
        local models = options.models
        local vehicles = m.get_nearby_vehicles(coords, radius, models)
        vehicle = vehicles[1]
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    local source_ped = options.source and GetPlayerPed(options.source)
    local is_inside = false
    if source_ped and source_ped ~= 0 then
        is_inside = GetPedInVehicleSeat(vehicle, -1) == source_ped or
                    GetPedInVehicleSeat(vehicle, 0) == source_ped or
                    GetPedInVehicleSeat(vehicle, 1) == source_ped or
                    GetPedInVehicleSeat(vehicle, 2) == source_ped or
                    GetPedInVehicleSeat(vehicle, 3) == source_ped
    end

    return {
        entity = vehicle,
        model = GetEntityModel(vehicle),
        coords = GetEntityCoords(vehicle),
        heading = GetEntityHeading(vehicle),
        plate = m.get_vehicle_plate(vehicle),
        plate_index = m.get_vehicle_plate_index(vehicle),
        is_inside = is_inside
    }
end

--- @section Containers

function m.get_nearest_container(pcoords, max_dist)
    local closest_dist = max_dist
    local closest_id = nil
    local closest_container = nil

    for id, container in pairs(core.containers.containers) do
        if container.type ~= "vehicle" and container.metadata and container.metadata.coords then
            local mc = container.metadata.coords
            local dist = #(pcoords - vector3(mc.x, mc.y, mc.z))
            if dist < closest_dist then
                closest_dist = dist
                closest_id = id
                closest_container = container
            end
        end
    end

    return closest_id, closest_container
end

function m.try_lock_container(container_id, source)
    local is_locked, locked_by = core.containers:is_locked(container_id)
    if is_locked and locked_by ~= source then
        exports.rig:notify(source, { type = "error", header = "Inventory", message = "Container is already in use", duration = 3000 })
        return false
    end
    if not is_locked then
        core.containers:lock(container_id, source)
    end
    return true
end

--- @section Inventory Popup

function m.send_popup(source, item_id, quantity, action)
    local item = _items[item_id]
    if not item then return end

    TriggerClientEvent("rig_inventory:client:inventory_popup", source, {
        item_id = item_id,
        image = core.settings.general.image_path .. item.image,
        quantity = quantity,
        action = action or "added",
        rarity = item.metadata and item.metadata.rarity or "common"
    })
end

function m.get_item_count(source, item_id, metadata)
    local inv = exports.rig:get_inventory(source)
    if not inv or not inv.items then return 0 end

    local total = 0
    for _, group_items in pairs(inv.items) do
        for _, item in pairs(group_items) do
            if item.id == item_id and (not metadata or m.metadata_equal(item.metadata, metadata)) then
                total = total + (item.quantity or 1)
            end
        end
    end

    return total
end

function m.has_item(source, item_id, amount, metadata)
    amount = amount or 1
    return m.get_item_count(source, item_id, metadata) >= amount
end

--- @section Hotbar

function m.assign_to_hotbar(source, from_col, from_row, from_group, to_slot)
    local item = m.get_item(source, from_col, from_row, from_group)
    if not item then return log("warn", "[hotbar] source item missing") end

    local inv_meta = m.get_inventory_metadata(source) or {}
    inv_meta.hotbar = inv_meta.hotbar or {}

    local existing = inv_meta.hotbar[tostring(to_slot)]

    local removed = m.remove_item(source, from_col, from_row, from_group, item.quantity or 1)
    if not removed then return log("error", "[hotbar] failed to remove source item") end

    if existing then
        m.place_item(source, from_group, from_col, from_row, {
            id = existing.id, quantity = existing.quantity, metadata = existing.metadata
        })
    end

    inv_meta.hotbar[tostring(to_slot)] = {
        id = item.id,
        quantity = item.quantity or 1,
        metadata = item.metadata
    }

    exports.rig:set_inventory_metadata(source, inv_meta, false)
    m.sync_and_refresh(source)
end

function m.move_from_hotbar(source, from_slot, to_col, to_row, to_group)
    local inv_meta = m.get_inventory_metadata(source) or {}
    inv_meta.hotbar = inv_meta.hotbar or {}

    local entry = inv_meta.hotbar[tostring(from_slot)]
    if not entry then return log("warn", "[hotbar] slot empty: " .. tostring(from_slot)) end

    local placed, msg, displaced = m.place_item(source, to_group, to_col, to_row, {
        id = entry.id, quantity = entry.quantity, metadata = entry.metadata
    })

    if not placed then
        return log("error", "[hotbar] failed to place item: " .. tostring(msg))
    end

    inv_meta.hotbar[tostring(from_slot)] = displaced and {
        id = displaced.id, quantity = displaced.quantity, metadata = displaced.metadata
    } or nil

    exports.rig:set_inventory_metadata(source, inv_meta, false)
    m.sync_and_refresh(source)
end

function m.swap_hotbar_slots(source, from_slot, to_slot)
    local inv_meta = m.get_inventory_metadata(source) or {}
    inv_meta.hotbar = inv_meta.hotbar or {}

    inv_meta.hotbar[tostring(from_slot)], inv_meta.hotbar[tostring(to_slot)] =
        inv_meta.hotbar[tostring(to_slot)], inv_meta.hotbar[tostring(from_slot)]

    exports.rig:set_inventory_metadata(source, inv_meta, false)
    m.sync_and_refresh(source)
end

return m