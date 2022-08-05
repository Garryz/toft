local cell = require "cell"
local watchdog = require "watchdog"

function cell.main(conf, handlerName)
    assert(type(conf) == "table" and type(conf.host) == "string" and type(conf.port) == "number")
    local handler = assert(require(handlerName))

    watchdog.init(conf, handler)

    cell.command(watchdog)
    cell.message(watchdog)

    cell.send("stewardSrv", "registerControlFunc", cell.self, {
        ["updateConfig"] = "updateConfig",
        ["updateLogic"] = "updateLogic",
        ["updateProto"] = "updateProto"
    })
end
