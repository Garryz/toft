local dataMode = require "dataMode"
local const = require "const"

local role = Class("role")

-- 角色构造
function role:ctor(uid)
    local classes = dataMode.getPersonalDataClasses()

    self.uid = uid
    self.gate = nil
    self.lastSaveTime = 0
    self.needSave = false

    self.moduleList = {}
    for _, moduleClass in pairs(classes) do
        local cname = moduleClass.__cname
        assert(self[cname] == nil)

        local moduleObj = moduleClass.new(uid)
        self[cname] = moduleObj
        table.insert(self.moduleList, cname)
    end
end

-- 登录各个模块
function role:loginModule(session)
    for _, cname in pairs(self.moduleList) do
        self[cname]:loadData()
    end

    -- 记录网关节点信息
    self.gate = session.gate

    for _, cname in pairs(self.moduleList) do
        self[cname]:doLogin()
    end
end

-- 各个模块登录完成之后有数据推送进行处理
function role:loginOver()
    for _, cname in pairs(self.moduleList) do
        self[cname]:loginOver()
    end
end

-- 登出各个模块
function role:logoutModule()
    for _, cname in pairs(self.moduleList) do
        self[cname]:doLogout()
    end
end

-- 非活跃登录
function role:inactiveLoginModule()
    for _, cname in pairs(self.moduleList) do
        self[cname]:loadData()
    end
end

-- 保存各个模块数据
function role:saveData()
    for _, cname in pairs(self.moduleList) do
        self[cname]:saveData()
    end
end

function role:setSaveStatus(status)
    self.needSave = status
end

-- 根据玩家数据交互来保存数据
function role:autoSaveData()
    local now = os.time()
    if now - self.lastSaveTime > const.ROLE_SAVE_DATA_TIME and self.needSave then
        self.lastSaveTime = now
        self.needSave = false
        self:saveData()
    end
end

return role
