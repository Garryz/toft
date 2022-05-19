local cell = require "cell"
local log = require "log"

local mysqlClass = Class("mysqlClass")

function mysqlClass:ctor(mysqlPoolSrvName, key)
    self.mysqlPoolSrvName = mysqlPoolSrvName
    self.key = key
    self.mysql = nil
    self:initMysql()
end

function mysqlClass:initMysql()
    self.mysql = cell.call(self.mysqlPoolSrvName, "getSrvIdByHash", tostring(self.key))
end

function mysqlClass:callMysql(sql)
    return cell.call(self.mysql, "query", sql)
end

local function getDatabaseName()
    return "SELECT database() as databaseName"
end

function mysqlClass:getDatabaseName()
    local result = self:callMysql(getDatabaseName())
    return result and result[1] and result[1].databaseName
end

local function checkTableHas(database, tableName)
    return string.format(
        "SELECT table_name FROM information_schema.TABLES WHERE TABLE_SCHEMA='%s' and table_name='%s'",
        database,
        tableName
    )
end

function mysqlClass:checkTableHas(dbName, tableName)
    local result = self:callMysql(checkTableHas(dbName, tableName))
    return not (result == nil or #result == 0)
end

local function createTable(tableName, columnNameOptions, primaryKey, index)
    local str = "CREATE TABLE " .. tableName .. " ("
    for key, value in pairs(columnNameOptions) do
        str = str .. key .. " " .. value .. ","
    end
    if index then
        str = str .. string.format("PRIMARY KEY (%s), %s)", primaryKey, index)
    else
        str = str .. string.format("PRIMARY KEY (%s))", primaryKey)
    end

    str = str .. " DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
    return str
end

function mysqlClass:createTable(tableName, columnNameOptions, keyName, index)
    local sql = createTable(tableName, columnNameOptions, keyName, index)
    local result = self:callMysql(sql)
    if result.errno then
        log.errorf("createTable fatal err:%s, sql:%s", result.err, sql)
        error(result.err)
    end
end

local function getTableColumnOptions(database, tableName)
    return string.format(
        "SELECT COLUMN_NAME, IS_NULLABLE, COLUMN_TYPE, DATA_TYPE, COLUMN_COMMENT, COLUMN_DEFAULT FROM information_schema.columns where table_schema='%s' and table_name='%s'",
        database,
        tableName
    )
end

function mysqlClass:getTableColumnOptions(dbName, tableName)
    return self:callMysql(getTableColumnOptions(dbName, tableName))
end

local function addColumn(tableName, columnName, columnNameOption)
    return string.format("alter table %s add column %s %s", tableName, columnName, columnNameOption)
end

function mysqlClass:addColumn(tableName, columnName, columnNameOption)
    local sql = addColumn(tableName, columnName, columnNameOption)
    local result = self:callMysql(sql)
    if result.errno then
        log.errorf("addColumn fatal err:%s, sql:%s", result.err, sql)
        error(result.err)
    end
end

local function deleteColumn(tableName, columnName)
    return string.format("alter table %s drop column %s", tableName, columnName)
end

function mysqlClass:deleteColumn(tableName, columnName)
    local sql = deleteColumn(tableName, columnName)
    local result = self:callMysql(sql)
    if result.errno then
        log.errorf("deleteColumn fatal err:%s, sql:%s", result.err, sql)
        error(result.err)
    end
end

local function formatLastColumn(columnType, isNullable, columnComment, columnDefault)
    local res = {}
    table.insert(res, columnType)
    if isNullable == "NO" then
        table.insert(res, "not null")
        if columnDefault then
            table.insert(res, string.format("default %s", columnDefault))
        end
    else
        if columnDefault then
            table.insert(res, string.format("default %s", columnDefault))
        else
            if columnType ~= "json" then
                table.insert(res, "default null")
            end
        end
    end

    if columnComment and columnComment ~= "" then
        table.insert(res, string.format("comment '%s'", columnComment))
    end

    return string.lower(table.concat(res, " "))
end

local function formatNewColumn(options)
    options = string.lower(options)
    options = string.gsub(options, "int%((%d+)%)", "int")

    if string.find(options, "not") or string.find(options, "json") then
        return options
    end
    -- 字段默认值处理
    local s, _ = string.find(options, "default")
    if not s then
        local cd, _ = string.find(options, "comment")
        if cd then
            local ss = string.sub(options, 1, cd - 1)
            local tt = string.sub(options, cd, -1)
            return string.format("%s%s%s", ss, "default null ", tt)
        end
        return string.format("%s %s", options, "default null")
    end

    return options
end

local function updateColumnType(tableName, columnName, ops)
    return string.format("alter table %s modify column %s %s", tableName, columnName, ops)
end

function mysqlClass:updateColumnType(tableName, columnName, ops)
    local sql = updateColumnType(tableName, columnName, ops)
    local result = self:callMysql(sql)
    if result.errno then
        log.errorf("updateColumnType fatal err:%s, sql:%s", result.err, sql)
        error(result.err)
    end
end

function mysqlClass:initTable(module, force)
    assert(module.tableName, "tableName nil")
    local dbName = self:getDatabaseName()
    -- create table
    if not self:checkTableHas(dbName, module.tableName) then
        self:createTable(module.tableName, module.columnNameOptions, module.keyName, module.index)
        return
    end

    -- get table Options
    local tableColumns = {}
    local result = self:getTableColumnOptions(dbName, module.tableName)
    if result then
        for _, v in pairs(result) do
            assert(v["COLUMN_NAME"], string.toString(v))
            local columnName = v["COLUMN_NAME"]
            tableColumns[columnName] = true
            if force then
                local columnNameOption = module.columnNameOptions[columnName]
                if not columnNameOption then
                    -- delete column
                    self:deleteColumn(module.tableName, columnName)
                else
                    -- change column
                    local last =
                        formatLastColumn(v["COLUMN_TYPE"], v["IS_NULLABLE"], v["COLUMN_COMMENT"], v["COLUMN_DEFAULT"])
                    local new = formatNewColumn(columnNameOption)
                    if new ~= last then
                        log.infof("table=%s, column=%s, last=%s, new=%s", module.tableName, columnName, last, new)
                        self:updateColumnType(module.tableName, columnName, new)
                    end
                end
            end
        end
    end

    -- add column
    for key, value in pairs(module.columnNameOptions) do
        if not tableColumns[key] then
            self:addColumn(module.tableName, key, value)
        end
    end
end

local function formatColumnValue(v)
    if type(v) == "string" then
        return string.format("'%s'", v)
    end
    return v
end

local function getRow(tableName, key, value)
    return string.format("select * from %s where %s=%s", tableName, key, formatColumnValue(value))
end

function mysqlClass:getRow(tableName, keyName, keyValue)
    local sql = getRow(tableName, keyName, keyValue)
    local result = self:callMysql(sql)
    if result.errno then
        log.errorf("getRow fatal err:%s, sql:%s", result.err, sql)
        return
    end

    return result[1]
end

local function addRow(tableName, row)
    local columns, values = {}, {}
    for k, v in pairs(row) do
        table.insert(columns, k)
        table.insert(values, formatColumnValue(v))
    end

    return string.format(
        "insert into %s(%s) values(%s);",
        tableName,
        table.concat(columns, ","),
        table.concat(values, ",")
    )
end

local function setRow(tableName, row)
    local sql = addRow(tableName, row)
    if string.sub(sql, #sql) == ";" then
        sql = string.sub(sql, 1, #sql - 1)
    end

    local updates = {}
    for k, v in pairs(row) do
        table.insert(updates, string.format("%s=%s", k, formatColumnValue(v)))
    end

    return string.format("%s on duplicate key update %s;", sql, table.concat(updates, ","))
end

function mysqlClass:setRow(tableName, row)
    local sql = setRow(tableName, row)
    local result = self:callMysql(sql)
    if result.errno then
        log.errorf("setRow fatal err:%s, sql:%s", result.err, sql)
        return false
    end

    return true
end

local function delRow(tableName, keyName, keyValue)
    return string.format("delete from %s where %s=%s;", tableName, keyName, formatColumnValue(keyValue))
end

function mysqlClass:delRow(tableName, keyName, keyValue)
    local sql = delRow(tableName, keyName, keyValue)
    local result = self:callMysql(sql)
    if result.errno then
        log.errorf("delRow fatal err:%s, sql:%s", result.err, sql)
        return false
    end

    return true
end

function mysqlClass:execute(sql, poolKey)
    if poolKey then
        self.key = poolKey
        self:initMysql()
    end
    return self:callMysql(sql)
end

return mysqlClass
