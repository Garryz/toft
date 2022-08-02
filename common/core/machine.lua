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

function machine.getMysqlConf(name)
    local data = datasheet.query(machineConf)
    assert(data)
    local conf = {
        host = data[name .. "_mysql_host"],
        port = data[name .. "_mysql_port"],
        user = data[name .. "_mysql_user"],
        password = data[name .. "_mysql_password"],
        database = data[name .. "_mysql_database"],
        max_packet_size = data[name .. "_mysql_max_packet_size"],
        charset = data[name .. "_mysql_charset"]
    }
    conf.port = conf.port and tonumber(conf.port) or 3306
    conf.max_packet_size = conf.max_packet_size and tonumber(conf.max_packet_size) or 1024 * 1024
    conf.charset = conf.charset or "utf8mb4"
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
        protocol = data[nodeName .. "_ws_protocol"],
        port = data[nodeName .. "_ws_port"]
    }
    conf.port = conf.port and tonumber(conf.port)
    return conf
end

function machine.getBeginUid()
    local data = datasheet.query(machineConf)
    assert(data)
    return data.begin_uid and tonumber(data.begin_uid) or 10000
end

function machine.getDebugPort(nodeName)
    local data = datasheet.query(machineConf)
    assert(data)
    local port = data[nodeName .. "_debugport"]
    return port and tonumber(port)
end

function machine.isTest()
    local data = datasheet.query(machineConf)
    assert(data)
    if not data.mode then
        return false
    end
    return data.mode == "DEBUG"
end

return machine
