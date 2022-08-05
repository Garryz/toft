local cell = require "cell"
local control = require "control"
local cluster = require "cluster"

function cell.main()
    cell.command(control)
    cell.message(control)

    cell.register("controlSrv")
    cluster.register("controlSrv", cell.self)
end
