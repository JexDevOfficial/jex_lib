-- Version checker. Once the server is up, every jex_* resource is checked for
-- updates and the result is printed under one banner.
--
-- Free scripts have public repos, so their latest version is read straight
-- from the fxmanifest.lua there. Paid scripts don't, so their latest version
-- comes from versions.json in the public jex_lib repo. versions.json also
-- lists the free scripts (with no version) so missing ones show as not
-- installed.
--
-- Releasing a free script: publish it. Releasing a paid one: bump its version
-- in versions.json and publish jex_lib.
-- Turn it off with: set jex:versionCheck false

local OWNER = 'JexDevOfficial'
local BRANCH = 'main'
local VERSIONS = ('https://raw.githubusercontent.com/%s/jex_lib/%s/versions.json'):format(OWNER, BRANCH)
local PREFIX = 'jex_'
local TIMEOUT = 10000

local TAGLINE = 'Systems for better worlds.'

-- Shown in the footer, in this order. Empty ones are skipped.
local LINKS = {
    'jex-dev.com',
    'github.com/' .. OWNER,
    '', -- discord invite
}

local FRAMEWORKS = {
    { 'rsg-core', 'RSG Core' },
    { 'vorp_core', 'VORP' },
    { 'redem_roleplay', 'RedEM:RP' },
    { 'qbr-core', 'QBR' },
}

local INVENTORIES = { 'rsg-inventory', 'vorp_inventory', 'redemrp_inventory', 'ox_inventory' }

-- The jex-dev.com palette, as 24-bit console colour.
local function rgb(r, g, b) return ('\27[38;2;%d;%d;%dm'):format(r, g, b) end

local C = {
    lime = rgb(183, 255, 60),
    text = rgb(232, 229, 222),
    muted = rgb(133, 135, 138),
    faint = rgb(92, 95, 99),
    amber = rgb(255, 196, 61),
    red = rgb(255, 99, 88),
    reset = '\27[0m',
}

-- JEX.DEV, three rows tall. Each glyph is the same width on every row.
local GLYPHS = {
    J = { ' ╻', ' ┃', '┗┛' },
    E = { '┏━╸', '┣╸ ', '┗━╸' },
    X = { '╻ ╻', '┏╋┛', '╹ ╹' },
    ['.'] = { ' ', ' ', '╹' },
    D = { '╺┳┓', ' ┃┃', '╺┻┛' },
    V = { '╻ ╻', '┃┏┛', '┗┛ ' },
}

local function parts(v)
    local t = {}
    for n in tostring(v):gmatch('%d+') do t[#t + 1] = tonumber(n) end
    return t
end

-- -1 if a is older than b, 0 if equal, 1 if newer.
local function compare(a, b)
    local x, y = parts(a), parts(b)
    for i = 1, math.max(#x, #y) do
        local p, q = x[i] or 0, y[i] or 0
        if p ~= q then return p < q and -1 or 1 end
    end
    return 0
end

local function manifest_version(body)
    -- Line anchored, so fx_version never matches.
    return ('\n' .. body):match("\n%s*version%s*%(?%s*['\"]([^'\"]+)['\"]")
end

local function running(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function framework()
    local core = 'Standalone'
    for _, f in ipairs(FRAMEWORKS) do
        if running(f[1]) then core = f[2] break end
    end
    for _, inv in ipairs(INVENTORIES) do
        if running(inv) then return core .. C.faint .. '  ·  ' .. C.text .. inv end
    end
    return core
end

-- Everything in versions.json, plus any other jex_* resource on this server.
local function resources(latest)
    local seen, list = {}, {}
    local function add(name)
        if not seen[name] then
            seen[name] = true
            list[#list + 1] = name
        end
    end

    for name in pairs(latest) do add(name) end
    for i = 0, GetNumResources() - 1 do
        local name = GetResourceByFindIndex(i)
        if name and name:sub(1, #PREFIX) == PREFIX then add(name) end
    end

    -- jex_lib first, the rest alphabetical.
    table.sort(list, function(a, b)
        if a == 'jex_lib' or b == 'jex_lib' then return a == 'jex_lib' end
        return a < b
    end)
    return list
end

-- Every line sits against a lime rule, like the accent bar on the site.
local function line(text)
    print(C.lime .. '  ▌ ' .. C.reset .. (text or '') .. C.reset)
end

local function wordmark()
    for row = 1, 3 do
        local jex, dev = {}, {}
        for ch in ('JEX'):gmatch('.') do jex[#jex + 1] = GLYPHS[ch][row] end
        for ch in ('.DEV'):gmatch('.') do dev[#dev + 1] = GLYPHS[ch][row] end
        line(' ' .. C.text .. table.concat(jex, ' ') .. ' ' .. C.lime .. table.concat(dev, ' '))
    end
end

local function rule(label)
    line(C.lime .. label .. ' ' .. C.faint .. ('─'):rep(44 - #label))
end

local ROW = '%s %s%-20s %s%-9s %s'

local function row(r)
    local name = r.name
    local stopped = r.running and '' or (C.faint .. ' (stopped)')

    if r.status == 'current' then
        line(ROW:format(C.lime .. '●', C.text, name, C.muted, r.have, C.faint .. 'up to date' .. stopped))
    elseif r.status == 'newer' then
        line(ROW:format(C.lime .. '●', C.text, name, C.muted, r.have,
            C.faint .. 'dev build, latest is ' .. r.latest .. stopped))
    elseif r.status == 'outdated' then
        line(ROW:format(C.amber .. '▲', C.text, name, C.red, r.have,
            C.lime .. '→ ' .. r.latest .. '  ' .. C.amber .. 'update' .. stopped))
        line(('  %s%s'):format(C.faint, r.url))
    elseif r.status == 'missing' then
        line(ROW:format(C.faint .. '○', C.faint, name, C.faint, '', 'not installed  ' .. r.url))
    else
        line(ROW:format(C.red .. '×', C.text, name, C.muted, r.have, C.red .. 'could not check' .. stopped))
    end
end

local function report(results, reached)
    local outdated, installed = 0, 0
    for _, r in ipairs(results) do
        if r.status == 'outdated' then outdated = outdated + 1 end
        if r.status ~= 'missing' then installed = installed + 1 end
    end

    local summary
    if not reached then
        summary = C.red .. 'Could not reach the Jex version list.'
    elseif outdated > 0 then
        summary = C.amber .. ('%d update%s available.'):format(outdated, outdated == 1 and '' or 's')
    else
        summary = C.lime .. ('All %d installed Jex scripts are up to date.'):format(installed)
    end

    local links = {}
    for _, link in ipairs(LINKS) do
        if link ~= '' then links[#links + 1] = link end
    end

    print('')
    line()
    wordmark()
    line(' ' .. C.muted .. TAGLINE)
    line()
    rule('SCRIPTS')
    for _, r in ipairs(results) do row(r) end
    line()
    line(summary)
    line()
    rule('SERVER')
    line(('%s%-10s %s%s'):format(C.muted, 'Framework', C.text, framework()))
    line(('%s%-10s %s%s'):format(C.muted, 'Links', C.text,
        table.concat(links, C.faint .. '  ·  ' .. C.text)))
    line()
    print('')
end

local function await(pending)
    local waited = 0
    while pending() > 0 and waited < TIMEOUT do
        Wait(250)
        waited = waited + 250
    end
end

local function check()
    local latest, pending = nil, 1

    PerformHttpRequest(VERSIONS, function(code, body)
        if code == 200 and body then
            local parsed, data = pcall(json.decode, body)
            if parsed and type(data) == 'table' then latest = data end
        end
        pending = 0
    end, 'GET')

    await(function() return pending end)

    local results = {}
    for _, name in ipairs(resources(latest or {})) do
        local state = GetResourceState(name)
        local entry = latest and latest[name] or {}
        local r = {
            name = name,
            have = GetResourceMetadata(name, 'version', 0) or '0.0.0',
            running = running(name),
            latest = entry.version,
            url = entry.url or ('https://github.com/%s/%s'):format(OWNER, name),
            status = 'unknown',
        }
        results[#results + 1] = r

        if state == 'missing' or state == 'unknown' then
            r.status = 'missing'
        elseif not r.latest then
            -- Free script: its public repo's fxmanifest is the latest version.
            pending = pending + 1
            local raw = ('https://raw.githubusercontent.com/%s/%s/%s/fxmanifest.lua'):format(OWNER, name, BRANCH)
            PerformHttpRequest(raw, function(code, body)
                r.latest = code == 200 and body and manifest_version(body) or nil
                pending = pending - 1
            end, 'GET')
        end
    end

    await(function() return pending end)

    for _, r in ipairs(results) do
        if r.status ~= 'missing' and r.latest then
            local cmp = compare(r.have, r.latest)
            r.status = cmp < 0 and 'outdated' or cmp > 0 and 'newer' or 'current'
        end
    end

    report(results, latest ~= nil)
end

CreateThread(function()
    if GetConvar('jex:versionCheck', 'true') == 'false' then return end

    -- Let every resource in server.cfg start first, so scripts ensured after
    -- jex_lib are counted.
    Wait(2000)
    check()
end)
