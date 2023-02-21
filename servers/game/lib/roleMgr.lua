-- 角色对象管理器
local role = require "role"
local redisClass = require "redisClass"
local timeUtil = require "utils.timeUtil"
local cluster = require "cluster"
local env = require "env"
local cell = require "cell"

local redis
local gameNode = env.getconfig("nodeName")

cell.init(function()
    redis = redisClass.new("redisSrv", 0)
end)

local roleMgr = Class("roleMgr")

function roleMgr:ctor()
    self.roleList = {}
    self.inactiveRoleList = {}
end

function roleMgr:loginRole(uid, session)
    local roleObj = self.inactiveRoleList[uid]
    if not roleObj then
        roleObj = role.new(uid)
    end
    roleObj:loginModule(session)
    self.roleList[uid] = roleObj
    self.inactiveRoleList[uid] = nil
    cluster.call("master", "accountMgr", "setGame", uid, gameNode, cell.id)
end

function roleMgr:logoutRole(uid)
    local roleObj = self:getRole(uid)
    if not roleObj then
        return
    end

    roleObj:logoutModule()
    roleObj:saveData()
    self.roleList[uid] = nil
    cluster.send("master", "accountMgr", "logout", uid)
end

function roleMgr:getRole(uid)
    return self.roleList[uid]
end

function roleMgr:getRoleList()
    return self.roleList
end

function roleMgr:getRoleMayInactive(uid)
    local roleObj = self.roleList[uid]
    if roleObj then
        return roleObj
    end
    roleObj = self.inactiveRoleList[uid]
    if roleObj then
        return roleObj
    end
    roleObj = role.new(uid)
    roleObj:inactiveLoginModule()
    self.inactiveRoleList[uid] = roleObj
    redis:sadd("dailyInactive:" .. timeUtil.toDate(), uid)
    cluster.call("master", "accountMgr", "setGame", uid, gameNode, cell.id)
    return roleObj
end

function roleMgr:logoutInactiveRole(uid)
    local roleObj = self.inactiveRoleList[uid]
    if not roleObj then
        return
    end

    roleObj:saveData()
    self.inactiveRoleList[uid] = nil
    cluster.send("master", "accountMgr", "logoutInactive", uid)
end

function roleMgr:saveRoleData()
    for _, roleObj in pairs(self.roleList) do
        roleObj:saveData()
    end
    for _, roleObj in pairs(self.inactiveRoleList) do
        roleObj:saveData()
    end
end

function roleMgr:autoSaveRoleData()
    for _, roleObj in pairs(self.roleList) do
        roleObj:autoSaveData()
    end
    for _, roleObj in pairs(self.inactiveRoleList) do
        roleObj:autoSaveData()
    end
end

return roleMgr
