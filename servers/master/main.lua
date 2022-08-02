local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"
local redisClass = require "redisClass"
local mysqlClass = require "mysqlClass"
local dataMode = require "dataMode"

function cell.main()
    log.info("master start")

    machine.init()

    cell.uniqueservice("service.debugconsole", machine.getDebugPort("master"))

    cell.uniqueservice("serverMgrSrv")
    cell.uniqueservice("accountMgrSrv")

    cell.newservice("poolSrv", "redisSrv", 3, "redisSrv", false, machine.getRedisConf("game"))
    cell.newservice("poolSrv", "mysqlSrv", 3, "mysqlSrv", false, machine.getMysqlConf("game"))

    cluster.open("master")

    local redis = redisClass.new("redisSrv", 0)
    redis:set("increaseUid", machine.getBeginUid(), true)

    dataMode.initMysqlTables()

    log.info("master start end")
end
