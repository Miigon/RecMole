-- GameServer

CONN_OFFI_GS = false

gs = require "core".Object:extend()
local Game = require "./game"
local Map = require "./map"
local gpp = require "./gamepktprotocol" -- must load AFTER Game and Map to avoid recursive requirement issues
gpp.initLibs()
local net = require "net"

local policy_file = "\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"
local allsocket = {}
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
        allsocket[client] = Game.newUser()
        allsocket[client].socket = client
        
        local buffer = ""
        local expecting = 1
        client:on("data",function(data)
            if data == "<policy-file-request/>\000" then
                client:write(policy_file)
                return
            end
            --p("Game cli->srv",data)
            if conf.passthru then
                ce:write(data)
            else
                buffer = buffer .. data
                while #buffer >= expecting do
                    expecting = gpp.preparse(buffer:sub(1,4))
                    if #buffer >= expecting then
                        local packet = buffer:sub(1,expecting)
                        gpp.parse(packet,client,allsocket[client])
                        buffer = buffer:sub(expecting+1,-1)
                    end
                    expecting = 1
                end
            end
        end)
        client:on("end",function()
            Game.endUser(allsocket[client])
            allsocket[client] = nil
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

function gpp.broadcast(data,when)
    if when then
        for k,_ in pairs(allsocket) do
            if when(k) then
                k:write(data)
            end
        end
    else
        for k,_ in pairs(allsocket) do
            k:write(data)
        end
    end
end

return {GameServer = gs}