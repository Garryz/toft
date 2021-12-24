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

return protoUtil
