--- @module actions
--- @file src/server/modules/actions.lua
--- @description Handles all inventory actions; use, move, drop, etc.

--- @section Imports

local _items = require("configs.items")
local _inventories = require("configs.inventories")

--- @section Initialisation

local m = {}

--- @section Helpers

local function resolve_group(section)
    if not section then return nil end
    return section:gsub("^left_", ""):gsub("^right_", ""):gsub("^center_", "")
end

local function is_player_group(group_id)
    local def = _inventories[group_id]
    return def and def.is_player == true
end

local function sync_and_refresh(source)
    local synced = exports.rig:sync_player_data(source)
    if not synced then print("player data sync failed") return end

    local inv_data = exports.rig:get_inventory(source)
    if inv_data then
        print("sync inv data; ", json.encode(inv_data))
        TriggerClientEvent("rig_inventory:client:inventory_changed", source, inv_data)
        return
    end

    TriggerClientEvent("rig_inventory:client:inventory_changed", source)
end

--- @section Local Item Helpers

local function get_item(source, col, row, group)
    local inv = exports.rig:get_inventory(source)
    if not inv or not inv.items or not inv.items[group] then return nil end
    return inv.items[group][col .. "_" .. row]
end

local function set_item(source, col, row, group, item)
    return exports.rig:set_inventory_slots(source, {
        { group_id = group, key = col .. "_" .. row, item = item }
    })
end

local function remove_item(source, col, row, group, amount)
    local item = get_item(source, col, row, group)
    if not item then return false end

    amount = amount or 1
    local qty = item.quantity or 1

    if qty <= amount then
        return set_item(source, col, row, group, nil)
    end

    item.quantity = qty - amount
    return set_item(source, col, row, group, item)
end

local function find_free_slot(source, group)
    local def = _inventories[group]
    if not def then return nil end

    local inv = exports.rig:get_inventory(source)
    local items = inv and inv.items and inv.items[group] or {}

    for row = 1, def.rows or 4 do
        for col = 1, def.columns or 10 do
            if not items[col .. "_" .. row] then return col, row end
        end
    end

    return nil
end

local function add_item(source, item_id, quantity, group)
    quantity = quantity or 1
    local def = _items[item_id]
    if not def then return false end

    if def.stackable then
        local inv = exports.rig:get_inventory(source)
        local items = inv and inv.items and inv.items[group] or {}
        for key, existing in pairs(items) do
            if existing.id == item_id then
                existing.quantity = (existing.quantity or 1) + quantity
                local col, row = key:match("(%d+)_(%d+)")
                return set_item(source, tonumber(col), tonumber(row), group, existing)
            end
        end
    end

    local col, row = find_free_slot(source, group)
    if not col then return false end

    return set_item(source, col, row, group, { id = item_id, quantity = quantity, col = col, row = row })
end

local function get_inventory_metadata(source)
    local inv = exports.rig:get_inventory(source)
    return inv and inv.metadata or {}
end

--- @section Weapon Handlers

local function handle_weapon_use(source, col, row, item, def, group)
    local ped = GetPlayerPed(source)
    if not ped or not DoesEntityExist(ped) then return false end

    local inv_meta = get_inventory_metadata(source)
    local equipped = inv_meta.equipped_weapon

    if equipped and equipped.col == col and equipped.row == row and equipped.group == group and equipped.id == item.id and item.metadata and equipped.serial == item.metadata.serial then
        RemoveAllPedWeapons(ped, true)
        inv_meta.equipped_weapon = nil
        exports.rig:set_inventory_metadata(source, inv_meta, false)
        sync_and_refresh(source)
        return true
    end

    RemoveAllPedWeapons(ped, true)
    item.metadata = item.metadata or {}

    if not item.metadata.serial or item.metadata.serial == "" then
        item.metadata.serial = ("%s_%s_%s"):format(item.id, source, os.time())
        exports.rig:set_item_metadata(source, group, col .. "_" .. row, { serial = item.metadata.serial }, true)
    end

    local weapon_hash = GetHashKey(item.id)
    local ammo = tonumber(item.metadata.ammo) or 0
    GiveWeaponToPed(ped, weapon_hash, ammo, false, true)
    SetPedAmmo(ped, weapon_hash, ammo)

    if type(item.metadata.attachments) == "table" then
        for _, attachment_id in ipairs(item.metadata.attachments) do
            local att_def = _items[attachment_id]
            if att_def and att_def.actions and att_def.actions.use and att_def.actions.use.attachments then
                for _, mod in ipairs(att_def.actions.use.attachments) do
                    if mod.weapon == item.id and mod.component then
                        GiveWeaponComponentToPed(ped, weapon_hash, GetHashKey(mod.component))
                    end
                end
            end
        end
    end

    inv_meta.equipped_weapon = { col = col, row = row, group = group, id = item.id, serial = item.metadata.serial }
    exports.rig:set_inventory_metadata(source, inv_meta, false)
    sync_and_refresh(source)
    return true
end

local function handle_ammo_use(source, col, row, item, def, group)
    local inv_meta = get_inventory_metadata(source)
    local equipped = inv_meta.equipped_weapon
    if not equipped then return false end

    local ped = GetPlayerPed(source)
    if not ped or not DoesEntityExist(ped) then return false end

    local weapon_item = get_item(source, equipped.col, equipped.row, equipped.group)
    if not weapon_item then return false end

    local weapon_def = _items[weapon_item.id]
    if not weapon_def then return false end

    local allowed_ammo = weapon_def.metadata and weapon_def.metadata.ammo_types or {}
    local valid = false
    for _, ammo_id in ipairs(allowed_ammo) do
        if ammo_id == item.id then valid = true break end
    end
    if not valid then return false end

    weapon_item.metadata = weapon_item.metadata or {}
    local current_ammo = tonumber(weapon_item.metadata.ammo) or 0
    local rounds_to_add = math.min(def.metadata and def.metadata.ammo_refill or 1, item.quantity or 1)
    local new_ammo = current_ammo + rounds_to_add
    weapon_item.metadata.ammo = new_ammo

    exports.rig:set_item_metadata(source, equipped.group, equipped.col .. "_" .. equipped.row, weapon_item.metadata, false)

    local weapon_hash = GetHashKey(weapon_item.id)
    SetPedAmmo(ped, weapon_hash, new_ammo)

    remove_item(source, col, row, group, rounds_to_add)
    sync_and_refresh(source)
    return true
end

local function handle_attachment_use(source, col, row, item, def, group)
    local inv_meta = get_inventory_metadata(source)
    local equipped = inv_meta.equipped_weapon
    if not equipped then return false end

    local weapon_item = get_item(source, equipped.col, equipped.row, equipped.group)
    if not weapon_item then return false end

    local component
    for _, mod in ipairs(def.actions.use.attachments or {}) do
        if mod.weapon == weapon_item.id then
            component = mod.component
            break
        end
    end
    if not component then return false end

    weapon_item.metadata = weapon_item.metadata or {}
    weapon_item.metadata.attachments = weapon_item.metadata.attachments or {}

    local ped = GetPlayerPed(source)
    local weapon_hash = GetHashKey(weapon_item.id)
    local component_hash = GetHashKey(component)

    for i = #weapon_item.metadata.attachments, 1, -1 do
        if weapon_item.metadata.attachments[i] == item.id then
            RemoveWeaponComponentFromPed(ped, weapon_hash, component_hash)
            table.remove(weapon_item.metadata.attachments, i)
            add_item(source, item.id, 1, group)
            exports.rig:set_item_metadata(source, equipped.group, equipped.col .. "_" .. equipped.row, weapon_item.metadata, false)
            sync_and_refresh(source)
            return true
        end
    end

    GiveWeaponComponentToPed(ped, weapon_hash, component_hash)
    table.insert(weapon_item.metadata.attachments, item.id)
    remove_item(source, col, row, group, 1)
    exports.rig:set_item_metadata(source, equipped.group, equipped.col .. "_" .. equipped.row, weapon_item.metadata, false)
    sync_and_refresh(source)
    return true
end

--- @section Use Item

function m.use_item(source, use_data)
    if not source or not use_data then return log("error", "[use_item] invalid params") end

    local col, row, group

    if type(use_data) == "table" then
        col = tonumber(use_data.col)
        row = tonumber(use_data.row)
        group = use_data.group
    end

    if not col or not row or not group then return log("warn", "[use_item] col/row/group required") end

    local item = get_item(source, col, row, group)
    if not item then return log("warn", "[use_item] no item at position") end

    local def = _items[item.id]
    if not def then return log("error", "[use_item] no definition: " .. item.id) end

    local category = def.category or "general"

    if category == "weapon" then return handle_weapon_use(source, col, row, item, def, group) end
    if category == "ammo" then return handle_ammo_use(source, col, row, item, def, group) end
    if category == "attachments" then return handle_attachment_use(source, col, row, item, def, group) end

    if category == "player_inventory" then
        local use_config = def.actions and def.actions.use
        if use_config and use_config.animation then
            TriggerClientEvent("rig:cl:use_item_animation", source, {
                animation = use_config.animation,
                col = col, row = row, group = group, item_id = item.id
            })
            return true
        end
        return false
    end

    local ok = exports.rig:run_hook(item.id, source, col, row, group)
    if not ok then
        log("info", "[use_item] item not usable: " .. item.id)
    end
    return ok
end

--- @section Move Item

function m.move_item(source, move_data)
    if not move_data then return log("error", "[move_item] no data") end

    local from_col = tonumber(move_data.from_col)
    local from_row = tonumber(move_data.from_row)
    local to_col = tonumber(move_data.to_col)
    local to_row = tonumber(move_data.to_row)
    local from_group = resolve_group(move_data.from_section or move_data.from_group)
    local to_group = resolve_group(move_data.to_section or move_data.to_group)

    if not from_col or not from_row or not to_col or not to_row or not from_group or not to_group then
        return log("error", ("[move_item] incomplete data: %s"):format(json.encode(move_data)))
    end

    log("debug", ("[move_item] src:%s | from:%s_%s(%s) -> to:%s_%s(%s)"):format(source, from_col, from_row, from_group, to_col, to_row, to_group))

    if to_group == "vicinity" then
        m.drop_item(source, { col = from_col, row = from_row, group = from_group })
        return
    end

    if from_group == "vicinity" then
        local drop_id = move_data.dataset and tonumber(move_data.dataset.drop_id)
        if drop_id then m.pickup_drop(source, drop_id) end
        return
    end

    local from_is_player = is_player_group(from_group)
    local to_is_player = is_player_group(to_group)

    if from_is_player and to_is_player then
        local inv_data = exports.rig:get_inventory(source)
        if not inv_data or not inv_data.items then 
            return log("error", "[move_item] no player inventory data") 
        end

        local from_key = from_col .. "_" .. from_row
        local to_key = to_col .. "_" .. to_row

        local from_items = inv_data.items[from_group]
        local to_items = inv_data.items[to_group]

        local source_item = from_items and from_items[from_key]
        if not source_item then 
            return log("warn", "[move_item] source item missing") 
        end

        local target_item = to_items and to_items[to_key]

        source_item.col = to_col
        source_item.row = to_row

        local changes = {
            { group_id = from_group, key = from_key, item = target_item },
            { group_id = to_group, key = to_key, item = source_item }
        }

        if target_item then
            target_item.col = from_col
            target_item.row = from_row
        end

        local success = exports.rig:set_inventory_slots(source, changes)
        if success then
            sync_and_refresh(source)
            log("success", "[move_item] player -> player ok")
        else
            log("warn", "[move_item] player move failed")
        end
        return
    end

    log("error", "[move_item] unhandled move case")
end

return m