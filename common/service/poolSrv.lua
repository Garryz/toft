local cell = require "cell"
local cluster = require "cluster"

local pool = {}

local command = {}

function command.getSrvIdByHash(key)
    key = tostring(key)
    local value = 0
    for i = 1, #key do
        value = value + string.byte(key, i)
    end
    return pool[value % #pool + 1]
end

cell.command(command)

function cell.main(service, count, regname, remote, ...)
    for i = 1, count do
        local c = cell.newservice(service, ...)
        if c then
            table.insert(pool, c:id())
        end
    end
    if regname then
        cell.register(regname)
        if remote then
            cluster.register(regname, cell.self)
        end
    end
end
