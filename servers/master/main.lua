local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"

function cell.main()
    log.info("master start")

    machine.init()

    cell.uniqueservice("serverMgrSrv")

    cluster.open("master")

    -- local pool = cell.newservice("poolSrv", "redisSrv", 3, "redisSrv", true, machine.getRedisConf("game"))

    -- local function test(i)
    --     local redis = cell.call(pool, "getSrvIdByHash", i)
    --     local value = cell.call(redis, "get", "test")
    --     if value then
    --         log.info(value)
    --     end
    --     cell.call(redis, "set", "test", i + 1)
    --     log.info(cell.call(redis, "get", "test"))
    -- end

    -- test(0)
    -- test(1)
    -- test(2)

    log.info("master start end")
end
