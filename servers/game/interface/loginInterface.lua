local code = require "code"

local login = {}

function login.keepAlive()
    return code.OK
end

function login.getPassword(role)
    return code.OK, role.user:getPassword()
end

return login
