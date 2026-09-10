--- @section Imports

local _vehicles = require("configs.vehicles")

local m = {}

--- @section Inventory

local VEHICLE_CLASSES = {
    [0] = "compact", [1] = "sedan", [2] = "suv", [3] = "coupe",
    [4] = "muscle", [5] = "sports", [6] = "super", [7] = "motorcycle",
    [8] = "offroad", [9] = "industrial", [10] = "utility", [11] = "van",
    [12] = "cycle", [13] = "boat", [14] = "helicopter", [15] = "plane",
    [16] = "service", [17] = "emergency", [18] = "military",
    [19] = "commercial", [20] = "train"
}

function m.get_vehicle_class_name(class_id)
    return VEHICLE_CLASSES[class_id] or "sedan"
end

function m.get_vehicle_config(vehicle)
    if not DoesEntityExist(vehicle) then return nil, nil end
    local model_name = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    local class_name = m.get_vehicle_class_name(GetVehicleClass(vehicle))
    if _vehicles[model_name] then
        return _vehicles[model_name].trunk, _vehicles[model_name].glovebox
    end
    if _vehicles.vehicle_defaults and _vehicles.vehicle_defaults[class_name] then
        return _vehicles.vehicle_defaults[class_name].trunk, _vehicles.vehicle_defaults[class_name].glovebox
    end
    return nil, nil
end

function m.is_rear_engine(vehicle)
    if not _vehicles or not _vehicles.rear_engine then return false end
    local model_name = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    return _vehicles.rear_engine[model_name] == true
end

function m.get_nearby_vehicle(radius)
    radius = radius or 2.5
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, radius, 0, 70)
    if not DoesEntityExist(vehicle) then return nil, nil end
    local bone_index = m.is_rear_engine(vehicle) and GetEntityBoneIndexByName(vehicle, "engine") or GetEntityBoneIndexByName(vehicle, "boot")
    if bone_index ~= -1 then
        local bone_coords = GetWorldPositionOfEntityBone(vehicle, bone_index)
        if #(coords - bone_coords) <= radius then
            return vehicle, "trunk"
        end
    end
    return nil, nil
end

function m.get_current_vehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        return vehicle, "glovebox"
    end
    return nil, nil
end

function m.get_accessible_vehicle_inventory()
    local vehicle, veh_type = m.get_current_vehicle()
    if vehicle then
        local _, glovebox_config = m.get_vehicle_config(vehicle)
        return vehicle, veh_type, glovebox_config
    end
    vehicle, veh_type = m.get_nearby_vehicle(2.5)
    if vehicle then
        local trunk_config = m.get_vehicle_config(vehicle)
        return vehicle, veh_type, trunk_config
    end
    return nil, nil, nil
end

function m.set_vehicle_trunk_state(vehicle, inv_type, open)
    if not DoesEntityExist(vehicle) then return end
    if inv_type == "trunk" then
        local door = m.is_rear_engine(vehicle) and 4 or 5
        if open then SetVehicleDoorOpen(vehicle, door, false, false)
        else SetVehicleDoorShut(vehicle, door, false) end
    end
end

return m