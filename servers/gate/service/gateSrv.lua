local cell = require "cell"
local cluster = require "cluster"
local gate = require "gate"

function cell.main()
    gate.init()

    cell.command(gate)
    cell.message(gate)

    cell.register("gateSrv")
    cluster.register("gateSrv", cell.self)

    cell.send("stewardSrv", "registerControlFunc", cell.self, {
        ["updateConfig"] = "updateConfig",
        ["updateLogic"] = "updateLogic",
        ["updateProto"] = "updateProto"
    })
end
