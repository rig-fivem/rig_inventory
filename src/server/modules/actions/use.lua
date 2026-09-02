--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module actions.use
--- @file src/server/modules/actions/use.lua
--- @description Handles item use actions.

--- @section Imports

local _items = require("configs.items")
local _utils = require("src.server.modules.utils")

--- @section Initialisation

local m = {}

--- @section Weapon Handlers

local function handle_weapon_use(source, col, row, item, def, group)
    local ped = GetPlayerPed(source)
    if not ped or not DoesEntityExist(ped) then return false end

    local inv_meta = _utils.get_inventory_metadata(source)
    local equipped = inv_meta.equipped_weapon

    if equipped and equipped.col == col and equipped.row == row and equipped.group == group and equipped.id == item.id and item.metadata and equipped.serial == item.metadata.serial then
        RemoveAllPedWeapons(ped, true)
        inv_meta.equipped_weapon = nil
        exports.rig:set_inventory_metadata(source, inv_meta, false)
        _utils.sync_and_refresh(source)
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
    _utils.sync_and_refresh(source)
    return true
end

local function handle_ammo_use(source, col, row, item, def, group)
    local inv_meta = _utils.get_inventory_metadata(source)
    local equipped = inv_meta.equipped_weapon
    if not equipped then return false end

    local ped = GetPlayerPed(source)
    if not ped or not DoesEntityExist(ped) then return false end

    local weapon_item = _utils.get_item(source, equipped.col, equipped.row, equipped.group)
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

    _utils.remove_item(source, col, row, group, rounds_to_add)
    _utils.sync_and_refresh(source)
    return true
end

local function handle_attachment_use(source, col, row, item, def, group)
    local inv_meta = _utils.get_inventory_metadata(source)
    local equipped = inv_meta.equipped_weapon
    if not equipped then return false end

    local weapon_item = _utils.get_item(source, equipped.col, equipped.row, equipped.group)
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
            _utils.add_item(source, item.id, 1, group)
            exports.rig:set_item_metadata(source, equipped.group, equipped.col .. "_" .. equipped.row, weapon_item.metadata, false)
            _utils.sync_and_refresh(source)
            return true
        end
    end

    GiveWeaponComponentToPed(ped, weapon_hash, component_hash)
    table.insert(weapon_item.metadata.attachments, item.id)
    _utils.remove_item(source, col, row, group, 1)
    exports.rig:set_item_metadata(source, equipped.group, equipped.col .. "_" .. equipped.row, weapon_item.metadata, false)
    _utils.sync_and_refresh(source)
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

    local item = _utils.get_item(source, col, row, group)
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

return m