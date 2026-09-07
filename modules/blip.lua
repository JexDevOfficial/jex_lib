Jex.Blip = {}
local Blip = Jex.Blip

local created = {}

local BLIP_STYLE = 1664425300

local function varString(text)
    return CreateVarString(10, 'LITERAL_STRING', text)
end

function Blip.Create(opts)
    local c = Jex.Util.Coords(opts.coords)
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, BLIP_STYLE, c.x, c.y, c.z)

    if opts.sprite then
        Citizen.InvokeNative(0x74F74D3207ED525C, blip, opts.sprite, 1)
    end

    if opts.label then
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, varString(opts.label))
    end

    if opts.scale then
        Citizen.InvokeNative(0xD38744167B2FA257, blip, opts.scale + 0.0)
    end

    if opts.colour then
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, opts.colour)
    end

    created[#created + 1] = blip
    return blip
end

function Blip.CreateMany(list)
    local out = {}
    for _, opts in ipairs(list or {}) do
        out[#out + 1] = Blip.Create(opts)
    end
    return out
end

function Blip.Remove(blip)
    if not blip then return end

    RemoveBlip(blip)

    for i, existing in ipairs(created) do
        if existing == blip then
            table.remove(created, i)
            break
        end
    end
end

function Blip.RemoveAll()
    for _, blip in ipairs(created) do RemoveBlip(blip) end
    created = {}
end

AddEventHandler('onResourceStop', function(resource)
    if resource == Jex.resource then Blip.RemoveAll() end
end)
