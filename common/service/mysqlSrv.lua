local cell = require "cell"
local mysql = require "db.mysql"

local db

local command =
    setmetatable(
    {},
    {
        __index = function(t, k)
            local function f(...)
                return db[k](db, ...)
            end
            t[k] = f
            return f
        end
    }
)

function cell.main(conf)
    conf.on_connect = function(db)
        db:query("set charset utf8mb4")
    end
    db = mysql.connect(conf)
    cell.command(command)
    cell.message(command)
end
