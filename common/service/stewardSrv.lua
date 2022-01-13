local cell = require "cell"
local steward = require "steward"
local cluster = require "cluster"

function cell.main()
    steward.init()

    cell.command(steward)
    cell.message(steward)

    cluster.register("stewardSrv", cell.self)
end
