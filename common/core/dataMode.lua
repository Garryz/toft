local lfsUtil = require "utils.lfs"
local log = require "log"

local m = {}

local function getAllDataClasses()
    local dataClasses = {}
    local files = lfsUtil.getLuaFiles("./dev/selfModules")
    for _, file in ipairs(files) do
        dataClasses[file] = require("selfModules." .. file)
    end

    return dataClasses
end

function m.getPersonalDataClasses()
    local dataClasses = {}
    local files = lfsUtil.getLuaFiles("./dev/selfModules")
    for _, file in ipairs(files) do
        dataClasses[file] = require("selfModules." .. file)
    end

    return dataClasses
end

function m.initMysqlTables(force)
    log.info("初始化数据库中")
    for _, v in pairs(getAllDataClasses()) do
        local obj = v.new()
        obj:initMysqlTable(force)
    end
    log.info("初始化数据库完成")
end

return m
