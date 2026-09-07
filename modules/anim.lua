Jex.Anim = {}
local Anim = Jex.Anim

function Anim.RequestDict(dict, timeout)
    if HasAnimDictLoaded(dict) then return true end

    RequestAnimDict(dict)

    local deadline = GetGameTimer() + (timeout or 5000)
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > deadline then
            Jex.Warn(('animation dict "%s" never loaded'):format(dict))
            return false
        end
        Wait(10)
    end

    return true
end

function Anim.Play(dict, name, opts)
    opts = opts or {}
    if not Anim.RequestDict(dict) then return false end

    TaskPlayAnim(PlayerPedId(), dict, name,
        opts.blendIn or 8.0, opts.blendOut or -8.0,
        opts.duration or -1, opts.flag or 1,
        0.0, false, false, false)

    return true
end

function Anim.PlayAndWait(dict, name, ms, opts)
    if not Anim.Play(dict, name, opts) then return false end
    Wait(ms or 2000)
    Anim.Stop()
    return true
end

function Anim.Stop(ped)
    ClearPedTasks(ped or PlayerPedId())
end

function Anim.Scenario(name, duration)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, GetHashKey(name), duration or -1, true, false, false, false)
end
