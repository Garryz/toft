local redisClass = require "redisClass"
local mysqlClass = require "mysqlClass"
local json = require "json"

local baseModule = Class("baseModule")

function baseModule:ctor(redisPoolSrvName, mysqlPoolSrvName, key, tableName, keyName, index)
    self.redis = redisClass.new(redisPoolSrvName, key or 0)
    self.mysql = mysqlClass.new(mysqlPoolSrvName, key or 0)
    self.tableName = tableName
    self.keyName = keyName
    self.index = index
end

function baseModule:getInitColumnNameOptions()
    return {}
end

function baseModule:getKeyValue()
    return self[self.keyName]
end

local function isJsonType(option)
    return string.match(string.upper(option), "JSON")
end

local function isNumberType(option)
    return string.match(string.upper(option), "INT")
end

function baseModule:getDbData()
    local columnOptionList = self:getInitColumnNameOptions()
    local dbData = {}
    for key, option in pairs(columnOptionList) do
        local val = self[key]
        if isJsonType(option) then
            dbData[key] = json.encode(val)
        else
            dbData[key] = val
        end
    end

    return dbData
end

local function getRedisKey(tableName, keyValue)
    return string.format("%s:%s", tableName, keyValue)
end

function baseModule:getFromRedis()
    return self.redis:hgetall(getRedisKey(self.tableName, self:getKeyValue()))
end

function baseModule:setToRedis(data)
    self.redis:hmset(getRedisKey(self.tableName, self:getKeyValue()), data)
end

function baseModule:delToRedis()
    self.redis:del(getRedisKey(self.tableName, self:getKeyValue()))
end

function baseModule:initMysqlTable(force)
    self.mysql:initTable(
        {
            tableName = self.tableName,
            columnNameOptions = self:getInitColumnNameOptions(),
            keyName = self.keyName,
            index = self.index
        },
        force
    )
end

function baseModule:getFromMysql()
    return self.mysql:getRow(self.tableName, self.keyName, self:getKeyValue())
end

function baseModule:setToMysql(data)
    return self.mysql:setRow(self.tableName, data)
end

function baseModule:delToMysql()
    return self.mysql:delRow(self.tableName, self.keyName, self:getKeyValue())
end

function baseModule:setData(data)
    if not data then
        return false
    end

    if type(data) == "string" then
        data = json.decode(data)
    end
    for key, value in pairs(self:getInitColumnNameOptions()) do
        if data[key] then
            if isNumberType(value) then
                self[key] = tonumber(data[key])
            elseif isJsonType(value) then
                if type(data[key]) == "string" then
                    self[key] = json.decode(data[key]) or {}
                else
                    self[key] = data[key]
                end
            else
                self[key] = data[key]
            end
        end
    end

    return true
end

function baseModule:loadData()
    local function get()
        local res = self:getFromRedis()
        if res and next(res) then
            return res
        end

        res = self:getFromMysql()
        if res and next(res) then
            -- add to redis
            self:setToRedis(res)
            res = self:getFromRedis()
        end

        return res
    end

    local data = get()
    return self:setData(data)
end

function baseModule:saveData()
    if not self:getKeyValue() or not self.tableName then
        return false
    end

    self:setToRedis(self:getDbData())

    return true
end

function baseModule:delData()
    self:delToRedis()
    self:delToMysql()
end

return baseModule
