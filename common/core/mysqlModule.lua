local mysqlClass = require "mysqlClass"

local mysqlModule = Class("mysqlModule")

function mysqlModule:ctor(mysqlPoolSrvName, poolKey, tableName, keyName, index)
    self.mysql = mysqlClass.new(mysqlPoolSrvName, poolKey or 0)
    self.tableName = tableName
    self.keyName = keyName
    self.index = index
end

function mysqlModule:getInitColumnNameOptions()
    return {}
end

function mysqlModule:initMysqlTable(force)
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

function mysqlModule:execute(sql, poolKey)
    return self.mysql:execute(sql, poolKey)
end

return mysqlModule
