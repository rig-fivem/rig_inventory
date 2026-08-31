--- @section RIG Events

--- @section RIG Events

AddEventHandler("rig:server:player_loaded", function(source)
    local inv = exports.rig:get_inventory(source)

    print("player loaded after get source: ", source)
    if not inv or not inv.items or next(inv.items) == nil then
        print("player loaded no items adding pockets")
        exports.rig:add_inventory_group(source, "pockets", {})
    end
end)

RegisterCommand("_open_inventory", function(source)
    local username = exports.rig:get_username(source)
    if not username then
        log("error", "[rig_inventory] username missing")
        return
    end

    local player_data = exports.rig:get_player_data(source, "inventory")
    if not player_data then
        log("error", ("[rig_inventory] Failed to fetch inventory data for source %d"):format(source))
        return
    end

    player_data.username = username

    print("opening inventory server?")

    TriggerClientEvent("rig_inventory:client:open_inventory", source, player_data)
end)