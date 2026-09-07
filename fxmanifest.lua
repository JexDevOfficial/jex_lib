fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'jex_lib'
author 'jex.dev'
description 'Shared library for Jex scripts. Detects your framework on start.'
version '1.0.0'
repository 'https://github.com/JexDevOfficial/jex_lib'

lua54 'yes'

ui_page 'nui/index.html'

-- Anything loaded through init.lua has to be listed here, or the client
-- cannot read it.
files {
    'init.lua',
    'config.lua',
    'core/*.lua',
    'modules/*.lua',
    'nui/index.html',
    'nui/style.css',
    'nui/app.js',
}

server_script 'boot.lua'
client_script 'client.lua'
