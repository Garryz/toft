local log = require "log"

local web = {}

function web.init()
    log.info("web.init")
end

-- 处理http请求
function web.httpRequest(ip, url, method, headers, path, query, body)
    log.info("web.httpRequest")
    return 200
end

return web
