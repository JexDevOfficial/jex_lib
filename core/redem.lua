-- Written against redem_roleplay source. Not yet run on a live server.
--
-- RedEM does not expose its inventory the way the other two do - there
-- are no add/remove exports, only internal functions and events. Items
-- are the least certain part of this adapter and every call is wrapped.

local Core = Jex.Core
local RedEM = exports.redem_roleplay:RedEM()

local server = IsDuplicityVersion()

local function try(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    Jex.Debug(('redem call failed: %s'):format(result))
    return fallback
end

if server then

    local function player(src)
        return try(function() return RedEM.GetPlayer(src) end, nil)
    end

    function Core.IsLoaded(src)
        return player(src) ~= nil
    end

    function Core.GetIdentifier(src)
        local p = player(src)
        return p and try(function() return p.GetIdentifier() end, nil) or nil
    end

    function Core.GetName(src)
        local p = player(src)
        if not p then return '' end
        return try(function() return p.GetName() end, '') or ''
    end

    function Core.GetCharInfo(src)
        local p = player(src)
        if not p then return Core.EmptyCharInfo() end

        return {
            firstname = try(function() return p.GetFirstName() end, '') or '',
            lastname = try(function() return p.GetLastName() end, '') or '',
            birthdate = '',
            gender = 0,
        }
    end

    function Core.GetJob(src)
        local p = player(src)
        if not p then return Core.EmptyJob() end

        local name = try(function() return p.GetJob() end, nil)
        if not name then return Core.EmptyJob() end

        return {
            name = name,
            label = name,
            grade = tonumber(try(function() return p.GetJobGrade() end, 0)) or 0,
            gradeLabel = '',
            onDuty = true,
            isBoss = false,
        }
    end

    function Core.GetGang(src)
        local p = player(src)
        if not p then return Core.EmptyGang() end

        local name = try(function() return p.GetGang() end, nil)
        if not name or name == '' then return Core.EmptyGang() end

        return {
            name = name,
            label = name,
            grade = tonumber(try(function() return p.GetGangGrade() end, 0)) or 0,
            gradeLabel = '',
            isBoss = false,
        }
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
        for _, src in ipairs(GetPlayers() or {}) do
            out[#out + 1] = tonumber(src)
        end
        return out
    end

    -- Cash and bank are separate calls here, not one function with an
    -- account name.
    function Core.GetMoney(src, account)
        local p = player(src)
        if not p then return 0 end

        if account == 'bank' then
            return tonumber(try(function() return p.GetBankMoney() end, 0)) or 0
        elseif account == 'gold' then
            return tonumber(try(function() return p.getGold() end, 0)) or 0
        end

        return tonumber(try(function() return p.GetMoney() end, 0)) or 0
    end

    function Core.AddMoney(src, account, amount, _)
        local p = player(src)
        if not p or (tonumber(amount) or 0) <= 0 then return false end

        return try(function()
            if account == 'bank' then p.AddBankMoney(amount) else p.AddMoney(amount) end
            return true
        end, false)
    end

    function Core.RemoveMoney(src, account, amount, _)
        local p = player(src)
        if not p or (tonumber(amount) or 0) <= 0 then return false end
        if Core.GetMoney(src, account) < amount then return false end

        return try(function()
            if account == 'bank' then p.RemoveBankMoney(amount) else p.RemoveMoney(amount) end
            return true
        end, false)
    end

    function Core.AddItem(src, item, amount, meta)
        return try(function()
            TriggerEvent('redemrp_inventory:addItem', src, item, amount or 1, meta or {})
            return true
        end, false)
    end

    function Core.RemoveItem(src, item, amount, meta)
        return try(function()
            TriggerEvent('redemrp_inventory:removeItem', src, item, amount or 1, meta or {})
            return true
        end, false)
    end

    function Core.GetItems(src)
        local items = try(function()
            local result
            TriggerEvent('redemrp_inventory:getData', src, function(inv) result = inv end)
            return result
        end, nil)

        local out = {}
        for _, it in pairs(items or {}) do
            if type(it) == 'table' and it.name then
                out[#out + 1] = Core.Item {
                    name = it.name, label = it.label, amount = it.amount or it.count,
                    slot = it.slot, weight = it.weight, type = it.type,
                    meta = it.meta or it.metadata,
                }
            end
        end

        return out
    end

    function Core.GetItemCount(src, item)
        local n = 0
        for _, it in ipairs(Core.GetItems(src)) do
            if it.name == item then n = n + it.amount end
        end
        return n
    end

    function Core.HasItem(src, item, amount)
        return Core.GetItemCount(src, item) >= (amount or 1)
    end

    -- No weight check available without reaching inside the inventory,
    -- so this is optimistic. The add will fail on its own if it cannot fit.
    function Core.CanCarry()
        return true
    end

    function Core.RegisterUsableItem(item, cb)
        AddEventHandler('RegisterUsableItem:' .. item, function(src)
            cb(src)
        end)
    end

    function Core.Notify(src, msg, kind, duration)
        TriggerClientEvent('jex:notify', src, msg, kind, duration)
    end

else

    local loaded = false

    RegisterNetEvent('redemrp:playerLoaded', function() loaded = true end)
    RegisterNetEvent('redemrp_roleplay:playerSpawned', function() loaded = true end)

    function Core.IsLoaded()
        return loaded
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
        local items = try(function() return RedEM.GetInventory() end, nil)

        local out = {}
        for _, it in pairs(items or {}) do
            if type(it) == 'table' and it.name then
                out[#out + 1] = Core.Item {
                    name = it.name, label = it.label,
                    amount = it.amount or it.count,
                    slot = it.slot, weight = it.weight,
                    meta = it.meta or it.metadata,
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
