local cell = require "cell"
local const = require "const"
local env = require "env"
local machine = require "machine"
local cluster = require "cluster"
local timer = require "timer"
local log = require "log"
local lfsUtil = require "utils.lfs"

local steward = {}

local services = {}

local fileTimes = {}

local weight = const.SERVER_DEFAULT_WEIGHT
local load = 0

local function pingMaster()
    local nodeType = env.getconfig("nodeType")
    local nodeName = env.getconfig("nodeName")
    local serverData = {
        weight = weight,
        nodeType = nodeType,
        nodeName = nodeName
    }
    local tcpConf = machine.getTcpListenConf(nodeName)
    serverData.host = tcpConf.host
    serverData.port = tcpConf.port
    local wsConf = machine.getWsListenConf(nodeName)
    serverData.wsPort = wsConf.port
    serverData.wsProtocol = wsConf.protocol
    serverData.load = load
    cluster.send("master", "serverMgr", "serverHeartbeat", serverData)
end

-- 排除文件
local function excludeFile(dir)
    -- 服务文件目录
    if dir:match("service") then
        return true
    end
    -- hive目录
    if dir:match("hive") then
        return true
    end
    -- 协议目录
    if dir:match("proto") or dir:match("pb") then
        return true
    end
    -- 配置文件目录 TODO
    -- if dir:match(configPath) then
    --     return true
    -- end
    -- hotfix 目录
    if dir:match("hotfix") then
        return true
    end
    -- main 文件
    if dir:match("main") then
        return true
    end
end

-- 获取逻辑文件路径
local function getLogicDirs()
    local res = {}

    local luaDirs = string.split(package.path, ";")
    for _, value in ipairs(luaDirs) do
        if not excludeFile(value) then
            table.insert(res, string.rtrim(value, "?.lua"))
        end
    end

    return res
end

local function getAllFileMod()
    local res = {}

    local logicDirs = getLogicDirs()

    local fileList = {}
    for _, logicDir in ipairs(logicDirs) do
        local files = lfsUtil.getLuaFiles(logicDir)
        for _, file in ipairs(files) do
            local dir = string.format("%s%s", logicDir, file)
            if not excludeFile(dir) then
                fileList[dir] = file:gsub("/", ".")
            end
        end
    end

    for dir, file in pairs(fileList) do
        res[file] = lfsUtil.getFileModification(dir .. ".lua") -- 文件修改时间
    end

    return res
end

local function getChangeFiles()
    local changeList = {}
    local newFileTimes = getAllFileMod()
    for file, time in pairs(newFileTimes) do
        if time ~= fileTimes[file] then
            table.insert(changeList, file)
        end
    end

    fileTimes = newFileTimes
    return changeList
end

function steward.init(isMaster)
    if not isMaster then
        timer.timeOut(1, pingMaster)
    end
    fileTimes = getAllFileMod()
end

function steward.serverDown(downClusterMap)
    log.info("steward.serverDown", string.toString(downClusterMap))
end

function steward.updateConfig()
    for c, funcMap in pairs(services) do
        if funcMap["updateConfig"] then
            cell.send(c, funcMap["updateConfig"])
        end
    end
end

function steward.updateLogic()
    local files = getChangeFiles()

    if not next(files) then
        return
    end

    for c, funcMap in pairs(services) do
        if funcMap["updateLogic"] then
            cell.send(c, funcMap["updateLogic"], files)
        end
    end
end

function steward.updateProto()
    for c, funcMap in pairs(services) do
        if funcMap["updateProto"] then
            cell.send(c, funcMap["updateProto"])
        end
    end
end

function steward.stop()
    for c, funcMap in pairs(services) do
        if funcMap["stop"] then
            cell.send(c, funcMap["stop"])
        end
    end
end

function steward.registerControlFunc(c, funcMap)
    services[c] = funcMap
end

return steward
