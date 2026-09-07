local Core = Jex.Core
local RSG = exports['rsg-core']:GetCoreObject()

local ACCOUNTS = (JexConfig and JexConfig.Accounts) or { cash = 'cash', bank = 'bank', gold = 'gold' }

local server = IsDuplicityVersion()

local function player(src)
    return RSG.Functions.GetPlayer(src)
end

if server then

    function Core.IsLoaded(src)
        return player(src) ~= nil
    end

    function Core.GetIdentifier(src)
        local p = player(src)
        return p and p.PlayerData.citizenid
    end

    function Core.GetName(src)
        local p = player(src)
        if not p then return '' end
        local c = p.PlayerData.charinfo or {}
        return ('%s %s'):format(c.firstname or '', c.lastname or ''):gsub('^%s+', '')
    end

    function Core.GetCharInfo(src)
        local p = player(src)
        if not p then return Core.EmptyCharInfo() end
        local c = p.PlayerData.charinfo or {}
        return {
            firstname = c.firstname or '',
            lastname = c.lastname or '',
            birthdate = c.birthdate or '',
            gender = c.gender or 0,
        }
    end

    function Core.GetJob(src)
        local p = player(src)
        if not p or not p.PlayerData.job then return Core.EmptyJob() end
        local j = p.PlayerData.job
        return {
            name = j.name or 'unemployed',
            label = j.label or '',
            grade = (j.grade and j.grade.level) or 0,
            gradeLabel = (j.grade and j.grade.name) or '',
            onDuty = j.onduty ~= false,
            isBoss = j.isboss or false,
        }
    end

    function Core.GetGang(src)
        local p = player(src)
        if not p or not p.PlayerData.gang then return Core.EmptyGang() end
        local g = p.PlayerData.gang
        return {
            name = g.name or 'none',
            label = g.label or '',
            grade = (g.grade and g.grade.level) or 0,
            gradeLabel = (g.grade and g.grade.name) or '',
            isBoss = g.isboss or false,
        }
    end

    function Core.HasJob(src, jobs, minGrade)
        local job = Core.GetJob(src)
        if type(jobs) == 'string' then jobs = { jobs } end

        for _, name in ipairs(jobs or {}) do
            if job.name == name then
                return job.grade >= (minGrade or 0)
            end
        end

        return false
    end

    function Core.GetPlayers()
        local out = {}
        for _, src in pairs(RSG.Functions.GetPlayers() or {}) do
            out[#out + 1] = tonumber(src)
        end
        return out
    end

    function Core.GetMoney(src, account)
        local p = player(src)
        if not p then return 0 end
        return p.PlayerData.money[ACCOUNTS[account] or account or 'cash'] or 0
    end

    function Core.AddMoney(src, account, amount, reason)
        local p = player(src)
        if not p or (tonumber(amount) or 0) <= 0 then return false end
        return p.Functions.AddMoney(ACCOUNTS[account] or account or 'cash', amount, reason) and true or false
    end

    function Core.RemoveMoney(src, account, amount, reason)
        local p = player(src)
        if not p or (tonumber(amount) or 0) <= 0 then return false end
        return p.Functions.RemoveMoney(ACCOUNTS[account] or account or 'cash', amount, reason) and true or false
    end

    function Core.AddItem(src, item, amount, meta, slot)
        local ok = exports['rsg-inventory']:AddItem(src, item, amount or 1, slot, meta, Jex.resource)
        return ok and true or false
    end

    -- RSG takes no metadata when removing; it matches on slot instead.
    function Core.RemoveItem(src, item, amount, meta, slot)
        local ok = exports['rsg-inventory']:RemoveItem(src, item, amount or 1, slot, Jex.resource)
        return ok and true or false
    end

    function Core.GetItems(src)
        local inv = exports['rsg-inventory']:GetInventory(src)
        local out = {}

        for _, it in pairs((inv and inv.items) or inv or {}) do
            if type(it) == 'table' and it.name then
                out[#out + 1] = Core.Item {
                    name = it.name, label = it.label, amount = it.amount or it.count,
                    slot = it.slot, weight = it.weight, type = it.type,
                    unique = it.unique, useable = it.useable,
                    meta = it.info or it.metadata, image = it.image,
                }
            end
        end

        return out
    end

    function Core.GetItemCount(src, item)
        return exports['rsg-inventory']:GetItemCount(src, item) or 0
    end

    function Core.HasItem(src, item, amount)
        return Core.GetItemCount(src, item) >= (amount or 1)
    end

    function Core.CanCarry(src, item, amount)
        local ok = exports['rsg-inventory']:CanAddItem(src, item, amount or 1)
        return ok ~= false
    end

    function Core.RegisterUsableItem(item, cb)
        RSG.Functions.CreateUseableItem(item, function(src) cb(src) end)
    end

    function Core.Notify(src, msg, kind, duration)
        TriggerClientEvent('jex:notify', src, msg, kind, duration)
    end

else

    -- GetPlayerData returns directly when called without a callback.
    function Core.IsLoaded()
        local d = RSG.Functions.GetPlayerData()
        return d ~= nil and d.citizenid ~= nil
    end

    function Core.GetCharInfo()
        local d = RSG.Functions.GetPlayerData() or {}
        local c = d.charinfo or {}
        return {
            firstname = c.firstname or '',
            lastname = c.lastname or '',
            birthdate = c.birthdate or '',
            gender = c.gender or 0,
        }
    end

    function Core.GetJob()
        local d = RSG.Functions.GetPlayerData() or {}
        local j = d.job
        if not j then return Core.EmptyJob() end
        return {
            name = j.name or 'unemployed',
            label = j.label or '',
            grade = (j.grade and j.grade.level) or 0,
            gradeLabel = (j.grade and j.grade.name) or '',
            onDuty = j.onduty ~= false,
            isBoss = j.isboss or false,
        }
    end

    function Core.GetGang()
        local d = RSG.Functions.GetPlayerData() or {}
        local g = d.gang
        if not g then return Core.EmptyGang() end
        return {
            name = g.name or 'none',
            label = g.label or '',
            grade = (g.grade and g.grade.level) or 0,
            gradeLabel = (g.grade and g.grade.name) or '',
            isBoss = g.isboss or false,
        }
    end

    function Core.GetItems()
        local d = RSG.Functions.GetPlayerData() or {}
        local out = {}

        for _, it in pairs(d.items or {}) do
            if type(it) == 'table' and it.name then
                out[#out + 1] = Core.Item {
                    name = it.name, label = it.label, amount = it.amount or it.count,
                    slot = it.slot, weight = it.weight, type = it.type,
                    unique = it.unique, useable = it.useable,
                    meta = it.info or it.metadata, image = it.image,
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

    -- RSG has no notify of its own; rsg-core uses ox_lib for this. Ours
    -- is handled by jex_lib so we are not relying on somebody else's
    -- resource being installed.
    function Core.Notify(msg, kind, duration)
        TriggerEvent('jex:notify', msg, kind, duration)
    end

end
