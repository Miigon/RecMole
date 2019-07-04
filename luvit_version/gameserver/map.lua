local Map = {}
local maps = {}
local mapsinfo = require "./mapsinfo"
local gpp = require "./gamepktprotocol"

for i=1,#mapsinfo do
    maps[i] = {}
end

function Map.getMap(mapid)
    return maps[mapid]
end

function Map.getMapByUser(user)
    return Map.getMap(user.map)
end

function Map.changeMapOfUser(user,newmap)
    local oldmap = user.mapid
    Map._userLeaveMap(user)
    user.mapid = newmap
    Map._userEnterMap(user,newmap)
end

function Map.isMapVaild(mapid)
    return maps[mapid] and true or false
end

function Map._userLeaveMap(user_leaving)
    local map = maps[user_leaving.mapid]
    if map == nil then return end
    for i=1,#map do
        local iuser = map[i]
        if iuser == user_leaving then
            map[i] = nil;
        end
        --todo: send leave packet
    end
end

function Map._userEnterMap(user_entering,mapid) -- won't actually change current map of the user. just inform everyone in the map that the user entered.
    if Map.isMapVaild(mapid) == false then
        return
    end
    --p(user_entering,mapid)
    local map = maps[user_entering.mapid]
    map[#map+1] = user_entering
    gpp.broadcastEnterMap(map,user_entering)
end
return Map