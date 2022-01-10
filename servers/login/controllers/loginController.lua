local code = require "code"

local login = {}

function login.register(msg)
    return code.OK, {token = "1", host = "127.0.0.1", port = 8081, wsport = 444, uid = 1}
end

return login
