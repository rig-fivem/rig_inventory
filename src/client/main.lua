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

local Drops = require("src.client.registry.drops")

--- @section Globals

inventory_open = false
core.client_drops = Drops.new()

--- @section Events

RegisterNetEvent("rig_inventory:client:open_inventory", function(player_data)
    if type(player_data) ~= "table" then return end
    inventory_open = true
    SetTimecycleModifier("hud_def_blur")
    _inv.build(player_data)
end)

RegisterNetEvent("rig_inventory:client:close_inventory", function()
    inventory_open = false
    ClearTimecycleModifier()
    TriggerEvent("rig_inventory:client:close_ui")
end)

RegisterNetEvent("rig_inventory:client:inventory_changed", function(player_data)
    if not inventory_open then print("inventory isnt open") return end
    if not player_data or not player_data.items then print("player items missing") return end

    for group_id, raw_items in pairs(player_data.items) do
        local built = _inv.build_items_for_grid(raw_items, item_defs, group_id)
        _nui.update_grid(built, "left_" .. group_id)
    end

    local client_drops = core.client_drops and core.client_drops.drops or {}
    local vicinity_items = _inv.build_vicinity_items(client_drops, 2.5)
    _nui.update_grid(vicinity_items, "vicinity")
end)

RegisterNetEvent("rig_inventory:client:init_drops", function(data)
    core.client_drops:init(data)
end)

RegisterNetEvent("rig_inventory:client:add_drop", function(data)
    print("adding client drop?")
    core.client_drops:add(data)
end)

RegisterNetEvent("rig_inventory:client:remove_drop", function(id)
    core.client_drops:remove(id)
end)

--- @section Commands

RegisterCommand("inv:open", function()
    if IsNuiFocused() or IsPauseMenuActive() then return end
    ExecuteCommand("_open_inventory")
end, false)

RegisterKeyMapping("inv:open", "Open Inventory", "keyboard", "TAB")

--- @section Threads

CreateThread(function()
    TriggerServerEvent("rig_inventory:server:request_drops")

    while true do
        local player_coords = GetEntityCoords(PlayerPedId())
        core.client_drops:stream(player_coords)
        Wait(500)
    end
end)