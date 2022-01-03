local cell = require "cell"
local log = require "log"

local ostime = os.time
local osdate = os.date

local INVALID_NUMBER = -1 -- 无效数字

-- 时间类的定义
local timeClass = Class("time")
function timeClass:ctor()
    self.year = INVALID_NUMBER -- 年
    self.month = INVALID_NUMBER -- 月
    self.day = INVALID_NUMBER -- 日
    self.hour = INVALID_NUMBER -- 小时
    self.min = INVALID_NUMBER -- 分钟
    self.sec = INVALID_NUMBER -- 秒
end

-- 时间事件类的定义
local timeEventClass = Class("timeEvent")
function timeEventClass:ctor()
    self.func = nil -- 函数指针
    self.args = {} -- 函数参数
    self.time = timeClass.new() -- 时间
end

local timer = {}

-- 每隔多久(单位是秒)
function timer.timeOut(timeCount, func, ...)
    local timeEventObj = timeEventClass.new()

    timeEventObj.func = func -- 函数指针
    timeEventObj.args = table.pack(...) -- 函数参数

    timeEventObj.time.sec = timeCount

    local function doWork(obj)
        cell.timeout(
            obj.time.sec * 1000,
            function()
                local ok, err = pcall(obj.func, table.unpack(obj.args))
                if not ok then
                    log.error(err)
                end
                doWork(obj)
            end
        )
    end

    doWork(timeEventObj)
end

-- 每小时
function timer.timeOfHour(min, sec, func, ...)
    local timeEventObj = timeEventClass.new()

    timeEventObj.func = func -- 函数指针
    timeEventObj.args = table.pack(...) -- 函数参数

    -- 计算第一次开始的时间
    local nowTime = osdate("*t")
    timeEventObj.time.year = nowTime.year
    timeEventObj.time.month = nowTime.month
    timeEventObj.time.day = nowTime.day
    timeEventObj.time.hour = nowTime.hour
    timeEventObj.time.min = min
    timeEventObj.time.sec = sec

    if ostime(nowTime) >= ostime(timeEventObj.time) then
        timeEventObj.time.hour = timeEventObj.time.hour + 1
    end

    local function doWork(obj)
        cell.timeout(
            (ostime(obj.time) - ostime()) * 1000,
            function()
                local ok, err = pcall(obj.func, table.unpack(obj.args))
                if not ok then
                    log.error(err)
                end
                obj.time.hour = obj.time.hour + 1 -- 每小时
                doWork(obj)
            end
        )
    end

    doWork(timeEventObj)
end

-- 每天
function timer.timeOfDay(hour, min, sec, func, ...)
    local timeEventObj = timeEventClass.new()

    timeEventObj.func = func -- 函数指针
    timeEventObj.args = table.pack(...) -- 函数参数

    -- 计算第一次开始的时间
    local nowTime = osdate("*t")
    timeEventObj.time.year = nowTime.year
    timeEventObj.time.month = nowTime.month
    timeEventObj.time.day = nowTime.day
    timeEventObj.time.hour = hour
    timeEventObj.time.min = min
    timeEventObj.time.sec = sec

    if ostime(nowTime) >= ostime(timeEventObj.time) then
        timeEventObj.time.day = timeEventObj.time.day + 1
    end

    local function doWork(obj)
        cell.timeout(
            (ostime(obj.time) - ostime()) * 1000,
            function()
                local ok, err = pcall(obj.func, table.unpack(obj.args))
                if not ok then
                    log.error(err)
                end
                obj.time.day = obj.time.day + 1 -- 每天
                doWork(obj)
            end
        )
    end

    doWork(timeEventObj)
end

-- 每周(1表示周日)
function timer.timeOfWeek(wday, hour, min, sec, func, ...)
    local timeEventObj = timeEventClass.new()

    timeEventObj.func = func -- 函数指针
    timeEventObj.args = table.pack(...) -- 函数参数

    -- 计算第一次开始的时间
    local nowTime = osdate("*t")
    timeEventObj.time.year = nowTime.year
    timeEventObj.time.month = nowTime.month
    timeEventObj.time.hour = hour
    timeEventObj.time.min = min
    timeEventObj.time.sec = sec

    if nowTime.wday > wday then
        timeEventObj.time.day = nowTime.day + wday + 7 - nowTime.wday
    elseif nowTime.wday == wday then
        timeEventObj.time.day = nowTime.day
        if ostime(nowTime) > ostime(timeEventObj.time) then
            timeEventObj.time.day = timeEventObj.time.day + 7
        end
    else
        timeEventObj.time.day = nowTime.day + (wday - nowTime.wday)
    end

    local function doWork(obj)
        cell.timeout(
            (ostime(obj.time) - ostime()) * 1000,
            function()
                local ok, err = pcall(obj.func, table.unpack(obj.args))
                if not ok then
                    log.error(err)
                end
                obj.time.day = obj.time.day + 7
                doWork(obj)
            end
        )
    end

    doWork(timeEventObj)
end

-- 每月
function timer.timeOfMonth(day, hour, min, sec, func, ...)
    local timeEventObj = timeEventClass.new()

    timeEventObj.func = func -- 函数指针
    timeEventObj.args = table.pack(...) -- 函数参数

    -- 计算第一次开始的时间
    local nowTime = osdate("*t")
    timeEventObj.time.year = nowTime.year
    timeEventObj.time.month = nowTime.month
    timeEventObj.time.day = day
    timeEventObj.time.hour = hour
    timeEventObj.time.min = min
    timeEventObj.time.sec = sec

    if ostime(nowTime) >= ostime(timeEventObj.time) then
        timeEventObj.time.month = timeEventObj.time.month + 1
    end

    local function doWork(obj)
        cell.timeout(
            (ostime(obj.time) - ostime()) * 1000,
            function()
                local ok, err = pcall(obj.func, table.unpack(obj.args))
                if not ok then
                    log.error(err)
                end
                obj.time.month = obj.time.month + 1
                doWork(obj)
            end
        )
    end

    doWork(timeEventObj)
end

-- 特定时间
function timer.specificTime(year, month, day, hour, min, sec, func, ...)
    local timeEventObj = timeEventClass.new()

    timeEventObj.func = func -- 函数指针
    timeEventObj.args = table.pack(...) -- 函数参数

    -- 计算第一次开始的时间
    timeEventObj.time.year = year
    timeEventObj.time.month = month
    timeEventObj.time.day = day
    timeEventObj.time.hour = hour
    timeEventObj.time.min = min
    timeEventObj.time.sec = sec

    if ostime() >= ostime(timeEventObj.time) then
        return
    end

    local function doWork(obj)
        cell.timeout(
            (ostime(obj.time) - ostime()) * 1000,
            function()
                local ok, err = pcall(obj.func, table.unpack(obj.args))
                if not ok then
                    log.error(err)
                end
            end
        )
    end

    doWork(timeEventObj)
end

return timer
