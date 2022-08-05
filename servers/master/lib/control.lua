local cell = require "cell"

local control = {}

function control.updateConfig()
    cell.send("stewardSrv", "updateConfig")
end

function control.updateLogic()
    cell.send("stewardSrv", "updateLogic")
end

function control:updateProto()
    cell.send("stewardSrv", "updateProto")
end

function control:stop()
    cell.send("stewardSrv", "stop")
end

return control
