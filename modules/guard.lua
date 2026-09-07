-- Server-side checks. The client sends intent; this decides.
-- Every one of these returns false rather than throwing, so a refused
-- action is a quiet no, not a stack trace in somebody's console.

Jex.Guard = {}
local Guard = Jex.Guard

local buckets = {}

-- How far a player can be from a point and still be considered at it.
-- Generous on purpose: positions lag, and a false refusal is worse than
-- a metre of slack.
local REACH = 4.0

function Guard.Loaded(src)
    return Jex.Core.IsLoaded(src) == true
end

function Guard.Near(src, coords, within)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    return Jex.Util.Distance(GetEntityCoords(ped), coords) <= (within or REACH)
end

function Guard.Job(src, jobs, minGrade)
    return Jex.Core.HasJob(src, jobs, minGrade)
end

function Guard.CanAfford(src, account, amount)
    return Jex.Core.GetMoney(src, account) >= (tonumber(amount) or 0)
end

function Guard.HasItem(src, item, amount)
    return Jex.Core.HasItem(src, item, amount or 1)
end

-- Owning a record is a question only the script can answer, so it hands
-- us the lookup and we do the comparing.
function Guard.Owns(src, lookup)
    local id = Jex.Core.GetIdentifier(src)
    if not id then return false end

    local owner = lookup(id)
    return owner ~= nil and owner == id
end

function Guard.Str(value, maxLength)
    if type(value) ~= 'string' then return nil end

    local clean = Jex.Util.Clean(value, maxLength or 255)
    return clean ~= '' and clean or nil
end

function Guard.Int(value, min, max)
    local n = tonumber(value)
    if not n or n ~= n then return nil end

    n = math.floor(n)
    if min and n < min then return nil end
    if max and n > max then return nil end

    return n
end

function Guard.OneOf(value, allowed)
    for _, entry in ipairs(allowed or {}) do
        if value == entry then return value end
    end
    return nil
end

-- Per player, per action. Stops an injected event being fired in a loop.
function Guard.Rate(src, action, perMinute)
    local key = ('%s:%s'):format(src, action)
    local now = GetGameTimer()
    local window = 60000
    local limit = perMinute or 20

    local bucket = buckets[key]

    if not bucket or now - bucket.since > window then
        buckets[key] = { since = now, count = 1 }
        return true
    end

    if bucket.count >= limit then return false end

    bucket.count = bucket.count + 1
    return true
end

AddEventHandler('playerDropped', function()
    local src = tostring(source)
    for key in pairs(buckets) do
        if key:sub(1, #src + 1) == src .. ':' then buckets[key] = nil end
    end
end)

-- The usual set, in one call. Returns false and notifies on the first
-- failure, so a handler reads as: if not Jex.Guard.Check(...) then return end
function Guard.Check(src, opts)
    opts = opts or {}

    if not Guard.Loaded(src) then return false end

    if opts.rate and not Guard.Rate(src, opts.rate, opts.perMinute) then
        return false
    end

    if opts.coords and not Guard.Near(src, opts.coords, opts.within) then
        Jex.Core.Notify(src, 'You are too far away.', 'error')
        return false
    end

    if opts.job and not Guard.Job(src, opts.job, opts.grade) then
        Jex.Core.Notify(src, 'You are not allowed to do that.', 'error')
        return false
    end

    if opts.cost and not Guard.CanAfford(src, opts.account or 'cash', opts.cost) then
        Jex.Core.Notify(src, 'You cannot afford that.', 'error')
        return false
    end

    if opts.item and not Guard.HasItem(src, opts.item, opts.amount) then
        Jex.Core.Notify(src, 'You do not have what you need.', 'error')
        return false
    end

    return true
end
