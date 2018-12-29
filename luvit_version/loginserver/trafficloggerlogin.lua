-- Login Server

local net = require "net"
local lpp = require "./loginpktprocess"



local policy_file = "\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"

local server = net.createServer(function(client)
    print("Login server client connected")
    local ce
    local ccc
    
    -- proxy to official login server
    ce = net.createConnection(1863, '123.206.131.236', function (err)
        print("Connected to official login server")
        do
            local buffer = ""
            local expecting = 1
            ce:on("data",function(data)
                --client:write(data);
                p("s2c",data)
                buffer = buffer .. data
                while #buffer >= expecting do
                    expecting = lpp.preparse(buffer)
                    if #buffer >= expecting then
                        local packet = buffer:sub(1,expecting)
                        lpp.parse(packet,nil,1) -- mode = 1
                        buffer = buffer:sub(expecting+1,-1)
                        client:write(packet)
                    end
                    expecting = 1
                end
                
                p(buffer,#buffer,expecting)
                
            end)
        end
        ce:on("end",function()
            client:destroy()
        end)

        -- Add some listenners for incoming connection
        client:on("error",function(err)
            client:destroy()
        end)
        client:on("end",function(err)
            client:destroy()
        end)
        do
            local buffer = ""
            local expecting = 1
            client:on("data",function(data)
                if data == "<policy-file-request/>\000" then -- policy file
                    client:write(policy_file)
                    return
                end
                ce:write(data);
                buffer = buffer .. data
                while #buffer >= expecting do
                    expecting = lpp.preparse(buffer)
                    if #buffer >= expecting then
                        local packet = buffer:sub(1,expecting)
                        local dat = lpp.parse(packet,client)
                        if type(dat) == "string" then
                            ce:write(dat)
                            p(dat)
                        else
                            if not dat then ce:write(packet) end
                        end
                        --ce:write(packet)
                        buffer = buffer:sub(expecting+1,-1)
                    end
                end
                --p("c2s",data)
                
            end)
        end
        client:on("end",function()
            ce:destroy()
        end)
    end)
end)

-- Add error listenner for server
server:on('error',function(err)
    if err then error(err) end
end)

server:listen(conf.login_port)

print("\27[36mTrafficLogger Login server started on \27[1mtcp://localhost:"..conf.login_port.."/\27[0m")