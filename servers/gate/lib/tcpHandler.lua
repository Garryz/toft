local socket = require "socket"

local handler = {}

function handler.acceptSock(fd, addr, conf)
    return socket.bind(fd, addr)
end

function handler.readMsg(sock)
    local body = sock:readbytes(4)
    if not body then
        sock:disconnect()
        return false
    end
    local cmd, len = string.unpack(">I2>I2", body)
    if not cmd or not len then
        sock:disconnect()
        return false
    end
    body = ""
    if len > 0 then
        body = sock:readbytes(len)
        if not body then
            sock:disconnect()
            return false
        end
    end
    local data = string.unpack("c" .. len, body)
    if not data then
        sock:disconnect()
        return false
    end
    return true, cmd, data
end

function handler.writeMsg(sock, cmd, msg)
    msg = string.pack(">I2>I2c" .. #msg, cmd, #msg, msg)
    sock:write(msg)
end

function handler.closeSock(sock)
    sock:disconnect()
end

return handler
