--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @file src/server/main.lua
--- @description Handles main server side stuff

--- @section Imports

local _items = require("src.shared.data.items")
local _inventories = require("configs.inventories")
local _actions = require("src.server.modules.actions")
local _utils = require("src.server.modules.utils")
local _use_item = require("src.server.modules.actions.use")
local _craft = require("src.server.modules.actions.craft")

local Drops = require("src.server.registry.drops")
local Containers = require("src.server.registry.containers")
local UsableItems = require("src.server.registry.usable_items")

--- @section Variables

-- @todo move to config
local starter_items = {
    { id = "water", quantity = 8, col = 1, row = 1 },
    { id = "ammo_9mm", quantity = 50, col = 9, row = 1 },
    { id = "pistol_mag_extended", quantity = 1, col = 8, row = 1 },
    { id = "weapon_pistol", quantity = 1, col = 1, row = 2 },
    { id = "dufflebag", quantity = 1, col = 3, row = 2 }
}

--- @section Registries

core.drops = Drops.new()
core.containers = Containers.new()
core.usable_items = UsableItems.new()

--- @section Usable Items

local function handle_item_use(source, item_id, def, col, row, group)
    local use_config = def.actions.use

    if type(use_config) == "function" then
        return use_config(source, col, row, group)
    end

    if type(use_config) ~= "table" then return end

    if use_config.attachments then
        log("info", ("[handle_item_use] attachments use: item=%s col=%s row=%s group=%s"):format(item_id, col, row, group))
        return
    end

    if use_config.animation then
        log("info", ("[handle_item_use] animation use: item=%s col=%s row=%s group=%s"):format(item_id, col, row, group))
        return
    end
end

local function register_usable_items()
    local count = 0

    for id, def in pairs(_items) do
        if def.actions and def.actions.use then
            exports.rig:register_hook(id, function(source, col, row, group)
                handle_item_use(source, id, def, col, row, group)
            end)
            log("success", "Usable item registered: " .. id)
            count = count + 1
        end
    end

    log("success", "Registered Items: " .. count)
    return count
end

SetTimeout(500, function()
    register_usable_items()
end)

--- @section RIG Events

AddEventHandler("rig:server:player_loaded", function(source)
    local inv = exports.rig:get_inventory(source)

    if not inv or not inv.items or next(inv.items) == nil then
        local pockets_data = {}
        
        for _, entry in ipairs(starter_items) do
            local def = _items[entry.id]
            local metadata = {}

            if def and def.metadata then
                for k, v in pairs(def.metadata) do
                    metadata[k] = v
                end
            end

            local key = entry.col .. "_" .. entry.row
            pockets_data[key] = {
                col = entry.col,
                row = entry.row,
                id = entry.id,
                quantity = entry.quantity,
                metadata = next(metadata) ~= nil and metadata or nil
            }
        end

        exports.rig:add_inventory_group(source, "pockets", pockets_data)
    end

    local loadout = inv and inv.metadata and inv.metadata.loadout
    if loadout then
        SetTimeout(3000, function()
            for _, entry in pairs(loadout) do
                local def = _items[entry.id]
                local use_config = def and def.actions and def.actions.use
                if use_config and use_config.clothing then
                    TriggerClientEvent("rig_inventory:client:apply_inventory_clothing", source, {
                        action = "equip",
                        clothing = use_config.clothing,
                        prop = use_config.prop,
                        silent = true
                    })
                end
            end
        end)
    end
end)

--- @section Events

RegisterServerEvent("rig_inventory:server:move_item", function(data)
    local _src = source

    _actions.move_item(_src, data)
end)

RegisterServerEvent("rig_inventory:server:use_item", function(data)
    local _src = source

    _actions.use_item(_src, data)
end)

RegisterServerEvent("rig_inventory:server:close_inventory", function()
    local _src = source

    core.containers:unlock_all_for_player(_src)

    TriggerClientEvent("rig_inventory:client:close_inventory", _src)
end)

RegisterServerEvent("rig_inventory:server:request_drops", function()
    local _src = source
    TriggerClientEvent("rig_inventory:client:init_drops", _src, core.drops.drops)
end)

RegisterServerEvent("rig_inventory:server:request_containers", function()
    local _src = source
    local payload = {}

    local total = 0
    for _ in pairs(core.containers.containers) do total = total + 1 end

    for id, container in pairs(core.containers.containers) do
        local coords = container.metadata and container.metadata.coords

        if container.type ~= "vehicle" and coords then
            local def = _inventories[container.subtype]
            if def and def.model then
                payload[id] = {
                    id = id,
                    model = def.model,
                    coords = coords,
                    subtype = container.subtype,
                    keys = { { key = "E", label = "Open Container" } }
                }
            else
                log("error", ("[request_containers] skip %s - no model def for subtype '%s'"):format(id, tostring(container.subtype)))
            end
        end
    end

    log("info", ("[request_containers] sending %d container(s) to client"):format((function() local n=0 for _ in pairs(payload) do n=n+1 end return n end)()))
    TriggerClientEvent("rig_inventory:client:init_containers", _src, payload)
end)

RegisterServerEvent("rig_inventory:server:animation_finished", function(data)
    local _src = source
    _use_item.animation_finished(_src, data)
end)

RegisterServerEvent("rig_inventory:server:unequip_loadout_item", function(data)
    local _src = source
    _use_item.unequip_loadout_item(_src, data)
end)

RegisterServerEvent("rig_inventory:server:quick_craft", function(item_id)
    local _src = source
    _craft.request_craft(_src, item_id)
end)

RegisterServerEvent("rig_inventory:server:craft_finished", function(item_id)
    local _src = source
    _craft.finish_craft(_src, item_id)
end)

RegisterServerEvent("rig_inventory:server:use_hotbar_slot", function(slot)
    local _src = source
    if type(slot) ~= "number" then return end

    _actions.use_item(_src, {
        col = slot,
        row = 1,
        group = "hotbar"
    })
end)

--- @section Exports

exports("register_usable_item", function(item_id, handler)
    return core.usable_items:register(item_id, handler)
end)

exports("remove_usable_item", function(item_id)
    return core.usable_items:remove(item_id)
end)

--- @section Lifecycle

AddEventHandler("playerDropped", function()
    local _src = source
    core.containers:unlock_all_for_player(_src)
end)

AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() ~= resource then return end
    core.containers:save_all()
end)

--- @section Commands

RegisterCommand("_open_inventory", function(source)
    local user = exports.rig:get_user_data(source)
    if not user then
        log("error", "[rig_inventory] user is missing")
        return
    end

    local inventory_data = exports.rig:get_player_data(source, "inventory")
    if not inventory_data then
        log("error", ("[rig_inventory] Failed to fetch inventory data for source %d"):format(source))
        return
    end

    local payload = {
        player_data = {
            unique_id = user.unique_id,
            name = user.username,
            items = inventory_data.items or {},
            metadata = inventory_data.metadata or {}
        },
        secondary = nil,
        is_vehicle = false
    }

    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        local pcoords = GetEntityCoords(ped)

        local info = _utils.get_vehicle_info(nil, { source = source, coords = pcoords, radius = 4.0 })
        if info and info.plate then
            local inv_type = info.is_inside and "glovebox" or "trunk"
            local container = core.containers:get_or_create_vehicle(info.plate, inv_type, info)
            
            if container and _utils.try_lock_container(container.identifier, source) then
                local cfg = _utils.get_vehicle_config(info.model, info.class, inv_type)
                payload.secondary = {
                    id = container.identifier,
                    type = inv_type,
                    items = container:get_items(),
                    plate = info.plate,
                    vehicle = info.entity,
                    config = cfg,
                    is_vehicle = true
                }
                payload.is_vehicle = true
            end
        end

        if not payload.secondary then
            local container_id, container = _utils.get_nearest_container(pcoords, 2.5)
            if container_id and container and _utils.try_lock_container(container_id, source) then
                payload.secondary = {
                    id = container_id,
                    type = container.subtype or container.type,
                    items = container:get_items(),
                    metadata = container.metadata
                }
            end
        end
    end

    TriggerClientEvent("rig_inventory:client:open_inventory", source, payload)
end, false)

--- @section Bootstrap

local function load_persisted_containers()
    local rows = exports.oxmysql:query_async("SELECT identifier, owner, inventory_type, inventory_subtype, metadata FROM inventories WHERE inventory_type = 'container'", {})
    if not rows then return end

    local count = 0
    for _, row in ipairs(rows) do
        local metadata = row.metadata and json.decode(row.metadata) or {}

        local container = core.containers:get_or_create(row.identifier, {
            owner = row.owner,
            type = row.inventory_type,
            subtype = row.inventory_subtype,
            metadata = metadata
        })

        if container then
            count = count + 1
        else
            log("info", ("[bootstrap] FAILED to load %s"):format(row.identifier))
        end
    end

    log("success", ("[rig_inventory] Loaded %d persisted container(s) from DB"):format(count))
end

SetTimeout(500, load_persisted_containers)

--- @section Debug Commands

RegisterCommand("testcontainer", function(source, args)
    if source == 0 then return end

    local subtype = args[1] or "storage_crate"
    local def = _inventories[subtype]
    if not def or not def.is_container then
        return print(("[testcontainer] '%s' isn't a valid container type in configs.inventories"):format(subtype))
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading)

    local target = {
        x = coords.x + (-math.sin(rad) * 1.5),
        y = coords.y + (math.cos(rad) * 1.5),
        z = coords.z
    }

    local identifier = ("%s:%s"):format(subtype, os.time())

    local container = core.containers:get_or_create(identifier, {
        owner = GetPlayerIdentifierByType(source, "license") or tostring(source),
        type = "container",
        subtype = subtype,
        metadata = { coords = target }
    })

    if not container then
        return print(("[testcontainer] failed to create container %s"):format(identifier))
    end

    TriggerClientEvent("rig_inventory:client:add_container", -1, {
        id = identifier,
        model = def.model,
        coords = target,
        keys = {
            { key = "E", label = "Open Container" }
        }
    })

    print(("[testcontainer] spawned '%s' (%s) at %s"):format(identifier, subtype, json.encode(target)))
end, false)