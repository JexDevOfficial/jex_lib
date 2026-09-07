Jex.Util = {}
local Util = Jex.Util

function Util.Round(n, places)
    local mult = 10 ^ (places or 0)
    return math.floor((tonumber(n) or 0) * mult + 0.5) / mult
end

function Util.Comma(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    return (out:gsub('^,', ''))
end

function Util.Coords(v)
    if not v then return vector3(0.0, 0.0, 0.0) end
    if v.x then return vector3(v.x + 0.0, v.y + 0.0, (v.z or 0.0) + 0.0) end
    return vector3(v[1] + 0.0, v[2] + 0.0, (v[3] or 0.0) + 0.0)
end

function Util.Distance(a, b)
    return #(Util.Coords(a) - Util.Coords(b))
end

function Util.Near(a, b, within)
    return Util.Distance(a, b) <= (within or 2.0)
end

function Util.Closest(from, list, within)
    local best, bestDist

    for i, entry in ipairs(list or {}) do
        local d = Util.Distance(from, entry.coords or entry)
        if (not bestDist or d < bestDist) and (not within or d <= within) then
            best, bestDist = i, d
        end
    end

    return best, bestDist
end

-- Waits for the framework to finish loading. Anything touching player
-- data at resource start needs this, or it races the core.
function Jex.Wait(timeout)
    local deadline = GetGameTimer() + (timeout or 30000)

    while GetGameTimer() < deadline do
        if Jex.Core and Jex.Core.IsLoaded then
            local ok, loaded = pcall(Jex.Core.IsLoaded, IsDuplicityVersion() and 0 or nil)
            if ok and loaded ~= nil then return true end
        end
        Wait(200)
    end

    Jex.Warn('gave up waiting for the framework to load')
    return false
end

function Util.Trim(s)
    return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Anything a player typed goes through this before it is stored or
-- shown to somebody else.
function Util.Clean(s, maxLength)
    s = Util.Trim(s):gsub('[%c]', '')
    local max = maxLength or 255
    if #s > max then s = s:sub(1, max) end
    return s
end

function Util.Id(length)
    local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    local out = {}
    for i = 1, (length or 6) do
        local n = math.random(#chars)
        out[i] = chars:sub(n, n)
    end
    return table.concat(out)
end
