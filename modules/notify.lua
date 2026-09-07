-- What a script calls.
--
-- Server: Jex.Notify(src, text, type, duration)
-- Client: Jex.Notify(text, type, duration)
--
-- type is 'success', 'error', 'warning' or 'info'. Where it ends up is
-- the server owner's choice - see JexConfig.Notify. jex_lib's own
-- client does the routing, so this only has to hand the message over.

function Jex.Notify(a, b, c, d)
    if IsDuplicityVersion() then
        if not a then return end
        TriggerClientEvent('jex:notify', a, b, c, d)
    else
        TriggerEvent('jex:notify', a, b, c)
    end
end
