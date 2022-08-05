local cell = require "cell"
local gameAgent = require "gameAgent"

function cell.main()
    gameAgent.init()

    cell.command(gameAgent)
    cell.message(gameAgent)

    cell.send("stewardSrv", "registerControlFunc", cell.self, {
        ["updateConfig"] = "updateConfig",
        ["updateLogic"] = "updateLogic",
        ["updateProto"] = "updateProto",
        ["stop"] = "stop"
    })
end
