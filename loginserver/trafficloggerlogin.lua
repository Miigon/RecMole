-- Login Server

local net = require "net"
local lpp = require "./loginpktprocess"
local ce
local ccc
if true then
    ce = net.createConnection(1863, '123.206.131.236', function (err)
    if err then error(err) end

    print("Connected to official login server")

    ce:on("data",function(data)
        --ccc:write(data)
        ccc:write(data:gsub("123.206.131.236","127.0.0.1\0\0\0\0\0\0"))
    end)

    end)
end
local policy_file = "\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"
local server = net.createServer(function(client)
    --print("Login server client connected")
    
    -- Add some listenners for incoming connection
    client:on("error",function(err)
        print("Client read error: " .. err)
        client:close()
    end)
    client:on("data",function(data)
        if data == "<policy-file-request/>\000" then
            --print("Login server policy file requested")
            client:write(policy_file)
            return
        end
        ce:write(data)
    end)
    ccc = client
end)

-- Add error listenner for server
server:on('error',function(err)
    if err then error(err) end
end)

server:listen(conf.login_port)

print("\27[36mTrafficLogger Login server started on \27[1mtcp://localhost:"..conf.login_port.."/\27[0m")