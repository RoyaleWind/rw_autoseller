fx_version 'adamant'
game 'gta5'
author 'RoyaleWind'
description 'RW vending machine'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server.lua',
	'config.lua',
	'sv_item.lua',
}
  
client_scripts {
	'client/main.lua',
	'config.lua'
}
