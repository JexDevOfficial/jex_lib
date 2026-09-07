-- Loaded by every Jex script:
--
--   shared_scripts { '@jex_lib/init.lua' }
--
-- Everything then lives on the Jex global. Each script gets its own
-- copy in its own Lua state, so Jex holds behaviour, never shared state.

local LIB = 'jex_lib'
local script = GetCurrentResourceName()

if GetResourceState(LIB) ~= 'started' then
    error(("%s needs jex_lib. Put 'ensure jex_lib' above it in server.cfg."):format(script), 0)
end

Jex = {
    resource = script,
    version = GetResourceMetadata(LIB, 'version', 0) or '0.0.0',
}

local function tag(colour, msg)
    print(('^%d[%s]^7 %s'):format(colour, script, msg))
end

function Jex.Print(msg) tag(2, msg) end
function Jex.Warn(msg) tag(3, msg) end
function Jex.Error(msg) tag(1, msg) end

function Jex.Debug(msg)
    local on = Config and Config.Debug
    if on == nil then on = JexConfig and JexConfig.Debug end
    if on then tag(6, msg) end
end

local function load_file(path)
    local chunk = LoadResourceFile(LIB, path)
    if not chunk then
        return Jex.Warn(('missing jex_lib/%s'):format(path))
    end

    local fn, err = load(chunk, ('@@%s/%s'):format(LIB, path))
    if not fn then
        return Jex.Error(('jex_lib/%s failed to parse: %s'):format(path, err))
    end

    local ok, ferr = pcall(fn)
    if not ok then
        Jex.Error(('jex_lib/%s failed to run: %s'):format(path, ferr))
    end
end

local server = IsDuplicityVersion()

load_file('version.lua')
load_file('config.lua')

-- Compare against the library, not against ourselves - a bundled copy
-- can be older than the one actually installed.
function Jex.Require(min)
    local function parts(v)
        local t = {}
        for n in tostring(v):gmatch('%d+') do t[#t + 1] = tonumber(n) end
        return t
    end

    local has, want = parts(Jex.version), parts(min)

    for i = 1, math.max(#has, #want) do
        local a, b = has[i] or 0, want[i] or 0
        if a > b then return true end
        if a < b then
            error(('%s needs jex_lib %s or newer. This server has %s.\n'
                .. 'Latest release: github.com/JexDevOfficial/jex_lib/releases')
                :format(script, min, Jex.version), 0)
        end
    end

    return true
end

load_file('core/detect.lua')
load_file('core/contract.lua')

-- Only the detected adapter is loaded. A VORP server never parses RSG
-- code, so a core that is not installed cannot throw on load.
load_file(('core/%s.lua'):format(Jex.core))

load_file('modules/util.lua')
load_file('modules/callback.lua')

if server then
    load_file('modules/db.lua')
    load_file('modules/guard.lua')
else
    load_file('modules/anim.lua')
    load_file('modules/blip.lua')
    load_file('modules/npc.lua')
    load_file('modules/marker.lua')
    load_file('modules/prompt.lua')
    load_file('modules/point.lua')
end

if Jex.CheckContract then Jex.CheckContract() end
