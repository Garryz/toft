local cell = require "cell"
local redisClass = require "redisClass"
local const = require "const"
local machine = require "machine"
local timer = require "timer"
local log = require "log"
local backupRole = require "backupRole"
local timeUtil = require "utils.timeUtil"
local cluster = require "cluster"
local hotfix = require "hotfix.helper"

local backup = {}

local backupDays = const.BACKUP_DAYS

local redis = nil

local function getDay(timestamp)
    return math.floor(timestamp / (3600 * 24))
end

local function getSecsSwapLoginTime()
    local swapDays = backupDays - 5
    if swapDays < 7 then
        swapDays = 7
    end
    if machine.isTest() then
        swapDays = 1
    end
    return swapDays * 24 * 3600
end

local function swapOneDay(key, inactive)
    log.infof("swapOneDay key[%s]", string.toString(key))
    local uidList = redis:smembers(key)
    if not next(uidList) then
        return false
    end

    local secsSwapLoginTime = getSecsSwapLoginTime()

    for _, uid in ipairs(uidList) do
        local role = backupRole.new(tonumber(uid))
        -- 是否已备份
        local isExist = role:isExist()
        if isExist then
            -- 最后登录时间
            local loginTime = role:getLoginTime()
            if loginTime and (loginTime == 0 or timeUtil.currentTime() > loginTime + secsSwapLoginTime) then
                local session = cluster.call("master", "accountMgr", "getSession", uid)
                if session and session.game and session.gameAgent and inactive then
                    cluster.send(session.game, session.gameAgent, "logoutInactive", uid)
                end

                local ok = role:loadRedisData()
                if not ok then
                    log.errorf("swapOneDay key[%s] uid[%s] loadRedisData error ", string.toString(key), uid)
                    return false
                end
                ok = role:backupToMysql()
                if not ok then
                    log.errorf("swapOneDay key[%s] uid[%s] backupToMysql error ", string.toString(key), uid)
                    return false
                end
                if not session or not session.gate then
                    role:delRedisData()
                end
            end
            cell.sleep(2)
        end
    end

    redis:del(key)
    return true
end

local function swapProcessThread()
    local currDay = getDay(timeUtil.currentTime())

    local function swap(keys, inactive)
        if not next(keys) then
            return
        end

        for _, v in ipairs(keys) do
            local time = string.split(v, ":")
            time = string.split(time[2], "-")
            local day = getDay(timeUtil.getTime(time[1], time[2], time[3]))
            if currDay - day > backupDays then
                local ok, r = pcall(swapOneDay, v, inactive)
                if not ok then
                    log.errorf("swapOneDay error %s", r or "")
                end
            end
        end
    end

    local activeKeys = redis:keys("dailyActive:*")
    swap(activeKeys)

    local inactiveKeys = redis:keys("dailyInactive:*")
    swap(inactiveKeys, true)
end

function backup.init()
    if machine.isTest() then
        backupDays = 1
    end

    redis = redisClass.new("redisSrv", 0)

    timer.timeOfDay(2, 0, 0, swapProcessThread)
end

function backup.updateLogic(files)
    hotfix.init()
    hotfix.update(files)
end

return backup
