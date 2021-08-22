local cell = require "cell"
local log = require "log"
local cluster = require "cluster"

function cell.main()
    log.info("master start")

    cluster.open("master")

    log.info("master start end")
end
