fx_version 'cerulean'
game 'gta5'

author 'Dingos Development :: Developer: Johnny'
description 'AI Medic Script for QBCore'
version '1.0.0'

-- Shared configuration
shared_script 'config.lua'

-- Client-side scripts
client_scripts {
    'client.lua'
}

-- Server-side scripts
server_scripts {
    '@qb-core/server/main.lua',
    'server.lua'
}

-- For custom scripts join the link below your first order is on us
-- https://discord.gg/mQQ2D28XqK
