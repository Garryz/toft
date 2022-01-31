local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"
local redisClass = require "redisClass"

function cell.main()
    log.info("master start")

    machine.init()

    cell.uniqueservice("serverMgrSrv")

    cluster.open("master")

    cell.newservice("poolSrv", "redisSrv", 3, "redisSrv", false, machine.getRedisConf("game"))

    local redis = redisClass.new("redisSrv")
    local result1 = table.pack(redis:set("mykey", "Hello world"))
    log.info("result1", string.toString(result1))
    local result2 = table.pack(redis:strlen("mykey"))
    log.info("result2", string.toString(result2))
    local result3 = table.pack(redis:strlen("nonexisting"))
    log.info("result3", string.toString(result3))
    -- local result4 = table.pack(redis:setrange("key2", 6, "Redis"))
    -- log.info("result4", string.toString(result4))
    -- local result5 = table.pack(redis:get("key2"))
    -- log.info("result5", string.toString(result5))
    -- local result6 = table.pack(redis:zrangebylex("myzset", "[c", "[[aa"))
    -- log.info("result6", string.toString(result6))
    -- local result7 = table.pack(redis:zrangebylex("myzset", "[[a", "(c"))
    -- log.info("result7", string.toString(result7))

    log.info("master start end")
end
