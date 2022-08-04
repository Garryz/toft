local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"

function cell.main()
    log.info("login start")

    machine.init()

    cell.uniqueservice("service.debugconsole", machine.getDebugPort("login"))

    cell.uniqueservice("stewardSrv")

    cell.newservice("poolSrv", "redisSrv", 3, "redisSrv", false, machine.getRedisConf("game"))
    cell.newservice("poolSrv", "mysqlSrv", 3, "mysqlSrv", false, machine.getMysqlConf("game"))

    cell.uniqueservice("httpServerSrv", "127.0.0.1", 8080, 3, "webapp", 8192)

    cluster.open("login")

    log.info("login start end")
end
