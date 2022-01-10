-- 登陆游戏服任务

local baseTask = require "task.baseTask"
local log = require "log"
local socket = require "socket"
local const = require "task.const"

local tcpLoginGameTask = Class("tcpLoginGameTask", baseTask)

function tcpLoginGameTask:ctor(robot, cnfTask)
    tcpLoginGameTask.super.ctor(self, robot, cnfTask)

    self.host = nil
    self.port = nil
    self.token = nil
    self.uid = nil
end

function tcpLoginGameTask:doStart()
    tcpLoginGameTask.super.doStart(self)

    if self.robot.sock then
        log.infof("[%s] tcpLoginGameTask:doStart in game", self.robot.name)
        self:doAgain()
        return
    end

    assert(self.host and self.port)
    local sock = socket.connect(self.host, self.port)

    if not sock then
        self:doAgain()
        return
    end

    self.robot:initSock(sock, 1)

    self.robot:send2S("login.authTokenReq", {uid = self.uid, token = self.token})
end

function tcpLoginGameTask:login_authTokenRsp(data)
    if self.status ~= const.taskStatus.START then
        return
    end

    log.infof("login_authTokenRsp %s", string.toString(data))

    self.robot:eventHandle("onLoginGameOk")

    self:doDone()
end

function tcpLoginGameTask:onRegisterOk(data)
    self.host = data.host
    self.port = data.port
    self.token = data.token
    self.uid = data.uid

    self.robot.uid = self.uid
    log.infof("tcpLoginGameTask:onRegisterOk [%s]->uid:%s", self.robot.name, self.uid)
end

return tcpLoginGameTask
