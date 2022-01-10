local const = require "task.const"
local log = require "log"

local baseTask = Class("baseTask")

function baseTask:ctor(robot, cnfTask)
    assert(robot)
    self.robot = robot
    self.taskType = cnfTask.taskType
    self.exeInterval = cnfTask.exeInterval
    self.times = cnfTask.times
    self.needDoneTask = cnfTask.needDoneTask

    self.status = const.taskStatus.WAIT
    self.doneTimes = 0
    self.nextStartTime = 0
end

-- 任务开始时调用
function baseTask:doStart()
    self.status = const.taskStatus.START
    log.infof("[%s] task start, type:%s", self.robot.name, self.taskType)
    self.robot:eventHandle("onTaskStart", self.taskType)
end

-- 任务完成时调用
function baseTask:doDone()
    self.status = const.taskStatus.DONE
    self.doneTimes = self.doneTimes + 1
    self.nextStartTime = os.time() + self.exeInterval
    log.infof("[%s] task done, type:%s", self.robot.name, self.taskType)
    self.robot:eventHandle("onTaskDone", self.taskType)
end

-- 任务需要重新执行时调用
function baseTask:doAgain()
    self.status = const.taskStatus.WAIT
    self.nextStartTime = os.time() + self.exeInterval
    log.infof("[%s] task again, type:%s", self.robot.name, self.taskType)
end

return baseTask
