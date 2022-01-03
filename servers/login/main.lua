local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"

function cell.main()
    log.info("login start")

    machine.init()

    cell.uniqueservice("httpServerSrv", "127.0.0.1", 8080, 3, "webapp", 8192)

    cluster.open("login")

    local protoUtil = require "utils.protoUtil"
    protoUtil.init()

    local req = {
        username = "二哈",
        password = "三哈"
    }

    local data = assert(protoUtil.encode("login.registerReq", req))

    local msg = assert(protoUtil.decode("login.registerReq", data))

    print(string.toString(msg))

    print(protoUtil.enumNum("cmd.requestCmd", "login_register"))

    print(protoUtil.enumStr("cmd.requestCmd", 0))

    log.info("login start end")
end
