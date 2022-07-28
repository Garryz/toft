local baseModule = require "baseModule"

local userModule = Class("userModule", baseModule)

function userModule:ctor(uid)
    userModule.super.ctor(self, "redisSrv", "mysqlSrv", uid, "tb_user", "uid")

    self.uid = uid
    self.username = ""
    self.password = ""
end

function userModule:getInitColumnNameOptions()
    return {
        uid = "int unsigned NOT NULL",
        username = "varchar(50)",
        password = "varchar(50) DEFAULT NULL"
    }
end

function userModule:setUsername(username)
    self.username = username
end

function userModule:setPassword(password)
    self.password = password
end

function userModule:getPassword()
    return self.password
end

return userModule
