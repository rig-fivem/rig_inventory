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
version "0.2.0"
description "Player inventory system for RIG (FiveM)."
license "Apache 2.0"
author "Case"
lua54 "yes"

ui_page "ui/index.html"
files {
    "locales/*.json",
    "ui/**/*",
    "images/*.png"
}

shared_scripts {
    "init.lua",
    "configs/**/*.lua",
    "src/shared/data/*.lua"
}

client_scripts {
    "src/client/registry/*.lua",
    "src/client/modules/*.lua",
    "src/client/nui/*.lua",
    "src/client/main.lua"
}
server_scripts {
    "src/server/registry/*.lua",
    "src/server/modules/**/*.lua",
    "src/server/main.lua",
    "src/server/commands.lua"
}

dependency "rig"