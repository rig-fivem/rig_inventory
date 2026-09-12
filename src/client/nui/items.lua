--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module items
--- @file src/client/nui/items.lua
--- @description Transforms raw item tables into NUI item schemas.

--- @section Imports

local _items = require("src.shared.data.items")
local _inventories = require("configs.inventories")
local _metadata = require("configs.metadata")

local _animations = require("src.client.modules.animations")

--- @section Initialisation

local m = {}

--- @section Functions

function m.resolve_meta_value(meta_def, meta_value)
    if not meta_def.display then return nil end
    if type(meta_value) == "table" and not meta_def.values then return nil end

    if meta_def.values then
        if type(meta_value) == "table" then
            local labels = {}
            for _, v in ipairs(meta_value) do
                local mapped = meta_def.values[tostring(v)]
                labels[#labels + 1] = mapped and mapped.label or tostring(v)
            end
            return #labels > 0 and table.concat(labels, ", ") or nil
        end
        local mapped = meta_def.values[tostring(meta_value)]
        return mapped and mapped.label or tostring(meta_value)
    end

    return tostring(meta_value) .. (meta_def.suffix or "")
end

function m.build_actions(def, col, row, entry, group)
    if not def or not def.actions then return nil end
    local group_def = _inventories[group]
    if not group_def or not group_def.is_player then return nil end

    local quantity = tonumber(entry and entry.quantity) or 1
    local actions = {}

    if def.actions.use then
        actions[#actions + 1] = {
            id = "use",
            key = "G",
            label = "Use",
            should_close = true,
            on_action = function(data)
                TriggerServerEvent("rig_inventory:server:use_item", { col = data.dataset.col, row = data.dataset.row, group = data.dataset.group_id })
                TriggerServerEvent("rig_inventory:server:close_inventory")
            end
        }
    end

    local stackable = def.stackable
    if stackable == nil then stackable = true end

    if stackable ~= false and quantity > 1 then
        actions[#actions + 1] = {
            id = "split",
            key = "S",
            label = "Split Stack",
            modal = {
                title = "Split Stack",
                options = {
                    {
                        id = "quantity",
                        label = "Quantity",
                        type = "number",
                        default = 1,
                        min = 1,
                        max = quantity - 1,
                        dataset = { col = col, row = row, group_id = group }
                    }
                },
                buttons = {
                    {
                        label = "Confirm",
                        on_action = function(data)
                            local amt = tonumber(data.dataset.quantity)
                            local c = tonumber(data.dataset.col)
                            local r = tonumber(data.dataset.row)
                            local group_id = data.dataset.group_id
                            if amt and c and r and group_id then
                                TriggerServerEvent("rig:sv:split_item", { col = c, row = r, group = group_id, quantity = amt })
                            end
                        end
                    },
                    { label = "Cancel", action = "close_modal" }
                }
            }
        }
    end
    return (#actions > 0) and actions or nil
end

function m.build_for_grid(raw_items, group_id)
    local formatted_items = {}

    for _, entry in pairs(raw_items or {}) do
        local def = _items[entry.id]
        if def then
            local values = {}
            local progress = nil
            local metadata = type(entry.metadata) == "table" and entry.metadata or {}

            for meta_key, meta_value in pairs(metadata) do
                local meta_def = _metadata[meta_key]
                if meta_def then
                    if meta_key == "durability" then progress = { value = meta_value } end
                    local display = m.resolve_meta_value(meta_def, meta_value)
                    if display then values[#values + 1] = { key = meta_def.label, value = display } end
                end
            end

            local description = type(def.description) == "string" and { def.description } or def.description

            formatted_items[#formatted_items + 1] = {
                id = entry.id,
                image = core.settings.general.image_path .. (def.image or "default.png"),
                label = def.label,
                col = entry.col,
                row = entry.row,
                w = entry.w or def.w or 1,
                h = entry.h or def.h or 1,
                quantity = entry.quantity or 1,
                category = def.category,
                progress = progress,
                dataset = { col = entry.col, row = entry.row, group_id = group_id },
                on_hover = {
                    title = def.label or entry.id,
                    description = description or {},
                    values = (#values > 0) and values or nil,
                    rarity = (type(entry.metadata) == "table" and entry.metadata.rarity) or (def.metadata and def.metadata.rarity) or "common",
                    actions = m.build_actions(def, entry.col, entry.row, entry, group_id)
                }
            }
        end
    end

    return formatted_items
end

function m.build_vicinity(drops, radius)
    local formatted_items = {}
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local col, row = 1, 1

    for _, drop in pairs(drops or {}) do
        local dcoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        if #(pcoords - dcoords) <= radius then
            local def = _items[drop.item_id]
            local values = {}

            for meta_key, meta_value in pairs(drop.metadata or {}) do
                local meta_def = _metadata[meta_key]
                if meta_def then
                    local display = m.resolve_meta_value(meta_def, meta_value)
                    if display then values[#values + 1] = { key = meta_def.label, value = display } end
                end
            end

            local description = type(drop.description) == "string" and { drop.description } or drop.description
            local w, h = drop.w or 1, drop.h or 1

            formatted_items[#formatted_items + 1] = {
                id = drop.item_id,
                image = core.settings.general.image_path .. drop.image,
                label = drop.label or drop.item_id,
                col = col,
                row = row,
                w = w,
                h = h,
                quantity = drop.quantity,
                category = drop.category,
                dataset = { drop_id = drop.id },
                on_hover = {
                    title = drop.label or drop.item_id,
                    description = description or {},
                    values = (#values > 0) and values or nil,
                    rarity = (drop.metadata and drop.metadata.rarity) or (def and def.metadata and def.metadata.rarity) or "common"
                }
            }
            col = col + w
            if col > 10 then col = 1 row = row + 1 end
        end
    end

    return formatted_items
end

function m.build_loadout(loadout)
    local loadout_items = {}
    
    for slot_id, entry in pairs(loadout or {}) do
        local def = _items[entry.id]
        loadout_items[slot_id] = {
            id = entry.id,
            image = core.settings.general.image_path .. (entry.image or (def and def.image) or "default.png"),
            label = entry.label or (def and def.label) or entry.id,
            category = entry.category or (def and def.category),
            dataset = { slot_id = slot_id, serial = entry.serial },
            on_hover = {
                title = entry.label or (def and def.label) or entry.id,
                rarity = (entry.metadata and entry.metadata.rarity) or "common",
                actions = {
                    {
                        id = "unequip",
                        key = "G",
                        label = "Unequip",
                        on_action = function(data)
                            TriggerEvent("rig_inventory:client:close_inventory")
                            _animations.play(PlayerPedId(), {
                                dict = "clothingshirt",
                                anim = "try_shirt_positive_d",
                                flags = 49,
                                duration = 2000,
                                freeze = false,
                                continuous = false,
                            }, function()
                                TriggerServerEvent("rig_inventory:server:unequip_loadout_item", { slot_id = data.dataset.slot_id, serial = data.dataset.serial })
                            end)
                        end
                    }
                }
            }
        }
    end
    return loadout_items
end

return m