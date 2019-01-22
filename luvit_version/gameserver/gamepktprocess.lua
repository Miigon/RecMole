-- Module for processing packets

local gpp = {}
gpp.handler = {}
local buffer = require "buffer"
require "../easybytewrite"
local offset = 17 -- 包头长度

function gpp.makeHead(cmdId,userId,errorId,bodylen)
    local head = buffer.Buffer:new(offset)
    head:wuint(1,offset+bodylen) --PkgLen
    head:wbyte(5,0) --Version
    head:wuint(6,cmdId) --Command
    head:wuint(10,userId) --UserID
    head:wuint(14,errorId) --Result
    return tostring(head)
end

function gpp.makeAllNpcJob(userid,npcid)
    local buf = buffer.Buffer:new(4)
    buf:wuint(1,0) --jobCount
    return tostring(buf)
end


function gpp.makeOneUser(userid,mapid,type)
    return gpp.makeAllSceneUser(userid,mapid,type):sub(5,-1)
end


function gpp.makeAllSceneUser(userid,mapid,type)
    local buf = buffer.Buffer:new(247)
    -- TEMP
    buf:wuint(1,1) --count
    buf:wuint(5,userid) --userid
    buf:write(9,"RecMole",16) --nick
    buf:wuint(26,0) --parentid
    buf:wuint(29,0) --childcount
    buf:wuint(33,0) --newchildcount
    buf:wuint(37,16766720) --color
    buf:wuint(41,0) --vip
    buf:wuint(45,mapid) --MapId
    buf:wuint(49,type) --MapType
    buf:wbyte(53,0) --status
    buf:wuint(54,0) --action
    buf:wuint(58,0) --Pet_action
    buf:wbyte(62,0) --Direction
    buf:wuint(63,510) --PosX
    buf:wuint(67,350) --PosY
    buf:wuint(71,0) --Grid
    buf:wuint(75,0) --Action2
    buf:wuint(79,0) --PetID
    buf:write(83,"",16) --PetName
    buf:wuint(99,0) --PetColor
    buf:wbyte(103,0) --PetLevel
    buf:wuint(104,0) --Reserved1
    buf:wuint(108,0) --PetSick
    buf:wuint(112,0) --skill_Fire
    buf:wuint(116,0) --skill_Water
    buf:wuint(120,0) --skill_Wood
    buf:wuint(124,0) --Skill_Type
    buf:wuint(128,0) --Skill_Value
    buf:wbyte(132,0) --item1
    buf:wbyte(133,0) --item2
    buf:wbyte(134,0) --item3
    buf:wuint(135,0) --Pet_cloth
    buf:wuint(139,0) --Pet_honor
    buf:wuint(143,0) --Can_Fly
    buf:write(147,"",32) --Activity
    --Dragon
    buf:wuint(179,0) --id
    buf:write(183,"",16) --nickname
    buf:wuint(199,0) --growth
    buf:wuint(203,0) --digTreasureLvl
    buf:wuint(207,0) --hasCar
    --CAR INFO IF NOT 0
    buf:wuint(211,0) --hasAnimal
    --ANIMAL INFO IF NOT 0
    buf:wuint(215,0) --roleType
    buf:wbyte(219,6) --ItemCount
    --ITEM INFO IF NOT 0
    buf:wuint(220,12059)
    buf:wuint(224,12645)
    buf:wuint(228,12646)
    buf:wuint(232,12735)
    buf:wuint(236,12750)
    buf:wuint(240,14730)
    buf:wuint(244,0) --superGuide
    
    return tostring(buf)
end

function gpp.sendTextNotice(socket,type,map,maptype,grid,userid,nick,icon,schema,pic,infomsg)
    socket:write(gpp.makeHead(10003,userid,0,52+#infomsg))
    socket:wuint(type)
    socket:wuint(map)
    socket:wuint(maptype)
    socket:wuint(grid)
    socket:wuint(userid)
    socket:wstr(nick,16)
    socket:wuint(icon)
    socket:wuint(schema)
    socket:wuint(pic)
    socket:wuint(#infomsg)
    socket:wstr(infomsg,#infomsg)
end

function gpp.makeLoginOnlineSre(userId) -- 实际发送的是User info
    local buf = buffer.Buffer:new(239)
    buf:wuint(1,userId) --userid
    buf:write(5,"RecMole",16) --nick
    buf:wuint(21,0) --parentid
    buf:wuint(25,0) --childcount
    buf:wuint(29,0) --newchildcount
    buf:wuint(33,16766720) --color
    buf:wuint(37,0) --vip
    buf:wuint(41,0) --roleType
    buf:wuint(45,1524493816) --birthday
    buf:wuint(49,0) --exp
    buf:wuint(53,0) --strong
    buf:wuint(57,0) --iq
    buf:wuint(61,0) --charm
    buf:wuint(65,0) --game_king
    buf:wuint(69,12450) --YXQ  (摩尔豆)
    buf:wuint(73,0) --enginner
    buf:wuint(77,1) --dancelevel
    buf:wuint(81,1) --planter
    buf:wuint(85,1) --farmer
    buf:wuint(89,0) --dining_flag
    buf:wuint(93,0) --dining_level
    buf:wuint(97,3) --mapid (地图) 47
    buf:wuint(101,0) --maptype
    buf:wbyte(105,0) --status
    buf:wuint(106,0) --action
    buf:wbyte(110,0) --direction
    buf:wuint(111,111) --posx
    buf:wuint(115,115) --posy
    buf:wuint(119,509) --LoginTimes
    buf:wuint(123,50601600) --birthday
    buf:wuint(127,0) --PetSkill5_Flag
    buf:wuint(131,0) --Magic_task
    buf:wuint(135,0) --Vip_level
    buf:wuint(139,0) --Vip_month
    buf:wuint(143,0) --VipValue
    buf:wuint(147,0) --VipEndTime
    buf:wuint(151,0) --autoPayVip
    -- Dragon
    buf:wuint(155,0) --obj.id
    buf:write(159,"",16) --obj.nickname
    buf:wuint(175,0) --obj.growth
    buf:wuint(179,17429) --RemainingTime
    buf:write(183,'\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\001\000\000\000\006\000\000\000\000\000\000\000\000',32) --Activity
    buf:wbyte(215,6) --ItemCount (LoginOnlineSreRes.as:74)
    buf:wuint(216,12059)
    buf:wuint(220,12645)
    buf:wuint(224,12646)
    buf:wuint(228,12735)
    buf:wuint(232,12750)
    buf:wuint(236,14730)
    return tostring(buf)
end

function gpp.makeMapInfo(mapid,type)
    local buf = buffer.Buffer:new(80)
    buf:wuint(1,mapid) --MapId
    buf:wuint(5,type) --MapType
    buf:write(9,"粒粒小广场",64) --Name
    buf:wuint(73,1) --type
    buf:wuint(77,0) --itemCount --物体数量
    return tostring(buf)
end

function gpp.makeIsFinishedSth(userid,type)
    local buf = buffer.Buffer:new(8)
    buf:wuint(1,type) --type
    buf:wuint(5,1022) --done
    return tostring(buf)
end

function gpp.sendChat(userId,socket,towho,str)
    print("聊天频道：",str)
    socket:write(gpp.makeHead(302,userId,0,28+#str))
    socket:wuint(0)
    socket:wstr("RecMole",16)
    socket:wuint(0) --friend
    socket:wuint(#str) --msglen
    socket:wstr(str,#str)
end

function gpp.makeAction(userid,action,direction)
    local buf = buffer.Buffer:new(10)
    buf:wuint(1,userid)
    buf:wuint(5,action)
    buf:wbyte(9,direction)
    return tostring(buf)
end

function gpp.make()
    local buf = buffer.Buffer:new(--[[TODO:Length]])

    return tostring(buf)
end

function gpp.makeLeaveMap(list)
    local buf = buffer.Buffer:new(#list*4 + 4)
    buf:wuint(1,#list)
    for i=1,#list do
        buf:wuint(1+i*4,list[i])
    end
    return tostring(buf)
end

function gpp.makeUserInfo(id)
    local buf = buffer.Buffer:new(27)
    buf:wuint(1,id)
    buf:wbyte(5,1) --level
    buf:wuint(6,0) --exp
    buf:wuint(10,95) --needExp
    buf:wushort(14,30) --bagsize
    buf:wushort(16,3) --exchg_bagsize
    buf:wbyte(18,1) --max_training_num
    buf:wbyte(19,0) --training_lv
    buf:wuint(20,0) --instrument1
    buf:wuint(24,0) --instrument2
    return tostring(buf)
end

function gpp.makeServerTime()
    local buf = buffer.Buffer:new(8)
    buf:wuint(1,os.time()) --sec
    buf:wuint(5,0) -- millisec
    return tostring(buf)
end

function gpp.makeBlacklist(userid)
    local buf = buffer.Buffer:new(4)
    buf:wuint(1,0) --Count
    return tostring(buf)
end

function gpp.makeComeBKStatus(userid,type)
    local buf = buffer.Buffer:new(12)
    buf:wuint(1,type)
    buf:wuint(5,0) --value1
    buf:wuint(9,0) --value2
    return tostring(buf)
end

function gpp.makeWalk(userid,endx,endy,id)
    local buf = buffer.Buffer:new(20)
    buf:wuint(1,id)
    buf:wuint(5,endx)
    buf:wuint(9,endy)
    buf:wuint(13,id)
    buf:wuint(17,0)
    return tostring(buf)
end

function gpp.makeTraffic(userid,type)
    local buf = buffer.Buffer:new(12)
    buf:wuint(1,type)
    buf:wuint(5,8) --Unknown
    buf:wuint(9,2356) --Sec
    return tostring(buf)
end

function gpp.makePostcardCount(userid)
    local buf = buffer.Buffer:new(4)
    buf:wuint(1,0) --TEMP
    return tostring(buf)
end

function gpp.makeElementKnightInfo(userid)
    local buf = buffer.Buffer:new(85)
    buf:wuint(1,0) --id
    buf:wuint(5,2) --type
    buf:write(9,"RecMole",16) --nick
    buf:wuint(25,0) --exp
    buf:wuint(29,0) --curStrength
    buf:wuint(33,0) --maxStrength
    buf:wuint(37,2) --talent
    buf:wuint(41,0) --coolDown
    buf:wuint(45,0) --minAttack
    buf:wuint(49,0) --maxAttack
    buf:wuint(53,0) --minDef
    buf:wuint(57,0) --maxDef
    buf:wuint(61,0) --pvpWin
    buf:wuint(65,0) --pvpLose
    buf:wuint(69,0) --chasm
    buf:wuint(73,0) --rank
    buf:wuint(77,0) --count
    --ElementKnightCardInfo if not 0
    buf:wuint(81,0) --count 2

    return tostring(buf)
end

function gpp.makeLimitInfo(userid,list)
    local buf = buffer.Buffer:new(4+#list*4)
    buf:wuint(1,#list)
    for i=1,#list do
        --buf:wuint(1+i*4,list[i] or 0)
        buf:wuint(1+i*4,5) --TEMP
    end
    return tostring(buf)
end


function gpp.preparse(data)
    local buf = buffer.Buffer:new(data)
    return buf:readUInt32BE(1)
end

function gpp.parse(data,socket,user)
    local buf = buffer.Buffer:new(data)
    local length = math.min(buf:ruint(1),buf.length)
    if length < 17 then return end
    --if buf:readInt8(5) ~= 65 then return end -- Version，65  --Problematic
    local cmdId = buf:ruint(6)
    local userId = buf:ruint(10)
    --print ("收到包 " .. cmdId)
    if buf:ruint(14) ~= 0 then return end -- Result，未知
    local handler = gpp.handler[cmdId]
    if handler then
        handler(socket,userId,buf,length,user)
    else
        print("\27[31mUnhandled packet:",cmdId,"with length",length  ,"\27[0m")
        --p(data)
    end
    
end

-- note:登录Online Server
gpp.handler[201] = function(socket,userId,buf,length)
    local serverID = buf:readInt16BE(offset+1)
    local magicString = buf:toString(offset+3,offset+18)
    local sessionLen = buf:ruint(offset+19)
    local off2 = offset+23+sessionLen;
    local session = buf:toString(offset+23,off2)
    local loginType = buf:readInt16BE(off2+1)
    local adByte = buf:rbyte(off2+3)
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
    body = gpp.sendTextNotice(socket,0,0,0,0,userId,"RECMOLE",0,0,0,"测试 RecMole 连接性能" )

end

gpp.handler[11010] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(11010,userId,0,1))
    socket:write("\0")
end

--注册会员跳转页面session
gpp.handler[10302] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(10302,userId,0,36))
    socket:write('[C\139E435370a2b2f3c57c07f3564f792f1650')
end

--SMC任务列表
gpp.handler[216] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(216,userId,0,4))
    socket:write('\0\0\0\0')
end

--获取是否需要支付密码
gpp.handler[8920] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(8920,userId,0,4))
    socket:write('\0\0\0\0')
end

--查询魔法课程
gpp.handler[1496] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(1496,userId,0,4))
    socket:write('\0\0\0\0')
end

--查看连续30天登录信息
gpp.handler[6024] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(6024,userId,0,24))
    socket:write(string.rep("\0",24))
end

--查看连续30天登录信息
gpp.handler[6026] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(6026,userId,0,8))
    socket:write("\0\0\0\0\0\0\0\0")
end

--查询是否已有超级拉姆
gpp.handler[232] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(232,userId,0,1))
    socket:write("\0")
end

--拉取宠物任务列表
gpp.handler[228] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(228,userId,0,8))
    socket:write("\0\0\0\0\0\0\0\0")
end

--统计平台消息
gpp.handler[6034] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(6034,userId,0,1))
    socket:write("\0")
end

--拉宠物在地图中的数量
gpp.handler[233] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(233,userId,0,4))
    socket:write("\0\0\0\0")
end

--离开地图
gpp.handler[402] = function(socket,userId,buf,length,user)
    local map = user[map]
    local body = gpp.makeLeaveMap({userId})
    local function when402(user)
        --user.map == 
    end
    
    gpp.broadcast(gpp.makeHead(402,userId,0,#body))
    gpp.broadcast(body)
end

--进入地图
gpp.handler[401] = function(socket,userId,buf,length,user)
    local newmapid = buf:ruint(offset+1)
    local newmaptype = buf:ruint(offset+5)
    local oldmapid = buf:ruint(offset+9)
    local oldmaptype = buf:ruint(offset+13)
    local newgrid = buf:ruint(offset+17)
    local oldgrid = buf:ruint(offset+21)
    user.map = newmapid
    local body = gpp.makeOneUser(userId,newmapid,newmaptype)
    socket:write(gpp.makeHead(401,userId,0,#body))
    socket:write(body)
end

--走路
gpp.handler[303] = function(socket,userId,buf,length)
    local endx = buf:ruint(offset+1)
    local endy = buf:ruint(offset+5)
    local id = buf:ruint(offset+9)
    local body = gpp.makeWalk(userId,endx,endy,id)
    socket:write(gpp.makeHead(303,userId,0,#body))
    socket:write(body)
end

--聊天
gpp.handler[302] = function(socket,userId,buf,length)
    local towho = buf:ruint(offset+1)
    local msglen = buf:ruint(offset+5)
    local str = buf:toString(offset+9,offset+9+msglen-2)
    gpp.sendChat(userId,socket,towho,str)
end

--查看背包
gpp.handler[507] = function(socket,userId,buf,length)
    local userid = buf:ruint(offset+1)
    local type = buf:ruint(offset+5)
    local flag = buf:rbyte(offset+9)
    local newtype = buf:rbyte(offset+10)
    p(userid,type,flag,newtype)
    socket:write(gpp.makeHead(507,userId,0,1))
    socket:write("\0")
end

--动作
gpp.handler[305] = function(socket,userId,buf,length)
    local action = buf:ruint(offset+1)
    local direction = buf:rbyte(offset+5)
    local body = gpp.makeAction(userId,action,direction)
    socket:write(gpp.makeHead(305,userId,0,#body))
    socket:write(body)
end

--时间问候
gpp.handler[10011] = function(socket,userId,buf,length)
    local type = buf:ruint(offset+1)
    local body = gpp.makeTraffic(userId,type)
    socket:write(gpp.makeHead(10011,userId,0,#body))
    socket:write(body)
end

--COME_BK_STATUS
gpp.handler[8755] = function(socket,userId,buf,length)
    local type = buf:ruint(offset+1)
    if true then return end --ignore 2025 temporarily
    local body = gpp.makeComeBKStatus(userId,type)
    socket:write(gpp.makeHead(8755,userId,0,#body))
    socket:write(body)
end

--仅读取未读过的明信片数目
gpp.handler[805] = function(socket,userId,buf,length)
    local body = gpp.makePostcardCount(userId)
    socket:write(gpp.makeHead(805,userId,0,#body))
    socket:write(body)
end

--GET_KNIGHT_TRANSFER_STATE
gpp.handler[8974] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(8974,userId,0,4))
    socket:write("\0\0\0\2")
end

--屋委会会长投票
gpp.handler[2008] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(2008,userId,0,32))
    socket:write('\000\022\000\001Pp\255\255\248\000\000\000\000\003\129\b\000\000\000\000\000\000X\t%\221\200@\000\000\000\000')
end

--ELEMENT_KNIGHT_INFO
gpp.handler[8990] = function(socket,userId,buf,length)
    local body = gpp.makeElementKnightInfo()
    socket:write(gpp.makeHead(8990,userId,0,#body))
    socket:write(body)
end

--getKnightTransferState
gpp.handler[9124] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(9124,userId,0,4))
    socket:write("\0\0\0\0")
end

--11085 getUserInfo
gpp.handler[11085] = function(socket,userId,buf,length)
    local body = gpp.makeUserInfo(buf:ruint(offset+1))
    socket:write(gpp.makeHead(11085,userId,0,#body))
    socket:write(body)
end

--获取我的职业
gpp.handler[1328] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(1328,userId,0,226))
    socket:write('\005\000\000\000\001\000\000\000\001\000\000\000\002\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000Stx\252wm6v\216V1\239\228G@f%.#3{D+X\015A')
end

--MAGICSPIRIT_BAG_INFO
gpp.handler[12018] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(12018,userId,0,380))
    socket:write('\000\000\000\006S\195i\211\000\026>\252\003\004\000\000\001\144\000\147\000Z\000\023\v\192\001\000\000\000\001\000TT\249\169\000\026>\196\002\005\000\000\0039\000\144\000G\000\r\003\236\001\a\210\000\000\000TT\249\224\000\026>\224\003\b\000\000\006\'\000\167\000N\000\031\000\000\000\000\000\000\000\000Y\209\003\198\000\026?O\001\001\000\000\000\000\000\200\001^\000P\000\000\000\000\000\000\000\000Y\214SQ\000\026?P\002\001\000\000\000\000\000\200\001^\000P\000\000\000\000\000\000\000\000Y\214SR\000\026?Q\003\001\000\000\000\000\000\200\001^\000P\000\000\000\000\000\000\000\000%6\000\174[GS\004\233\v\a\213\128OquAN\f\000\019\020\014\217\030\225h\018\028\253:~%*w\184T\208AR\f\023\024\210\\\026w2i\bvU\192\211%0H\236VFA\b\0159\019\130]]w?k\228#\006\235z%*"|\173\163A\0182\224\016\026]\026q\021h\175"O9e%*v(TCA\bU\209\016\212]\000H}i\t"\0019z%\226wvT\019A\b\f\000\019\018]\026.\228;Y"\027\006*\'+v(TCA\192\r^\019B]\026w2h\b"\001`\172vxv2k\018B\t\f\000\019\018]\210vlhX"\0019z%*v(quA\198RG@F\220\023p\231\232GStx4')
end

--MAGICSPIRIT_USER_INFO
gpp.handler[12004] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(12004,userId,0,124))
    socket:write("\004.\2156\004\000\000\000r\000\000\001\000\000]TT\251\155\000\028\000'\001S\195i\211TT\249\224\000\000\000\000\000\000\000\000TT\249\169\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000")
end

--summmerAct_GetStep
gpp.handler[8817] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(8817,userId,0,12))
    socket:write("\0\0\0\0\0\0\0\0\0\0\0\0")
end

--通用状态标记 get_limit_info
gpp.handler[11009] = function(socket,userId,buf,length)
    local len = buf:ruint(offset+1)
    local list = {}
    for i = 1,len do
        list[i] = 0--buf:ruint(1+i*4)
    end
    local body = gpp.makeLimitInfo(userId,list)
    socket:write(gpp.makeHead(11009,userId,0,#body))
    socket:write(body)
end

--根据游戏ID获得登入签登入Session
gpp.handler[426] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(426,userId,0,16))
    socket:write("\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
end

--GET_MY_PROFESSION
gpp.handler[12018] = function(socket,userId,buf,length)
    socket:write(gpp.makeHead(12018,userId,0,380))
    socket:write('\000\000\000\006S\195i\211\000\026>\252\003\004\000\000\001\144\000\147\000Z\000\023\v\192\001\000\000\000\001\000TT\249\169\000\026>\196\002\005\000\000\0039\000\144\000G\000\r\003\236\001\a\210\000\000\000TT\249\224\000\026>\224\003\b\000\000\006\'\000\167\000N\000\031\000\000\000\000\000\000\000\000Y\209\003\198\000\026?O\001\001\000\000\000\000\000\200\001^\000P\000\000\000\000\000\000\000\000Y\214SQ\000\026?P\002\001\000\000\000\000\000\200\001^\000P\000\000\000\000\000\000\000\000Y\214SR\000\026?Q\003\001\000\000\000\000\000\200\001^\000P\000\000\000\000\000\000\000\000%6\000\174[GS\004\233\v\a\213\128OquAN\f\000\019\020\014\217\030\225h\018\028\253:~%*w\184T\208AR\f\023\024\210\\\026w2i\bvU\192\211%0H\236VFA\b\0159\019\130]]w?k\228#\006\235z%*"|\173\163A\0182\224\016\026]\026q\021h\175"O9e%*v(TCA\bU\209\016\212]\000H}i\t"\0019z%\226wvT\019A\b\f\000\019\018]\026.\228;Y"\027\006*\'+v(TCA\192\r^\019B]\026w2h\b"\001`\172vxv2k\018B\t\f\000\019\018]\210vlhX"\0019z%*v(quA\198RG@F\220\023p\231\232GStx4')
end

--获取地图信息
gpp.handler[406] = function(socket,userId,buf,length)
    local mapid = buf:readInt32BE(offset+1)
    local type = buf:readInt32BE(offset+5)
    local body = gpp.makeMapInfo(mapid,type)
    socket:write(gpp.makeHead(406,userId,0,#body))
    socket:write(body)
end

--获取地图用户
gpp.handler[405] = function(socket,userId,buf,length)   
    local mapid = buf:readInt32BE(offset+1)
    local type = buf:readInt32BE(offset+5)
    local myinfo_grid = buf:readInt32BE(offset+9)
    local body = gpp.makeAllSceneUser(userId,mapid,type)
    socket:write(gpp.makeHead(405,userId,0,#body))
    socket:write(body)
end

--查询NPC所有任务状态
gpp.handler[3106] = function(socket,userId,buf,length)
    local npcid = buf:readInt32BE(offset+1)
    --local body = gpp.makeAllNpcJob(userId,npcid)
    local body = '\000\000\000\a\000\000\000\t\000\000\000\004\255\255\2558\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\002\000\000\000\000\000\000\000\003\000\000\000\a\255\255\2558\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\002\000\000\000\000\000\000\000\004\000\000\000\a\255\255\2558\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\000\000\000\000\000\000\000\000\024\000\000\000\b\000\000\000\000\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\002\000\000\000\000\000\000\000\025\000\000\000\b\255\255\2558\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\000\000\000\000\026\000\000\000\b\255\255\2558\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\000\000\000\000(\000\000\000\t\255\255\2558\000\000\000\000\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000\000'
    socket:write(gpp.makeHead(3106,userId,0,#body))
    socket:write(body)
end

--获取黑名单列表
gpp.handler[609] = function(socket,userId,buf,length)
    local body = gpp.makeBlacklist(userId)
    socket:write(gpp.makeHead(609,userId,0,#body))
    socket:write(body)
end

--是否完成某事
gpp.handler[10101] = function(socket,userId,buf,length)
    local type = buf:readInt32BE(offset+1)
    local body = gpp.makeIsFinishedSth(userId,type)
    socket:write(gpp.makeHead(10101,userId,0,#body))
    socket:write(body)
end

--查询领取状态
gpp.handler[8606] = function(socket,userId,buf,length)
    local type = buf:readInt32BE(offset+1)
    local body = gpp.makeIsFinishedSth(userId,type) -- TODO:implement this
    socket:write(gpp.makeHead(8606,userId,0,#body))
    socket:write(body)
end

--获取服务器时间
gpp.handler[10301] = function(socket,userId,buf,length)
    local body = gpp.makeServerTime()
    socket:write(gpp.makeHead(10301,userId,0,#body))
    socket:write(body)
end

return gpp