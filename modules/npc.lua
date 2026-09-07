Jex.Npc = {}
local Npc = Jex.Npc

local spawned = {}
local registered = {}

local function requestModel(model, timeout)
    local hash = type(model) == 'string' and GetHashKey(model) or model

    if HasModelLoaded(hash) then return hash end
    RequestModel(hash)

    local deadline = GetGameTimer() + (timeout or 5000)
    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then
            Jex.Warn(('ped model "%s" never loaded'):format(tostring(model)))
            return nil
        end
        Wait(10)
    end

    return hash
end

function Npc.Create(opts)
    local hash = requestModel(opts.model)
    if not hash then return nil end

    local c = Jex.Util.Coords(opts.coords)
    local ped = CreatePed(hash, c.x, c.y, c.z - 1.0, opts.heading or 0.0, false, false, false, false)

    Wait(0)

    -- Without this they wander off, get shot, or react to the player.
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedCanRagdoll(ped, false)

    if opts.scenario then
        TaskStartScenarioInPlace(ped, GetHashKey(opts.scenario), -1, true, false, false, false)
    elseif opts.anim then
        Jex.Anim.RequestDict(opts.anim.dict)
        TaskPlayAnim(ped, opts.anim.dict, opts.anim.name, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end

    SetModelAsNoLongerNeeded(hash)
    spawned[#spawned + 1] = ped

    return ped
end

function Npc.CreateMany(list)
    local out = {}
    for _, opts in ipairs(list or {}) do
        out[#out + 1] = Npc.Create(opts)
    end
    return out
end

-- Spawns when the player gets close and despawns when they leave, so a
-- server with a hundred of these only ever has the nearby ones loaded.
function Npc.Register(opts)
    local entry = {
        opts = opts,
        coords = Jex.Util.Coords(opts.coords),
        within = opts.within or 60.0,
        ped = nil,
    }

    registered[#registered + 1] = entry
    return entry
end

function Npc.RegisterMany(list)
    for _, opts in ipairs(list or {}) do Npc.Register(opts) end
end

function Npc.FaceCoords(ped, coords)
    local c = Jex.Util.Coords(coords)
    local p = GetEntityCoords(ped)
    SetEntityHeading(ped, GetHeadingFromVector_2d(c.x - p.x, c.y - p.y))
end

function Npc.Remove(ped)
    if not ped or not DoesEntityExist(ped) then return end

    DeleteEntity(ped)

    for i, existing in ipairs(spawned) do
        if existing == ped then
            table.remove(spawned, i)
            break
        end
    end
end

function Npc.RemoveAll()
    for _, ped in ipairs(spawned) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    spawned = {}

    for _, entry in ipairs(registered) do entry.ped = nil end
end

-- One thread for every registered ped. Idles at half a second when
-- nothing is close.
CreateThread(function()
    while true do
        local wait = 1000

        if #registered > 0 then
            local pos = GetEntityCoords(PlayerPedId())

            for _, entry in ipairs(registered) do
                local near = #(pos - entry.coords) < entry.within

                if near and not entry.ped then
                    entry.ped = Npc.Create(entry.opts)
                    if entry.opts.faces then Npc.FaceCoords(entry.ped, entry.opts.faces) end
                elseif not near and entry.ped then
                    Npc.Remove(entry.ped)
                    entry.ped = nil
                end
            end

            wait = 500
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == Jex.resource then Npc.RemoveAll() end
end)
