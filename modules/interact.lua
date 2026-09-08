Jex.Interact = {}
local Interact = Jex.Interact

local function setting(key, fallback)
    if Config and Config[key] ~= nil then return Config[key] end
    if JexConfig and JexConfig[key] ~= nil then return JexConfig[key] end
    return fallback
end

local points = {}
local mode

local REACH = setting('InteractDistance', 2.5)

local ORDER = { 'jex_interact', 'ox_target', 'pc', 'murphy' }

local ADAPTERS = {
    jex_interact = {
        resource = 'jex_interact',
        add = function(point)
            exports.jex_interact:AddPoint {
                id = point.id,
                coords = point.coords,
                distance = point.radius or REACH,
                label = point.label,
                options = point.options,
            }
        end,
    },

    ox_target = {
        resource = 'ox_target',
        add = function(point)
            local options = {}

            for _, opt in ipairs(point.options) do
                options[#options + 1] = {
                    label = opt.label,
                    icon = opt.icon,
                    canInteract = opt.canInteract,
                    onSelect = opt.onSelect,
                }
            end

            exports.ox_target:addSphereZone {
                coords = point.coords,
                radius = point.radius or REACH,
                debug = false,
                options = options,
            }
        end,
    },

    pc = {
        resource = 'pc_interaction',
        add = function(point)
            local options = {}

            for _, opt in ipairs(point.options) do
                options[#options + 1] = {
                    text = opt.label,
                    canUse = opt.canInteract,
                    onSelect = opt.onSelect,
                }
            end

            exports.pc_interaction:GetApi().CreateInteraction(
                point.id, point.coords, options,
                (point.radius or REACH) * 3, point.radius or REACH)
        end,
    },

    murphy = {
        resource = 'murphy_interact',
        add = function(point)
            local options = {}

            for _, opt in ipairs(point.options) do
                options[#options + 1] = {
                    label = opt.label,
                    action = opt.onSelect,
                }
            end

            exports.murphy_interact:AddInteraction {
                id = point.id,
                coords = point.coords,
                options = options,
                interactDst = point.radius or REACH,
            }
        end,
    },
}

local function detect()
    local wanted = setting('Interaction', 'auto')

    if wanted ~= 'auto' then
        local adapter = ADAPTERS[wanted]

        if adapter and GetResourceState(adapter.resource) ~= 'started' then
            Jex.Warn(('Interaction is set to "%s" but %s is not running. Using prompts.')
                :format(wanted, adapter.resource))
            return 'prompt'
        end

        return wanted
    end

    for _, name in ipairs(ORDER) do
        if GetResourceState(ADAPTERS[name].resource) == 'started' then return name end
    end

    return 'prompt'
end

local pending = {}
local ready = false

--- Registers a place a player can interact with. How it appears is the
--- server owner's choice, not the script's.
---@param point table (`id`, `coords`, `radius`, `label`, `options`)
---@return string (The id, generated if you did not give one)
function Interact.Register(point)
    point.coords = Jex.Util.Coords(point.coords)
    point.options = point.options or {}
    point.id = point.id or ('%s:%d'):format(Jex.resource, #points + 1)

    points[#points + 1] = point

    if not ready then
        pending[#pending + 1] = point
        return point.id
    end

    local adapter = ADAPTERS[mode]

    if adapter then
        local ok, err = pcall(adapter.add, point)

        if not ok then
            Jex.Warn(('%s refused a point, falling back to prompts: %s'):format(mode, err))
            mode = 'prompt'
        end
    end

    return point.id
end

--- Registers several at once.
---@param list table (An array of points)
function Interact.RegisterMany(list)
    for _, point in ipairs(list or {}) do Interact.Register(point) end
end

--- Removes one interaction.
---@param id string (What Register returned)
---@return boolean (`true` if it was there)
function Interact.Remove(id)
    for i, point in ipairs(points) do
        if point.id == id then
            if point.prompts then point.prompts.Remove() end
            table.remove(points, i)
            return true
        end
    end

    return false
end

--- Removes everything this resource registered. Happens on its own when the
--- resource stops.
function Interact.RemoveAll()
    for _, point in ipairs(points) do
        if point.prompts then point.prompts.Remove() end
    end

    points = {}
end

--- Which interaction system was detected.
---@return string ('jex_interact', 'ox_target', 'pc', 'murphy' or 'prompt')
function Interact.Mode()
    return mode
end

CreateThread(function()
    Wait(500)

    mode = detect()
    ready = true

    Jex.Debug(('interaction: %s'):format(mode))

    for _, point in ipairs(pending) do
        if ADAPTERS[mode] then pcall(ADAPTERS[mode].add, point) end
    end

    pending = {}
end)

CreateThread(function()
    while true do
        local wait = 400

        if mode == 'prompt' and #points > 0 then
            local pos = GetEntityCoords(PlayerPedId())

            for _, point in ipairs(points) do
                local near = #(pos - point.coords) <= (point.radius or REACH)

                if near and not point.prompts then
                    point.prompts = Jex.Prompt.Build {
                        label = point.label,
                        options = point.options,
                    }
                end

                if near and point.prompts then
                    wait = 0
                    point.prompts.Show()

                    local chosen = point.prompts.Pressed()

                    if chosen and chosen.onSelect then
                        chosen.onSelect(point)
                        Wait(250)
                    end
                end
            end
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == Jex.resource then Interact.RemoveAll() end
end)
