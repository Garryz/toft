local taskMgr = require "taskMgr"
local log = require "log"
local protoUtil = require "utils.protoUtil"
local cell = require "cell"

local robot = Class("robot")

function robot:ctor(name, processId)
    self.name = name -- 机器人名称
    self.uid = 0 -- 玩家uid
    self.sock = nil -- gate网关socket
    self.connectType = 0 -- 1 tcp 2 websock
    self.inGame = false -- 是否在游戏中
    self.lstKeepaliveTime = 0 -- 上次发送游戏心跳包时间

    self.taskMgr = taskMgr.new(self, processId) -- 创建任务管理器
end

function robot:initSock(sock, connectType)
    self.sock = sock
    self.connectType = connectType
    self.inGame = false
    self.lstKeepaliveTime = 0
    if sock == nil and connectType == nil then
        self:eventHandle("onSockClose")
    else
        cell.fork(robot.dispatch, self)
    end
end

function robot:init()
    -- 初始化任务管理器
    self.taskMgr:init()
end

function robot:activate()
    self.taskMgr:activate()

    -- 发送游戏心跳包
    self:keepAlive()
end

-- 发送心跳包
function robot:keepAlive()
    local curTime = os.time()
    if self.inGame and self.lstKeepaliveTime + 30 < curTime then
        -- 已经登陆游戏且间隔30秒
        self:send2S("login.keepAliveReq", {})
        self.lstKeepaliveTime = curTime
    end
end

-- 发送协议到游戏服
function robot:send2S(protoName, protoArgs)
    if not self.sock then
        log.infof("[%s] robot:send2S not sock", self.name)
        return
    end

    local ok, cmd, str = protoUtil.encodeReqByProto(protoName, protoArgs)
    if not ok then
        log.infof("encode %s error", protoName)
        return
    end
    local msg = string.pack(">I2>I2c" .. #str, cmd, #str, str)
    if self.connectType == 1 then
        self.sock:write(msg)
    elseif self.connectType == 2 then
        self.sock:writemsg(msg, "binary")
    end
end

function robot:readTcpMsg()
    local body = self.sock:readbytes(4)
    if not body then
        self:initSock(nil, nil)
        return false
    end
    local cmd, len = string.unpack(">I2>I2", body)
    if not cmd or not len then
        self:initSock(nil, nil)
        return false
    end
    body = ""
    if len > 0 then
        body = self.sock:readbytes(len)
        if not body then
            self:initSock(nil, nil)
            return false
        end
    end
    local data = string.unpack("c" .. len, body)
    if not data then
        self:initSock(nil, nil)
        return false
    end
    return true, cmd, data
end

function robot:readWsMsg()
    local ok, body =
        pcall(
        function()
            return self.sock:readmsg()
        end
    )
    if not ok or not body then
        self:initSock(nil, nil)
        return false
    end
    local cmd, len = string.unpack(">I2>I2", body)
    if not cmd or not len then
        self:initSock(nil, nil)
        return false
    end
    local data = string.unpack("c" .. len, body, 5)
    if not data then
        self:initSock(nil, nil)
        return false
    end
    return true, cmd, data
end

-- 接收服务器网关，游戏协议数据
function robot:dispatch()
    while true do
        if not self.sock then
            return
        end
        local ok, cmd, data
        if self.connectType == 1 then
            ok, cmd, data = self:readTcpMsg()
        elseif self.connectType == 2 then
            ok, cmd, data = self:readWsMsg()
        end

        if not ok then
            return
        end
        local ok, cmdStr, rsp = protoUtil.decodeRspByCmd(cmd, data)
        if not ok then
            return
        end

        -- 通过事件派发协议数据
        self:eventHandle(cmdStr, rsp)
    end
end

-- 事件派发
function robot:eventHandle(eventName, ...)
    if self[eventName] and type(self[eventName]) == "function" then
        self[eventName](self, ...)
    end

    self.taskMgr:eventHandle(eventName, ...)
end

function robot:onLoginGameOk()
    self.inGame = true
end

return robot
