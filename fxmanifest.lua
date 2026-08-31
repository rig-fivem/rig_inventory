--[[
----------------------------------------
RIG Inventory (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_inventory
License: https://github.com/rig-fivem/rig_inventory/blob/main/LICENSE
----------------------------------------
]]

fx_version "cerulean"
games { "gta5" }
name "rig_inventory"
version "0.1.0"
description "Player inventory system for RIG (FiveM)."
license "Apache 2.0"
author "Case"
lua54 "yes"

ui_page "ui/index.html"
files {
    "locales/*.json",
    "ui/**/*"
}

shared_scripts {
    "configs/*.lua",
    "init.lua"
}
client_scripts {
    "src/client/modules/*.lua",
    "src/client/nui/*.lua",
    "src/client/main.lua"
}
server_scripts {
    "src/server/main.lua"
}

dependency "rig"