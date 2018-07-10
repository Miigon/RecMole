-- RecMole Main

local conf={
    ressrv_port = 32400,
    loginip_port = 32401,
    login_server_address = "127.0.0.1:32402",
    login_port = 32402,
    gameserver_port = 1865,--32410,
    passthru = false,
    res_official_address = false,
    res_no_decrypt = true,
    trafficlogger = true,
}
_G.conf = conf

require "./buffer_write"
require "./ressrv"
require "./loginip"
local _ = conf.trafficlogger and require "./loginserver/trafficloggerlogin" or require "./loginserver/login"

local gs = conf.trafficlogger and require "./gameserver/trafficlogger" or require "./gameserver/gameserver"
gs.GameServer:new()