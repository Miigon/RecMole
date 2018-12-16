local playermanager = {}
local dataprovider = require "./dataprovider"
local onlineList = {}

function playermanager.login(userid)
    if onlineList[userid] ~= nil then return false end
    local userdata = {}
    onlineList[userid] = userdata
    userdata.nick = playermanager.getUserNick(userid)
    return true
end

function playermanager.getUserNick(userid)
    return dataprovider.getData(userid,"nick")
end


return playermanager