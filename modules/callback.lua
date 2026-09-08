
Jex.Callback = {}

local Callback = Jex.Callback
local RES = Jex.resource
local EVENT = ('jex:cb:%s'):format(RES)

local handlers = {}
local pending = {}
local nextId = 0

if IsDuplicityVersion() then

    function Callback.Register(name, cb)
        handlers[name] = cb
    end

    RegisterNetEvent(EVENT .. ':request', function(id, name, args)
        local src = source
        local handler = handlers[name]

        if not handler then
            Jex.Warn(('no callback registered for "%s"'):format(name))
            return TriggerClientEvent(EVENT .. ':response', src, id)
        end

        local ok, result = pcall(handler, src, table.unpack(args or {}))

        if not ok then
            Jex.Error(('callback "%s" failed: %s'):format(name, result))
            return TriggerClientEvent(EVENT .. ':response', src, id)
        end

        TriggerClientEvent(EVENT .. ':response', src, id, result)
    end)

else

    function Callback.Await(name, timeout, ...)
        nextId = nextId + 1
        local id = nextId

        pending[id] = { done = false }
        TriggerServerEvent(EVENT .. ':request', id, name, { ... })

        local deadline = GetGameTimer() + (timeout or 10000)

        while not pending[id].done do
            if GetGameTimer() > deadline then
                pending[id] = nil
                Jex.Warn(('callback "%s" timed out'):format(name))
                return nil
            end
            Wait(0)
        end

        local result = pending[id].result
        pending[id] = nil
        return result
    end

    RegisterNetEvent(EVENT .. ':response', function(id, result)
        local entry = pending[id]
        if not entry then return end
        entry.result = result
        entry.done = true
    end)

end
