local cell = require "cell"
local code = require "code"
local const = require "const"
local timer = require "timer"
local log = require "log"
local tokenUtil = require "utils.tokenUtil"
local cluster = require "cluster"
local env = require "env"
local protoUtil = require "utils.protoUtil"
local hotfix = require "hotfix.helper"

local connectMap = {} -- fd -> {fd = fd, watchdog = watchdog, auth = false, uid = uid}
local sessionMap = {} -- uid -> {fd = fd, gameNode = gameNode, gameAgent = gameAgent, heart = heart}
local nodeName = env.getconfig("nodeName")

local gate = {}

local function heart()
    local currentTime = os.time()
    for uid, session in pairs(sessionMap) do
        if currentTime - session.heart >= const.WAIT_SOCKET_EXPIRE_TIME then
            gate.kick(uid)
        end
    end
end

local function doAuth(msg)
    if msg.cmdStr ~= "login.authToken" then
        return false, "login.authTokenRsp", {
            code = code.TOKEN_AUTH_FAIL
        }
    end
    local ok, errStr = tokenUtil.auth(msg.req.uid, msg.req.token)
    if not ok then
        log.errorf("doAuth error %s", errStr)
        return false, "login.authTokenRsp", {
            code = code.TOKEN_AUTH_FAIL
        }
    end
    return true, "login.authTokenRsp", {
        code = code.OK
    }, msg.req.uid
end

-- watchdogSrv -> gateSrv
function gate.open(fd, watchdog)
    connectMap[fd] = {
        fd = fd,
        watchdog = watchdog,
        auth = false
    }
end

-- watchdogSrv -> gateSrv
function gate.close(fd)
    local c = connectMap[fd]
    connectMap[fd] = nil
    if not c or not c.uid or c.replace then
        return
    end
    local s = sessionMap[c.uid]
    sessionMap[c.uid] = nil
    if not s or not s.game or not s.gameAgent then
        return
    end
    local ok, error = pcall(cluster.call, s.game, s.gameAgent, "logout", c.uid)
    if not ok then
        log.errorf("logout gameAgent error, game = %s, gameAgent = %s, uid = %s", string.toString(s.game),
            string.toString(s.gameAgent), string.toString(c.uid))
    end
    ok, error = pcall(cluster.call, "master", "accountMgr", "logout", c.uid)
    if not ok then
        log.errorf("logout accountMgr error, uid = %s", string.toString(c.uid))
    end
end

-- watchdogSrv -> gateSrv
function gate.forward(fd, msg)
    local c = connectMap[fd]
    if not c then
        return
    end

    if not c.auth then
        local authSucc, protoName, res, uid = doAuth(msg)
        if not authSucc then
            cell.send(c.watchdog, "push2C", fd, protoName, res)
            cell.send(c.watchdog, "close", fd)
            return
        end

        c.auth = true
        c.uid = uid

        local s = sessionMap[uid]
        if s then
            if s.fd ~= fd then
                local oldC = connectMap[s.fd]
                if oldC then
                    oldC.replace = true
                    cell.send(oldC.watchdog, "push2C", s.fd, "login.serverCodeNot", {
                        code = code.REPLACE_LOGIN
                    })
                    cell.send(oldC.watchdog, "close", s.fd)
                end
                s.fd = fd
            end
            s.heart = os.time()
        else
            local newSession = {
                fd = fd,
                heart = os.time(),
                gate = nodeName
            }

            cluster.call("master", "accountMgr", "setGate", uid, newSession.gate)

            local gameServer = cluster.call("master", "serverMgr", "dispatchServer", "game", uid)
            if not gameServer then
                gate.kick(uid)
                return
            end

            local gameAgent = cluster.call(gameServer.nodeName, "gameSrv", "getSrvIdByHash", uid)
            if not gameAgent then
                gate.kick(uid)
                return
            end

            newSession.game = gameServer.nodeName
            newSession.gameAgent = gameAgent

            local ok = cluster.call(gameServer.nodeName, gameAgent, "login", uid, newSession)
            if not ok then
                gate.kick(uid)
                return
            end

            if not connectMap[fd] then
                gate.kick(uid)
                return
            end

            sessionMap[uid] = newSession
        end
        cell.send(c.watchdog, "push2C", fd, protoName, res)
        return
    end

    local s = sessionMap[c.uid]
    if not s then
        cell.send(c.watchdog, "push2C", fd, "login.serverCodeNot", {
            code = code.UNKNOWN
        })
    else
        s.heart = os.time()

        msg.req.uid = c.uid

        cluster.send(s.game, s.gameAgent, "protoData", msg)
    end
end

-- gateSrv -> watchdogSrv
function gate.push2C(uid, protoName, res)
    local session = sessionMap[uid]
    if not session then
        return
    end
    local fd = session.fd
    if not fd then
        return
    end
    local c = connectMap[fd]
    if not c or not c.watchdog then
        return
    end
    cell.send(c.watchdog, "push2C", fd, protoName, res)
end

-- gateSrv -> watchdogSrv
function gate.push2CByCmd(uid, cmd, res)
    local session = sessionMap[uid]
    if not session then
        return
    end
    local fd = session.fd
    if not fd then
        return
    end
    local c = connectMap[fd]
    if not c or not c.watchdog then
        return
    end
    cell.send(c.watchdog, "push2CByCmd", fd, cmd, res)
end

-- gateSrv -> watchdogSrv
function gate.broadcast(protoName, res)
    local watchdogMap = {}
    for _, c in pairs(connectMap) do
        watchdogMap[c.watchdog] = true
    end
    for watchdog, _ in pairs(watchdogMap) do
        cell.send(watchdog, "broadcast", protoName, res)
    end
end

-- gateSrv -> watchdogSrv
function gate.multicast(uids, protoName, res)
    local watchdogMap = {}
    for _, uid in ipairs(uids) do
        local session = sessionMap[uid]
        if not session then
            goto continue
        end
        local fd = session.fd
        if not fd then
            goto continue
        end
        local c = connectMap[fd]
        if not c then
            goto continue
        end
        local watchdog = c.watchdog
        if not watchdog then
            goto continue
        end
        if not watchdogMap[watchdog] then
            watchdogMap[watchdog] = {}
        end
        table.insert(watchdogMap[watchdog], fd)

        ::continue::
    end
    for watchdog, fds in pairs(watchdogMap) do
        cell.send(watchdog, "multicast", fds, protoName, res)
    end
end

-- gateSrv -> watchdogSrv
function gate.kick(uid, protoName, res)
    local session = sessionMap[uid]
    if not session then
        return
    end
    sessionMap[uid] = nil
    local fd = session.fd
    if not fd then
        return
    end
    local c = connectMap[fd]
    if not c or not c.watchdog then
        return
    end
    if protoName and res then
        cell.send(c.watchdog, "push2C", fd, protoName, res)
    end
    cell.send(c.watchdog, "close", fd)
end

function gate.init()
    protoUtil.init()
    timer.timeOut(const.WAIT_SOCKET_EXPIRE_TIME, heart)
end

function gate.updateConfig()

end

function gate.updateLogic(files)
    hotfix.init()
    hotfix.update(files)
end

function gate.updateProto()
    protoUtil.update()
end

return gate
