-- 注册任务
local baseTask = require "task.baseTask"
local protoUtil = require "utils.protoUtil"
local log = require "log"
local httpc = require "http.httpc"
local code = require "code"
local crypt = require "crypt"

local httpRegisterTask = Class("httpRegisterTask", baseTask)

function httpRegisterTask:ctor(robot, cnfTask)
    httpRegisterTask.super.ctor(self, robot, cnfTask)

    self.host = cnfTask.param.host
end

function httpRegisterTask:doStart()
    httpRegisterTask.super.doStart(self)

    local req = {
        username = crypt.base64encode(crypt.randomkey()),
        password = crypt.base64encode(crypt.randomkey())
    }
    local ok, cmd, resStr = protoUtil.encodeReqByProto("login.registerReq", req)
    if not ok then
        return
    end
    local msg = string.pack(">I2>I2c" .. #resStr, cmd, #resStr, resStr)

    local status, body = httpc.request("POST", self.host, "/", nil, nil, msg, 2000)
    log.infof("status = %s", status)

    local cmd, len = string.unpack(">I2>I2", body)
    local rspStr = string.unpack("c" .. len, body, 5)
    local ok, _, rsp = protoUtil.decodeRspByCmd(cmd, rspStr)
    if not ok then
        return
    end

    if not rsp.code or rsp.code ~= code.OK then
        log.errorf("rsp.code = %s", rsp.code)
        self:doAgain()
        return
    end

    self.robot:eventHandle("onRegisterOk", rsp)

    self:doDone()
end

return httpRegisterTask
