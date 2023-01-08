-- 登录任务
local baseTask = require "task.baseTask"
local protoUtil = require "utils.protoUtil"
local log = require "log"
local httpc = require "http.httpc"
local code = require "code"

local httpLoginTask = Class("httpLoginTask", baseTask)

function httpLoginTask:ctor(robot, cnfTask)
    httpLoginTask.super.ctor(self, robot, cnfTask)

    self.host = cnfTask.param.host

    self.username = cnfTask.param.username
    self.password = cnfTask.param.password
end

function httpLoginTask:doStart()
    httpLoginTask.super.doStart(self)

    local req = {
        username = self.username,
        password = self.password
    }
    local ok, cmd, resStr = protoUtil.encodeReqByProto("login.loginReq", req)
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

    self.robot:eventHandle("onRegisterOK", rsp)

    self:doDone()
end

return httpLoginTask
