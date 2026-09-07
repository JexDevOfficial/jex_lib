-- jex_lib's own client. Notifications have to exist exactly once on a
-- server rather than once per script, so this owns the routing and
-- every script reaches it through the jex:notify event.
--
-- Ours is the fallback, not the point. If the server runs a notification
-- resource it chose, that is what Jex scripts use - same as interaction.

local settings = { style = 'auto', position = 'top-right', max = 4 }

local chunk = LoadResourceFile(GetCurrentResourceName(), 'config.lua')
if chunk then
    local fn = load(chunk)
    if fn and pcall(fn) and JexConfig then
        settings.style = JexConfig.Notify or settings.style
        settings.position = JexConfig.NotifyPosition or settings.position
        settings.max = JexConfig.NotifyMax or settings.max
    end
end

local TYPES = { success = true, error = true, warning = true, info = true }

-- Checked in this order, and only if the resource is running.
-- jex_notifications first: if somebody installed ours, that is the one
-- they meant to use.
local ORDER = { 'jex_notifications', 'ox_lib', 'vorp', 'redem' }

local ADAPTERS = {
    jex_notifications = {
        resource = 'jex_notifications',
        send = function(text, kind, duration, title)
            exports.jex_notifications:Show {
                text = text,
                type = kind,
                duration = duration,
                title = title,
            }
        end,
    },

    ox_lib = {
        resource = 'ox_lib',
        send = function(text, kind, duration, title)
            TriggerEvent('ox_lib:notify', {
                title = title,
                description = text,
                type = kind,
                duration = duration,
            })
        end,
    },

    vorp = {
        resource = 'vorp_core',
        send = function(text, _, duration)
            exports.vorp_core:ShowAdvancedRightNotification(text, 'generic_textures', 'tick', 'COLOR_WHITE', duration)
        end,
    },

    redem = {
        resource = 'redem_roleplay',
        send = function(text, _, duration)
            exports.redem_roleplay:showNotification(text, duration)
        end,
    },
}

local route

local function detect()
    local wanted = settings.style

    if wanted ~= 'auto' then
        local adapter = ADAPTERS[wanted]

        -- Say so now rather than silently using something else the first
        -- time a script tries to notify somebody.
        if adapter and GetResourceState(adapter.resource) ~= 'started' then
            Jex.Warn(('Notify is set to "%s" but %s is not running. Using ours.')
                :format(wanted, adapter.resource))
            return 'jex'
        end

        return wanted
    end

    for _, name in ipairs(ORDER) do
        if GetResourceState(ADAPTERS[name].resource) == 'started' then return name end
    end

    return 'jex'
end

local function notify(text, kind, duration, title)
    if not text or text == '' then return end

    kind = TYPES[kind] and kind or 'info'
    duration = tonumber(duration) or 4000

    local adapter = ADAPTERS[route]

    if adapter then
        local ok, err = pcall(adapter.send, text, kind, duration, title)
        if ok then return end

        Jex.Warn(('%s refused a notification, using ours: %s'):format(route, err))
        route = 'jex'
    end

    SendNUIMessage {
        action = 'notify',
        text = text,
        type = kind,
        title = title,
        duration = duration,
    }
end

RegisterNetEvent('jex:notify', notify)
AddEventHandler('jex:notify', notify)

-- Open to anything on the server, not just Jex scripts.
exports('Notify', function(text, kind, duration, title)
    notify(text, kind, duration, title)
end)

CreateThread(function()
    Wait(500)

    route = detect()

    SendNUIMessage { action = 'config', position = settings.position, max = settings.max }
end)
