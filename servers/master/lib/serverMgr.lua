local clusterClass = require "clusterClass"
local log = require "log"
local timer = require "timer"
local cluster = require "cluster"

local serverMgr = {}

local clusterList = {}

local function createCluster(nodeType)
    -- if nodeType == "game" then
    --     return clusterClass.new(nodeType)
    -- end
    return clusterClass.new(nodeType)
end

function serverMgr.serverHeartbeat(serverConf)
    local nodeType = serverConf.nodeType

    local clusterObj = clusterList[nodeType]
    if not clusterObj then
        clusterObj = createCluster(nodeType)
        clusterList[nodeType] = clusterObj
    end

    clusterObj:serverHeartbeat(serverConf)
end

local function checkServer()
    local downClusterMap = {}
    for nodeType, clusterObj in pairs(clusterList) do
        local downServerMap = clusterObj:checkServer()
        if next(downServerMap) then
            downClusterMap[nodeType] = downServerMap
        end
    end
    if next(downClusterMap) then
        for _, clusterObj in pairs(clusterList) do
            local servers = clusterObj:getAvaliableServerList()
            for _, server in ipairs(servers) do
                -- 给存活节点发送下线节点的消息
                cluster.send(server:getNodeName(), "stewardSrv", "serverDown", downClusterMap)
            end
        end
    end
end

function serverMgr.init()
    timer.timeOut(2, checkServer)
end

function serverMgr.dispatchServer(nodeType, uid)
    local clusterObj = clusterList[nodeType]
    if not clusterObj then
        log.errorf("dispatchServer -> nodeType:%s找不到", nodeType)
        return
    end

    return clusterObj:dispatchServer(uid)
end

function serverMgr.getServerInfo(nodeType, nodeName)
    local clusterObj = clusterList[nodeType]
    if not clusterObj then
        log.errorf("getServerInfo -> nodeType:%s找不到", nodeType)
        return
    end

    return clusterObj:getServerByNodeName(nodeName)
end

return serverMgr
