local const = require "task.const"
local log = require "log"
local taskMgr = Class("taskMgr")

function taskMgr:ctor(robot, processId)
    assert(robot)
    self.robot = robot -- 机器人实例
    self.processId = processId -- 过程id
    self.taskList = {} -- 任务实例列表
end

-- 任务管理初始化
function taskMgr:init()
    assert(self.processId, "not processId")

    -- 读取过程配置，初始化任务列表
    local process = const.processDef[self.processId]
    for _, cnfTask in ipairs(process) do
        table.insert(self.taskList, self:createTask(cnfTask))
    end

    log.infof("taskMgr:init [%s] task init finish", self.robot.name)
end

-- 根据任务类型创建实例
function taskMgr:createTask(cnfTask)
    local modulePath = "task." .. cnfTask.taskType
    local loadModule = require(modulePath)
    return loadModule.new(self.robot, cnfTask)
end

-- 任务管理器活跃逻辑
function taskMgr:activate()
    for _, task in pairs(self.taskList) do
        if self:checkTaskStart(task) then
            task:doStart()
        end
    end
end

-- 检查指定任务是否能开始
function taskMgr:checkTaskStart(task)
    if task.status == const.taskStatus.START then
        return false
    end

    if task.times and task.times > 0 and task.times <= task.doneTimes then
        return false
    end

    if not self.robot.inGame then
        if
            not (task.taskType == const.taskType.TASK_HTTP_REGISTER or
                task.taskType == const.taskType.TASK_HTTP_USER_LOGIN or
                task.taskType == const.taskType.TASK_TCP_LOGIN_GAME or
                task.taskType == const.taskType.TASK_WS_LOGIN_GAME)
         then
            return false
        end
    end

    if task.nextStartTime > os.time() then
        return false
    end

    return true
end

function taskMgr:checkTaskNeedInGame(task)
    if
        task.taskType == const.taskType.TASK_HTTP_REGISTER or task.taskType == const.taskType.TASK_HTTP_USER_LOGIN or
            task.taskType == const.taskType.TASK_TCP_LOGIN_GAME or
            task.taskType == const.taskType.TASK_WS_LOGIN_GAME or
            task.taskType == const.taskType.TAKS_DISSCONNECT_GAME
     then
        return false
    end

    if not self.robot.inGame then
        if task.status == const.taskStatus.START then
            task:doAgain()
        end
        return true
    end

    return false
end

-- 事件派发处理
function taskMgr:eventHandle(eventName, ...)
    if self[eventName] and type(self[eventName]) == "function" then
        self[eventName](self, ...)
    end

    for _, task in ipairs(self.taskList) do
        if task[eventName] and type(task[eventName]) == "function" then
            if not self:checkTaskNeedInGame(task) then
                task[eventName](task, ...)
            end
        end
    end
end

return taskMgr
