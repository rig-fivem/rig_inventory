--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module panels
--- @file src/client/nui/inventory/m.lua
--- @description Builds individual panel views (left, center, right, hotbar).

--- @section Imports

local _items = require("src.shared.data.items")
local _inventories = require("configs.inventories")
local _item_builder = require("src.client.nui.items")

--- @section Initalisation

local m = {}

--- @section Helpers

local function calculate_group_weight(raw_items)
    local total = 0
    for _, entry in pairs(raw_items or {}) do
        local def = _items[entry.id]
        total = total + ((def and def.weight or 0) * (entry.quantity or 1))
    end
    return total
end

function m.build_player_groups(player_data)
    local groups = {}
    for group_id, raw_items in pairs(player_data.items or {}) do
        local def = _inventories[group_id]
        if def and def.is_player then
            groups[#groups + 1] = {
                id = group_id,
                title = def.label,
                span = def.icon and ('<i class="%s"></i>'):format(def.icon) or nil,
                layout = { columns = def.columns or 10, rows = def.rows or 4, cell_size = "3vw" },
                collapsible = def.collapsible or false,
                collapsed = def.collapsed or false,
                items = _item_builder.build_for_grid(raw_items, group_id)
            }
        end
    end
    return groups
end

function m.build_center(player_data)
    local loadout = player_data and player_data.metadata and player_data.metadata.loadout or {}
    local loadout_items = _item_builder.build_loadout(loadout)
    return {
        type = "slots",
        title = { text = "Loadout" },
        layout = { scroll_y = "none", scroll_x = "none" },
        allow_cross_group_swap = true,
        groups = {
            {
                id = "loadout",
                layout_type = "positioned",
                collapsible = false,
                slots = {
                    { id = "helmet", label = "Helmet", position = { top = "0%", left = "0%" }, size = "72px" },
                    { id = "mask", label = "Mask", position = { top = "0%", left = "30%" }, size = "72px" },
                    { id = "backpack", label = "Bag", position = { top = "22%", left = "0%" }, size = "72px" },
                    { id = "primary", label = "Sling 1", position = { top = "22%", left = "30%" }, size = "72px" },
                    { id = "vest", label = "Vest", position = { top = "44%", left = "0%" }, size = "72px" },
                    { id = "secondary", label = "Sling 2", position = { top = "44%", left = "30%" }, size = "72px" },
                    { id = "shirt", label = "Shirt", position = { top = "66%", left = "0%" }, size = "72px" },
                    { id = "melee", label = "Melee", position = { top = "66%", left = "30%" }, size = "72px" },
                    { id = "pants", label = "Pants", position = { top = "85%", left = "0%" }, size = "72px" },
                    { id = "shoes", label = "Shoes", position = { top = "85%", left = "30%" }, size = "72px" }
                },
                items = loadout_items
            }
        }
    }
end

function m.build_vehicle(plate, inv_type, config)
    if not plate or not config then return nil end
    local vehicle_group_id = ("vehicle:%s:%s"):format(inv_type, plate)
    local container = core.client_containers:get(vehicle_group_id)

    local grid_items = {}
    if container and container.items and container.items[vehicle_group_id] then
        grid_items = _item_builder.build_for_grid(container.items[vehicle_group_id], vehicle_group_id)
    end

    return {
        type = "grid",
        section_key = vehicle_group_id,
        title = {
            text = inv_type == "glovebox" and "Glovebox" or "Trunk",
            span = ('<i class="fa-solid fa-car"></i> %s'):format(plate)
        },
        layout = { scroll_x = "none", scroll_y = "scroll", columns = config.columns or 10, rows = config.rows or 4, cell_size = "3vw" },
        items = grid_items
    }
end

function m.build_container(container_id)
    local container = core.client_containers:get(container_id)
    if not container then return nil end

    local subtype = container.subtype or container.type or "storage"
    local config = _inventories[subtype] or {}
    local raw_items = (container.items and container.items[subtype]) or {}
    local grid_items = _item_builder.build_for_grid(raw_items, subtype)
    local current_weight = calculate_group_weight(raw_items)

    return {
        type = "grid",
        section_key = container_id,
        title = {
            text = config.label or subtype:gsub("^%l", string.upper),
            span = ('<i class="fa-solid fa-weight-hanging"></i> %d / %d g'):format(current_weight, config.max_weight or 0)
        },
        layout = { scroll_x = "none", scroll_y = "scroll" },
        groups = {
            {
                id = subtype,
                layout = { columns = config.columns or 10, rows = config.rows or 6, cell_size = "3vw" },
                collapsible = false,
                items = grid_items
            }
        }
    }
end

function m.build_right()
    if core.client_vars and core.client_vars.current_vehicle_data then
        local d = core.client_vars.current_vehicle_data
        return m.build_vehicle(d.plate, d.type, d.config)
    end

    if core.client_vars and core.client_vars.current_container then
        return m.build_container(core.client_vars.current_container)
    end

    local client_drops = core.client_drops and core.client_drops.drops or {}
    local vicinity_items = _item_builder.build_vicinity(client_drops, 2.5)

    return {
        type = "grid",
        section_key = "vicinity",
        title = {
            text = "Vicinity",
            span = '<i class="fa-solid fa-location-dot"></i> Ground'
        },
        layout = { scroll_x = "none", scroll_y = "scroll", columns = 10, rows = 20, cell_size = "3vw" },
        items = vicinity_items
    }
end

function m.build_hotbar(player_data)
    local raw_hotbar = player_data and player_data.metadata and player_data.metadata.hotbar or (player_data and player_data.hotbar) or {}
    local hotbar_items = {}

    for slot_str, entry in pairs(raw_hotbar) do
        if entry and entry.id then
            local def = _items[entry.id]
            local slot_key = tostring(slot_str)
            hotbar_items[slot_key] = {
                id = entry.id,
                image = core.settings.general.image_path .. (entry.image or (def and def.image) or "default.png"),
                quantity = entry.quantity or 1,
                category = entry.category or (def and def.category) or "misc",
                progress = entry.durability and { value = entry.durability } or (entry.progress or nil),
                on_hover = {
                    title = entry.label or (def and def.label) or entry.id,
                    description = type(def and def.description) == "string" and { def.description } or ((def and def.description) or {}),
                    values = entry.values or {},
                    actions = {
                        { id = "use_" .. entry.id, key = "E", label = "Use" }
                    },
                    rarity = (entry.metadata and entry.metadata.rarity) or (def and def.rarity) or "common"
                }
            }
        end
    end

    return {
        slot_count = 8,
        show_slot_numbers = true,
        layout = { slot_size = "64px" },
        items = hotbar_items
    }
end

return m