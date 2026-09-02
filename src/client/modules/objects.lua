--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module objects
--- @file src/client/modules/objects.lua
--- @description Handles creating and removing world objects.

if rawget(_G, "__objects_module") then
    return _G.__objects_module
end

local objects = {}
_G.__objects_module = objects

--- @section State

local created_entities = {}

--- @section Helpers

local function request_model(model, timeout)
    if HasModelLoaded(model) then return true end
    
    RequestModel(model)
    local start = GetGameTimer()
    local max_wait = timeout or 10000
    
    while not HasModelLoaded(model) do
        if GetGameTimer() - start > max_wait then
            print(("[requests] Model load timeout: %s"):format(model))
            return false
        end
        Wait(0)
    end
    
    return true
end

--- @section API

function objects.create(model, coords)
    local model_hash = GetHashKey(model)
    if not request_model(model_hash) then
        print(("[objects] Failed to load model: %s"):format(model))
        return nil
    end
    local entity = CreateObject(model_hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, coords.w or 0.0)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    SetModelAsNoLongerNeeded(model_hash)
    created_entities[entity] = true
    return entity
end

function objects.remove(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
        created_entities[entity] = nil
    end
end

function objects.track_entity(entity)
    if entity then created_entities[entity] = true end
end

function objects.cleanup_all()
    for entity in pairs(created_entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    created_entities = {}
end

AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() == resource then
        objects.cleanup_all()
    end
end)

return objects