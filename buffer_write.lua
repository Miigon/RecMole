local buffer = require "buffer"
buffer.Buffer.write = function(buf,pos,str,len)
    local getbyte = string.byte
    local i = 0
    for c in str:gmatch"." do
        if i < len then
            buf:writeUInt8(pos+i,getbyte(c))
        else
            return
        end
        i = i + 1
    end
    for j = i,len-1 do
        buf:writeUInt8(pos+j,0)
    end
end
