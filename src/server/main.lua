--- @file src/server/main.lua
--- @description Handles main server side stuff

--- @section Imports

local _items = require("configs.items")
local _actions = require("src.server.modules.actions")

--- @section Variables

-- @todo move to config
local starter_items = {
    { id = "water", quantity = 8, col = 1, row = 1 }
}

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