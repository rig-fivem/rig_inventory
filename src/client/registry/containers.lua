--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @class Containers
--- @file src/client/registry/containers.lua
--- @description Client-side registry for world containers.

--- @section Imports

local objects = require("src.client.modules.objects")

--- @section Constants

local SPAWN_DISTANCE   = 50.0
local DESPAWN_DISTANCE = SPAWN_DISTANCE + 10.0

--- @section Class

local Containers = {}
Containers.__index = Containers

--- @section Factory

function Containers.new()
    return setmetatable({
        placed = {},
        vehicles = {}
    }, Containers)
end

--- @section CRUD

function Containers:init(data)
    if type(data) ~= "table" then return end
    for id, container in pairs(data) do
        container.entity = nil
        self.placed[id] = container
    end
end

function Containers:add(data)
    if type(data) ~= "table" or not data.id then return end
    data.entity = nil
    self.placed[data.id] = data
end

function Containers:get(id)
    return self.placed[id] or self.vehicles[id]
end

function Containers:remove(id)
    local container = self.placed[id]
    if not container then return end
    
    if container.entity then 
        objects.remove(container.entity) 
    end
    self.placed[id] = nil
end

--- @section Vehicle Containers

function Containers:add_vehicle(data)
    if type(data) ~= "table" or not data.id then return end
    self.vehicles[data.id] = data
end

function Containers:clear_vehicles()
    for k in pairs(self.vehicles) do 
        self.vehicles[k] = nil 
    end
end

--- @section Streaming

function Containers:stream(player_coords)
    for id, container in pairs(self.placed) do
        local coords = container.coords or (container.metadata and container.metadata.coords)

        if coords and coords.x and coords.y and coords.z then
            local pos = vector3(coords.x, coords.y, coords.z)
            local dist = #(player_coords - pos)

            if dist < SPAWN_DISTANCE and not container.entity then
                container.entity = objects.create(container.model, coords)
            elseif dist >= DESPAWN_DISTANCE and container.entity then
                objects.remove(container.entity)
                container.entity = nil
            end
        end
    end
end

return Containers