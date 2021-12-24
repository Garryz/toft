local protoUtil = require "utils.protoUtil"

return setmetatable(
    {},
    {
        __index = function(t, k)
            local code = protoUtil.enumNum("code.code", tostring(k))
            t[k] = code
            return code
        end
    }
)
