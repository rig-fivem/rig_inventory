--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @class UsableItems
--- @file src/server/registry/usable_items.lua
--- @description Handles usable items registered through external resources.

--- @section Initialisation

local UsableItems = {}
UsableItems.__index = UsableItems

--- @section Factory

function UsableItems.new()
    return setmetatable({
        items = {}
    }, UsableItems)
end

--- @section Methods

function UsableItems:register(item_id, cb)
    if type(item_id) ~= "string" or item_id == "" then
        return false, "invalid_item_id"
    end

    local is_valid = type(cb) == "function" or (type(cb) == "table" and (cb.__cfx_functionReference or cb._cfgFunction))
    
    if not is_valid then
        return false, "invalid_handler"
    end

    if self.items[item_id] then
        log("warn", ("[usable_items] overwriting existing handler for '%s'"):format(item_id))
    end

    self.items[item_id] = cb
    log("success", ("[usable_items] registered handler for '%s'"):format(item_id))
    return true
end

function UsableItems:remove(item_id)
    if not self.items[item_id] then return false end
    self.items[item_id] = nil
    return true
end

function UsableItems:get(item_id)
    return self.items[item_id]
end

return UsableItems