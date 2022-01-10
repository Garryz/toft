local cell = require "cell"
local timer = require "timer"
local log = require "log"
local robot = require "robot"
local protoUtil = require "utils.protoUtil"

local command = {}

local robotObj = nil
local gcTime = 0

-- 机器人服务初始化接口
function command.doStart(name, processId)
    -- 机器人模块初始化
    robotObj = robot.new(name, processId)
    robotObj:init()

    -- 设置活跃函数定时
    timer.timeOut(1, command.activate)

    log.infof("[%s] doStart processId:%s", name, processId)
end

-- 活跃逻辑接口
function command.activate()
    local curTime = os.time()

    -- 定时清理lua垃圾
    if curTime >= gcTime + 60 then
        gcTime = curTime
        collectgarbage("collect")
    end

    robotObj:activate()
end

cell.command(command)
cell.message(command)

function cell.main()
    protoUtil.init()
end
