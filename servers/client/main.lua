local cell = require "cell"
local log = require "log"
local machine = require "machine"
local env = require "env"

function cell.main()
    log.info("client start")

    machine.init()

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
        local name = string.format("%s_%05d", robotName, i)
        cell.call(addr, "doStart", name, processId)
    end

    log.info("client start end")
end
