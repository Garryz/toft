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

function protoUtil.encodeByProto(enum, protoName, data)
    local cmdStr = protoName:gsub("%.", "_")
    local cmd = protoUtil.enumNum(enum, cmdStr)
    if not cmd then
        log.errorf("%s cmdStr=%s not exist", enum, cmdStr)
        return false
    end
    local str = protoUtil.encode(protoName, data)
    if not str then
        log.errorf("protoName=%s, data=%s encode error", protoName, string.toString(data))
        return false
    end
    return true, cmd, str
end

function protoUtil.encodeReqByProto(protoName, data)
    return protoUtil.encodeByProto("cmd.requestReq", protoName, data)
end

function protoUtil.encodeRspByProto(protoName, data)
    return protoUtil.encodeByProto("cmd.requestRsp", protoName, data)
end

function protoUtil.encodeByCmd(enum, cmd, data)
    local str = ""
    local desc = protoUtil.enumStr(enum, cmd)
    if not desc then
        log.errorf("%s cmd=%s not exist", enum, cmd)
        return false
    end
    desc = desc:gsub("_", ".")
    str = protoUtil.encode(desc, data)
    if not str then
        log.errorf("protoName=%s, data=%s encode error", desc, string.toString(data))
        return false
    end
    return true, str
end

function protoUtil.encodeReqByCmd(cmd, data)
    return protoUtil.encodeByCmd("cmd.requestReq", cmd, data)
end

function protoUtil.encodeRspByCmd(cmd, data)
    return protoUtil.encodeByCmd("cmd.requestRsp", cmd, data)
end

function protoUtil.decodeByCmd(enum, cmd, data)
    local enumStr = protoUtil.enumStr(enum, cmd)
    if not enumStr then
        log.errorf("%s cmd=%s not exist", enum, cmd)
        return false
    end
    local desc = enumStr:gsub("_", ".")
    local msg = protoUtil.decode(desc, data)
    if not msg then
        log.errorf("protoName=%s decode error", desc)
        return false
    end
    return true, enumStr, msg
end

function protoUtil.decodeReqByCmd(cmd, data)
    return protoUtil.decodeByCmd("cmd.requestReq", cmd, data)
end

function protoUtil.decodeRspByCmd(cmd, data)
    return protoUtil.decodeByCmd("cmd.requestRsp", cmd, data)
end

return protoUtil
