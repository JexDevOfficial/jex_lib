
local CORES = {
    { resource = 'rsg-core',        name = 'rsg',   label = 'RSG Core' },
    { resource = 'vorp_core',       name = 'vorp',  label = 'VORP' },
    { resource = 'redem_roleplay',  name = 'redem', label = 'RedEM:RP' },
}

local INVENTORIES = {
    { resource = 'rsg-inventory',      name = 'rsg',   label = 'rsg-inventory' },
    { resource = 'vorp_inventory',     name = 'vorp',  label = 'vorp_inventory' },
    { resource = 'redemrp_inventory',  name = 'redem', label = 'redemrp_inventory' },
}

local function first_started(list)
    for _, entry in ipairs(list) do
        if GetResourceState(entry.resource) == 'started' then return entry end
    end
end

local core = first_started(CORES)

local forced = (Config and Config.Core) or (JexConfig and JexConfig.Core)

if forced and forced ~= 'auto' then
    Jex.core = forced
    Jex.coreLabel = forced
    Jex.Warn(('core forced to "%s" by config'):format(forced))
elseif core then
    Jex.core = core.name
    Jex.coreLabel = core.label
else
    Jex.core = 'custom'
    Jex.coreLabel = 'custom'
    Jex.Warn('no supported framework found - using the custom bridge. '
        .. 'Fill in jex_lib/core/custom.lua if your core is not VORP, RSG or RedEM:RP.')
end

local inv = first_started(INVENTORIES)

Jex.inventory = inv and inv.name or Jex.core
Jex.inventoryLabel = inv and inv.label or Jex.coreLabel

Jex.Debug(('core: %s, inventory: %s'):format(Jex.coreLabel, Jex.inventoryLabel))
