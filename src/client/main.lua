--- @file src/client/main.lua
--- @description Main client side handling

--- @section Imports

local _nui = require("src.client.modules.nui")
local _inv = require("src.client.nui.inventory")

--- @section Globals

inventory_open = false
client_drops = {} -- @todo populated once a drops/world-item system exists

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
end)

--- @section Commands

RegisterCommand("inv:open", function()
    if IsNuiFocused() or IsPauseMenuActive() then return end
    ExecuteCommand("_open_inventory")
end, false)

RegisterKeyMapping("inv:open", "Open Inventory", "keyboard", "TAB")