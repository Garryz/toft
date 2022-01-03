local env = require "env"
local builder = require "datasheet.builder"
local datasheet = require "datasheet"

local machine = {}

local machineConf = "__MACHINE"

function machine.init()
    local file = env.getconfig("machineConf")
    local f = assert(io.open(file, "rb"), file)

    local data = {}
    for line in f:lines() do
        if string.find(line, "^%s*#") == nil then
            for k, v in string.gmatch(line, "([%w_]+)%s*=%s*(.+)") do
                data[k] = v
            end
        end
    end

    f:close()

    builder.new(machineConf, data)
end

function machine.get(k)
    local data = datasheet.query(machineConf)
    assert(data)
    return data[k]
end

function machine.getRedisConf(name)
    local data = datasheet.query(machineConf)
    assert(data)
    local conf = {
        host = data[name .. "_redis_host"],
        port = data[name .. "_redis_port"],
        auth = data[name .. "_redis_auth"],
        db = data[name .. "_redis_db"]
    }
    conf.port = conf.port and tonumber(conf.port)
    conf.db = conf.db and tonumber(conf.db)
    return conf
end

function machine.getTcpListenConf(nodeName)
    local data = datasheet.query(machineConf)
    assert(data)
    local conf = {
        host = data[nodeName .. "_listen_host"],
        port = data[nodeName .. "_port"]
    }
    conf.port = conf.port and tonumber(conf.port)
    return conf
end

function machine.getWsListenConf(nodeName)
    local data = datasheet.query(machineConf)
    assert(data)
    local conf = {
        host = data[nodeName .. "_listen_host"],
        protocol = data[nodeName .. "ws_protocol"],
        port = data[nodeName .. "_ws_port"]
    }
    conf.port = conf.port and tonumber(conf.port)
    return conf
end

return machine
