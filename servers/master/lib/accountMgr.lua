local log = require "log"

local accountMgr = {}
-- 状态
local STATUS = {
    LOGIN = 1,
    GAME = 2,
    LOGOUT = 3
}

-- 玩家列表
local accounts = {} -- accounts[uid] = {uid = uid, status = status}

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
        -- TODO
        account.status = STATUS.LOGOUT
    end
    -- 上线
    local account = {
        uid = uid,
        status = STATUS.LOGIN
    }
    accounts[uid] = account
    return true
end

return accountMgr
