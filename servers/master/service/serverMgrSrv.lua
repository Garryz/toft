local cell = require "cell"
local cluster = require "cluster"
local serverMgr = require "serverMgr"

function cell.main()
    serverMgr.init()

    cell.command(serverMgr)
    cell.message(serverMgr)

    cluster.register("serverMgr", cell.self)
end
