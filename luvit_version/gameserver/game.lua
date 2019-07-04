local Game = {}
local Map = require "./map"
local gpp = require "./gamepktprotocol"
local usrcnt = 0
local userlist = {}

function Game.newUser()
    local user = {}
    user.logon = false;

    return user
end

function Game.login(user,userid,serverID,magicString,userion,loginType)
    userlist[userid] = user
    usrcnt = usrcnt + 1
    user.logon = true
    user.userid = userid
    user.nick = "小摩尔" .. usrcnt .. "号"
    user.color = 16766720
    user.vip = false
    user.birthday = 1524493816
    user.exp = 19
    user.strong = 32
    user.iq = 10
    user.charm = 12
    user.game_king = 0
    user.molebean = 12450
    user.map = 3
    user.status = 0
    user.action = 0
    user.direction = 0
    user.x = 333
    user.y = 333
    user.pet_action = 0
    user.grid = 0
    user.action2 = 0
    user.super_guide = 0
    Game.enterMap(user,3,0)
    gpp.sendLoginOnlineSre(user)
    gpp.sendTextNotice(user,0,0,0,0,userid,"RECMOLE",0,0,0,"RecMole 文本通知测试。你登录的账号为：".. userid )
    p(user)
    Game.talk(user,0,"我是一坨可爱的小摩尔~")
end

function Game.endUser(user)
    
end

function Game.enterMap(user,newmap,newmaptype)
    Map.changeMapOfUser(user,newmap)
end

function Game.walk(user,endx,endy,id)
    user.x = endx
    user.y = endy
    gpp.broadcastWalk(Map.getMapByUser(user),user.userid,endx,endy,id)
end

function Game.talk(user,towho,str)
    if towho == 0 then
        if str == "/color" then
            gpp.broadcastChat(Map.getMapByUser(user),user,towho,"我已经随机变色了")
            user.color = math.random(0xffffffff)
            gpp.sendAllSceneUser(user,user.map)
            return
        end
        gpp.broadcastChat(Map.getMapByUser(user),user,towho,str)
    elseif userlist[towho] then
        gpp.sendChat(userlist[towho],user,towho,str)
    end
    print(string.format("\27[0m[%s]%s: %s",user.userid,user.nick,str))
end

function Game.doAction(user,action,direction)
    user.action = action
    user.direction = direction
    gpp.broadcastAction(Map.getMapByUser(user),user,action,direction)
end

return Game
