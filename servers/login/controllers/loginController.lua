local code = require "code"

local login = {}

function login.register(msg)
    return code.OK, {token = "1"}
end

return login
