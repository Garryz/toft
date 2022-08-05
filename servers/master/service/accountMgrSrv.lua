local cell = require "cell"
local cluster = require "cluster"
local accountMgr = require "accountMgr"

function cell.main()
    accountMgr.init()

    cell.command(accountMgr)
    cell.message(accountMgr)

    cluster.register("accountMgr", cell.self)

    cell.send("stewardSrv", "registerControlFunc", cell.self, {
        ["updateLogic"] = "updateLogic"
    })
end

