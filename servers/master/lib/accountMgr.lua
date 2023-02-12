local log = require "log"
local cluster = require "cluster"
local redisClass = require "redisClass"
local timeUtil = require "utils.timeUtil"
local hotfix = require "hotfix.helper"
local const = require "const"
local timer = require "timer"

local accountMgr = {}
-- 状态
local STATUS = {
    LOGIN = 1,
    GAME = 2,
    LOGOUT = 3
}

local redis = nil

-- 玩家列表
local accounts = {} -- accounts[uid] = {uid = uid, status = status, heart = heart, gate = gate, game = game, gameAgent = gameAgent}

local function heart()
    local currentTime = os.time()
    for uid, account in pairs(accounts) do
        if account.status == STATUS.LOGIN and currentTime - account.heart >= const.WAIT_LOGIN_EXPIRE_TIME then
            accounts[uid] = nil
        end
    end
end

function accountMgr.init()
    redis = redisClass.new("redisSrv", 0)
    timer.timeOut(const.WAIT_LOGIN_EXPIRE_TIME, heart)
end

function accountMgr.login(uid)
    local account = accounts[uid]
    -- 登录过程禁止顶替
    if account and account.status == STATUS.LOGOUT then
        log.error("login fail, at status LOGOUT " .. uid)
        return false
    end
    if account and account.status == STATUS.LOGIN then
        log.error("login fail, at status LOGIN " .. uid)
        return false
    end
    -- 在线，顶替
    if account then
        account.status = STATUS.LOGOUT
        if account.gate then
            cluster.call(account.gate, "gateSrv", "kick", uid, "login.serverCodeNot", {
                code = code.REPLACE_LOGIN
            })
        end
    end
    -- 上线
    local account = {
        uid = uid,
        status = STATUS.LOGIN,
        heart = os.time()
    }
    accounts[uid] = account
    redis:sadd("dailyActive:" .. timeUtil.toDate(), uid)
    return true
end

function accountMgr.setGate(uid, nodeName)
    local account = accounts[uid]
    if not account then
        return
    end

    account.gate = nodeName
end

function accountMgr.setGame(uid, game, gameAgent)
    local account = accounts[uid]
    if not account then
        account = {
            uid = uid
        }
        accounts[uid] = account
    end

    account.game = game
    account.gameAgent = gameAgent
    account.status = STATUS.GAME
end

function accountMgr.getSession(uid)
    local account = accounts[uid]
    if not account then
        return
    end

    return {
        gate = account.gate,
        game = account.game,
        gameAgent = account.gameAgent
    }
end

function accountMgr.logout(uid)
    local account = accounts[uid]
    if not account then
        return false
    end

    if account.status ~= STATUS.GAME then
        return false
    end
    account.status = STATUS.LOGOUT

    accounts[uid] = nil

    return true
end

function accountMgr.logoutInactive(uid)
    local account = accounts[uid]
    if not account then
        return false
    end

    if account.gate then
        account.game = nil
        account.gameAgent = nil
    else
        accounts[uid] = nil
    end

    return true
end

function accountMgr.updateLogic(files)
    hotfix.init()
    hotfix.update(files)
end

return accountMgr
