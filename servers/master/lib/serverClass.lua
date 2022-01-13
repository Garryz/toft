local const = require "const"

local serverClass = Class("serverClass")

function serverClass:ctor(serverConf)
    self.weight = serverConf.weight or const.SERVER_DEFAULT_WEIGHT
    self.nodeName = serverConf.nodeName
    self.nodeType = serverConf.nodeType
    self.host = serverConf.host
    self.port = serverConf.port
    self.wsPort = serverConf.wsport
    self.wsProtocol = serverConf.wsProtocol
    self.load = serverConf.load or 0

    self.available = true
    self.aliveTime = 0
end

function serverClass:setWeight(weight)
    self.weight = weight
end

function serverClass:getWeight()
    return self.weight
end

function serverClass:getNodeName()
    return self.nodeName
end

function serverClass:setDisabled()
    self.available = false
end

function serverClass:setAvailable()
    self.available = true
end

function serverClass:isAvailable()
    return self.available
end

function serverClass:setAliveTime(time)
    self.aliveTime = time
end

function serverClass:getAliveTime()
    return self.aliveTime
end

function serverClass:setLoad(load)
    self.load = load
end

function serverClass:getLoad()
    return self.load
end

function serverClass:formatServerInfo()
    return {
        nodeName = self.nodeName,
        nodeType = self.nodeType,
        host = self.host,
        port = self.port,
        wsPort = self.wsPort,
        wsProtocol = self.wsProtocol
    }
end

return serverClass
