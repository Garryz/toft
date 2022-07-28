-- 登陆游戏服任务
local baseTask = require "task.baseTask"
local log = require "log"
local websocket = require "http.websocket"
local const = require "task.const"

local wsLoginGameTask = Class("wsLoginGameTask", baseTask)

function wsLoginGameTask:ctor(robot, cnfTask)
    wsLoginGameTask.super.ctor(self, robot, cnfTask)

    self.host = nil
    self.wsport = nil
    self.token = nil
    self.uid = nil
end

function wsLoginGameTask:doStart()
    wsLoginGameTask.super.doStart(self)

    if self.robot.sock then
        log.infof("[%s] wsLoginGameTask:doStart in game", self.robot.name)
        self:doAgain()
        return
    end

    assert(self.host and self.wsport)
    local host = "ws://" .. self.host .. ":" .. self.wsport .. "/"
    local sock = websocket.connect(host)

    if not sock then
        self:doAgain()
        return
    end

    self.robot:initSock(sock, 2)

    self.robot:send2S("login.authTokenReq", {
        uid = self.uid,
        token = self.token
    })
end

function wsLoginGameTask:login_authTokenRsp(data)
    if self.status ~= const.taskStatus.START then
        return
    end

    log.infof("login_authTokenRsp %s", string.toString(data))

    self.robot:eventHandle("onLoginGameOk")

    self:doDone()
end

function wsLoginGameTask:onRegisterOk(data)
    self.host = data.host
    self.wsport = data.wsport
    self.token = data.token
    self.uid = data.uid

    self.robot.uid = self.uid
    log.infof("wsLoginGameTask:onRegisterOk [%s]->uid:%s", self.robot.name, self.uid)
end

return wsLoginGameTask
