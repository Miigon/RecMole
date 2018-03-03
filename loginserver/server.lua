-- servers
local srv = {}

function srv.getGoodSrvList()
    return 
    {
        {
            id = 1,
            userCount = 0,
            ip = "127.0.0.1",
            port = 32410,
            friends = 0,
        },
        {
            id = 2,
            userCount = 10,
            ip = "127.0.0.1",
            port = 32410,
            friends = 0,
        },
        {
            id = 3,
            userCount = 20,
            ip = "127.0.0.1",
            port = 32410,
            friends = 0,
        },
    }
end

function srv.getServerList()
    return srv.getGoodSrvList()
end

function srv.getMaxServerID()
    return 20;
end

return srv