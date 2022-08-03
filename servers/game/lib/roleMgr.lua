-- 角色对象管理器
local role = require "role"

local roleMgr = Class("roleMgr")

function roleMgr:ctor()
    self.roleList = {}
end

function roleMgr:loginRole(uid, session)
    local roleObj = role.new(uid)
    roleObj:loginModule(session)
    self.roleList[uid] = roleObj
end

function roleMgr:logoutRole(uid)
    local roleObj = self:getRole(uid)
    if not roleObj then
        return
    end

    roleObj:logoutModule()
    self.roleList[uid] = nil
end

function roleMgr:getRole(uid)
    return self.roleList[uid]
end

function roleMgr:saveRoleData()
    for _, roleObj in pairs(self.roleList) do
        roleObj:saveData()
    end
end

function roleMgr:autoSaveRoleData()
    for _, roleObj in pairs(self.roleList) do
        roleObj:autoSaveData()
    end
end

return roleMgr
