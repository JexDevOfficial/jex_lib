
Jex.DB = {}
local DB = Jex.DB

local function mysql()
    if GetResourceState('oxmysql') ~= 'started' then
        error(('%s needs oxmysql running.'):format(Jex.resource), 0)
    end
    return exports.oxmysql
end

function DB.Query(sql, params)
    return mysql():query_async(sql, params or {})
end

function DB.Single(sql, params)
    return mysql():single_async(sql, params or {})
end

function DB.Scalar(sql, params)
    return mysql():scalar_async(sql, params or {})
end

function DB.Insert(sql, params)
    return mysql():insert_async(sql, params or {})
end

function DB.Update(sql, params)
    return mysql():update_async(sql, params or {})
end

function DB.Install(tables)
    CreateThread(function()
        local made = 0

        for _, sql in ipairs(tables or {}) do
            local ok, err = pcall(function()
                mysql():query_async(sql, {})
            end)

            if ok then
                made = made + 1
            else
                Jex.Error(('table setup failed: %s'):format(err))
                Jex.Error('refusing to continue - running against a database we cannot write to loses data.')
                return
            end
        end

        Jex.Debug(('database ready (%d tables checked)'):format(made))
        Jex.dbReady = true
        TriggerEvent(('jex:%s:dbReady'):format(Jex.resource))
    end)
end

function DB.AddColumn(tableName, column, definition)
    local exists = DB.Scalar([[
        SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?
    ]], { tableName, column })

    if (exists or 0) > 0 then return false end

    DB.Query(('ALTER TABLE `%s` ADD COLUMN `%s` %s'):format(tableName, column, definition))
    Jex.Debug(('added %s.%s'):format(tableName, column))
    return true
end

function DB.Ready(cb)
    if Jex.dbReady then return cb() end
    AddEventHandler(('jex:%s:dbReady'):format(Jex.resource), cb)
end
