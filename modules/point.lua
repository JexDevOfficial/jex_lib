-- One place in the world, described once. The blip, the ped, the marker
-- and the interaction all come from a single call, and the server owner
-- decides how the interaction looks.

Jex.Point = {}
local Point = Jex.Point

local registered = {}

local function setting(key, fallback)
    if Config and Config[key] ~= nil then return Config[key] end
    if JexConfig and JexConfig[key] ~= nil then return JexConfig[key] end
    return fallback
end

function Point.Register(opts)
    local coords = Jex.Util.Coords(opts.coords)

    local point = {
        id = opts.id,
        label = opts.label or '',
        coords = coords,
        within = opts.within or 2.5,
        options = opts.options,
        onEnter = opts.onEnter,
        onExit = opts.onExit,
        onNearby = opts.onNearby,
        inside = false,
    }

    if opts.blip then
        point.blip = Jex.Blip.Create {
            coords = coords,
            sprite = opts.blip.sprite,
            label = opts.blip.label or opts.label,
            scale = opts.blip.scale,
            colour = opts.blip.colour,
        }
    end

    if opts.npc then
        Jex.Npc.Register {
            model = opts.npc.model,
            coords = opts.npc.coords or coords,
            heading = opts.npc.heading,
            scenario = opts.npc.scenario,
            anim = opts.npc.anim,
            faces = opts.npc.faces,
            within = opts.npc.within or 60.0,
        }
    end

    if opts.marker then
        point.stopMarker = Jex.Marker.Loop(coords, {
            type = opts.marker.type,
            size = opts.marker.size,
            colour = opts.marker.colour,
            height = opts.marker.height,
            within = opts.marker.within or 15.0,
        })
    end

    -- Options mean it can be interacted with. How that looks is the
    -- server owner's choice, not the script's.
    if opts.options and #opts.options > 0 then
        point.interactId = Jex.Interact.Register {
            id = opts.id,
            coords = coords,
            radius = point.within,
            label = opts.label,
            options = opts.options,
        }
    end

    registered[#registered + 1] = point
    return point
end

function Point.RegisterMany(list, shared)
    local out = {}

    for _, opts in ipairs(list or {}) do
        if shared then
            for key, value in pairs(shared) do
                if opts[key] == nil then opts[key] = value end
            end
        end
        out[#out + 1] = Point.Register(opts)
    end

    return out
end

function Point.Remove(point)
    if not point then return end

    if point.blip then Jex.Blip.Remove(point.blip) end
    if point.stopMarker then point.stopMarker() end
    if point.interactId then Jex.Interact.Remove(point.interactId) end

    for i, existing in ipairs(registered) do
        if existing == point then
            table.remove(registered, i)
            break
        end
    end
end

function Point.RemoveAll()
    for _, point in ipairs(registered) do
        if point.blip then Jex.Blip.Remove(point.blip) end
        if point.stopMarker then point.stopMarker() end
    end

    registered = {}
    Jex.Interact.RemoveAll()
end

-- One thread for every point a script owns. Sleeps when nothing is near.
CreateThread(function()
    while true do
        local wait = 1000

        if #registered > 0 then
            local pos = GetEntityCoords(PlayerPedId())
            wait = 500

            for _, point in ipairs(registered) do
                local inside = #(pos - point.coords) <= point.within

                if inside and not point.inside then
                    point.inside = true
                    if point.onEnter then point.onEnter(point) end
                elseif not inside and point.inside then
                    point.inside = false
                    if point.onExit then point.onExit(point) end
                end

                if inside then
                    wait = 0
                    if point.onNearby then point.onNearby(point) end
                end
            end
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == Jex.resource then Point.RemoveAll() end
end)
