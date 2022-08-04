local cell = require "cell"

local os = os
local math = math
local tonumber = tonumber

local timeUtil = {}

-- 获取当前时间 单位秒
function timeUtil.currentTime()
    return math.floor(cell.time())
end

function timeUtil.toString(t)
    return os.data("%Y-%m-%d %H:%M:%S", t or timeUtil.currentTime())
end

function timeUtil.toDate(t)
    return os.date("%Y-%m-%d", t or timeUtil.currentTime())
end

function timeUtil.toTab(t)
    return os.date("*t", t)
end

function timeUtil.toInt(tab)
    return os.time(tab)
end

function timeUtil.getYday(t)
    return os.date("%j", t)
end

-- 获取时间的0点时间戳
function timeUtil.getCday(ctime)
    local a = timeUtil.toTab(ctime)
    a.hour, a.min, a.sec = 0, 0, 0
    return timeUtil.toInt(a)
end

-- 将时间格式化秒 %Y-%m-%d %H:%M:%S
function timeUtil.getSecond(t)
    local a = string.split(t, " ")
    local b = string.split(a[1], "-")
    local c = string.split(a[2], ":")

    return timeUtil.toInt({
        year = b[1],
        month = b[2],
        day = b[3],
        hour = c[1],
        min = c[2],
        sec = c[3]
    })
end

function timeUtil.getDayCount(year, month)
    local year = tonumber(year)
    local month = tonumber(month)
    if not year or not month then
        return 0
    end

    if month == 1 or month == 3 or month == 5 or month == 7 or month == 8 or month == 10 or month == 12 then
        return 31
    end

    if month == 2 then
        if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
            return 29
        else
            return 28
        end
    end

    return 30
end

function timeUtil.getTime(year, month, day, hour, min, sec)
    local timeStruct = {}
    timeStruct.sec = tonumber(sec) or 0
    timeStruct.min = tonumber(min) or 0
    timeStruct.hour = tonumber(hour) or 0
    timeStruct.day = tonumber(day) or 0
    timeStruct.month = tonumber(month) or 0
    timeStruct.year = tonumber(year) or 0

    return timeUtil.toInt(timeStruct)
end

-- 两个时间相距天数
function timeUtil.getDisDays(t1, t2)
    if t1 == nil or t2 == nil then
        return 0
    end

    local d1 = timeUtil.getYday(t1)
    local d2 = timeUtil.getYday(t2)
    return math.abs(d1 - d2)
end

function timeUtil.isSameDay(t1, t2)
    if t1 == nil or t2 == nil then
        return false
    end
    local d1 = timeUtil.getYday(t1)
    local d2 = timeUtil.getYday(t2)
    if d1 == d2 then
        return true
    end
    return false
end

function timeUtil.isSameMonth(t1, t2)
    if t1 == nil or t2 == nil then
        return false
    end
    local n1 = os.date("*t", t1)
    local n2 = os.date("*t", t2)
    if n1.year == n2.year and n1.month == n2.month then
        return true
    end
    return false
end

-- 获取当天开始时间
function timeUtil.getDayStartTime(currTime, days)
    local daySec = 24 * 3600
    local addDay = days or 0
    local timeout = math.floor((currTime + 8 * 3600) / daySec) * daySec + daySec * addDay - 8 * 3600

    return timeout
end

-- 获取当天结束时间
function timeUtil.getDayEndTime(currTime, days)
    local daySec = 24 * 3600
    local addDay = days or 1
    local timeout = math.floor((currTime + 8 * 3600) / daySec) * daySec + daySec * addDay - 8 * 3600 - 1
end

-- 获取当天0点时间戳
function timeUtil.getUnixtimeToday(t1)
    local nt = os.date("*t", t1)
    return os.time({
        year = nt.year,
        month = nt.month,
        day = nt.day,
        hour = 0,
        min = 0,
        sec = 0
    })
end

-- 获取明天0点时间戳
function timeUtil.getUnixtimeTomorrow(t1)
    return timeUtil.getUnixtimeToday(t1) + 86400
end

return timeUtil
