--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @class Drops
--- @file src/server/registry/drops.lua
--- @description Manages ground drops.

--- @section Helpers

local function resolve_coords(drops, base)
    for _, drop in pairs(drops) do
        local dx = base.x - drop.coords.x
        local dy = base.y - drop.coords.y
        if math.sqrt(dx * dx + dy * dy) < 0.6 then
            base = {
                x = base.x + math.random(-30, 30) / 100,
                y = base.y + math.random(-30, 30) / 100,
                z = base.z
            }
        end
    end
    return base
end

--- @section Initialisation

local Drops = {}
Drops.__index = Drops

--- @section Factory

function Drops.new()
    return setmetatable({
        drops = {},
        pickup_locks = {},
        drop_index = 0,
    }, Drops)
end

--- @section CRUD

function Drops:add(data)
    self.drop_index = self.drop_index + 1
    data.id = self.drop_index
    data.coords = resolve_coords(self.drops, data.coords)
    self.drops[self.drop_index] = data
    TriggerClientEvent("rig_inventory:client:add_drop", -1, data)
    return self.drop_index
end

function Drops:remove(drop_id)
    if not self.drops[drop_id] then return false end
    self.drops[drop_id] = nil
    self.pickup_locks[drop_id] = nil
    TriggerClientEvent("rig_inventory:client:remove_drop", -1, drop_id)
    return true
end

function Drops:get(drop_id)
    return self.drops[drop_id]
end

function Drops:get_all()
    return self.drops
end

function Drops:get_nearby(source, radius)
    radius = radius or 2.5
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return {} end

    local pcoords = GetEntityCoords(ped)
    local nearby = {}

    for drop_id, drop in pairs(self.drops) do
        local dcoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        if #(pcoords - dcoords) <= radius then
            nearby[#nearby + 1] = drop_id
        end
    end

    return nearby
end

--- @section Locks

function Drops:is_locked(drop_id)
    return self.pickup_locks[drop_id] ~= nil
end

function Drops:lock(drop_id)
    if self.pickup_locks[drop_id] then return false end
    self.pickup_locks[drop_id] = true
    return true
end

function Drops:unlock(drop_id)
    self.pickup_locks[drop_id] = nil
end

--- @section Sync

function Drops:sync_to(source)
    TriggerClientEvent("rig_inventory:client:init_drops", source, self.drops)
end

return Drops