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
--- @description Handles item use, loadout equipping/unequipping, and item animation callbacks.

--- @section Imports

local _items = require("src.shared.data.items")
local _utils = require("src.server.modules.utils")

--- @section Initialisation

local m = {}

--- @section Constants

local CLOTHING_COMPONENTS = {
    [5] = { style = "bag_style", texture = "bag_texture" },
}

--- @section Apply Clothing

local function apply_loadout_clothing(source, use_config, equipping)
    if not use_config or not use_config.clothing then return end

    local mapping = CLOTHING_COMPONENTS[use_config.clothing.component_id]
    if not mapping then
        log("warn", ("[apply_loadout_clothing] no style mapping for component_id %s - add one to CLOTHING_COMPONENTS"):format(tostring(use_config.clothing.component_id)))
    else
        local avatar_data = exports.rig:get_player_data(source, "avatar")
        local current_clothing = (avatar_data and avatar_data.clothing) or {}

        local patched_clothing = {}
        for k, v in pairs(current_clothing) do patched_clothing[k] = v end

        if equipping then
            local gender_clothing = use_config.clothing.male or use_config.clothing.female or use_config.clothing
            patched_clothing[mapping.style] = gender_clothing.drawable
            if mapping.texture then patched_clothing[mapping.texture] = gender_clothing.texture end
        else
            patched_clothing[mapping.style] = -1
            if mapping.texture then patched_clothing[mapping.texture] = 0 end
        end

        local persisted = exports.rig:customise_avatar(source, { clothing = patched_clothing })
        if not persisted then
            log("error", ("[apply_loadout_clothing] customise_avatar failed for src:%s"):format(source))
        end
    end


    TriggerClientEvent("rig_inventory:client:apply_inventory_clothing", source, {
        action = equipping and "equip" or "remove",
        clothing = use_config.clothing,
        prop = use_config.prop
    })
end

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

        TriggerEvent("rig_inventory:server:weapon_state_changed", source, false, nil)
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

    TriggerEvent("rig_inventory:server:weapon_state_changed", source, true, item)
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

--- @section Player Inventory Actions

function m.toggle_player_inventory(source, data)
    if not source or not data then return log("error", "[toggle_player_inventory] missing args") end

    local item = _utils.get_item(source, data.col, data.row, data.group)
    if not item then
        exports.rig:notify(source, { type = "error", header = "Inventory", message = "Item not found", duration = 3000 })
        return log("warn", "[toggle_player_inventory] no item")
    end

    local def = _items[item.id]
    if not def or not def.actions or not def.actions.use then
        exports.rig:notify(source, { type = "error", header = "Inventory", message = "This item cannot be used", duration = 3000 })
        return log("error", "[toggle_player_inventory] no definition: " .. item.id)
    end

    local use_config = def.actions.use
    local inventory_group = use_config.inventory_group
    local loadout_slot = use_config.loadout_slot

    local inv_meta = _utils.get_inventory_metadata(source) or {}
    inv_meta.equipped_inventories = inv_meta.equipped_inventories or {}
    inv_meta.loadout = inv_meta.loadout or {}

    local is_equipped = item.metadata and item.metadata.equipped == true

    if is_equipped then
        if loadout_slot then
            inv_meta.loadout[loadout_slot] = nil
        end

        if inventory_group then
            local group_contents = exports.rig:remove_inventory_group(source, inventory_group)
            item.metadata.stored_items = group_contents
        end

        item.metadata.equipped = false

        for i, equipped_inv in ipairs(inv_meta.equipped_inventories) do
            if equipped_inv.group == (inventory_group or loadout_slot) and equipped_inv.serial == item.metadata.serial then
                table.remove(inv_meta.equipped_inventories, i)
                break
            end
        end

        _utils.add_item(source, item.id, 1, data.group)

        apply_loadout_clothing(source, use_config, false)
        exports.rig:set_inventory_metadata(source, inv_meta, false)
        _utils.sync_and_refresh(source)
        exports.rig:notify(source, { type = "success", header = "Inventory", message = ("Unequipped %s"):format(def.label), duration = 4000 })
        log("success", ("[toggle_player_inventory] unequipped %s from slot %s"):format(item.id, loadout_slot or inventory_group))
    else
        for _, equipped_inv in ipairs(inv_meta.equipped_inventories) do
            local other_item = _utils.get_item(source, equipped_inv.col, equipped_inv.row, equipped_inv.source_group)
            if other_item and other_item.metadata and other_item.metadata.serial ~= (item.metadata and item.metadata.serial or "") then
                exports.rig:notify(source, { type = "error", header = "Inventory", message = "You already have one equipped!", duration = 4000 })
                return log("warn", "[toggle_player_inventory] already equipped for src: " .. source)
            end
        end

        if loadout_slot and inv_meta.loadout[loadout_slot] then
            exports.rig:notify(source, { type = "error", header = "Inventory", message = "That slot is already occupied!", duration = 4000 })
            return log("warn", "[toggle_player_inventory] loadout slot occupied: " .. loadout_slot)
        end

        item.metadata = item.metadata or {}
        if not item.metadata.serial or item.metadata.serial == "" then
            item.metadata.serial = ("%s_%s_%s"):format(item.id, source, os.time())
        end

        item.metadata.equipped = true
        local stored_items = item.metadata.stored_items or {}

        local removed = _utils.remove_item(source, data.col, data.row, data.group, 1)
        if not removed then
            exports.rig:notify(source, { type = "error", header = "Inventory", message = "Failed to equip item", duration = 3000 })
            return log("error", "[toggle_player_inventory] failed to remove item from source")
        end

        if inventory_group then
            local success = exports.rig:add_inventory_group(source, inventory_group, stored_items)
            if not success then
                _utils.add_item(source, item.id, 1, data.group)
                exports.rig:notify(source, { type = "error", header = "Inventory", message = "Failed to add inventory", duration = 3000 })
                return
            end
        end

        if loadout_slot then
            inv_meta.loadout[loadout_slot] = {
                id = item.id,
                label = def.label,
                image = def.image,
                category = def.category,
                metadata = item.metadata,
                serial = item.metadata.serial,
                source_group = data.group,
                inventory_group = inventory_group
            }
        end

        table.insert(inv_meta.equipped_inventories, {
            group = inventory_group or loadout_slot,
            serial = item.metadata.serial,
            col = data.col,
            row = data.row,
            source_group = data.group,
            item_id = item.id
        })

        apply_loadout_clothing(source, use_config, true)
        exports.rig:set_inventory_metadata(source, inv_meta, false)
        _utils.sync_and_refresh(source)
        exports.rig:notify(source, { type = "success", header = "Inventory", message = ("Equipped %s"):format(def.label), duration = 4000 })
        log("success", ("[toggle_player_inventory] equipped %s to slot %s"):format(item.id, loadout_slot or inventory_group))
    end
end
core.toggle_player_inventory = m.toggle_player_inventory

function m.unequip_loadout_item(source, data)
    if not data or not data.slot_id then return log("error", "[unequip_loadout_item] missing slot_id") end

    local inv_meta = _utils.get_inventory_metadata(source) or {}
    inv_meta.loadout = inv_meta.loadout or {}

    local slot_entry = inv_meta.loadout[data.slot_id]
    if not slot_entry then return log("warn", "[unequip_loadout_item] slot empty: " .. data.slot_id) end

    local def = _items[slot_entry.id]
    if not def then return log("error", "[unequip_loadout_item] no item def: " .. slot_entry.id) end

    local use_config = def.actions and def.actions.use

    if slot_entry.inventory_group then
        local group_contents = exports.rig:remove_inventory_group(source, slot_entry.inventory_group)
        slot_entry.metadata = slot_entry.metadata or {}
        slot_entry.metadata.stored_items = group_contents
    end

    slot_entry.metadata = slot_entry.metadata or {}
    slot_entry.metadata.equipped = false

    inv_meta.equipped_inventories = inv_meta.equipped_inventories or {}
    for i, equipped_inv in ipairs(inv_meta.equipped_inventories) do
        if equipped_inv.serial == slot_entry.serial then
            table.remove(inv_meta.equipped_inventories, i)
            break
        end
    end

    inv_meta.loadout[data.slot_id] = nil

    local target_group = slot_entry.source_group or "pockets"
    local success = _utils.add_item(source, slot_entry.id, 1, target_group)
    if not success then
        log("error", "[unequip_loadout_item] failed to return item to " .. target_group)
        return
    end

    if use_config then
        apply_loadout_clothing(source, use_config, false)
    end

    exports.rig:set_inventory_metadata(source, inv_meta, false)
    _utils.sync_and_refresh(source)
    exports.rig:notify(source, { type = "success", header = "Inventory", message = ("Unequipped %s"):format(def.label), duration = 4000 })
    log("success", ("[unequip_loadout_item] src:%s unequipped %s from %s"):format(source, slot_entry.id, data.slot_id))
end

function m.animation_finished(source, data)
    if not data or not data.item_id or not data.col or not data.row or not data.group then
        return log("error", "[animation_finished] missing data")
    end

    local def = _items[data.item_id]
    if not def then return log("warn", "[animation_finished] no item def: " .. data.item_id) end

    if def.category == "player_inventory" then
        return m.toggle_player_inventory(source, { col = data.col, row = data.row, group = data.group })
    end

    local use_config = def.actions and def.actions.use
    if use_config then
        local anim = use_config.animation
        if type(anim) == "table" and type(anim.callback) == "function" then
            anim.callback(source, data)
        elseif type(use_config.callback) == "function" then
            use_config.callback(source, data)
        end
    end
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

    local weapon_categories = {
        firearm = true,
        melee = true,
        throwable = true
    }

    if weapon_categories[category] then return handle_weapon_use(source, col, row, item, def, group) end
    if category == "ammo" then return handle_ammo_use(source, col, row, item, def, group) end
    if category == "attachments" then return handle_attachment_use(source, col, row, item, def, group) end

    if category == "player_inventory" then
        local use_config = def.actions and def.actions.use
        if use_config and use_config.animation then
            TriggerClientEvent("rig_inventory:client:use_item_animation", source, {
                animation = use_config.animation,
                col = col, row = row, group = group, item_id = item.id
            })
            return true
        end

        m.toggle_player_inventory(source, { col = col, row = row, group = group })
        return true
    end

    local ok = exports.rig:run_hook(item.id, source, col, row, group)
    if not ok then
        log("info", "[use_item] item not usable: " .. item.id)
    end
    return ok
end

return m