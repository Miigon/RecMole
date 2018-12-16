local net = require "net"
local index = getmetatable(net.Socket).__index
local char = string.char
local band = bit.band
local rshift = bit.rshift
local rep = string.rep
local sub = string.sub

function index.wuint(socket,data)
    socket:write(char(rshift(band(data,0xFF000000),24)))
    socket:write(char(rshift(band(data,0xFF0000),16)))
    socket:write(char(rshift(band(data,0xFF00),8)))
    socket:write(char(band(data,0xFF)))
end

function index.wushort(socket,data)
    socket:write(char(rshift(band(data,0xFF00),8)))
    socket:write(char(band(data,0xFF)))
end

function index.wbyte(socket,data)
    socket:write(char(band(data,0xFF)))
end

function index.wstr(socket,data,len)
    local actual_len = #data
    if len < actual_len then
        socket:write(sub(data,1,len))
    else
        socket:write(data)
        if len > actual_len then
            socket:write(rep("\0",len - actual_len))
        end
    end
end
