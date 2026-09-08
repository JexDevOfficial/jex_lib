
Jex.Core = Jex.Core or {}

local SERVER = {
    'GetIdentifier', 'GetName', 'GetCharInfo', 'GetJob', 'GetGang',
    'HasJob', 'GetPlayers', 'IsLoaded',
    'GetMoney', 'AddMoney', 'RemoveMoney',
    'AddItem', 'RemoveItem', 'GetItemCount', 'HasItem', 'CanCarry',
    'GetItems', 'RegisterUsableItem',
    'Notify',
}

local CLIENT = {
    'IsLoaded', 'GetCharInfo', 'GetJob', 'GetGang',
    'HasItem', 'GetItemCount', 'GetItems',
    'Notify',
}

function Jex.Core.EmptyJob()
    return { name = 'unemployed', label = 'Unemployed', grade = 0,
             gradeLabel = '', onDuty = true, isBoss = false }
end

function Jex.Core.EmptyGang()
    return { name = 'none', label = 'No Gang', grade = 0,
             gradeLabel = '', isBoss = false }
end

function Jex.Core.EmptyCharInfo()
    return { firstname = '', lastname = '', birthdate = '', gender = 0 }
end

function Jex.Core.Item(t)
    t = t or {}
    return {
        name = t.name or '',
        label = t.label or t.name or '',
        amount = tonumber(t.amount) or 0,
        slot = tonumber(t.slot) or 0,
        weight = tonumber(t.weight) or 0,
        type = t.type or 'item',
        unique = t.unique or false,
        useable = t.useable or false,
        meta = t.meta or {},
        image = t.image or '',
    }
end

function Jex.CheckContract()
    if not (Config and Config.Debug) and not (JexConfig and JexConfig.Debug) then return end

    local missing = {}
    for _, name in ipairs(IsDuplicityVersion() and SERVER or CLIENT) do
        if type(Jex.Core[name]) ~= 'function' then missing[#missing + 1] = name end
    end

    if #missing > 0 then
        Jex.Warn(('%s bridge is missing: %s'):format(Jex.coreLabel, table.concat(missing, ', ')))
    else
        Jex.Debug(('%s bridge complete'):format(Jex.coreLabel))
    end
end
