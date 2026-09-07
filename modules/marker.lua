Jex.Marker = {}
local Marker = Jex.Marker

Marker.Types = {
    cylinder = 0x94FDAE17,
    ring = 0x50638AB9,
    arrow = 0x36B1B3E7,
    star = 0x2ADB4A2A,
    point = 0x1E1E1E1E,
}

function Marker.Draw(coords, opts)
    opts = opts or {}
    local c = Jex.Util.Coords(coords)
    local size = opts.size or 1.0
    local rgba = opts.colour or { 183, 255, 60, 100 }

    Citizen.InvokeNative(0x2A32FAA57B937173,
        opts.type or Marker.Types.cylinder,
        c.x, c.y, c.z - (opts.drop or 0.95),
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        size, size, opts.height or 0.5,
        rgba[1], rgba[2], rgba[3], rgba[4],
        false, false, 2, false, nil, nil, false)
end

-- Draws while the player is close and stops when they leave. Sleeps
-- when nobody is near, so an idle marker costs nothing.
function Marker.Loop(coords, opts)
    opts = opts or {}
    local c = Jex.Util.Coords(coords)
    local within = opts.within or 15.0
    local stopped = false

    CreateThread(function()
        while not stopped do
            local wait = 500
            local ped = PlayerPedId()

            if #(GetEntityCoords(ped) - c) < within then
                wait = 0
                Marker.Draw(c, opts)
            end

            Wait(wait)
        end
    end)

    return function() stopped = true end
end
