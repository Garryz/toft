local log = require "log"
local protoUtil = require "utils.protoUtil"

local web = {}

function web.init()
    log.info("web.init")
    protoUtil.init()
end

-- 处理http请求
function web.httpRequest(ip, url, method, headers, path, query, body)
    local cmd = string.unpack(">I2", body)
    if not cmd then
        return 404
    end
    local len = string.unpack(">I2", body, 3)
    if not len then
        return 404
    end
    local data = string.unpack("c" .. len, body, 5)
    if not data then
        return 404
    end
    local cmdStr = protoUtil.enumStr("cmd.requestCmd", cmd)
    if not cmdStr then
        log.errorf("cmd.requestCmd cmd=%s not exist", cmd)
        return 404
    end

    local cmdStrs = string.split(cmdStr, "_")
    if not cmdStrs[1] or cmdStrs[1] == "" then
        log.errorf("cmd.requestCmd cmd=%s format error", cmdStr)
        return 404
    end
    local controllerName = cmdStrs[1] .. "Controller"
    local funcName = table.concat(cmdStrs, "", 2)
    if not funcName or funcName == "" then
        log.errorf("cmd.requestCmd cmd=%s format error", cmdStr)
        return 404
    end

    local ok, controller = pcall(require, "controllers." .. controllerName)
    if not ok then
        log.errorf("controller %s error %s", controllerName, controller)
        return 404
    end
    local func = controller[funcName]
    if not func then
        log.errorf("controller %s no include func %s", controllerName, funcName)
        return 404
    end

    local req = {}
    local reqDesc = protoUtil.enumStr("cmd.requestReq", cmd)
    if reqDesc then
        reqDesc = reqDesc:gsub("_", ".")
        req = protoUtil.decode(reqDesc, data)
        if not req then
            req = {}
        end
    end

    local ok, code, res = pcall(func, req)
    if not ok then
        log.errorf("controller %s func %s exec error", controllerName, funcName)
        return 404
    end
    if not code then
        log.errorf("controller %s func %s must return code first", controllerName, funcName)
        return 404
    end
    res = res or {}
    res.code = code

    local resStr = ""
    local rspDesc = protoUtil.enumStr("cmd.requestRsp", cmd)
    if rspDesc then
        rspDesc = rspDesc:gsub("_", ".")
        resStr = protoUtil.encode(rspDesc, res)
        if not resStr then
            resStr = ""
        end
    end

    resStr = string.pack(">I2>I2c" .. #resStr, cmd, #resStr, resStr)

    return 200, resStr
end

return web
