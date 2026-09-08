
function Jex.Notify(a, b, c, d)
    if IsDuplicityVersion() then
        if not a then return end
        TriggerClientEvent('jex:notify', a, b, c, d)
    else
        TriggerEvent('jex:notify', a, b, c)
    end
end
