local baseModule = require "baseModule"

local userModule = Class("user", baseModule)

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
        password = "varchar(50) DEFAULT NULL",
        loginTime = "int(11) DEFAULT 0",
        lastLoginTime = "int(11) DEFAULT 0",
        logoutTime = "int(11) DEFAULT 0"
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

function userModule:doLogin()
    userModule.super.doLogin(self)
    self.loginTime = os.time()
end

function userModule:doLogout()
    userModule.super.doLogout()
    self.logoutTime = os.time()
    self.lastLoginTime = self.loginTime
end

return userModule
