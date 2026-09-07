-- Fill this in if your server does not run VORP, RSG or RedEM:RP.
--
-- Every function below is called by Jex scripts. Return the shapes shown
-- and everything works - you never have to touch a script itself.
--
-- Only the server half is required unless a script asks the client for
-- items or job directly.

local Core = Jex.Core

if IsDuplicityVersion() then

    -- Is this player's character loaded in yet?
    function Core.IsLoaded(src)
        return false
    end

    -- Your database key for a character. Must be stable across sessions.
    function Core.GetIdentifier(src)
        return nil
    end

    -- "First Last"
    function Core.GetName(src)
        return ''
    end

    -- { firstname, lastname, birthdate, gender }
    function Core.GetCharInfo(src)
        return Core.EmptyCharInfo()
    end

    -- { name, label, grade, gradeLabel, onDuty, isBoss }
    function Core.GetJob(src)
        return Core.EmptyJob()
    end

    function Core.GetGang(src)
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

    -- Array of server ids.
    function Core.GetPlayers()
        local out = {}
        for _, src in ipairs(GetPlayers() or {}) do out[#out + 1] = tonumber(src) end
        return out
    end

    -- account is 'cash', 'bank' or 'gold'.
    function Core.GetMoney(src, account)
        return 0
    end

    function Core.AddMoney(src, account, amount, reason)
        return false
    end

    -- Return false if they cannot afford it.
    function Core.RemoveMoney(src, account, amount, reason)
        return false
    end

    function Core.AddItem(src, item, amount, meta, slot)
        return false
    end

    function Core.RemoveItem(src, item, amount, meta, slot)
        return false
    end

    -- Array of Core.Item{...}
    function Core.GetItems(src)
        return {}
    end

    function Core.GetItemCount(src, item)
        return 0
    end

    function Core.HasItem(src, item, amount)
        return Core.GetItemCount(src, item) >= (amount or 1)
    end

    function Core.CanCarry(src, item, amount)
        return true
    end

    -- cb(src) when the item is used.
    function Core.RegisterUsableItem(item, cb)
    end

    function Core.Notify(src, msg, kind, duration)
        TriggerClientEvent('jex:notify', src, msg, kind, duration)
    end

else

    function Core.IsLoaded() return false end
    function Core.GetCharInfo() return Core.EmptyCharInfo() end
    function Core.GetJob() return Core.EmptyJob() end
    function Core.GetGang() return Core.EmptyGang() end
    function Core.GetItems() return {} end
    function Core.GetItemCount() return 0 end

    function Core.HasItem(item, amount)
        return Core.GetItemCount(item) >= (amount or 1)
    end

    function Core.Notify(msg, kind, duration)
        TriggerEvent('jex:notify', msg, kind, duration)
    end

end
