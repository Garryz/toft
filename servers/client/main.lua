local cell = require "cell"
local log = require "log"
local machine = require "machine"
local env = require "env"

function cell.main()
    log.info("client start")

    machine.init()

    cell.uniqueservice("service.debugconsole", machine.getDebugPort("client"))

    -- 获取机器人名称
    local robotName = env.getconfig("robotName")
    -- 获取机器人数量
    local robotNum = env.getconfig("robotNum")
    -- 获取过程id
    local processId = env.getconfig("processId")

    -- 创建机器人服务(机器人对应一个robotSrv服务)
    local addrList = {}
    for i = 1, robotNum do
        local addr = cell.newservice("robotSrv")
        table.insert(addrList, addr)
    end

    -- 通知机器人服务开始任务过程
    for i, addr in ipairs(addrList) do
        local name = string.format("%s_%09d", robotName, i)
        cell.call(addr, "doStart", name, processId)
    end

    local protoUtil = require "utils.protoUtil"
    protoUtil.init()
    local playerUtil = require "utils.playerUtil"
    local password1 = playerUtil.getPassword(10001)
    local password2 = playerUtil.getPassword(10001)
    log.infof("分布式玩家数据调用 password1 = %s, password2 = %s", password1, password2)

    log.info("client start end")
end
