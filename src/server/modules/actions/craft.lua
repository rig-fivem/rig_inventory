--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions.craft
--- @file src/server/modules/actions/craft.lua
--- @description Handles functions for quick crafting in inventory

--- @section Imports

local _items = require("src.shared.data.items")
local _utils = require("src.server.modules.utils")

--- @section Initialisation

local m = {}

--- @section Helpers

local function has_ingredients(source, ingredients)
    for _, ingredient in ipairs(ingredients) do
        if not _utils.has_item(source, ingredient.id, ingredient.amount) then
            return false, ingredient
        end
    end
    return true
end

local function notify_missing(source, ingredient)
    local def = ingredient and _items[ingredient.id]
    exports.rig:notify(source, {
        type = "error", header = "Crafting",
        message = ("Missing %s"):format((def and def.label) or (ingredient and ingredient.id) or "ingredients"),
        duration = 4000
    })
end

--- @section Functions

function m.request_craft(source, item_id)
    local def = _items[item_id]
    if not def then return log("error", "[request_craft] no item def: " .. tostring(item_id)) end

    local craft = def.actions and def.actions.craft
    if not craft then return log("error", "[request_craft] item not craftable: " .. item_id) end

    local ok, missing = has_ingredients(source, craft.ingredients or {})
    if not ok then return notify_missing(source, missing) end

    TriggerClientEvent("rig_inventory:client:play_animation", source, item_id)
end

function m.finish_craft(source, item_id)
    local def = _items[item_id]
    if not def then return log("error", "[finish_craft] no item def: " .. tostring(item_id)) end

    local craft = def.actions and def.actions.craft
    if not craft then return log("error", "[finish_craft] item not craftable: " .. item_id) end

    local ok, missing = has_ingredients(source, craft.ingredients or {})
    if not ok then return notify_missing(source, missing) end

    for _, ingredient in ipairs(craft.ingredients or {}) do
        _utils.remove_item(source, ingredient.id, ingredient.amount)
    end

    _utils.add_item(source, item_id, craft.amount or 1, nil, nil, true)
    _utils.sync_and_refresh(source)

    exports.rig:notify(source, {
        type = "success", header = "Crafting",
        message = ("Crafted %s"):format(def.label),
        duration = 4000
    })
end

return m