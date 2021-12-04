local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"
local httpc = require "http.httpc"

function cell.main()
    log.info("client start")

    machine.init()

    local status, body = httpc.get("http://127.0.0.1:8080", "/", nil, nil, 2000)
    log.info(status, body)

    log.info("client start end")
end
