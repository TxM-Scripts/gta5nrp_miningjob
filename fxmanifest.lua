fx_version 'cerulean'
game 'gta5'

author 'gta5nrp_miningjob'
description 'Mining Job with custom minigame'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/scripts.js',
    'html/index.css'
}
