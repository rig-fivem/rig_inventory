--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

--- @module nui
--- @file src/client/modules/nui.lua
--- @description Handles core NUI stuff; notifications, modals, ui framework etc.

--- @section Guard

if rawget(_G, "__client_nui_module") then
    return _G.__client_nui_module
end

--- @section Initialisation

local m = {}
_G.__client_nui_module = m

local functions = {}

--- @section Functions

function m.has_function(label)
    return functions[label] ~= nil
end

function m.register_function(label, func)
    functions[label] = func
end

function m.call_registered_function(label, data)
    if not label then
        log("error", "nui: label is required")
        return false
    end

    local func = functions[label]
    if not func then
        log("error", ("nui: no function registered for label '%s'"):format(label))
        return false
    end

    return func(data)
end

function m.sanitize(data, path)
    path = path or "root"
    local out = {}

    for k, v in pairs(data) do
        local p = ("%s_%s"):format(path, tostring(k)):gsub("[^%w_]", "")

        if (k == "on_action" or k == "on_increment" or k == "on_decrement" or k == "on_select") then
            m.register_function(p, v)
            out.action = p
        elseif type(v) == "table" then
            out[k] = m.sanitize(v, p)
        else
            out[k] = v
        end
    end

    return out
end

--- @section Modal

function m.build_modal(opts)
    if not opts then
        log("error", "nui: build_modal called with missing opts")
        return
    end

    local safe_opts = m.sanitize(opts, "modal")
    if not safe_opts then
        log("error", "nui: build_modal sanitize failed")
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        func = "build_modal",
        payload = safe_opts
    })
end

function m.close_modal(container)
    SetNuiFocus(false, false)
    SendNUIMessage({
        func = "remove_modal",
        payload = { container = container }
    })
end

--- @section UI Framework

function m.build_ui(ui)
    if not ui then
        log("error", "nui: build_ui called with missing ui")
        return
    end

    local safe_ui = m.sanitize(ui, "ui")
    if not safe_ui then
        log("error", "nui: build_ui sanitize failed")
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ func = "build_ui", payload = safe_ui })
end

function m.close_ui()
    SendNUIMessage({ func = "close_ui" })
    SetNuiFocus(false, false)
end

--- @section Headshot

function m.get_player_headshot(player_ped)
    player_ped = player_ped or PlayerPedId()
    local headshot = RegisterPedheadshotTransparent(player_ped)
    if not (headshot and IsPedheadshotValid(headshot)) then
        return nil
    end

    local timeout, txd = 1000, nil
    while not IsPedheadshotReady(headshot) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    if IsPedheadshotReady(headshot) then
        txd = GetPedheadshotTxdString(headshot)
        SetTimeout(2000, function() UnregisterPedheadshot(headshot) end)
    else
        UnregisterPedheadshot(headshot)
    end

    return txd and ("https://nui-img/%s/%s?v=%d"):format(txd, txd, GetGameTimer())
end

--- @section Inventory

function m.update_slots(items)
    if type(items) ~= "table" then
        log("warn", "update_slots: invalid items table")
        return
    end

    local safe_items = m.sanitize(items, "inventory_update")

    SendNUIMessage({ func = "update_slots", items = safe_items })
end

function m.update_grid(items, section_key)
    if type(items) ~= "table" then
        log("warn", "update_grid: invalid items table")
        return
    end

    local safe_items = m.sanitize(items, "inventory_update")

    SendNUIMessage({ func = "update_grid", items = safe_items, section_key = section_key })
end

--- @section Popup

function m.inventory_popup(data)
    if not data then return end
    SendNUIMessage({
        func = "inventory_popup",
        payload = data
    })
end

--- @section NUI Callbacks

RegisterNUICallback("nui:remove_focus", function()
    log("info", "nui: focus cleared")
    SetNuiFocus(false, false)
end)

RegisterNUICallback("nui:handler", function(data, cb)
    log("info", ("nui: handler invoked with %s"):format(json.encode(data)))

    if not data or not data.action then
        if cb then cb(false) end
        return
    end

    if data.action == "grid_moved_item" then
        TriggerServerEvent("rig_inventory:server:move_item", data.dataset)
        if cb then cb({ success = true }) end
        return
    end

    if m.has_function(data.action) then
        local success, result = pcall(m.call_registered_function, data.action, data)
        if not success then
            log("error", ("nui: handler failed for action '%s': %s"):format(data.action, result))
        end
    else
        TriggerServerEvent("rig:server:nui_handler", data)
    end

    if data.should_close then
        SetNuiFocus(false, false)
    end

    if cb then cb(true) end
end)

--- @section Events

RegisterNetEvent("rig_inventory:client:remove_focus", function()
    SetNuiFocus(false, false)
end)

RegisterNetEvent("rig_inventory:client:build_modal", function(opts)
    if not opts then return log("error", "nui: build_modal event missing opts") end

    m.build_modal(opts)
end)

RegisterNetEvent("rig_inventory:client:close_modal", function(container)
    if not container then container = "#ui_focus" end
    m.close_modal(container)
end)

RegisterNetEvent("rig_inventory:client:build_ui", function(opts)
    if not opts then return log("error", "nui: build_ui event missing opts") end

    m.build_ui(opts)
end)

RegisterNetEvent("rig_inventory:client:close_ui", function()
    m.close_ui()
end)

RegisterNetEvent("rig_inventory:client:inventory_popup", function(data)
    m.inventory_popup(data)
end)

--- @section Exports

exports("build_modal", m.build_modal)
exports("close_modal", m.close_modal)

exports("build_ui", m.build_ui)
exports("close_ui", m.close_ui)

exports("inventory_popup", m.inventory_popup)

return m