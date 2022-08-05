local cell = require "cell"
local backup = require "backup"

function cell.main()
    backup.init()

    cell.command(backup)
    cell.message(backup)

    cell.send("stewardSrv", "registerControlFunc", cell.self, {
        ["updateLogic"] = "updateLogic"
    })
end
