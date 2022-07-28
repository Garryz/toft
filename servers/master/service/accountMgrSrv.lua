local cell = require "cell"
local cluster = require "cluster"
local accountMgr = require "accountMgr"

function cell.main()
    cell.command(accountMgr)
    cell.message(accountMgr)

    cluster.register("accountMgr", cell.self)
end

