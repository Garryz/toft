local cell = require "cell"
local log = require "log"
local machine = require "machine"
local cluster = require "cluster"
local httpc = require "http.httpc"
local protoUtil = require "utils.protoUtil"

function cell.main()
    log.info("client start")

    machine.init()

    protoUtil.init()

    local req = {
        username = "二哈",
        password = "三哈"
    }

    local data = assert(protoUtil.encode("login.registerReq", req))
    local msg = string.pack(">I2>I2c" .. #data, 0, #data, data)

    local status, body = httpc.request("POST", "http://127.0.0.1:8080", "/", nil, nil, msg, 2000)
    log.infof("status = %s", status)

    local cmd = string.unpack(">I2", body)
    log.infof("cmd = %s", cmd)
    local rspDesc = protoUtil.enumStr("cmd.requestRsp", cmd)
    rspDesc = rspDesc:gsub("_", ".")
    local len = string.unpack(">I2", body, 3)
    local data = string.unpack("c" .. len, body, 5)
    local rsp = protoUtil.decode(rspDesc, data)
    log.infof("rsp data = %s", string.toString(rsp))

    log.info("client start end")
end
