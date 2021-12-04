local cell = require "cell"
local socket = require "socket"

function cell.main(ip, port, agentCount, webModuleName, bodyLimit)
    local pool = cell.newservice("poolSrv", "httpAgentSrv", agentCount, nil, false, webModuleName, bodyLimit)
    socket.listen(
        ip,
        port,
        function(fd, addr, listenSock)
            local client = cell.call(pool, "getSrvIdByHash", fd)
            cell.send(client, "http", fd, addr)
            return client
        end
    )
end
