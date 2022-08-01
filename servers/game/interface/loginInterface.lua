local code = require "code"

local login = {}

function login.keepAlive()
    return code.OK
end

return login
