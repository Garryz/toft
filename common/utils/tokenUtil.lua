local crypt = require "crypt"

local DES_SECRET = "dG9mdA=="

local tokenUtil = {}

function tokenUtil.create(uid, password)
    local timestamp = os.time()
    local s = string.format("%s:%s:%s", uid, timestamp, password)
    s = crypt.base64encode(crypt.desencode(DES_SECRET, s))
    return s:gsub("[+/]", function(c)
        if c == '+' then
            return '-'
        else
            return '_'
        end
    end)
end

function tokenUtil.parseToken(token)
    token = token:gsub("[-_]", function(c)
        if c == '-' then
            return '+'
        else
            return '/'
        end
    end)
    local s = crypt.desdecode(DES_SECRET, crypt.base64decode(token))
    local uid, time, password = s:match("([^:]+):([^:]+):(.+)")

    -- 检验时间
    local now = os.time()
    local time = tonumber(time) or 0
    if time + 86400 < now then
        return false, string.format("time expire, val %d", time)
    end

    return true, uid, password
end

function tokenUtil.auth(uid, token)
    if not uid or not token then
        return false, "function:token_auth args illedge!"
    end

    local ok, tuid, tpassword = tokenUtil.parseToken(token)
    if not ok or not tuid or not tpassword then
        return false, string.format("token parse fail! token is %s", token)
    end

    tuid = tonumber(tuid) or 0
    if tuid ~= uid then
        return false, string.format("uid not same, %d, %d", uid, tuid)
    end

    return true
end

return tokenUtil
