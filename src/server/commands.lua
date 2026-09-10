--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @script server_commands
--- @file src/server/commands.lua
--- @description Admin command to give items to self or other players with mandatory amount.

--- @section Commands

exports.rig:register_command({
    ace = { "rig.dev", "rig.admin" },
    name = "rig:giveitem",
    help = "Give an item to yourself or another player.",
    params = {
        { name = "item", help = "Item ID" },
        { name = "amount", help = "Quantity" },
        { name = "id", help = "Player server ID (optional, defaults to yourself)" }
    },
    handler = function(source, args)
        local item_id = args[1]
        local quantity = tonumber(args[2])
        local target = tonumber(args[3]) or source

        if not item_id or not quantity then
            exports.rig:notify(source, {
                type = "error",
                header = "SYSTEM",
                message = "Usage: /rig:giveitem [item] [amount] [id (optional)]",
                duration = 4000
            })
            return
        end

        -- Fallback validation if target player exists
        local target_ped = GetPlayerPed(target)
        if not target_ped or target_ped == 0 then
            exports.rig:notify(source, {
                type = "error",
                header = "SYSTEM",
                message = "Target player not found.",
                duration = 4000
            })
            return
        end

        -- Execute the add_item action export
        local success, err = exports.rig_inventory:add_item(target, item_id, quantity)
        if success then
            exports.rig:notify(source, {
                type = "success",
                header = "SYSTEM",
                message = ("Successfully gave %d x %s to player %d."):format(quantity, item_id, target),
                duration = 4000
            })
            if target ~= source then
                exports.rig:notify(target, {
                    type = "success",
                    header = "SYSTEM",
                    message = ("You received %d x %s from an admin."):format(quantity, item_id),
                    duration = 4000
                })
            end
        else
            exports.rig:notify(source, {
                type = "error",
                header = "SYSTEM",
                message = ("Failed to give item: %s"):format(tostring(err)),
                duration = 4000
            })
        end
    end
})