local cell = require "cell"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local log = require "log"

local bodyLimit = 8192

local command = {}

local function response(sock, ...)
    local ok, err = httpd.writeresponse(sockethelper.writefunc(sock), ...)
    if not ok then
        log.errorf("fd = %d, %s", sock:fd(), err)
    end
end

local webapp

function command.http(fd, ip)
    local sock = socket.bind(fd)
    local code, url, method, header, body = httpd.readrequest(sockethelper.readfunc(sock), bodyLimit)
    if code then
        if code ~= 200 then
            response(sock, code)
        else
            local path, query = urllib.parse(url)
            local q = {}
            if query then
                q = urllib.parsequery(query)
            end
            response(sock, webapp.httpRequest(ip, url, method, header, path, q, body))
        end
    else
        if url == sockethelper.socketerror then
            log.error("socket closed")
        else
            log.error(url)
        end
    end
    sock:disconnect()
end

cell.command(command)
cell.message(command)

function cell.main(webModuleName, bodyLimit)
    webapp = require(webModuleName)
    if webapp.init then
        webapp.init()
    end
    bodyLimit = bodyLimit or 8192
end
