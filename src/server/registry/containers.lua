--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @class Containers
--- @file src/server/registry/containers.lua
--- @description Registry of loaded containers (vehicle gloveboxes/trunks, fridges,
--- chests, etc). New piece - didn't exist as a standalone module in the monolith,
--- `core.containers` was referenced there but never included in the extract, so
--- its API surface below is reconstructed from how the monolith actions/events
--- called into it (get, get_or_create_vehicle, get_locked_by_player,
--- unlock_all_for_player) plus what a sane vehicle-container cache needs.

--- @section Imports

local Container = require("src.server.classes.container")

--- @section Initialisation

local Containers = {}
Containers.__index = Containers

--- @section Factory

function Containers.new()
    return setmetatable({
        containers = {},
        locks = {},
        player_locks = {},
    }, Containers)
end

--- @section Lookup

function Containers:get(identifier)
    if not identifier then return nil end
    return self.containers[identifier]
end

function Containers:get_or_create(identifier, data)
    if not identifier then return nil end

    local existing = self.containers[identifier]
    if existing then
        if not existing:has_loaded() then
            if not existing:load() then return nil end
        end
        return existing
    end

    local container = Container.new(identifier, data)
    if not container:load() then return nil end

    self.containers[identifier] = container
    return container
end

function Containers:get_or_create_vehicle(plate, inv_type, info)
    if not plate or not inv_type then return nil end

    local identifier = ("vehicle:%s:%s"):format(inv_type, plate)
    return self:get_or_create(identifier, {
        owner = plate,
        type = "vehicle",
        subtype = inv_type,
        metadata = info and { vehicle_class = info.class, model = info.model } or nil
    })
end

function Containers:get_nearest(coords, radius)
    radius = radius or 2.5

    local nearest_id, nearest_container, nearest_dist

    for identifier, container in pairs(self.containers) do
        if container.type ~= "vehicle" and container:has_loaded() then
            local meta = container:get_data("metadata")
            local c = meta and meta.coords
            if c then
                local dx = coords.x - c.x
                local dy = coords.y - c.y
                local dz = (coords.z or c.z) - c.z
                local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                if dist <= radius and (not nearest_dist or dist < nearest_dist) then
                    nearest_dist = dist
                    nearest_id = identifier
                    nearest_container = container
                end
            end
        end
    end

    return nearest_id, nearest_container
end

--- @section Removal

function Containers:remove(identifier)
    local container = self.containers[identifier]
    if not container then return false end

    container:unload()
    self.containers[identifier] = nil
    self:unlock(identifier)
    return true
end

--- @section Locking
--- One container "open" per player at a time. Whoever calls open_inventory /
--- open_container for a fridge/chest/vehicle should `lock` it, and release it
--- with `unlock`/`unlock_all_for_player` on close/disconnect.

function Containers:is_locked(identifier)
    return self.locks[identifier] ~= nil
end

--- @param identifier string
--- @param source number
--- @return boolean success false if already locked by someone else
function Containers:lock(identifier, source)
    if not identifier or not source then return false end

    local current_holder = self.locks[identifier]
    if current_holder and current_holder ~= source then
        return false
    end

    -- players can only have one container open at a time; release whatever they had before
    local previous = self.player_locks[source]
    if previous and previous ~= identifier then
        self:unlock(previous)
    end

    self.locks[identifier] = source
    self.player_locks[source] = identifier
    return true
end

function Containers:unlock(identifier)
    if not identifier then return false end

    local source = self.locks[identifier]
    if not source then return false end

    self.locks[identifier] = nil
    if self.player_locks[source] == identifier then
        self.player_locks[source] = nil
    end

    return true
end

function Containers:unlock_all_for_player(source)
    local identifier = self.player_locks[source]
    if identifier then
        self:unlock(identifier)
    end
end

function Containers:get_locked_by_player(source)
    return self.player_locks[source]
end

--- @section Persistence

--- Saves every dirty, loaded container. Call on resource stop.
function Containers:save_all()
    for _, container in pairs(self.containers) do
        if container:has_loaded() then
            container:save()
        end
    end
end

return Containers