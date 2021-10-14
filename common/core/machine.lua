local env = require "env"
local builder = require "datasheet.builder"
local datasheet = require "datasheet"

local machine = {}

local machine_conf = "__MACHINE"

function machine.init()
    local file = env.getconfig("machine_conf")
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

    builder.new(machine_conf, data)
end

function machine.get(k)
    local data = datasheet.query(machine_conf)
    assert(data)
    return data[k]
end

function machine.getRedisConf(name)
    local data = datasheet.query(machine_conf)
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

return machine
