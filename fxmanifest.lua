fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author "BOGi"
name "Simple vehicle market system"
description "The Underground - Simple vehicle market"
version "4.2.0"

shared_scripts {
    '@ox_lib/init.lua',
    'config/cfg_settings.lua',
    'config/cfg_locales.lua',
    'config/cfg_zones.lua',
    'config/cfg_vehicles.lua'
}


server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/sh_framework.lua',
    'server/sv_main.lua'
}

client_scripts {
    'bridge/sh_framework.lua',
    'bridge/sh_notify.lua',
    'client/cl_main.lua'
}

dependencies {
    'oxmysql',
    'ox_target',
    'ox_lib'
}
