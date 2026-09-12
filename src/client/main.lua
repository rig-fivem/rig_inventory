--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @file src/client/main.lua
--- @description Main client side handling

--- @section Imports

local _nui = require("src.client.modules.nui")
local _inv = require("src.client.nui.inventory")
local _item_builder = require("src.client.nui.items")
local _panels = require("src.client.nui.panels")
local _animations = require("src.client.modules.animations")
local _utils = require("src.client.modules.utils")

local Drops = require("src.client.registry.drops")
local Containers = require("src.client.registry.containers")

local _items = require("src.shared.data.items")

--- @section Globals

core.client_drops = Drops.new()
core.client_containers = Containers.new()

--- @section Events

RegisterNetEvent("rig_inventory:client:open_inventory", function(payload)
    if type(payload) ~= "table" then return end

    core.client_vars.inventory_open = true
    SetTimecycleModifier("hud_def_blur")

    if payload.secondary then
        core.client_vars.current_container = payload.secondary.id
        core.client_vars.current_inv_type = payload.secondary.type

        if payload.is_vehicle then
            core.client_vars.current_vehicle = payload.secondary.vehicle
            core.client_vars.current_vehicle_data = {
                plate = payload.secondary.plate,
                type = payload.secondary.type,
                config = payload.secondary.config
            }

            core.client_containers:add_vehicle(payload.secondary)
            _utils.set_vehicle_trunk_state(payload.secondary.vehicle, payload.secondary.type, true)
        else
            core.client_vars.current_vehicle = nil
            core.client_vars.current_vehicle_data = nil
            core.client_containers:add(payload.secondary)
        end
    else
        core.client_vars.current_container = nil
        core.client_vars.current_inv_type = nil
        core.client_vars.current_vehicle = nil
        core.client_vars.current_vehicle_data = nil
    end

    _inv.build(payload)
end)

RegisterNetEvent("rig_inventory:client:close_inventory", function()
    core.client_vars.inventory_open = false
    core.client_vars.current_container = nil
    core.client_vars.current_inv_type = nil
    core.client_vars.current_vehicle = nil
    core.client_vars.current_vehicle_data = nil

    ClearTimecycleModifier()
    TriggerEvent("rig_inventory:client:close_ui")
end)

RegisterNetEvent("rig_inventory:client:inventory_changed", function(player_data, container_data)
    if not core.client_vars.inventory_open then return end

    if player_data and player_data.items then
        for group_id, raw_items in pairs(player_data.items) do
            local built = _item_builder.build_for_grid(raw_items, group_id)
            _nui.update_grid(built, "left_" .. group_id)
        end

        local loadout = player_data.metadata and player_data.metadata.loadout or {}
        local hotbar = _panels.build_hotbar(player_data)

        _nui.update_slots({ loadout = _item_builder.build_loadout(loadout) }, "player_loadout")
        _nui.update_hotbar({ items = hotbar.items })
    end

    local client_drops = core.client_drops and core.client_drops.drops or {}
    local vicinity_items = _item_builder.build_vicinity(client_drops, 2.5)
    _nui.update_grid(vicinity_items, "vicinity")

    if container_data and container_data.id and container_data.items then
        local subtype = container_data.subtype or core.client_vars.current_inv_type or "storage"

        local raw = container_data.items[subtype] or container_data.items[container_data.id] or container_data.items
        if type(raw) ~= "table" then raw = {} end

        local built = _item_builder.build_for_grid(raw, subtype)

        local section_key = core.client_vars.current_vehicle_data
            and ("vehicle:%s:%s"):format(subtype, core.client_vars.current_vehicle_data.plate)
            or ("right_" .. subtype)

        _nui.update_grid(built, section_key)
    end
end)

RegisterNetEvent("rig_inventory:client:apply_inventory_clothing")
AddEventHandler("rig_inventory:client:apply_inventory_clothing", function(data)
    local ped = PlayerPedId()
    if data.action == "equip" then
        if data.clothing then
            local model = GetEntityModel(ped)
            local is_male = model == GetHashKey("mp_m_freemode_01")
            local clothing = data.clothing
            local drawable = is_male and clothing.male and clothing.male.drawable or clothing.drawable
            local texture = is_male and clothing.male and clothing.male.texture or clothing.texture
            SetPedComponentVariation(ped, clothing.component_id, drawable, texture, 0)
        end
        if data.prop then
            SetPedPropIndex(ped, data.prop.component_id, data.prop.drawable, data.prop.texture, true)
        end
    elseif data.action == "remove" then
        if data.clothing then
            SetPedComponentVariation(ped, data.clothing.component_id, 0, 0, 0)
        end
        if data.prop then
            ClearPedProp(ped, data.prop.component_id)
        end
    end
    TriggerEvent("rig_inventory:client:close_inventory")
end)

RegisterNetEvent("rig_inventory:client:use_item_animation")
AddEventHandler("rig_inventory:client:use_item_animation", function(data)
    if not data or not data.animation then
        log("error", "Animation missing")
        return
    end
    local ped = PlayerPedId()
    local anim = data.animation

    if anim.progress then
        local progress_type = anim.progress.type or "circle"
        local duration = anim.duration or 5000
        local message = anim.progress.message or "Using item..."

        if progress_type == "bar" then
            exports.rig:progress_bar({ message = message, duration = duration })
        else
            exports.rig:progress_circle({ message = message, duration = duration })
        end
    end

    _animations.play(ped, anim, function()
        TriggerServerEvent("rig_inventory:server:animation_finished", {
            item_id = data.item_id,
            col = data.col,
            row = data.row,
            group = data.group
        })
    end)
end)

RegisterNetEvent("rig_inventory:client:play_crafting_animation")
AddEventHandler("rig_inventory:client:play_crafting_animation", function(item_id)
    TriggerEvent("rig_inventory:client:close_inventory")
    
    if not item_id then
        log("error", "[play_crafting_animation] missing item id")
        return
    end

    if not _items[item_id] then
        log("error", "[play_crafting_animation] item id is not a registered item")
        return
    end

    local item = _items[item_id]
    local ped = PlayerPedId()

    local progress = item.actions.craft and item.actions.craft.progress or false
    local duration = item.actions.craft and item.actions.craft.duration or 5000

    if progress then
        local progress_type = progress.type or "circle"
        local message = progress.message or "Using item..."

        if progress_type == "bar" then
            exports.rig:progress_bar({ message = message, duration = duration })
        else
            exports.rig:progress_circle({ message = message, duration = duration })
        end
    end

    _animations.play(ped, {
        dict = "amb@prop_human_parking_meter@female@base",
        anim = "base_female",
        flags = 49,
        duration = duration,
    }, function()
        TriggerServerEvent("rig_inventory:server:craft_finished", item_id)
    end)
end)

--- @section Drop Events

RegisterNetEvent("rig_inventory:client:init_drops", function(data)
    core.client_drops:init(data)
end)

RegisterNetEvent("rig_inventory:client:add_drop", function(data)
    core.client_drops:add(data)
end)

RegisterNetEvent("rig_inventory:client:remove_drop", function(id)
    core.client_drops:remove(id)
end)

--- @section Container Events

RegisterNetEvent("rig_inventory:client:init_containers", function(data)
    core.client_containers:init(data)
end)

RegisterNetEvent("rig_inventory:client:add_container", function(data)
    core.client_containers:add(data)
end)

RegisterNetEvent("rig_inventory:client:remove_container", function(id)
    core.client_containers:remove(id)
end)

RegisterNetEvent("rig_inventory:client:add_vehicle_container", function(data)
    core.client_containers:add_vehicle(data)
end)

--- @section Keymapping

RegisterCommand("inv:open", function()
    if IsNuiFocused() or IsPauseMenuActive() then return end
    ExecuteCommand("_open_inventory")
end, false)

RegisterKeyMapping("inv:open", "Open Inventory", "keyboard", "TAB")

for i = 1, 8 do
    RegisterCommand('inv:slot_' .. i, function()
       TriggerServerEvent("rig_inventory:server:use_hotbar_slot", i)
    end, false)

    RegisterKeyMapping('inv:slot_' .. i, "Use slot ".. i, 'keyboard', i)
end

--- @section Threads

CreateThread(function()
    while not exports.rig:is_playing() do
        Wait(500)
    end

    Wait(500)

    TriggerServerEvent("rig_inventory:server:request_drops")
    TriggerServerEvent("rig_inventory:server:request_containers")

    while true do
        if exports.rig:is_playing() then
            local player_coords = GetEntityCoords(PlayerPedId())

            core.client_drops:stream(player_coords)
            core.client_containers:stream(player_coords)
        end
        Wait(500)
    end
end)

RegisterCommand("requestcontainers", function()
    TriggerServerEvent("rig_inventory:server:request_containers")
end)