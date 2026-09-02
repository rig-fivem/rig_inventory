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

local _items = require("configs.items")
local _actions = require("src.server.modules.actions")

local Drops = require("src.server.registry.drops")

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
end)

--- @section Events

RegisterServerEvent("rig_inventory:server:move_item", function(data)
    local _src = source

    print("move_item source: ", source)
    print("move_item data: ", json.encode(data))

    _actions.move_item(_src, data)
end)

RegisterServerEvent("rig_inventory:server:use_item", function(data)
    local _src = source

    print("use_item source: ", source)
    print("use_item data: ", json.encode(data))

    _actions.use_item(_src, data)
end)

--- @section Commands

RegisterCommand("_open_inventory", function(source)
    local user = exports.rig:get_user_data(source)
    if not user then
        log("error", "[rig_inventory] user is missing")
        return
    end

    local player_data = exports.rig:get_player_data(source, "inventory")
    if not player_data then
        log("error", ("[rig_inventory] Failed to fetch inventory data for source %d"):format(source))
        return
    end

    player_data.username = user.username
    player_data.unique_id = user.unique_id

    TriggerClientEvent("rig_inventory:client:open_inventory", source, player_data)
end)