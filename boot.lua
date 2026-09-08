
local function detect()
    local cores = {
        { 'rsg-core', 'RSG Core' },
        { 'vorp_core', 'VORP' },
        { 'redem_roleplay', 'RedEM:RP' },
    }

    for _, entry in ipairs(cores) do
        if GetResourceState(entry[1]) == 'started' then return entry[2] end
    end
end

local function inventory()
    local invs = {
        { 'rsg-inventory', 'rsg-inventory' },
        { 'vorp_inventory', 'vorp_inventory' },
        { 'redemrp_inventory', 'redemrp_inventory' },
    }

    for _, entry in ipairs(invs) do
        if GetResourceState(entry[1]) == 'started' then return entry[2] end
    end
end

exports('Notify', function(src, text, kind, duration, title)
    if not src then return end
    TriggerClientEvent('jex:notify', src, text, kind, duration, title)
end)

exports('NotifyAll', function(text, kind, duration, title)
    TriggerClientEvent('jex:notify', -1, text, kind, duration, title)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateThread(function()
        Wait(2000)

        local core = detect()
        local inv = inventory()
        local version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'

        print(('^2[jex_lib]^7 v%s'):format(version))

        if core then
            print(('^2[jex_lib]^7 detected ^5%s^7 with ^5%s^7'):format(core, inv or 'its own inventory'))
        else
            print('^3[jex_lib]^7 no supported framework found. Scripts will use the custom bridge -'
                .. ' fill in jex_lib/core/custom.lua if you are not on VORP, RSG or RedEM:RP.')
        end

        if GetResourceState('oxmysql') ~= 'started' then
            print('^3[jex_lib]^7 oxmysql is not running. Anything that stores data will not work.')
        end
    end)
end)
