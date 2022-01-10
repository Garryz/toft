local websocket = require "http.websocket"

local handler = {}

function handler.acceptSock(fd, addr, conf)
    return websocket.accept(fd, conf.protocol, addr)
end

function handler.readMsg(sock)
    local ok, body =
        pcall(
        function()
            return sock:readmsg()
        end
    )
    if not ok or not body then
        sock:close()
        return false
    end
    local cmd, len = string.unpack(">I2>I2", body)
    if not cmd or not len then
        sock:close()
        return false
    end
    local data = string.unpack("c" .. len, body, 5)
    if not data then
        sock:close()
        return false
    end
    return true, cmd, data
end

function handler.writeMsg(sock, cmd, msg)
    msg = string.pack(">I2>I2c" .. #msg, cmd, #msg, msg)
    sock:writemsg(msg, "binary")
end

function handler.closeSock(sock)
    sock:close()
end

return handler
