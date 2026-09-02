--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @class Drops
--- @file src/client/registry/drops.lua
--- @description Client-side registry for ground drops.

--- @section Imports

local objects = require("src.client.modules.objects")

--- @section Constants

local SPAWN_DISTANCE   = 30.0
local DESPAWN_DISTANCE = 35.0

--- @section Class

local Drops = {}
Drops.__index = Drops

--- @section Factory

function Drops.new()
    return setmetatable({
        drops = {}
    }, Drops)
end

--- @section CRUD

function Drops:init(data)
    if type(data) ~= "table" then return end
    for id, drop in pairs(data) do
        drop.entity = nil
        self.drops[id] = drop
    end
end

function Drops:add(data)
    if type(data) ~= "table" or not data.id then return end
    data.entity = nil
    self.drops[data.id] = data
end

function Drops:remove(id)
    local drop = self.drops[id]
    if not drop then return end
    if drop.entity then objects.remove(drop.entity) end
    self.drops[id] = nil
end

--- @section Streaming

function Drops:stream(player_coords)
    for id, drop in pairs(self.drops) do
        local pos = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        local dist = #(player_coords - pos)

        if dist < SPAWN_DISTANCE and not drop.entity then
            drop.entity = objects.create(drop.model, drop.coords)

        elseif dist >= DESPAWN_DISTANCE and drop.entity then
            objects.remove(drop.entity)
            drop.entity = nil
        end
    end
end

return Drops