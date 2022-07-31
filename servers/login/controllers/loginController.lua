local code = require "code"
local redisClass = require "redisClass"
local userModule = require "selfModules.userModule"
local crypt = require "crypt"
local tokenUtil = require "utils.tokenUtil"
local cell = require "cell"
local cluster = require "cluster"

local login = {}

local redis = redisClass.new("redisSrv", 0)

local usernameRedisKey = "usernames"
local preUsernameRedisKey = "preUsernames"
local increaseUidRedisKey = "increaseUid"
local username2uidRedisKey = "username2uid"

local function isExistUsername(username)
    return redis:sismember(usernameRedisKey, username)
end

local function addUsername(username)
    return redis:sadd(usernameRedisKey, username) > 0
end

local function addPreUsername(username)
    return redis:sadd(preUsernameRedisKey, username) > 0
end

local function delPreUsername(username)
    return redis:srem(preUsernameRedisKey, username)
end

local function getIncreaseUid()
    return redis:incr(increaseUidRedisKey)
end

local function checkParameter(username, password)
    return not username or not password or username == "" or password == "" or #username > 50 or #password > 50 or
               not string.match(username, "^[%w%p]+$") or not string.match(password, "^[%w%p]+$")
end

local function setUid(username, uid)
    return redis:hset(username2uidRedisKey, username, uid)
end

local function getUid(username)
    return redis:hget(username2uidRedisKey, username)
end

function login.register(msg)
    local username, password = msg.username, msg.password
    if checkParameter(username, password) then
        return code.PARAMETER_ERROR
    end

    if isExistUsername(username) or not addPreUsername(username) then
        return code.USERNAME_REPEAT
    end

    local uid = getIncreaseUid()
    local user = userModule.new(uid)
    user:setUsername(username)
    user:setPassword(crypt.hexencode(crypt.md5(password)))
    user:saveData()
    addUsername(username)
    delPreUsername(username)
    setUid(username, uid)

    return login.login(msg)
end

function login.login(msg)
    local uid, password, token
    if msg.token ~= nil and msg.token ~= "" then
        local ok, tuid, tpassword = tokenUtil.parseToken(msg.token)
        if not ok then
            return code.TOKEN_EXPIRE
        end
        uid, password, token = tonumber(tuid), tpassword, msg.token
    elseif msg.username ~= nil and msg.username ~= "" then
        local tuid = getUid(msg.username)
        if not tuid and tuid == "" then
            return code.UID_NOEXIST
        end
        uid, password = tonumber(tuid), msg.password
        token = tokenUtil.create(uid, password)
    end

    local user = userModule.new(uid)
    if not user:loadData() then
        return code.USER_NOEXIST
    end

    if crypt.hexencode(crypt.md5(password)) ~= user:getPassword() then
        return code.PASSWORD_ERROR
    end

    if not cluster.call("master", "accountMgr", "login", uid) then
        return code.REPLACE_LOGIN
    end

    local gateServer = cluster.call("master", "serverMgr", "dispatchServer", "gate", uid)

    local data = {
        code = code.OK,
        token = token,
        host = gateServer.host,
        port = gateServer.port,
        wsport = gateServer.wsPort,
        uid = uid
    }

    return code.OK, data
end

return login
