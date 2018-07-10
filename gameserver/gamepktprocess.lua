-- Module for processing packets

local gpp = {}
gpp.handler = {}
local buffer = require "buffer"
local offset = 17 -- 包头长度

function gpp.makeHead(cmdId,userId,errorId,bodylen)
    local head = buffer.Buffer:new(offset)
    head:writeUInt32BE(1,offset+bodylen) --PkgLen
    head:writeUInt8(5,0) --Version
    head:writeUInt32BE(6,cmdId) --Command
    head:writeUInt32BE(10,userId) --UserID
    head:writeUInt32BE(14,errorId) --Result
    return tostring(head)
end

function gpp.makeTextNotice(type,map,maptype,grid,userid,nick,icon,schema,pic,infomsg)
    local buf = buffer.Buffer:new(52+#infomsg)
    buf:writeUInt32BE(1,type)
    buf:writeUInt32BE(5,map)
    buf:writeUInt32BE(9,maptype)
    buf:writeUInt32BE(13,grid)
    buf:writeUInt32BE(17,userid)
    buf:write(21,nick,16)
    buf:writeUInt32BE(37,icon)
    buf:writeUInt32BE(41,schema)
    buf:writeUInt32BE(45,pic)
    buf:writeUInt32BE(49,#infomsg)
    buf:write(53,nike)
    -- Not finished
end

function gpp.makeLoginOnlineSre(userId) -- 实际发送的是User info
    local buf = buffer.Buffer:new(223)
    buf:writeUInt32BE(1,userId) --userid
    buf:write(5,"RecMole",16) --nick
    buf:writeUInt32BE(21,0) --parentid
    buf:writeUInt32BE(25,0) --childcount
    buf:writeUInt32BE(29,0) --newchildcount
    buf:writeUInt32BE(33,16766720) --color
    buf:writeUInt32BE(37,0) --vip
    buf:writeUInt32BE(41,0) --roleType
    buf:writeUInt32BE(45,1524493816) --birthday
    buf:writeUInt32BE(49,0) --exp
    buf:writeUInt32BE(53,0) --strong
    buf:writeUInt32BE(57,0) --iq
    buf:writeUInt32BE(61,0) --charm
    buf:writeUInt32BE(65,0) --game_king
    buf:writeUInt32BE(69,12450) --YXQ  (摩尔豆)
    buf:writeUInt32BE(73,0) --enginner
    buf:writeUInt32BE(77,1) --dancelevel
    buf:writeUInt32BE(81,1) --planter
    buf:writeUInt32BE(85,1) --farmer
    buf:writeUInt32BE(89,0) --dining_flag
    buf:writeUInt32BE(93,0) --dining_level
    buf:writeUInt32BE(97,301) --mapid (地图) 47
    buf:writeUInt32BE(101,0) --maptype
    buf:writeUInt8(105,0) --status
    buf:writeUInt32BE(106,0) --action
    buf:writeUInt8(110,0) --direction
    buf:writeUInt32BE(111,160) --posx
    buf:writeUInt32BE(115,375) --posy
    buf:writeUInt32BE(119,64) --LoginTimes
    buf:writeUInt32BE(123,0) --birthday
    buf:writeUInt32BE(127,0) --PetSkill5_Flag
    buf:writeUInt32BE(131,0) --Magic_task
    buf:writeUInt32BE(135,0) --Vip_level
    buf:writeUInt32BE(139,0) --Vip_month
    buf:writeUInt32BE(143,0) --VipValue
    buf:writeUInt32BE(147,0) --VipEndTime
    buf:writeUInt32BE(151,0) --autoPayVip
    -- Dragon
    buf:writeUInt32BE(155,0) --obj.id
    buf:write(159,"RecMole",16) --obj.nickname
    buf:writeUInt32BE(175,0) --obj.growth
    buf:writeUInt32BE(179,14254) --RemainingTime
    buf:write(183,"",32) --Activity
    buf:writeUInt8(215,2) --ItemCount (LoginOnlineSreRes.as:74)
    buf:writeUInt8(219,67) --item1
    buf:writeUInt8(223,68) --item2
    return tostring(buf)
end

function gpp.makeMapInfo(mapid,type)
    local buf = buffer.Buffer:new(223)
    buf:writeUInt32BE(1,mapid) --MapId
    buf:writeUInt32BE(5,type) --MapType
    buf:write(9,"地图名Placeholder",64) --Name
    buf:writeUInt32BE(73,0) --type
    buf:writeUInt32BE(79,0) --itemCount --物体数量
    return tostring(buf)
end

function gpp.parse(data,socket)
    local buf = buffer.Buffer:new(data)
    local length = math.min(buf:readUInt32BE(1),buf.length)
    if length < 17 then return end
    --if buf:readInt8(5) ~= 65 then return end -- Version，65  --Problematic
    local cmdId = buf:readUInt32BE(6)
    local userId = buf:readUInt32BE(10)
    --print ("收到包 " .. cmdId)
    if buf:readUInt32BE(14) ~= 0 then return end -- Result，未知
    local handler = gpp.handler[cmdId]
    if handler then handler(socket,userId,buf,length)
    else
        print("\27[31mUnhandled login packet:",cmdId,"\27[0m")
        --p(data)
    end
    
end

-- note:登录Online Server
gpp.handler[201] = function(socket,userId,buf,length)
    local serverID = buf:readInt16BE(offset+1)
    local magicString = buf:toString(offset+3,offset+18)
    local sessionLen = buf:readUInt32BE(offset+19)
    local off2 = offset+23+sessionLen;
    local session = buf:toString(offset+23,off2)
    local loginType = buf:readInt16BE(off2+1)
    local adByte = buf:readUInt8(off2+3)
    print(
        string.format(
            "\27[1m[loginOnlineSre]\n\tserverID:%i\n\tmagicString:%s\n\tsession:%s\n\tloginType:%i\n\t\27[0m",
            serverID,
            magicString,
            session,
            loginType
    ))
    --回发一个201包
    local body = gpp.makeLoginOnlineSre(userId)
    socket:write(gpp.makeHead(201,userId,0,#body))
    socket:write(body)
end

gpp.handler[11010] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(11010,userId,0,1))
    socket:write("\0")
end

--获取地图信息
gpp.handler[406] = function(socket,userId,buf,length)
    local mapid = buf:readInt32BE(offset+1)
    local type = buf:readInt32BE(offset+5)
    local body = gpp.makeMapInfo(mapid,type)
    socket:write(gpp.makeHead(406,userId,0,#body))
    socket:write(body)
end

return gpp