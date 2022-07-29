local cell = require "cell"
local code = require "code"
local const = require "const"
local timer = require "timer"
local log = require "log"
local protoUtil = require "utils.protoUtil"
local tokenUtil = require "utils.tokenUtil"
local cluster = require "cluster"
local env = require "env"

local connectMap = {} -- fd -> {fd = fd, watchdog = watchdog, auth = false, uid = uid}
local sessionMap = {} -- uid -> {fd = fd, gameNode = gameNode, gameAgent = gameAgent, heart = heart}

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
    if msg.cmdStr ~= "login.authTokenReq" then
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
    connectMap[fd] = nil
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
                heart = os.time()
            }

            cluster.send("master", "accountMgr", "setGate", uid, env.getconfig("nodeName"))

            local gameServer = cluster.call("master", "serverMgr", "dispatchServer", "game", uid)
            if not gameServer then
                gate.kick(uid)
                return
            end

            -- TODO 分配game节点 并 login
            -- 检查连接是否存在
            if not connectMap[fd] then
                -- 刚刚分配的game节点 logout
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
        -- TODO 转发给game服
        s.heart = os.time()
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
    -- TODO 通知gameAgent logout
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
    cluster.send("master", "accountMgr", "clearAccount", uid)
end

function gate.init()
    protoUtil.init()
    timer.timeOut(const.WAIT_SOCKET_EXPIRE_TIME, heart)
end

return gate
