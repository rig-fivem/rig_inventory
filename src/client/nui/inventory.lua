--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module inventory
--- @file src.client.nui.inventory
--- @description Handles client-side inventory UI building.

--- @section Imports

local item_defs = require("configs.items")
local inv_defs = require("configs.inventories")
local metadata_defs = require("configs.metadata")

local _nui = require("src.client.modules.nui")

--- @section Initialisation

local m = {}

--- @section Helpers

local function build_header()
    local player_source = GetPlayerServerId(PlayerId())
    return {
        layout = {
            left = { justify = "flex-start" },
            center = { justify = "center" },
            right = { justify = "flex-end" }
        },
        elements = {
            left = {},
            center = { { type = "tabs" } },
            right = {
                {
                    type = "buttons",
                    buttons = {
                        {
                            id = "close_inventory",
                            label = "Close",
                            class = "primary",
                            should_close = true,
                            on_action = function()
                                TriggerServerEvent("rig_inventory:server:close_inventory")
                                inventory_open = false
                                ClearTimecycleModifier()
                            end
                        }
                    }
                }
            }
        }
    }
end

local function build_footer()
    return {
        layout = {
            left = { justify = "flex-start" },
            center = { justify = "center" },
            right = { justify = "flex-end" }
        },
        elements = {
            right = {
                {
                    type = "actions",
                    actions = {
                        {
                            key = "ESCAPE",
                            label = "Close",
                            should_close = true,
                            on_action = function()
                                TriggerServerEvent("rig_inventory:server:close_inventory")
                                inventory_open = false
                                ClearTimecycleModifier()
                            end
                        }
                    }
                }
            }
        }
    }
end

local function build_loadout_items(loadout)
    local items = {}
    for slot_id, entry in pairs(loadout or {}) do
        local def = item_defs[entry.id]
        items[slot_id] = {
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
                        should_close = false,
                        on_action = function(data)
                            print("unequipping")
                        end
                    }
                }
            }
        }
    end
    return items
end

local function build_hotbar(player_data)
    local raw_hotbar = player_data and player_data.metadata and player_data.metadata.hotbar or (player_data and player_data.hotbar) or {}
    local hotbar_items = {}

    for slot_str, entry in pairs(raw_hotbar) do
        if entry and entry.id then
            local def = item_defs[entry.id]
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

local function build_center(player_data)
    local loadout = player_data and player_data.metadata and player_data.metadata.loadout or {}
    local items = build_loadout_items(loadout)
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
                    { id = "bag", label = "Bag", position = { top = "22%", left = "0%" }, size = "72px" },
                    { id = "primary", label = "Sling 1", position = { top = "22%", left = "30%" }, size = "72px" },
                    { id = "vest", label = "Vest", position = { top = "44%", left = "0%" }, size = "72px" },
                    { id = "secondary", label = "Sling 2", position = { top = "44%", left = "30%" }, size = "72px" },
                    { id = "shirt", label = "Shirt", position = { top = "66%", left = "0%" }, size = "72px" },
                    { id = "melee", label = "Melee", position = { top = "66%", left = "30%" }, size = "72px" },
                    { id = "pants", label = "Pants", position = { top = "85%", left = "0%" }, size = "72px" },
                    { id = "shoes", label = "Shoes", position = { top = "85%", left = "30%" }, size = "72px" }
                },
                items = items
            }
        }
    }
end

local function build_item_actions(def, col, row, entry, group)
    if not def or not def.actions then return nil end
    local group_def = inv_defs[group]
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
                TriggerServerEvent("rig_inventory:sv:close_inventory")
                inventory_open = false
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

local function resolve_meta_value(meta_def, meta_value)
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

local function build_player_groups(player_data)
    local groups = {}
    for group_id, raw_items in pairs(player_data.items or {}) do
        local def = inv_defs[group_id]
        if def and def.is_player then
            groups[#groups + 1] = {
                id = group_id,
                title = def.label,
                span = def.icon and ('<i class="%s"></i>'):format(def.icon) or nil,
                layout = { columns = def.columns or 10, rows = def.rows or 4, cell_size = "3vw" },
                collapsible = def.collapsible or false,
                collapsed = def.collapsed or false,
                items = m.build_items_for_grid(raw_items, group_id)
            }
        end
    end
    return groups
end

local function build_right()
    local client_drops = core.client_drops and core.client_drops.drops or {}
    local vicinity_items = m.build_vicinity_items(client_drops, 2.5)
    return {
        type = "grid",
        section_key = "vicinity",
        title = {
            text = "Vicinity",
            span = '<i class="fa-solid fa-location-dot"></i> ' .. "Ground"
        },
        layout = { scroll_x = "none", scroll_y = "scroll", columns = 10, rows = 20, cell_size = "3vw" },
        items = vicinity_items
    }
end

--- @section Vicinity Items

function m.build_vicinity_items(drops, radius)
    local items = {}
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local col, row = 1, 1

    for _, drop in pairs(drops or {}) do
        local dcoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        if #(pcoords - dcoords) <= radius then
            local def = item_defs[drop.item_id]
            local values = {}

            for meta_key, meta_value in pairs(drop.metadata or {}) do
                local meta_def = metadata_defs[meta_key]
                if meta_def then
                    local display = resolve_meta_value(meta_def, meta_value)
                    if display then values[#values + 1] = { key = meta_def.label, value = display } end
                end
            end

            local description = type(drop.description) == "string" and { drop.description } or drop.description

            local w = drop.w or 1
            local h = drop.h or 1
            items[#items + 1] = {
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

    return items
end

--- @section Grid Items

function m.build_items_for_grid(raw_items, group_id)
    local items = {}

    for _, entry in pairs(raw_items or {}) do
        local def = item_defs[entry.id]
        if def then
            local values = {}
            local progress = nil

            for meta_key, meta_value in pairs(entry.metadata or {}) do
                local meta_def = metadata_defs[meta_key]
                if meta_def then
                    if meta_key == "durability" then progress = { value = meta_value } end
                    local display = resolve_meta_value(meta_def, meta_value)
                    if display then values[#values + 1] = { key = meta_def.label, value = display } end
                end
            end

            local description = type(def.description) == "string" and { def.description } or def.description

            items[#items + 1] = {
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
                    rarity = (entry.metadata and entry.metadata.rarity) or (def.metadata and def.metadata.rarity) or "common",
                    actions = build_item_actions(def, entry.col, entry.row, entry, group_id)
                }
            }
        end
    end

    return items
end

--- @section Build

function m.build(player_data)
    local groups = build_player_groups(player_data)
    local header = build_header()

    header.elements.left = {
        {
            type = "group",
            items = {
                { type = "logo", image = _nui.get_player_headshot() },
                { type = "text", title = player_data.username, subtitle = player_data.unique_id }
            }
        }
    }

    _nui.build_ui({
        header = header,
        footer = build_footer(),
        content = {
            pages = {
                inventory_page = {
                    index = 1,
                    title = "Inventory",
                    layout = { left = 3, center = 2, spacer3 = 4, right = 3 },
                    left = {
                        type = "grid",
                        title = { text = "Inventories" },
                        layout = { scroll_x = "none", scroll_y = "scroll" },
                        groups = groups
                    },
                    center = build_center(player_data),
                    right = build_right()
                }
            },
            hotbar = build_hotbar(player_data)
        }
    })
end

return m