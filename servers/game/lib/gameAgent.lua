local cell = require "cell"
local cluster = require "cluster"
local log = require "log"
local machine = require "machine"
local protoUtil = require "utils.protoUtil"
local code = require "code"
local timer = require "timer"
local const = require "const"
local hotfix = require "hotfix.helper"

local roleMgr = (require "roleMgr").new()

local gameAgent = {}

local queues = {}
local function cs(uid)
    local q = queues[uid]
    if not q then
        q = cell.queue()
        queues[uid] = q
    end
    return q
end

local itfList = {}

-- 定时自动保存数据
local function autoSaveData()
    local saveTime = const.SAVE_DATA_TIME
    if machine.isTest() then
        saveTime = const.SAVE_DATA_TIME_TEST
    end

    timer.timeOut(saveTime, roleMgr.autoSaveRoleData, roleMgr)
end

-- 初始化code
function gameAgent.init()
    protoUtil.init()
    autoSaveData()
end

-- 登录
function gameAgent.login(uid, session)
    roleMgr:loginRole(uid, session)
    return true
end

-- 登出
function gameAgent.logout(uid)
    roleMgr:logoutRole(uid)
end

function gameAgent.logoutInactive(uid)
    roleMgr:logoutInactiveRole(uid)
end

-- 获取接口对象
local function getItfObj(itfName)
    local fileName = string.format("interface.%sInterface", itfName)
    itfList[itfName] = itfList[itfName] or require(fileName)
    return itfList[itfName]
end

-- 回应请求协议
local function responseProto(uid, cmd, errcode, res)
    res = res or {}
    assert(type(res) == "table",
        string.format("uid:%s,cmd:%s,errcode:%s,res:%s", uid, cmd, errcode, string.toString(res)))
    res.code = errcode

    local role = roleMgr:getRole(uid)
    if not role then
        return
    end

    if role.gate then
        cluster.send(role.gate, "gateSrv", "push2CByCmd", uid, cmd, res)
    end
end

-- 格式化协议
local function formatProtoName(pname)
    local data = string.split(pname, ".")
    local itfName = table.remove(data, 1)
    for index, _ in ipairs(data) do
        if index > 1 then
            data[index] = string.firstToUpper(data[index])
        end
    end

    local funcName = table.concat(data, "")
    return itfName, funcName
end

local function protoData(msg)
    local uid = msg.req.uid
    local cmd = msg.cmd
    local args = msg.req
    local role = roleMgr:getRole(uid)
    if not role then
        log.warningf("protoData not find role! uid:%s", uid)
        return responseProto(uid, cmd, code.INNER_SERVER_ERROR)
    end

    local itfName, funcName = formatProtoName(msg.cmdStr)
    if itfName == "test" and not machine.isTest() then
        log.errorf("testInterface is forbiden in production ! itfName:%s, funcName:%s", itfName, funcName)
        return
    end
    local ok, itfObj = pcall(getItfObj, itfName)
    if not ok or not itfObj then
        log.errorf("dont find module ! itfName:%s, funcName:%s", itfName, funcName)
        return responseProto(uid, cmd, code.INNER_SERVER_ERROR)
    end
    local func = itfObj[funcName]
    if not func then
        log.errorf("dont find func ! itfName:%s, funcName:%s", itfName, funcName)
        return responseProto(uid, cmd, code.INNER_SERVER_ERROR)
    end

    local ok, errorcode, rs = xpcall(func, function()
        log.error(debug.traceback())
    end, role, args)
    if not ok then
        log.errorf("itfName:%s, funcName:%s, args:%s", itfName, funcName, string.toString(args))
        return responseProto(uid, cmd, code.INNER_SERVER_ERROR)
    end

    responseProto(uid, cmd, errorcode, rs)

    if funcName ~= "keepAlive" then
        role:setSaveStatus(true)
    end

    -- 协议处理完后进行处理
    local afterFuncName = string.format("%sAfter", funcName)
    local afterFunc = itfObj[afterFuncName]
    if not afterFunc then
        return
    end

    local ok, errorcode, rs = xpcall(afterFunc, function()
        log.error(debug.traceback())
    end, role, args)
    if not ok then
        log.errorf("after itfName:%s, funcName:%s, args:%s", itfName, afterFuncName, stirng.toStingtring(args))
        return
    end
end

-- 处理客户端协议数据
function gameAgent.protoData(msg)
    cs(msg.req.uid)(protoData, msg)
end

local function doCmd(uid, cmd, args)
    local role = roleMgr:getRoleMayInactive(uid)
    if not role then
        log.warningf("doCmd uid[%s] role nil", tostring(uid))
        return
    end

    local itfName, funcName = cmd:match "([^.]*).(.*)"
    if itfName == "test" and not machine.isTest() then
        log.errorf("testInterface is forbiden in production ! itfName:%s, funcName:%s", itfName, funcName)
        return
    end
    local ok, itfObj = pcall(getItfObj, itfName)
    if not ok or not itfObj then
        log.errorf("doCmd dont find module ! itfName:%s, funcName:%s", itfName, funcName)
        return
    end
    local func = itfObj[funcName]
    if not func then
        log.errorf("dont find func ! itfName:%s, funcName:%s", itfName, funcName)
        return
    end

    local ok, errorcode, rs = xpcall(func, function()
        log.error(debug.traceback())
    end, role, args)
    if not ok then
        log.errorf("itfName:%s, funcName:%s, args:%s", itfName, funcName, string.toString(args))
        return
    end

    role:setSaveStatus(true)

    return errorcode, rs
end

function gameAgent.doCmd(uid, cmd, args)
    return cs(uid)(doCmd, uid, cmd, args)
end

function gameAgent.broadcastDoCmd(cmd, args)
    local roleList = roleMgr:getRoleList()
    for uid, _ in pairs(roleList) do
        gameAgent.doCmd(uid, cmd, args)
    end
end

function gameAgent.updateConfig()

end

function gameAgent.updateLogic(files)
    hotfix.init()
    hotfix.update(files)
end

function gameAgent.updateProto()
    protoUtil.update()
end

function gameAgent.stop()
    roleMgr:saveRoleData()
end

return gameAgent
