local cell = require "cell"
local steward = require "steward"
local cluster = require "cluster"

function cell.main(isMaster)
    steward.init(isMaster)

    cell.command(steward)
    cell.message(steward)

    cell.register("stewardSrv")
    cluster.register("stewardSrv", cell.self)
end
