local cell = require "cell"

local redisClass = Class("redisClass")

function redisClass:ctor(redisPoolSrvName, key)
    self.redisPoolSrvName = redisPoolSrvName
    self.key = key
    self.redis = nil
    self:initRedis()
end

function redisClass:initRedis()
    self.redis = cell.call(self.redisPoolSrvName, "getSrvIdByHash", tostring(self.key))
end

function redisClass:callRedis(cmd, key, ...)
    return cell.call(self.redis, cmd, key, ...)
end

function redisClass:hset(hash, field, value)
    return self:callRedis("hset", hash, field, value)
end

function redisClass:hsetnx(hash, field, value)
    return self:callRedis("hsetnx", hash, field, value)
end

function redisClass:hget(hash, field, default)
    return self:callRedis("hget", hash, field) or default
end

function redisClass:hdel(hash, field1, ...)
    return self:callRedis("hdel", hash, field1, ...)
end

function redisClass:hexists(hash, field)
    return self:callRedis("hexists", hash, field)
end

function redisClass:hgetall(hash)
    return self:callRedis("hgetall", hash)
end

function redisClass:hincrby(hash, field, int)
    return self:callRedis("hincrby", hash, field, int)
end

function redisClass:hincrbyfloat(hash, field, float)
    return self:callRedis("hincrbyfloat", hash, field, float)
end

function redisClass:hkeys(hash)
    return self:callRedis("hkeys", hash)
end

function redisClass:hlen(hash)
    return self:callRedis("hlen", hash)
end

function redisClass:hmget(hash, field1, ...)
    return self:callRedis("hmget", hash, field1, ...)
end

function redisClass:hmset(hash, map)
    return self:callRedis("hmset", hash, map)
end

function redisClass:hstrlen(hash, field)
    return self:callRedis("hstrlen", hash, field)
end

function redisClass:hvals(hash)
    return self:callRedis("hvals", hash)
end

function redisClass:set(key, value, noExist, expireSec)
    local args = {"set", key, value}
    if expireSec then
        table.insert(args, "ex")
        table.insert(args, expireSec)
    end
    if noExist then
        table.insert(args, "nx")
    end
    return self:callRedis(table.unpack(args))
end

function redisClass:get(key)
    return self:callRedis("get", key)
end

function redisClass:del(key1, ...)
    return self:callRedis("del", key1, ...)
end

function redisClass:exists(key)
    return self:callRedis("exists", key)
end

function redisClass:expire(key, sec)
    return self:callRedis("expire", key, sec)
end

function redisClass:ttl(key)
    return self:callRedis("ttl", key)
end

function redisClass:expireat(key, unixtime)
    return self:callRedis("expireat", key, unixtime)
end

function redisClass:mset(map)
    return self:callRedis("mset", map)
end

function redisClass:keys(pattern)
    return self:callRedis("keys", pattern)
end

function redisClass:persist(key)
    return self:callRedis("persist", key)
end

function redisClass:rename(key, newKey)
    return self:callRedis("rename", key, newKey)
end

function redisClass:renamenx(key, newKey)
    return self:callRedis("renamenx", key, newKey)
end

function redisClass:type(key)
    return self:callRedis("type", key)
end

function redisClass:lpush(list, value1, ...)
    return self:callRedis("lpush", list, value1, ...)
end

function redisClass:rpush(list, value1, ...)
    return self:callRedis("rpush", list, value1, ...)
end

function redisClass:lrange(list, startIndex, endIndex)
    return self:callRedis("lrange", list, startIndex, endIndex)
end

function redisClass:lindex(list, index)
    return self:callRedis("lindex", list, index)
end

function redisClass:linsert(list, pivot, value, isBefore)
    local t = {"linsert", list}
    if isBefore then
        table.insert(t, "before")
    else
        table.insert(t, "after")
    end
    table.insert(t, pivot)
    table.insert(t, value)
    return self:callRedis(table.unpack(t))
end

function redisClass:llen(list)
    return self:callRedis("llen", list)
end

function redisClass:lpop(list)
    return self:callRedis("lpop", list)
end

function redisClass:lpushx(list, value)
    return self:callRedis("lpushx", list, value)
end

function redisClass:lrem(list, count, value)
    return self:callRedis("lrem", list, count, value)
end

function redisClass:lset(list, index, value)
    return self:callRedis("lset", list, index, value)
end

function redisClass:ltrim(list, startIndex, endIndex)
    return self:callRedis("ltrim", list, startIndex, endIndex)
end

function redisClass:rpop(list)
    return self:callRedis("rpop", list)
end

function redisClass:rpoplpush(srcList, dstList)
    return self:callRedis("rpoplpush", srcList, dstList)
end

function redisClass:rpushx(list, value)
    return self:callRedis("rpushx", list, value)
end

function redisClass:sadd(set, value1, ...)
    return self:callRedis("sadd", set, value1, ...)
end

function redisClass:smembers(set)
    return self:callRedis("smembers", set)
end

function redisClass:scard(set)
    return self:callRedis("scard", set)
end

function redisClass:sdiff(set, set1, ...)
    return self:callRedis("sdiff", set, set1, ...)
end

function redisClass:sdiffstore(dstSet, set, set1, ...)
    return self:callRedis("sdiffstore", dstSet, set, set1, ...)
end

function redisClass:sinter(set1, set2, ...)
    return self:callRedis("sinter", set1, set2, ...)
end

function redisClass:sinterstore(dstSet, set1, set2, ...)
    return self:callRedis("sinterstore", dstSet, set1, set2, ...)
end

function redisClass:sismember(set, value)
    return self:callRedis("sismember", set, value)
end

function redisClass:smove(srcSet, dstSet, value)
    return self:callRedis("smove", srcSet, dstSet, value)
end

function redisClass:spop(set, count)
    if count then
        return self:callRedis("spop", set, count)
    end
    return self:callRedis("spop", set)
end

function redisClass:srandmember(set, count)
    if count then
        return self:callRedis("srandmember", set, count)
    end
    return self:callRedis("srandmember", set)
end

function redisClass:srem(set, value1, ...)
    return self:callRedis("srem", set, value1, ...)
end

function redisClass:sunion(set1, set2, ...)
    return self:callRedis("sunion", set1, set2, ...)
end

function redisClass:sunionstore(dstSet, set1, set2, ...)
    return self:callRedis("sunionstore", dstSet, set1, set2, ...)
end

function redisClass:zadd(zset, score, value, noAddNew, onlyAddNew, change, incr)
    local args = {"zadd", zset}
    if noAddNew then
        table.insert(args, "xx")
    end
    if onlyAddNew then
        table.insert(args, "nx")
    end
    if change then
        table.insert(args, "ch")
    end
    if incr then
        table.insert(args, "incr")
    end
    table.insert(args, score)
    table.insert(args, value)
    return self:callRedis(table.unpack(args))
end

function redisClass:zaddbymap(zset, map, noAddNew, onlyAddNew, change, incr)
    local args = {"zadd", zset}
    if noAddNew then
        table.insert(args, "xx")
    end
    if onlyAddNew then
        table.insert(args, "nx")
    end
    if change then
        table.insert(args, "ch")
    end
    if incr then
        table.insert(args, "incr")
    end
    for value, score in pairs(map) do
        table.insert(args, score)
        table.insert(args, value)
    end
    return self:callRedis(table.unpack(args))
end

function redisClass:zrange(zset, startIndex, endIndex, withScores)
    local args = {"zrange", zset, startIndex, endIndex}
    if withScores then
        table.insert(args, "withscores")
        local result = self:callRedis(table.unpack(args))
        local list = {}
        for i = 1, #result / 2 do
            table.insert(list, {value = result[2 * i - 1], score = result[2 * i]})
        end
        return list
    end
    return self:callRedis(table.unpack(args))
end

function redisClass:zcard(zset)
    return self:callRedis("zcard", zset)
end

function redisClass:zcount(zset, minScore, maxScore)
    return self:callRedis("zcount", zset, minScore, maxScore)
end

function redisClass:zincrby(zset, incrScore, value)
    return self:callRedis("zincrby", zset, incrScore, value)
end

-- map = {zset -> weight}
-- aggregate 1 sum 2 min 3 max
function redisClass:zinterstore(dstZset, map, aggregate)
    local args = {"zinterstore", dstZset}
    local zsetCount = 0
    for _, _ in pairs(map) do
        zsetCount = zsetCount + 1
    end
    table.insert(args, zsetCount)
    for zset, _ in pairs(map) do
        table.insert(args, zset)
    end
    table.insert(args, "weights")
    for _, weight in pairs(map) do
        table.insert(args, weight)
    end
    if aggregate then
        if aggregate == 1 then
            table.insert(args, "aggregate")
            table.insert(args, "sum")
        elseif aggregate == 2 then
            table.insert(args, "aggregate")
            table.insert(args, "min")
        elseif aggregate == 3 then
            table.insert(args, "aggregate")
            table.insert(args, "max")
        end
    end
    return self:callRedis(table.unpack(args))
end

-- minValue - + [?
-- maxValue - + [?
function redisClass:zlexcount(zset, minValue, maxValue)
    return self:callRedis("zlexcount", zset, minValue, maxValue)
end

-- minValue - + [? (?
-- maxValue - + [? (?
function redisClass:zrangebylex(zset, minValue, maxValue, limit, offset, count)
    local args = {"zrangebylex", zset, minValue, maxValue}
    if limit then
        table.insert(args, "limit")
        table.insert(args, offset)
        table.insert(args, count)
    end
    return self:callRedis(table.unpack(args))
end

-- maxValue + - [? (?
-- minValue + - [? (?
function redisClass:zrevrangebylex(zset, maxValue, minValue, limit, offset, count)
    local args = {"zrevrangebylex", zset, maxValue, minValue}
    if limit then
        table.insert(args, "limit")
        table.insert(args, offset)
        table.insert(args, count)
    end
    return self:callRedis(table.unpack(args))
end

-- minScore -inf ? (?
-- maxScore +inf ? (?
function redisClass:zrangebyscore(zset, minScore, maxScore, withScores, limit, offset, count)
    local args = {"zrangebyscore", zset, minScore, maxScore}
    if withScores then
        table.insert(args, "withscores")
    end
    if limit then
        table.insert(args, "limit")
        table.insert(args, offset)
        table.insert(args, count)
    end
    if withScores then
        local result = self:callRedis(table.unpack(args))
        local list = {}
        for i = 1, #result / 2 do
            table.insert(list, {value = result[2 * i - 1], score = result[2 * i]})
        end
        return list
    end
    return self:callRedis(table.unpack(args))
end

function redisClass:zrank(zset, value)
    return self:callRedis("zrank", zset, value)
end

function redisClass:zrem(zset, value1, ...)
    return self:callRedis("zrem", zset, value1, ...)
end

-- minValue - + [? (?
-- maxValue - + [? (?
function redisClass:zremrangebylex(zset, minValue, maxValue)
    return self:callRedis("zremrangebylex", zset, minValue, maxValue)
end

function redisClass:zremrangebyrank(zset, startIndex, endIndex)
    return self:callRedis("zremrangebyrank", zset, startIndex, endIndex)
end

-- minScore -inf ? (?
-- maxScore +inf ? (?
function redisClass:zremrangebyscore(zset, minScore, maxScore)
    return self:callRedis("zremrangebyscore", zset, minScore, maxScore)
end

function redisClass:zrevrange(zset, startIndex, endIndex, withScores)
    local args = {"zrevrange", zset, startIndex, endIndex}
    if withScores then
        table.insert(args, "withscores")
        local result = self:callRedis(table.unpack(args))
        local list = {}
        for i = 1, #result / 2 do
            table.insert(list, {value = result[2 * i - 1], score = result[2 * i]})
        end
        return list
    end
    return self:callRedis(table.unpack(args))
end

-- maxScore +inf ? (?
-- minScore -inf ? (?
function redisClass:zrevrangebyscore(zset, maxScore, minScore, withScores, limit, offset, count)
    local args = {"zrevrangebyscore", zset, maxScore, minScore}
    if withScores then
        table.insert(args, "withscores")
    end
    if limit then
        table.insert(args, "limit")
        table.insert(args, offset)
        table.insert(args, count)
    end
    if withScores then
        local result = self:callRedis(table.unpack(args))
        local list = {}
        for i = 1, #result / 2 do
            table.insert(list, {value = result[2 * i - 1], score = result[2 * i]})
        end
        return list
    end
    return self:callRedis(table.unpack(args))
end

function redisClass:zrevrank(zset, value)
    return self:callRedis("zrevrank", zset, value)
end

function redisClass:zscore(zset, value)
    local score = self:callRedis("zscore", zset, value)
    return score and tonumber(score)
end

-- map = {zset -> weight}
-- aggregate 1 sum 2 min 3 max
function redisClass:zunionstore(dstZset, map, aggregate)
    local args = {"zunionstore", dstZset}
    local zsetCount = 0
    for _, _ in pairs(map) do
        zsetCount = zsetCount + 1
    end
    table.insert(args, zsetCount)
    for zset, _ in pairs(map) do
        table.insert(args, zset)
    end
    table.insert(args, "weights")
    for _, weight in pairs(map) do
        table.insert(args, weight)
    end
    if aggregate then
        if aggregate == 1 then
            table.insert(args, "aggregate")
            table.insert(args, "sum")
        elseif aggregate == 2 then
            table.insert(args, "aggregate")
            table.insert(args, "min")
        elseif aggregate == 3 then
            table.insert(args, "aggregate")
            table.insert(args, "max")
        end
    end
    return self:callRedis(table.unpack(args))
end

function redisClass:append(key, value)
    return self:callRedis("append", key, value)
end

function redisClass:decr(key)
    return self:callRedis("decr", key)
end

function redisClass:decrby(key, value)
    return self:callRedis("decrby", key, value)
end

function redisClass:getrange(key, startIndex, endIndex)
    return self:callRedis("getrange", key, startIndex, endIndex)
end

function redisClass:getset(key, value)
    return self:callRedis("getset", key, value)
end

function redisClass:incr(key)
    return self:callRedis("incr", key)
end

function redisClass:incrby(key, value)
    return self:callRedis("incrby", key, value)
end

function redisClass:incrbyfloat(key, value)
    return self:callRedis("incrbyfloat", key, value)
end

function redisClass:mget(key1, ...)
    return self:callRedis("mget", key1, ...)
end

function redisClass:msetnx(map)
    return self:callRedis("msetnx", map)
end

function redisClass:setrange(key, offset, value)
    return self:callRedis("setrange", key, offset, value)
end

function redisClass:strlen(key)
    return self:callRedis("strlen", key)
end

return redisClass
