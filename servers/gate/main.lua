local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"
local env = require "env"

function cell.main()
    log.info("gate start")

    machine.init()

    local nodeName = env.getconfig("nodeName")

    cell.newservice("watchdogSrv", machine.getTcpListenConf(nodeName), "tcpHandler")
    cell.newservice("watchdogSrv", machine.getWsListenConf(nodeName), "wsHandler")
    cell.uniqueservice("gateSrv")

    cluster.open("gate")

    log.info("gate start end")
end
