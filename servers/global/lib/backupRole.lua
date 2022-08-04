local dataMode = require "dataMode"
local redisClass = require "redisClass"

local backupRole = Class("backupRole")

-- 角色构造
function backupRole:ctor(uid)
    local classes = dataMode.getPersonalDataClasses()

    self.uid = uid

    self.moduleList = {}
    for _, moduleClass in pairs(classes) do
        local cname = moduleClass.__cname
        assert(self[cname] == nil)

        local moduleObj = moduleClass.new(uid)
        self[cname] = moduleObj
        table.insert(self.moduleList, cname)
    end

    self.redis = redisClass.new("redisSrv", uid)
end

function backupRole:isExist()
    if not self.user then
        return false
    end
    local redisKey = self.user.tabName .. ":" .. self.user:getKeyValue()
    return self.redis:exists(redisKey)
end

function backupRole:getLoginTime()
    if not self.user then
        return
    end
    local redisKey = self.user.tabName .. ":" .. self.user:getKeyValue()
    local loginTime = self.redis:hget(redisKey, "loginTime")
    return tonumber(loginTime) or 0
end

function backupRole:loadRedisData()
    for _, cname in pairs(self.moduleList) do
        local moduleObj = self[cname]
        local data = moduleObj:getFromRedis()
        if not data or not next(data) then
            return false
        end
        if not moduleObj:setData(data) then
            return false
        end
    end

    return true
end

function backupRole:backupToMysql()
    for _, cname in pairs(self.moduleList) do
        local moduleObj = self[cname]
        local data = moduleObj:getDbData()
        if not moduleObj:setToMysql(data) then
            return false
        end
    end

    return true
end

function backupRole:delRedisData()
    for _, cname in pairs(self.moduleList) do
        local moduleObj = self[cname]
        moduleObj:delToRedis()
    end
end

return backupRole
