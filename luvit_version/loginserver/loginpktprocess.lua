-- Module for processing packets

local lpp = {}
lpp.handler = {}
local buffer = require "buffer"
require "../easybytewrite"
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

function lpp.sendAuthCode(socket,userid,flag,codeid,codedata)
    socket:write(lpp.makeHead(101,userid,0,24+#codedata))
    socket:wuint(flag)
    socket:wstr(codeid,16)
    socket:wuint(#codedata)
    socket:wstr(codedata,#codedata)
end

function lpp.parse(data,socket,mode)
    local buf = buffer.Buffer:new(data)
    p("len",buf:readUInt32BE(1),buf.length)
    local length = math.min(buf:readUInt32BE(1),buf.length)
    if length < 17 then return end
    --if buf:readUInt8(5) ~= 1 then return end
    local cmdId = buf:readUInt32BE(6)
    p(cmdId,mode)
    local userId = buf:readUInt32BE(10)
    if buf:readUInt32BE(14) ~= 0 then return end
    local handler = lpp.handler[cmdId]
    local ret = false
    if handler then ret = handler(socket,userId,buf,length,mode or 0)
    else
        print("\27[31mUnhandled login packet:",cmdId,"\27[0m")
        --p(data)
    end
    return ret;
end

function lpp.preparse(data)
    local buf = buffer.Buffer:new(data)
    return buf:readUInt32BE(1)
end

local aut = require("fs").readFileSync("upper.gif")

-- CMD_GET_AUTHCODE
lpp.handler[101] = function(socket,userId,buf,length)
    lpp.sendAuthCode(socket,0,1,"0123456789abcdef",aut)
    return true
end

-- CMD_LOGIN
lpp.handler[103] = function(socket,userId,buf,length,mode)
    if mode == 0 then -- 客户端发出
        if length < 147 then return end
        local password = buf:toString(offset+1,offset+32)
        local authcode = buf:toString(offset+61,offset+65)
        
        --local body = lpp.makeLoginBody(session)
        if presignSession(authcode,userId) == false then
            lpp.sendAuthCode(socket,0,1,"0123456789abcdef",aut)
            return true
        end
        print("\27[1mLogin:",userId..",pass "..password..",token "..authcode.."\27[0m")

        return buf:toString(1,offset+44) .. string.rep("\0",21) .. buf:toString(offset+66,offset+130);
    elseif mode == 1 then -- 服务端发出
        if buf:ruint(offset+1) == 0 then --登录成功
            signSession(userId)
        end
    end
end

-- CMD_GET_GOOD_SERVER_LIST
lpp.handler[105] = function(socket,userId,buf,length)
    return false
end

-- CMD_GET_SERVER_LIST
lpp.handler[106] = function(socket,userId,buf,length)
    return false
end



return lpp