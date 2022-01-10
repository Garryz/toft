local cell = require "cell"
local protoUtil = require "utils.protoUtil"
local socket = require "socket"
local const = require "const"
local timer = require "timer"
local log = require "log"

local watchdog = {}

local socks = {} -- fd -> sock
local waitFds = {} -- fd -> connectTime

local handler = {}

function handler.acceptSock(fd, addr, conf)
    -- return sock
end

function handler.readMsg(sock)
    -- return true, cmd, data
end

function handler.writeMsg(sock, cmd, msg)
    -- sock:write(msg)
end

function handler.closeSock(sock)
    -- sock:disconnect()
end

local function onclose(fd)
    waitFds[fd] = nil
    if socks[fd] then
        socks[fd] = nil
        cell.send("gateSrv", "close", fd)
    end
end

local function expire()
    local currentTime = os.time()
    for fd, connectTime in pairs(waitFds) do
        if currentTime - connectTime >= const.WAIT_SOCKET_EXPIRE_TIME then
            local sock = socks[fd]
            if sock then
                handler.closeSock(sock)
            end
        end
    end
end

local function dispatch(fd)
    return function()
        while true do
            local sock = socks[fd]
            if not sock then
                return
            end
            local ok, cmd, data = handler.readMsg(sock)
            if not ok then
                return
            end
            local ok, cmdStr, req = protoUtil.decodeReqByCmd(cmd, data)
            if not ok then
                goto continue
            end
            waitFds[fd] = nil
            cmdStr = cmdStr:gsub("_", ".")
            local msg = {cmd = cmd, cmdStr = cmdStr, req = req}
            cell.send("gateSrv", "forward", fd, msg)

            ::continue::
        end
    end
end

-- gateSrv -> watchdogSrv
function watchdog.close(fd)
    local sock = socks[fd]
    if sock then
        handler.closeSock(sock)
    end
end

-- gateSrv -> watchdogSrv
function watchdog.push2C(fd, protoName, res)
    local sock = socks[fd]
    if not sock then
        return
    end
    local ok, cmd, resStr = protoUtil.encodeRspByProto(protoName, res)
    if not ok then
        return
    end
    handler.writeMsg(sock, cmd, resStr)
end

-- gateSrv -> watchdogSrv
function watchdog.push2CByCmd(fd, cmd, res)
    local sock = socks[fd]
    if not sock then
        return
    end
    local ok, resStr = protoUtil.encodeRspByCmd(cmd, res)
    if not ok then
        return
    end
    handler.writeMsg(sock, cmd, resStr)
end

-- gateSrv -> watchdogSrv
function watchdog.broadcast(protoName, res)
    local ok, cmd, resStr = protoUtil.encodeRspByProto(protoName, res)
    if not ok then
        return
    end
    for _, sock in pairs(socks) do
        handler.writeMsg(sock, cmd, resStr)
    end
end

-- gateSrv -> watchdogSrv
function watchdog.multicast(fds, protoName, res)
    local ok, cmd, resStr = protoUtil.encodeRspByProto(protoName, res)
    if not ok then
        return
    end
    for _, fd in ipairs(fds) do
        local sock = socks[fd]
        if sock then
            handler.writeMsg(sock, cmd, resStr)
        end
    end
end

function watchdog.init(conf, h)
    handler = h
    protoUtil.init()
    socket.listen(
        conf.host,
        conf.port,
        function(fd, addr, listenSock)
            cell.fork(
                function()
                    local sock = handler.acceptSock(fd, addr, conf)
                    if sock then
                        socks[fd] = sock
                        sock:onclose(onclose)
                        waitFds[fd] = os.time()
                        cell.send("gateSrv", "open", fd, cell.self)
                        cell.fork(dispatch(fd))
                    end
                end
            )
        end
    )
    timer.timeOut(const.WAIT_SOCKET_EXPIRE_TIME, expire)
end

return watchdog
