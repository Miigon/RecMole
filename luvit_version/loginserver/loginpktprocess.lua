-- Module for processing packets

local lpp = {}
lpp.handler = {}
local buffer = require "buffer"
local srv = require "./server"
local offset = 17

function lpp.makeHead(cmdId,userId,errorId,bodylen)
    local head = buffer.Buffer:new(offset)
    head:writeUInt32BE(1,offset+bodylen) --PkgLen
    head:writeUInt8(5,0) --Version
    head:writeUInt32BE(6,cmdId) --Command
    head:writeUInt32BE(10,userId) --UserID
    head:writeUInt32BE(14,errorId) --Result
    return tostring(head)
end

function lpp.makeLoginBody(session)
    return "\0\0\0\0"..session.."\0\0\0\0"
end

local function createSrvList(buf,srvs)
    buf:writeUInt32BE(1,#srvs)
    local offset = 4
    for i=1,#srvs do
        buf:writeUInt32BE(offset+1,srvs[i].id)
        buf:writeUInt32BE(offset+5,srvs[i].userCount)
        local ip = srvs[i].ip
        for j=1,16 do
            if j <= #ip then
                buf:writeUInt8(offset+8+j,ip:byte(j))
            else
                buf:writeUInt8(offset+8+j,0)
            end
        end
        buf:writeUInt16BE(offset+25,srvs[i].port)
        buf:writeUInt32BE(offset+27,srvs[i].friends)
        offset = offset + 30
    end
end

function lpp.sendTextInfoBroadcast(socket,userid,msg) -- not used
    socket:write(lpp.makeHead(1414,userid,0,8+#msg))
    socket:wuint(0)
    socket:wuint(#msg)
    socket:wstr(msg,#msg)
end

function lpp.sendAuthCode(socket,userid,flag,codeid,codedata)
    socket:write(lpp.makeHead(101,userid,0,24+#codedata))
    socket:wuint(flag)
    socket:wstr(codeid,16)
    socket:wuint(#codedata)
    socket:wstr(codedata,#codedata)
end

--local aut = require("fs").readFileSync("upper.gif")

function lpp.makeSrvList(servers)
    local list = buffer.Buffer:new(#servers * 30 + 4)
    createSrvList(list,servers)
    return tostring(list)
end

function lpp.makeGoodSrvList(servers)
    local meta = buffer.Buffer:new(12)
    meta:writeUInt32BE(1,srv.getMaxServerID())
    meta:writeUInt32BE(5,0)-- isVip，TODO: 实现用户系统
    meta:writeUInt32BE(9,0)-- 好友列表userCount，RecMole无实现，填0
    return lpp.makeSrvList(servers) .. tostring(meta)
end

function lpp.preparse(data)
    local buf = buffer.Buffer:new(data)
    return buf:readUInt32BE(1)
end

function lpp.parse(data,socket)
    local buf = buffer.Buffer:new(data)
    local length = math.min(buf:readUInt32BE(1),buf.length)
    if length < 17 then return end
    if buf:readUInt8(5) ~= 1 then return end
    local cmdId = buf:readUInt32BE(6)
    local userId = buf:readUInt32BE(10)
    if buf:readUInt32BE(14) ~= 0 then return end
    local handler = lpp.handler[cmdId]
    if handler then handler(socket,userId,buf,length)
    else
        print("\27[31mUnhandled login packet:",cmdId,"\27[0m")
        --p(data)
    end
    
end

local aut = require("fs").readFileSync("upper.gif")

-- CMD_GET_AUTHCODE
lpp.handler[101] = function()
    p"getauth"
end

-- CMD_LOGIN
lpp.handler[103] = function(socket,userId,buf,length)
    if length < 147 then return end
    local password = buf:toString(offset+1,offset+32)
    local session = "0000000000000000"
    local body = lpp.makeLoginBody(session)
    --lpp.sendAuthCode(socket,userId,1,"0123456789abcdef",aut)
    socket:write(lpp.makeHead(103,userId,0,#body))
    socket:write(body)
    print("\27[1mLogin:",userId..",pass "..password..",session "..session.."\27[0m")
end

-- CMD_GET_GOOD_SERVER_LIST
lpp.handler[105] = function(socket,userId,buf,length)
    local session = buf:toString(offset+1,offset+16)
    local body = lpp.makeGoodSrvList(srv.getGoodSrvList())
    socket:write(lpp.makeHead(105,userId,0,#body))
    socket:write(body)
end

-- CMD_GET_SERVER_LIST
lpp.handler[106] = function(socket,userId,buf,length)
    local session = buf:toString(offset+1,offset+16)
    local body = lpp.makeSrvList(srv.getServerList())
    socket:write(lpp.makeHead(106,userId,0,#body))
    socket:write(body)
end



return lpp