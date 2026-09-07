-- Written against vorp_core and vorp_inventory source. Not yet run on a
-- live VORP server - anything that could differ is wrapped so it fails
-- soft rather than taking the resource down.

local Core = Jex.Core
local VORP = exports.vorp_core:GetCore()

-- VORP numbers its currencies instead of naming them.
local CURRENCY = { cash = 0, bank = 0, gold = 1, rol = 2 }

local server = IsDuplicityVersion()

local function char(src)
    local user = VORP.getUser(src)
    return user and user.getUsedCharacter or nil
end

-- Nothing here has been run against a live VORP server, so every call
-- into it goes through this. A wrong guess degrades instead of taking
-- the resource down on somebody else's server.
local function try(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    Jex.Debug(('vorp call failed: %s'):format(result))
    return fallback
end

if server then

    function Core.IsLoaded(src)
        return char(src) ~= nil
    end

    function Core.GetIdentifier(src)
        local c = char(src)
        return c and tostring(c.charIdentifier) or nil
    end

    function Core.GetName(src)
        local c = char(src)
        if not c then return '' end
        return Jex.Util.Trim(('%s %s'):format(c.firstname or '', c.lastname or ''))
    end

    function Core.GetCharInfo(src)
        local c = char(src)
        if not c then return Core.EmptyCharInfo() end
        return {
            firstname = c.firstname or '',
            lastname = c.lastname or '',
            birthdate = c.age and tostring(c.age) or '',
            gender = c.gender or 0,
        }
    end

    -- VORP has no gangs. Jobs carry a grade and a label and nothing else.
    function Core.GetJob(src)
        local c = char(src)
        if not c then return Core.EmptyJob() end
        return {
            name = c.job or 'unemployed',
            label = c.jobLabel or c.job or '',
            grade = tonumber(c.jobGrade) or 0,
            gradeLabel = '',
            onDuty = true,
            isBoss = false,
        }
    end

    function Core.GetGang()
        return Core.EmptyGang()
    end

    function Core.HasJob(src, jobs, minGrade)
        local job = Core.GetJob(src)
        if type(jobs) == 'string' then jobs = { jobs } end

        for _, name in ipairs(jobs or {}) do
            if job.name == name then return job.grade >= (minGrade or 0) end
        end

        return false
    end

    function Core.GetPlayers()
        local out = {}
        for _, user in pairs(try(function() return VORP.getUsers() end, {}) or {}) do
            local src = user.source or user
            if tonumber(src) then out[#out + 1] = tonumber(src) end
        end
        return out
    end

    function Core.GetMoney(src, account)
        local c = char(src)
        if not c then return 0 end
        if account == 'gold' then return tonumber(c.gold) or 0 end
        return tonumber(c.money) or 0
    end

    -- No reason field on this core, so it is accepted and dropped.
    function Core.AddMoney(src, account, amount, _)
        local c = char(src)
        if not c or (tonumber(amount) or 0) <= 0 then return false end

        return try(function()
            c.addCurrency(CURRENCY[account] or 0, amount)
            return true
        end, false)
    end

    function Core.RemoveMoney(src, account, amount, _)
        local c = char(src)
        if not c or (tonumber(amount) or 0) <= 0 then return false end
        if Core.GetMoney(src, account) < amount then return false end

        return try(function()
            c.removeCurrency(CURRENCY[account] or 0, amount)
            return true
        end, false)
    end

    function Core.AddItem(src, item, amount, meta)
        return try(function()
            exports.vorp_inventory:addItem(src, item, amount or 1, meta)
            return true
        end, false)
    end

    function Core.RemoveItem(src, item, amount, meta)
        return try(function()
            exports.vorp_inventory:subItem(src, item, amount or 1, meta)
            return true
        end, false)
    end

    function Core.GetItems(src)
        local items = try(function()
            return exports.vorp_inventory:getUserInventoryItems(src)
        end, {}) or {}

        local out = {}
        for _, it in pairs(items) do
            if type(it) == 'table' and it.name then
                out[#out + 1] = Core.Item {
                    name = it.name, label = it.label, amount = it.count or it.amount,
                    slot = it.slot, weight = it.weight, type = it.type,
                    unique = it.limit == 1, useable = it.usable,
                    meta = it.metadata, image = it.name .. '.png',
                }
            end
        end

        return out
    end

    function Core.GetItemCount(src, item)
        return try(function()
            return exports.vorp_inventory:getItemCount(src, nil, item) or 0
        end, 0) or 0
    end

    function Core.HasItem(src, item, amount)
        return Core.GetItemCount(src, item) >= (amount or 1)
    end

    function Core.CanCarry(src, item, amount)
        local ok = try(function()
            return exports.vorp_inventory:canCarryItem(src, item, amount or 1)
        end, true)
        return ok ~= false
    end

    function Core.RegisterUsableItem(item, cb)
        try(function()
            exports.vorp_inventory:registerUsableItem(item, function(payload)
                cb(payload.source or payload)
            end)
            return true
        end, false)
    end

    function Core.Notify(src, msg, kind, duration)
        TriggerClientEvent('jex:notify', src, msg, kind, duration)
    end

else

    local data = {}

    RegisterNetEvent('vorp:SelectedCharacter', function(charid)
        data.charid = charid
        data.loaded = true
    end)

    function Core.IsLoaded()
        return data.loaded == true
    end

    function Core.GetCharInfo()
        return Core.EmptyCharInfo()
    end

    function Core.GetJob()
        return Core.EmptyJob()
    end

    function Core.GetGang()
        return Core.EmptyGang()
    end

    function Core.GetItems()
        local items = try(function()
            return exports.vorp_inventory:getUserInventory()
        end, {}) or {}

        local out = {}
        for _, it in pairs(items) do
            if type(it) == 'table' and it.name then
                out[#out + 1] = Core.Item {
                    name = it.name, label = it.label, amount = it.count or it.amount,
                    slot = it.slot, weight = it.weight, meta = it.metadata,
                }
            end
        end
        return out
    end

    function Core.GetItemCount(item)
        local n = 0
        for _, it in ipairs(Core.GetItems()) do
            if it.name == item then n = n + it.amount end
        end
        return n
    end

    function Core.HasItem(item, amount)
        return Core.GetItemCount(item) >= (amount or 1)
    end

    function Core.Notify(msg, kind, duration)
        TriggerEvent('jex:notify', msg, kind, duration)
    end

end
