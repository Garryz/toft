local cell = require "cell"
local cluster = require "cluster"
local env = require "env"
local code = require "code"

local nodeName = env.getconfig("nodeName")
local playerUtil = {}

local function getContext(uid, cmd, args)
    local session = cluster.call("master", "accountMgr", "getSession", uid)
    if session and session.game and session.gameAgent then
        if nodeName == session.game then
            return cell.call(session.gameAgent, "getContext", uid, cmd, args)
        else
            return cluster.call(session.game, session.gameAgent, "getContext", uid, cmd, args)
        end
    else
        local gameServer = cluster.call("master", "serverMgr", "dispatchServer", "game", uid)
        if not gameServer then
            return
        end

        local gameAgent = cluster.call(gameServer.nodeName, "gameSrv", "getSrvIdByHash", uid)
        if not gameAgent then
            return
        end

        return cluster.call(gameServer.nodeName, gameAgent, "getContext", uid, cmd, args)
    end
end

function playerUtil.getPassword(uid)
    local errcode, password = getContext(uid, "login.getPassword")
    if errcode and errcode == code.OK then
        return password
    end
end

return playerUtil
