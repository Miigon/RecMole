-- TrafficLogger

gs = require "core".Object:extend()
local timer = require "timer"
local net = require "net"

local policy_file = "\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"
local fs = require "fs"
local function logd(fd,pre,data)
    fd:write(pre)
    fd:write(data)
end
function gs:initialize(port)
    local server = net.createServer(function(client)
        local ce
        local fd
        local sfile = os.time().."-"..os.clock()..".bin"
        print "Someone Connected to gameserver."
        
        p("Session file:",sfile)
        fd = io.open("sessionlog/"..sfile, "w+")
        local tmr = timer.setInterval(5000,function()fd:flush()end)
        ce = net.createConnection(1865, '123.206.131.236', function (err)
            if err then error(err) end
    
            print("Connected to official game server")

            ce:on("data",function(data)
                --print("FROM SRV:",#data)
                client:write(data)
                logd(fd,"\n\xDE\xADSRV\xBE\xEF\n"..os.clock().."\n",data)
            end)
        end)

        client:on("close",function()
            p("Closed session file:",sfile)
            fd:close()
            tmr:close()
        end)
        client:on("data",function(data)
            --[[
            if false and data == "<policy-file-request/>\000" then
                client:write(policy_file)
                return
            end]]
            --print("FROM CLI:",#data)
            ce:write(data)
            logd(fd,"\n\xDE\xADCLI\xBE\xEF\n"..os.clock().."\n",data)
        end)
    end)
    
    -- Add error listenner for server
    server:on('error',function(err)
        if err then error(err) end
    end)

    server:listen(conf.gameserver_port)
    print("\27[36mTrafficLogger server started on \27[1mtcp://localhost:"..conf.gameserver_port.."/\27[0m")
end

return {GameServer = gs}