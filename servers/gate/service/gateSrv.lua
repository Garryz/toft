local cell = require "cell"
local cluster = require "cluster"
local gate = require "gate"

function cell.main()
    gate.init()

    cell.command(gate)
    cell.message(gate)

    cell.register("gateSrv")
    cluster.register("gateSrv", cell.self)
end
