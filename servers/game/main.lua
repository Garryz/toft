local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"
local env = require "env"

function cell.main()
    local nodeName = env.getconfig("nodeName")
    log.info(nodeName .. " start")

    machine.init()

    cell.uniqueservice("service.debugconsole", machine.getDebugPort(nodeName))

    cell.uniqueservice("stewardSrv")

    cell.newservice("poolSrv", "redisSrv", 3, "redisSrv", false, machine.getRedisConf("game"))
    cell.newservice("poolSrv", "mysqlSrv", 3, "mysqlSrv", false, machine.getMysqlConf("game"))

    cell.newservice("poolSrv", "gameAgentSrv", 20, "gameSrv", true)

    cluster.open(nodeName)

    log.info(nodeName .. " start end")
end
