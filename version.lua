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

local LINKS = {
    { 'DISCORD', '' },
    { 'WEBSITE', 'https://jex-dev.com' },
    { 'GITHUB', 'https://github.com/' .. OWNER },
}

local FRAMEWORKS = {
    { 'vorp_core', 'VORP' },
    { 'rsg-core', 'RSG' },
    { 'redem_roleplay', 'RedEM:RP' },
    { 'qbr-core', 'QBR' },
}

local LOGO = {
    '     ██╗███████╗██╗  ██╗',
    '     ██║██╔════╝╚██╗██╔╝',
    '     ██║█████╗   ╚███╔╝ ',
    '██   ██║██╔══╝   ██╔██╗ ',
    '╚█████╔╝███████╗██╔╝ ██╗',
    ' ╚════╝ ╚══════╝╚═╝  ╚═╝',
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

local function framework()
    for _, f in ipairs(FRAMEWORKS) do
        local state = GetResourceState(f[1])
        if state == 'started' or state == 'starting' then return f[2] end
    end
    return 'STANDALONE'
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

local function banner()
    local dots = '^1▪ ▪ ▪ ▪ ▪ ▪'
    print('')
    print(('        %s  ^7VERSIONS CHECKER  %s^7'):format(dots, dots))
    print('')
    for _, line in ipairs(LOGO) do
        -- Solid blocks in yellow, the box-drawing shadow in red.
        print('        ^1' .. line:gsub('(█+)', '^3%1^1') .. '^7')
    end
    print('')
    for _, link in ipairs(LINKS) do
        if link[2] ~= '' then
            print(('        ^5%-9s^3%s^7'):format(link[1] .. ':', link[2]))
        end
    end
    print('')
    print(('        %s ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪^7'):format(dots))
    print('')
end

local function ok(msg) print('^2✓ ^7' .. msg) end
local function warn(msg) print('^3! ^7' .. msg) end
local function fail(msg) print('^1✗ ^7' .. msg) end

local function report(results, reached)
    banner()

    local outdated = 0
    for _, r in ipairs(results) do
        if r.status == 'outdated' then outdated = outdated + 1 end
    end

    if not reached then
        fail('^1COULD NOT REACH THE JEX VERSION LIST.^7')
    elseif outdated > 0 then
        warn(('^3%d JEX RESOURCE%s NEED%s UPDATING.^7'):format(
            outdated, outdated == 1 and '' or 'S', outdated == 1 and 'S' or ''))
    else
        ok('^2ALL INSTALLED JEX RESOURCES ARE UP TO DATE.^7')
    end

    ok('FRAMEWORK IN USE: ^3' .. framework() .. '^7')

    for _, r in ipairs(results) do
        local name = r.running and r.name or (r.name .. ' ^8(stopped)^7')
        local url = r.url and ('  ' .. r.url) or ''
        if r.status == 'missing' then
            print(('^8- %s not installed%s^7'):format(r.name, url))
        elseif r.status == 'current' then
            ok(('%s ^2%s^7'):format(name, r.have))
        elseif r.status == 'newer' then
            ok(('%s ^5%s^7 (dev build, latest is %s)'):format(name, r.have, r.latest))
        elseif r.status == 'outdated' then
            warn(('%s ^1%s^7 -> ^2%s^7%s'):format(name, r.have, r.latest, url))
        else
            fail(('%s %s (could not check)'):format(name, r.have))
        end
    end

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
            running = state == 'started' or state == 'starting',
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
