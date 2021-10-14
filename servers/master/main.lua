local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"

function cell.main()
    log.info("master start")

    machine.init()

    local redis = cell.newservice("redisSrv", machine.getRedisConf("game"))
    local value = cell.call(redis, "get", "test")
    if value then
        log.info(value)
    end
    cell.call(redis, "set", "test", 1)
    log.info(cell.call(redis, "get", "test"))

    cluster.open("master")

    log.info("master start end")
end
