local const = {}

-- 任务类型和任务模块名对应
const.taskType = {
    TASK_HTTP_REGISTER = "httpRegisterTask", -- 账号注册任务
    TASK_HTTP_USER_LOGIN = "httpUserLoginTask", -- 账号密码登陆任务
    TASK_TCP_LOGIN_GAME = "tcpLoginGameTask", -- tcp登陆游戏任务
    TASK_WS_LOGIN_GAME = "wsLoginGameTask", -- ws登陆游戏任务
    TAKS_DISSCONNECT_GAME = "disconnectGameTask" -- 断开游戏服连接任务
}

-- 任务状态
const.taskStatus = {
    WAIT = "未开始",
    START = "进行中",
    DONE = "完成"
}

-- 任务过程定义
--[[
	参数说明：
		过程：
			* const.processDef[]的下标为任务过程id， 可以自定义多个任务过程模版。
		任务列表：
			* const.processDef[]{}数组的元素为任务定义，可以自定义多个任务。
		任务：
			* taskType为任务类型const.taskType对应
			* exeInterval 执行间隔（包括第一次启动）
			* times 任务执行次数， -1表示无限次数
			* needDoneTask{} 任务开始的前置完成的任务类型列表，{}为没限制
			* param{} 任务参数 任务自定义字段（选填）
		任务执行顺序：
			* 使用前置任务完成限制顺序
--]]
const.processDef = {
    [1] = {{
        taskType = const.taskType.TASK_HTTP_REGISTER,
        exeInterval = 1,
        times = 1,
        needDoneTask = {},
        param = {
            host = "127.0.0.1:8080"
        }
    }, {
        taskType = const.taskType.TASK_TCP_LOGIN_GAME,
        exeInterval = 1,
        times = 1,
        needDoneTask = {const.taskType.TASK_HTTP_REGISTER}
    } -- {
    --     taskType = const.taskType.TASK_WS_LOGIN_GAME,
    --     exeInterval = 1,
    --     times = 1,
    --     needDoneTask = {const.taskType.TASK_HTTP_REGISTER}
    -- }
    }
}

return const
