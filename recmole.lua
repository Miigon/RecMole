-- RecMole Main

local conf={
    ressrv_port = 32400,
    loginip_port = 32401,
    login_server_address = "127.0.0.1:32402",
    login_port = 32402,
    gameserver_port = 32410,
}
_G.conf = conf

require "./ressrv"
require "./loginip"
require "./loginserver/login"
local gs = require "./gameserver/gameserver"
gs.GameServer:new()