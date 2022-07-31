local cell = require "cell"

local gameAgent = {}

local queues = {}
local function cs(uid)
    local q = queues[uid]
    if not q then
        q = cell.queue()
        queues[uid] = q
    end
    return q
end

-- 登录
function gameAgent.login(uid, session)
    return true
end

-- 登出
function gameAgent.logout(uid)

end

local function protoData(msg)

end

-- 处理客户端协议数据
function gameAgent.protoData(msg)
    cs(msg.req.uid)(protoData, msg)
end

return gameAgent
