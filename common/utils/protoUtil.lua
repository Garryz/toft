local machine = require "machine"
local log = require "log"
local lfs = require "utils.lfs"
local pb = require "pb"

local protoUtil = {}

local function reload()
    local pbPath = machine.get("pb_path")
    if not pbPath then
        log.error("pb_path not config")
        return
    end
    pb.clear()
    local pbList = lfs.getFiles(pbPath)
    for _, file in ipairs(pbList) do
        file = pbPath .. file
        local ok, offset = pb.loadfile(file)
        if not ok then
            log.errorf("pb load error, file=%s, offset=%s", file, offset)
        end
    end
end

function protoUtil.init()
    reload()
end

function protoUtil.update()
    reload()
end

function protoUtil.encode(protoName, data)
    return pb.encode(protoName, data)
end

function protoUtil.decode(protoName, data)
    return pb.decode(protoName, data)
end

function protoUtil.enumNum(enumType, enumStr)
    return pb.enum(enumType, enumStr)
end

function protoUtil.enumStr(enumType, enumNum)
    return pb.enum(enumType, enumNum)
end

function protoUtil.encodeByProto(protoName, data)
    local cmdStr = protoName:gsub(".", "_")
    local cmd = protoUtil.enumNum("cmd.reqeustRsp", cmdStr)
    if not cmd then
        log.errorf("cmd.reqeustRsp cmdStr=%s not exist", cmdStr)
        return false
    end
    local resStr = protoUtil.encode(protoName, data)
    if not resStr then
        log.errorf("protoName=%s, data=%s encode error", protoName, string.toString(data))
        return false
    end
    return true, cmd, resStr
end

function protoUtil.encodeByCmd(cmd, data)
    local resStr = ""
    local rspDesc = protoUtil.enumStr("cmd.requestRsp", cmd)
    if not rspDesc then
        log.errorf("cmd.requestRsp cmd=%s not exist", cmd)
        return false
    end
    rspDesc = rspDesc:gsub("_", ".")
    resStr = protoUtil.encode(rspDesc, data)
    if not resStr then
        log.errorf("protoName=%s, data=%s encode error", rspDesc, string.toString(data))
        return false
    end
    return true, resStr
end

function protoUtil.decodeByCmd(cmd, data)
    local reqDesc = protoUtil.enumStr("cmd.requestReq", cmd)
    if not reqDesc then
        log.errorf("cmd.requestReq cmd=%s not exist", cmd)
        return false
    end
    reqDesc = reqDesc:gsub("_", ".")
    local req = protoUtil.decode(reqDesc, data)
    if not req then
        log.errorf("protoName=%s decode error", reqDesc)
        return false
    end
    return true, req
end

return protoUtil
