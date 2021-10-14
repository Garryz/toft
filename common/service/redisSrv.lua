local cell = require "cell"
local redis = require "db.redis"

local db

local command =
    setmetatable(
    {},
    {
        __index = function(t, k)
            local cmd = string.lower(k)

            local function f(...)
                return db[cmd](db, ...)
            end
            t[k] = f
            return f
        end
    }
)

function cell.main(conf)
    db = redis.connect(conf)
    cell.command(command)
    cell.message(command)
end
