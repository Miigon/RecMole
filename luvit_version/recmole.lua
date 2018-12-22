-- RecMole Main

local conf={
    res_dir = "../res",
    ressrv_port = 32400,
    loginip_port = 32401,
    login_server_address = "127.0.0.1:32402",
    login_port = 32402,
    gameserver_port = 32410,--32410, 1201 for official
    passthru = false,
    res_official_address = false,
    res_bypass_encrypt = false,
    trafficlogger = true,
}
_G.conf = conf

require "./buffer_extension"
require "./ressrv"
--require "./loginip"

--local _ = conf.trafficlogger and require "./loginserver/trafficloggerlogin" or require "./loginserver/login"

--local gs = conf.trafficlogger and require "./gameserver/trafficlogger" or require "./gameserver/gameserver"
--gs.GameServer:new()