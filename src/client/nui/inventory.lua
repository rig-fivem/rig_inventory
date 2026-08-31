--- @script src.client.inventory.actions
--- @description Handles client-side inventory UI building with center preview ped and camera DoF blur.

--- @section Imports

local item_defs = require("configs.items")
local inv_defs = require("configs.inventories")

local _nui = require("src.client.modules.nui")

--- @section State

local inventory_open = false
local preview_ped = nil
local preview_cam = nil
local client_drops = {} -- @todo populated once a drops/world-item system exists

--- @section Helpers

local function stop_ped_preview()
    if preview_cam then
        RenderScriptCams(false, true, 250, true, true)
        DestroyCam(preview_cam, false)
        preview_cam = nil
    end

    if preview_ped and DoesEntityExist(preview_ped) then
        DeleteEntity(preview_ped)
        preview_ped = nil
    end
end

local function start_ped_preview()
    stop_ped_preview()
    local player_ped = PlayerPedId()
    local player_coords = GetEntityCoords(player_ped)
    local cam_coords = GetGameplayCamCoord()
    local cam_rot = GetGameplayCamRot(2)
    local yaw = math.rad(cam_rot.z)
    local dist = 3.0
    local spawn_x = cam_coords.x - math.sin(yaw) * dist
    local spawn_y = cam_coords.y + math.cos(yaw) * dist
    local spawn_z = player_coords.z

    preview_ped = ClonePed(player_ped, false, false, false)
    SetEntityCoords(preview_ped, spawn_x, spawn_y, spawn_z, false, false, false, false)
    SetEntityHeading(preview_ped, cam_rot.z + 180.0)
    SetEntityInvincible(preview_ped, true)
    SetEntityCollision(preview_ped, false, false)
    FreezeEntityPosition(preview_ped, true)
    SetBlockingOfNonTemporaryEvents(preview_ped, true)

    preview_cam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        cam_coords.x, cam_coords.y, cam_coords.z,
        cam_rot.x, cam_rot.y, cam_rot.z,
        GetGameplayCamFov(),
        false, 0
    )

    SetCamActive(preview_cam, true)
    RenderScriptCams(true, true, 250, true, true)
    
    SetCamUseShallowDofMode(preview_cam, true)
    SetCamNearDof(preview_cam, 2.0)
    SetCamFarDof(preview_cam, 3.0)
    SetCamDofStrength(preview_cam, 1.0)

    CreateThread(function()
        while DoesCamExist(preview_cam) do
            SetUseHiDof()
            Wait(0)
        end
    end)
end

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
                    type = "group",
                    items = {
                        { type = "text", subtitle = "ID: " .. player_source }
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
                                stop_ped_preview()
                                FreezeEntityPosition(PlayerPedId(), false)
                                TriggerServerEvent("rig_inventory:server:close_inventory")
                                inventory_open = false
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
            image = core.convars.image_path .. (entry.image or (def and def.image) or "default.png"),
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
                image = core.convars.image_path .. (entry.image or (def and def.image) or "default.png"),
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
        layout = { slot_size = "58px" },
        items = hotbar_items
    }
end

local function build_center(player_data)
    local loadout = player_data and player_data.metadata and player_data.metadata.loadout or {}
    local items = build_loadout_items(loadout)
    return {
        type = "slots",
        layout = { scroll_y = "none", scroll_x = "none" },
        allow_cross_group_swap = true,
        groups = {
            {
                id = "loadout",
                layout_type = "positioned",
                collapsible = false,
                slots = {
                    { id = "helmet", label = "HELMET", position = { top = "2%", left = "10%" }, size = "64px" },
                    { id = "mask", label = "MASK", position = { top = "2%", right = "10%" }, size = "64px" },
                    { id = "backpack", label = "BACKPACK", position = { top = "22%", left = "0%" }, size = "64px" },
                    { id = "sling1", label = "SLING 1", position = { top = "22%", right = "0%" }, size = "64px" },
                    { id = "vest", label = "VEST", position = { top = "42%", left = "0%" }, size = "64px" },
                    { id = "sling2", label = "SLING 2", position = { top = "42%", right = "0%" }, size = "64px" },
                    { id = "shirt", label = "SHIRT", position = { top = "62%", left = "0%" }, size = "64px" },
                    { id = "melee", label = "MELEE", position = { top = "62%", right = "0%" }, size = "64px" },
                    { id = "pants", label = "PANTS", position = { top = "82%", left = "10%" }, size = "64px" },
                    { id = "shoes", label = "SHOES", position = { top = "82%", right = "10%" }, size = "64px" },
                },
                items = items
            }
        }
    }
end

local function build_items_for_grid(raw_items, group_id)
    local items = {}

    for _, entry in pairs(raw_items or {}) do
        local def = item_defs[entry.id]
        if def then
            items[#items + 1] = {
                id = entry.id,
                image = core.convars.image_path .. (entry.image or def.image),
                label = def.label,
                col = entry.col,
                row = entry.row,
                w = entry.w or def.w or 1,
                h = entry.h or def.h or 1,
                quantity = entry.quantity or 1,
                category = def.category,
                dataset = { col = entry.col, row = entry.row, group_id = group_id },
                on_hover = {
                    title = def.label or entry.id,
                    description = type(def.description) == "string" and { def.description } or (def.description or {})
                }
            }
        end
    end

    return items
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
                items = build_items_for_grid(raw_items, group_id)
            }
        end
    end
    return groups
end

local function build_vicinity_items(drops, radius)
    local items = {}
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local col, row = 1, 1

    for _, drop in pairs(drops or {}) do
        local dcoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        if #(pcoords - dcoords) <= radius then
            local w = drop.w or 1
            local h = drop.h or 1
            items[#items + 1] = {
                id = drop.item_id,
                image = core.convars.image_path .. drop.image,
                label = drop.label or drop.item_id,
                col = col,
                row = row,
                w = w,
                h = h,
                quantity = drop.quantity,
                category = drop.category,
                dataset = { drop_id = drop.id }
            }
            col = col + w
            if col > 10 then col = 1 row = row + 1 end
        end
    end

    return items
end

local function build_right()
    local vicinity_items = build_vicinity_items(client_drops, 2.5)
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

--- @section Build

local function build_inventory(player_data)
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
                    layout = { left = 3, spacer2 = 1, center = 4, spacer3 = 1, right = 3 },
                    left = {
                        type = "grid",
                        title = { text = "Equipment" },
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

--- @section Events

RegisterNetEvent("rig_inventory:client:open_inventory", function(player_data)
    if type(player_data) ~= "table" then return end
    inventory_open = true
    start_ped_preview()
    build_inventory(player_data)
end)

RegisterNetEvent("rig_inventory:client:close_inventory", function()
    inventory_open = false
    stop_ped_preview()
    TriggerEvent("rig_inventory:client:close_ui")
    FreezeEntityPosition(PlayerPedId(), false)
end)

--- @section Commands

RegisterCommand("inv:open", function()
    if IsNuiFocused() or IsPauseMenuActive() then return end

    ExecuteCommand("_open_inventory")
end, false)

RegisterKeyMapping("inv:open", "Open Inventory", "keyboard", "TAB")