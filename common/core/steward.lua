local const = require "const"
local env = require "env"
local machine = require "machine"
local cluster = require "cluster"
local timer = require "timer"
local log = require "log"

local steward = {}

local weight = const.SERVER_DEFAULT_WEIGHT
local load = 0

local function pingMaster()
    local nodeType = env.getconfig("nodeType")
    local nodeName = env.getconfig("nodeName")
    local serverData = {
        weight = weight,
        nodeType = nodeType,
        nodeName = nodeName
    }
    local tcpConf = machine.getTcpListenConf(nodeName)
    serverData.host = tcpConf.host
    serverData.port = tcpConf.port
    local wsConf = machine.getWsListenConf(nodeName)
    serverData.wsPort = wsConf.port
    serverData.wsProtocol = wsConf.protocol
    serverData.load = load
    cluster.send("master", "serverMgr", "serverHeartbeat", serverData)
end

function steward.init()
    timer.timeOut(1, pingMaster)
end

function steward.serverDown(downClusterMap)
    log.info("steward.serverDown", string.toString(downClusterMap))
end

return steward
