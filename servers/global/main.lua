local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"

function cell.main()
    log.info("global start")

    machine.init()

    cell.uniqueservice("service.debugconsole", machine.getDebugPort("global"))

    cell.uniqueservice("stewardSrv")

    cell.newservice("poolSrv", "redisSrv", 3, "redisSrv", false, machine.getRedisConf("game"))
    cell.newservice("poolSrv", "mysqlSrv", 3, "mysqlSrv", false, machine.getMysqlConf("game"))

    cell.uniqueservice("backupSrv")

    cluster.open("global")

    log.info("global start end")
end
