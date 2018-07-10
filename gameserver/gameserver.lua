-- GameServer

CONN_OFFI_GS = false

gs = require "core".Object:extend()
local gpp = require "./gamepktprocess"
local net = require "net"

local policy_file = "\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"

local ce
local ccc
if conf.passthru then
    ce = net.createConnection(1865, '123.206.131.236', function (err)
        if err then error(err) end

        print("Connected to official game server")

        ce:on("data",function(data) 
            ccc:write(data)
            p("Game srv->cli",data)
        end)
    end)
end

function gs:initialize(port)
    local server = net.createServer(function(client)
        print "Someone Connected to gameserver."
        client:on("data",function(data)
            if data == "<policy-file-request/>\000" then
                client:write(policy_file)
                return
            end
            --p("Game cli->srv",data)
            if conf.passthru then
                ce:write(data)
            else
                gpp.parse(data,client)
            end
        end)
        ccc = client
    end)
    
    -- Add error listenner for server
    server:on('error',function(err)
        if err then error(err) end
    end)

    server:listen(conf.gameserver_port)
    print("\27[36mGame server started on \27[1mtcp://localhost:"..conf.gameserver_port.."/\27[0m")
end

return {GameServer = gs}