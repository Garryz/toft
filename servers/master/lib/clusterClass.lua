local cell = require "cell"
local const = require "const"
local log = require "log"
local serverClass = require "serverClass"

local clusterClass = Class("clusterClass")

function clusterClass:ctor(nodeType)
    self.serverList = {} -- {[1] = serverObj, [2] = serverObj...}
    self.dispathCount = 0
    self.totalWeight = 0
    self.weightList = {} -- {index = index, weight = weight, load = load, loadPerWeight = loadPerWeight}
    self.nodeType = nodeType
end

function clusterClass:checkServer()
    local currentTime = cell.time()
    local down = false
    for _, serverObj in ipairs(self.serverList) do
        local aliveTime = serverObj:getAliveTime()
        if aliveTime > 0 and currentTime - aliveTime > const.SERVER_DOWN_TIME then
            log.errorf("[%s] server disconnected", serverObj:getNodeName())
            -- 服务器断开连接 现在无用
            serverObj:setDisabled()
            down = true
        end
    end

    -- 计算权重
    if down then
        self:clacWeight()
    end
end

function clusterClass:getServerByNodeName(nodeName)
    for _, serverObj in ipairs(self.serverList) do
        if nodeName == serverObj.nodeName then
            return serverObj
        end
    end
end

function clusterClass:serverHeartbeat(serverConf)
    local nodeName = serverConf.nodeName
    -- 是否已存在
    local serverObj = self:getServerByNodeName(nodeName)
    if not serverObj then
        serverObj = serverClass.new(serverConf)
        table.insert(self.serverList, serverObj)
    end
    -- 更新服务器心跳和权重
    serverObj:setAliveTime(cell.time())
    serverObj:setWeight(serverConf.weight or const.SERVER_DEFAULT_WEIGHT)
    serverObj:setLoad(serverConf.load or serverObj:getLoad())
    serverObj:setAvailable()

    -- 计算权重
    self:clacWeight()
end

function clusterClass:clacWeight()
    self.totalWeight, self.weightList = 0, {}
    for index, serverObj in ipairs(self.serverList) do
        local weight = serverObj:getWeight()
        local load = serverObj:getLoad()
        if serverObj:isAvailable() and weight > 0 then
            self.totalWeight = self.totalWeight + weight
            table.insert(self.weightList, {index = index, weight = weight, load = load})
        end
    end
    for _, v in ipairs(self.weightList) do
        v.loadPerWeight = v.load / (v.weight / self.totalWeight)
    end
    table.sort(
        self.weightList,
        function(a, b)
            return a.loadPerWeight < b.loadPerWeight
        end
    )
end

-- 权重分配
function clusterClass:dispatchServerByWeight()
    if self.totalWeight <= 0 then
        log.errorf("权重分配 %s totalWeight=0", self.nodeType)
        return
    end

    local index = self.weightList[1].index

    local serverObj = self.serverList[index]
    if serverObj then
        return serverObj:formatServerInfo()
    end
end

-- 获取可用服务器列表
function clusterClass:getAvaliableServerList()
    local list = {}
    for _, serverObj in ipairs(self.serverList) do
        if serverObj:isAvailable() then
            table.insert(list, serverObj)
        end
    end

    return list
end

-- 随机分配
function clusterClass:dispatchServerByRandom()
    local availableServerList = self:getAvaliableServerList()
    local serverCount = #availableServerList
    if serverCount <= 0 then
        log.errorf("随机分配 %s 无可用服务器", self.nodeType)
        return
    end
    local index = math.random(1, serverCount)

    local serverObj = availableServerList[index]
    if serverObj then
        return serverObj:formatServerInfo()
    end
end

-- 哈希分配
function clusterClass:dispatchServerByHash(uid)
    local availableServerList = self:getAvaliableServerList()
    local serverCount = #availableServerList
    if serverCount <= 0 then
        log.errorf("哈希分配 %s 无可用服务器", self.nodeType)
        return
    end
    local index = uid % serverCount + 1

    local serverObj = availableServerList[index]
    if serverObj then
        return serverObj:formatServerInfo()
    end
end

-- 分配 对外接口 子类重写这个
function clusterClass:dispatchServer(uid)
    return self:dispatchServerByWeight()
end

return clusterClass
