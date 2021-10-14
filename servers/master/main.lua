local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"

function cell.main()
    log.info("master start")

    machine.init()

    for k, v in pairs(machine.getRedisConf("game")) do
        log.info(k, v)
    end

    cluster.open("master")

    log.info("master start end")
end
